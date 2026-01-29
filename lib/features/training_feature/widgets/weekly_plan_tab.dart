import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Tab 4 — Plan Semanal según días y split válido
/// Lee directamente desde plan persistido (Motor V2)
/// No genera planes legacy
class WeeklyPlanTab extends StatefulWidget {
  final TrainingPlanConfig? planConfig;
  final TrainingProfile profile;
  final Map<String, int> vopByMuscle;
  final Map<String, dynamic> effectiveExtra;

  const WeeklyPlanTab({
    super.key,
    required this.planConfig,
    required this.profile,
    required this.vopByMuscle,
    required this.effectiveExtra,
  });

  @override
  State<WeeklyPlanTab> createState() => _WeeklyPlanTabState();
}

class _WeeklyPlanTabState extends State<WeeklyPlanTab> {
  @override
  Widget build(BuildContext context) {
    final planConfig = widget.planConfig;

    // Guard clause: Si no existe plan persistido, mostrar estado bloqueado
    if (planConfig == null || planConfig.weeks.isEmpty) {
      return _buildBlocked(
        title: 'No hay plan semanal persistido',
        message:
            'Este tab solo muestra el plan generado por el Motor V2. Genera un plan en "Perfiles" para la fecha seleccionada.',
      );
    }

    // Usar la primera semana del plan persistido (determinístico)
    final TrainingWeek week = planConfig.weeks.first;
    final sessions = week.sessions;

    // Renderizar contenido del plan persistido
    return _buildPersistentPlanContent(
      context: context,
      week: week,
      sessions: sessions,
    );
  }

  Widget _buildBlocked({required String title, required String message}) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        color: kBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: kTextColorSecondary),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: kTextColorSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Haz clic en "Perfiles" para generar un plan para la fecha seleccionada.',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: kTextColorSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersistentPlanContent({
    required BuildContext context,
    required TrainingWeek week,
    required List<TrainingSession> sessions,
  }) {
    if (sessions.isEmpty) {
      return _buildBlocked(
        title: 'Semana sin sesiones',
        message: 'Esta semana del plan no tiene sesiones configuradas.',
      );
    }

    // Agrupar por día (1..N)
    final sessionsByDay = <int, List<TrainingSession>>{};
    for (final session in sessions) {
      final day = session.dayNumber;
      if (!sessionsByDay.containsKey(day)) {
        sessionsByDay[day] = [];
      }
      sessionsByDay[day]!.add(session);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessionsByDay.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final day = sessionsByDay.keys.toList()[index];
        final daySessions = sessionsByDay[day]!;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Día $day',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildSessionExercises(daySessions, context),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSessionExercises(
    List<TrainingSession> sessions,
    BuildContext context,
  ) {
    final widgets = <Widget>[];

    for (final session in sessions) {
      if (session.exercises.isEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin ejercicios configurados',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
        continue;
      }

      for (final exercise in session.exercises) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sets: ${exercise.sets} | Reps: ${exercise.reps}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'RIR: ${exercise.rir}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
