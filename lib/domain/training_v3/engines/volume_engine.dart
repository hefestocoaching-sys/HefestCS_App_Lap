// lib/domain/training_v3/engines/volume_engine.dart

import 'package:hcs_app_lap/core/utils/app_logger.dart';

/// Motor de cálculo de volumen óptimo por músculo
///
/// Implementa las reglas científicas de las Semanas 1-2 (35 imágenes):
/// - VME (Volumen Mínimo Efectivo): Umbral para generar adaptación
/// - MAV (Volumen Adaptativo Máximo): Punto óptimo de hipertrofia
/// - MRV (Volumen Máximo Recuperable): Límite antes de sobreentrenamiento
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 1, Imagen 1-5: Landmarks de volumen por nivel
/// - Semana 1, Imagen 6-10: VME por músculo
/// - Semana 1, Imagen 11-15: MAV por músculo
/// - Semana 1, Imagen 16-20: MRV por músculo
/// - Semana 2, Imagen 21-25: Progresión volumétrica (+1-4 sets/semana)
/// - Semana 2, Imagen 26-30: Ajuste por prioridad muscular
/// - Semana 2, Imagen 31-35: Fatiga y recuperación
///
/// REFERENCIAS:
/// - Schoenfeld et al. (2017): Dose-response relationship
/// - Baz-Valle et al. (2021): Systematic review volume
/// - Israetel et al. (2020): Volume landmarks
///
/// Versión: 1.0.0
class VolumeEngine {
  /// Calcula el volumen semanal óptimo para un músculo específico
  ///
  /// ALGORITMO:
  /// 1. Obtener landmarks según nivel (VME/MAV/MRV)
  /// 2. Seleccionar volumen base según prioridad
  /// 3. Aplicar progresión si hay volumen actual
  /// 4. Validar contra MRV (safety check)
  ///
  /// PARÁMETROS:
  /// - [muscle]: ID del músculo ('chest', 'quads', 'back', etc.)
  /// - [trainingLevel]: 'novice' | 'intermediate' | 'advanced'
  /// - [priority]: 1-5 (1=mínimo, 5=máximo)
  /// - [currentVolume]: Sets actuales (opcional, para progresión)
  ///
  /// RETORNA:
  /// - int: Sets semanales recomendados
  static int calculateOptimalVolume({
    required String muscle,
    required String trainingLevel,
    required int priority,
    int? currentVolume,
  }) {
    // VALIDACIÓN DE ENTRADA
    _validateInputs(muscle, trainingLevel, priority);

    // PASO 1: Obtener landmarks según nivel
    // Semana 1, Imagen 1-20
    final landmarks = _getVolumeLandmarks(muscle, trainingLevel);
    final vme = landmarks['vme']!;
    final mav = landmarks['mav']!;
    final mrv = landmarks['mrv']!;

    // PASO 2: Calcular volumen base según prioridad
    // Semana 2, Imagen 26-30
    final baseVolume = _calculateBaseVolume(
      vme: vme,
      mav: mav,
      priority: priority,
    );

    // PASO 3: Si hay volumen actual, aplicar progresión
    // Semana 2, Imagen 21-25: +1-4 sets por semana
    int targetVolume;
    if (currentVolume != null && currentVolume > 0) {
      targetVolume = _applyProgression(
        currentVolume: currentVolume,
        baseVolume: baseVolume,
        mav: mav,
        mrv: mrv,
      );
    } else {
      targetVolume = baseVolume;
    }

    // PASO 4: Validar contra MRV (safety)
    // Semana 1, Imagen 16-20
    if (targetVolume > mrv) {
      logger.warning('Target volume exceeds MRV, reducing to safe limit', {
        'muscle': muscle,
        'targetVolume': targetVolume,
        'mrv': mrv,
      });
      targetVolume = mrv;
    }

    // PASO 5: Validar que no sea menor a VME
    if (targetVolume < vme) {
      logger.warning('Target volume below VME, increasing to minimum', {
        'muscle': muscle,
        'targetVolume': targetVolume,
        'vme': vme,
      });
      targetVolume = vme;
    }

    return targetVolume;
  }

  /// Obtiene los landmarks de volumen según músculo y nivel
  ///
  /// FUENTE: Semana 1, Imagen 1-20
  ///
  /// NOTA: Estos valores son promedios científicos.
  /// Individuos pueden variar ±20%
  static Map<String, int> _getVolumeLandmarks(String muscle, String level) {
    // Tabla científica completa basada en Israetel et al. (2020)
    // Actualizada a 14 músculos canónicos
    final landmarksByMuscle = {
      'chest': {
        'novice': {'vme': 10, 'mav': 15, 'mrv': 20},
        'intermediate': {'vme': 12, 'mav': 18, 'mrv': 24},
        'advanced': {'vme': 15, 'mav': 22, 'mrv': 28},
      },
      // Hombros divididos en 3 cabezas
      'deltoide_anterior': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'deltoide_lateral': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'deltoide_posterior': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'triceps': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
      // Espalda dividida en 3 regiones
      'lats': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
      'upper_back': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'traps': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'biceps': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
      'quads': {
        'novice': {'vme': 10, 'mav': 15, 'mrv': 20},
        'intermediate': {'vme': 12, 'mav': 18, 'mrv': 24},
        'advanced': {'vme': 15, 'mav': 22, 'mrv': 28},
      },
      'hamstrings': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'glutes': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'calves': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'abs': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
    };

    return landmarksByMuscle[muscle]![level]!;
  }

  /// Calcula volumen base según prioridad
  ///
  /// FUENTE: Semana 2, Imagen 26-30
  ///
  /// ESCALA DE PRIORIDAD:
  /// 5 (máxima) → MAV (límite superior)
  /// 4          → MAV - 20%
  /// 3 (media)  → Punto medio VME-MAV
  /// 2          → VME + 20%
  /// 1 (mínima) → VME (límite inferior)
  static int _calculateBaseVolume({
    required int vme,
    required int mav,
    required int priority,
  }) {
    switch (priority) {
      case 5:
        return mav; // Máximo adaptativo
      case 4:
        return mav - ((mav - vme) * 0.2).round();
      case 3:
        return ((vme + mav) / 2).round(); // Punto medio
      case 2:
        return vme + ((mav - vme) * 0.2).round();
      case 1:
        return vme; // Mínimo efectivo
      default:
        throw ArgumentError('Priority debe estar entre 1-5');
    }
  }

  /// Aplica progresión volumétrica conservadora
  ///
  /// FUENTE: Semana 2, Imagen 21-25
  ///
  /// REGLAS:
  /// - Si volumen actual < MAV: Aumentar +2 sets (conservador)
  /// - Si volumen actual >= MAV: Aumentar +1 set (muy conservador)
  /// - Nunca exceder MRV
  static int _applyProgression({
    required int currentVolume,
    required int baseVolume,
    required int mav,
    required int mrv,
  }) {
    // Si está por debajo del MAV, progresión moderada
    if (currentVolume < mav) {
      final newVolume = currentVolume + 2;
      return newVolume > mrv ? mrv : newVolume;
    }

    // Si está en o sobre MAV, progresión conservadora
    final newVolume = currentVolume + 1;
    return newVolume > mrv ? mrv : newVolume;
  }

  /// Valida parámetros de entrada
  static void _validateInputs(String muscle, String level, int priority) {
    final validMuscles = [
      'chest',
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
      'triceps',
      'lats',
      'upper_back',
      'traps',
      'biceps',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'abs',
    ];

    if (!validMuscles.contains(muscle)) {
      throw ArgumentError(
        'Músculo inválido: $muscle. '
        'Opciones válidas: ${validMuscles.join(", ")}',
      );
    }

    final validLevels = ['novice', 'intermediate', 'advanced'];
    if (!validLevels.contains(level)) {
      throw ArgumentError(
        'Nivel inválido: $level. '
        'Opciones válidas: ${validLevels.join(", ")}',
      );
    }

    if (priority < 1 || priority > 5) {
      throw ArgumentError('Priority debe estar entre 1-5');
    }
  }

  /// Calcula volumen total semanal para todos los músculos
  ///
  /// USADO POR: Validación de carga total de entrenamiento
  static int calculateTotalWeeklyVolume(Map<String, int> volumeByMuscle) {
    return volumeByMuscle.values.fold(0, (sum, vol) => sum + vol);
  }

  /// Verifica si el volumen está en rango óptimo
  static bool isVolumeOptimal({
    required int volume,
    required String muscle,
    required String trainingLevel,
  }) {
    final landmarks = _getVolumeLandmarks(muscle, trainingLevel);
    final mav = landmarks['mav']!;
    final mrv = landmarks['mrv']!;

    // Óptimo = entre MAV y MRV (zona de alto crecimiento)
    return volume >= mav && volume <= mrv;
  }
}
