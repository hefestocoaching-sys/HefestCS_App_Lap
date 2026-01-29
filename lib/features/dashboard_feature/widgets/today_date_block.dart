import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Bloque superior del HOME que muestra la fecha seleccionada.
///
/// Contiene:
/// - Título "HOY"
/// - Fecha formateada larga (ej. "viernes, 2 de enero de 2026")
/// - Botón "Cambiar fecha" que abre DatePicker
class TodayDateBlock extends ConsumerStatefulWidget {
  const TodayDateBlock({super.key});

  @override
  ConsumerState<TodayDateBlock> createState() => _TodayDateBlockState();
}

class _TodayDateBlockState extends ConsumerState<TodayDateBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(globalDateProvider);
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    // Formato largo: "viernes, 2 de enero de 2026"
    final formattedDate = DateFormat(
      'EEEE, d \'de\' MMMM \'de\' yyyy',
      'es_ES',
    ).format(selectedDate);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1F2E).withAlpha(245),
                  const Color(0xFF1A1F2E).withAlpha(240),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? Colors.white.withAlpha(30)
                    : Colors.white.withAlpha(15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF00D9FF,
                  ).withAlpha(_isHovered ? 20 : 10),
                  blurRadius: _isHovered ? 24 : 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título "HOY" con gradiente
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
                  ).createShader(bounds),
                  child: const Text(
                    'HOY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Fecha formateada larga
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                    height: 1.2,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 20),

                // Botón "Cambiar fecha" con glassmorphism
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF00D9FF),
                                onPrimary: Colors.white,
                                surface: Color(0xFF1A1F2E),
                                onSurface: kTextColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        final endOfDay = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          23,
                          59,
                          59,
                        );
                        if (context.mounted) {
                          ref
                              .read(globalDateProvider.notifier)
                              .setDate(endOfDay);
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: const Text(
                      'Cambiar fecha',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00D9FF),
                      side: const BorderSide(
                        color: Color(0xFF00D9FF),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(0xFF00D9FF).withAlpha(10),
                    ),
                  ),
                ),

                // Indicador de estado "Hoy"
                if (isToday) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kSuccessColor.withAlpha(30),
                          kSuccessColor.withAlpha(20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kSuccessColor.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: kSuccessColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mostrando datos actuales',
                          style: TextStyle(
                            fontSize: 13,
                            color: kSuccessColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF59E0B).withAlpha(30),
                          const Color(0xFFF59E0B).withAlpha(20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16, color: Color(0xFFF59E0B)),
                        SizedBox(width: 8),
                        Text(
                          'Datos históricos',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
