import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/domain/training/models/muscle_key.dart';

const muscleLabelEs = {
  'chest': 'Pectoral',
  'back': 'Espalda',
  'lats': 'Dorsal ancho',
  'traps': 'Trapecio',
  'shoulders': 'Hombros',
  'biceps': 'Bíceps',
  'triceps': 'Tríceps',
  'forearms': 'Antebrazo',
  'quads': 'Cuádriceps',
  'hamstrings': 'Isquiotibiales',
  'glutes': 'Glúteos',
  'calves': 'Pantorrillas',
  'abs': 'Abdomen',
  'fullBody': 'Cuerpo completo',
};

class MevMvrTable extends StatelessWidget {
  final TrainingPlanConfig planConfig;

  const MevMvrTable({super.key, required this.planConfig});

  /// Helper: Lectura robusta de double desde extra con múltiples keys de fallback
  static double? _readDouble(Map<String, dynamic> extra, List<String> keys) {
    for (final k in keys) {
      final v = extra[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v.replaceAll(',', '.'));
        if (p != null) return p;
      }
    }
    return null;
  }

  /// Helper: Lectura robusta de mapa de String a double desde extra
  static Map<String, double> _readDoubleMap(
    Map<String, dynamic> extra,
    String key,
  ) {
    final raw = extra[key];
    if (raw is! Map) return <String, double>{};
    final out = <String, double>{};
    raw.forEach((k, v) {
      if (k == null) return;
      final keyStr = k.toString();
      if (v is num) {
        out[keyStr] = v.toDouble();
      } else if (v is String) {
        final p = double.tryParse(v.replaceAll(',', '.'));
        if (p != null) out[keyStr] = p;
      }
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final profile = planConfig.trainingProfileSnapshot;

    // Si no hay snapshot del perfil, no podemos calcular MEV/MRV
    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kAppBarColor.withValues(alpha: 0.43),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Text(
            'No hay datos de perfil disponibles para calcular MEV/MRV',
            style: TextStyle(color: kTextColorSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Leer MEV/MRV individualizados con parseo robusto y fallback keys
    final mevIndividual = _readDouble(profile.extra, [
      'mevIndividual',
      'mev_individual',
      'MEV',
    ]);
    final mrvIndividual = _readDouble(profile.extra, [
      'mrvIndividual',
      'mrv_individual',
      'MRV',
    ]);

    // Leer targetSets por músculo con parseo robusto
    final targetSetsByMuscle = _readDoubleMap(
      profile.extra,
      'targetSetsByMuscle',
    );

    // Leer mapas por músculo
    final mevByMuscle = _readDoubleMap(profile.extra, 'mevByMuscle');
    final mrvByMuscle = _readDoubleMap(profile.extra, 'mrvByMuscle');

    // Condición: datos suficientes
    final hasGlobal = (mevIndividual != null && mrvIndividual != null);
    final hasMaps = (mevByMuscle.isNotEmpty && mrvByMuscle.isNotEmpty);
    final hasIndiv = targetSetsByMuscle.isNotEmpty && (hasGlobal || hasMaps);

    if (!hasIndiv) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kAppBarColor.withValues(alpha: 0.43),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Text(
            'No hay datos de volumen individualizado disponibles',
            style: TextStyle(color: kTextColorSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final muscles = targetSetsByMuscle.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: kAppBarColor.withValues(alpha: 0.43),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            const Divider(height: 1, color: kPrimaryColor),
            ...muscles.map((m) {
              final normalizedKey = MuscleKey.fromRaw(m)?.name;
              // Valores por músculo con fallback al global
              final double mevRow = normalizedKey != null
                  ? (mevByMuscle[normalizedKey] ?? (mevIndividual ?? 0))
                  : (mevIndividual ?? 0);
              final double mrvRow = normalizedKey != null
                  ? (mrvByMuscle[normalizedKey] ?? (mrvIndividual ?? 0))
                  : (mrvIndividual ?? 0);
              // Sets Plan: leer targetSetsByMuscle (NO usar suma de ejercicios)
              final double? targetSets = targetSetsByMuscle[m];

              // Estado: evaluar targetSets contra MEV/MRV individualizados con null-safety
              final String status;
              final Color statusColor;
              final IconData statusIcon;

              if (targetSets == null || targetSets == 0) {
                status = 'No programado';
                statusColor = Colors.grey.shade500;
                statusIcon = Icons.remove_circle_outline;
              } else if (targetSets < mevRow) {
                status = 'Bajo MEV';
                statusColor = Colors.orange.shade600;
                statusIcon = Icons.arrow_downward;
              } else if (targetSets > mrvRow) {
                status = 'Sobre MRV';
                statusColor = Colors.red.shade600;
                statusIcon = Icons.warning_amber_outlined;
              } else {
                status = 'Óptimo';
                statusColor = Colors.green.shade600;
                statusIcon = Icons.check_circle_outline;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        muscleLabelEs[m] ?? m,
                        style: const TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        targetSets?.toStringAsFixed(1) ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        mevRow.round().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kTextColor),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        mrvRow.round().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kTextColor),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Músculo',
              style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Sets Plan',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'MEV',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'MRV',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Estado',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
