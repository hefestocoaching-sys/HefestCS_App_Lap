/// Phase 4: Priority Cap Service
///
/// Responsabilidad:
/// Calcular el VMR efectivo (techo fisiológico) por músculo según su rol de prioridad
/// (primary / secondary / tertiary), sin modificar VME ni redistribuir volumen.
///
/// Este servicio define los LÍMITES SUPERIORES de volumen semanal por músculo,
/// no los targets. Los targets se calculan posteriormente en Phase 5.
///
/// Reglas de negocio:
/// - PRIMARY:   vmrEffective = mrv (100% del rango disponible)
/// - SECONDARY: vmrEffective = mev + 0.60 × (mrv - mev) (60% del rango)
/// - TERTIARY:  vmrEffective = mev + 0.25 × (mrv - mev) (25% del rango)
///
/// El VME nunca se modifica - siempre representa el mínimo fisiológico.
class Phase4PriorityCapService {
  const Phase4PriorityCapService();

  /// Calcula el VMR efectivo para cada músculo según los 3 roles posibles.
  ///
  /// Retorna un mapa donde cada músculo tiene sus 3 techos calculados:
  /// ```dart
  /// {
  ///   "glutes": {"primary": 21.0, "secondary": 16.2, "tertiary": 12.5},
  ///   "quads": {"primary": 18.0, "secondary": 14.0, "tertiary": 10.5},
  ///   ...
  /// }
  /// ```
  ///
  /// [mevByMuscle] - Volumen Mínimo Efectivo por músculo (sets/semana)
  /// [mrvByMuscle] - Volumen Máximo Recuperable por músculo (sets/semana)
  /// [priorityMusclesPrimary] - Músculos con prioridad PRIMARY (opcional, para logging)
  /// [priorityMusclesSecondary] - Músculos con prioridad SECONDARY (opcional, para logging)
  /// [priorityMusclesTertiary] - Músculos con prioridad TERTIARY (opcional, para logging)
  Map<String, Map<String, double>> compute({
    required Map<String, double> mevByMuscle,
    required Map<String, double> mrvByMuscle,
    List<String>? priorityMusclesPrimary,
    List<String>? priorityMusclesSecondary,
    List<String>? priorityMusclesTertiary,
  }) {
    final result = <String, Map<String, double>>{};

    // Procesar todos los músculos presentes en mevByMuscle
    for (final muscle in mevByMuscle.keys) {
      final mev = mevByMuscle[muscle] ?? 0.0;
      final mrv = mrvByMuscle[muscle] ?? mev;

      // Calcular VMR efectivo para cada rol
      final vmrPrimary = _computeVmrEffective(
        mev: mev,
        mrv: mrv,
        role: PriorityRole.primary,
      );

      final vmrSecondary = _computeVmrEffective(
        mev: mev,
        mrv: mrv,
        role: PriorityRole.secondary,
      );

      final vmrTertiary = _computeVmrEffective(
        mev: mev,
        mrv: mrv,
        role: PriorityRole.tertiary,
      );

      result[muscle] = {
        'primary': vmrPrimary,
        'secondary': vmrSecondary,
        'tertiary': vmrTertiary,
      };
    }

    return result;
  }

  /// Calcula el VMR efectivo para un músculo según su rol.
  ///
  /// Fórmulas:
  /// - PRIMARY:   vmrEffective = mrv
  /// - SECONDARY: vmrEffective = mev + 0.60 × (mrv - mev)
  /// - TERTIARY:  vmrEffective = mev + 0.25 × (mrv - mev)
  ///
  /// El resultado siempre está clamped a [mev, mrv].
  double _computeVmrEffective({
    required double mev,
    required double mrv,
    required PriorityRole role,
  }) {
    final range = mrv - mev;

    final double raw = switch (role) {
      PriorityRole.primary => mrv, // 100% del rango
      PriorityRole.secondary => mev + (0.60 * range), // 60% del rango
      PriorityRole.tertiary => mev + (0.25 * range), // 25% del rango
    };

    // Clamp para garantizar que vmrEffective ∈ [mev, mrv]
    final clamped = raw.clamp(mev, mrv);

    // Redondear a 1 decimal para consistencia
    return (clamped * 10).roundToDouble() / 10;
  }

  /// Obtiene el VMR efectivo para un músculo específico según su rol asignado.
  ///
  /// Útil cuando se necesita consultar el techo de un músculo individual
  /// sin recalcular todo el mapa.
  double getEffectiveVmrForMuscle({
    required String muscle,
    required Map<String, double> mevByMuscle,
    required Map<String, double> mrvByMuscle,
    required List<String> primaryMuscles,
    required List<String> secondaryMuscles,
    required List<String> tertiaryMuscles,
  }) {
    final mev = mevByMuscle[muscle] ?? 0.0;
    final mrv = mrvByMuscle[muscle] ?? mev;

    final role = _resolveRole(
      muscle: muscle,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      tertiaryMuscles: tertiaryMuscles,
    );

    return _computeVmrEffective(mev: mev, mrv: mrv, role: role);
  }

  /// Resuelve el rol de prioridad de un músculo.
  ///
  /// Si el músculo no está en ninguna lista, se asume SECONDARY como default.
  PriorityRole _resolveRole({
    required String muscle,
    required List<String> primaryMuscles,
    required List<String> secondaryMuscles,
    required List<String> tertiaryMuscles,
  }) {
    if (primaryMuscles.contains(muscle)) return PriorityRole.primary;
    if (secondaryMuscles.contains(muscle)) return PriorityRole.secondary;
    if (tertiaryMuscles.contains(muscle)) return PriorityRole.tertiary;
    return PriorityRole.secondary; // Default: techo moderado
  }

  /// Calcula el presupuesto de volumen disponible para cada músculo
  /// según su rol asignado.
  ///
  /// Retorna: {muscle: vmrEffective}
  ///
  /// Esto representa el techo máximo de series semanales que el músculo
  /// puede recibir sin comprometer la recuperación.
  Map<String, double> computeEffectiveCaps({
    required Map<String, double> mevByMuscle,
    required Map<String, double> mrvByMuscle,
    required List<String> primaryMuscles,
    required List<String> secondaryMuscles,
    required List<String> tertiaryMuscles,
  }) {
    final caps = <String, double>{};

    for (final muscle in mevByMuscle.keys) {
      caps[muscle] = getEffectiveVmrForMuscle(
        muscle: muscle,
        mevByMuscle: mevByMuscle,
        mrvByMuscle: mrvByMuscle,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        tertiaryMuscles: tertiaryMuscles,
      );
    }

    return caps;
  }
}

/// Roles de prioridad muscular.
///
/// Determinan qué porcentaje del rango fisiológico (MEV-MRV)
/// está disponible para programación.
enum PriorityRole {
  /// Músculo prioritario: acceso al 100% del rango (hasta MRV)
  primary,

  /// Músculo secundario: acceso al 60% del rango
  secondary,

  /// Músculo terciario/mantenimiento: acceso al 25% del rango
  tertiary,
}

/// Extensión para obtener el factor multiplicador de cada rol.
extension PriorityRoleExtension on PriorityRole {
  /// Factor que determina qué porcentaje del rango (MRV - MEV)
  /// se suma al MEV para obtener el techo efectivo.
  double get rangeFactor => switch (this) {
    PriorityRole.primary => 1.00,
    PriorityRole.secondary => 0.60,
    PriorityRole.tertiary => 0.25,
  };

  /// Nombre legible del rol.
  String get displayName => switch (this) {
    PriorityRole.primary => 'Primary',
    PriorityRole.secondary => 'Secondary',
    PriorityRole.tertiary => 'Tertiary',
  };
}
