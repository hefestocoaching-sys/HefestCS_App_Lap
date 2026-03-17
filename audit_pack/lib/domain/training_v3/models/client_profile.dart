import 'package:equatable/equatable.dart';

/// Modelo de perfil del cliente para análisis científico
class ClientProfile extends Equatable {
  final int age;
  final String experience; // 'beginner', 'intermediate', 'advanced'
  final double recoveryCapacity; // 0-10
  final double caloricBalance; // -500 to +500
  final double geneticResponse; // 0.5 - 1.5 (multiplicador)

  const ClientProfile({
    required this.age,
    required this.experience,
    required this.recoveryCapacity,
    required this.caloricBalance,
    required this.geneticResponse,
  });

  @override
  List<Object?> get props => [
    age,
    experience,
    recoveryCapacity,
    caloricBalance,
    geneticResponse,
  ];
}
