import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/history_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/chip_group_card.dart';

class BackgroundTab extends ConsumerStatefulWidget {
  const BackgroundTab({super.key});

  @override
  BackgroundTabState createState() => BackgroundTabState();
}

class BackgroundTabState extends ConsumerState<BackgroundTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Client? _client;
  late ClinicalHistory _baseHistory;
  late ClinicalHistory _draftHistory;
  late List<String> _hereditarySelected;
  late List<String> _pathologicalSelected;
  bool _isDirty = false;
  String? _loadedRevision;

  List<String> _safeStringList(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : [];

  final List<String> _hereditaryOptions = [
    'Hipertensión Arterial',
    'Enfermedades Cardiovasculares',
    'Dislipidemias',
    'Diabetes Mellitus',
    'Obesidad',
    'Enfermedad Tiroidea',
    'Cáncer',
    'Enfermedad de Alzheimer / Demencia',
    'Asma',
    'Alergias Severas',
    'Enfermedades Renales',
    'Enfermedades Autoinmunes',
  ];

  final List<String> _pathologicalOptions = [
    'Hipertensión Arterial',
    'Diabetes Mellitus',
    'Enfermedad Tiroidea',
    'Dislipidemias',
    'Cáncer (actual o remisión)',
    'VIH/SIDA',
    'EPOC',
    'Asma',
    'Enfermedades Hepáticas',
    'Enfermedades Renales Crónicas',
    'Depresión',
    'Ansiedad',
    'Cirugias Previas',
    'Hospitalizaciones',
    'Alergias',
    'Fracturas',
    'Transfusiones',
    'COVID-19',
  ];

  @override
  void initState() {
    super.initState();
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      _client = client;
      _loadFromClient(client);
    }
  }

  void _loadFromClient(Client client) {
    _client = client;
    _baseHistory = client.history;
    _draftHistory = client.history;
    _loadedRevision = backgroundTabRevision(client);
    _hereditarySelected = _safeStringList(
      client.history.extra[HistoryExtraKeys.hereditaryFamilyHistory],
    );
    _pathologicalSelected = _safeStringList(
      client.history.extra[HistoryExtraKeys.personalPathologicalHistory],
    );
    _isDirty = false;
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  void _updateHereditary(List<String> selected) {
    _hereditarySelected = selected;
    final currentExtra = Map<String, dynamic>.from(_draftHistory.extra);
    currentExtra[HistoryExtraKeys.hereditaryFamilyHistory] = selected;
    _draftHistory = _draftHistory.copyWith(extra: currentExtra);
    _markDirty();
  }

  void _updatePathological(List<String> selected) {
    _pathologicalSelected = selected;
    final currentExtra = Map<String, dynamic>.from(_draftHistory.extra);
    currentExtra[HistoryExtraKeys.personalPathologicalHistory] = selected;
    _draftHistory = _draftHistory.copyWith(extra: currentExtra);
    _markDirty();
  }

  Future<void> saveIfDirty() async {
    if (!_isDirty || _client == null) return;
    Client? savedClient;
    await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
      savedClient = applyBackgroundTabPatch(
        activeClient: prev,
        baseHistory: _baseHistory,
        draftHistory: _draftHistory,
      );
      return savedClient!;
    });
    if (savedClient != null) {
      _loadFromClient(savedClient!);
    }
  }

  void resetDrafts() {
    final client = ref.read(clientsProvider).value?.activeClient ?? _client;
    if (client == null) return;
    _client = client;
    _loadFromClient(client);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveDraft() async {
    if (_client == null) return;
    Client? savedClient;
    try {
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        savedClient = applyBackgroundTabPatch(
          activeClient: prev,
          baseHistory: _baseHistory,
          draftHistory: _draftHistory,
        );
        return savedClient!;
      });

      if (!mounted) return;
      if (savedClient != null) {
        _loadFromClient(savedClient!);
        setState(() {});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Antecedentes guardados'),
          backgroundColor: kPrimaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Solo recargar si cambia el cliente activo (diferente ID = diferente paciente).
    // NO recargar cuando otra sección (antropometría, nutrición, etc.) guarda datos
    // del mismo cliente — eso sobreescribiría el borrador de historia clínica.
    ref.listen(clientsProvider, (previous, next) {
      final nextClient = next.value?.activeClient;
      if (nextClient == null) return;

      // Solo recargar si cambió el ID del cliente activo o si no hay cliente cargado aún
      final current = _client;
      final shouldReload =
          current == null ||
          current.id != nextClient.id ||
          (!_isDirty && _loadedRevision != backgroundTabRevision(nextClient));
      _client = nextClient;
      if (shouldReload) {
        _loadFromClient(nextClient);
        if (mounted) setState(() {});
      }
    });

    // Carga inicial si el widget se construye sin cliente (initState llegó primero sin datos)
    if (_client == null) {
      final client = ref.read(clientsProvider).value?.activeClient;
      if (client != null) {
        _client = client;
        _loadFromClient(client);
      }
    }

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
                ChipGroupCard(
                  title: 'Antecedentes Heredofamiliares',
                  icon: Icons.family_restroom,
                  accentColor: kPrimaryColor,
                  options: _hereditaryOptions,
                  selectedOptions: _hereditarySelected,
                  onUpdate: (List<String> selected) {
                    _updateHereditary(selected);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                ChipGroupCard(
                  title: 'Antecedentes Patológicos Personales',
                  icon: Icons.medical_information,
                  accentColor: Colors.orange,
                  options: _pathologicalOptions,
                  selectedOptions: _pathologicalSelected,
                  onUpdate: (List<String> selected) {
                    _updatePathological(selected);
                    setState(() {});
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _saveDraft,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Antecedentes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: kTextColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
