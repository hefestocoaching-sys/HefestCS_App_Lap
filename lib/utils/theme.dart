import 'package:flutter/material.dart';

const List<BoxShadow> kCardShadow = [
  // Sombra oscura principal (da profundidad)
  BoxShadow(
    color: Color.fromRGBO(
      0,
      0,
      0,
      0.5,
    ), // Equivalente a Colors.black.withAlpha(127)
    blurRadius: 15,
    spreadRadius: 1,
    offset: Offset(0, 8),
  ),
  // Sombra sutil interna (da el toque de flotación)
  BoxShadow(
    color: Color.fromRGBO(
      0,
      0,
      0,
      0.25,
    ), // Equivalente a Colors.black.withAlpha(64)
    blurRadius: 5,
    spreadRadius: 1,
    offset: Offset(0, 2),
  ),
];
// ------------------------------------

// Tus colores personalizados
const Color kBackgroundColor = Color(
  0xFF232B45,
); // Fondo GENERAL UNIFICADO (Scaffold/Shell)
const Color kAppBarColor = Color(
  0xFF232B45,
); // Panel Lateral y Barra Superior (UNIFICADO)
const Color kBiochemistry = Color(
  0xFF12192C,
); // Panel Lateral y Barra Superior (UNIFICADO)
// --- kCardColor ahora es igual al fondo para el look más oscuro/plano ---
const Color kCardColor = Color(
  0xFF010510,
); // Fondo de Tarjetas (Uniforme con el Shell)
const Color kInputFillColor = Color(0xFF12192C); // 3. Inputs (Tono Intermedio)
const kCardBackgroundColor = Color(0xFF1E1E1E);

// Borde suave gris azulado
const Color kBorderColor = Color(0xFF0C2C55); // Gris clínico muy suave

const Color kPrimaryColor = Color(
  0xFF3F51B5,
); // Azul para iconos seleccionados/acentos
const Color kTextColor = Color.fromARGB(255, 215, 213, 213); // Blanco
const Color kUnselectedIconColor = Color(
  0xFF888888,
); // Gris para iconos no seleccionados
const Color kSelectedIconColor = Color(
  0xFFFFFFFF,
); // Blanco para icono seleccionado
const Color kButtonBackgroundColor = Color(
  0xFF3F51B5,
); // Fondo de botón (el azul que se activa)
const Color kAccentColor = Color(0xFFFFFFFF);
const Color kTextColorSecondary = Color(0xFFA3A3A3); // Gris secundario
const Color kGraphColor = Color(0xFF020F2B);
const Color kGraphSelected = Color(0x779F9546);

// ═══════════════════════════════════════════════════════════
// SEMANTIC COLORS (Estados visuales para Motor V3)
// ═══════════════════════════════════════════════════════════

/// Verde - Estado óptimo (volumen en MAV, rendimiento bueno).
/// Usar cuando: % de MAV está entre 80-110% (zona de estímulo eficaz y sostenible).
const Color kSuccessColor = Color(0xFF4CAF50);

/// Naranja - Advertencia (volumen bajo MEV o cercano a MRV).
/// Usar cuando: % de MAV < 80% o % de MRV > 90% (estímulo subóptimo o fatiga acumulada).
const Color kWarningColor = Color(0xFFFFA726);

/// Rojo - Error/Peligro (volumen > MRV, fatiga alta, sobreentrenamiento).
/// Usar cuando: % de MRV > 110% o señales de fatiga crítica sostenida.
const Color kErrorColor = Color(0xFFEF5350);

/// Azul - Información (estado neutral, contexto o guía).
const Color kInfoColor = Color(0xFF42A5F5);

/// Variantes con alpha para fondos sutiles (backgrounds)
final Color kSuccessSubtle = kSuccessColor.withAlpha(40);
final Color kWarningSubtle = kWarningColor.withAlpha(40);
final Color kErrorSubtle = kErrorColor.withAlpha(40);
final Color kInfoSubtle = kInfoColor.withAlpha(40);

final ThemeData appThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: kPrimaryColor,
  scaffoldBackgroundColor: kBackgroundColor,
  // --- Aseguramos que el tema global use kCardColor ---
  cardColor: kCardColor, // Aplicamos kCardColor globalmente
  cardTheme: CardThemeData(
    color: kCardColor, // También en el CardTheme
    elevation: 0, // Quitamos la elevación por defecto si usamos BoxDecoration
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    margin: const EdgeInsets.only(
      top: 16,
      right: 16,
      bottom: 16,
    ), // Margen por defecto
  ),

  splashFactory: InkRipple.splashFactory,
  splashColor: kPrimaryColor.withAlpha(50),
  highlightColor: Colors.transparent,
  hoverColor: kPrimaryColor.withAlpha(15),

  appBarTheme: const AppBarTheme(
    backgroundColor: kAppBarColor,
    foregroundColor: kTextColor,
    elevation: 0,
  ),

  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: kTextColor),
    headlineSmall: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
    labelLarge: TextStyle(color: kTextColor),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: kTextColorSecondary,
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: kTextColor,
    ),
    titleMedium: TextStyle(color: kTextColor, fontWeight: FontWeight.w500),
  ),

  tabBarTheme: TabBarThemeData(
    labelColor: kTextColor,
    unselectedLabelColor: kTextColorSecondary,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: kPrimaryColor, width: 3.0),
    ),
    overlayColor: WidgetStateProperty.resolveWith<Color?>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.hovered)) {
        return kPrimaryColor.withAlpha(30);
      }
      if (states.contains(WidgetState.focused)) {
        return kPrimaryColor.withAlpha(50);
      }
      return null;
    }),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: kTextColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kBackgroundColor.withValues(alpha: 0.35),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: kPrimaryColor.withValues(alpha: 0.6),
        width: 1.2,
      ),
    ),
  ),
);

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
);
