import 'package:flutter/material.dart';

/// Design Tokens 2026 - Sistema de diseño coherente
/// Centraliza colores, espaciado, tipografía y radios para toda la app
class DesignTokens {
  // ========== COLORES ==========

  /// Colores Primarios
  static const Color primaryBlue = Color(0xFF1F77E5);
  static const Color primaryCyan = Color(0xFF00BCD4);

  /// Colores Semánticos
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  /// Colores para Secciones de Historia Clínica
  static const Color allergyBg = Color(0xFFFCE4EC); // Rosado suave
  static const Color diseaseBg = Color(0xFFEBF5FB); // Azul suave
  static const Color medicationBg = Color(0xFFF0F4C3); // Verde suave
  static const Color surgeryBg = Color(0xFFE8F5E9); // Verde muy suave

  /// Colores de Severidad
  static const Color severityCritical = Color(0xFFD32F2F); // Rojo oscuro
  static const Color severityHigh = Color(0xFFFF6F00); // Naranja oscuro
  static const Color severityMedium = Color(0xFFFBC02D); // Amarillo dorado
  static const Color severityLow = Color(0xFF1976D2); // Azul oscuro

  /// Colores de Músculos (para Entrenamiento)
  static const Color muscleChest = Color(0xFFEF5350);
  static const Color muscleBack = Color(0xFF42A5F5);
  static const Color muscleLegs = Color(0xFF66BB6A);
  static const Color muscleShoulder = Color(0xFFAB47BC);
  static const Color muscleArms = Color(0xFFEC407A);
  static const Color muscleCore = Color(0xFFFFCA28);

  /// Colores de Fondo
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgDark = Color(0xFF121212);
  static const Color bgDarkSecondary = Color(0xFF1E1E1E);

  /// Colores de Texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF9E9E9E);

  /// Colores de Elevación
  static const Color elevation1 = Color(0xFFF5F5F5);
  static const Color elevation2 = Color(0xFFEEEEEE);
  static const Color elevation3 = Color(0xFFE0E0E0);

  /// Colores Neutrales
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ========== ESPACIADO ==========

  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 48.0;

  // ========== BORDER RADIUS ==========

  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 20.0;
  static const double radiusFull = 999.0;

  // ========== DURACIONES DE ANIMACIÓN ==========

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ========== TIPOGRAFÍA ==========

  /// Estilos de Encabezados
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Estilos de Cuerpo
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  /// Estilos de Label
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  /// Caption/Subtitle
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  // ========== SOMBRAS ==========

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0D000000), // 5% black
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x14000000), // 8% black
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  // ========== ESTILOS DE SECCIÓN (Historia Clínica) ==========

  /// Estilos para títulos de sección expandible
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryBlue,
  );

  /// Estilos para subtítulos en items
  static const TextStyle itemSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  // ========== UTILIDADES ==========

  /// Obtener color basado en severidad
  static Color getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRÍTICA':
      case 'CRITICAL':
        return severityCritical;
      case 'SEVERA':
      case 'SEVERE':
      case 'HIGH':
        return severityHigh;
      case 'MODERADA':
      case 'MODERATE':
      case 'MEDIUM':
        return severityMedium;
      case 'LEVE':
      case 'MILD':
      case 'LOW':
        return severityLow;
      default:
        return info;
    }
  }

  /// Obtener color de músculo para Entrenamiento
  static Color getMuscleColor(String muscle) {
    final muscleKey = muscle.toLowerCase();
    if (muscleKey.contains('pecho')) {
      return muscleChest;
    }
    if (muscleKey.contains('espalda')) {
      return muscleBack;
    }
    if (muscleKey.contains('pierna') || muscleKey.contains('leg')) {
      return muscleLegs;
    }
    if (muscleKey.contains('hombro')) {
      return muscleShoulder;
    }
    if (muscleKey.contains('brazo') || muscleKey.contains('arm')) {
      return muscleArms;
    }
    if (muscleKey.contains('núcleo') || muscleKey.contains('core')) {
      return muscleCore;
    }
    return primaryBlue;
  }

  /// Obtener color de fondo para sección
  static Color getSectionBackgroundColor(String sectionType) {
    final type = sectionType.toLowerCase();
    if (type.contains('alergia') || type.contains('allergy')) {
      return allergyBg;
    }
    if (type.contains('enfermedad') || type.contains('disease')) {
      return diseaseBg;
    }
    if (type.contains('medicamento') || type.contains('medication')) {
      return medicationBg;
    }
    if (type.contains('quirúrgico') || type.contains('surgery')) {
      return surgeryBg;
    }
    return bgLight;
  }
}
