import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Textos estandarizados para acciones de guardado por fecha
class SaveMessages {
  /// Botón para editar un registro existente
  static const String buttonEditRecord = 'Editar este registro';

  /// Botón para guardar cambios de una fecha existente
  static const String buttonSaveChanges = 'Guardar cambios de esta fecha';

  /// Botón para crear un nuevo registro en una fecha nueva
  static const String buttonCreateNew = 'Guardar nuevo registro';

  /// Botón de cancelar
  static const String buttonCancel = 'Cancelar';

  /// Botón de crear primer registro
  static const String buttonCreateFirst = 'Crear primer registro';

  /// Feedback cuando se actualiza un registro existente
  static String feedbackRecordUpdated(DateTime date) {
    return 'Registro de ${DateFormat('yyyy-MM-dd').format(date)} actualizado';
  }

  /// Feedback cuando se crea un nuevo registro
  static String feedbackRecordCreated(DateTime date) {
    return 'Registro guardado para ${DateFormat('yyyy-MM-dd').format(date)}';
  }

  /// Mensaje de estado vacío genérico
  static const String emptyStateDefault = 'Sin registros aún';

  /// Error cuando no hay cambios que guardar
  static const String errorNoChanges = 'No hay cambios que guardar';

  /// Error cuando la fecha es inválida
  static const String errorInvalidDate = 'Fecha inválida';

  /// Error genérico de validación
  static const String errorValidation = 'Por favor, corrige los errores';
}

/// Helper para determinar si es edición o nuevo registro
class SaveActionDetector {
  /// Detecta si un registro con la misma fecha ya existe
  /// Retorna true si es EDICIÓN (existe), false si es NUEVO
  static bool isEditingExistingDate<T>(
    List<T> records,
    DateTime targetDate,
    DateTime Function(T) dateExtractor,
  ) {
    return records.any((record) {
      final recordDate = dateExtractor(record);
      return DateUtils.isSameDay(recordDate, targetDate);
    });
  }

  /// Obtiene el texto de botón apropiado para guardar
  static String getButtonText<T>(
    List<T> records,
    DateTime targetDate,
    DateTime Function(T) dateExtractor,
  ) {
    final isEditing = isEditingExistingDate(records, targetDate, dateExtractor);
    return isEditing
        ? SaveMessages.buttonSaveChanges
        : SaveMessages.buttonCreateNew;
  }

  /// Obtiene el feedback apropiado
  static String getFeedback<T>(
    List<T> records,
    DateTime targetDate,
    DateTime Function(T) dateExtractor,
  ) {
    final isEditing = isEditingExistingDate(records, targetDate, dateExtractor);
    return isEditing
        ? SaveMessages.feedbackRecordUpdated(targetDate)
        : SaveMessages.feedbackRecordCreated(targetDate);
  }
}
