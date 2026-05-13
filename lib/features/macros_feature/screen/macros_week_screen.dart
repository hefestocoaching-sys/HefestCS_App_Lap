import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/macros_content.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class MacrosWeekScreen extends StatelessWidget {
  final Client client;
  final Function(Client) onClientUpdated;

  const MacrosWeekScreen({
    super.key,
    required this.client,
    required this.onClientUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Macros de la Semana'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const MacrosContent(),
    );
  }
}
