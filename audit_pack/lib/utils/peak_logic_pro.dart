// lib/utils/peak_logic_pro.dart

// Modelo para la salida de datos
class PeakOutput {
  final String riesgo;
  final String accion;
  final double protG;
  final double choG;
  final double grasaG;
  final double aguaMl;
  final double sodioMg;
  final double potasioMg;
  final double creatinaG;
  final double glicerolG;

  PeakOutput({
    required this.riesgo,
    required this.accion,
    required this.protG,
    required this.choG,
    required this.grasaG,
    required this.aguaMl,
    required this.sodioMg,
    required this.potasioMg,
    required this.creatinaG,
    required this.glicerolG,
  });
}

class PeakLogicPro {
  // <<<--- MODIFICACIÓN: Protocolo de 8 Días (D-7 a D-0) ---
  // El mapa ahora comienza en -7, alineado con la evidencia.
  static final Map<int, Map<String, double>> _baseTargets = {
    // Fase 1: Depleción y Sensibilización (Sodio/Agua ALTOS) [cite: 756-763]
    -7: {
      'prot': 2.5,
      'cho': 1.0,
      'grasa': 0.8,
      'agua': 70,
      'sodio': 5000,
      'k': 4000,
    }, // Día de depleción
    -6: {
      'prot': 2.5,
      'cho': 1.0,
      'grasa': 0.8,
      'agua': 70,
      'sodio': 5000,
      'k': 4000,
    }, // Día de depleción
    -5: {
      'prot': 2.5,
      'cho': 1.0,
      'grasa': 0.8,
      'agua': 70,
      'sodio': 5000,
      'k': 4000,
    }, // Día de depleción
    // Fase 2: Carga de Glucógeno "Front-Load" (CHO/Sodio/Agua ALTOS) [cite: 764-774]
    -4: {
      'prot': 2.0,
      'cho': 10.0,
      'grasa': 0.3,
      'agua': 80,
      'sodio': 5000,
      'k': 4000,
    }, // Carga
    -3: {
      'prot': 2.0,
      'cho': 10.0,
      'grasa': 0.3,
      'agua': 80,
      'sodio': 5000,
      'k': 4000,
    }, // Carga
    -2: {
      'prot': 2.0,
      'cho': 10.0,
      'grasa': 0.3,
      'agua': 80,
      'sodio': 5000,
      'k': 4000,
    }, // Carga
    // Fase 3: Transición y Diuresis (Sodio ALTO, Agua MODERADA) [cite: 775-780]
    -1: {
      'prot': 2.0,
      'cho': 4.0,
      'grasa': 0.3,
      'agua': 40,
      'sodio': 5000,
      'k': 4000,
    }, // Transición
    // Fase 4: Día del Show (Comidas reactivas) [cite: 783-788]
    0: {
      'prot': 1.5,
      'cho': 2.0,
      'grasa': 0.2,
      'agua': 15,
      'sodio': 3000,
      'k': 3000,
    },
  };
  // <<<--- FIN DE LA MODIFICACIÓN ---

  // --- Helpers y Límites de Seguridad ---
  static double _clampDouble(double val, double minV, double maxV) {
    if (val.isNaN) {
      return minV;
    }
    return val.clamp(minV, maxV);
  }

  static bool _isDangerous(double pesoPct, int? urineColor) {
    // Un cambio >3% SÍ es peligroso.
    if (pesoPct.abs() > 3.0) {
      return true;
    }
    return false;
  }

  static PeakOutput compute({
    required double pesoToday,
    required double? pesoPrev,
    required double? abdFoldToday,
    required double? abdFoldPrev,
    required double? waistToday,
    required double? waistPrev,
    required int? urineColor,
    required int daysUntilCompetition,
    required bool useCreatine,
    required bool useGlycerol,
    bool isFlat = false,
    bool isSpillover = false,
    bool isPeak3D = false,
    required double? bfPercent,
    required String sexo,
    bool glycerolTested = false,
  }) {
    // 1. OBTENER VALORES BASE
    final targets =
        _baseTargets[daysUntilCompetition] ??
        {
          'prot': 2.2,
          'cho': 3.0,
          'grasa': 1.0,
          'agua': 40,
          'sodio': 3000,
          'k': 3500,
        };
    double protKg = (targets['prot'] as num?)?.toDouble() ?? 2.2;
    double choKg = (targets['cho'] as num?)?.toDouble() ?? 3.0;
    double grasaKg = (targets['grasa'] as num?)?.toDouble() ?? 1.0;
    double aguaMlKg = (targets['agua'] as num?)?.toDouble() ?? 40.0;
    double sodioMg = (targets['sodio'] as num?)?.toDouble() ?? 3000.0;
    double potasioMg = (targets['k'] as num?)?.toDouble() ?? 3500.0;

    String riesgo = "OK";
    String accion = "Mantener plan base del día.";

    // 2. LÓGICA REACTIVA DE MÁXIMA PRIORIDAD (Basada en PDF 2, Tabla 3)
    if (isPeak3D) {
      // Escenario 4: PICO 3D (ÉXITO)
      riesgo = "ÉXITO";
      accion =
          "Escenario 4 (PICO 3D): ¡Éxito! NO CAMBIAR NADA. Mantener este plan y repetir comidas/líquidos.";
    } else if (isFlat && isSpillover) {
      // Escenario 3: PLANO y BORRADO (Falla de Carga)
      riesgo = "CRÍTICO";
      accion =
          "Escenario 3 (Plano y Borrado): Falla de Carga (SGLT1 inhibido por bajo Na o estrés). PROTOCOLO RESET: Aplicar 100g CH + 1500mg Na + 1L Agua/Glicerol. Re-evaluar en 3h.";
      choKg = 4.0;
      sodioMg = 5500;
      aguaMlKg = 55;
    } else if (isSpillover) {
      // Escenario 2: LLENO pero BORRADO (Spillover)
      riesgo = "ATENCIÓN";
      accion =
          "Escenario 2 (Spillover): Saturación de glucógeno. Reduciendo CHO. ¡MANTENER SODIO Y AGUA ALTOS para aclarar!";
      choKg *= 0.6;
    } else if (isFlat) {
      // Escenario 1: PLANO y SECO
      riesgo = "MEDIA";
      accion =
          "Escenario 1 (Plano y Seco): Carga insuficiente o deshidratación. Forzando llenado con +CH, +Sodio y +Agua.";
      choKg += 1.0;
      sodioMg += 1000;
      aguaMlKg += 15;
    } else {
      // 3. AJUSTES POR MÉTRICAS (Solo si no hay feedback visual)
      if (pesoPrev != null && pesoPrev > 0) {
        final pesoPct = (pesoToday - pesoPrev) / pesoPrev * 100;
        final abdFoldPct =
            (abdFoldToday != null && abdFoldPrev != null && abdFoldPrev > 0)
            ? ((abdFoldToday - abdFoldPrev) / abdFoldPrev) * 100
            : 0.0;
        final waistDelta =
            (waistToday != null && waistPrev != null && waistPrev > 0)
            ? (waistToday - waistPrev)
            : 0.0;

        if (_isDangerous(pesoPct, urineColor)) {
          riesgo = "ALTA";
          accion =
              "Cambio de peso >3%. ALERTA. Evaluar visualmente y aplicar protocolo reactivo (Escenarios 1, 2 o 3).";
        } else {
          // Refuerza Escenario 1 (Plano/Seco)
          if (urineColor != null && urineColor >= 7) {
            riesgo = "MEDIA";
            accion = "Orina oscura. Reforzando carga de fluidos.";
            aguaMlKg += 15;
            sodioMg += 500;
          }
          // Refuerza Escenario 2 (Spillover)
          else if (urineColor != null &&
              urineColor <= 2 &&
              (pesoPct > 1 || abdFoldPct > 1.5 || waistDelta > 1.0)) {
            riesgo = "MEDIA";
            accion =
                "Posible retención/Spillover (Orina clara + Aumento de pliegue/peso/cintura). Reduciendo CHO.";
            choKg *= 0.8;
          }

          // Lógica de Pliegue Abdominal y Cintura
          if (abdFoldPct > 1.5 || waistDelta > 1.0) {
            riesgo = "ATENCIÓN";
            accion =
                "Pliegue abdominal o cintura han aumentado. Riesgo de spillover. Reduciendo CHO.";
            choKg *= 0.75;
          } else if (abdFoldPct < -1.5 || waistDelta < -0.5) {
            if (riesgo == "OK") {
              accion =
                  "Pliegue abdominal o cintura reducidos. Buen progreso. Mantener plan.";
            }
          }
        }
      }
    }

    // 4. RESTRINGIR RANGOS FINALES (CLAMPING)
    protKg = _clampDouble(protKg, 1.5, 3.0);
    choKg = _clampDouble(choKg, 0.5, 12.0);
    grasaKg = _clampDouble(grasaKg, 0.2, 1.0);
    aguaMlKg = _clampDouble(aguaMlKg, 10.0, 90.0);
    sodioMg = _clampDouble(sodioMg, 2000.0, 7000.0);
    potasioMg = _clampDouble(potasioMg, 3000.0, 5000.0);

    // 5. CÁLCULOS TOTALES
    final double protG = (protKg * pesoToday);
    final double choG = (choKg * pesoToday);
    final double grasaG = (grasaKg * pesoToday);
    final double aguaMl = (aguaMlKg * pesoToday);

    final double creatinaG = useCreatine
        ? _clampDouble(0.03 * pesoToday, 3.0, 5.0)
        : 0.0;

    double glicerolG = 0.0;
    if (useGlycerol && daysUntilCompetition <= 1 && glycerolTested) {
      glicerolG = _clampDouble(
        1.0 * pesoToday,
        0.8 * pesoToday,
        1.5 * pesoToday,
      );
    }

    return PeakOutput(
      riesgo: riesgo,
      accion: accion,
      protG: protG,
      choG: choG,
      grasaG: grasaG,
      aguaMl: aguaMl,
      sodioMg: sodioMg,
      potasioMg: potasioMg,
      creatinaG: creatinaG,
      glicerolG: glicerolG,
    );
  }
}
