import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hcs_app_lap/features/nutrition_feature/models/dietary_state_models.dart';
import 'package:hcs_app_lap/utils/mets_data.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/glass_container.dart';
import 'package:hcs_app_lap/utils/widgets/shared_form_widgets.dart';

class DietaryActivitySection extends StatefulWidget {
  final Map<String, List<UserActivity>> dailyActivities;
  final Map<String, double> dailyNafFactors;
  final double Function(String day) calculateDailyGET;
  final void Function(String day, UserActivity activity) onAddActivity;
  final void Function(String day, UserActivity activity) onRemoveActivity;
  final void Function(String fromDay, List<String> toDays) onCopyActivities;
  final void Function(String day, double factor) onSetNaf;
  final void Function(String fromDay, List<String> toDays) onCopyNaf;

  const DietaryActivitySection({
    super.key,
    required this.dailyActivities,
    required this.dailyNafFactors,
    required this.calculateDailyGET,
    required this.onAddActivity,
    required this.onRemoveActivity,
    required this.onCopyActivities,
    required this.onSetNaf,
    required this.onCopyNaf,
  });

  @override
  State<DietaryActivitySection> createState() => _DietaryActivitySectionState();
}

class _DietaryActivitySectionState extends State<DietaryActivitySection> {
  UserActivity? _hoveredActivity;

  @override
  Widget build(BuildContext context) {
    const orderedDays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    // Mantener orden fijo lunes-domingo y asegurar 7 columnas aunque falten claves.
    final days = [
      ...orderedDays,
      // Si hubiera claves extra no previstas, las mostramos al final.
      ...widget.dailyActivities.keys.where((d) => !orderedDays.contains(d)),
    ];

    // ✅ PATRÓN CLÍNICO: Grid vertical 4+3 (dos filas)
    // NO scroll horizontal, NO Wrap dinámico
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primera fila: Lunes a Jueves (4 días)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: days.take(4).map((day) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildDayCard(day),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Segunda fila: Viernes a Domingo (3 días)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...days.skip(4).take(3).map((day) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildDayCard(day),
                ),
              );
            }),
            // Espacio vacío para alinear con la primera fila
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCard(String day) {
    final activities = widget.dailyActivities[day] ?? const <UserActivity>[];
    final naf = widget.dailyNafFactors[day] ?? 1.0;
    final totalDailyGET = widget.calculateDailyGET(day);

    // ✅ Altura clínica: 325px fija (margen seguro para evitar overflow en desktop)
    // Cálculo de alturas internas (COMPACTADAS v2):
    // - Header: ~63px (1 fila compacta + border)
    // - Footer: ~44px (acciones con altura fija)
    // - Contenido: Flexible (ajustable)
    const totalHeight = 325.0;
    const footerHeight = 44.0;

    return SizedBox(
      height: totalHeight,
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Header compactado en una fila (eliminado overflow amarillo)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: kBorderColor.withAlpha((255 * 0.15).round()),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Lado izq: Día + GET grande
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              totalDailyGET.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'kcal',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Lado der: NAF chip + botón ajustar (alineados verticalmente compactos)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(
                            'NAF: ${naf.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 10,
                            ),
                          ),
                          backgroundColor: kAppBarColor.withAlpha(140),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextButton.icon(
                          onPressed: () => _showNafSelectionDialog(day),
                          icon: const Icon(
                            Icons.tune,
                            color: kPrimaryColor,
                            size: 13,
                          ),
                          label: const Text(
                            'Ajustar',
                            style: TextStyle(color: kPrimaryColor, fontSize: 9),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(
                              horizontal: -4,
                              vertical: -4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ✅ Lista compacta de actividades (altura flexible para evitar overflow)
              Flexible(
                child: activities.isEmpty
                    ? _buildEmptyState(day)
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: activities.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.8,
                          color: kPrimaryColor.withAlpha((255 * 0.15).round()),
                          indent: 12,
                          endIndent: 12,
                        ),
                        itemBuilder: (_, index) {
                          final activity = activities[index];
                          return _buildCompactActivityTile(day, activity);
                        },
                      ),
              ),
              // ✅ Acciones compactas al pie (altura fija para evitar overflow)
              SizedBox(
                height: footerHeight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kAppBarColor.withAlpha((255 * 0.25).round()),
                    border: Border(
                      top: BorderSide(
                        color: kBorderColor.withAlpha((255 * 0.15).round()),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniActionButton(
                        icon: Icons.add,
                        color: kPrimaryColor,
                        tooltip: 'Añadir Actividad',
                        onTap: () => _showAddActivityDialog(day),
                      ),
                      _buildMiniActionButton(
                        icon: Icons.copy_all,
                        color: activities.isNotEmpty
                            ? Colors.white70
                            : Colors.white24,
                        tooltip: 'Copiar Actividades',
                        onTap: activities.isNotEmpty
                            ? () => _showCopyDayDialog(day, activities)
                            : null,
                      ),
                      _buildMiniActionButton(
                        icon: Icons.repeat,
                        color: Colors.white70,
                        tooltip: 'Copiar NAF',
                        onTap: () => _showCopyNafDialog(day),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Tile compacto para lista vertical en header fijo
  Widget _buildCompactActivityTile(String day, UserActivity activity) {
    final bool isHovering = _hoveredActivity == activity;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredActivity = activity),
      onExit: (_) => setState(() => _hoveredActivity = null),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isHovering
              ? kPrimaryColor.withAlpha((255 * 0.12).round())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Título + Subtítulo (mejorado con jerarquía visual)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    activity.metActivity.activityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${activity.durationMinutes} min • ${activity.metValue} METs',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Icons siempre visible pero mutan en hover
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    // Editar (placeholder)
                  },
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: isHovering ? kPrimaryColor : Colors.white54,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    widget.onRemoveActivity(day, activity);
                    setState(() => _hoveredActivity = null);
                  },
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: isHovering ? Colors.redAccent : Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ❌ Método _buildTotalsBar removido - ahora los totales están en el header y acciones en footer

  Widget _buildEmptyState(String day) {
    return Center(
      child: InkWell(
        onTap: () => _showAddActivityDialog(day),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: kBorderColor.withAlpha((255 * 0.2).round()),
            ),
            borderRadius: BorderRadius.circular(8),
            color: kAppBarColor.withAlpha((255 * 0.15).round()),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: kTextColorSecondary.withAlpha((255 * 0.4).round()),
                size: 20,
              ),
              const SizedBox(height: 4),
              const Text(
                'Añadir actividad',
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? color.withAlpha((255 * 0.3).round()) : color,
          ),
        ),
      ),
    );
  }

  // --- DIALOGS ---
  void _showNafSelectionDialog(String day) {
    double currentNafFactor = widget.dailyNafFactors[day] ?? 1.0;
    NafRange currentRange = nafRanges.firstWhere(
      (range) => range.factors.contains(currentNafFactor),
      orElse: () => nafRanges.first,
    );

    NafRange selectedRange = currentRange;
    double selectedFactor = currentNafFactor;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: kCardColor,
              title: Text('Seleccionar NAF/NEAT para: $day'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 27.75),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 200,
                                maxWidth: 320,
                              ),
                              child: CustomDropdownButton<NafRange>(
                                label: 'Nivel de Actividad Diaria',
                                value: nafRanges.contains(selectedRange)
                                    ? selectedRange
                                    : nafRanges.first,
                                items: nafRanges,
                                itemLabelBuilder: (range) => range.label,
                                icon: Icons.directions_walk_outlined,
                                onChanged: (NafRange? newValue) {
                                  if (newValue == null) return;
                                  setStateSB(() {
                                    selectedRange = newValue;
                                    selectedFactor = newValue.factors.first;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 180,
                              maxWidth: 320,
                            ),
                            child: CompactDropdown<double>(
                              title: 'Factor NAF Específico',
                              value: selectedFactor,
                              items: selectedRange.factors,
                              onChanged: (double? newValue) {
                                if (newValue != null) {
                                  setStateSB(() {
                                    selectedFactor = newValue;
                                  });
                                }
                              },
                              icon: Icons.insights_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 720),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kAppBarColor.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: kTextColorSecondary.withAlpha(50),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            selectedRange.description,
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const Divider(height: 14, color: kTextColorSecondary),
                          Text(
                            selectedRange.context,
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontSize: 14,
                              fontStyle: FontStyle.normal,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: kTextColorSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onSetNaf(day, selectedFactor);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Guardar Factor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddActivityDialog(String day) async {
    String? selectedCategory;
    MetActivity? selectedActivity;
    double? selectedMetValue;

    final durationController = TextEditingController(text: '30');

    final categories = metLibrary
        .map((e) => e.category)
        .toSet()
        .where((cat) => cat != 'Actividades Cotidianas')
        .toList();
    List<MetActivity> filteredActivities = [];
    List<double> metOptions = [];

    try {
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateSB) {
              return AlertDialog(
                backgroundColor: kCardColor,
                title: Text('Añadir Actividad: $day'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 200,
                                maxWidth: 320,
                              ),
                              child: CustomDropdownButton<String>(
                                label: 'Categoría',
                                value: selectedCategory,
                                items: categories,
                                itemLabelBuilder: (cat) => cat,
                                onChanged: (String? newValue) {
                                  setStateSB(() {
                                    selectedCategory = newValue;
                                    selectedActivity = null;
                                    selectedMetValue = null;
                                    filteredActivities = selectedCategory == null
                                        ? []
                                        : metLibrary
                                            .where(
                                              (activity) =>
                                                  activity.category ==
                                                  selectedCategory,
                                            )
                                            .toList();
                                    metOptions = [];
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 200,
                                maxWidth: 320,
                              ),
                              child: CustomDropdownButton<MetActivity>(
                                label: 'Actividad',
                                value: selectedActivity,
                                items: filteredActivities,
                                itemLabelBuilder: (activity) =>
                                    activity.activityName,
                                onChanged: (MetActivity? newValue) {
                                  setStateSB(() {
                                    selectedActivity = newValue;
                                    metOptions = newValue?.metOptions.toList() ??
                                        [];
                                    selectedMetValue = metOptions.isNotEmpty
                                        ? metOptions[metOptions.length ~/ 2]
                                        : null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (selectedActivity != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kAppBarColor.withAlpha(150),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kPrimaryColor.withAlpha(100),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cómo se siente:',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                selectedActivity!.userFeel,
                                style: const TextStyle(
                                  color: kTextColor,
                                  fontSize: 13,
                                ),
                              ),
                              const Divider(
                                height: 16,
                                color: kTextColorSecondary,
                              ),
                              const Text(
                                'Ejemplos:',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                selectedActivity!.examples,
                                style: const TextStyle(
                                  color: kTextColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomDropdownButton<double>(
                              label: 'MET Específico',
                              value: selectedMetValue,
                              items: metOptions,
                              itemLabelBuilder: (met) => met.toString(),
                              onChanged: (double? newValue) {
                                setStateSB(() {
                                  selectedMetValue = newValue;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextFormField(
                              controller: durationController,
                              label: 'Dur (min)',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: kTextColorSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final duration =
                          int.tryParse(durationController.text) ?? 0;
                      if (selectedActivity != null &&
                          selectedMetValue != null &&
                          duration > 0) {
                        widget.onAddActivity(
                          day,
                          UserActivity(
                            day: day,
                            metActivity: selectedActivity!,
                            metValue: selectedMetValue!,
                            durationMinutes: duration,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      durationController.dispose();
    }
  }

  void _showCopyDayDialog(String fromDay, List<UserActivity> activities) {
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay actividades (EAT) para copiar.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final days = widget.dailyActivities.keys.toList();
    final Map<String, bool> selectedDays = {for (var d in days) d: false};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: kCardColor,
              title: Text('Copiar Actividades (EAT) de $fromDay'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: days
                      .where((d) => d != fromDay)
                      .map(
                        (d) => CheckboxListTile(
                          title: Text(d),
                          value: selectedDays[d],
                          onChanged: (bool? value) {
                            setStateSB(() {
                              selectedDays[d] = value ?? false;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: kTextColorSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final toDays = selectedDays.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();
                    if (toDays.isNotEmpty) {
                      widget.onCopyActivities(fromDay, toDays);
                    }
                    final count = toDays.length;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Actividades (EAT) copiadas a $count días.',
                        ),
                        backgroundColor: kPrimaryColor,
                      ),
                    );
                  },
                  child: const Text('Copiar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCopyNafDialog(String fromDay) {
    final double nafToCopy = widget.dailyNafFactors[fromDay] ?? 1.0;
    final days = widget.dailyActivities.keys.toList();
    final Map<String, bool> selectedDays = {for (var d in days) d: false};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: kCardColor,
              title: Text('Copiar NAF ($nafToCopy) de $fromDay'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: days
                      .where((d) => d != fromDay)
                      .map(
                        (d) => CheckboxListTile(
                          title: Text(d),
                          value: selectedDays[d],
                          onChanged: (bool? value) {
                            setStateSB(() {
                              selectedDays[d] = value ?? false;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: kTextColorSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final toDays = selectedDays.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();
                    if (toDays.isNotEmpty) {
                      widget.onCopyNaf(fromDay, toDays);
                    }
                    final count = toDays.length;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Factor NAF copiado a $count días.'),
                        backgroundColor: kPrimaryColor,
                      ),
                    );
                  },
                  child: const Text('Copiar NAF'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
