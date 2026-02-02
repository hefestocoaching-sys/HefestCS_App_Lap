// lib/domain/training_v3/models/user_profile.dart

import 'package:equatable/equatable.dart';

/// Perfil completo del usuario para Motor V3
///
/// Contiene toda la información necesaria para generar programas personalizados:
/// - Datos demográficos (edad, género, antropometría)
/// - Historial de entrenamiento (años, nivel, volumen previo)
/// - Preferencias (días disponibles, duración de sesión, objetivos)
/// - Restricciones (lesiones, equipamiento disponible)
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 1-2: Volumen se ajusta según nivel de entrenamiento
/// - Semana 6: Disponibilidad determina split óptimo
/// - Semana 5: Historial de lesiones afecta selección de ejercicios
///
/// Versión: 1.0.0
class UserProfile extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// ID único del usuario (Firebase UID)
  final String id;

  /// Nombre completo
  final String name;

  /// Email
  final String email;

  // ════════════════════════════════════════════════════════════
  // DATOS DEMOGRÁFICOS
  // ════════════════════════════════════════════════════════════

  /// Edad en años (18-80)
  final int age;

  /// Género ('male', 'female', 'other')
  final String gender;

  /// Altura en cm (140-220)
  final double heightCm;

  /// Peso en kg (40-160)
  final double weightKg;

  // ════════════════════════════════════════════════════════════
  // HISTORIAL DE ENTRENAMIENTO
  // ════════════════════════════════════════════════════════════

  /// Años de entrenamiento continuo (0-30)
  /// Semana 1: Determina rango de volumen (novice/intermediate/advanced)
  final double yearsTraining;

  /// Nivel de entrenamiento ('novice', 'intermediate', 'advanced')
  /// Semana 1, Imagen 1-5: Define landmarks VME/MAV/MRV
  final String trainingLevel;

  /// Semanas consecutivas entrenando sin pausa (0-52)
  final int consecutiveWeeks;

  // ════════════════════════════════════════════════════════════
  // PREFERENCIAS DE ENTRENAMIENTO
  // ════════════════════════════════════════════════════════════

  /// Días disponibles por semana (3-6)
  /// Semana 6, Imagen 64-69: Determina split (3d=FullBody, 4d=U/L, 5-6d=PPL)
  final int availableDays;

  /// Duración de sesión en minutos (30-120)
  final int sessionDuration;

  /// Objetivo principal ('hypertrophy', 'strength', 'endurance', 'general_fitness')
  final String primaryGoal;

  /// Prioridades musculares (músculo -> prioridad 1-5)
  /// 5 = máxima prioridad (asignar MAV)
  /// 3 = prioridad media (punto medio VME-MAV)
  /// 1 = mínima prioridad (asignar VME)
  /// Semana 1, Imagen 11-15
  final Map<String, int> musclePriorities;

  // ════════════════════════════════════════════════════════════
  // RESTRICCIONES
  // ════════════════════════════════════════════════════════════

  /// Equipamiento disponible
  /// Semana 5, Imagen 44: Selección de ejercicios filtrada por equipamiento
  final List<String> availableEquipment;

  /// Historial de lesiones (articulación -> descripción)
  /// Semana 5: Evitar ejercicios de alto riesgo para articulaciones lesionadas
  final Map<String, String> injuryHistory;

  /// Ejercicios excluidos manualmente (IDs)
  final List<String> excludedExercises;

  // ════════════════════════════════════════════════════════════
  // METADATA
  // ════════════════════════════════════════════════════════════

  /// Fecha de creación del perfil
  final DateTime createdAt;

  /// Última actualización
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.yearsTraining,
    required this.trainingLevel,
    this.consecutiveWeeks = 0,
    required this.availableDays,
    required this.sessionDuration,
    required this.primaryGoal,
    required this.musclePriorities,
    required this.availableEquipment,
    this.injuryHistory = const {},
    this.excludedExercises = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calcula BMI (Body Mass Index)
  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  /// Validar que los datos sean coherentes
  bool get isValid {
    if (age < 18 || age > 80) return false;
    if (heightCm < 140 || heightCm > 220) return false;
    if (weightKg < 40 || weightKg > 160) return false;
    if (yearsTraining < 0 || yearsTraining > 30) return false;
    if (availableDays < 3 || availableDays > 6) return false;
    if (sessionDuration < 30 || sessionDuration > 120) return false;
    if (!['novice', 'intermediate', 'advanced'].contains(trainingLevel)) {
      return false;
    }
    if (!['male', 'female', 'other'].contains(gender)) return false;
    return true;
  }

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'yearsTraining': yearsTraining,
      'trainingLevel': trainingLevel,
      'consecutiveWeeks': consecutiveWeeks,
      'availableDays': availableDays,
      'sessionDuration': sessionDuration,
      'primaryGoal': primaryGoal,
      'musclePriorities': musclePriorities,
      'availableEquipment': availableEquipment,
      'injuryHistory': injuryHistory,
      'excludedExercises': excludedExercises,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserialización desde JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      yearsTraining: (json['yearsTraining'] as num).toDouble(),
      trainingLevel: json['trainingLevel'] as String,
      consecutiveWeeks: json['consecutiveWeeks'] as int? ?? 0,
      availableDays: json['availableDays'] as int,
      sessionDuration: json['sessionDuration'] as int,
      primaryGoal: json['primaryGoal'] as String,
      musclePriorities: Map<String, int>.from(json['musclePriorities'] as Map),
      availableEquipment: List<String>.from(json['availableEquipment'] as List),
      injuryHistory: Map<String, String>.from(
        json['injuryHistory'] as Map? ?? {},
      ),
      excludedExercises: List<String>.from(
        json['excludedExercises'] as List? ?? [],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// CopyWith para actualizaciones inmutables
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? yearsTraining,
    String? trainingLevel,
    int? consecutiveWeeks,
    int? availableDays,
    int? sessionDuration,
    String? primaryGoal,
    Map<String, int>? musclePriorities,
    List<String>? availableEquipment,
    Map<String, String>? injuryHistory,
    List<String>? excludedExercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      yearsTraining: yearsTraining ?? this.yearsTraining,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      consecutiveWeeks: consecutiveWeeks ?? this.consecutiveWeeks,
      availableDays: availableDays ?? this.availableDays,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      musclePriorities: musclePriorities ?? this.musclePriorities,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      injuryHistory: injuryHistory ?? this.injuryHistory,
      excludedExercises: excludedExercises ?? this.excludedExercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    age,
    gender,
    heightCm,
    weightKg,
    yearsTraining,
    trainingLevel,
    consecutiveWeeks,
    availableDays,
    sessionDuration,
    primaryGoal,
    musclePriorities,
    availableEquipment,
    injuryHistory,
    excludedExercises,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, level: $trainingLevel, '
        'days: $availableDays, goal: $primaryGoal)';
  }
}
