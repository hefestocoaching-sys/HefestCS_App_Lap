import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'muscle_detail_modal.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// @deprecated Usar VolumeRangeMuscleTableV3 en su lugar
///
/// LEGACY - Esta versión lee phase2/phase3 que NO son generados por Motor V3.
/// Motor V3 usa SOLO: plan.volumePerMuscle (Map<String, int>)
///
/// Modelo UI para una fila de la tabla de volumen por músculo.
/// Extrae datos de planJson.state.phase2 y phase3 (LEGACY).
class VolumeRangeUiRow {
  final String muscle;
  final int mev;
  final int? targetSets; // Nullable para manejar "--"
  final int mrv;
  final double? percentile;
  final String role; // Primario, Secundario, Terciario

  const VolumeRangeUiRow({
    required this.muscle,
    required this.mev,
    this.targetSets,
    required this.mrv,
    this.percentile,
    required this.role,
  });

  /// Calcula la posición relativa del target dentro del rango [mev, mrv].
  /// Retorna un valor entre 0.0 y 1.0.
  double get positionInRange {
    if (targetSets == null) return 0.5;
    if (mrv <= mev) return 0.5;
    final range = mrv - mev;
    if (range == 0) return 0.5;
    final position = (targetSets! - mev) / range;
    return position.clamp(0.0, 1.0);
  }

  /// Determina el color según la zona del rango.
  /// Verde: 40%-70% del rango (óptimo)
  /// Amarillo: <40% (bajo)
  /// Ámbar: >70% (alto)
  Color get zoneColor {
    final pos = positionInRange;
    if (pos < 0.4) return Colors.amber.shade600; // Bajo
    if (pos > 0.7) return Colors.orange.shade700; // Alto
    return Colors.green.shade600; // Óptimo
  }

  String get zoneLabel {
    final pos = positionInRange;
    if (pos < 0.4) return 'Bajo';
    if (pos > 0.7) return 'Alto';
    return 'Óptimo';
  }
}

class MuscleVolumeData {
  final int vme;
  final int vmr;
  final int vma;
  final int target;
  final Map<String, dynamic>? calculations;

  MuscleVolumeData({
    required this.vme,
    required this.vmr,
    required this.vma,
    required this.target,
    this.calculations,
  });
}

/// Mapper que convierte los datos de planJson a filas UI.
class VolumeRangeMapper {
  const VolumeRangeMapper();

  /// Extrae y mapea los datos de phase2 y phase3 del planJson.
  /// Retorna lista ordenada alfabéticamente por músculo.
  List<VolumeRangeUiRow> mapFromPlanJson(Map<String, dynamic>? planJson) {
    if (planJson == null) return const [];

    final state = planJson['state'] as Map<String, dynamic>?;
    if (state == null) return const [];

    // Phase 2: muscleCapacityByMuscle o capacityByMuscle -> {muscle: {mev, mrv, mav}}
    final phase2 = state['phase2'] as Map<String, dynamic>?;
    // Soportar ambas claves por compatibilidad
    final capacityByMuscle =
        (phase2?['muscleCapacityByMuscle'] ?? phase2?['capacityByMuscle'])
            as Map<String, dynamic>?;

    // Phase 3: targetWeeklySetsByMuscle y chosenPercentileByMuscle
    final phase3 = state['phase3'] as Map<String, dynamic>?;
    final targetWeeklySetsByMuscle =
        phase3?['targetWeeklySetsByMuscle'] as Map<String, dynamic>?;
    final chosenPercentileByMuscle =
        phase3?['chosenPercentileByMuscle'] as Map<String, dynamic>?;

    if (capacityByMuscle == null) return const [];

    final rows = <VolumeRangeUiRow>[];

    for (final entry in capacityByMuscle.entries) {
      final muscle = entry.key;
      final capacityData = entry.value;

      if (capacityData is! Map<String, dynamic>) continue;

      final mev = _readInt(capacityData, 'mev');
      final mrv = _readInt(capacityData, 'mrv');

      // Obtener target de phase3, null si no existe (se mostrará "--")
      final targetRaw = targetWeeklySetsByMuscle?[muscle];
      final int? targetSets = targetRaw is num ? targetRaw.round() : null;

      // Obtener percentil de phase3
      final percentileRaw = chosenPercentileByMuscle?[muscle];
      final percentile = percentileRaw is num ? percentileRaw.toDouble() : null;

      rows.add(
        VolumeRangeUiRow(
          muscle: muscle,
          mev: mev,
          targetSets: targetSets,
          mrv: mrv,
          percentile: percentile,
          role: 'Primario', // Default para planJson (sin datos de prioridad)
        ),
      );
    }

    // Ordenar alfabéticamente
    rows.sort((a, b) => a.muscle.compareTo(b.muscle));

    return rows;
  }

  int _readInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }

  /// Extrae datos DIRECTAMENTE de training.extra del cliente.
  /// Esta es la FUENTE PRIMARIA cuando el Motor v2 ha generado datos.
  /// NO usa baseSeries, mevIndividual, mrvIndividual ni valores por defecto.
  /// TAMBIÉN resuelve roles a partir de priority lists.
  List<VolumeRangeUiRow> mapFromTrainingExtra(
    Map<String, dynamic>? extra,
    VolumeRangeMuscleTable parent,
  ) {
    if (extra == null) return const [];

    // FUENTE ÚNICA: Solo usar mapas por músculo generados por Motor v2
    final mevByMuscle = _readNumMap(extra, 'mevByMuscle');
    final mrvByMuscle = _readNumMap(extra, 'mrvByMuscle');
    final targetSetsByMuscle = _readNumMap(extra, 'targetSetsByMuscle');

    // Si no hay mapas por músculo, no mostrar nada
    if (mevByMuscle.isEmpty &&
        mrvByMuscle.isEmpty &&
        targetSetsByMuscle.isEmpty) {
      return const [];
    }

    // Parse priority lists
    final primaryMuscles = parent._parsePriorityList(
      extra[TrainingExtraKeys.priorityMusclesPrimary],
    );
    final secondaryMuscles = parent._parsePriorityList(
      extra[TrainingExtraKeys.priorityMusclesSecondary],
    );
    final tertiaryMuscles = parent._parsePriorityList(
      extra[TrainingExtraKeys.priorityMusclesTertiary],
    );

    // Unir todas las keys de músculos desde los mapas
    final allMuscles = <String>{
      ...mevByMuscle.keys,
      ...mrvByMuscle.keys,
      ...targetSetsByMuscle.keys,
    };

    final rows = <VolumeRangeUiRow>[];

    for (final muscle in allMuscles) {
      final mevRaw = mevByMuscle[muscle];
      final mrvRaw = mrvByMuscle[muscle];
      final targetRaw = targetSetsByMuscle[muscle];

      final int mev = mevRaw?.round() ?? 0;
      final int mrv = mrvRaw?.round() ?? 0;
      final int? targetSets = targetRaw?.round();

      if (mev > 0 || mrv > 0) {
        // Resolver rol
        final role = parent._getRoleLabel(
          muscle,
          primaryMuscles,
          secondaryMuscles,
          tertiaryMuscles,
        );

        rows.add(
          VolumeRangeUiRow(
            muscle: muscle,
            mev: mev,
            targetSets: targetSets,
            mrv: mrv,
            percentile: null,
            role: role,
          ),
        );
      }
    }

    rows.sort((a, b) => a.muscle.compareTo(b.muscle));
    return rows;
  }

  /// Extrae datos del TrainingPlanConfig (Motor Legacy) o training.extra con Motor v2.
  /// Usa EXCLUSIVAMENTE mevByMuscle, mrvByMuscle, targetSetsByMuscle del extra.
  /// NO usa baseSeries, mevIndividual, mrvIndividual ni valores por defecto.
  /// TAMBIÉN resuelve roles a partir de priority lists.
  List<VolumeRangeUiRow> mapFromPlanConfig(
    TrainingPlanConfig? planConfig,
    VolumeRangeMuscleTable parent,
  ) {
    if (planConfig == null) return const [];

    final extra = planConfig.trainingProfileSnapshot?.extra;
    if (extra == null) return const [];

    // FUENTE ÚNICA: Solo usar mapas por músculo
    // NO usar baseSeries, mevIndividual, mrvIndividual, ni defaults
    final mevByMuscle = _readNumMap(extra, 'mevByMuscle');
    final mrvByMuscle = _readNumMap(extra, 'mrvByMuscle');
    final targetSetsByMuscle = _readNumMap(extra, 'targetSetsByMuscle');

    // Si no hay mapas por músculo, no mostrar nada
    if (mevByMuscle.isEmpty &&
        mrvByMuscle.isEmpty &&
        targetSetsByMuscle.isEmpty) {
      return const [];
    }

    // Parse priority lists
    final primaryMuscles = parent._parsePriorityList(
      extra[TrainingExtraKeys.priorityMusclesPrimary],
    );
    final secondaryMuscles = parent._parsePriorityList(
      extra[TrainingExtraKeys.priorityMusclesSecondary],
    );
    final tertiaryMuscles = parent._parsePriorityList(
      extra[TrainingExtraKeys.priorityMusclesTertiary],
    );

    // Unir todas las keys de músculos desde los mapas
    final allMuscles = <String>{
      ...mevByMuscle.keys,
      ...mrvByMuscle.keys,
      ...targetSetsByMuscle.keys,
    };

    final rows = <VolumeRangeUiRow>[];

    for (final muscle in allMuscles) {
      // CRÍTICO: Si no existe el valor, usar null (mostrará "--")
      // NO usar 0 ni valores por defecto
      final mevRaw = mevByMuscle[muscle];
      final mrvRaw = mrvByMuscle[muscle];
      final targetRaw = targetSetsByMuscle[muscle];

      final int mev = mevRaw?.round() ?? 0;
      final int mrv = mrvRaw?.round() ?? 0;

      // targetSets es NULLABLE: null = mostrar "--", nunca un default
      final int? targetSets = targetRaw?.round();

      // Solo incluir si hay al menos MEV o MRV válido
      if (mev > 0 || mrv > 0) {
        // Resolver rol
        final role = parent._getRoleLabel(
          muscle,
          primaryMuscles,
          secondaryMuscles,
          tertiaryMuscles,
        );

        rows.add(
          VolumeRangeUiRow(
            muscle: muscle,
            mev: mev,
            targetSets: targetSets, // null si no existe -> mostrará "--"
            mrv: mrv,
            percentile: null, // El motor legacy no guarda percentiles
            role: role,
          ),
        );
      }
    }

    // Ordenar alfabéticamente
    rows.sort((a, b) => a.muscle.compareTo(b.muscle));

    return rows;
  }

  /// Lee un `Map<String, num>` de extra, retornando `Map<String, double>`.
  Map<String, double> _readNumMap(Map<String, dynamic> extra, String key) {
    final raw = extra[key];
    if (raw is! Map) return <String, double>{};
    final out = <String, double>{};
    raw.forEach((k, v) {
      if (k == null) return;
      final keyStr = k.toString();
      if (v is num) {
        out[keyStr] = v.toDouble();
      } else if (v is String) {
        final p = double.tryParse(v.replaceAll(',', '.'));
        if (p != null) out[keyStr] = p;
      }
    });
    return out;
  }
}

/// Widget de tabla densa que muestra el rango fisiológico (VME-VMR)
/// y el volumen objetivo semanal por músculo.
///
/// Fuentes de datos (en orden de prioridad):
/// 1. trainingExtra (PRIMARIA): training.extra del cliente con datos Motor v2
/// 2. planJson (Motor v2): planJson.state.phase2/phase3
/// 3. planConfig (Motor Legacy): trainingProfileSnapshot.extra
class VolumeRangeMuscleTable extends StatelessWidget {
  /// FUENTE PRIMARIA: training.extra del cliente (Motor v2 genera targetSetsByMuscle)
  final Map<String, dynamic>? trainingExtra;

  /// Datos del Motor v2 (phase2.capacityByMuscle, phase3.targetWeeklySetsByMuscle)
  final Map<String, dynamic>? planJson;

  /// Datos del Motor Legacy (trainingProfileSnapshot.extra) - SOLO como fallback
  final TrainingPlanConfig? planConfig;

  const VolumeRangeMuscleTable({
    super.key,
    this.trainingExtra,
    this.planJson,
    this.planConfig,
  });

  @override
  Widget build(BuildContext context) {
    const mapper = VolumeRangeMapper();

    // 🔍 LOG AUDITORÍA: Verificar fuente de datos
    debugPrint('[UI][TAB1] trainingExtra != null: ${trainingExtra != null}');
    if (trainingExtra != null) {
      debugPrint(
        '[UI][TAB1] trainingExtra[targetSetsByMuscle] = ${trainingExtra!['targetSetsByMuscle']}',
      );
      debugPrint(
        '[UI][TAB1] trainingExtra[mevByMuscle] = ${trainingExtra!['mevByMuscle']}',
      );
    }
    if (planJson != null) {
      final state = planJson!['state'] as Map<String, dynamic>?;
      final phase3 = state?['phase3'] as Map<String, dynamic>?;
      final targets = phase3?['targetWeeklySetsByMuscle'];
      debugPrint(
        '[UI][TAB1] planJson.phase3.targetWeeklySetsByMuscle = $targets',
      );
    }

    // ORDEN DE PRIORIDAD:
    // 1. trainingExtra (fuente primaria - datos v2 en cliente)
    // 2. planJson (Motor v2 directo)
    // 3. planConfig (legacy fallback)
    var rows = mapper.mapFromTrainingExtra(trainingExtra, this);
    if (rows.isEmpty) {
      rows = mapper.mapFromPlanJson(planJson);
    }
    if (rows.isEmpty) {
      rows = mapper.mapFromPlanConfig(planConfig, this);
    }

    if (rows.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: kAppBarColor.withValues(alpha: 0.43),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCardHeader(),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1.0),
                2: FlexColumnWidth(1.0),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.5),
                5: FixedColumnWidth(70),
              },
              children: [
                _buildHeaderRow(),
                ...rows.map((row) {
                  final data = _toMuscleVolumeData(row);
                  return _buildMuscleRow(row.muscle, data);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: kPrimaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Cálculo de Series por Músculo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Rango fisiológico (VME–VMR) y volumen objetivo semanal',
            style: TextStyle(color: kTextColorSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'La prioridad muscular (Rol) es un atributo explicativo: no se entrena directamente, '
              'solo indica por qué un músculo recibe más o menos volumen dentro de su rango fisiológico.',
              style: TextStyle(color: kTextColorSecondary, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS PARA RESOLUCIÓN DE ROLES (copiados de intensity_split_table.dart)
  // ════════════════════════════════════════════════════════════════════════

  /// Obtiene el rol (Primario/Secundario/Terciario) de un músculo
  String _getRoleLabel(
    String muscle,
    Set<String> primaryMuscles,
    Set<String> secondaryMuscles,
    Set<String> tertiaryMuscles,
  ) {
    final canonMuscle = _canonMuscleId(muscle);

    if (primaryMuscles.contains(canonMuscle)) {
      return 'Primario';
    }
    if (secondaryMuscles.contains(canonMuscle)) {
      return 'Secundario';
    }
    if (tertiaryMuscles.contains(canonMuscle)) {
      return 'Terciario';
    }
    return 'Primario'; // default
  }

  /// Canonicaliza nombre de músculo (español → inglés)
  String _canonMuscleId(String input) {
    if (input.isEmpty) return '';

    // Remover acentos
    var clean = input.toLowerCase().trim();
    clean = clean.replaceAll(RegExp(r'[áà]'), 'a');
    clean = clean.replaceAll(RegExp(r'[éè]'), 'e');
    clean = clean.replaceAll(RegExp(r'[íì]'), 'i');
    clean = clean.replaceAll(RegExp(r'[óò]'), 'o');
    clean = clean.replaceAll(RegExp(r'[úù]'), 'u');

    // Mapeo explícito de sinónimos
    const mapping = {
      'pectoral': 'chest',
      'pecho': 'chest',
      'gluteo': 'glutes',
      'gluteos': 'glutes',
      'espalda': 'back',
      'lats': 'lats',
      'dorsal': 'lats',
      'dorsales': 'lats',
      'cuadriceps': 'quads',
      'femoral': 'hamstrings',
      'femorales': 'hamstrings',
      'isquio': 'hamstrings',
      'tibial': 'calves',
      'gemelo': 'calves',
      'gemelos': 'calves',
      'pantorrilla': 'calves',
      'pantorrillas': 'calves',
      'hombro': 'shoulders',
      'deltoides': 'shoulders',
      'deltoid': 'shoulders',
      'deltoide': 'shoulders',
      'trapecio': 'traps',
      'trapecios': 'traps',
      'bíceps': 'biceps',
      'biceps': 'biceps',
      'tríceps': 'triceps',
      'triceps': 'triceps',
      'antebrazo': 'forearms',
      'antebrazos': 'forearms',
      'abdomen': 'abs',
      'abdominal': 'abs',
      'abdominales': 'abs',
      'core': 'abs',
      'oblicuo': 'obliques',
      'oblicuos': 'obliques',
    };

    if (mapping.containsKey(clean)) {
      return mapping[clean]!;
    }

    // Heurística: partial match
    for (final entry in mapping.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        return entry.value;
      }
    }

    return clean;
  }

  /// Parsea una lista de prioridades (string CSV o List)
  Set<String> _parsePriorityList(dynamic raw) {
    if (raw == null) return {};

    final out = <String>{};

    void addOne(String v) {
      if (v.trim().isEmpty) return;
      out.add(_canonMuscleId(v));
    }

    if (raw is List) {
      for (final e in raw) {
        if (e == null) continue;
        addOne(e.toString());
      }
      return out;
    }

    if (raw is String) {
      for (final part in raw.split(',')) {
        addOne(part);
      }
      return out;
    }

    addOne(raw.toString());
    return out;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.43),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: kTextColorSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Genera un plan para ver el cálculo\nde series por músculo',
              style: TextStyle(color: kTextColorSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: kPrimaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      children: [
        _buildTableCell('Músculo', isHeader: true, alignment: TextAlign.left),
        _buildTableCell('VME', isHeader: true),
        _buildTableCell('VMR', isHeader: true),
        _buildTableCell('Target', isHeader: true),
        _buildTableCell('Estado', isHeader: true),
        _buildTableCell('Detalles', isHeader: true),
      ],
    );
  }

  TableRow _buildMuscleRow(String muscle, MuscleVolumeData data) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    final double percentage = data.vma == 0
        ? 0.0
        : (data.target / data.vma) * 100;

    if (data.target < data.vme) {
      statusColor = Colors.red;
      statusText = 'Bajo VME';
      statusIcon = Icons.warning;
    } else if (data.target >= data.vme && data.target < data.vma) {
      statusColor = Colors.orange;
      statusText = 'Subóptimo';
      statusIcon = Icons.trending_down;
    } else if (data.target >= data.vma && data.target < data.vmr) {
      statusColor = Colors.green;
      statusText = 'Óptimo';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.red;
      statusText = 'Riesgo';
      statusIcon = Icons.error;
    }

    return TableRow(
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: kPrimaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      children: [
        _buildTableCell(
          _formatMuscleName(muscle),
          isHeader: false,
          alignment: TextAlign.left,
          fontWeight: FontWeight.w600,
        ),
        _buildTableCell(
          data.vme.toString(),
          isHeader: false,
          color: Colors.orange.withValues(alpha: 0.7),
        ),
        _buildTableCell(
          data.vmr.toString(),
          isHeader: false,
          color: Colors.red.withValues(alpha: 0.7),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.target.toString(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(statusIcon, size: 14, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              _buildPercentageCell(percentage),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Center(
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.analytics_outlined,
                  size: 20,
                  color: kPrimaryColor,
                ),
                tooltip: 'Ver cálculos científicos',
                onPressed: () => _showMuscleDetails(context, muscle, data),
                style: IconButton.styleFrom(
                  backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    TextAlign alignment = TextAlign.center,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        textAlign: alignment,
        style: TextStyle(
          color: color ?? (isHeader ? kPrimaryColor : kTextColor),
          fontSize: isHeader ? 13 : 12,
          fontWeight:
              fontWeight ?? (isHeader ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildPercentageCell(double percentage) {
    final visualState = _VolumeRangeMuscleTableState();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: visualState._getBackgroundForPercentage(percentage),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: visualState._getTextColorForPercentage(percentage),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  void _showMuscleDetails(
    BuildContext context,
    String muscle,
    MuscleVolumeData data,
  ) {
    showDialog(
      context: context,
      builder: (context) => MuscleDetailModal(
        muscleName: muscle,
        vme: data.vme,
        vmr: data.vmr,
        vma: data.vma,
        target: data.target,
        calculations: data.calculations,
        onOverrideApplied: (vme, vmr, reason) {
          _handleVolumeOverride(context, muscle, vme, vmr, reason);
        },
      ),
    );
  }

  void _handleVolumeOverride(
    BuildContext context,
    String muscle,
    int vme,
    int vmr,
    String reason,
  ) {
    debugPrint(
      'Override aplicado a $muscle: VME=$vme, VMR=$vmr, Razón: $reason',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Override guardado para $muscle'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            // TODO: Implementar undo
          },
        ),
      ),
    );
  }

  String _formatMuscleName(String muscle) {
    final names = {
      'chest': 'Pecho',
      'lats': 'Dorsales',
      'midBack': 'Espalda Media',
      'lowBack': 'Lumbar',
      'traps': 'Trapecios',
      'frontDelts': 'Hombro Frontal',
      'sideDelts': 'Hombro Lateral',
      'rearDelts': 'Hombro Posterior',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'quads': 'Cuádriceps',
      'hamstrings': 'Isquiosurales',
      'glutes': 'Glúteos',
      'calves': 'Gemelos',
      'abs': 'Abdominales',
    };
    return names[muscle.toLowerCase()] ?? muscle;
  }

  MuscleVolumeData _toMuscleVolumeData(VolumeRangeUiRow row) {
    final vme = row.mev;
    final vmr = row.mrv;
    final vma = ((vme + vmr) / 2).round();

    return MuscleVolumeData(
      vme: vme,
      vmr: vmr,
      vma: vma,
      target: row.targetSets ?? 0,
      calculations: _buildCalculationsForRow(row),
    );
  }

  Map<String, dynamic> _buildCalculationsForRow(VolumeRangeUiRow row) {
    final vme = row.mev;
    final vmr = row.mrv;
    final vma = ((vme + vmr) / 2).round();

    return {
      'vme': vme,
      'vma': vma,
      'vmr': vmr,
      'target': row.targetSets ?? 0,
      'adjustments': const <String, dynamic>{},
      'baseVME': vme,
      'alerts': const <Map<String, dynamic>>[],
    };
  }
}

class _VolumeRangeMuscleTableState {
  /// Retorna color de fondo según porcentaje de MAV
  Color _getBackgroundForPercentage(double percentage) {
    if (percentage < 80) return kWarningSubtle; // Bajo MEV
    if (percentage > 110) return kErrorSubtle; // Sobre MRV
    return kSuccessSubtle; // Zona óptima MAV
  }

  /// Retorna color de texto según porcentaje de MAV
  Color _getTextColorForPercentage(double percentage) {
    if (percentage < 80) return kWarningColor;
    if (percentage > 110) return kErrorColor;
    return kSuccessColor;
  }
}
