import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class ModuleCardContainer extends StatelessWidget {
  final Widget child;

  const ModuleCardContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos el margen del tema (puede ser EdgeInsetsGeometry?)
    final EdgeInsetsGeometry? themeMargin = Theme.of(context).cardTheme.margin;

    // --- CORRECCIÓN: Convertir EdgeInsetsGeometry? a EdgeInsets ---
    // Creamos un EdgeInsets base (nuestro valor por defecto)
    const EdgeInsets defaultBaseMargin = EdgeInsets.only(top: 16, right: 16, bottom: 16);

    // Verificamos si el margen del tema es del tipo EdgeInsets y lo usamos, si no, usamos el base
    final EdgeInsets baseMargin = (themeMargin is EdgeInsets?) ? (themeMargin ?? defaultBaseMargin) : defaultBaseMargin;

    // Ahora podemos usar copyWith en baseMargin, que es EdgeInsets
    final EdgeInsets finalMargin = baseMargin.copyWith(right: 24); // Aumentado a 24
    // -----------------------------------------------------------

    return Container(
      margin: finalMargin, // Usamos el margen final calculado
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: kCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}