import '../../core/enums/gender.dart';
import '../../core/enums/client_level.dart';

class ClientProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final DateTime? birthDate;
  final int? age;
  final Gender? gender;
  final String? maritalStatus;
  final String country;
  final String occupation;
  final ClientLevel? level; // mapea tu clientLevel string a enum
  final String objective;

  const ClientProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.country,
    required this.occupation,
    required this.objective,
    this.birthDate,
    this.age,
    this.gender,
    this.maritalStatus,
    this.level,
  });

  ClientProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    DateTime? birthDate,
    int? age,
    Gender? gender,
    String? maritalStatus,
    String? country,
    String? occupation,
    ClientLevel? level,
    String? objective,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      country: country ?? this.country,
      occupation: occupation ?? this.occupation,
      level: level ?? this.level,
      objective: objective ?? this.objective,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'birthDate': birthDate?.toIso8601String(),
    'age': age,
    'gender': gender?.name,
    'maritalStatus': maritalStatus,
    'country': country,
    'occupation': occupation,
    'level': level?.name,
    'objective': objective,
  };

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
      age: json['age'] as int?,
      gender: (json['gender'] != null) ? Gender.values.byName(json['gender']) : null,
      maritalStatus: json['maritalStatus'] as String?,
      country: json['country'] ?? '',
      occupation: json['occupation'] ?? '',
      level: (json['level'] != null) ? ClientLevel.values.byName(json['level']) : null,
      objective: json['objective'] ?? '',
    );
  }
}
