import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';

class MacrosWeekSummaryChart extends StatelessWidget {
  final Map<String, DailyMacroSettings> weeklyMacros;
  const MacrosWeekSummaryChart({super.key, required this.weeklyMacros});

  @override
  Widget build(BuildContext context) {
    // Puedes pegar aquí tu gráfica original del zip si quieres idéntico diseño.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Resumen semanal: ${weeklyMacros.length} días configurados'),
      ),
    );
  }
}
