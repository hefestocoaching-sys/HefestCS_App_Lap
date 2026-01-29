import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Layout en dos columnas para módulos clínicos
/// Columna izquierda: Lista de registros (fija)
/// Columna derecha: Panel de edición/detalle (expandible)
class TwoColumnModuleLayout extends StatelessWidget {
  final Widget recordsList;
  final Widget detailPanel;
  final double listWidth;

  const TwoColumnModuleLayout({
    super.key,
    required this.recordsList,
    required this.detailPanel,
    this.listWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: Lista de registros
        Container(
          width: listWidth,
          decoration: BoxDecoration(
            color: kBackgroundColor.withAlpha((255 * 0.3).round()),
            border: Border(
              right: BorderSide(
                color: kAppBarColor.withAlpha((255 * 0.3).round()),
                width: 1,
              ),
            ),
          ),
          child: recordsList,
        ),
        // Columna derecha: Panel de edición/detalle
        Expanded(child: detailPanel),
      ],
    );
  }
}

/// Panel de lista de registros (columna izquierda)
class RecordsListPanel extends StatelessWidget {
  final Widget? header;
  final List<Widget> records;
  final Widget? newRecordButton;

  const RecordsListPanel({
    super.key,
    this.header,
    required this.records,
    this.newRecordButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        if (newRecordButton != null) ...[
          Padding(padding: const EdgeInsets.all(16), child: newRecordButton),
        ],
        Expanded(
          child: records.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay registros',
                      style: TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: records.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) => records[index],
                ),
        ),
      ],
    );
  }
}

/// Panel de edición/detalle (columna derecha)
class DetailPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DetailPanel({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }
}
