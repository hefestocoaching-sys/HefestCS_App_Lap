import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/constants/muscle_labels_es.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/muscle_detail_modal.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Modelo UI para una fila de la tabla de volumen por músculo.
/// Extrae datos de planJson.state.phase2 y phase3.
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
            _buildTableHeader(),
            const Divider(height: 1, color: kPrimaryColor),
            ...rows.map((row) => _buildRow(context, row)),
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

  Widget _buildRoleChip(String role) {
    final roleColor = _roleColor(role);
    final roleLabel = _roleLabelEs(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        roleLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: roleColor,
        ),
        overflow: TextOverflow.ellipsis,
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

  /// Traduce rol al español
  String _roleLabelEs(String role) {
    return switch (role) {
      'Primario' => 'Primario',
      'Secundario' => 'Secundario',
      'Terciario' => 'Terciario',
      _ => 'Primario',
    };
  }

  /// Retorna el color según rol
  Color _roleColor(String role) {
    return switch (role) {
      'Primario' => Colors.green,
      'Secundario' => Colors.orange,
      'Terciario' => Colors.blue,
      _ => kTextColorSecondary,
    };
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha: 0.05)),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Músculo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextColor,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rol',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextColor,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'VME',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextColor,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Volumen Objetivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextColor,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'VMR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, VolumeRangeUiRow row) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => MuscleDetailModal(
            muscleName: row.muscle,
            calculations: _buildCalculationsForRow(row),
            trainingExtra: trainingExtra ?? const {},
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            // Músculo
            Expanded(
              flex: 3,
              child: Text(
                muscleLabelEs(row.muscle),
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            // Rol con chip
            Expanded(flex: 2, child: _buildRoleChip(row.role)),
            // VME
            Expanded(
              flex: 1,
              child: Text(
                row.mev.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextColor, fontSize: 12),
              ),
            ),
            // Barra visual con target
            Expanded(
              flex: 4,
              child: row.targetSets != null
                  ? _VolumeBarWithTarget(row: row)
                  : const Center(
                      child: Text(
                        '--',
                        style: TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
            // VMR
            Expanded(
              flex: 1,
              child: Text(
                row.mrv.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextColor, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
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

/// Widget interno que dibuja la barra de volumen con el marker.
class _VolumeBarWithTarget extends StatelessWidget {
  final VolumeRangeUiRow row;

  const _VolumeBarWithTarget({required this.row});

  @override
  Widget build(BuildContext context) {
    final target = row.targetSets;
    if (target == null) {
      return const Center(
        child: Text('--', style: TextStyle(color: kTextColorSecondary)),
      );
    }

    return Tooltip(
      message: row.percentile != null
          ? 'Percentil utilizado: ${(row.percentile! * 100).toStringAsFixed(0)}%'
          : 'Sin percentil',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Número del target
          Text(
            target.toString(),
            style: TextStyle(
              color: row.zoneColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          // Barra visual
          SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final markerPosition = row.positionInRange * width;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Fondo de la barra (rango completo)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade800.withValues(alpha: 0.3),
                            Colors.green.shade600.withValues(alpha: 0.3),
                            Colors.orange.shade700.withValues(alpha: 0.3),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    // Marker del target
                    Positioned(
                      left: markerPosition.clamp(2, width - 6),
                      top: -2,
                      child: Container(
                        width: 4,
                        height: 12,
                        decoration: BoxDecoration(
                          color: row.zoneColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: row.zoneColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 2),
          // Label de zona
          Text(
            row.zoneLabel,
            style: TextStyle(
              color: row.zoneColor,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
