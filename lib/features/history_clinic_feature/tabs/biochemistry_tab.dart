import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/widgets/clinic_flat_section.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/widgets/shared_form_widgets.dart';
import 'package:hcs_app_lap/utils/widgets/analyzed_text_field.dart';
import 'package:hcs_app_lap/domain/entities/biochemistry_record.dart';
import 'package:hcs_app_lap/utils/record_helpers.dart';

class BiochemistryTab extends ConsumerStatefulWidget {
  final Client client;
  final Function(Client) onClientUpdated;

  const BiochemistryTab({
    super.key,
    required this.client,
    required this.onClientUpdated,
  });

  @override
  ConsumerState<BiochemistryTab> createState() => _BiochemistryTabState();
}

class _BiochemistryTabState extends ConsumerState<BiochemistryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {};

  final List<String> _allKeys = [
    'glucose',
    'hba1c',
    'fastingInsulin',
    'cholesterolTotal',
    'ldl',
    'hdl',
    'cholesterolNoHDL',
    'triglycerides',
    'apoA1',
    'apoB',
    'ast',
    'alt',
    'ggt',
    'alkalinePhosphatase',
    'bilirubinTotal',
    'albumin',
    'totalProteins',
    'creatinine',
    'ureaBUN',
    'bunCreatinineRatio',
    'egfr',
    'sodium',
    'potassium',
    'chloride',
    'bicarbonate',
    'serumOsmolality',
    'urineDensity',
    'uricAcid',
    'hemoglobin',
    'hematocrit',
    'leukocytes',
    'platelets',
    'mcv',
    'mch',
    'rdw',
    'ferritin',
    'serumIron',
    'transferrinTIBC',
    'transferrinSaturation',
    'uibc',
    'vitaminD',
    'vitaminB12',
    'vitaminB6',
    'vitaminB1',
    'vitaminE',
    'vitaminA',
    'vitaminK',
    'magnesium',
    'zinc',
    'copper',
    'selenium',
    'folate',
    'pcrUs',
    'homocysteine',
    'fibrinogen',
    'tsh',
    't4Total',
    't3Total',
    't4Free',
    't3Free',
    'ck',
    'ldh',
    'restingLactate',
    'testosteroneTotal',
    'testosteroneFree',
    'shbg',
    'estradiol',
    'progesteroneLuteal',
    'lh',
    'fsh',
    'prolactin',
    'dheaS',
    'morningCortisol',
  ];

  @override
  void initState() {
    super.initState();
    for (var key in _allKeys) {
      _controllers[key] = TextEditingController();
    }
    _getCtrl('alp');
    _getCtrl('urea');
    _loadLatestRecord();
  }

  @override
  void didUpdateWidget(covariant BiochemistryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.client.id != oldWidget.client.id) {
      _clearFields();
      _loadLatestRecord();
    }
  }

  TextEditingController _getCtrl(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();
    }
    return _controllers[key]!;
  }

  void _loadLatestRecord() {
    final globalDate = ref.read(globalDateProvider);
    final record = widget.client.latestBiochemistryAtOrBefore(globalDate);
    if (record != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(record.date);
      void set(String key, double? val) =>
          _getCtrl(key).text = val?.toString() ?? '';

      set('glucose', record.glucose);
      set('hba1c', record.hba1c);
      set('fastingInsulin', record.fastingInsulin);
      set('cholesterolTotal', record.cholesterolTotal);
      set('ldl', record.ldl);
      set('hdl', record.hdl);
      set('triglycerides', record.triglycerides);
      set('apoA1', record.apoA1);
      set('apoB', record.apoB);
      set('ast', record.ast);
      set('alt', record.alt);
      set('ggt', record.ggt);
      set('alkalinePhosphatase', record.alkalinePhosphatase);
      set('alp', record.alkalinePhosphatase);
      set('bilirubinTotal', record.bilirubinTotal);
      set('albumin', record.albumin);
      set('totalProteins', record.totalProteins);
      set('creatinine', record.creatinine);
      set('ureaBUN', record.ureaBUN);
      set('urea', record.ureaBUN);
      set('bunCreatinineRatio', record.bunCreatinineRatio);
      set('egfr', record.egfr);
      set('sodium', record.sodium);
      set('potassium', record.potassium);
      set('chloride', record.chloride);
      set('bicarbonate', record.bicarbonate);
      set('uricAcid', record.uricAcid);
      set('hemoglobin', record.hemoglobin);
      set('hematocrit', record.hematocrit);
      set('leukocytes', record.leukocytes);
      set('platelets', record.platelets);
      set('mcv', record.mcv);
      set('mch', record.mch);
      set('rdw', record.rdw);
      set('ferritin', record.ferritin);
      set('serumIron', record.serumIron);
      set('transferrinTIBC', record.transferrinTIBC);
      set('transferrinSaturation', record.transferrinSaturation);
      set('uibc', record.uibc);
      set('vitaminD', record.vitaminD);
      set('vitaminB12', record.vitaminB12);
      set('folate', record.folate);
      set('magnesium', record.magnesium);
      set('zinc', record.zinc);
      set('copper', record.copper);
      set('selenium', record.selenium);
      set('pcrUs', record.pcrUs);
      set('homocysteine', record.homocysteine);
      set('fibrinogen', record.fibrinogen);
      set('tsh', record.tsh);
      set('t4Total', record.t4Total);
      set('t3Total', record.t3Total);
      set('t4Free', record.t4Free);
      set('t3Free', record.t3Free);
      set('testosteroneTotal', record.testosteroneTotal);
      set('testosteroneFree', record.testosteroneFree);
      set('shbg', record.shbg);
      set('estradiol', record.estradiol);
      set('progesteroneLuteal', record.progesteroneLuteal);
      set('lh', record.lh);
      set('fsh', record.fsh);
      set('prolactin', record.prolactin);
      set('dheaS', record.dheaS);
      set('morningCortisol', record.morningCortisol);
      set('ck', record.ck);
      set('ldh', record.ldh);
      set('restingLactate', record.restingLactate);
    } else {
      _clearFields();
    }
  }

  void _clearFields() {
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _controllers.forEach((_, controller) => controller.clear());
  }

  void _showErrorSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : kPrimaryColor,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now().add(const Duration(days: 1));
    final initialCandidate =
        DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final initialDate = initialCandidate.isBefore(firstDate)
        ? firstDate
        : (initialCandidate.isAfter(lastDate) ? lastDate : initialCandidate);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kPrimaryColor,
            onPrimary: kTextColor,
            surface: kCardColor,
            onSurface: kTextColor,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: kBackgroundColor),
        ),
        child: child!,
      ),
    );
    if (!context.mounted) return;
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveRecord() {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar('Por favor, corrige los errores.');
      return;
    }

    final date = DateTime.tryParse(_dateController.text);
    if (date == null) {
      _showErrorSnackbar('Fecha inválida.');
      return;
    }

    double? getVal(String key) {
      final text = _controllers[key]?.text.trim();
      if (text == null || text.isEmpty) return null;
      return double.tryParse(text);
    }

    final newRecord = BioChemistryRecord(
      date: date,
      glucose: getVal('glucose'),
      hba1c: getVal('hba1c'),
      fastingInsulin: getVal('fastingInsulin'),
      cholesterolTotal: getVal('cholesterolTotal'),
      ldl: getVal('ldl'),
      hdl: getVal('hdl'),
      cholesterolNoHDL: getVal('cholesterolNoHDL'),
      triglycerides: getVal('triglycerides'),
      apoA1: getVal('apoA1'),
      apoB: getVal('apoB'),
      ast: getVal('ast'),
      alt: getVal('alt'),
      ggt: getVal('ggt'),
      alkalinePhosphatase: getVal('alkalinePhosphatase') ?? getVal('alp'),
      bilirubinTotal: getVal('bilirubinTotal'),
      albumin: getVal('albumin'),
      totalProteins: getVal('totalProteins'),
      creatinine: getVal('creatinine'),
      ureaBUN: getVal('ureaBUN') ?? getVal('urea'),
      bunCreatinineRatio: getVal('bunCreatinineRatio'),
      egfr: getVal('egfr'),
      sodium: getVal('sodium'),
      potassium: getVal('potassium'),
      chloride: getVal('chloride'),
      bicarbonate: getVal('bicarbonate'),
      serumOsmolality: getVal('serumOsmolality'),
      urineDensity: getVal('urineDensity'),
      uricAcid: getVal('uricAcid'),
      hemoglobin: getVal('hemoglobin'),
      hematocrit: getVal('hematocrit'),
      leukocytes: getVal('leukocytes'),
      platelets: getVal('platelets'),
      mcv: getVal('mcv'),
      mch: getVal('mch'),
      rdw: getVal('rdw'),
      ferritin: getVal('ferritin'),
      serumIron: getVal('serumIron'),
      transferrinTIBC: getVal('transferrinTIBC'),
      transferrinSaturation: getVal('transferrinSaturation'),
      uibc: getVal('uibc'),
      vitaminD: getVal('vitaminD'),
      vitaminB12: getVal('vitaminB12'),
      folate: getVal('folate'),
      magnesium: getVal('magnesium'),
      zinc: getVal('zinc'),
      copper: getVal('copper'),
      selenium: getVal('selenium'),
      pcrUs: getVal('pcrUs'),
      homocysteine: getVal('homocysteine'),
      fibrinogen: getVal('fibrinogen'),
      tsh: getVal('tsh'),
      t4Total: getVal('t4Total'),
      t3Total: getVal('t3Total'),
      t4Free: getVal('t4Free'),
      t3Free: getVal('t3Free'),
      testosteroneTotal: getVal('testosteroneTotal'),
      testosteroneFree: getVal('testosteroneFree'),
      shbg: getVal('shbg'),
      estradiol: getVal('estradiol'),
      progesteroneLuteal: getVal('progesteroneLuteal'),
      lh: getVal('lh'),
      fsh: getVal('fsh'),
      prolactin: getVal('prolactin'),
      dheaS: getVal('dheaS'),
      morningCortisol: getVal('morningCortisol'),
      ck: getVal('ck'),
      ldh: getVal('ldh'),
      restingLactate: getVal('restingLactate'),
    );

    final updatedRecords = upsertRecordByDate<BioChemistryRecord>(
      existingRecords: widget.client.biochemistry,
      newRecord: newRecord,
      dateExtractor: (record) => record.date,
    );

    widget.onClientUpdated(
      widget.client.copyWith(biochemistry: updatedRecords),
    );
    _showErrorSnackbar('Análisis guardado con éxito.', isError: false);
  }

  // --- UI PANELS (GLASS) ---

  Widget _buildGlassSection(String title, List<Widget> children, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.analytics_rounded,
              color: Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children.map((c) => SizedBox(width: w, child: c)).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 72) / 4;
        final gender = widget.client.gender;

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClinicFlatSection(
                  title: 'Fecha del Análisis',
                  icon: Icons.event,
                  accentColor: kPrimaryColor,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            controller: _dateController,
                            label: 'Fecha del Análisis',
                            readOnly: true,
                            onTap: () => _selectDate(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _saveRecord,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(140, 48),
                            backgroundColor: kPrimaryColor,
                            foregroundColor: kTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildGlassSection('Glucosa', [
                  AnalyzedTextField(
                    label: 'Glucosa Ayunas',
                    controller: _getCtrl('glucose'),
                    biomarkerKey: 'glucose',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'HbA1c (%)',
                    controller: _getCtrl('hba1c'),
                    biomarkerKey: 'hba1c',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Insulina',
                    controller: _getCtrl('fastingInsulin'),
                    biomarkerKey: 'fastingInsulin',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Perfil Lipídico', [
                  AnalyzedTextField(
                    label: 'Colesterol Total',
                    controller: _getCtrl('cholesterolTotal'),
                    biomarkerKey: 'cholesterolTotal',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'LDL',
                    controller: _getCtrl('ldl'),
                    biomarkerKey: 'ldl',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'HDL',
                    controller: _getCtrl('hdl'),
                    biomarkerKey: 'hdl',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Triglicéridos',
                    controller: _getCtrl('triglycerides'),
                    biomarkerKey: 'triglycerides',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'ApoB',
                    controller: _getCtrl('apoB'),
                    biomarkerKey: 'apoB',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'ApoA-1',
                    controller: _getCtrl('apoA1'),
                    biomarkerKey: 'apoA1',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Colesterol No-HDL',
                    controller: _getCtrl('cholesterolNoHDL'),
                    biomarkerKey: 'cholesterolNoHDL',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Función Hepática', [
                  AnalyzedTextField(
                    label: 'AST (TGO)',
                    controller: _getCtrl('ast'),
                    biomarkerKey: 'ast',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'ALT (TGP)',
                    controller: _getCtrl('alt'),
                    biomarkerKey: 'alt',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'GGT',
                    controller: _getCtrl('ggt'),
                    biomarkerKey: 'ggt',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Fosf. Alcalina',
                    controller: _getCtrl('alp'),
                    biomarkerKey: 'alkalinePhosphatase',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Bilirrubina Total',
                    controller: _getCtrl('bilirubinTotal'),
                    biomarkerKey: 'bilirubinTotal',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Albúmina',
                    controller: _getCtrl('albumin'),
                    biomarkerKey: 'albumin',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Proteínas Totales',
                    controller: _getCtrl('totalProteins'),
                    biomarkerKey: 'totalProteins',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Renal / Electrolitos', [
                  AnalyzedTextField(
                    label: 'Creatinina',
                    controller: _getCtrl('creatinine'),
                    biomarkerKey: 'creatinine',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Urea (BUN)',
                    controller: _getCtrl('urea'),
                    biomarkerKey: 'ureaBUN',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Ratio BUN/Creat.',
                    controller: _getCtrl('bunCreatinineRatio'),
                    biomarkerKey: 'bunCreatinineRatio',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'eGFR',
                    controller: _getCtrl('egfr'),
                    biomarkerKey: 'egfr',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Sodio',
                    controller: _getCtrl('sodium'),
                    biomarkerKey: 'sodium',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Potasio',
                    controller: _getCtrl('potassium'),
                    biomarkerKey: 'potassium',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Cloro',
                    controller: _getCtrl('chloride'),
                    biomarkerKey: 'chloride',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Bicarbonato',
                    controller: _getCtrl('bicarbonate'),
                    biomarkerKey: 'bicarbonate',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Osmolaridad',
                    controller: _getCtrl('serumOsmolality'),
                    biomarkerKey: 'serumOsmolality',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Densidad Urin.',
                    controller: _getCtrl('urineDensity'),
                    biomarkerKey: 'urineDensity',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Ácido Úrico',
                    controller: _getCtrl('uricAcid'),
                    biomarkerKey: 'uricAcid',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Hematología / Hierro', [
                  AnalyzedTextField(
                    label: 'Hemoglobina',
                    controller: _getCtrl('hemoglobin'),
                    biomarkerKey: 'hemoglobin',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Hematocrito',
                    controller: _getCtrl('hematocrit'),
                    biomarkerKey: 'hematocrit',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Leucocitos',
                    controller: _getCtrl('leukocytes'),
                    biomarkerKey: 'leukocytes',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Plaquetas',
                    controller: _getCtrl('platelets'),
                    biomarkerKey: 'platelets',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'VCM',
                    controller: _getCtrl('mcv'),
                    biomarkerKey: 'mcv',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'HCM',
                    controller: _getCtrl('mch'),
                    biomarkerKey: 'mch',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'RDW',
                    controller: _getCtrl('rdw'),
                    biomarkerKey: 'rdw',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Ferritina',
                    controller: _getCtrl('ferritin'),
                    biomarkerKey: 'ferritin',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Hierro Sérico',
                    controller: _getCtrl('serumIron'),
                    biomarkerKey: 'serumIron',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'TIBC',
                    controller: _getCtrl('transferrinTIBC'),
                    biomarkerKey: 'transferrinTIBC',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: '% Sat. Transf.',
                    controller: _getCtrl('transferrinSaturation'),
                    biomarkerKey: 'transferrinSaturation',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'UIBC',
                    controller: _getCtrl('uibc'),
                    biomarkerKey: 'uibc',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Vitaminas y Minerales', [
                  AnalyzedTextField(
                    label: 'Vit. D',
                    controller: _getCtrl('vitaminD'),
                    biomarkerKey: 'vitaminD',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Vit. B12',
                    controller: _getCtrl('vitaminB12'),
                    biomarkerKey: 'vitaminB12',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Folato',
                    controller: _getCtrl('folate'),
                    biomarkerKey: 'folate',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Magnesio',
                    controller: _getCtrl('magnesium'),
                    biomarkerKey: 'magnesium',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Zinc',
                    controller: _getCtrl('zinc'),
                    biomarkerKey: 'zinc',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Cobre',
                    controller: _getCtrl('copper'),
                    biomarkerKey: 'copper',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Selenio',
                    controller: _getCtrl('selenium'),
                    biomarkerKey: 'selenium',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Inflamación', [
                  AnalyzedTextField(
                    label: 'PCR-us',
                    controller: _getCtrl('pcrUs'),
                    biomarkerKey: 'pcrUs',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Homocisteína',
                    controller: _getCtrl('homocysteine'),
                    biomarkerKey: 'homocysteine',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Fibrinógeno',
                    controller: _getCtrl('fibrinogen'),
                    biomarkerKey: 'fibrinogen',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Tiroides', [
                  AnalyzedTextField(
                    label: 'TSH',
                    controller: _getCtrl('tsh'),
                    biomarkerKey: 'tsh',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'T4 Total',
                    controller: _getCtrl('t4Total'),
                    biomarkerKey: 't4Total',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'T3 Total',
                    controller: _getCtrl('t3Total'),
                    biomarkerKey: 't3Total',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'T4 Libre',
                    controller: _getCtrl('t4Free'),
                    biomarkerKey: 't4Free',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'T3 Libre',
                    controller: _getCtrl('t3Free'),
                    biomarkerKey: 't3Free',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Hormonal', [
                  if (gender == 'Masculino') ...[
                    AnalyzedTextField(
                      label: 'Testost. Total',
                      controller: _getCtrl('testosteroneTotal'),
                      biomarkerKey: 'testosteroneTotal',
                      gender: gender,
                    ),
                    AnalyzedTextField(
                      label: 'Testost. Libre',
                      controller: _getCtrl('testosteroneFree'),
                      biomarkerKey: 'testosteroneFree',
                      gender: gender,
                    ),
                  ],
                  if (gender == 'Femenino') ...[
                    AnalyzedTextField(
                      label: 'Estradiol',
                      controller: _getCtrl('estradiol'),
                      biomarkerKey: 'estradiol',
                      gender: gender,
                    ),
                    AnalyzedTextField(
                      label: 'Progesterona',
                      controller: _getCtrl('progesteroneLuteal'),
                      biomarkerKey: 'progesteroneLuteal',
                      gender: gender,
                    ),
                  ],
                  AnalyzedTextField(
                    label: 'SHBG',
                    controller: _getCtrl('shbg'),
                    biomarkerKey: 'shbg',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'LH',
                    controller: _getCtrl('lh'),
                    biomarkerKey: 'lh',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'FSH',
                    controller: _getCtrl('fsh'),
                    biomarkerKey: 'fsh',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Prolactina',
                    controller: _getCtrl('prolactin'),
                    biomarkerKey: 'prolactin',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'DHEA-S',
                    controller: _getCtrl('dheaS'),
                    biomarkerKey: 'dheaS',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Cortisol AM',
                    controller: _getCtrl('morningCortisol'),
                    biomarkerKey: 'morningCortisol',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 24),

                _buildGlassSection('Entrenamiento', [
                  AnalyzedTextField(
                    label: 'CK',
                    controller: _getCtrl('ck'),
                    biomarkerKey: 'ck',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'LDH',
                    controller: _getCtrl('ldh'),
                    biomarkerKey: 'ldh',
                    gender: gender,
                  ),
                  AnalyzedTextField(
                    label: 'Lactato Reposo',
                    controller: _getCtrl('restingLactate'),
                    biomarkerKey: 'restingLactate',
                    gender: gender,
                  ),
                ], itemWidth),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
