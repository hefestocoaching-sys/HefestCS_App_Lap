// lib/domain/training_v3/engines/intensity_engine.dart

import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

// [V3][P0] Intensity zone range constants
const int kHeavyMin = 15;
const int kHeavyMax = 30;
const int kMediumMin = 40;
const int kMediumMax = 70;
const int kLightMin = 15;
const int kLightMax = 30;

/// Motor de distribución de intensidad por ejercicio
///
/// Implementa las reglas científicas de la Semana 3 (12 imágenes):
/// - Distribución óptima: 20% heavy, 60% medium, 20% light
/// - Heavy: 6-8 reps, >85% 1RM
/// - Medium: 8-12 reps, 70-85% 1RM
/// - Light: 16-20 reps, 60-70% 1RM
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 3, Imagen 26: Curva de hipertrofia por intensidad
/// - Semana 3, Imagen 27-29: Distribución 20/60/20
/// - Semana 3, Imagen 30-32: Heavy para fuerza + hipertrofia
/// - Semana 3, Imagen 33-35: Medium para hipertrofia pura
///
/// REFERENCIAS:
/// - Schoenfeld et al. (2021): Hypertrophy across loading ranges
/// - Lasevicius et al. (2018): Muscle growth with different intensities
///
/// Versión: 1.0.0
class IntensityEngine {
  // ── P0.2-IE-2: Default split (no log/bitácora) ──
  Map<String, int> defaultSplitNoLog() {
    return const {
      IntensityZone.heavy: 20,
      IntensityZone.medium: 60,
      IntensityZone.light: 20,
    };
  }

  // ── P0.2-IE-3: Validator ──
  Map<String, int> validateOrDefaultSplit(Map<String, int> split) {
    final heavy = split[IntensityZone.heavy] ?? -1;
    final medium = split[IntensityZone.medium] ?? -1;
    final light = split[IntensityZone.light] ?? -1;
    final total = heavy + medium + light;

    final ok =
        (heavy >= kHeavyMin && heavy <= kHeavyMax) &&
        (medium >= kMediumMin && medium <= kMediumMax) &&
        (light >= kLightMin && light <= kLightMax) &&
        (total == 100);

    return ok ? split : defaultSplitNoLog();
  }

  // ── P0.2-IE-4: Deterministic set split for a day ──
  Map<String, int> computeSetSplitForDay({
    required int setsForDay,
    Map<String, int>? desiredSplit,
  }) {
    final split = validateOrDefaultSplit(desiredSplit ?? defaultSplitNoLog());

    final heavyPct = split['heavy']!;
    final lightPct = split['light']!;

    final heavySets = (setsForDay * (heavyPct / 100.0)).round();
    final lightSets = (setsForDay * (lightPct / 100.0)).round();
    final mediumSets = setsForDay - heavySets - lightSets;

    return {
      IntensityZone.heavy: heavySets < 0 ? 0 : heavySets,
      IntensityZone.medium: mediumSets < 0 ? 0 : mediumSets,
      IntensityZone.light: lightSets < 0 ? 0 : lightSets,
    };
  }

  /// Distribuye intensidades a una lista de ejercicios
  ///
  /// ALGORITMO:
  /// 1. Calcular cuántos ejercicios por zona (20/60/20)
  /// 2. Asignar heavy a compounds grandes primero
  /// 3. Asignar medium a compounds auxiliares
  /// 4. Asignar light a aislamiento
  ///
  /// PARÁMETROS:
  /// - [exercises]: Lista de IDs de ejercicios
  /// - [exerciseTypes]: Mapa ejercicio → tipo ('compound'/'isolation')
  ///
  /// RETORNA:
  /// - Map&lt;String, String&gt;: ejercicioId → 'heavy'|'medium'|'light'
  static Map<String, String> distributeIntensities({
    required List<String> exercises,
    required Map<String, String> exerciseTypes,
    int dayIndex = 0,
  }) {
    final ordered = List<String>.from(exercises)..sort();
    final intensities = <String, String>{};

    if (ordered.isEmpty) return intensities;

    final totalExercises = ordered.length;
    int heavyCount = (totalExercises * 0.20).round();
    int mediumCount = (totalExercises * 0.60).round();
    int lightCount = totalExercises - heavyCount - mediumCount;

    if (dayIndex.isOdd) {
      heavyCount = 0;
      mediumCount = (totalExercises * 0.60).round();
      lightCount = totalExercises - mediumCount;
    }

    List<String> availableForZone(String zone) {
      return ordered.where((id) {
        if (intensities.containsKey(id)) return false;
        return ExerciseCatalogV3.allowsZone(id, zone);
      }).toList();
    }

    void assignZone({
      required String zone,
      required int count,
      bool compoundsFirst = false,
    }) {
      if (count <= 0) return;
      var candidates = availableForZone(zone);
      if (compoundsFirst) {
        candidates.sort((a, b) {
          final aCompound = exerciseTypes[a] == 'compound';
          final bCompound = exerciseTypes[b] == 'compound';
          if (aCompound != bCompound) return aCompound ? -1 : 1;
          return a.compareTo(b);
        });
      }

      if (candidates.length < count) {
        throw StateError(
          '[IntensityEngine][STRICT_NO_FALLBACK] No hay suficientes ejercicios para zona=$zone '
          'requested=$count available=${candidates.length} total=$totalExercises',
        );
      }

      for (var i = 0; i < count; i++) {
        intensities[candidates[i]] = zone;
      }
    }

    assignZone(
      zone: IntensityZone.heavy,
      count: heavyCount,
      compoundsFirst: true,
    );
    assignZone(
      zone: IntensityZone.medium,
      count: mediumCount,
      compoundsFirst: true,
    );
    assignZone(zone: IntensityZone.light, count: lightCount);

    if (intensities.length != totalExercises) {
      throw StateError(
        '[IntensityEngine][STRICT_NO_FALLBACK] Intensidad incompleta: '
        'assigned=${intensities.length} total=$totalExercises',
      );
    }

    return intensities;
  }

  /// Obtiene el rango de repeticiones para una zona de intensidad
  ///
  /// FUENTE: Semana 3, Imagen 30-35
  static List<int> getRepRangeForIntensity(String intensity) {
    switch (intensity) {
      case IntensityZone.heavy:
        return [6, 8]; // Fuerza + hipertrofia
      case IntensityZone.medium:
        return [8, 12]; // Hipertrofia óptima
      case IntensityZone.light:
        return [16, 20]; // Hipertrofia metabólica
      default:
        throw ArgumentError('Intensidad inválida: $intensity');
    }
  }

  /// Obtiene el descanso recomendado para una zona de intensidad
  ///
  /// FUENTE: Semana 3, complementario
  static int getRestSecondsForIntensity(String intensity) {
    switch (intensity) {
      case IntensityZone.heavy:
        return 240; // 4 minutos (180-300s)
      case IntensityZone.medium:
        return 120; // 2 minutos (90-180s)
      case IntensityZone.light:
        return 75; // 75 segundos (60-90s)
      default:
        throw ArgumentError('Intensidad inválida: $intensity');
    }
  }

  /// Valida que la distribución sea científica
  static bool isDistributionValid(Map<String, String> intensities) {
    if (intensities.isEmpty) return false;

    final total = intensities.length;
    final heavyCount = intensities.values
        .where((i) => i == IntensityZone.heavy)
        .length;
    final mediumCount = intensities.values
        .where((i) => i == IntensityZone.medium)
        .length;
    final lightCount = intensities.values
        .where((i) => i == IntensityZone.light)
        .length;

    // Calcular porcentajes
    final heavyPct = heavyCount / total;
    final mediumPct = mediumCount / total;
    final lightPct = lightCount / total;

    final sumOk = ((heavyPct + mediumPct + lightPct) - 1.0).abs() <= 0.001;
    if (!sumOk) return false;

    if (heavyPct < 0.15 || heavyPct > 0.30) return false;
    if (mediumPct < 0.40 || mediumPct > 0.70) return false;
    if (lightPct < 0.15 || lightPct > 0.30) return false;

    return true;
  }
}
