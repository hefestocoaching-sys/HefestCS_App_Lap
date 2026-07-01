import 'package:hcs_app_lap/core/registry/muscle_registry.dart' as registry;
import 'package:hcs_app_lap/core/utils/app_logger.dart';

/// Mapper canónico que convierte keys de preferencias de ejercicios
/// a las claves canónicas del motor de entrenamiento.
///
/// USO:
/// - Las preferencias UI/catálogo pueden usar keys variantes (ej: 'pectorals', 'chest')
/// - Este mapper garantiza normalización a las 14 claves SSOT del motor
/// - El resultado se usa para lookups en `muscle_volume_landmarks_ssot` y motor de generación
///
/// GARANTÍA:
/// - Todas las keys retornadas están en `canonicalMuscles` del registry
/// - Nunca inventa nuevos músculos
/// - Si no reconoce una key, retorna null (con warning en logs)
///
class ExercisePreferenceMuscleKeyMapper {
  ExercisePreferenceMuscleKeyMapper._();

  /// Normaliza una key de preferencia a clave canónica del motor.
  ///
  /// ENTRADA:
  /// - 'pectorals' → 'pectorals' (ya canónico)
  /// - 'chest' → 'pectorals' (alias UI)
  /// - 'delts_front' → 'delts_front' (ya canónico)
  /// - 'deltoide_anterior' → 'delts_front' (alias clínico)
  ///
  /// SALIDA:
  /// - Exactamente una clave de las 14 canónicas, o null si no se reconoce
  static String? toCanonicalKey(String preferenceKey) {
    if (preferenceKey.isEmpty) return null;

    // Primero intentar normalizacion estricta del registry (SSOT)
    final canonical = registry.tryNormalizeMuscleKey(preferenceKey);
    if (canonical != null) {
      if (preferenceKey.toLowerCase() != canonical) {
        logger.debug('Exercise preference key normalized', {
          'from': preferenceKey,
          'to': canonical,
        });
      }
      return canonical;
    }

    // Si no se reconoce, log y retornar null
    logger.warning('Exercise preference key not recognized', {
      'key': preferenceKey,
    });
    return null;
  }

  /// Mapea un conjunto de keys de preferencias a claves canónicas.
  /// Filtra nulls automáticamente.
  static Set<String> toCanonicalKeys(Iterable<String> preferenceKeys) {
    final canonical = <String>{};
    for (final key in preferenceKeys) {
      final norm = toCanonicalKey(key);
      if (norm != null) {
        canonical.add(norm);
      }
    }
    return canonical;
  }

  /// Documenta el mapeo de aliases soportados.
  /// Útil para referencias y auditorías.
  static const Map<String, String> supportedAliases = <String, String>{
    // Pectorales
    'pectorals': 'pectorals (canónico)',
    'chest': 'pectorals (alias)',
    'pecho': 'pectorals (español)',
    'pectoral': 'pectorals (español singular)',
    'pectorales': 'pectorals (español)',

    // Dorsal
    'lats': 'lats (canónico)',
    'dorsal ancho': 'lats (español)',
    'latissimus': 'lats (clínico)',
    'dorsal': 'lats (español)',

    // Espalda alta
    'upper_back': 'upper_back (canónico)',
    'upper back': 'upper_back (variante)',
    'espalda alta': 'upper_back (español)',
    'romboides': 'upper_back (español)',

    // Trapecios
    'traps': 'traps (canónico)',
    'trapecios': 'traps (español)',
    'trapecio': 'traps (español singular)',
    'trapezius': 'traps (clínico)',

    // Deltoides - Anterior
    'delts_front': 'delts_front (canónico)',
    'delts front': 'delts_front (variante)',
    'deltoide anterior': 'delts_front (español)',
    'deltoide_anterior': 'delts_front (español underscore)',
    'deltoides anterior': 'delts_front (español)',
    'deltoide frontal': 'delts_front (español)',
    'hombro anterior': 'delts_front (español)',

    // Deltoides - Lateral
    'delts_lateral': 'delts_lateral (canónico)',
    'delts lateral': 'delts_lateral (variante)',
    'deltoide lateral': 'delts_lateral (español)',
    'deltoide_lateral': 'delts_lateral (español underscore)',
    'deltoides lateral': 'delts_lateral (español)',
    'side delt lateral': 'delts_lateral (inglés)',
    'hombro lateral': 'delts_lateral (español)',

    // Deltoides - Posterior
    'delts_rear': 'delts_rear (canónico)',
    'delts rear': 'delts_rear (variante)',
    'deltoide posterior': 'delts_rear (español)',
    'deltoide_posterior': 'delts_rear (español underscore)',
    'deltoides posterior': 'delts_rear (español)',
    'rear delt posterior': 'delts_rear (inglés)',
    'hombro posterior': 'delts_rear (español)',

    // Bíceps
    'biceps': 'biceps (canónico)',
    'bicep': 'biceps (variante)',
    'bicepses': 'biceps (plural alterno)',
    'biceps braquial': 'biceps (español)',

    // Tríceps
    'triceps': 'triceps (canónico)',
    'tricep': 'triceps (variante)',
    'tricepses': 'triceps (plural alterno)',
    'triceps braquial': 'triceps (español)',

    // Cuádriceps
    'quads': 'quads (canónico)',
    'quad': 'quads (variante)',
    'cuadriceps': 'quads (español)',
    'cuádriceps': 'quads (español acentuado)',
    'quadriceps': 'quads (clínico)',
    'muslo anterior': 'quads (español)',
    'femorales anteriores': 'quads (español)',

    // Isquios
    'hamstrings': 'hamstrings (canónico)',
    'hamstring': 'hamstrings (variante)',
    'isquios': 'hamstrings (español)',
    'isquiosurales': 'hamstrings (español)',
    'isquiotibiales': 'hamstrings (español)',
    'muslo posterior': 'hamstrings (español)',
    'femorales posteriores': 'hamstrings (español)',

    // Glúteos
    'glutes': 'glutes (canónico)',
    'glute': 'glutes (variante)',
    'gluteo': 'glutes (español)',
    'glúteo': 'glutes (español acentuado)',
    'gluteos': 'glutes (español plural)',
    'glúteos': 'glutes (español plural acentuado)',
    'nalgas': 'glutes (español coloquial)',
    'gluteo maximo': 'glutes (español)',

    // Pantorrillas
    'calves': 'calves (canónico)',
    'calf': 'calves (variante)',
    'pantorrilla': 'calves (español)',
    'pantorrillas': 'calves (español plural)',
    'gemelo': 'calves (español)',
    'gemelos': 'calves (español plural)',
    'gastrocnemio': 'calves (español)',
    'soleo': 'calves (español)',
    'gastrocnemius': 'calves (clínico)',
    'soleus': 'calves (clínico)',

    // Abdominales
    'abs': 'abs (canónico)',
    'abdomen': 'abs (inglés)',
    'abdominales': 'abs (español)',
    'obliques': 'abs (anatomía)',
    'core': 'abs (funcional)',
  };

  /// Lista de la 14 claves canónicas del motor del entrenamiento.
  static const List<String> canonicalKeys = <String>[
    'pectorals',
    'lats',
    'upper_back',
    'traps',
    'delts_front',
    'delts_lateral',
    'delts_rear',
    'biceps',
    'triceps',
    'quads',
    'hamstrings',
    'glutes',
    'calves',
    'abs',
  ];
}
