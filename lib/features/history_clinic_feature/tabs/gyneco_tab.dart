import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/history_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/widgets/shared_form_widgets.dart';
import 'package:hcs_app_lap/utils/widgets/info_card.dart';
import 'package:hcs_app_lap/utils/widgets/chip_group_card.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class GynecoTab extends ConsumerStatefulWidget {
  const GynecoTab({super.key});

  @override
  GynecoTabState createState() => GynecoTabState();
}

class GynecoTabState extends ConsumerState<GynecoTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Client? _client;
  late ClinicalHistory _draftHistory;
  bool _isDirty = false;
  bool _justSaved = false;
  bool _controllersReady = false;

  String _safeString(dynamic value) => value?.toString() ?? '';
  bool _safeBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  int? _safeInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  late TextEditingController _contraceptiveTypeController;
  late TextEditingController _weeksController;
  late TextEditingController _specificConditionsController;

  final List<String> _menstrualStatusOptions = [
    'Regular',
    'Irregular',
    'Ausente (Amenorrea)',
    'Menopausia',
    'No aplica / No sabe',
  ];
  final List<String> _pregnancyHistoryOptions = [
    'Ninguno',
    'Embarazada Actualmente',
    'Postparto (<1 año)',
    'Embarazos Previos (sin complic.)',
    'Embarazos Previos (con complic.)',
  ];
  final List<String> _birthTypeOptions = ['Vaginal', 'Cesárea', 'No aplica'];
  final List<String> _symptomOptions = [
    'SPM Severo',
    'Dolor Menstrual Incapacitante',
    'Sofocos',
    'Problemas de Sueño (Ciclo/Meno)',
    'Cambios de humor significativos',
    'Ninguno relevante',
  ];

  @override
  void initState() {
    super.initState();
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      _client = client;
      _initializeFromClient(client);
    }
  }

  void _initializeFromClient(Client client) {
    _draftHistory = client.history;
    _contraceptiveTypeController = TextEditingController(
      text: _safeString(
        _draftHistory.extra[HistoryExtraKeys.contraceptiveType],
      ),
    );
    _weeksController = TextEditingController(
      text: _safeString(
        _draftHistory.extra[HistoryExtraKeys.weeksGestationOrPostpartum],
      ),
    );
    _specificConditionsController = TextEditingController(
      text: _draftHistory.specificGynecoConditions ?? '',
    );
    _isDirty = false;
    _controllersReady = true;
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  Map<String, dynamic> _copyExtra() =>
      Map<String, dynamic>.from(_draftHistory.extra);

  Future<Client?> saveIfDirty() async {
    if (!_isDirty || _client == null) return null;
    final updatedClient = _client!.copyWith(history: _draftHistory);
    _isDirty = false;
    return updatedClient;
  }

  void resetDrafts() {
    final client = ref.read(clientsProvider).value?.activeClient ?? _client;
    if (client == null) return;
    _client = client;
    _initializeFromClient(client);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveDraft() async {
    final client = _client;
    if (client == null) return;
    final updatedClient = client.copyWith(history: _draftHistory);
    _justSaved = true;
    try {
      await ref
          .read(clientsProvider.notifier)
          .updateActiveClient(
            (prev) => prev.copyWith(history: updatedClient.history),
          );
    } finally {
      _justSaved = false;
    }
    if (!mounted) return;
    _isDirty = false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Datos gineco guardados')));
  }

  @override
  void dispose() {
    if (_controllersReady) {
      _contraceptiveTypeController.dispose();
      _weeksController.dispose();
      _specificConditionsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(clientsProvider, (previous, next) {
      final nextClient = next.value?.activeClient;
      if (nextClient == null) return;
      final isDifferentClient = _client?.id != nextClient.id;
      if (_justSaved) return;
      if (isDifferentClient || !_isDirty) {
        _client = nextClient;
        _initializeFromClient(nextClient);
        setState(() {});
      }
    });

    final client = ref.watch(clientsProvider).value?.activeClient;
    final isDifferentClient = _client?.id != client?.id;
    if (_client == null ||
        (isDifferentClient && client != null) ||
        (!_isDirty && _client != client && client != null)) {
      _client = client;
      if (client != null) {
        _initializeFromClient(client);
      }
    }

    if (client != null && parseGender(client.gender) == Gender.male) {
      return const Center(
        child: Text('Modulo no aplicable para genero masculino.'),
      );
    }

    final extra = _draftHistory.extra;
    final menstrualStatus = extra[HistoryExtraKeys.menstrualStatus] as String?;
    final usesContraceptives = _safeBool(
      extra[HistoryExtraKeys.usesHormonalContraceptives],
    );
    final pregnancyHistory =
        extra[HistoryExtraKeys.pregnancyHistory] as String?;
    final birthType = extra[HistoryExtraKeys.birthType] as String?;
    final cycleSymptoms =
        (_draftHistory.cycleRelatedSymptoms as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoCard(
                  title: 'Estado Menstrual',
                  icon: Icons.calendar_month,
                  accentColor: Colors.pink,
                  children: [
                    CustomDropdownButton<String>(
                      label: 'Estado Menstrual',
                      value: menstrualStatus,
                      items: _menstrualStatusOptions,
                      onChanged: (val) {
                        final copy = _copyExtra();
                        copy[HistoryExtraKeys.menstrualStatus] = val;
                        _draftHistory = _draftHistory.copyWith(extra: copy);
                        _markDirty();
                        setState(() {});
                      },
                      itemLabelBuilder: (item) => item.toString(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Usa Anticonceptivos Hormonales'),
                      value: usesContraceptives,
                      onChanged: (val) {
                        final copy = _copyExtra();
                        copy[HistoryExtraKeys.usesHormonalContraceptives] = val;
                        _draftHistory = _draftHistory.copyWith(extra: copy);
                        _markDirty();
                        setState(() {});
                      },
                    ),
                    if (usesContraceptives)
                      CustomTextFormField(
                        controller: _contraceptiveTypeController,
                        label: 'Tipo de Anticonceptivo',
                        onChanged: (v) {
                          final copy = _copyExtra();
                          copy[HistoryExtraKeys.contraceptiveType] = v;
                          _draftHistory = _draftHistory.copyWith(extra: copy);
                          _markDirty();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                InfoCard(
                  title: 'Historial de Embarazo y Lactancia',
                  icon: Icons.pregnant_woman,
                  accentColor: Colors.purple,
                  children: [
                    CustomDropdownButton<String>(
                      label: 'Historial de Embarazo',
                      value: pregnancyHistory,
                      items: _pregnancyHistoryOptions,
                      onChanged: (val) {
                        final copy = _copyExtra();
                        copy[HistoryExtraKeys.pregnancyHistory] = val;
                        _draftHistory = _draftHistory.copyWith(extra: copy);
                        _markDirty();
                        setState(() {});
                      },
                      itemLabelBuilder: (item) => item.toString(),
                    ),
                    const SizedBox(height: 16),
                    if (pregnancyHistory == 'Embarazada Actualmente' ||
                        pregnancyHistory == 'Postparto (<1 año)')
                      CustomTextFormField(
                        controller: _weeksController,
                        label: 'Semanas de Gestación o Postparto',
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final copy = _copyExtra();
                          copy[HistoryExtraKeys.weeksGestationOrPostpartum] =
                              _safeInt(v);
                          _draftHistory = _draftHistory.copyWith(extra: copy);
                          _markDirty();
                        },
                      ),
                    const SizedBox(height: 16),
                    CustomDropdownButton<String>(
                      label: 'Tipo de Parto (si aplica)',
                      value: birthType,
                      items: _birthTypeOptions,
                      onChanged: (val) {
                        final copy = _copyExtra();
                        copy[HistoryExtraKeys.birthType] = val;
                        _draftHistory = _draftHistory.copyWith(extra: copy);
                        _markDirty();
                        setState(() {});
                      },
                      itemLabelBuilder: (item) => item.toString(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Está en período de lactancia'),
                      value: _draftHistory.isBreastfeeding ?? false,
                      onChanged: (val) {
                        _draftHistory = _draftHistory.copyWith(
                          isBreastfeeding: val,
                        );
                        _markDirty();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                InfoCard(
                  title: 'Síntomas y Condiciones',
                  icon: Icons.healing,
                  accentColor: Colors.amber,
                  children: [
                    ChipGroupCard(
                      title: 'Síntomas Relacionados al Ciclo',
                      icon: Icons.sync,
                      options: _symptomOptions,
                      selectedOptions: cycleSymptoms,
                      onUpdate: (val) {
                        _draftHistory = _draftHistory.copyWith(
                          cycleRelatedSymptoms: val,
                        );
                        _markDirty();
                        setState(() {});
                      },
                      accentColor: kPrimaryColor,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _specificConditionsController,
                      label:
                          'Condiciones Ginecológicas Específicas (SOP, etc.)',
                      maxLines: 3,
                      onChanged: (v) {
                        _draftHistory = _draftHistory.copyWith(
                          specificGynecoConditions: v,
                        );
                        _markDirty();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: ElevatedButton(
                    onPressed: _saveDraft,
                    child: const Text('Guardar Datos Gineco'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
