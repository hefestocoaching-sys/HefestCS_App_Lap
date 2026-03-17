import 'package:hcs_app_lap/utils/date_helpers.dart';

/// Entidad simple para citas/consultas con clientes (sin Freezed temporalmente)
class Appointment {
  final String id;
  final String clientId;
  final DateTime dateTime;
  final int durationMinutes;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? notes;
  final DateTime? completedAt;
  final bool sendReminder;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.dateTime,
    this.durationMinutes = 60,
    this.type = AppointmentType.weeklyCheck,
    this.status = AppointmentStatus.scheduled,
    this.notes,
    this.completedAt,
    this.sendReminder = false,
  });

  Appointment copyWith({
    String? id,
    String? clientId,
    DateTime? dateTime,
    int? durationMinutes,
    AppointmentType? type,
    AppointmentStatus? status,
    String? notes,
    DateTime? completedAt,
    bool? sendReminder,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      sendReminder: sendReminder ?? this.sendReminder,
    );
  }

  /// Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'dateTime': dateTime,
      'durationMinutes': durationMinutes,
      'type': type.name,
      'status': status.name,
      'notes': notes,
      'completedAt': completedAt,
      'sendReminder': sendReminder,
    };
  }

  /// Crear desde JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      dateTime: json['dateTime'] is DateTime
          ? json['dateTime'] as DateTime
          : parseDateTimeOrEpoch(json['dateTime'].toString()),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      type: AppointmentType.values.byName(
        (json['type'] as String?) ?? 'weeklyCheck',
      ),
      status: AppointmentStatus.values.byName(
        (json['status'] as String?) ?? 'scheduled',
      ),
      notes: json['notes'] as String?,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] is DateTime
                ? json['completedAt'] as DateTime
                : tryParseDateTime(json['completedAt'].toString()))
          : null,
      sendReminder: json['sendReminder'] as bool? ?? false,
    );
  }
}

/// Tipos de citas
enum AppointmentType {
  weeklyCheck,
  measurement,
  planRenewal,
  training,
  firstConsult,
  custom,
}

/// Estado de la cita
enum AppointmentStatus { scheduled, completed, cancelled, noShow }

/// Extensiones para AppointmentType
extension AppointmentTypeExt on AppointmentType {
  String get label {
    switch (this) {
      case AppointmentType.weeklyCheck:
        return 'Check Semanal';
      case AppointmentType.measurement:
        return 'Medición';
      case AppointmentType.planRenewal:
        return 'Renovación Plan';
      case AppointmentType.training:
        return 'Entrenamiento';
      case AppointmentType.firstConsult:
        return 'Primera Consulta';
      case AppointmentType.custom:
        return 'Personalizado';
    }
  }

  String get emoji {
    switch (this) {
      case AppointmentType.weeklyCheck:
        return '✓';
      case AppointmentType.measurement:
        return '📏';
      case AppointmentType.planRenewal:
        return '📋';
      case AppointmentType.training:
        return '💪';
      case AppointmentType.firstConsult:
        return '👤';
      case AppointmentType.custom:
        return '📅';
    }
  }
}

/// Extensiones para AppointmentStatus
extension AppointmentStatusExt on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Programada';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      case AppointmentStatus.noShow:
        return 'No asistió';
    }
  }
}
