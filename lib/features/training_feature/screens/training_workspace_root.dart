import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/training_feature/screens/training_workspace_screen.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// TrainingWorkspaceRoot: Pantalla autónoma de Entrenamiento sin shell clínico
/// Renderiza Training como una aplicación completa e independiente.
class TrainingWorkspaceRoot extends ConsumerWidget {
  const TrainingWorkspaceRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Container(
        // Estructura fullscreen optimizada para Training sin shell lateral
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kBackgroundColor,
              kBackgroundColor.withValues(alpha: 0.98),
            ],
          ),
        ),
        child: const SafeArea(child: TrainingWorkspaceScreen()),
      ),
    );
  }
}
