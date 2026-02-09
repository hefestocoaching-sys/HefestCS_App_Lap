import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Menú lateral global (siempre visible)
/// Colapsable por hover: 64px cerrado → 240px abierto
/// Muestra opciones globales normalmente, opciones de cliente cuando hay cliente activo
class GlobalSideNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback? onClientsPressed;
  final bool hasActiveClient;
  final String? clientName;

  const GlobalSideNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.onClientsPressed,
    this.hasActiveClient = false,
    this.clientName,
  });

  @override
  State<GlobalSideNavigationRail> createState() =>
      _GlobalSideNavigationRailState();
}

class _GlobalSideNavigationRailState extends State<GlobalSideNavigationRail> {
  bool _isExpanded = false;

  static const double _collapsedWidth = 64.0;
  static const double _expandedWidth = 240.0;
  static const Duration _animationDuration = Duration(milliseconds: 250);

  List<NavItem> _getItems() {
    debugPrint(
      'GlobalSideNavigationRail._getItems: hasActiveClient=${widget.hasActiveClient}',
    );
    if (widget.hasActiveClient) {
      // Items cuando hay cliente activo
      return [
        NavItem(icon: Icons.home_outlined, label: 'Inicio', index: 0),
        NavItem(icon: Icons.dashboard_outlined, label: 'Resumen', index: 10),
        NavItem(
          icon: Icons.medical_services_outlined,
          label: 'Historia Clínica',
          index: 1,
        ),
        NavItem(
          icon: Icons.accessibility_new_outlined,
          label: 'Antropometría',
          index: 2,
        ),
        NavItem(
          icon: Icons.local_fire_department_outlined,
          label: 'Gasto Energético',
          index: 3,
        ),
        NavItem(
          icon: Icons.restaurant_menu_outlined,
          label: 'Macronutrientes',
          index: 4,
        ),
        NavItem(
          icon: Icons.table_chart_outlined,
          label: 'Tabla de Equivalentes',
          index: 5,
        ),
        NavItem(
          icon: Icons.menu_book_outlined,
          label: 'Diseño de Menú',
          index: 6,
        ),
        NavItem(
          icon: Icons.fitness_center_outlined,
          label: 'Entrenamiento',
          index: 7,
        ),
        NavItem(icon: Icons.science_outlined, label: 'Bioquímica', index: 8),
      ];
    } else {
      // Items globales normales
      return [
        NavItem(icon: Icons.home_outlined, label: 'Inicio', index: 0),
        NavItem(icon: Icons.group_outlined, label: 'Clientes', index: 9),
        NavItem(icon: Icons.science_outlined, label: 'Bioquímica', index: 8),
        NavItem(
          icon: Icons.calendar_today_outlined,
          label: 'Agenda',
          index: -2,
        ),
        NavItem(
          icon: Icons.account_balance_outlined,
          label: 'Finanzas',
          index: -3,
        ),
        NavItem(icon: Icons.restaurant_outlined, label: 'Alimentos', index: -4),
        NavItem(icon: Icons.book_outlined, label: 'Recetas', index: -5),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems(); // Recalcular items en cada build

    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() => _isExpanded = false),
      child: AnimatedContainer(
        duration: _animationDuration,
        width: _isExpanded ? _expandedWidth : _collapsedWidth,
        height: double.infinity,
        color: const Color(0xFF1A1F2E),
        child: Column(
          children: [
            // Logo/branding en header
            Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withAlpha(20),
                    width: 1,
                  ),
                ),
              ),
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'HCS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.medical_services_outlined,
                      color: kPrimaryColor,
                      size: 32,
                    ),
            ),
            // Items de navegación distribuidos uniformemente
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calcular si los items caben sin scroll
                  final itemHeight = 48.0; // altura aproximada de cada item
                  final totalItemsHeight = items.length * itemHeight;
                  final needsScroll = totalItemsHeight > constraints.maxHeight;

                  if (needsScroll) {
                    // Si no caben, usar scroll compacto
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: items.map((item) {
                          final isSelected =
                              item.index >= 0 &&
                              widget.selectedIndex == item.index;
                          return _NavRailItem(
                            item: item,
                            isExpanded: _isExpanded,
                            isSelected: isSelected,
                            onTap: () {
                              if (item.index == 9) {
                                debugPrint(
                                  'DEBUG: Clients button tapped, calling onClientsPressed',
                                );
                                widget.onClientsPressed?.call();
                                debugPrint('DEBUG: onClientsPressed called');
                              } else if (item.index >= 0) {
                                widget.onIndexChanged(item.index);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    );
                  } else {
                    // Si caben, distribuir uniformemente
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: items.map((item) {
                        final isSelected =
                            item.index >= 0 &&
                            widget.selectedIndex == item.index;
                        return _NavRailItem(
                          item: item,
                          isExpanded: _isExpanded,
                          isSelected: isSelected,
                          onTap: () {
                            if (item.index == 9) {
                              debugPrint(
                                'DEBUG: Clients button tapped, calling onClientsPressed',
                              );
                              widget.onClientsPressed?.call();
                              debugPrint('DEBUG: onClientsPressed called');
                            } else if (item.index >= 0) {
                              widget.onIndexChanged(item.index);
                            }
                          },
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
            // Settings en footer
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(20), width: 1),
                ),
              ),
              child: _NavRailItem(
                item: NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                  index: 8,
                ),
                isExpanded: _isExpanded,
                isSelected: widget.selectedIndex == 8,
                onTap: () => widget.onIndexChanged(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final int index;
  final bool isHeader;

  NavItem({
    required this.icon,
    required this.label,
    required this.index,
    this.isHeader = false,
  });
}

class _NavRailItem extends StatefulWidget {
  final NavItem item;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavRailItem({
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavRailItem> createState() => _NavRailItemState();
}

class _NavRailItemState extends State<_NavRailItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48, // Altura fija para distribución uniforme
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? kPrimaryColor.withAlpha(76)
                      : _isHovered
                      ? Colors.white.withAlpha(18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.isSelected
                      ? kPrimaryColor
                      : kTextColorSecondary,
                  size: 20,
                ),
              ),
              // Label (solo cuando expanded)
              if (widget.isExpanded)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      widget.item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: widget.isSelected ? kPrimaryColor : kTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
