import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/shared/record_detail/record_detail_shell.dart';
import 'package:hcs_app_lap/features/shared/record_detail/record_tab_scaffold.dart';
import '../widgets/anthropometry_record_header.dart';

/// Pantalla de detalle del registro antropométrico.
/// Estructura:
/// - Header fijo con fecha y estado
/// - Tabs: Mediciones | Cálculos | Interpretación
/// - Scroll interno por tab
class AnthropometryRecordDetailScreen extends StatefulWidget {
  final String date;

  const AnthropometryRecordDetailScreen({super.key, required this.date});

  @override
  State<AnthropometryRecordDetailScreen> createState() =>
      _AnthropometryRecordDetailScreenState();
}

class _AnthropometryRecordDetailScreenState
    extends State<AnthropometryRecordDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecordDetailShell(
      header: AnthropometryRecordHeader(date: widget.date, status: 'Completo'),
      tabController: _tabController,
      tabs: const [
        Tab(text: 'Mediciones'),
        Tab(text: 'Cálculos'),
        Tab(text: 'Interpretación'),
      ],
      tabViews: [
        RecordTabScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mediciones Antropométricas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Aquí van los inputs antropométricos (talla, peso, pliegues, perímetros, etc)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        RecordTabScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Índices y Cálculos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Índices, %grasa, masa magra, metabolismo basal, etc',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        RecordTabScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interpretación Clínica',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Análisis e interpretación de los datos antropométricos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
