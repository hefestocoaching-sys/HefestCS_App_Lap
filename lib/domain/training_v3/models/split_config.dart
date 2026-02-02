// lib/domain/training_v3/models/split_config.dart

import 'package:equatable/equatable.dart';

/// Configuración del split de entrenamiento
///
/// Define cómo se distribuyen los grupos musculares a lo largo de la semana.
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 6, Imagen 64-69: Configuraciones de split basadas en días disponibles
///   * 3 días → Full Body (frecuencia 3x por músculo)
///   * 4 días → Upper/Lower (frecuencia 2x por músculo)
///   * 5 días → Push/Pull/Legs (frecuencia 1.5-2x por músculo)
///   * 6 días → Push/Pull/Legs 2x (frecuencia 2x por músculo)
///
/// Versión: 1.0.0
class SplitConfig extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// ID único del split
  final String id;

  /// Nombre del split
  /// Ejemplos: "Full Body 3x", "Upper/Lower 4x", "PPL 6x"
  final String name;

  /// Tipo de split
  /// Valores: 'full_body', 'upper_lower', 'push_pull_legs', 'body_part'
  final String type;

  // ════════════════════════════════════════════════════════════
  // CONFIGURACIÓN
  // ════════════════════════════════════════════════════════════

  /// Días de entrenamiento por semana (3-6)
  final int daysPerWeek;

  /// Frecuencia de entrenamiento por músculo por semana
  /// Ejemplos:
  /// - Full Body 3x → 3.0 (cada músculo se entrena 3 veces)
  /// - Upper/Lower 4x → 2.0 (cada músculo se entrena 2 veces)
  /// - PPL 6x → 2.0 (cada músculo se entrena 2 veces)
  final double frequencyPerMuscle;

  /// Distribución de músculos por día
  /// Ejemplo para PPL:
  /// [
  ///   ['chest', 'shoulders', 'triceps'],  // Push
  ///   ['back', 'biceps'],                 // Pull
  ///   ['quads', 'hamstrings', 'glutes']   // Legs
  /// ]
  final List<List<String>> muscleDistribution;

  // ════════════════════════════════════════════════════════════
  // METADATA
  // ════════════════════════════════════════════════════════════

  /// Descripción del split
  final String description;

  const SplitConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.daysPerWeek,
    required this.frequencyPerMuscle,
    required this.muscleDistribution,
    required this.description,
  });

  /// Validar que el split sea coherente
  bool get isValid {
    // Validar días por semana
    if (daysPerWeek < 3 || daysPerWeek > 6) return false;

    // Validar tipo válido
    if (![
      'full_body',
      'upper_lower',
      'push_pull_legs',
      'body_part',
    ].contains(type)) {
      return false;
    }

    // Validar frecuencia razonable (1-3x por músculo)
    if (frequencyPerMuscle < 1.0 || frequencyPerMuscle > 3.0) return false;

    // Validar que muscleDistribution tenga sentido con daysPerWeek
    // Para PPL 6x: debe tener 3 días base (Push, Pull, Legs) que se repiten
    // Para Upper/Lower 4x: debe tener 2 días base (Upper, Lower) que se repiten
    if (type == 'push_pull_legs' && muscleDistribution.length != 3)
      return false;
    if (type == 'upper_lower' && muscleDistribution.length != 2) return false;
    if (type == 'full_body' && muscleDistribution.length != 1) return false;

    return true;
  }

  /// Obtener lista de todos los músculos únicos en el split
  List<String> get allMuscles {
    final muscles = <String>{};
    for (final day in muscleDistribution) {
      muscles.addAll(day);
    }
    return muscles.toList();
  }

  // ════════════════════════════════════════════════════════════
  // FACTORY CONSTRUCTORS PREDEFINIDOS
  // ════════════════════════════════════════════════════════════

  /// Full Body 3 días por semana
  /// Semana 6, Imagen 64: Frecuencia 3x por músculo
  factory SplitConfig.fullBody3x() {
    return SplitConfig(
      id: 'full_body_3x',
      name: 'Full Body 3x',
      type: 'full_body',
      daysPerWeek: 3,
      frequencyPerMuscle: 3.0,
      muscleDistribution: [
        [
          'chest',
          'back',
          'quads',
          'hamstrings',
          'shoulders',
          'biceps',
          'triceps',
        ],
      ],
      description:
          'Entrenamiento de cuerpo completo 3 veces por semana. '
          'Ideal para principiantes o personas con poco tiempo.',
    );
  }

  /// Upper/Lower 4 días por semana
  /// Semana 6, Imagen 65-66: Frecuencia 2x por músculo
  factory SplitConfig.upperLower4x() {
    return SplitConfig(
      id: 'upper_lower_4x',
      name: 'Upper/Lower 4x',
      type: 'upper_lower',
      daysPerWeek: 4,
      frequencyPerMuscle: 2.0,
      muscleDistribution: [
        ['chest', 'back', 'shoulders', 'biceps', 'triceps'], // Upper
        ['quads', 'hamstrings', 'glutes', 'calves'], // Lower
      ],
      description:
          'División tren superior/inferior 4 días por semana. '
          'Frecuencia 2x por músculo, balance volumen/recuperación.',
    );
  }

  /// Push/Pull/Legs 6 días por semana
  /// Semana 6, Imagen 67-69: Frecuencia 2x por músculo
  factory SplitConfig.pushPullLegs6x() {
    return SplitConfig(
      id: 'ppl_6x',
      name: 'Push/Pull/Legs 6x',
      type: 'push_pull_legs',
      daysPerWeek: 6,
      frequencyPerMuscle: 2.0,
      muscleDistribution: [
        ['chest', 'shoulders', 'triceps'], // Push
        ['back', 'biceps'], // Pull
        ['quads', 'hamstrings', 'glutes'], // Legs
      ],
      description:
          'División Push/Pull/Legs 6 días por semana (2 ciclos completos). '
          'Alto volumen total, ideal para intermedios/avanzados.',
    );
  }

  /// Push/Pull/Legs 3 días por semana
  /// Variante para personas con menos disponibilidad
  factory SplitConfig.pushPullLegs3x() {
    return SplitConfig(
      id: 'ppl_3x',
      name: 'Push/Pull/Legs 3x',
      type: 'push_pull_legs',
      daysPerWeek: 3,
      frequencyPerMuscle: 1.0,
      muscleDistribution: [
        ['chest', 'shoulders', 'triceps'], // Push
        ['back', 'biceps'], // Pull
        ['quads', 'hamstrings', 'glutes'], // Legs
      ],
      description:
          'División Push/Pull/Legs 3 días por semana (1 ciclo). '
          'Frecuencia 1x por músculo, volumen bajo, necesita más sets por sesión.',
    );
  }

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'daysPerWeek': daysPerWeek,
      'frequencyPerMuscle': frequencyPerMuscle,
      'muscleDistribution': muscleDistribution,
      'description': description,
    };
  }

  /// Deserialización desde JSON
  factory SplitConfig.fromJson(Map<String, dynamic> json) {
    return SplitConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      daysPerWeek: json['daysPerWeek'] as int,
      frequencyPerMuscle: (json['frequencyPerMuscle'] as num).toDouble(),
      muscleDistribution: (json['muscleDistribution'] as List)
          .map((day) => List<String>.from(day as List))
          .toList(),
      description: json['description'] as String,
    );
  }

  /// CopyWith para actualizaciones inmutables
  SplitConfig copyWith({
    String? id,
    String? name,
    String? type,
    int? daysPerWeek,
    double? frequencyPerMuscle,
    List<List<String>>? muscleDistribution,
    String? description,
  }) {
    return SplitConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      frequencyPerMuscle: frequencyPerMuscle ?? this.frequencyPerMuscle,
      muscleDistribution: muscleDistribution ?? this.muscleDistribution,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    daysPerWeek,
    frequencyPerMuscle,
    muscleDistribution,
    description,
  ];

  @override
  String toString() {
    return 'SplitConfig(name: $name, days: $daysPerWeek, freq: ${frequencyPerMuscle}x)';
  }
}
