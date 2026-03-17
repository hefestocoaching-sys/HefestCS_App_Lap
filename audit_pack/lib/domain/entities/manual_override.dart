import 'package:hcs_app_lap/core/enums/muscle_group.dart';

/// Estructura de overrides manuales del coach (solo lectura desde extra)
class ManualOverride {
  final Map<String, VolumeOverride>? volumeOverrides;
  final Map<String, String>? priorityOverrides;
  final bool allowIntensification;
  final int intensificationMaxPerWeek;
  final double? rirTargetOverride;

  const ManualOverride({
    this.volumeOverrides,
    this.priorityOverrides,
    this.allowIntensification = false,
    this.intensificationMaxPerWeek = 1,
    this.rirTargetOverride,
  });

  /// Parsea desde Map crudo del extra
  factory ManualOverride.fromMap(dynamic raw) {
    if (raw == null) return const ManualOverride();
    if (raw is! Map<String, dynamic>) return const ManualOverride();

    final volumeMap = raw['volumeOverrides'] as Map?;
    final volumeOverrides = volumeMap?.cast<String, dynamic>().map((
      muscle,
      vol,
    ) {
      if (vol is Map<String, dynamic>) {
        return MapEntry(
          muscle,
          VolumeOverride(
            mev: (vol['mev'] as num?)?.toInt(),
            mav: (vol['mav'] as num?)?.toInt(),
            mrv: (vol['mrv'] as num?)?.toInt(),
          ),
        );
      }
      return MapEntry(muscle, const VolumeOverride());
    });

    final priorityMap = raw['priorityOverrides'] as Map?;
    final priorityOverrides = priorityMap?.cast<String, String>();

    return ManualOverride(
      volumeOverrides: volumeOverrides,
      priorityOverrides: priorityOverrides,
      allowIntensification: (raw['allowIntensification'] as bool?) ?? false,
      intensificationMaxPerWeek:
          (raw['intensificationMaxPerWeek'] as int?) ?? 1,
      rirTargetOverride: (raw['rirTargetOverride'] as num?)?.toDouble(),
    );
  }

  /// Valida overrides y retorna lista de warnings si hay errores
  List<String> validate() {
    final warnings = <String>[];

    // Validar volume overrides
    volumeOverrides?.forEach((muscle, override) {
      // Validar que muscle sea válido
      try {
        MuscleGroup.values.byName(muscle);
      } catch (_) {
        warnings.add('volumeOverride: músculo inválido "$muscle"');
        return;
      }

      // Validar valores positivos
      if (override.mev != null && override.mev! <= 0) {
        warnings.add('volumeOverride[$muscle]: MEV debe ser > 0');
      }
      if (override.mav != null && override.mav! <= 0) {
        warnings.add('volumeOverride[$muscle]: MAV debe ser > 0');
      }
      if (override.mrv != null && override.mrv! <= 0) {
        warnings.add('volumeOverride[$muscle]: MRV debe ser > 0');
      }

      // Validar mev ≤ mav ≤ mrv
      if (override.mev != null &&
          override.mav != null &&
          override.mev! > override.mav!) {
        warnings.add('volumeOverride[$muscle]: MEV > MAV (debe ser MEV ≤ MAV)');
      }
      if (override.mav != null &&
          override.mrv != null &&
          override.mav! > override.mrv!) {
        warnings.add('volumeOverride[$muscle]: MAV > MRV (debe ser MAV ≤ MRV)');
      }
    });

    // Validar priority overrides
    priorityOverrides?.forEach((muscle, priority) {
      try {
        MuscleGroup.values.byName(muscle);
      } catch (_) {
        warnings.add('priorityOverride: músculo inválido "$muscle"');
        return;
      }
      if (!['primary', 'secondary', 'none'].contains(priority)) {
        warnings.add(
          'priorityOverride[$muscle]: prioridad inválida "$priority" (debe ser primary|secondary|none)',
        );
      }
    });

    // Validar rirTargetOverride
    if (rirTargetOverride != null) {
      if (rirTargetOverride! < 0.0 || rirTargetOverride! > 4.0) {
        warnings.add('rirTargetOverride: debe estar entre 0.0 y 4.0');
      }
    }

    // Validar intensification
    if (intensificationMaxPerWeek < 0) {
      warnings.add('intensificationMaxPerWeek: debe ser >= 0');
    }

    return warnings;
  }

  /// Retorna true si hay al menos un override activo
  bool get hasAnyOverride =>
      (volumeOverrides?.isNotEmpty ?? false) ||
      (priorityOverrides?.isNotEmpty ?? false) ||
      rirTargetOverride != null ||
      (allowIntensification && intensificationMaxPerWeek > 0);
}

class VolumeOverride {
  final int? mev;
  final int? mav;
  final int? mrv;

  const VolumeOverride({this.mev, this.mav, this.mrv});

  bool get isEmpty => mev == null && mav == null && mrv == null;
}
