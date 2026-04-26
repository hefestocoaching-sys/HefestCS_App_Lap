class IntensitySplit {
  final double heavy;
  final double medium;
  final double light;

  const IntensitySplit({
    required this.heavy,
    required this.medium,
    required this.light,
  });

  double get total => heavy + medium + light;

  bool get isWithinBounds =>
      heavy >= 15 &&
      heavy <= 30 &&
      medium >= 40 &&
      medium <= 70 &&
      light >= 15 &&
      light <= 30;

  bool get sumsTo100 => (total - 100).abs() < 0.0001;

  bool get isValid => isWithinBounds && sumsTo100;

  Map<String, double> toMap() => {
    'heavy': heavy,
    'medium': medium,
    'light': light,
  };

  factory IntensitySplit.fromMap(Map<String, dynamic> map) {
    return IntensitySplit(
      heavy: (map['heavy'] as num?)?.toDouble() ?? 20,
      medium: (map['medium'] as num?)?.toDouble() ?? 60,
      light: (map['light'] as num?)?.toDouble() ?? 20,
    );
  }

  static const IntensitySplit defaultSplit = IntensitySplit(
    heavy: 20,
    medium: 60,
    light: 20,
  );
}
