// lib/presentation/widgets/feedback/hcs_loading.dart

import 'package:flutter/material.dart';

/// Loading indicator consistente
///
/// Uso:
/// ```dart
/// // Inline
/// HcsLoading(message: 'Cargando...')
///
/// // Full screen
/// HcsLoading.fullScreen(message: 'Generando programa...')
/// ```
class HcsLoading extends StatelessWidget {
  final String? message;
  final bool fullScreen;
  final Color? color;

  const HcsLoading({
    super.key,
    this.message,
    this.fullScreen = false,
    this.color,
  });

  factory HcsLoading.fullScreen({String? message}) {
    return HcsLoading(message: message, fullScreen: true);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? const Color(0xFF00D9FF),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1419),
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}
