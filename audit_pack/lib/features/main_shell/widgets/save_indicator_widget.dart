import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/save_indicator_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Widget indicador de guardado que aparece en la esquina superior derecha
/// Muestra el estado actual de guardado: guardando, guardado, o error
class SaveIndicatorWidget extends ConsumerWidget {
  const SaveIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saveState = ref.watch(saveIndicatorProvider);

    // No mostrar nada si está idle
    if (saveState.status == SaveStatus.idle) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: saveState.status == SaveStatus.idle ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedSlide(
          offset: saveState.status == SaveStatus.idle
              ? const Offset(0, -1)
              : Offset.zero,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: _getBackgroundColor(saveState.status),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono o spinner
                  _buildIcon(saveState.status),
                  const SizedBox(width: 10),
                  // Mensaje
                  Text(
                    saveState.message ?? _getDefaultMessage(saveState.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(SaveStatus status) {
    switch (status) {
      case SaveStatus.saving:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SaveStatus.saved:
        return const Icon(Icons.check_circle, color: Colors.white, size: 20);
      case SaveStatus.error:
        return const Icon(Icons.error, color: Colors.white, size: 20);
      case SaveStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Color _getBackgroundColor(SaveStatus status) {
    switch (status) {
      case SaveStatus.saving:
        return kPrimaryColor.withValues(alpha: 0.95);
      case SaveStatus.saved:
        return Colors.green.shade600;
      case SaveStatus.error:
        return Colors.red.shade600;
      case SaveStatus.idle:
        return Colors.transparent;
    }
  }

  String _getDefaultMessage(SaveStatus status) {
    switch (status) {
      case SaveStatus.saving:
        return 'Guardando...';
      case SaveStatus.saved:
        return 'Guardado ✓';
      case SaveStatus.error:
        return 'Error al guardar ⚠️';
      case SaveStatus.idle:
        return '';
    }
  }
}
