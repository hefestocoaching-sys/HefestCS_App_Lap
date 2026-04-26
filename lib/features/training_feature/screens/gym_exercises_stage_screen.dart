import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_flow_stage.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart';
import 'package:hcs_app_lap/utils/theme.dart';

enum _PreferenceKind { frequent, preferred, avoid }

class GymExercisesStageScreen extends ConsumerStatefulWidget {
  final VoidCallback? onContinue;
  final bool isLocked;

  const GymExercisesStageScreen({
    this.onContinue,
    this.isLocked = false,
    super.key,
  });

  @override
  ConsumerState<GymExercisesStageScreen> createState() =>
      _GymExercisesStageScreenState();
}

class _GymExercisesStageScreenState
    extends ConsumerState<GymExercisesStageScreen> {
  final Map<String, List<Exercise>> _catalogByGroup =
      <String, List<Exercise>>{};
  final Map<String, ExercisePreferenceBucket> _draftByGroup =
      <String, ExercisePreferenceBucket>{};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) {
      return _buildLockedView();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kWarningSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kWarningColor.withValues(alpha: 0.7)),
              ),
              child: Text(_error!, style: const TextStyle(color: kTextColor)),
            ),
          ...kExercisePreferenceGroups.map(_buildGroupCard),
          const SizedBox(height: 24),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Future<void> _bootstrap() async {
    try {
      await ExerciseCatalogV3.ensureLoaded();
      final activeClient = ref.read(clientsProvider).value?.activeClient;
      final raw = activeClient
          ?.training
          .extra[TrainingExtraKeys.exercisePreferencesByMuscle];
      final persisted = ExercisePreferencesByMuscle.fromDynamic(raw);

      for (final group in kExercisePreferenceGroups) {
        final exercises = ExerciseCatalogV3.getByMuscleKeys(
          group.catalogMuscleKeys,
        );
        final seen = <String>{};
        final unique = exercises.where((e) => seen.add(e.id)).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        _catalogByGroup[group.id] = unique;
        _draftByGroup[group.id] = persisted.bucketForGroup(group);
      }
    } catch (_) {
      _error = 'No se pudo cargar el catalogo de ejercicios.';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  bool get _isValidDraft {
    return _draftByGroup.values.any((bucket) => bucket.hasAny);
  }

  Future<void> _saveAndContinue() async {
    if (!_isValidDraft || _isSaving) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final byMuscle = <String, ExercisePreferenceBucket>{};
      for (final group in kExercisePreferenceGroups) {
        final bucket =
            _draftByGroup[group.id] ?? const ExercisePreferenceBucket();
        if (!bucket.hasAny) continue;
        for (final muscleKey in group.persistMuscleKeys) {
          byMuscle[muscleKey] = bucket;
        }
      }
      final payload = ExercisePreferencesByMuscle(byMuscle: byMuscle).toJson();

      await ref.read(clientsProvider.notifier).updateActiveClient((current) {
        final extra = Map<String, dynamic>.from(current.training.extra);
        extra[TrainingExtraKeys.exercisePreferencesByMuscle] = payload;
        extra[TrainingExtraKeys.trainingFlowStage] =
            TrainingFlowStage.plan.name;

        return current.copyWith(
          training: current.training.copyWith(extra: extra),
        );
      });

      if (!mounted) return;
      widget.onContinue?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron guardar las preferencias. Intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleExercise({
    required String groupId,
    required String exerciseId,
    required _PreferenceKind kind,
    required bool selected,
  }) {
    final current = _draftByGroup[groupId] ?? const ExercisePreferenceBucket();
    final frequent = Set<String>.from(current.frequent);
    final preferred = Set<String>.from(current.preferred);
    final avoid = Set<String>.from(current.avoid);

    void addTo(Set<String> target) {
      target.add(exerciseId);
      frequent.remove(exerciseId);
      preferred.remove(exerciseId);
      avoid.remove(exerciseId);
      target.add(exerciseId);
    }

    switch (kind) {
      case _PreferenceKind.frequent:
        if (selected) {
          addTo(frequent);
        } else {
          frequent.remove(exerciseId);
        }
        break;
      case _PreferenceKind.preferred:
        if (selected) {
          addTo(preferred);
        } else {
          preferred.remove(exerciseId);
        }
        break;
      case _PreferenceKind.avoid:
        if (selected) {
          addTo(avoid);
        } else {
          avoid.remove(exerciseId);
        }
        break;
    }

    setState(() {
      _draftByGroup[groupId] = ExercisePreferenceBucket(
        frequent: frequent,
        preferred: preferred,
        avoid: avoid,
      );
    });
  }

  Widget _buildLockedView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.lock_outline, size: 48, color: kTextColorSecondary),
          SizedBox(height: 16),
          Text(
            'Completa Intensidad primero',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Necesitas definir los porcentajes de intensidad (heavy, medium, light) para acceder a esta etapa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferencias de ejercicios',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Registra ejercicios frecuentes, preferidos y a evitar por grupo muscular.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: kTextColorSecondary),
        ),
      ],
    );
  }

  Widget _buildGroupCard(ExercisePreferenceGroup group) {
    final catalog = _catalogByGroup[group.id] ?? const <Exercise>[];
    final bucket = _draftByGroup[group.id] ?? const ExercisePreferenceBucket();

    return Card(
      color: kCardColor.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            group.label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          subtitle: Text(
            'Frecuentes: ${bucket.frequent.length} | Preferidos: ${bucket.preferred.length} | Evitar: ${bucket.avoid.length}',
            style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
          ),
          children: [
            if (catalog.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Sin ejercicios disponibles para este grupo en el catalogo.',
                  style: TextStyle(color: kTextColorSecondary),
                ),
              )
            else ...[
              _buildCategorySection(
                title: 'Frecuente',
                color: kInfoColor,
                groupId: group.id,
                kind: _PreferenceKind.frequent,
                selectedIds: bucket.frequent,
                catalog: catalog,
              ),
              const SizedBox(height: 12),
              _buildCategorySection(
                title: 'Preferido',
                color: kSuccessColor,
                groupId: group.id,
                kind: _PreferenceKind.preferred,
                selectedIds: bucket.preferred,
                catalog: catalog,
              ),
              const SizedBox(height: 12),
              _buildCategorySection(
                title: 'Evitar',
                color: kWarningColor,
                groupId: group.id,
                kind: _PreferenceKind.avoid,
                selectedIds: bucket.avoid,
                catalog: catalog,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required Color color,
    required String groupId,
    required _PreferenceKind kind,
    required Set<String> selectedIds,
    required List<Exercise> catalog,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: catalog.map((exercise) {
            final selected = selectedIds.contains(exercise.id);
            return FilterChip(
              selectedColor: color.withValues(alpha: 0.2),
              checkmarkColor: color,
              selected: selected,
              label: Text(exercise.name, style: const TextStyle(fontSize: 12)),
              onSelected: (value) {
                _toggleExercise(
                  groupId: groupId,
                  exerciseId: exercise.id,
                  kind: kind,
                  selected: value,
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isValidDraft && !_isSaving ? _saveAndContinue : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: kPrimaryColor,
        ),
        child: Text(
          _isSaving
              ? 'Guardando...'
              : 'Guardar preferencias y continuar a Plan',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
