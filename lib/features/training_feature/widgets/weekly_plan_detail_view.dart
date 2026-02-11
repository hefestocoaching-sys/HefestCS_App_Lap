import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/design/hcs_glass_container.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
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
        _buildPhaseIndicator(week.weekNumber),
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
                    return _buildSessionCard(session, index + 1);
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

  Widget _buildPhaseIndicator(int weekNumber) {
    late String title;
    late String description;
    late IconData icon;
    late Color color;

    if (weekNumber >= 1 && weekNumber <= 3) {
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
                  style: const TextStyle(color: kTextColorSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(dynamic session, int dayNumber) {
    final rawPrescriptions = session.prescriptions as List<dynamic>;
    final prescriptions = rawPrescriptions.map<Map<String, dynamic>>((p) {
      if (p is Map<String, dynamic>) return p;
      final dynamic json = (p as dynamic).toJson();
      return (json as Map).cast<String, dynamic>();
    }).toList();

    if (prescriptions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: HcsGlassContainer(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            'Sin ejercicios configurados',
            style: TextStyle(color: kTextColorSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: kCardColor.withAlpha(50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: HcsGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(
              'Día $dayNumber',
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${prescriptions.length} ejercicios',
              style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: kPrimaryColor.withAlpha(50),
              child: Text(
                '$dayNumber',
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            children: [
              for (var i = 0; i < prescriptions.length; i++)
                _buildExerciseRow(prescriptions[i], i + 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseRow(Map<String, dynamic> prescription, int order) {
    final exercise = prescription['exercise'];
    final name = (exercise is Map && exercise['name'] != null)
        ? exercise['name'].toString()
        : (prescription['exerciseName']?.toString() ?? 'Ejercicio');
    final sets = prescription['sets']?.toString() ?? '0';
    final reps =
        prescription['reps']?.toString() ??
        prescription['repRange']?.toString() ??
        '-';
    final rir = prescription['rir']?.toString() ?? '2';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: kBackgroundColor.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: kPrimaryColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$order',
              style: const TextStyle(
                color: kTextColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: kTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$sets x $reps @ RIR $rir',
              style: const TextStyle(
                color: kPrimaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
