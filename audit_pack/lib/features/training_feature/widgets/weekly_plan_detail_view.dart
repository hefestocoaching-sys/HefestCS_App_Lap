import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Vista semanal del plan Motor V3 con navegación por microciclos.
///
/// Basado en fundamentos de periodización (06-progression-variation.md):
/// - Semanas 1-3: ACUMULACIÓN → volumen creciente, RIR constante (2-3)
/// - Semana 4: INTENSIFICACIÓN → volumen estable, RIR ↓ (0-1)
/// - Semana 5+: DELOAD → volumen -50%, RIR alto (4-5)
///
/// Esta vista consume la estructura del Motor V3:
/// `TrainingPlanConfig.weeks[].sessions[].prescriptions[]`.
class WeeklyPlanDetailView extends ConsumerStatefulWidget {
  final TrainingPlanConfig plan;

  const WeeklyPlanDetailView({super.key, required this.plan});

  @override
  ConsumerState<WeeklyPlanDetailView> createState() =>
      _WeeklyPlanDetailViewState();
}

class _WeeklyPlanDetailViewState extends ConsumerState<WeeklyPlanDetailView> {
  int _selectedWeekIndex = 0;

  @override
  Widget build(BuildContext context) {
    final totalWeeks = widget.plan.weeks.length;

    if (totalWeeks == 0) {
      return const Center(
        child: Text(
          'Plan sin semanas disponibles',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    if (_selectedWeekIndex < 0 || _selectedWeekIndex >= totalWeeks) {
      return const Center(
        child: Text(
          'Error: semana fuera de rango',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    final week = widget.plan.weeks[_selectedWeekIndex];
    final sessions = week.sessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWeekNavigator(totalWeeks),
        const SizedBox(height: 12),
        _buildPhaseIndicator(week.weekNumber, phaseName: week.phase.name),
        const SizedBox(height: 12),
        Expanded(
          child: sessions.isEmpty
              ? const Center(
                  child: Text(
                    'Semana sin sesiones configuradas',
                    style: TextStyle(color: kTextColorSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return _buildSessionCard(session, week.weekNumber);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeekNavigator(int totalWeeks) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _selectedWeekIndex > 0
                ? () {
                    setState(() {
                      _selectedWeekIndex -= 1;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            color: kTextColor,
          ),
          Expanded(
            child: Text(
              'Semana ${_selectedWeekIndex + 1} de $totalWeeks',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: _selectedWeekIndex < totalWeeks - 1
                ? () {
                    setState(() {
                      _selectedWeekIndex += 1;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            color: kTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(int weekNumber, {String? phaseName}) {
    late String title;
    late String description;
    late IconData icon;
    late Color color;

    if (phaseName == 'deload' || phaseName == 'deload_week') {
      title = 'DELOAD';
      description = 'Volumen -50%, RIR alto (4-5), recuperación';
      icon = Icons.spa;
      color = kSuccessColor;
    } else if (phaseName == 'intensification') {
      title = 'INTENSIFICACIÓN';
      description = 'Volumen estable, RIR ↓ (0-1)';
      icon = Icons.bolt;
      color = kWarningColor;
    } else if (weekNumber >= 1 && weekNumber <= 3) {
      title = 'ACUMULACIÓN';
      description = 'Volumen ↑ progresivo, RIR constante (2-3)';
      icon = Icons.trending_up;
      color = kInfoColor;
    } else if (weekNumber == 4) {
      title = 'INTENSIFICACIÓN';
      description = 'Volumen estable, RIR ↓ (0-1)';
      icon = Icons.bolt;
      color = kWarningColor;
    } else {
      title = 'DELOAD';
      description = 'Volumen -50%, RIR alto (4-5), recuperación';
      icon = Icons.spa;
      color = kSuccessColor;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session, int weekNumber) {
    return Card(
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Header de la sesión con botón de completar
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withAlpha(30),
                border: Border.all(color: kPrimaryColor.withAlpha(80)),
              ),
              child: Center(
                child: Text(
                  '${session.dayNumber}',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            title: Text(
              session.sessionName,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${session.prescriptions.length} ejercicios',
              style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            trailing: TextButton.icon(
              onPressed: () => _showSessionLogDialog(
                context,
                session: session,
                weekNumber: weekNumber,
              ),
              icon: const Icon(
                Icons.check_circle_outline,
                size: 16,
                color: kSuccessColor,
              ),
              label: const Text(
                'Registrar',
                style: TextStyle(color: kSuccessColor, fontSize: 12),
              ),
            ),
          ),
          // Prescripciones expandibles
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text(
              'Ver ejercicios',
              style: TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            children: session.prescriptions
                .map(
                  (p) => ListTile(
                    dense: true,
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          p.label,
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      p.exerciseName,
                      style: const TextStyle(color: kTextColor, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${p.sets} series × ${p.repRange} reps • RIR ${p.rir}',
                      style: const TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showSessionLogDialog(
    BuildContext context, {
    required TrainingSession session,
    required int weekNumber,
  }) {
    double rpe = 7;
    double rir = 2;
    double recovery = 7;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: kCardColor,
          title: Text(
            'Registrar — ${session.sessionName}',
            style: const TextStyle(color: kTextColor, fontSize: 15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sliderRow(
                'RPE sesión',
                rpe,
                1,
                10,
                (v) => setDialogState(() => rpe = v),
              ),
              _sliderRow(
                'RIR promedio',
                rir,
                0,
                5,
                (v) => setDialogState(() => rir = v),
              ),
              _sliderRow(
                'Recuperación previa',
                recovery,
                1,
                10,
                (v) => setDialogState(() => recovery = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Semana $weekNumber • ${session.prescriptions.length} ejercicios',
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: kTextColorSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccessColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _persistSessionLog(
                  session: session,
                  weekNumber: weekNumber,
                  rpe: rpe,
                  rir: rir,
                  recovery: recovery,
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).toInt(),
            activeColor: kPrimaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _persistSessionLog({
    required TrainingSession session,
    required int weekNumber,
    required double rpe,
    required double rir,
    required double recovery,
  }) async {
    // Calcular sets por músculo desde las prescripciones
    final setsByMuscle = <String, int>{};
    for (final p in session.prescriptions) {
      final muscle = p.muscleGroup.canonicalKey;
      setsByMuscle[muscle] = (setsByMuscle[muscle] ?? 0) + p.sets;
    }

    await ref
        .read(trainingPlanProvider.notifier)
        .recordCompletedSession(
          clientId: ref.read(clientsProvider).value?.activeClient?.id ?? '',
          weekNumber: weekNumber,
          setsByMuscle: setsByMuscle,
          sessionRpe: rpe,
          sessionRir: rir,
          perceivedRecovery: recovery,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sesión registrada en bitácora'),
          backgroundColor: kSuccessColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
