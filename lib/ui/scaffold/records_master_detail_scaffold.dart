import 'package:flutter/material.dart';

/// Scaffold genérico que controla el flujo maestro-detalle.
///
/// Cuando [selectedRecord] es null → muestra [recordsGrid]
/// Cuando [selectedRecord] tiene valor → muestra [detailBuilder]
///
/// ✅ No sabe de antropometría
/// ✅ No sabe de nutrición
/// ✅ No sabe de fechas
/// ✅ Solo controla el flujo
class RecordsMasterDetailScaffold<T> extends StatelessWidget {
  final T? selectedRecord;
  final Widget recordsGrid;
  final Widget Function(T record) detailBuilder;

  const RecordsMasterDetailScaffold({
    super.key,
    required this.selectedRecord,
    required this.recordsGrid,
    required this.detailBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedRecord == null) {
      return recordsGrid;
    }

    return detailBuilder(selectedRecord as T);
  }
}
