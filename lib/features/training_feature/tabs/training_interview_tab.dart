import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/landmark_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_flow_stage.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/domain/interview_help_content.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_field_definitions.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_form_state.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_validator.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_pipeline_guard.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_volume_computation_helper.dart';
import 'package:hcs_app_lap/features/training_feature/services/training_profile_form_mapper.dart';
import 'package:hcs_app_lap/ui/clinic_section_surface.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/interview_field_label.dart';

class TrainingInterviewTab extends ConsumerStatefulWidget {
  const TrainingInterviewTab({super.key});

  @override
  ConsumerState<TrainingInterviewTab> createState() =>
      TrainingInterviewTabState();
}

class TrainingInterviewTabState extends ConsumerState<TrainingInterviewTab>
    with AutomaticKeepAliveClientMixin {
  final TrainingInterviewFormState _formState = TrainingInterviewFormState();

  Client? _client;
  bool _isDirty = false;
  bool _initialized = false;
  String? _loadedClientId;
  bool _showValidationErrors = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      _client = client;
      _loadFromClient(client);
    }
  }

  @override
  void dispose() {
    _formState.dispose();
    super.dispose();
  }

  void _loadFromClient(Client client) {
    _formState.loadFromProfile(client.training);
    _showValidationErrors = false;
    _isDirty = false;
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<Client?> saveIfDirty() async {
    if (!_isDirty || _client == null) return null;

    final validationError = _formState.validateLocal();
    if (validationError != null) {
      if (mounted) {
        setState(() => _showValidationErrors = true);
      }
      return null;
    }

    final currentClient = _client!;
    final values = _formState.toValues(
      sex: currentClient.training.gender ?? currentClient.profile.gender,
    );
    final derivedLevel =
        values.trainingLevelDerived ??
        (values.trainingMonths == null
            ? null
            : deriveTrainingLevelFromMonths(values.trainingMonths!));
    if (derivedLevel == null) {
      if (mounted) {
        setState(() => _showValidationErrors = true);
      }
      return null;
    }

    final volume = computeTrainingVolume(
      level: derivedLevel,
      input: TrainingVolumeComputationInput(
        sex: values.sex,
        ageYears: values.ageYears ?? 0,
        heightCm: values.heightCm,
        weightKg: values.weightKg,
        strengthLevelClass: values.strengthLevelClass,
        workCapacityScore: values.workCapacityScore,
        recoveryHistoryScore: values.recoveryHistoryScore,
        externalRecoverySupport: values.externalRecoverySupport,
        programNoveltyClass: values.programNoveltyClass,
        externalPhysicalStressLevel: values.externalPhysicalStressLevel,
        nonPhysicalStressLevel2: values.nonPhysicalStressLevel2,
        restQuality2: values.restQuality2,
        dietHabitsClass: values.dietHabitsClass,
        usesAnabolics: values.usesAnabolics ?? false,
      ),
    );

    final updatedTraining = TrainingProfileFormMapper.apply(
      base: currentClient.training,
      input: values,
      volume: volume,
    );
    final updatedClient = currentClient.copyWith(training: updatedTraining);

    final interviewStatus = evaluateTrainingInterview(updatedTraining.extra);
    if (interviewStatus != TrainingInterviewStatus.valid) {
      if (mounted) {
        setState(() => _showValidationErrors = true);
      }
      return null;
    }

    try {
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        return prev.copyWith(training: updatedClient.training);
      });

      if (!mounted) return updatedClient;

      await _computeAndPersistLandmarks();
      _isDirty = false;
      _showValidationErrors = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrevista guardada. Continúa con Landmarks.'),
            backgroundColor: kPrimaryColor,
          ),
        );
      }

      return updatedClient;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar entrevista: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> commit() async {
    await _onSavePressed();
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

  Future<void> _onSavePressed() async {
    if (_client == null) return;
    await saveIfDirty();
  }

  Future<void> _computeAndPersistLandmarks() async {
    await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
      final extra = Map<String, dynamic>.from(prev.training.extra);
      final landmarksByMuscle = LandmarkEngine.calculateFromProfile(
        prev.training,
      );

      extra[TrainingExtraKeys.muscleLandmarks] =
          LandmarkEngine.serializeByCanonicalKey(landmarksByMuscle);
      extra.remove(TrainingExtraKeys.mevByMuscle);
      extra.remove(TrainingExtraKeys.mrvByMuscle);
      extra[TrainingExtraKeys.interviewPipelineSignature] =
          TrainingPipelineGuard.computeInterviewSignature(extra);

      extra.putIfAbsent(TrainingExtraKeys.seriesTypePercentSplit, () {
        return {'heavy': 20, 'medium': 60, 'light': 20};
      });

      extra[TrainingExtraKeys.trainingFlowStage] =
          TrainingFlowStage.landmarks.name;

      return prev.copyWith(training: prev.training.copyWith(extra: extra));
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen(clientsProvider, (previous, next) {
      final nextClient = next.value?.activeClient;
      if (nextClient == null) return;

      final isDifferentClient = _loadedClientId != nextClient.id;
      if (!_initialized || isDifferentClient) {
        _client = nextClient;
        _loadFromClient(nextClient);
        _loadedClientId = nextClient.id;
        _initialized = true;
        setState(() {});
      } else {
        _client = nextClient;
      }
    });

    final detectedLevelText =
        TrainingInterviewFieldDefinitions.detectedLevelLabel(
          _formState.trainingLevelDerived?.name,
        );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClinicSectionSurface(
              icon: Icons.person,
              title: TrainingInterviewFieldDefinitions.baseSectionTitle,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _NumberInputField(
                    label: TrainingInterviewFieldDefinitions.heightLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.heightCm],
                    controller: _formState.heightCmController,
                    width: 280,
                    errorText:
                        _showValidationErrors &&
                            (_formState.heightCm == null ||
                                _formState.heightCm! <= 0)
                        ? 'Requerido'
                        : null,
                    onChanged: (_) => _markDirty(),
                  ),
                  _NumberInputField(
                    label: TrainingInterviewFieldDefinitions.weightLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.weightKg],
                    controller: _formState.weightKgController,
                    width: 280,
                    errorText:
                        _showValidationErrors &&
                            (_formState.weightKg == null ||
                                _formState.weightKg! <= 0)
                        ? 'Requerido'
                        : null,
                    onChanged: (_) => _markDirty(),
                  ),
                  _NumberInputField(
                    label: TrainingInterviewFieldDefinitions.ageLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.ageYears],
                    controller: _formState.ageYearsController,
                    width: 220,
                    errorText:
                        _showValidationErrors &&
                            (_formState.ageYears == null ||
                                _formState.ageYears! <= 0)
                        ? 'Requerido'
                        : null,
                    onChanged: (_) => _markDirty(),
                  ),
                  _NumberInputField(
                    label: TrainingInterviewFieldDefinitions.trainingTimeLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.trainingMonths],
                    controller: _formState.trainingDurationController,
                    width: 420,
                    errorText:
                        _showValidationErrors &&
                            (_formState.trainingMonths == null ||
                                _formState.trainingMonths! <= 0)
                        ? 'Requerido'
                        : null,
                    onChanged: (value) {
                      _formState.setTrainingDurationFromText(value);
                      setState(() {});
                      _markDirty();
                    },
                  ),
                  _DropdownField<TrainingDurationUnit>(
                    label: TrainingInterviewFieldDefinitions.trainingUnitLabel,
                    helpContent: null,
                    value: _formState.trainingDurationUnit,
                    width: 180,
                    options: const [
                      InterviewOption(
                        value: TrainingDurationUnit.months,
                        label: 'Meses',
                      ),
                      InterviewOption(
                        value: TrainingDurationUnit.years,
                        label: 'Años',
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _updateTrainingDurationUnit(value);
                    },
                  ),
                  SizedBox(
                    width: 360,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${TrainingInterviewFieldDefinitions.trainingDetectedLabel}: $detectedLevelText',
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ClinicSectionSurface(
              icon: Icons.tune,
              title: TrainingInterviewFieldDefinitions.volumeSectionTitle,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _DropdownField<String>(
                    label: TrainingInterviewFieldDefinitions.strengthLevelLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.strengthLevelClass],
                    value: _formState.strengthLevelClass,
                    width: 280,
                    options: const [
                      InterviewOption(value: 'B', label: 'Baja'),
                      InterviewOption(value: 'M', label: 'Media'),
                      InterviewOption(value: 'A', label: 'Alta'),
                      InterviewOption(value: 'MA', label: 'Muy alta'),
                    ],
                    onChanged: (value) {
                      setState(() => _formState.strengthLevelClass = value);
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.strengthLevelClass == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<int>(
                    label: TrainingInterviewFieldDefinitions.workCapacityLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.workCapacityScore],
                    value: _formState.workCapacityScore,
                    width: 220,
                    options: const [
                      InterviewOption(value: 1, label: '1'),
                      InterviewOption(value: 2, label: '2'),
                      InterviewOption(value: 3, label: '3'),
                      InterviewOption(value: 4, label: '4'),
                      InterviewOption(value: 5, label: '5'),
                    ],
                    onChanged: (value) {
                      setState(() => _formState.workCapacityScore = value);
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.workCapacityScore == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<int>(
                    label:
                        TrainingInterviewFieldDefinitions.recoveryHistoryLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.recoveryHistoryScore],
                    value: _formState.recoveryHistoryScore,
                    width: 220,
                    options: const [
                      InterviewOption(value: 1, label: '1'),
                      InterviewOption(value: 2, label: '2'),
                      InterviewOption(value: 3, label: '3'),
                      InterviewOption(value: 4, label: '4'),
                      InterviewOption(value: 5, label: '5'),
                    ],
                    onChanged: (value) {
                      setState(() => _formState.recoveryHistoryScore = value);
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.recoveryHistoryScore == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<bool>(
                    label: TrainingInterviewFieldDefinitions
                        .externalRecoverySupportLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.externalRecoverySupport],
                    value: _formState.externalRecoverySupport,
                    width: 280,
                    options: const [
                      InterviewOption(value: true, label: 'Sí'),
                      InterviewOption(value: false, label: 'No'),
                    ],
                    onChanged: (value) {
                      setState(
                        () => _formState.externalRecoverySupport = value,
                      );
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.externalRecoverySupport == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<String>(
                    label:
                        TrainingInterviewFieldDefinitions.programNoveltyLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.programNoveltyClass],
                    value: _formState.programNoveltyClass,
                    width: 320,
                    options: const [
                      InterviewOption(value: 'N', label: 'Nulo'),
                      InterviewOption(value: 'B', label: 'Bajo'),
                      InterviewOption(value: 'I', label: 'Intermedio'),
                      InterviewOption(value: 'A', label: 'Alto'),
                    ],
                    onChanged: (value) {
                      setState(() => _formState.programNoveltyClass = value);
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.programNoveltyClass == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<String>(
                    label: TrainingInterviewFieldDefinitions
                        .externalPhysicalStressLabel,
                    helpContent:
                        InterviewHelpCatalog.byKey[InterviewHelpCatalog
                            .externalPhysicalStressLevel],
                    value: _formState.externalPhysicalStressLevel,
                    width: 400,
                    options: const [
                      InterviewOption(value: 'N', label: 'Nulo'),
                      InterviewOption(value: 'B', label: 'Bajo'),
                      InterviewOption(value: 'I', label: 'Intermedio'),
                      InterviewOption(value: 'A', label: 'Alto'),
                    ],
                    onChanged: (value) {
                      setState(
                        () => _formState.externalPhysicalStressLevel = value,
                      );
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.externalPhysicalStressLevel == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<String>(
                    label: TrainingInterviewFieldDefinitions
                        .nonPhysicalStressLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.nonPhysicalStressLevel2],
                    value: _formState.nonPhysicalStressLevel2,
                    width: 420,
                    options: const [
                      InterviewOption(value: 'B', label: 'Bajo'),
                      InterviewOption(value: 'P', label: 'Promedio'),
                      InterviewOption(value: 'A', label: 'Alto'),
                    ],
                    onChanged: (value) {
                      setState(
                        () => _formState.nonPhysicalStressLevel2 = value,
                      );
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.nonPhysicalStressLevel2 == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<String>(
                    label: TrainingInterviewFieldDefinitions.restQualityLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.restQuality2],
                    value: _formState.restQuality2,
                    width: 320,
                    options: const [
                      InterviewOption(value: 'B', label: 'Bajo'),
                      InterviewOption(value: 'P', label: 'Promedio'),
                      InterviewOption(value: 'A', label: 'Alto'),
                    ],
                    onChanged: (value) {
                      setState(() => _formState.restQuality2 = value);
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors && _formState.restQuality2 == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<String>(
                    label: TrainingInterviewFieldDefinitions.dietHabitsLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.dietHabitsClass],
                    value: _formState.dietHabitsClass,
                    width: 320,
                    options: const [
                      InterviewOption(value: 'SCA', label: 'Superávit alto'),
                      InterviewOption(value: 'SCM', label: 'Superávit medio'),
                      InterviewOption(value: 'SCB', label: 'Superávit bajo'),
                      InterviewOption(value: 'ISO', label: 'Mantenimiento'),
                      InterviewOption(value: 'DCB', label: 'Déficit bajo'),
                      InterviewOption(value: 'DCM', label: 'Déficit medio'),
                      InterviewOption(value: 'DCA', label: 'Déficit alto'),
                    ],
                    onChanged: (value) {
                      setState(() => _formState.dietHabitsClass = value);
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.dietHabitsClass == null
                        ? 'Requerido'
                        : null,
                  ),
                  _DropdownField<bool>(
                    label: TrainingInterviewFieldDefinitions.usesAnabolicsLabel,
                    helpContent: InterviewHelpCatalog
                        .byKey[InterviewHelpCatalog.usesAnabolics],
                    value: _formState.usesAnabolics,
                    width: 240,
                    options: const [
                      InterviewOption(value: true, label: 'Sí'),
                      InterviewOption(value: false, label: 'No'),
                    ],
                    onChanged: (value) {
                      setState(() => _formState.usesAnabolics = value);
                      _markDirty();
                    },
                    errorText:
                        _showValidationErrors &&
                            _formState.usesAnabolics == null
                        ? 'Requerido'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _onSavePressed,
                icon: const Icon(Icons.save),
                label: const Text('Guardar entrevista'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _updateTrainingDurationUnit(TrainingDurationUnit unit) {
    final currentMonths = _formState.trainingMonths;
    setState(() {
      _formState.setTrainingDurationUnit(unit);
      if (currentMonths != null && currentMonths > 0) {
        if (unit == TrainingDurationUnit.months) {
          _formState.trainingDurationController.text = currentMonths.toString();
        } else {
          final years = currentMonths / 12;
          _formState.trainingDurationController.text = years % 1 == 0
              ? years.toStringAsFixed(0)
              : years.toStringAsFixed(1);
        }
        _formState.setTrainingDurationFromText(
          _formState.trainingDurationController.text,
        );
      }
    });
    _markDirty();
  }
}

class _NumberInputField extends StatelessWidget {
  final String label;
  final InterviewHelpContent? helpContent;
  final TextEditingController controller;
  final double width;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _NumberInputField({
    required this.label,
    required this.helpContent,
    required this.controller,
    required this.width,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InterviewFieldLabel(label: label, helpContent: helpContent),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final InterviewHelpContent? helpContent;
  final T? value;
  final double width;
  final List<InterviewOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? errorText;

  const _DropdownField({
    required this.label,
    required this.helpContent,
    required this.value,
    required this.width,
    required this.options,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InterviewFieldLabel(label: label, helpContent: helpContent),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            items: [
              for (final option in options)
                DropdownMenuItem<T>(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: onChanged,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
          ),
        ],
      ),
    );
  }
}
