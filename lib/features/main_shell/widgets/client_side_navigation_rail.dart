import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Menú lateral contextual para cliente activo.
class ClientSideNavigationRail extends ConsumerWidget {
  final Client? client;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const ClientSideNavigationRail({
    super.key,
    required this.client,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  /// Anchura fija del panel para poder reservar espacio desde el shell.
  static const double width = 260.0;

  static final List<_ClientNavItem> _items = [
    _ClientNavItem(
      icon: Icons.home_outlined,
      label: 'Resumen del Cliente',
      index: 1,
    ),
    _ClientNavItem(
      icon: Icons.medical_services_outlined,
      label: 'Historia Clínica',
      index: 2,
    ),
    _ClientNavItem(
      icon: Icons.accessibility_new_outlined,
      label: 'Antropometría',
      index: 3,
    ),
    _ClientNavItem(
      icon: Icons.local_fire_department_outlined,
      label: 'Gasto Energético',
      index: 4,
    ),
    _ClientNavItem(
      icon: Icons.restaurant_menu_outlined,
      label: 'Macronutrientes',
      index: 5,
    ),
    _ClientNavItem(
      icon: Icons.table_chart_outlined,
      label: 'Tabla de Equivalentes',
      index: 6,
    ),
    _ClientNavItem(
      icon: Icons.menu_book_outlined,
      label: 'Diseño de Menu',
      index: 7,
    ),
    _ClientNavItem(
      icon: Icons.fitness_center_outlined,
      label: 'Entrenamiento',
      index: 8,
    ),
    _ClientNavItem(icon: Icons.science_outlined, label: 'Bioquimica', index: 9),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      globalDateProvider,
    ); // Mantener reactivo a la fecha aunque no se use directamente.

    final planEndDate = client?.nutrition.planEndDate;
    final isActivePlan =
        planEndDate != null && planEndDate.isAfter(DateTime.now());

    return Container(
      width: width,
      height: double.infinity,
      color: kCardColor,
      child: Column(
        children: [
          // Resumen compacto del cliente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(20), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client?.fullName ?? 'Cliente',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      client?.profile.gender?.name ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextColorSecondary,
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${client?.profile.age ?? 'N/A'} años',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextColorSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (client?.training.globalGoal != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      client!.training.globalGoal.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isActivePlan ? Icons.check_circle : Icons.info_outlined,
                      size: 12,
                      color: isActivePlan ? Colors.green : kTextColorSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isActivePlan ? 'Plan activo' : 'Sin plan activo',
                        style: TextStyle(
                          fontSize: 11,
                          color: isActivePlan
                              ? Colors.green
                              : kTextColorSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Navegación
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (context, idx) {
                final item = _items[idx];
                final isSelected = selectedIndex == item.index;
                return _ClientNavRailItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onIndexChanged(item.index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientNavItem {
  final IconData icon;
  final String label;
  final int index;

  const _ClientNavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _ClientNavRailItem extends StatefulWidget {
  final _ClientNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClientNavRailItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ClientNavRailItem> createState() => _ClientNavRailItemState();
}

class _ClientNavRailItemState extends State<_ClientNavRailItem> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? kPrimaryColor.withAlpha(51)
                : _isHovered
                ? Colors.white.withAlpha(10)
                : Colors.transparent,
            border: widget.isSelected
                ? Border(left: BorderSide(color: kPrimaryColor, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                color: widget.isSelected ? kPrimaryColor : kTextColorSecondary,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.isSelected ? kPrimaryColor : kTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
