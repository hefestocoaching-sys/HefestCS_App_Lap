import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/biochemistry_record.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/biochemistry_analyzer.dart';
import 'package:hcs_app_lap/utils/widgets/module_card_container.dart';
import 'package:intl/intl.dart';

import '../../../utils/widgets/bio_analysis_result.dart';

class BiochemistryComparisonScreen extends ConsumerStatefulWidget {
  const BiochemistryComparisonScreen({super.key});

  @override
  ConsumerState<BiochemistryComparisonScreen> createState() =>
      _BiochemistryComparisonScreenState();
}

class _BiochemistryComparisonScreenState
    extends ConsumerState<BiochemistryComparisonScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Client? _client;
  BioChemistryRecord? recordA;
  BioChemistryRecord? recordB;

  @override
  void initState() {
    super.initState();
    _client = ref.read(clientsProvider).value?.activeClient;
    _loadInitialRecords();
  }

  @override
  void didUpdateWidget(covariant BiochemistryComparisonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newClient = ref.read(clientsProvider).value?.activeClient;
    if (newClient != null &&
        (newClient.id != _client?.id ||
            newClient.biochemistry != _client?.biochemistry)) {
      _client = newClient;
      _loadInitialRecords();
    }
  }

  void _loadInitialRecords() {
    final client = _client;
    if (client == null) {
      if (mounted) {
        setState(() {
          recordA = null;
          recordB = null;
        });
      }
      return;
    }
    final records = List<BioChemistryRecord>.from(client.biochemistry);
    if (records.isEmpty) {
      if (mounted) {
        setState(() {
          recordA = null;
          recordB = null;
        });
      }
      return;
    }

    records.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        recordA = records.first;
        recordB = records.length > 1 ? records[1] : null;
      });
    }
  }

  final List<Map<String, String>> _tableStructure = const [
    {'title': 'PANEL METABÓLICO', 'key': ''},
    {'title': 'Glucosa (mg/dL)', 'key': 'glucose'},
    {'title': 'HbA1c (%)', 'key': 'hba1c'},
    {'title': 'Insulina Ayunas (µU/mL)', 'key': 'fastingInsulin'},
    {'title': 'PERFIL LIPÍDICO', 'key': ''},
    {'title': 'Colesterol Total (mg/dL)', 'key': 'cholesterolTotal'},
    {'title': 'LDL-c (mg/dL)', 'key': 'ldl'},
    {'title': 'HDL-c (mg/dL)', 'key': 'hdl'},
    {'title': 'Triglicéridos (mg/dL)', 'key': 'triglycerides'},
    {'title': 'ApoB (mg/dL)', 'key': 'apoB'},
    {'title': 'ApoA-1 (mg/dL)', 'key': 'apoA1'},
    {'title': 'Ratio ApoB/ApoA-1', 'key': 'apoBRatio'},
    {'title': 'FUNCIÓN HEPÁTICA', 'key': ''},
    {'title': 'AST (U/L)', 'key': 'ast'},
    {'title': 'ALT (U/L)', 'key': 'alt'},
    {'title': 'Albumina (g/dL)', 'key': 'albumin'},
    {'title': 'Función RENAL', 'key': ''},
    {'title': 'Creatinina (mg/dL)', 'key': 'creatinine'},
    {'title': 'eGFR (mL/min/1.73m²)', 'key': 'egfr'},
    {'title': 'Ácido Úrico (mg/dL)', 'key': 'uricAcid'},
    {'title': 'HEMATOLOGÍA / HIERRO', 'key': ''},
    {'title': 'Hemoglobina (g/dL)', 'key': 'hemoglobin'},
    {'title': 'Hematocrito (%)', 'key': 'hematocrit'},
    {'title': 'MCV (fL)', 'key': 'mcv'},
    {'title': 'Ferritina (ng/mL)', 'key': 'ferritin'},
    {'title': 'Sat. Transferrina (%)', 'key': 'transferrinSaturation'},
    {'title': 'HORMONAL (RIESGO EAAs)', 'key': ''},
    {'title': 'Testosterona Total (ng/dL)', 'key': 'testosteroneTotal'},
    {'title': 'Estradiol (pg/mL)', 'key': 'estradiol'},
    {'title': 'SHBG (nmol/L)', 'key': 'shbg'},
    {'title': 'LH (mIU/mL)', 'key': 'lh'},
    {'title': 'FSH (mIU/mL)', 'key': 'fsh'},
    {'title': 'Tiroides TSH (mIU/L)', 'key': 'tsh'},
    {'title': 'Tiroides T4 Libre (ng/dL)', 'key': 't4Free'},
    {'title': 'Tiroides T3 Libre (pg/mL)', 'key': 't3Free'},
  ];

  double? _getValue(BioChemistryRecord? record, String key) {
    if (record == null) return null;
    final recordMap = record.toJson();
    final direct = recordMap[key];
    if (direct is num) return direct.toDouble();
    final extra = recordMap['extra'];
    if (extra is Map) {
      final extraVal = extra[key];
      if (extraVal is num) return extraVal.toDouble();
    }
    return null;
  }

  Future<BioChemistryRecord?> _selectRecord(
    BioChemistryRecord? currentSelection,
    bool isRecordA,
  ) async {
    final client = _client;
    if (client == null) return null;
    final records = List<BioChemistryRecord>.from(client.biochemistry);
    if (records.isEmpty) return null;

    records.sort((a, b) => b.date.compareTo(a.date));

    return await showDialog<BioChemistryRecord>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: Text(
            isRecordA
                ? 'Seleccionar Fecha Final (A)'
                : 'Seleccionar Fecha Inicial (B)',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final dateStr = DateFormat(
                  'dd/MM/yyyy',
                  'es',
                ).format(record.date);
                final isSelected = record == currentSelection;
                final isOtherRecord = (isRecordA ? recordB : recordA) == record;

                return ListTile(
                  title: Text(dateStr),
                  subtitle: Text(
                    isSelected
                        ? 'Seleccionado'
                        : (isOtherRecord ? 'Otro Punto de Comparación' : ''),
                  ),
                  selected: isSelected,
                  onTap: () => Navigator.pop(context, record),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonCell(double? valueA, double? valueB, String key) {
    if (valueA == null) {
      return const Center(
        child: Text('N/A', style: TextStyle(color: kTextColorSecondary)),
      );
    }

    final delta = valueB != null ? valueA - valueB : null;

    final gender = _client?.profile.gender?.label;
    final analysisA = BiochemistryAnalyzer.analyze(key, valueA, gender: gender);

    Color deltaColor = kTextColor;
    String deltaText = '---';

    if (delta != null && valueB != null) {
      final isPositive = delta > 0.01;
      final isNegative = delta < -0.01;
      final percentageChange = valueB != 0 ? (delta / valueB.abs()) * 100 : 0.0;

      if (key == 'hdl' ||
          key == 'apoA1' ||
          key == 'egfr' ||
          key.contains('muscle')) {
        deltaColor = isPositive
            ? Colors.greenAccent.shade700
            : (isNegative ? Colors.redAccent.shade700 : kTextColor);
      } else if (key == 'ldl' ||
          key == 'apoB' ||
          key == 'triglycerides' ||
          key.contains('ast') ||
          key.contains('hematocrit')) {
        deltaColor = isPositive
            ? Colors.redAccent.shade700
            : (isNegative ? Colors.greenAccent.shade700 : kTextColor);
      } else {
        deltaColor = isPositive
            ? Colors.yellow.shade700
            : (isNegative ? Colors.blueAccent.shade400 : kTextColor);
      }

      deltaText =
          '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} (${percentageChange > 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: analysisA?.color.withAlpha(25) ?? Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valueA.toStringAsFixed(1),
                style: TextStyle(
                  color: analysisA?.color ?? kTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (analysisA?.status != BioStatus.normal &&
                  analysisA?.status != BioStatus.optimal)
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: analysisA?.color,
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (recordB != null)
            Text(
              deltaText,
              style: TextStyle(
                color: deltaColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final client = ref.watch(clientsProvider).value?.activeClient;
    if (_client != client && client != null) {
      _client = client;
      _loadInitialRecords();
    }

    if (client == null || client.biochemistry.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Text(
            client == null
                ? "Selecciona un cliente o crea uno nuevo"
                : "Necesitas al menos dos registros bioquímicos para usar la función de comparación avanzada.",
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (recordA == null) _loadInitialRecords();
    if (recordA == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ModuleCardContainer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Análisis y Evolución Histórica',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Cargar Recientes'),
                    onPressed: _loadInitialRecords,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDateSelector('Fecha Final (A - Reciente)', recordA, true),
                _buildDateSelector(
                  'Fecha Inicial (B - Histórico)',
                  recordB,
                  false,
                ),
              ],
            ),
            const Divider(height: 32),
            _buildComparisonTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    String title,
    BioChemistryRecord? record,
    bool isRecordA,
  ) {
    final dateText = record != null
        ? DateFormat('dd/MM/yyyy', 'es').format(record.date)
        : 'Seleccionar';

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: kTextColorSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kAppBarColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextButton(
            onPressed: () async {
              final selected = await _selectRecord(
                isRecordA ? recordA : recordB,
                isRecordA,
              );
              if (selected != null) {
                setState(() {
                  if (isRecordA) {
                    recordA = selected;
                  } else {
                    recordB = selected;
                  }
                  if (recordA != null &&
                      recordB != null &&
                      recordA!.date.isBefore(recordB!.date)) {
                    final temp = recordA;
                    recordA = recordB;
                    recordB = temp;
                  }
                });
              }
            },
            child: Text(
              dateText,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder.symmetric(
        inside: BorderSide(
          color: kTextColorSecondary,
          width: 0.5,
        ),
        outside: BorderSide(color: kAppBarColor, width: 2),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: kAppBarColor.withAlpha(150)),
          children: [
            _tableHeader('Marcador'),
            _tableHeader(
              'Valor A (${recordA != null ? DateFormat('dd/MM', 'es').format(recordA!.date) : 'N/A'})',
            ),
            _tableHeader(
              'Valor B (${recordB != null ? DateFormat('dd/MM', 'es').format(recordB!.date) : 'N/A'})',
            ),
          ],
        ),
        ..._tableStructure.map((item) {
          final isTitle = item['key'] == '';

          if (isTitle) {
            return TableRow(
              decoration: BoxDecoration(color: kCardColor.withAlpha(200)),
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 8.0,
                    ),
                    child: Text(
                      item['title']!,
                      style: const TextStyle(
                        color: kAccentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TableCell(child: Container()),
                TableCell(child: Container()),
              ],
            );
          }

          final key = item['key']!;
          final valueA = _getValue(recordA, key);
          final valueB = _getValue(recordB, key);

          return TableRow(
            children: [
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 8.0,
                  ),
                  child: Text(
                    item['title']!,
                    style: const TextStyle(color: kTextColor),
                  ),
                ),
              ),
              TableCell(child: _buildComparisonCell(valueA, valueB, key)),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 8.0,
                  ),
                  child: Text(
                    valueB != null ? valueB.toStringAsFixed(1) : 'N/A',
                    style: const TextStyle(color: kTextColorSecondary),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  TableCell _tableHeader(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
