import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Widget de estadística rápida (estilo glass)
class QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final String? trend;
  final bool? isPositive;
  final VoidCallback? onTap;

  const QuickStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = kPrimaryColor,
    this.subtitle,
    this.trend,
    this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (trend != null && isPositive != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isPositive! ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isPositive! ? kSuccessColor : Colors.red[400],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trend!,
                        style: TextStyle(
                          color: isPositive! ? kSuccessColor : Colors.red[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Formatear moneda mexicana
String formatMXN(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}
