import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estados posibles del indicador de guardado
enum SaveStatus {
  idle, // No hay actividad
  saving, // Guardando
  saved, // Guardado exitosamente
  error, // Error al guardar
}

/// Estado del indicador de guardado con mensaje opcional
class SaveIndicatorState {
  final SaveStatus status;
  final String? message;

  const SaveIndicatorState({required this.status, this.message});

  SaveIndicatorState copyWith({SaveStatus? status, String? message}) {
    return SaveIndicatorState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

/// Notifier para controlar el indicador de guardado global
class SaveIndicatorNotifier extends Notifier<SaveIndicatorState> {
  @override
  SaveIndicatorState build() {
    return const SaveIndicatorState(status: SaveStatus.idle);
  }

  /// Marca como guardando con mensaje opcional
  void setSaving([String? message]) {
    state = SaveIndicatorState(
      status: SaveStatus.saving,
      message: message ?? 'Guardando...',
    );
  }

  /// Marca como guardado exitosamente
  void setSaved([String? message]) {
    state = SaveIndicatorState(
      status: SaveStatus.saved,
      message: message ?? 'Guardado',
    );

    // Auto-ocultar después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (state.status == SaveStatus.saved) {
        state = const SaveIndicatorState(status: SaveStatus.idle);
      }
    });
  }

  /// Marca como error al guardar
  void setError([String? message]) {
    state = SaveIndicatorState(
      status: SaveStatus.error,
      message: message ?? 'Error al guardar',
    );

    // Auto-ocultar después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (state.status == SaveStatus.error) {
        state = const SaveIndicatorState(status: SaveStatus.idle);
      }
    });
  }

  /// Resetea a idle manualmente
  void reset() {
    state = const SaveIndicatorState(status: SaveStatus.idle);
  }
}

final saveIndicatorProvider =
    NotifierProvider<SaveIndicatorNotifier, SaveIndicatorState>(
      SaveIndicatorNotifier.new,
    );
