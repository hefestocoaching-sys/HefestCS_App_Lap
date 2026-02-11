import 'package:hcs_app_lap/domain/training/macrocycle_week.dart';

/// Servicio que genera templates de periodización por defecto.
///
/// NO toca:
/// - Cálculo de VME / VMR
/// - Cálculo de VOP
/// - Datos de prioridad
/// - Reparto de intensidades (Pesadas/Medias/Ligeras)
///
/// SOLO genera la estructura anual de multiplicadores.
class MacrocycleTemplateService {
  /// Construye el macrocycle por defecto de 52 semanas.
  ///
  /// Estructura:
  /// - Semana 1: AA (Adaptación Anual) · 1.0×
  /// - Semanas 2–3: AA · incremento progresivo
  /// - Semana 4: AA Deload · 0.6×
  /// - Semanas 5–20: HF1–HF4 · acumulación de volumen
  /// - Semana 21: Deload · 0.6×
  /// - Semanas 22–41: APC1–APC5 · apropiación e intensificación
  /// - Semana 42: Deload · 0.6×
  /// - Semanas 43–51: PC (Pico) · intensidad máxima
  /// - Semana 52: Deload · 0.6×
  static List<MacrocycleWeek> buildDefaultMacrocycle() {
    final weeks = <MacrocycleWeek>[];

    // ════════════════════════════════════════════════════════════════════════
    // AA (Adaptación Anual) — Semanas 1–4
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 1,
        phase: MacroPhase.adaptation,
        block: MacroBlock.AA,
        volumeMultiplier: 1.0,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 2,
        phase: MacroPhase.adaptation,
        block: MacroBlock.AA,
        volumeMultiplier: 1.05,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 3,
        phase: MacroPhase.adaptation,
        block: MacroBlock.AA,
        volumeMultiplier: 1.1,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 4,
        phase: MacroPhase.adaptation,
        block: MacroBlock.AA,
        volumeMultiplier: 0.6,
        isDeload: true,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // HF1 (Hipertrofia 1) — Semanas 5–8
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 5,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF1,
        volumeMultiplier: 1.1,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 6,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF1,
        volumeMultiplier: 1.15,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 7,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF1,
        volumeMultiplier: 1.2,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 8,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF1,
        volumeMultiplier: 0.7,
        isDeload: true,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // HF2 (Hipertrofia 2) — Semanas 9–12
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 9,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF2,
        volumeMultiplier: 1.15,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 10,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF2,
        volumeMultiplier: 1.2,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 11,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF2,
        volumeMultiplier: 1.25,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 12,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF2,
        volumeMultiplier: 0.7,
        isDeload: true,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // HF3 (Hipertrofia 3) — Semanas 13–16
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 13,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF3,
        volumeMultiplier: 1.2,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 14,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF3,
        volumeMultiplier: 1.25,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 15,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF3,
        volumeMultiplier: 1.3,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 16,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF3,
        volumeMultiplier: 0.7,
        isDeload: true,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // HF4 (Hipertrofia 4) — Semanas 17–20
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 17,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF4,
        volumeMultiplier: 1.25,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 18,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF4,
        volumeMultiplier: 1.3,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 19,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF4,
        volumeMultiplier: 1.35,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 20,
        phase: MacroPhase.hypertrophy,
        block: MacroBlock.HF4,
        volumeMultiplier: 0.6,
        isDeload: true,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // APC1 (Apropiación 1) — Semanas 21–23
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 21,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC1,
        volumeMultiplier: 1.15,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 22,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC1,
        volumeMultiplier: 1.2,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 23,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC1,
        volumeMultiplier: 1.1,
        isDeload: false,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // APC2 (Apropiación 2) — Semanas 24–26
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 24,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC2,
        volumeMultiplier: 1.15,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 25,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC2,
        volumeMultiplier: 1.2,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 26,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC2,
        volumeMultiplier: 0.65,
        isDeload: true,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // APC3 (Apropiación 3) — Semanas 27–29
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 27,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC3,
        volumeMultiplier: 1.15,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 28,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC3,
        volumeMultiplier: 1.2,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 29,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC3,
        volumeMultiplier: 1.1,
        isDeload: false,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // APC4 (Apropiación 4) — Semanas 30–32
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 30,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC4,
        volumeMultiplier: 1.15,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 31,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC4,
        volumeMultiplier: 1.2,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 32,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC4,
        volumeMultiplier: 0.65,
        isDeload: true,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // APC5 (Apropiación 5) — Semanas 33–35
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 33,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC5,
        volumeMultiplier: 1.15,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 34,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC5,
        volumeMultiplier: 1.2,
        isDeload: false,
      ),
    );
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 35,
        phase: MacroPhase.intensification,
        block: MacroBlock.APC5,
        volumeMultiplier: 1.1,
        isDeload: false,
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // PC (Pico) — Semanas 36–51
    // ════════════════════════════════════════════════════════════════════════
    for (int i = 36; i <= 41; i++) {
      weeks.add(
        MacrocycleWeek(
          weekNumber: i,
          phase: MacroPhase.peaking,
          block: MacroBlock.PC,
          volumeMultiplier:
              1.0 + ((i - 36) * 0.05), // Incremento gradual 1.0 → 1.3
          isDeload: false,
        ),
      );
    }

    // Deload en semana 42
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 42,
        phase: MacroPhase.peaking,
        block: MacroBlock.PC,
        volumeMultiplier: 0.5,
        isDeload: true,
      ),
    );

    // Pico final
    for (int i = 43; i <= 51; i++) {
      weeks.add(
        MacrocycleWeek(
          weekNumber: i,
          phase: MacroPhase.peaking,
          block: MacroBlock.PC,
          volumeMultiplier: 0.8 + ((i - 43) * 0.04),
          isDeload: false,
        ),
      );
    }

    // ════════════════════════════════════════════════════════════════════════
    // Deload final — Semana 52
    // ════════════════════════════════════════════════════════════════════════
    weeks.add(
      const MacrocycleWeek(
        weekNumber: 52,
        phase: MacroPhase.deload,
        block: MacroBlock.AA, // Reinicia ciclo
        volumeMultiplier: 0.5,
        isDeload: true,
      ),
    );

    return weeks;
  }

  /// Busca una semana específica por número
  static MacrocycleWeek? getWeekByNumber(
    List<MacrocycleWeek> macrocycle,
    int weekNumber,
  ) {
    try {
      return macrocycle.firstWhere((w) => w.weekNumber == weekNumber);
    } catch (_) {
      return null;
    }
  }

  /// Retorna todas las semanas de un bloque específico
  static List<MacrocycleWeek> getWeeksByBlock(
    List<MacrocycleWeek> macrocycle,
    MacroBlock block,
  ) {
    return macrocycle.where((w) => w.block == block).toList();
  }

  /// Retorna todas las semanas de una fase específica
  static List<MacrocycleWeek> getWeeksByPhase(
    List<MacrocycleWeek> macrocycle,
    MacroPhase phase,
  ) {
    return macrocycle.where((w) => w.phase == phase).toList();
  }

  /// Retorna solo las semanas de descarga
  static List<MacrocycleWeek> getDeloadWeeks(List<MacrocycleWeek> macrocycle) {
    return macrocycle.where((w) => w.isDeload).toList();
  }
}
