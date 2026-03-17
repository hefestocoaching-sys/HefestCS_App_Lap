import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/design/design_tokens.dart';

/// ClinicSection - Widget expandible reutilizable para Historia Clínica
/// Agrupa items relacionados con transiciones suaves y feedback visual
class ClinicSection extends StatefulWidget {
  /// Título de la sección (ej: "Alergias", "Enfermedades Crónicas")
  final String title;

  /// Icono a mostrar en el encabezado
  final IconData icon;

  /// Widgets a mostrar cuando la sección se expande
  final List<Widget> items;

  /// Color de fondo de la sección
  final Color? bgColor;

  /// Color del encabezado y acento
  final Color? accentColor;

  /// Si debe estar expandida por defecto
  final bool expandedByDefault;

  /// Contador opcional (ej: "3" items)
  final int? itemCount;

  const ClinicSection({
    required this.title,
    required this.icon,
    required this.items,
    this.bgColor,
    this.accentColor,
    this.expandedByDefault = false,
    this.itemCount,
    super.key,
  });

  @override
  State<ClinicSection> createState() => _ClinicSectionState();
}

class _ClinicSectionState extends State<ClinicSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expandedByDefault;

    _expandController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.bgColor ??
        Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final accentColor = widget.accentColor ?? DesignTokens.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // ========== HEADER EXPANDIBLE ==========
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                child: Row(
                  children: [
                    // Icono
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMd,
                        ),
                      ),
                      child: Center(
                        child: Icon(widget.icon, color: accentColor, size: 20),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceMd),

                    // Título y contador
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (widget.itemCount != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: DesignTokens.spaceSm,
                              ),
                              child: Text(
                                '${widget.itemCount} ${widget.itemCount == 1 ? 'elemento' : 'elementos'}',
                                style: DesignTokens.caption,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Ícono de expandir (rotor)
                    AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotateAnimation.value * 3.14159,
                          child: Icon(
                            Icons.expand_more,
                            color: accentColor,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ========== CONTENIDO EXPANDIBLE ==========
          AnimatedBuilder(
            animation: _expandController,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandController.value,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                // Divisor
                Divider(
                  height: DesignTokens.spaceSm,
                  thickness: 1,
                  color: Colors.grey[300],
                ),

                // Items
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.items.asMap().entries.map((entry) {
                      final isLast = entry.key == widget.items.length - 1;
                      return Column(
                        children: [
                          entry.value,
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spaceMd,
                              ),
                              child: Divider(
                                height: DesignTokens.spaceMd,
                                thickness: 0.5,
                                color: Colors.grey[300],
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar un item dentro de ClinicSection
/// Usado para Alergias, Medicamentos, Enfermedades, etc.
class ClinicSectionItem extends StatefulWidget {
  /// Nombre/título principal del item
  final String title;

  /// Subtítulo o descripción
  final String? subtitle;

  /// Icono de severidad o indicador visual
  final Color? indicatorColor;

  /// Ancho de la barra indicadora (severidad)
  final double indicatorWidth;

  /// Widget a mostrar a la derecha del título
  final Widget? trailing;

  /// Callback al hacer click
  final VoidCallback? onTap;

  /// Acciones adicionales (editar, eliminar, etc)
  final List<Widget>? actions;

  const ClinicSectionItem({
    required this.title,
    this.subtitle,
    this.indicatorColor,
    this.indicatorWidth = 4,
    this.trailing,
    this.onTap,
    this.actions,
    super.key,
  });

  @override
  State<ClinicSectionItem> createState() => _ClinicSectionItemState();
}

class _ClinicSectionItemState extends State<ClinicSectionItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: DesignTokens.durationFast,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceMd,
              vertical: DesignTokens.spaceMd,
            ),
            decoration: BoxDecoration(
              color: _isHovering
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.4),
            ),
            child: Row(
              children: [
                // Barra indicadora de severidad
                if (widget.indicatorColor != null)
                  Container(
                    width: widget.indicatorWidth,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.indicatorColor,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusSm,
                      ),
                    ),
                  ),
                if (widget.indicatorColor != null)
                  const SizedBox(width: DesignTokens.spaceMd),

                // Contenido principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: DesignTokens.labelLarge),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: DesignTokens.spaceSm),
                        Text(
                          widget.subtitle!,
                          style: DesignTokens.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: DesignTokens.spaceMd),

                // Trailing widget (ej: icono de favorito)
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
