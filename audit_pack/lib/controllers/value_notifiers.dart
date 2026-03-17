import 'package:flutter/material.dart';

/// Controladores reactivos base (ValueNotifiers)
/// para variables que se actualizan con frecuencia en formularios.

class ClientNotifier extends ValueNotifier<String?> {
  ClientNotifier() : super(null);
}

class GenderNotifier extends ValueNotifier<String?> {
  GenderNotifier() : super(null);
}

class MacroNotifier extends ValueNotifier<Map<String, double>> {
  MacroNotifier() : super({
    'proteina': 0,
    'carbohidratos': 0,
    'grasa': 0,
  });
}

class DateNotifier extends ValueNotifier<DateTime?> {
  DateNotifier() : super(null);
}
