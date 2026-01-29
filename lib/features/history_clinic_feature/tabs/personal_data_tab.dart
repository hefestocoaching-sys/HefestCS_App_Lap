// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/enums/client_level.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/ui/clinic_section_surface.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/invitation_code_dialog.dart';
import 'package:hcs_app_lap/utils/widgets/shared_form_widgets.dart';
import 'package:hcs_app_lap/utils/invitation_code_generator.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

class PersonalDataTab extends ConsumerStatefulWidget {
  const PersonalDataTab({super.key});

  @override
  PersonalDataTabState createState() => PersonalDataTabState();
}

class PersonalDataTabState extends ConsumerState<PersonalDataTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Client? _client;
  late ClientProfile _draftProfile;
  late NutritionSettings _draftNutrition;

  bool _isDirty = false;
  bool _isCustomObjective = false;
  bool _controllersReady = false;
  bool _justSaved = false; // Previene reload desde BD justo después de guardar

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _paisController;
  late TextEditingController _ocupacionController;
  late TextEditingController _objetivoController;
  late TextEditingController _terminoPlanController;
  late TextEditingController _edadController;
  late TextEditingController _fechaNacimientoController;
  late TextEditingController _inicioPlanController;

  final List<String> _countryOptions = const [
    'México',
    'España',
    'Argentina',
    'Colombia',
    'Chile',
    'Perú',
    'Estados Unidos',
    'Otro',
  ];

  final List<ClientLevel> _clientLevelOptions = ClientLevel.values;

  final List<String> _objectiveOptions = const [
    'Pérdida de grasa',
    'Ganancia muscular',
    'Recomposición',
    'Rendimiento',
    'Salud general',
    'Otro',
  ];

  final List<String> _planTypeOptions = const [
    'Mensual',
    'Bimestral',
    'Trimestral',
    'Semestral',
    'Anual',
  ];

  @override
  void initState() {
    super.initState();
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      _client = client;
      _loadFromClient(client);
    } else {
      // Inicializar controladores vacíos si no hay cliente
      _nombreController = TextEditingController();
      _emailController = TextEditingController();
      _telefonoController = TextEditingController();
      _paisController = TextEditingController();
      _ocupacionController = TextEditingController();
      _objetivoController = TextEditingController();
      _terminoPlanController = TextEditingController();
      _edadController = TextEditingController();
      _fechaNacimientoController = TextEditingController();
      _inicioPlanController = TextEditingController();
      _controllersReady = true;
    }
  }

  @override
  void dispose() {
    if (_controllersReady) {
      _nombreController.dispose();
      _emailController.dispose();
      _telefonoController.dispose();
      _paisController.dispose();
      _ocupacionController.dispose();
      _objetivoController.dispose();
      _terminoPlanController.dispose();
      _edadController.dispose();
      _fechaNacimientoController.dispose();
      _inicioPlanController.dispose();
    }
    super.dispose();
  }

  void _loadFromClient(Client client) {
    _draftProfile = client.profile;
    _draftNutrition = client.nutrition;

    _nombreController = TextEditingController(text: _draftProfile.fullName);
    _emailController = TextEditingController(text: _draftProfile.email);
    _telefonoController = TextEditingController(text: _draftProfile.phone);
    _paisController = TextEditingController(text: _draftProfile.country);
    _ocupacionController = TextEditingController(
      text: _draftProfile.occupation,
    );

    _isCustomObjective = !_objectiveOptions.contains(_draftProfile.objective);
    _objetivoController = TextEditingController(
      text: _isCustomObjective ? _draftProfile.objective : '',
    );

    _fechaNacimientoController = TextEditingController(
      text: _draftProfile.birthDate != null
          ? _dateFormat.format(_draftProfile.birthDate!)
          : '',
    );

    _inicioPlanController = TextEditingController(
      text: _draftNutrition.planStartDate != null
          ? _dateFormat.format(_draftNutrition.planStartDate!)
          : '',
    );

    _terminoPlanController = TextEditingController(
      text: _draftNutrition.planEndDate != null
          ? _dateFormat.format(_draftNutrition.planEndDate!)
          : '',
    );

    final age = _draftProfile.age ?? _calculateAge(_draftProfile.birthDate);
    _edadController = TextEditingController(
      text: age != null ? age.toString() : '',
    );

    _controllersReady = true;
    _isDirty = false;
  }

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  T? _getSafeValue<T>(T? value, List<T> options) =>
      options.contains(value) ? value : null;

  DateTime? _calculateEndDate(DateTime? startDate, String? planType) {
    if (startDate == null || planType == null) return null;
    switch (planType) {
      case 'Mensual':
        return startDate.add(const Duration(days: 30));
      case 'Bimestral':
        return startDate.add(const Duration(days: 60));
      case 'Trimestral':
        return startDate.add(const Duration(days: 90));
      case 'Semestral':
        return startDate.add(const Duration(days: 180));
      case 'Anual':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      default:
        return null;
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isBirthDate,
  }) async {
    final initialDate = isBirthDate
        ? (_draftProfile.birthDate ?? DateTime.now())
        : (_draftNutrition.planStartDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    if (isBirthDate) {
      final age = _calculateAge(picked);
      _draftProfile = _draftProfile.copyWith(birthDate: picked, age: age);
      _edadController.text = age?.toString() ?? '';
      _fechaNacimientoController.text = _dateFormat.format(picked);
    } else {
      final endDate = _calculateEndDate(picked, _draftNutrition.planType);
      _draftNutrition = _draftNutrition.copyWith(
        planStartDate: picked,
        planEndDate: endDate,
      );
      _inicioPlanController.text = _dateFormat.format(picked);
      _terminoPlanController.text = endDate != null
          ? _dateFormat.format(endDate)
          : '';
    }
    _markDirty();
    setState(() {});
  }

  void _renewPlan() {
    final now = DateTime.now();
    final endDate = _calculateEndDate(now, _draftNutrition.planType);
    _draftNutrition = _draftNutrition.copyWith(
      planStartDate: now,
      planEndDate: endDate,
    );
    _inicioPlanController.text = _dateFormat.format(now);
    _terminoPlanController.text = endDate != null
        ? _dateFormat.format(endDate)
        : '';
    _markDirty();
    setState(() {});
  }

  void _applyControllerChanges() {
    final objectiveValue = _isCustomObjective
        ? _objetivoController.text
        : (_getSafeValue(_draftProfile.objective, _objectiveOptions) ??
              _objectiveOptions.first);

    _draftProfile = _draftProfile.copyWith(
      fullName: _nombreController.text,
      email: _emailController.text,
      phone: _telefonoController.text,
      country: _paisController.text,
      occupation: _ocupacionController.text,
      objective: objectiveValue,
    );
  }

  Future<Client?> saveIfDirty() async {
    if (!_isDirty || _client == null) return null;
    _applyControllerChanges();
    final updated = _client!.copyWith(
      profile: _draftProfile,
      nutrition: _draftNutrition,
    );
    _client = updated;
    _isDirty = false;
    return updated;
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
    final client = _client;
    if (client == null) return;
    _applyControllerChanges();

    final invitationCode = (client.invitationCode?.isNotEmpty ?? false)
        ? client.invitationCode
        : InvitationCodeGenerator.generate();

    final updatedClient = client.copyWith(
      profile: _draftProfile,
      nutrition: _draftNutrition,
      invitationCode: invitationCode,
    );

    _client = updatedClient;
    _justSaved = true; // ✅ Flag para prevenir reload desde BD
    try {
      await ref
          .read(clientsProvider.notifier)
          .updateActiveClient((prev) => updatedClient.copyWith(id: prev.id));
    } finally {
      _justSaved = false; // ✅ Reset flag después de guardar (garantizado)
    }
    _isDirty = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos personales guardados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen(clientsProvider, (previous, next) {
      final nextClient = next.value?.activeClient;
      if (nextClient == null) return;
      final isDifferentClient = _client?.id != nextClient.id;
      // ✅ BUGFIX: Ignora reload si acabamos de guardar (_justSaved=true)
      // Esto previene que datos recién guardados se sobrescriban con versión anterior de BD
      if (_justSaved) return;
      if (isDifferentClient || !_isDirty) {
        _client = nextClient;
        _loadFromClient(nextClient);
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
        _loadFromClient(client);
      }
    }

    final safeCountryValue = _getSafeValue(
      _draftProfile.country.isEmpty ? null : _draftProfile.country,
      _countryOptions,
    );
    final safeLevelValue = _getSafeValue(
      _draftProfile.level,
      _clientLevelOptions,
    );
    final safeObjectiveValue = _isCustomObjective
        ? 'Otro'
        : _getSafeValue(_draftProfile.objective, _objectiveOptions);
    final safePlanValue = _getSafeValue(
      _draftNutrition.planType,
      _planTypeOptions,
    );
    final safeGenderValue = _draftProfile.gender == Gender.female
        ? 'Femenino'
        : _draftProfile.gender == Gender.male
        ? 'Masculino'
        : null;

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClinicSectionSurface(
                  icon: Icons.person,
                  title: 'Datos Personales',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GlassTextField(
                              controller: _nombreController,
                              label: 'Nombre completo',
                              onChanged: (_) => _markDirty(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassTextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => _markDirty(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassTextField(
                              controller: _telefonoController,
                              label: 'Teléfono',
                              keyboardType: TextInputType.phone,
                              onChanged: (_) => _markDirty(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassDropdown<String>(
                              label: 'País',
                              value: safeCountryValue,
                              items: _countryOptions,
                              onChanged: (v) {
                                if (v != null) {
                                  _paisController.text = v;
                                  _draftProfile = _draftProfile.copyWith(
                                    country: v,
                                  );
                                  _markDirty();
                                  setState(() {});
                                }
                              },
                              itemLabelBuilder: (item) => item,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassTextField(
                              controller: _ocupacionController,
                              label: 'Ocupación',
                              onChanged: (_) => _markDirty(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassDropdown<ClientLevel>(
                              label: 'Nivel de Cliente',
                              value: safeLevelValue,
                              items: _clientLevelOptions,
                              onChanged: (v) {
                                if (v != null) {
                                  _draftProfile = _draftProfile.copyWith(
                                    level: v,
                                  );
                                  _markDirty();
                                  setState(() {});
                                }
                              },
                              itemLabelBuilder: (item) => item.label,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassTextField(
                              controller: _fechaNacimientoController,
                              label: 'Fecha de nacimiento',
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(context, isBirthDate: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassTextField(
                              controller: _edadController,
                              label: 'Edad (años)',
                              keyboardType: TextInputType.number,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassDropdown<String>(
                              label: 'Género',
                              value: safeGenderValue,
                              items: const ['Masculino', 'Femenino'],
                              onChanged: (v) {
                                if (v != null) {
                                  final g = v == 'Femenino'
                                      ? Gender.female
                                      : Gender.male;
                                  _draftProfile = _draftProfile.copyWith(
                                    gender: g,
                                  );
                                  _markDirty();
                                  setState(() {});
                                }
                              },
                              itemLabelBuilder: (item) => item,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ClinicSectionSurface(
                  icon: Icons.flag,
                  title: 'Objetivo y Perfil',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GlassDropdown<String>(
                              label: 'Objetivo',
                              value: safeObjectiveValue,
                              items: _objectiveOptions,
                              onChanged: (value) {
                                if (value == null) return;
                                _isCustomObjective = value == 'Otro';
                                _draftProfile = _draftProfile.copyWith(
                                  objective: value,
                                );
                                _objetivoController.text = value;
                                _markDirty();
                                setState(() {});
                              },
                              itemLabelBuilder: (item) => item,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_isCustomObjective)
                            Expanded(
                              child: GlassTextField(
                                controller: _objetivoController,
                                label: 'Objetivo personalizado',
                                onChanged: (_) => _markDirty(),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassDropdown<String>(
                              label: 'Tipo de plan',
                              value: safePlanValue,
                              items: _planTypeOptions,
                              onChanged: (value) {
                                if (value == null) return;
                                _draftNutrition = _draftNutrition.copyWith(
                                  planType: value,
                                );
                                final endDate = _calculateEndDate(
                                  _draftNutrition.planStartDate,
                                  value,
                                );
                                _draftNutrition = _draftNutrition.copyWith(
                                  planEndDate: endDate,
                                );
                                _terminoPlanController.text = endDate != null
                                    ? _dateFormat.format(endDate)
                                    : '';
                                _markDirty();
                                setState(() {});
                              },
                              itemLabelBuilder: (item) => item,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassTextField(
                              controller: _inicioPlanController,
                              label: 'Inicio de plan',
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(context, isBirthDate: false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassTextField(
                              controller: _terminoPlanController,
                              label: 'Fecha de término',
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _renewPlan,
                            icon: const Icon(Icons.autorenew),
                            label: const Text('Renovar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: kTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveDraft,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar datos personales'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: kTextColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isDirty ? resetDrafts : null,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restablecer borradores'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor.withValues(alpha: 0.2),
                        foregroundColor: kTextColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ctx = context;
                      await _saveDraft();
                      if (mounted) {
                        InvitationCodeDialog.show(
                          ctx,
                          invitationCode: _client?.invitationCode ?? '',
                          clientName: _draftProfile.fullName,
                        );
                      }
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Ver código de invitación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAppBarColor,
                      foregroundColor: kTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
