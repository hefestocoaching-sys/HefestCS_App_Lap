import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controla la "Fecha Global" de la aplicación (Time Travel).
///
/// - Si es DateTime.now(), la app muestra los datos más recientes.
/// - Si es una fecha pasada, la app filtra los datos para mostrar el estado del cliente en ese momento.
class GlobalDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime newDate) => state = newDate;
}

final globalDateProvider = NotifierProvider<GlobalDateNotifier, DateTime>(
  GlobalDateNotifier.new,
);
