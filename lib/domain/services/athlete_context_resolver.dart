import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';

/// Contexto del atleta resuelto desde múltiples fuentes del cliente
class AthleteContext {
  /// Edad en años (calculada desde birthDate)
  final int ageYears;

  /// Sexo biológico
  final Gender sex;

  /// Altura en centímetros (del registro antropométrico más reciente, nullable)
  final double? heightCm;

  /// Peso en kilogramos (del registro antropométrico más reciente, nullable)
  final double? weightKg;

  /// Si usa esteroides anabólicos (de historia clínica o training.extra)
  final bool usesAnabolics;

  const AthleteContext({
    required this.ageYears,
    required this.sex,
    this.heightCm,
    this.weightKg,
    required this.usesAnabolics,
  });

  @override
  String toString() {
    return 'AthleteContext('
        'age: $ageYears años, '
        'sex: ${sex.name}, '
        'height: ${heightCm?.toStringAsFixed(1) ?? 'N/A'} cm, '
        'weight: ${weightKg?.toStringAsFixed(1) ?? 'N/A'} kg, '
        'usesAnabolics: $usesAnabolics'
        ')';
  }
}

/// Servicio para resolver el contexto del atleta desde el cliente
class AthleteContextResolver {
  const AthleteContextResolver();

  /// Resuelve el contexto del atleta desde el cliente
  ///
  /// Fuentes:
  /// - ageYears y sex: historia clínica (Client.profile)
  /// - heightCm y weightKg: latestAnthropometryRecord (más reciente por fecha)
  /// - usesAnabolics: history.extra > training.extra > false
  AthleteContext resolve(Client client) {
    // 1. Edad desde birthDate (obligatorio)
    final birthDate = client.profile.birthDate;
    if (birthDate == null) {
      throw ArgumentError(
        'Cliente ${client.id}: birthDate es requerido para calcular la edad',
      );
    }
    final ageYears = _calculateAge(birthDate);

    // 2. Sexo desde profile (obligatorio)
    final sex = client.profile.gender;
    if (sex == null) {
      throw ArgumentError(
        'Cliente ${client.id}: gender es requerido para el contexto del atleta',
      );
    }

    // 3. Altura y peso desde latestAnthropometryRecord (regla "más reciente")
    final latestAnthropo = client.latestAnthropometryRecord;
    final heightCm = latestAnthropo?.heightCm;
    final weightKg = latestAnthropo?.weightKg;

    // 4. Uso de anabólicos
    // Prioridad 1: history.extra (más confiable)
    bool usesAnabolics = false;
    if (client.history.extra.containsKey('usesAnabolics')) {
      final value = client.history.extra['usesAnabolics'];
      usesAnabolics = value is bool ? value : false;
    }
    // Prioridad 2: training.extra (fallback)
    else if (client.training.extra.containsKey(
      TrainingExtraKeys.usesAnabolics,
    )) {
      final value = client.training.extra[TrainingExtraKeys.usesAnabolics];
      usesAnabolics = value is bool ? value : false;
    }
    // Prioridad 3: false (default)

    return AthleteContext(
      ageYears: ageYears,
      sex: sex,
      heightCm: heightCm,
      weightKg: weightKg,
      usesAnabolics: usesAnabolics,
    );
  }

  /// Calcula la edad en años desde la fecha de nacimiento
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Ajustar si aún no ha cumplido años este año
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }
}
