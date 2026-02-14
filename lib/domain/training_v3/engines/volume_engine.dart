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
    final vop = landmarks['vop']!;
    final vmr = landmarks['vmr']!;

    final vmrTarget = _calculateVmrTarget(
      vop: vop,
      vmr: vmr,
      priority: priority,
    );

    // PASO 2: Calcular volumen base según prioridad
    // Semana 2, Imagen 26-30
    final baseVolume = _calculateBaseVolume(
      vme: vme,
      vop: vop,
      priority: priority,
    );

    // PASO 3: Si hay volumen actual, aplicar progresión
    // Semana 2, Imagen 21-25: +1-4 sets por semana
    int targetVolume;
    if (currentVolume != null && currentVolume > 0) {
      targetVolume = _applyProgression(
        currentVolume: currentVolume,
        baseVolume: baseVolume,
        vmrTarget: vmrTarget,
      );
    } else {
      targetVolume = baseVolume;
    }

    // PASO 4: Validar contra MRV (safety)
    // Semana 1, Imagen 16-20
    if (targetVolume > vmr) {
      logger.warning('Target volume exceeds VMR, reducing to safe limit', {
        'muscle': muscle,
        'targetVolume': targetVolume,
        'vmr': vmr,
      });
      targetVolume = vmr;
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
      'pectorals': {
        'novice': {'vme': 10, 'vop': 15, 'vmr': 20},
        'intermediate': {'vme': 12, 'vop': 18, 'vmr': 24},
        'advanced': {'vme': 15, 'vop': 22, 'vmr': 28},
      },
      // Hombros divididos en 3 cabezas
      'deltoide_anterior': {
        'novice': {'vme': 4, 'vop': 6, 'vmr': 8},
        'intermediate': {'vme': 5, 'vop': 8, 'vmr': 10},
        'advanced': {'vme': 6, 'vop': 10, 'vmr': 12},
      },
      'deltoide_lateral': {
        'novice': {'vme': 4, 'vop': 6, 'vmr': 8},
        'intermediate': {'vme': 5, 'vop': 8, 'vmr': 10},
        'advanced': {'vme': 6, 'vop': 10, 'vmr': 12},
      },
      'deltoide_posterior': {
        'novice': {'vme': 4, 'vop': 6, 'vmr': 8},
        'intermediate': {'vme': 5, 'vop': 8, 'vmr': 10},
        'advanced': {'vme': 6, 'vop': 10, 'vmr': 12},
      },
      'triceps': {
        'novice': {'vme': 6, 'vop': 10, 'vmr': 14},
        'intermediate': {'vme': 8, 'vop': 12, 'vmr': 16},
        'advanced': {'vme': 10, 'vop': 15, 'vmr': 20},
      },
      // Espalda dividida en 3 regiones
      'lats': {
        'novice': {'vme': 6, 'vop': 10, 'vmr': 14},
        'intermediate': {'vme': 8, 'vop': 12, 'vmr': 16},
        'advanced': {'vme': 10, 'vop': 15, 'vmr': 20},
      },
      'upper_back': {
        'novice': {'vme': 4, 'vop': 6, 'vmr': 8},
        'intermediate': {'vme': 5, 'vop': 8, 'vmr': 10},
        'advanced': {'vme': 6, 'vop': 10, 'vmr': 12},
      },
      'traps': {
        'novice': {'vme': 4, 'vop': 6, 'vmr': 8},
        'intermediate': {'vme': 5, 'vop': 8, 'vmr': 10},
        'advanced': {'vme': 6, 'vop': 10, 'vmr': 12},
      },
      'biceps': {
        'novice': {'vme': 6, 'vop': 10, 'vmr': 14},
        'intermediate': {'vme': 8, 'vop': 12, 'vmr': 16},
        'advanced': {'vme': 10, 'vop': 15, 'vmr': 20},
      },
      'quadriceps': {
        'novice': {'vme': 10, 'vop': 15, 'vmr': 20},
        'intermediate': {'vme': 12, 'vop': 18, 'vmr': 24},
        'advanced': {'vme': 15, 'vop': 22, 'vmr': 28},
      },
      'hamstrings': {
        'novice': {'vme': 8, 'vop': 12, 'vmr': 16},
        'intermediate': {'vme': 10, 'vop': 15, 'vmr': 20},
        'advanced': {'vme': 12, 'vop': 18, 'vmr': 24},
      },
      'glutes': {
        'novice': {'vme': 8, 'vop': 12, 'vmr': 16},
        'intermediate': {'vme': 10, 'vop': 15, 'vmr': 20},
        'advanced': {'vme': 12, 'vop': 18, 'vmr': 24},
      },
      'calves': {
        'novice': {'vme': 8, 'vop': 12, 'vmr': 16},
        'intermediate': {'vme': 10, 'vop': 15, 'vmr': 20},
        'advanced': {'vme': 12, 'vop': 18, 'vmr': 24},
      },
      'abs': {
        'novice': {'vme': 6, 'vop': 10, 'vmr': 14},
        'intermediate': {'vme': 8, 'vop': 12, 'vmr': 16},
        'advanced': {'vme': 10, 'vop': 15, 'vmr': 20},
      },
    };

    return landmarksByMuscle[muscle]![level]!;
  }

  /// Calcula volumen base según prioridad
  ///
  /// FUENTE: Semana 2, Imagen 26-30
  ///
  /// ESCALA DE PRIORIDAD:
  /// 5 (máxima) → VOP (punto optimo)
  /// 4          → VOP - 20%
  /// 3 (media)  → Punto medio VME-VOP
  /// 2          → VME + 20%
  /// 1 (mínima) → VME (limite inferior)
  static int _calculateBaseVolume({
    required int vme,
    required int vop,
    required int priority,
  }) {
    switch (priority) {
      case 5:
        return vop; // Punto optimo inicial
      case 4:
        return vop - ((vop - vme) * 0.2).round();
      case 3:
        return ((vme + vop) / 2).round();
      case 2:
        return vme + ((vop - vme) * 0.2).round();
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
  /// - Si volumen actual < VMR target: aumentar ~20%
  /// - Nunca exceder VMR target
  static int _applyProgression({
    required int currentVolume,
    required int baseVolume,
    required int vmrTarget,
  }) {
    if (currentVolume < vmrTarget) {
      final increment = (currentVolume * 0.20).round();
      final newVolume = currentVolume + (increment < 1 ? 1 : increment);
      return newVolume > vmrTarget ? vmrTarget : newVolume;
    }

    return baseVolume;
  }

  static int _calculateVmrTarget({
    required int vop,
    required int vmr,
    required int priority,
  }) {
    if (priority >= 5) {
      return vmr;
    }

    if (priority >= 3) {
      return (vmr * 0.75).round();
    }

    return vop;
  }

  /// Valida parámetros de entrada
  static void _validateInputs(String muscle, String level, int priority) {
    final validMuscles = [
      'pectorals',
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
      'triceps',
      'lats',
      'upper_back',
      'traps',
      'biceps',
      'quadriceps',
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
    final vop = landmarks['vop']!;
    final vmr = landmarks['vmr']!;

    // Óptimo = entre MAV y MRV (zona de alto crecimiento)
    return volume >= vop && volume <= vmr;
  }
}
