import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/design/workspace_scaffold.dart';
import '../widgets/anthropometry_record_tile.dart';
import 'anthropometry_record_detail_screen.dart';

/// Vista de registros antropométricos (lista por fecha).
/// Punto de entrada: WorkspaceScaffold → ListView de registros.
class AnthropometryRecordsScreen extends ConsumerWidget {
  const AnthropometryRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Por ahora, usaremos una lista vacia como placeholder
    final records = <Map<String, String>>[
      {'date': '23 de enero 2026', 'status': 'Completo'},
      {'date': '15 de enero 2026', 'status': 'En progreso'},
    ];

    return WorkspaceScaffold(
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'Antropometría',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return AnthropometryRecordTile(
                  date: record['date']!,
                  status: record['status']!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnthropometryRecordDetailScreen(
                          date: record['date']!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
