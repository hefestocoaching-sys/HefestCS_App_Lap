/// Severidad clínica de intolerancias digestivas (P0)
enum DigestiveSeverity { none, mild, moderate, severe }

/// ═══════════════════════════════════════════════════════════════════════════
/// Intolerancias digestivas clínicamente relevantes (P0)
/// ═══════════════════════════════════════════════════════════════════════════
/// SSOT: 3 intolerancias principales (evidencia clínica)
/// - Lactosa: prevalencia ~65% población mundial
/// - Gluten: celíaca + sensibilidad no-celíaca
/// - FODMAPs: IBS/SIBO
///
/// Cada una tiene severidad: none/mild/moderate/severe
class DigestiveIntolerances {
  final DigestiveSeverity lactose; // Deficiencia de lactasa
  final DigestiveSeverity gluten; // Celiaquía o sensibilidad
  final DigestiveSeverity fodmaps; // Mala absorción de oligosacáridos/polioles

  const DigestiveIntolerances({
    this.lactose = DigestiveSeverity.none,
    this.gluten = DigestiveSeverity.none,
    this.fodmaps = DigestiveSeverity.none,
  });

  /// Defaults seguros (sin intolerancias diagnosticadas)
  factory DigestiveIntolerances.defaults() {
    return const DigestiveIntolerances();
  }

  /// Deserialización segura desde Map
  factory DigestiveIntolerances.fromMap(Map<String, dynamic> map) {
    DigestiveSeverity parseSeverity(dynamic value) {
      if (value is String) {
        return DigestiveSeverity.values.firstWhere(
          (e) => e.name == value,
          orElse: () => DigestiveSeverity.none,
        );
      }
      return DigestiveSeverity.none;
    }

    return DigestiveIntolerances(
      lactose: parseSeverity(map['lactose']),
      gluten: parseSeverity(map['gluten']),
      fodmaps: parseSeverity(map['fodmaps']),
    );
  }

  /// Serialización segura a Map
  Map<String, dynamic> toMap() {
    return {
      'lactose': lactose.name,
      'gluten': gluten.name,
      'fodmaps': fodmaps.name,
    };
  }

  DigestiveIntolerances copyWith({
    DigestiveSeverity? lactose,
    DigestiveSeverity? gluten,
    DigestiveSeverity? fodmaps,
  }) {
    return DigestiveIntolerances(
      lactose: lactose ?? this.lactose,
      gluten: gluten ?? this.gluten,
      fodmaps: fodmaps ?? this.fodmaps,
    );
  }

  @override
  String toString() {
    return 'DigestiveIntolerances(lactose: $lactose, gluten: $gluten, fodmaps: $fodmaps)';
  }
}
