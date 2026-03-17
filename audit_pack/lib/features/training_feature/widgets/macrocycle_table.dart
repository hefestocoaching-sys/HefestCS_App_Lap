import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/macrocycle_week.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/glass_container.dart';
import 'package:hcs_app_lap/utils/widgets/section_header.dart';

/// Un widget que renderiza una tabla profesional para visualizar un macrociclo de entrenamiento.
///
/// Muestra las semanas planificadas en un formato de calendario, limitando la
/// visibilidad a las semanas que han sido pagadas por el cliente.
/// La tabla es scrollable horizontalmente para adaptarse a pantallas pequeñas.
class MacrocycleTable extends StatelessWidget {
  /// La lista completa de semanas planificadas para el macrociclo.
  final List<MacrocycleWeek> weeks;

  /// El número de semanas que el cliente ha pagado y que deben ser visibles.
  final int paidWeeks;

  /// El número de la semana actualmente seleccionada, para resaltarla.
  final int? selectedWeekNumber;

  /// Callback que se invoca cuando el usuario toca una semana.
  final ValueChanged<int>? onWeekSelected;

  const MacrocycleTable({
    super.key,
    required this.weeks,
    required this.paidWeeks,
    this.selectedWeekNumber,
    this.onWeekSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Filtra la lista para mostrar solo las semanas pagadas.
    final visibleWeeks = weeks.take(paidWeeks).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: "VISTA GENERAL DEL MACROCICLO"),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 32,
              headingRowColor: WidgetStateProperty.all(
                Colors.transparent, // El GlassContainer ya da el fondo
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'SEMANA',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'BLOQUE',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'OBJETIVO',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'VOLUMEN',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '% PESADAS',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '% MEDIAS',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '% LIGERAS',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'NOTAS',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows: visibleWeeks.map((week) {
                return DataRow(
                  selected: week.weekNumber == selectedWeekNumber,
                  onSelectChanged: onWeekSelected != null
                      ? (isSelected) {
                          if (isSelected ?? false) {
                            onWeekSelected!(week.weekNumber);
                          }
                        }
                      : null,
                  cells: [
                    DataCell(
                      Text(
                        week.weekNumber.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          week.block,
                          style: const TextStyle(
                            color: kTextColorSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        week.goal,
                        style: const TextStyle(color: kTextColorSecondary),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${week.targetVolume}%',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${week.heavyPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${week.mediumPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${week.lightPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.lightGreen),
                      ),
                    ),
                    DataCell(
                      Text(
                        week.notes ?? 'N/A',
                        style: const TextStyle(
                          color: kTextColorSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (visibleWeeks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  "No hay semanas planificadas para mostrar.",
                  style: TextStyle(color: kTextColorSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
