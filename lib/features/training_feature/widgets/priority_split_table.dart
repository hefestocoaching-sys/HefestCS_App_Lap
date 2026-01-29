import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/constants/muscle_labels_es.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Tabla que muestra el VMR efectivo por músculo según su rol asignado.
///
/// Lee las prioridades desde:
/// - priorityMusclesPrimary (comma-separated string)
/// - priorityMusclesSecondary (comma-separated string)
/// - priorityMusclesTertiary (comma-separated string)
///
/// Calcula VMR efectivo usando:
/// - Primary: 100% del MRV
/// - Secondary: MEV + 60% × (MRV - MEV)
/// - Tertiary: MEV + 25% × (MRV - MEV)
class PrioritySplitTable extends StatelessWidget {
  final Map<String, dynamic> trainingExtra;

  const PrioritySplitTable({super.key, required this.trainingExtra});

  @override
  Widget build(BuildContext context) {
    // Leer MEV y MRV
    final mevByMuscleRaw = trainingExtra['mevByMuscle'];
    final mrvByMuscleRaw = trainingExtra['mrvByMuscle'];

    final Map<String, dynamic> mevByMuscle = mevByMuscleRaw is Map
        ? Map<String, dynamic>.from(mevByMuscleRaw)
        : {};
    final Map<String, dynamic> mrvByMuscle = mrvByMuscleRaw is Map
        ? Map<String, dynamic>.from(mrvByMuscleRaw)
        : {};

    // Leer prioridades asignadas
    final primaryMuscles = _parseMusclePriority(
      trainingExtra[TrainingExtraKeys.priorityMusclesPrimary],
    );
    final secondaryMuscles = _parseMusclePriority(
      trainingExtra[TrainingExtraKeys.priorityMusclesSecondary],
    );
    final tertiaryMuscles = _parseMusclePriority(
      trainingExtra[TrainingExtraKeys.priorityMusclesTertiary],
    );

    // Si no hay datos de MEV/MRV, mostrar empty state
    if (mevByMuscle.isEmpty || mrvByMuscle.isEmpty) {
      return _buildEmptyState();
    }

    // Construir lista de músculos con su rol y VMR efectivo
    final List<_MuscleRoleData> muscleData = [];

    for (final muscle in mrvByMuscle.keys) {
      final mev = (mevByMuscle[muscle] as num?)?.toDouble() ?? 0;
      final mrv = (mrvByMuscle[muscle] as num?)?.toDouble() ?? 0;
      final range = mrv - mev;
      final muscleLower = muscle.toLowerCase();

      // Determinar rol asignado
      String role;
      double vmrEffective;
      Color roleColor;
      IconData roleIcon;

      if (primaryMuscles.contains(muscleLower)) {
        role = 'Primary';
        vmrEffective = mrv; // 100%
        roleColor = Colors.green;
        roleIcon = Icons.star;
      } else if (secondaryMuscles.contains(muscleLower)) {
        role = 'Secondary';
        vmrEffective = mev + 0.60 * range; // 60%
        roleColor = Colors.orange;
        roleIcon = Icons.star_half;
      } else if (tertiaryMuscles.contains(muscleLower)) {
        role = 'Tertiary';
        vmrEffective = mev + 0.25 * range; // 25%
        roleColor = Colors.blue;
        roleIcon = Icons.star_border;
      } else {
        // Músculo no asignado - usar Tertiary por defecto
        role = 'Sin asignar';
        vmrEffective = mev + 0.25 * range;
        roleColor = kTextColorSecondary;
        roleIcon = Icons.remove;
      }

      muscleData.add(
        _MuscleRoleData(
          muscle: muscle,
          mev: mev,
          mrv: mrv,
          role: role,
          vmrEffective: vmrEffective,
          roleColor: roleColor,
          roleIcon: roleIcon,
        ),
      );
    }

    // Ordenar: Primary primero, luego Secondary, luego Tertiary, luego sin asignar
    muscleData.sort((a, b) {
      const order = {
        'Primary': 0,
        'Secondary': 1,
        'Tertiary': 2,
        'Sin asignar': 3,
      };
      final orderA = order[a.role] ?? 4;
      final orderB = order[b.role] ?? 4;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.muscle.compareTo(b.muscle);
    });

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
            _buildCardHeader(
              primaryCount: primaryMuscles.length,
              secondaryCount: secondaryMuscles.length,
              tertiaryCount: tertiaryMuscles.length,
            ),
            _buildTableHeader(),
            const Divider(height: 1, color: kPrimaryColor),
            ...muscleData.map((data) => _buildRow(data)),
          ],
        ),
      ),
    );
  }

  String _canonMuscleId(String input) {
    var s = input.trim().toLowerCase();

    // Quitar acentos comunes (sin paquetes extra)
    s = s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');

    // Normalizar separadores
    s = s.replaceAll('&', 'y').replaceAll('/', ' ').replaceAll('-', ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Sinónimos ES -> IDs canónicos del motor (EN)
    const map = <String, String>{
      // Core grupos
      'pectoral': 'chest',
      'pecho': 'chest',
      'espalda': 'back',
      'dorsal': 'lats',
      'dorsales': 'lats',
      'lats': 'lats',
      'trapecio': 'traps',
      'traps': 'traps',
      'biceps': 'biceps',
      'triceps': 'triceps',
      'abdomen': 'abs',
      'abdominales': 'abs',
      'abs': 'abs',

      // Pierna
      'gluteo': 'glutes',
      'gluteos': 'glutes',
      'glutes': 'glutes',
      'cuadriceps': 'quads',
      'cuadricep': 'quads',
      'quads': 'quads',
      'isquiosurales': 'hamstrings',
      'isquios': 'hamstrings',
      'hamstrings': 'hamstrings',
      'gemelos': 'calves',
      'pantorrilla': 'calves',
      'gastrocnemio': 'calves',
      'soleo': 'calves',
      'calves': 'calves',

      // Hombro
      'hombro': 'shoulders',
      'hombros': 'shoulders',
      'deltoides': 'shoulders',
      'deltoide': 'shoulders',
      'deltoide frontal': 'shoulders',
      'deltoide lateral': 'shoulders',
      'deltoide posterior': 'shoulders',
      'deltoide lateral posterior': 'shoulders',
      'shoulders': 'shoulders',
    };

    // Match directo
    if (map.containsKey(s)) return map[s] ?? s;

    // Si ya viene como id canónico del motor, lo dejamos pasar
    const known = {
      'chest',
      'back',
      'lats',
      'traps',
      'shoulders',
      'biceps',
      'triceps',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'abs',
    };
    if (known.contains(s)) return s;

    // Heurística: si contiene tokens clave
    if (s.contains('pech') || s.contains('pector')) return 'chest';
    if (s.contains('espald')) return 'back';
    if (s.contains('dors')) return 'lats';
    if (s.contains('trap')) return 'traps';
    if (s.contains('bicep')) return 'biceps';
    if (s.contains('tricep')) return 'triceps';
    if (s.contains('abdom') || s.contains('core')) return 'abs';
    if (s.contains('glut')) return 'glutes';
    if (s.contains('cuad')) return 'quads';
    if (s.contains('isqu') || s.contains('femor')) return 'hamstrings';
    if (s.contains('gastro') ||
        s.contains('sole') ||
        s.contains('gemen') ||
        s.contains('pantor')) {
      return 'calves';
    }
    if (s.contains('delto') || s.contains('homb')) return 'shoulders';

    // fallback: devuelve string normalizado
    return s;
  }

  Set<String> _parseMusclePriority(dynamic raw) {
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
      // Permite CSV: "Pectoral, Espalda, Glúteo"
      for (final part in raw.split(',')) {
        addOne(part);
      }
      return out;
    }

    addOne(raw.toString());
    return out;
  }

  Widget _buildCardHeader({
    required int primaryCount,
    required int secondaryCount,
    required int tertiaryCount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: kPrimaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'VMR Efectivo por Prioridad',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Techo de volumen según rol asignado en la evaluación',
            style: TextStyle(color: kTextColorSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          // Resumen de asignaciones
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: kAppBarColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRoleChip(
                  count: primaryCount,
                  label: 'Primario',
                  color: Colors.green,
                  icon: Icons.star,
                  percent: '100%',
                ),
                _buildRoleChip(
                  count: secondaryCount,
                  label: 'Secundario',
                  color: Colors.orange,
                  icon: Icons.star_half,
                  percent: '60%',
                ),
                _buildRoleChip(
                  count: tertiaryCount,
                  label: 'Terciario',
                  color: Colors.blue,
                  icon: Icons.star_border,
                  percent: '25%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
    required String percent,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$label ($percent)',
          style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9),
        ),
      ],
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
            flex: 2,
            child: Text(
              'VME',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextColorSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'VMR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_MuscleRoleData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          // Músculo
          Expanded(
            flex: 3,
            child: Text(
              muscleLabelEs(data.muscle),
              style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
          ),
          // Rol con chip
          Expanded(
            flex: 2,
            child: _buildRowRoleChip(data.role, data.roleColor),
          ),
          // VME
          Expanded(
            flex: 2,
            child: Text(
              data.mev.round().toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
          ),
          // VMR (efectivo según rol)
          Expanded(
            flex: 2,
            child: Text(
              data.vmrEffective.round().toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: data.roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowRoleChip(String role, Color roleColor) {
    String label;
    if (role == 'Primary') {
      label = 'Primario';
    } else if (role == 'Secondary') {
      label = 'Secundario';
    } else if (role == 'Tertiary') {
      label = 'Terciario';
    } else {
      label = 'Sin asignar';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
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
              Icons.tune_outlined,
              size: 48,
              color: kTextColorSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Completa la evaluación de entrenamiento\npara ver el VMR efectivo por músculo',
              style: TextStyle(color: kTextColorSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Datos de un músculo con su rol asignado y VMR efectivo.
class _MuscleRoleData {
  final String muscle;
  final double mev;
  final double mrv;
  final String role;
  final double vmrEffective;
  final Color roleColor;
  final IconData roleIcon;

  _MuscleRoleData({
    required this.muscle,
    required this.mev,
    required this.mrv,
    required this.role,
    required this.vmrEffective,
    required this.roleColor,
    required this.roleIcon,
  });
}
