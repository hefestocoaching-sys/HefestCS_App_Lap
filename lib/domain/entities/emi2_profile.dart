/// Representa un registro del Índice de Masa Muscular Esquelética (EMI-2).
class Emi2Profile {
  final double? emi2Score;
  final String? classification;
  final DateTime date;
  final String? notes;

  const Emi2Profile({
    this.emi2Score,
    this.classification,
    required this.date,
    this.notes,
  });

  Emi2Profile copyWith({
    double? emi2Score,
    String? classification,
    DateTime? date,
    String? notes,
  }) {
    return Emi2Profile(
      emi2Score: emi2Score ?? this.emi2Score,
      classification: classification ?? this.classification,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emi2Score': emi2Score,
      'classification': classification,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Emi2Profile.fromJson(Map<String, dynamic> map) {
    return Emi2Profile(
      emi2Score: map['emi2Score'] as double?,
      classification: map['classification'] as String?,
      date: DateTime.parse(
        map['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      notes: map['notes'] as String?,
    );
  }
}
