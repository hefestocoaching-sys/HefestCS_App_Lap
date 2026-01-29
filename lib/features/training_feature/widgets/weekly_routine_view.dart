import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class WeeklyRoutineView extends StatelessWidget {
  final TrainingWeek week;

  const WeeklyRoutineView({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: week.sessions
          .map((session) => _SessionCard(session: session))
          .toList(),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TrainingSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // Estilo de vidrio unificado
        color: kAppBarColor.withAlpha(110),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la Sesión (Ej: Lunes - Torso A)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: kPrimaryColor.withAlpha(26),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "DÍA ${session.dayNumber}: ${session.sessionName.toUpperCase()}",
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: kPrimaryColor.withAlpha(128),
                ),
              ],
            ),
          ),

          // Lista de Ejercicios
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: session.prescriptions.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: kTextColorSecondary.withAlpha(26)),
            itemBuilder: (context, index) {
              return _ExerciseRow(prescription: session.prescriptions[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ExercisePrescription prescription;

  const _ExerciseRow({required this.prescription});

  @override
  Widget build(BuildContext context) {
    // Detectamos si es una técnica especial o pesado para colorear
    final bool isHeavy = prescription.rir == "3-4" || prescription.sets <= 3;
    final bool isFailure = prescription.rir == "0" || prescription.rir == "0-1";
    final bool isFst7 = prescription.label.contains("FST");

    Color accentColor = kTextColorSecondary;
    if (isFst7) {
      accentColor = Colors.purpleAccent;
    } else if (isFailure) {
      accentColor = Colors.redAccent;
    } else if (isHeavy) {
      accentColor = Colors.blueAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Etiqueta (A, B1, C...)
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withAlpha(128)),
            ),
            child: Text(
              prescription.label,
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Detalles del Ejercicio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prescription.exerciseName,
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _Tag(
                      text: "${prescription.sets} Series",
                      icon: Icons.layers,
                    ),
                    _Tag(text: "${prescription.reps} Reps", icon: Icons.repeat),
                    _Tag(
                      text: "RIR ${prescription.rir}",
                      icon: Icons.speed,
                      color: accentColor,
                    ),
                  ],
                ),
                if (prescription.notes != null &&
                    prescription.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      prescription.notes!,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const _Tag({required this.text, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kTextColorSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: c, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
