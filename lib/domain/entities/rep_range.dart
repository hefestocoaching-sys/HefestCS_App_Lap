import 'package:equatable/equatable.dart';

class RepRange extends Equatable {
  final int min;
  final int max;

  const RepRange(this.min, this.max);

  @override
  String toString() => '$min-$max';

  @override
  List<Object?> get props => [min, max];

  Map<String, dynamic> toJson() => {'min': min, 'max': max};

  factory RepRange.fromJson(Map<String, dynamic> json) {
    return RepRange(json['min'] as int? ?? 0, json['max'] as int? ?? 0);
  }
}
