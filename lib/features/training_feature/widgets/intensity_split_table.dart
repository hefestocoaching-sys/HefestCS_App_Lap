import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/muscle_labels_es.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/features/training_feature/context/vop_context.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

/// Mapa de herencia: músculos divididos → grupo para resolución de rol
const Map<String, String> muscleToGroup = {
  // Canónico
  'back': 'back',
  'lats': 'back',
  'traps': 'back',
  'shoulders': 'shoulders',
  'calves': 'calves',

  // Legacy (mapea a canon)
  'dorsal_ancho': 'back',
  'erectores_espinales': 'back',
  'romboides': 'back',
  'trapecio_medio': 'back',
  'deltoide_anterior': 'shoulders',
  'deltoide_lateral': 'shoulders',
  'deltoide_posterior': 'shoulders',
  'gastrocnemio': 'calves',
  'soleo': 'calves',
};

/// Tab 3 — Volumen / Intensidad
/// - Solo muestra el VOP (Volumen Operativo Prescrito) y su split H/M/L.
/// - Incluye bloque explicativo estático de intensidad (RIR).
class IntensitySplitTable extends ConsumerStatefulWidget {
  final Map<String, dynamic> trainingExtra;

  const IntensitySplitTable({super.key, required this.trainingExtra});

  @override
  ConsumerState<IntensitySplitTable> createState() =>
      _IntensitySplitTableState();
}

class _IntensitySplitTableState extends ConsumerState<IntensitySplitTable> {
  // Split fijo para pintar la tabla de VOP con H/M/L
  static const Map<String, double> _seriesSplit = {
    'heavy': 0.25,
    'medium': 0.5,
    'light': 0.25,
  };

  // Control de distribución porcentual de series
  late int _heavyPercent;
  late int _mediumPercent;
  late int _lightPercent;
  bool _isSaving = false;
  bool _didAutoPersistDefaultSplit = false;

  @override
  void initState() {
    super.initState();
    _loadSeriesSplitFromExtra();
  }

  void _loadSeriesSplitFromExtra() {
    final raw = widget.trainingExtra[TrainingExtraKeys.seriesTypePercentSplit];
    bool needsPersist = false;

    if (raw is Map) {
      setState(() {
        _heavyPercent = (raw['heavy'] as num?)?.toInt() ?? 20;
        _mediumPercent = (raw['medium'] as num?)?.toInt() ?? 60;
        _lightPercent = (raw['light'] as num?)?.toInt() ?? 20;
      });
    } else {
      setState(() {
        _heavyPercent = 20;
        _mediumPercent = 60;
        _lightPercent = 20;
      });
      needsPersist = true;
    }

    // Auto-persistir defaults una sola vez si no existen
    if (needsPersist && !_didAutoPersistDefaultSplit) {
      _didAutoPersistDefaultSplit = true;
      _persistSplit(20, 60, 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    var vopRaw = <String, double>{};
    bool hasVop = false;

    final vopCtx = VopContext.ensure(widget.trainingExtra);
    if (vopCtx != null && vopCtx.hasData) {
      hasVop = true;
      vopRaw = vopCtx.snapshot.setsByMuscle.map(
        (k, v) => MapEntry(k, v.toDouble()),
      );
    }

    // Parse priority lists para roles
    final primaryMuscles = _parsePriorityList(
      widget.trainingExtra['priorityMusclesPrimary'],
    );
    final secondaryMuscles = _parsePriorityList(
      widget.trainingExtra['priorityMusclesSecondary'],
    );
    final tertiaryMuscles = _parsePriorityList(
      widget.trainingExtra['priorityMusclesTertiary'],
    );

    final intensityVolumeSplit = _seriesSplit;

    // Agrupar espalda como bloque único
    final vopByMuscle = _aggregateForDisplay(vopRaw);
    final muscles = vopByMuscle.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfilesEditor(context),
          if (hasVop) ...[
            _buildSectionTitle('Volumen Operativo Prescrito (VOP)'),
            _buildVopTable(
              muscles: muscles,
              vopByMuscle: vopByMuscle,
              intensitySplit: intensityVolumeSplit,
              primary: primaryMuscles,
              secondary: secondaryMuscles,
              tertiary: tertiaryMuscles,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aún no hay VOP',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este split se aplicará cuando el motor genere el plan de entrenamiento.',
                      style: TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildIntensityExplanation(context),
        ],
      ),
    );
  }

  /// No agrupar: mostrar cada músculo individualmente (evita sumas irreales)
  /// PARTE 2 A6: Normaliza claves a canónicas antes de mostrar
  Map<String, double> _aggregateForDisplay(Map<String, double> source) {
    final result = <String, double>{};
    source.forEach((key, value) {
      // PARTE 2 A6: Normalizar ANTES de agregar al resultado
      final normalizedKey = normalizeMuscleKey(key);
      result[normalizedKey] = (result[normalizedKey] ?? 0) + value;
    });

    debugPrint('[VOP][Tab2] Claves normalizadas: ${result.keys.join(", ")}');
    return result;
  }

  Widget _buildProfilesEditor(BuildContext context) {
    return _buildSeriesSplitControl(context);
  }

  /// Control en línea con 3 dropdowns para distribución de series H/M/L
  Widget _buildSeriesSplitControl(BuildContext context) {
    const heavyOptions = [15, 20, 25, 30];
    const lightOptions = [15, 20, 25, 30];
    const mediumOptions = [40, 45, 50, 55, 60, 65, 70];

    final total = _heavyPercent + _mediumPercent + _lightPercent;
    final isValid = total == 100;

    return Card(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución de series por semana',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Define qué porcentaje de tus series serán pesadas, medias o ligeras.',
              style: TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Dropdown: Heavy %
                Expanded(
                  child: _buildDropdownControl(
                    label: '% Pesadas',
                    value: _heavyPercent,
                    options: heavyOptions,
                    isValid: isValid,
                    onChanged: (val) => _updateSplit('heavy', val),
                  ),
                ),
                const SizedBox(width: 8),
                // Dropdown: Medium %
                Expanded(
                  child: _buildDropdownControl(
                    label: '% Medias',
                    value: _mediumPercent,
                    options: mediumOptions,
                    isValid: isValid,
                    onChanged: (val) => _updateSplit('medium', val),
                  ),
                ),
                const SizedBox(width: 8),
                // Dropdown: Light %
                Expanded(
                  child: _buildDropdownControl(
                    label: '% Ligeras',
                    value: _lightPercent,
                    options: lightOptions,
                    isValid: isValid,
                    onChanged: (val) => _updateSplit('light', val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Indicador de validación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isValid
                      ? 'Distribución válida (100%)'
                      : 'Distribución inválida ($total%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isValid ? Colors.green : Colors.red,
                  ),
                ),
                if (_isSaving)
                  const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 6),
                      Text('Guardando...', style: TextStyle(fontSize: 11)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dropdown single para un parámetro
  Widget _buildDropdownControl({
    required String label,
    required int value,
    required List<int> options,
    required bool isValid,
    required void Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: value,
          decoration:
              hcsDecoration(
                context,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ).copyWith(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isValid ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isValid ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
              ),
          items: options.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text('$v%', style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              onChanged(v);
            }
          },
        ),
      ],
    );
  }

  /// Actualiza un valor del split y persiste inmediatamente
  void _updateSplit(String changed, int newVal) async {
    setState(() {
      if (changed == 'heavy') {
        _heavyPercent = newVal;
      } else if (changed == 'medium') {
        _mediumPercent = newVal;
      } else if (changed == 'light') {
        _lightPercent = newVal;
      }
    });

    await _persistSplit(_heavyPercent, _mediumPercent, _lightPercent);
  }

  Future<void> _persistSplit(int heavy, int medium, int light) async {
    setState(() => _isSaving = true);
    try {
      // TAREA A5 PARTE 2: Llamar a recalculateSeriesDistribution
      // OPTIMISTIC: Actualiza localmente y sincroniza en background
      await ref
          .read(trainingPlanProvider.notifier)
          .recalculateSeriesDistribution(
            heavyPercent: heavy,
            mediumPercent: medium,
            lightPercent: light,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint(
                '⚠️  [Tab 2 UI] Persistencia timeout - estado local mantiene valores',
              );
            },
          );

      if (mounted) {
        debugPrint(
          '✅ [Tab 2 UI] Series recalculadas: H=$heavy% M=$medium% L=$light%',
        );
      }
    } catch (e) {
      debugPrint('❌ [Tab 2 UI] Error al persistir split: $e');
      // No mostrar error al usuario - el estado local está actualizado
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Parsea una lista de musculos (puede ser List String, String CSV, o null)
  Set<String> _parsePriorityList(dynamic raw) {
    if (raw == null) return {};

    final out = <String>{};

    void addOne(dynamic v) {
      if (v == null) return;
      final s = v.toString().trim();
      if (s.isEmpty) return;
      out.add(_canonMuscleId(s)); // CLAVE: canoniza aquí
    }

    if (raw is List) {
      for (final e in raw) {
        addOne(e);
      }
      return out;
    }

    if (raw is String) {
      for (final part in raw.split(',')) {
        addOne(part);
      }
      return out;
    }

    addOne(raw);
    return out;
  }

  /// Obtiene el rol (Primario/Secundario/Terciario) de un músculo
  /// Para músculos divididos, hereda el rol desde su grupo (back, shoulders, calves, etc.)
  /// Nunca retorna '—'
  String _getRoleLabel(
    String muscle,
    Set<String> primaryMuscles,
    Set<String> secondaryMuscles,
    Set<String> tertiaryMuscles,
  ) {
    // Resolver a grupo si es un músculo dividido
    final group = muscleToGroup[muscle] ?? muscle;
    final canonGroup = _canonMuscleId(group);

    if (primaryMuscles.contains(canonGroup)) {
      return 'Primario';
    }
    if (secondaryMuscles.contains(canonGroup)) {
      return 'Secundario';
    }
    if (tertiaryMuscles.contains(canonGroup)) {
      return 'Terciario';
    }
    // Nunca retornar '—'
    return 'Primario';
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

  /// Construye la tabla operativa del VOP
  Widget _buildVopTable({
    required List<String> muscles,
    required Map<String, double> vopByMuscle,
    required Map<String, double> intensitySplit,
    required Set<String> primary,
    required Set<String> secondary,
    required Set<String> tertiary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.43),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.06),
            ),
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
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Series (VOP)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Pesadas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Medias',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Ligeras',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Estado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.green),

          ...muscles.map((muscle) {
            final vop = vopByMuscle[muscle] ?? 0;

            // Distribuir series según split H/M/L
            final heavy = (vop * intensitySplit['heavy']!).round();
            final medium = (vop * intensitySplit['medium']!).round();
            final light = (vop * intensitySplit['light']!).round();

            const status = 'OK';
            const statusColor = Colors.green;

            final role = _getRoleLabel(muscle, primary, secondary, tertiary);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.green.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      muscleLabelEs(muscle),
                      style: const TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _roleColor(role).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleLabelEs(role),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _roleColor(role),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      vop.round().toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$heavy',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$medium',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$light',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.teal, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Bloque explicativo estático de intensidad (RIR)
  Widget _buildIntensityExplanation(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Intensidad (RIR / RER) — Guía de ejecución',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'La intensidad regula la proximidad al fallo según el tipo de ejercicio. '
              'No modifica el volumen (VOP) ni la prioridad muscular.',
            ),
            const SizedBox(height: 12),
            const Text('• Ejercicios pesados y complejos: RIR 3–4'),
            const Text('• Ejercicios medios: RIR 1–3'),
            const Text('• Ejercicios ligeros y aislados: RIR 0–1'),
            const SizedBox(height: 8),
            const Text(
              'Nota: El fallo (RIR 0) se utiliza solo en ejercicios seguros '
              'o en fases específicas del programa.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  /// Traduce rol al español
  String roleLabelEs(String role) {
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

  /// Construye título de sección con ícono
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
