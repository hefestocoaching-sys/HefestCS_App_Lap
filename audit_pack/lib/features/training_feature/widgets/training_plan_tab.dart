import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/training/split_templates.dart';
import 'package:hcs_app_lap/features/training_feature/services/training_plan_builder.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/exercise_block_widget.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class _DayPlan {
  final int dayNumber;
  final bool isRest;
  final List<ExerciseBlock> blocks;

  const _DayPlan({
    required this.dayNumber,
    required this.isRest,
    required this.blocks,
  });
}

class _WeekPlan {
  final int weekNumber;
  final List<_DayPlan> days;

  const _WeekPlan({required this.weekNumber, required this.days});
}

/// Tab 3 — Generador de Plan de Entrenamiento (4 Semanas)
///
/// PROPÓSITO:
/// Generar un plan de entrenamiento profesional, estructurado y listo para
/// ejecutar, basado en:
/// - Plantilla de split (estructura días/músculos)
/// - VOP de Tab 2 (volumen semanal)
/// - Bitácora (adaptación desde semana 2)
/// - Distribución H/M/L de Tab 2
///
/// CARACTERÍSTICAS:
/// 1. Selector de días/semana (3-6)
/// 2. Selector dependiente de plantilla
/// 3. Generación automática de 4 semanas
/// 4. Adaptación conservadora por bitácora
/// 5. Visualización profesional del plan
/// 6. Exportación a PDF
///
/// DATOS ENTRANTES:
/// - VOP por músculo (desde Tab 2)
/// - Distribución H/M/L (desde Tab 2)
/// - Bitácora histórica (opcional, desde entrenamiento anterior)
///
/// DATOS SALIENTES:
/// - Plan de 4 semanas (estructura, volumen, distribución)
/// - PDF exportable (formato profesional)

class TrainingPlanTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> trainingExtra;

  const TrainingPlanTab({super.key, required this.trainingExtra});

  @override
  ConsumerState<TrainingPlanTab> createState() => _TrainingPlanTabState();
}

class _TrainingPlanTabState extends ConsumerState<TrainingPlanTab> {
  // Selectores
  int _selectedDays = 4;
  String? _selectedSplitId;
  final TrainingPlanBuilder _builder = TrainingPlanBuilder();
  List<_WeekPlan> _weeks = const [];

  @override
  void initState() {
    super.initState();
    // CAMBIO: Cargar plan persistido en lugar de auto-generar
    // Solo se genera cuando el usuario presiona "Generar plan" explícitamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainingPlanProvider.notifier).loadPersistedActivePlanIfAny();
    });
  }

  /// Generar o regenerar el plan actual
  void _generatePlan() {
    if (_selectedSplitId == null) return;

    final template = LegacySplitTemplates.getTemplateById(_selectedSplitId!);
    if (template == null) return;

    final vopByMuscle = _extractVopByMuscle();
    final perDay = _allocateBaselineAcrossDays(template, vopByMuscle);
    final phase = _extractPhase();
    final timePerSession = _timePerSessionMinutes();

    final weeks = <_WeekPlan>[];
    for (var w = 1; w <= 4; w++) {
      final days = <_DayPlan>[];
      for (var d = 1; d <= template.daysPerWeek; d++) {
        final muscles = template.getMusclesForDay(d);
        if (muscles.isEmpty) {
          days.add(_DayPlan(dayNumber: d, isRest: true, blocks: const []));
          continue;
        }

        final dayVop = <String, int>{};
        for (final m in muscles) {
          final sets = perDay[m]?[d] ?? 0;
          if (sets > 0) dayVop[m] = sets;
        }

        final blocks = _builder.buildSession(
          dayIndex: d,
          targetMuscles: muscles,
          vopByMuscle: dayVop,
          sessionDuration: timePerSession,
          phase: phase,
        );

        days.add(_DayPlan(dayNumber: d, isRest: false, blocks: blocks));
      }
      weeks.add(_WeekPlan(weekNumber: w, days: days));
    }

    setState(() {
      _weeks = weeks;
    });
  }

  /// Extraer VOP por músculo desde Tab 2
  /// PARTE 2 A6: Normaliza TODAS las claves a canónicas antes de usar
  Map<String, int> _extractVopByMuscle() {
    final raw =
        widget.trainingExtra[TrainingExtraKeys.finalTargetSetsByMuscleUi]
            as Map?;

    if (raw is! Map) return {};

    final result = <String, int>{};
    raw.forEach((key, value) {
      // PARTE 2 A6: Normalizar clave ANTES de usar
      final normalizedKey = normalizeMuscleKey(key.toString());

      if (value is num) {
        result[normalizedKey] = value.toInt();
      } else if (value is Map && value['total'] is num) {
        result[normalizedKey] = (value['total'] as num).toInt();
      }
    });

    debugPrint('[VOP][Tab3] Claves normalizadas: ${result.keys.join(", ")}');
    return result;
  }

  /// Distribuir el VOP semanal entre los días del split (suma exacta)
  Map<String, Map<int, int>> _allocateBaselineAcrossDays(
    LegacySplitTemplate template,
    Map<String, int> baselines,
  ) {
    final allocations = <String, Map<int, int>>{};
    final muscles = <String>{};
    for (final dayMuscles in template.dayToMuscles.values) {
      muscles.addAll(dayMuscles);
    }

    for (final muscle in muscles) {
      final daysForMuscle = <int>[];
      template.dayToMuscles.forEach((dayNum, ms) {
        if (ms.contains(muscle)) daysForMuscle.add(dayNum);
      });
      if (daysForMuscle.isEmpty) continue;

      final baseline = baselines[muscle] ?? 0;
      final freq = daysForMuscle.length;
      final q = freq == 0 ? 0 : baseline ~/ freq;
      int r = freq == 0 ? 0 : baseline % freq;

      final perDay = <int, int>{};
      for (final dayNum in daysForMuscle..sort()) {
        final add = r > 0 ? 1 : 0;
        perDay[dayNum] = q + add;
        if (r > 0) r--;
      }
      allocations[muscle] = perDay;
    }
    return allocations;
  }

  int _timePerSessionMinutes() {
    final raw = widget.trainingExtra[TrainingExtraKeys.timePerSessionMinutes];
    if (raw is num && raw.toInt() > 0) return raw.toInt();

    final legacy = widget.trainingExtra[TrainingExtraKeys.timePerSession];
    if (legacy is num && legacy.toInt() > 0) return legacy.toInt();

    return 75; // fallback clínico
  }

  TrainingPhase _extractPhase() {
    final raw = widget.trainingExtra['trainingPhase']?.toString().toLowerCase();
    switch (raw) {
      case 'intensification':
      case 'hf1':
        return TrainingPhase.intensification;
      case 'deload':
        return TrainingPhase.deload;
      default:
        return TrainingPhase.accumulation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 12),

          // Selectores
          _buildSelectors(),
          const SizedBox(height: 12),

          // Plan generado
          if (_weeks.isNotEmpty) ...[
            _buildPlanView(),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Selecciona días y plantilla para generar plan',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Plan de Entrenamiento (4 Semanas)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Genera un plan profesional basado en tu split, VOP y bitácora',
            style: TextStyle(color: kTextColorSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Selector de días
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Días/Semana',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDays,
                      isExpanded: true,
                      decoration: hcsDecoration(
                        context,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [3, 4, 5, 6].map((days) {
                        return DropdownMenuItem(
                          value: days,
                          child: Text('$days días'),
                        );
                      }).toList(),
                      onChanged: (newDays) {
                        if (newDays != null && newDays != _selectedDays) {
                          setState(() {
                            _selectedDays = newDays;
                            // Resetear split a default del nuevo rango de días
                            final templates =
                                LegacySplitTemplates.getTemplatesForDays(
                                  newDays,
                                );
                            _selectedSplitId = templates.isNotEmpty
                                ? templates.first.id
                                : null;
                            if (_selectedSplitId != null) {
                              _generatePlan();
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Selector de plantilla
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plantilla',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSplitId,
                      isExpanded: true,
                      decoration: hcsDecoration(
                        context,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          LegacySplitTemplates.getTemplatesForDays(
                            _selectedDays,
                          ).map((template) {
                            return DropdownMenuItem(
                              value: template.id,
                              child: Text(template.name),
                            );
                          }).toList(),
                      onChanged: (newId) {
                        if (newId != null && newId != _selectedSplitId) {
                          setState(() {
                            _selectedSplitId = newId;
                            _generatePlan();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanView() {
    if (_weeks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _weeks.map((week) => _buildWeekCard(week)).toList(),
      ),
    );
  }

  Widget _buildWeekCard(_WeekPlan week) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Semana ${week.weekNumber}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${_selectedDays}d • bloques A/B/C',
                  style: const TextStyle(
                    fontSize: 11,
                    color: kTextColorSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...week.days.map((day) => _buildDayItem(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(_DayPlan day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
        color: kCardColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      day.isRest ? Icons.self_improvement : Icons.today,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Día ${day.dayNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (!day.isRest)
                  Text(
                    '${day.blocks.length} ejercicios',
                    style: const TextStyle(
                      fontSize: 10,
                      color: kTextColorSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (day.isRest)
              const Text(
                'Descanso',
                style: TextStyle(color: kTextColorSecondary, fontSize: 11),
              )
            else
              Column(
                children: day.blocks
                    .map((b) => ExerciseBlockWidget(block: b))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
