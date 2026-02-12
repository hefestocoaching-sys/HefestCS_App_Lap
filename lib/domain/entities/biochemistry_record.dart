import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';

class BioChemistryRecord extends Equatable {
  final DateTime date;

  // --- 1. Glucosa ---
  final double? glucose;
  final double? hba1c;
  final double? fastingInsulin;

  // --- 2. Lípidos ---
  final double? cholesterolTotal;
  final double? ldl;
  final double? hdl;
  final double? cholesterolNoHDL;
  final double? triglycerides;
  final double? apoA1;
  final double? apoB;

  // --- 3. Función Hepática ---
  final double? ast;
  final double? alt;
  final double? ggt;
  final double? alkalinePhosphatase;
  final double? bilirubinTotal;
  final double? albumin;
  final double? totalProteins;

  // --- 4. Renal / Electrolitos ---
  final double? creatinine;
  final double? ureaBUN;
  final double? bunCreatinineRatio;
  final double? egfr;
  final double? sodium;
  final double? potassium;
  final double? chloride;
  final double? bicarbonate;
  final double? serumOsmolality;
  final double? urineDensity;
  final double? uricAcid;

  // --- 5. Hematología / Hierro ---
  final double? hemoglobin;
  final double? hematocrit;
  final double? leukocytes;
  final double? platelets;
  final double? mcv;
  final double? mch;
  final double? rdw;
  final double? ferritin;
  final double? serumIron;
  final double? transferrinTIBC;
  final double? transferrinSaturation;
  final double? uibc;

  // --- 6. Vitaminas y Minerales ---
  final double? vitaminD;
  final double? vitaminB12;
  final double? vitaminB6;
  final double? vitaminB1;
  final double? vitaminE;
  final double? vitaminA;
  final double? vitaminK;
  final double? magnesium;
  final double? zinc;
  final double? copper;
  final double? selenium;
  final double? folate;

  // --- 7. Inflamación / Cardiovascular ---
  final double? pcrUs;
  final double? homocysteine;
  final double? fibrinogen;

  // --- 8. Tiroides ---
  final double? tsh;
  final double? t4Total;
  final double? t3Total;
  final double? t4Free;
  final double? t3Free;

  // --- 9. Hormonal ---
  final double? testosteroneTotal;
  final double? testosteroneFree;
  final double? shbg;
  final double? estradiol;
  final double? progesteroneLuteal;
  final double? lh;
  final double? fsh;
  final double? prolactin;
  final double? dheaS;
  final double? morningCortisol;

  // --- 10. Entrenamiento ---
  final double? ck;
  final double? ldh;
  final double? restingLactate;

  // Getter calculado (ratio)
  double? get apoBRatio => (apoB != null && apoA1 != null && apoA1 != 0) ? (apoB! / apoA1!) : null;

  const BioChemistryRecord({
    required this.date,
    this.glucose, this.hba1c, this.fastingInsulin,
    this.cholesterolTotal, this.ldl, this.hdl, this.cholesterolNoHDL, this.triglycerides, this.apoA1, this.apoB,
    this.ast, this.alt, this.ggt, this.alkalinePhosphatase, this.bilirubinTotal, this.albumin, this.totalProteins,
    this.creatinine, this.ureaBUN, this.bunCreatinineRatio, this.egfr, this.sodium, this.potassium, this.chloride, this.bicarbonate, this.serumOsmolality, this.urineDensity, this.uricAcid,
    this.hemoglobin, this.hematocrit, this.leukocytes, this.platelets, this.mcv, this.mch, this.rdw,
    this.ferritin, this.serumIron, this.transferrinTIBC, this.transferrinSaturation, this.uibc,
    this.vitaminD, this.vitaminB12, this.vitaminB6, this.vitaminB1, this.vitaminE, this.vitaminA, this.vitaminK,
    this.magnesium, this.zinc, this.copper, this.selenium, this.folate,
    this.pcrUs, this.homocysteine, this.fibrinogen,
    this.tsh, this.t4Total, this.t3Total, this.t4Free, this.t3Free,
    this.testosteroneTotal, this.testosteroneFree, this.shbg, this.estradiol, this.progesteroneLuteal, this.lh, this.fsh, this.prolactin, this.dheaS, this.morningCortisol,
    this.ck, this.ldh, this.restingLactate,
  });

  // --- SERIALIZACIÓN JSON (Esto es lo que faltaba) ---

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'glucose': glucose, 'hba1c': hba1c, 'fastingInsulin': fastingInsulin,
      'cholesterolTotal': cholesterolTotal, 'ldl': ldl, 'hdl': hdl, 'cholesterolNoHDL': cholesterolNoHDL, 'triglycerides': triglycerides, 'apoA1': apoA1, 'apoB': apoB,
      'ast': ast, 'alt': alt, 'ggt': ggt, 'alkalinePhosphatase': alkalinePhosphatase, 'bilirubinTotal': bilirubinTotal, 'albumin': albumin, 'totalProteins': totalProteins,
      'creatinine': creatinine, 'ureaBUN': ureaBUN, 'bunCreatinineRatio': bunCreatinineRatio, 'egfr': egfr, 'sodium': sodium, 'potassium': potassium, 'chloride': chloride, 'bicarbonate': bicarbonate, 'serumOsmolality': serumOsmolality, 'urineDensity': urineDensity, 'uricAcid': uricAcid,
      'hemoglobin': hemoglobin, 'hematocrit': hematocrit, 'leukocytes': leukocytes, 'platelets': platelets, 'mcv': mcv, 'mch': mch, 'rdw': rdw,
      'ferritin': ferritin, 'serumIron': serumIron, 'transferrinTIBC': transferrinTIBC, 'transferrinSaturation': transferrinSaturation, 'uibc': uibc,
      'vitaminD': vitaminD, 'vitaminB12': vitaminB12, 'vitaminB6': vitaminB6, 'vitaminB1': vitaminB1, 'vitaminE': vitaminE, 'vitaminA': vitaminA, 'vitaminK': vitaminK,
      'magnesium': magnesium, 'zinc': zinc, 'copper': copper, 'selenium': selenium, 'folate': folate,
      'pcrUs': pcrUs, 'homocysteine': homocysteine, 'fibrinogen': fibrinogen,
      'tsh': tsh, 't4Total': t4Total, 't3Total': t3Total, 't4Free': t4Free, 't3Free': t3Free,
      'testosteroneTotal': testosteroneTotal, 'testosteroneFree': testosteroneFree, 'shbg': shbg, 'estradiol': estradiol, 'progesteroneLuteal': progesteroneLuteal, 'lh': lh, 'fsh': fsh, 'prolactin': prolactin, 'dheaS': dheaS, 'morningCortisol': morningCortisol,
      'ck': ck, 'ldh': ldh, 'restingLactate': restingLactate,
    };
  }

  factory BioChemistryRecord.fromJson(Map<String, dynamic> json) {
    return BioChemistryRecord(
      date: parseDateTimeOrEpoch(json['date']?.toString()),
      glucose: (json['glucose'] as num?)?.toDouble(),
      hba1c: (json['hba1c'] as num?)?.toDouble(),
      fastingInsulin: (json['fastingInsulin'] as num?)?.toDouble(),
      cholesterolTotal: (json['cholesterolTotal'] as num?)?.toDouble(),
      ldl: (json['ldl'] as num?)?.toDouble(),
      hdl: (json['hdl'] as num?)?.toDouble(),
      cholesterolNoHDL: (json['cholesterolNoHDL'] as num?)?.toDouble(),
      triglycerides: (json['triglycerides'] as num?)?.toDouble(),
      apoA1: (json['apoA1'] as num?)?.toDouble(),
      apoB: (json['apoB'] as num?)?.toDouble(),
      ast: (json['ast'] as num?)?.toDouble(),
      alt: (json['alt'] as num?)?.toDouble(),
      ggt: (json['ggt'] as num?)?.toDouble(),
      alkalinePhosphatase: (json['alkalinePhosphatase'] as num?)?.toDouble(),
      bilirubinTotal: (json['bilirubinTotal'] as num?)?.toDouble(),
      albumin: (json['albumin'] as num?)?.toDouble(),
      totalProteins: (json['totalProteins'] as num?)?.toDouble(),
      creatinine: (json['creatinine'] as num?)?.toDouble(),
      ureaBUN: (json['ureaBUN'] as num?)?.toDouble(),
      bunCreatinineRatio: (json['bunCreatinineRatio'] as num?)?.toDouble(),
      egfr: (json['egfr'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      potassium: (json['potassium'] as num?)?.toDouble(),
      chloride: (json['chloride'] as num?)?.toDouble(),
      bicarbonate: (json['bicarbonate'] as num?)?.toDouble(),
      serumOsmolality: (json['serumOsmolality'] as num?)?.toDouble(),
      urineDensity: (json['urineDensity'] as num?)?.toDouble(),
      uricAcid: (json['uricAcid'] as num?)?.toDouble(),
      hemoglobin: (json['hemoglobin'] as num?)?.toDouble(),
      hematocrit: (json['hematocrit'] as num?)?.toDouble(),
      leukocytes: (json['leukocytes'] as num?)?.toDouble(),
      platelets: (json['platelets'] as num?)?.toDouble(),
      mcv: (json['mcv'] as num?)?.toDouble(),
      mch: (json['mch'] as num?)?.toDouble(),
      rdw: (json['rdw'] as num?)?.toDouble(),
      ferritin: (json['ferritin'] as num?)?.toDouble(),
      serumIron: (json['serumIron'] as num?)?.toDouble(),
      transferrinTIBC: (json['transferrinTIBC'] as num?)?.toDouble(),
      transferrinSaturation: (json['transferrinSaturation'] as num?)?.toDouble(),
      uibc: (json['uibc'] as num?)?.toDouble(),
      vitaminD: (json['vitaminD'] as num?)?.toDouble(),
      vitaminB12: (json['vitaminB12'] as num?)?.toDouble(),
      vitaminB6: (json['vitaminB6'] as num?)?.toDouble(),
      vitaminB1: (json['vitaminB1'] as num?)?.toDouble(),
      vitaminE: (json['vitaminE'] as num?)?.toDouble(),
      vitaminA: (json['vitaminA'] as num?)?.toDouble(),
      vitaminK: (json['vitaminK'] as num?)?.toDouble(),
      magnesium: (json['magnesium'] as num?)?.toDouble(),
      zinc: (json['zinc'] as num?)?.toDouble(),
      copper: (json['copper'] as num?)?.toDouble(),
      selenium: (json['selenium'] as num?)?.toDouble(),
      folate: (json['folate'] as num?)?.toDouble(),
      pcrUs: (json['pcrUs'] as num?)?.toDouble(),
      homocysteine: (json['homocysteine'] as num?)?.toDouble(),
      fibrinogen: (json['fibrinogen'] as num?)?.toDouble(),
      tsh: (json['tsh'] as num?)?.toDouble(),
      t4Total: (json['t4Total'] as num?)?.toDouble(),
      t3Total: (json['t3Total'] as num?)?.toDouble(),
      t4Free: (json['t4Free'] as num?)?.toDouble(),
      t3Free: (json['t3Free'] as num?)?.toDouble(),
      testosteroneTotal: (json['testosteroneTotal'] as num?)?.toDouble(),
      testosteroneFree: (json['testosteroneFree'] as num?)?.toDouble(),
      shbg: (json['shbg'] as num?)?.toDouble(),
      estradiol: (json['estradiol'] as num?)?.toDouble(),
      progesteroneLuteal: (json['progesteroneLuteal'] as num?)?.toDouble(),
      lh: (json['lh'] as num?)?.toDouble(),
      fsh: (json['fsh'] as num?)?.toDouble(),
      prolactin: (json['prolactin'] as num?)?.toDouble(),
      dheaS: (json['dheaS'] as num?)?.toDouble(),
      morningCortisol: (json['morningCortisol'] as num?)?.toDouble(),
      ck: (json['ck'] as num?)?.toDouble(),
      ldh: (json['ldh'] as num?)?.toDouble(),
      restingLactate: (json['restingLactate'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [date, glucose, hba1c, cholesterolTotal, ldl, hdl, triglycerides];
}