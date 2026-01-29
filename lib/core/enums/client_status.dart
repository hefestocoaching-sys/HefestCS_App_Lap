// lib/core/enums/client_status.dart
enum ClientStatus {
  /// Cliente activo en coaching / seguimiento.
  active,

  /// Pausado temporalmente (viajes, vacaciones, temas personales).
  paused,

  /// Dado de baja por decisión propia o mutua.
  droppedOut,

  /// En fase de prueba o primera evaluación.
  trial,

  /// Prospecto (aún no inicia plan formal).
  prospect,

  /// Suspendido por pagos pendientes u otros temas administrativos.
  unpaid,

  /// Cerrado / histórico (no se espera reactivación).
  archived,
}

extension ClientStatusX on ClientStatus {
  String get label {
    switch (this) {
      case ClientStatus.active:
        return 'Activo';
      case ClientStatus.paused:
        return 'Pausado';
      case ClientStatus.droppedOut:
        return 'Baja';
      case ClientStatus.trial:
        return 'Prueba';
      case ClientStatus.prospect:
        return 'Prospecto';
      case ClientStatus.unpaid:
        return 'Adeudo';
      case ClientStatus.archived:
        return 'Archivado';
    }
  }

  static ClientStatus fromString(String? raw) {
    if (raw == null) return ClientStatus.active;
    switch (raw) {
      case 'active':
        return ClientStatus.active;
      case 'paused':
        return ClientStatus.paused;
      case 'droppedOut':
        return ClientStatus.droppedOut;
      case 'trial':
        return ClientStatus.trial;
      case 'prospect':
        return ClientStatus.prospect;
      case 'unpaid':
        return ClientStatus.unpaid;
      case 'archived':
        return ClientStatus.archived;
      default:
        return ClientStatus.active;
    }
  }

  String toJson() => name;
}
