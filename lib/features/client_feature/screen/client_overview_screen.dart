import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/services/anthropometry_analyzer.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

class ClientOverviewScreen extends ConsumerWidget {
  const ClientOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientsProvider).value?.activeClient;

    if (client == null) {
      return const Center(
        child: Text(
          'No hay cliente activo',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: _ClientOverviewContent(client: client),
      ),
    );
  }
}

class _ClientOverviewContent extends StatefulWidget {
  final Client client;

  const _ClientOverviewContent({required this.client});

  @override
  State<_ClientOverviewContent> createState() => _ClientOverviewContentState();
}

class _ClientOverviewContentState extends State<_ClientOverviewContent> {
  String _selectedMetric = 'Peso';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExecutiveSummaryBlock(context),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildWeeklyCaloriesGraphBlock(context)),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildMeasuresEvolutionBlock(context)),
            ],
          ),
          if (_shouldShowAdherenceBlock()) ...[
            const SizedBox(height: 24),
            _buildAdherenceBlock(context),
          ],
        ],
      ),
    );
  }

  Widget _buildExecutiveSummaryBlock(BuildContext context) {
    final planStart = widget.client.nutrition.planStartDate;
    final planEnd = widget.client.nutrition.planEndDate;
    final now = DateTime.now();

    final latestRecord = widget.client.latestAnthropometryRecord;
    final previousRecord = _getPreviousAnthropometryRecord();

    final analyzer = AnthropometryAnalyzer();
    final analysis = latestRecord != null
        ? analyzer.analyze(
            record: latestRecord,
            age: widget.client.profile.age,
            gender: widget.client.profile.gender?.label ?? 'Hombre',
          )
        : null;
    final previousAnalysis = previousRecord != null
        ? analyzer.analyze(
            record: previousRecord,
            age: widget.client.profile.age,
            gender: widget.client.profile.gender?.label ?? 'Hombre',
          )
        : null;

    final currentWeight = latestRecord?.weightKg;
    final previousWeight = previousRecord?.weightKg;
    final weightDelta = (currentWeight != null && previousWeight != null)
        ? currentWeight - previousWeight
        : null;

    final currentFatPerc = analysis?.bodyFatPercentage;
    final previousFatPerc = previousAnalysis?.bodyFatPercentage;
    final fatDelta = (currentFatPerc != null && previousFatPerc != null)
        ? currentFatPerc - previousFatPerc
        : null;

    final currentWaist = latestRecord?.waistCircNarrowest;
    final previousWaist = previousRecord?.waistCircNarrowest;
    final waistDelta = (currentWaist != null && previousWaist != null)
        ? currentWaist - previousWaist
        : null;
    final leanDelta = _computeLeanDelta(latestRecord, previousRecord, analyzer);

    final energyRecords = readNutritionRecordList(
      widget.client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
    );
    final latestEnergy = energyRecords.isNotEmpty ? energyRecords.last : null;
    final Map<String, int> dailyKcal =
        parseDailyKcalMap(latestEnergy?['dailyKcal']) ?? {};
    final Map<String, double> dailyGet = {};
    final rawGet = latestEnergy?['dailyGet'];
    if (rawGet is Map) {
      rawGet.forEach((key, value) {
        final v = (value as num?)?.toDouble();
        if (v != null) dailyGet[key.toString()] = v;
      });
    }

    int deficitDays = 0;
    int surplusDays = 0;
    int recordedDays = 0;
    dailyKcal.forEach((day, kcal) {
      final get = dailyGet[day];
      if (get != null) {
        recordedDays += 1;
        if (kcal < get) {
          deficitDays += 1;
        } else if (kcal > get) {
          surplusDays += 1;
        }
      }
    });

    String caloricText;
    if (recordedDays == 0) {
      caloricText = 'Sin datos recientes de calorías';
    } else if (deficitDays >= 4) {
      caloricText = 'Déficit consistente';
    } else if (surplusDays >= 4) {
      caloricText = 'Superávit frecuente';
    } else {
      caloricText = 'Patrón calórico mixto';
    }

    String bodyText;
    final improvements = <bool>[
      weightDelta != null ? weightDelta < -0.2 : false,
      fatDelta != null ? fatDelta < -0.3 : false,
      waistDelta != null ? waistDelta < -0.5 : false,
      leanDelta != null ? leanDelta > 0.2 : false,
    ];
    final declines = <bool>[
      weightDelta != null ? weightDelta > 0.3 : false,
      fatDelta != null ? fatDelta > 0.3 : false,
      waistDelta != null ? waistDelta > 0.5 : false,
      leanDelta != null ? leanDelta < -0.2 : false,
    ];

    final hasImprovement = improvements.any((e) => e);
    final hasDecline = declines.any((e) => e);

    if (latestRecord == null || previousRecord == null) {
      bodyText = 'Aún sin variación reciente';
    } else if (hasImprovement && !hasDecline) {
      bodyText = 'Medidas mejorando';
    } else if (hasDecline && !hasImprovement) {
      bodyText = 'Medidas empeorando';
    } else {
      bodyText = 'Medidas estables';
    }

    String planWeekText;
    if (planStart != null) {
      final weeksSinceStart =
          (now.difference(planStart).inDays / 7).floor() + 1;
      final totalWeeks = planEnd != null
          ? (planEnd.difference(planStart).inDays / 7).ceil()
          : null;
      if (weeksSinceStart <= 0) {
        planWeekText = 'Plan aún no inicia';
      } else if (totalWeeks != null && totalWeeks > 0) {
        final cappedWeek = weeksSinceStart > totalWeeks
            ? totalWeeks
            : weeksSinceStart;
        planWeekText = 'Semana $cappedWeek de $totalWeeks';
      } else {
        planWeekText = 'Semana $weeksSinceStart';
      }
    } else {
      planWeekText = 'Plan sin fecha de inicio';
    }

    final adherenceText = _adherenceSummaryText();

    // Obtener objetivo del plan desde configuración de macros
    String? planGoal;
    final weeklyMacros = widget.client.nutrition.weeklyMacroSettings;
    if (weeklyMacros != null && weeklyMacros.isNotEmpty) {
      planGoal = weeklyMacros.values.first.goalType;
    }

    // Determinar si el patrón calórico alinea con el objetivo
    bool isPatternAlignedWithGoal = false;
    if (planGoal != null) {
      if (planGoal == 'Pérdida de grasa' &&
          caloricText == 'Déficit consistente') {
        isPatternAlignedWithGoal = true;
      } else if (planGoal == 'Hipertrofia' &&
          caloricText == 'Superávit frecuente') {
        isPatternAlignedWithGoal = true;
      } else if (planGoal == 'Mantenimiento' &&
          caloricText == 'Patrón calórico mixto') {
        isPatternAlignedWithGoal = true;
      }
    }

    String planStatusLabel = 'Plan estancado';
    Color statusColor = Colors.orange.shade600;
    if (recordedDays == 0 && latestRecord == null) {
      planStatusLabel = 'Plan estancado';
      statusColor = Colors.grey;
    } else if (isPatternAlignedWithGoal &&
        bodyText == 'Medidas mejorando' &&
        (adherenceText == 'Adherencia adecuada' ||
            adherenceText == 'Adherencia excelente')) {
      // Plan en ejecución correcta: patrón alineado + cambios favorables + adherencia
      planStatusLabel = 'Plan funcionando correctamente';
      statusColor = Colors.green.shade700;
    } else if (!isPatternAlignedWithGoal && bodyText == 'Medidas empeorando') {
      // Riesgo real: patrón NO alineado con objetivo + cambios desfavorables
      planStatusLabel = 'Plan en riesgo';
      statusColor = Colors.orange.shade700;
    } else if (!isPatternAlignedWithGoal &&
        (adherenceText == 'Adherencia pobre' ||
            adherenceText == 'Adherencia muy pobre')) {
      // Riesgo: patrón desalineado + mala adherencia
      planStatusLabel = 'Plan en riesgo';
      statusColor = Colors.orange.shade700;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardBoxDecoration().copyWith(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withAlpha(120), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha(35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline,
                          size: 42,
                          color: kTextColorSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.client.profile.fullName,
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            planStatusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _planStatusPill(planWeekText, Icons.schedule_outlined),
                    _planStatusPill(
                      caloricText,
                      Icons.local_fire_department_outlined,
                    ),
                    _planStatusPill(bodyText, Icons.self_improvement_outlined),
                    if (adherenceText.isNotEmpty)
                      _planStatusPill(
                        adherenceText,
                        Icons.assignment_turned_in_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Observaciones:',
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _executiveBullet('• $caloricText'),
                _executiveBullet('• $bodyText'),
                _executiveBullet(
                  adherenceText.isNotEmpty
                      ? '• $adherenceText'
                      : '• Adherencia no evaluada',
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 0.9 * MediaQuery.of(context).size.width,
                    height: 1,
                    color: kAppBarColor.withAlpha(90),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _adminItem(
                        label: 'Inicio de plan',
                        value: planStart != null
                            ? DateFormat('dd/MM/yyyy').format(planStart)
                            : '—',
                      ),
                    ),
                    Expanded(
                      child: _adminItem(
                        label: 'Término de plan',
                        value: planEnd != null
                            ? DateFormat('dd/MM/yyyy').format(planEnd)
                            : '—',
                      ),
                    ),
                    Expanded(
                      child: _adminItem(
                        label: 'Código de acceso',
                        value: widget.client.invitationCode ?? '—',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    label: '% Grasa corporal',
                    value: currentFatPerc,
                    valueKg: analysis?.fatMassKg,
                    delta: fatDelta,
                    isPositiveGood: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kpiCard(
                    label: '% Masa muscular',
                    value: analysis?.muscleMassPercent,
                    valueKg: analysis?.muscleMassKg,
                    delta: _computeMusclePercDelta(
                      latestRecord,
                      previousRecord,
                      analyzer,
                    ),
                    isPositiveGood: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCaloriesGraphBlock(BuildContext context) {
    final energyRecords = readNutritionRecordList(
      widget.client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
    );
    final latestEnergy = energyRecords.isNotEmpty ? energyRecords.last : null;
    final Map<String, int> dailyKcal =
        parseDailyKcalMap(latestEnergy?['dailyKcal']) ?? {};
    final Map<String, double> dailyGet = {};
    final rawGet = latestEnergy?['dailyGet'];
    if (rawGet is Map) {
      rawGet.forEach((key, value) {
        final v = (value as num?)?.toDouble();
        if (v != null) dailyGet[key.toString()] = v;
      });
    }

    final days = <String, String>{
      'Lunes': 'L',
      'Martes': 'M',
      'Miércoles': 'X',
      'Jueves': 'J',
      'Viernes': 'V',
      'Sábado': 'S',
      'Domingo': 'D',
    };

    int deficitDays = 0;
    int surplusDays = 0;
    int recordedDays = 0;

    final maxKcal = dailyKcal.values.isEmpty
        ? 2500
        : dailyKcal.values.reduce((a, b) => a > b ? a : b).toDouble();

    final barWidgets = days.entries.map((entry) {
      final day = entry.key;
      final shortLabel = entry.value;
      final kcal = dailyKcal[day];
      final get = dailyGet[day];

      Color barColor = kTextColorSecondary;
      if (kcal != null && get != null) {
        recordedDays += 1;
        if (kcal < get) {
          barColor = Colors.green.shade700;
          deficitDays += 1;
        } else if (kcal > get) {
          barColor = Colors.orange.shade700;
          surplusDays += 1;
        }
      }

      final barHeight = kcal != null
          ? (kcal / maxKcal).clamp(0.05, 1.0) * 140
          : 0.05 * 140;

      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              kcal != null ? '$kcal' : '—',
              style: const TextStyle(
                color: kTextColorSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 140,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 18,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shortLabel,
              style: const TextStyle(
                color: kTextColorSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }).toList();

    String weeklyConclusion;
    if (recordedDays == 0) {
      weeklyConclusion = 'Sin registros calóricos recientes';
    } else {
      // Mostrar el estado predominante primero
      if (surplusDays > deficitDays) {
        weeklyConclusion = 'Superávit sostenido $surplusDays de 7 días';
        if (deficitDays > 0) {
          weeklyConclusion += ' | Déficit $deficitDays días';
        }
      } else if (deficitDays > surplusDays) {
        weeklyConclusion = 'Déficit sostenido $deficitDays de 7 días';
        if (surplusDays > 0) {
          weeklyConclusion += ' | Superávit $surplusDays días';
        }
      } else {
        // Equilibrio
        weeklyConclusion =
            'Equilibrio calórico | Déficit: $deficitDays días | Superávit: $surplusDays días';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen semanal de calorías',
            style: TextStyle(
              color: kTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: barWidgets,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: kAppBarColor),
          const SizedBox(height: 12),
          Text(
            weeklyConclusion,
            style: const TextStyle(
              color: kTextColorSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowAdherenceBlock() {
    final logsRaw =
        widget.client.nutrition.extra[NutritionExtraKeys.adherenceLogRecords];
    final logs = readNutritionRecordList(logsRaw);
    if (logs.isEmpty) return false;

    int plannedCount = 0;
    for (final log in logs) {
      final hasPlan = log['planned'] == true || log['hasPlan'] == true;
      if (hasPlan) plannedCount += 1;
    }

    return plannedCount > 0;
  }

  Widget _buildAdherenceBlock(BuildContext context) {
    final logsRaw =
        widget.client.nutrition.extra[NutritionExtraKeys.adherenceLogRecords];
    final logs = readNutritionRecordList(logsRaw);

    int completedDays = 0;
    int plannedDays = 0;
    for (final log in logs) {
      final hasPlan = log['planned'] == true || log['hasPlan'] == true;
      final done = log['completed'] == true || log['menuCompleted'] == true;
      if (hasPlan) plannedDays += 1;
      if (hasPlan && done) completedDays += 1;
    }

    final adherence = plannedDays > 0 ? (completedDays / plannedDays) : 0.0;
    final adherencePercentage = (adherence * 100).toStringAsFixed(0);
    final status = _adherenceStatusText(adherence);

    Color statusColor;
    if (adherence >= 0.85) {
      statusColor = Colors.green.shade700;
    } else if (adherence >= 0.7) {
      statusColor = Colors.blue.shade600;
    } else if (adherence >= 0.5) {
      statusColor = Colors.orange.shade600;
    } else {
      statusColor = Colors.red.shade600;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adherencia',
            style: TextStyle(
              color: kTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  '$adherencePercentage%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(32),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$completedDays de $plannedDays días completados',
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planStatusPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAppBarColor.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kPrimaryColor.withAlpha(180)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _executiveBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: kTextColorSecondary,
          fontSize: 13,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String label,
    required double? value,
    double? valueKg,
    required double? delta,
    required bool isPositiveGood,
  }) {
    Color? deltaColor;
    IconData? deltaIcon;
    String? deltaText;

    if (delta != null && delta.abs() >= 0.01) {
      final isPositiveDelta = delta > 0;
      final isGood = isPositiveDelta == isPositiveGood;
      deltaColor = isGood ? Colors.green.shade700 : Colors.orange.shade700;
      deltaIcon = isPositiveDelta ? Icons.arrow_upward : Icons.arrow_downward;
      deltaText = '${isPositiveDelta ? '+' : ''}${delta.toStringAsFixed(1)}%';
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.all(14),
      decoration: _cardBoxDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextColorSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value != null ? value.toStringAsFixed(1) : '—',
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '%',
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (valueKg != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${valueKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (deltaText != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(deltaIcon, size: 16, color: deltaColor),
                const SizedBox(width: 4),
                Text(
                  deltaText,
                  style: TextStyle(
                    color: deltaColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _adminItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextColorSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: kTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _adherenceSummaryText() {
    final logsRaw =
        widget.client.nutrition.extra[NutritionExtraKeys.adherenceLogRecords];
    final logs = readNutritionRecordList(logsRaw);
    if (logs.isEmpty) return '';

    int completed = 0;
    int planned = 0;
    for (final log in logs) {
      final hasPlan = log['planned'] == true || log['hasPlan'] == true;
      final done = log['completed'] == true || log['menuCompleted'] == true;
      if (hasPlan) planned += 1;
      if (hasPlan && done) completed += 1;
    }

    if (planned == 0) return '';

    final adherence = completed / planned;
    final status = _adherenceStatusText(adherence);

    switch (status) {
      case 'Excelente':
        return 'Adherencia excelente';
      case 'Buena':
        return 'Adherencia adecuada';
      case 'Moderada':
        return 'Adherencia moderada';
      case 'Baja':
        return 'Adherencia baja';
      default:
        return '';
    }
  }

  double? _computeLeanDelta(
    dynamic latestRecord,
    dynamic previousRecord,
    AnthropometryAnalyzer analyzer,
  ) {
    if (latestRecord == null || previousRecord == null) return null;
    final current = analyzer
        .analyze(
          record: latestRecord,
          age: widget.client.profile.age,
          gender: widget.client.profile.gender?.label ?? 'Hombre',
        )
        .leanMassKg;
    final previous = analyzer
        .analyze(
          record: previousRecord,
          age: widget.client.profile.age,
          gender: widget.client.profile.gender?.label ?? 'Hombre',
        )
        .leanMassKg;
    if (current == null || previous == null) return null;
    return current - previous;
  }

  double? _computeMusclePercDelta(
    dynamic latestRecord,
    dynamic previousRecord,
    AnthropometryAnalyzer analyzer,
  ) {
    if (latestRecord == null || previousRecord == null) return null;
    final current = analyzer
        .analyze(
          record: latestRecord,
          age: widget.client.profile.age,
          gender: widget.client.profile.gender?.label ?? 'Hombre',
        )
        .muscleMassPercent;
    final previous = analyzer
        .analyze(
          record: previousRecord,
          age: widget.client.profile.age,
          gender: widget.client.profile.gender?.label ?? 'Hombre',
        )
        .muscleMassPercent;
    if (current == null || previous == null) return null;
    return current - previous;
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: kCardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kAppBarColor.withAlpha(60), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  String _adherenceStatusText(double? adherence) {
    if (adherence == null) return '—';
    if (adherence >= 0.85) return 'Excelente';
    if (adherence >= 0.7) return 'Buena';
    if (adherence >= 0.5) return 'Moderada';
    return 'Baja';
  }

  dynamic _getPreviousAnthropometryRecord() {
    final records = widget.client.anthropometry;
    if (records.length < 2) return null;
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.length > 1 ? sorted[1] : null;
  }

  Widget _buildMeasuresEvolutionBlock(BuildContext context) {
    final records = widget.client.anthropometry;
    final sortedRecords = [...records]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedRecords.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardBoxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evolución de medidas',
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _buildMetricDropdown(),
              ],
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Sin suficientes datos para mostrar evolución',
                style: TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    final analyzer = AnthropometryAnalyzer();
    final dataPoints = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      double? value;

      switch (_selectedMetric) {
        case 'Peso':
          value = record.weightKg;
          break;
        case '% Grasa corporal':
          final analysis = analyzer.analyze(
            record: record,
            age: widget.client.profile.age,
            gender: widget.client.profile.gender?.label ?? 'Hombre',
          );
          value = analysis.bodyFatPercentage;
          break;
        case '% Masa muscular':
          final analysis = analyzer.analyze(
            record: record,
            age: widget.client.profile.age,
            gender: widget.client.profile.gender?.label ?? 'Hombre',
          );
          value = analysis.muscleMassPercent;
          break;
        case 'Sumatoria de pliegues':
          double sum = 0.0;
          int count = 0;
          final folds = [
            record.tricipitalFold,
            record.subscapularFold,
            record.suprailiacFold,
            record.supraspinalFold,
            record.abdominalFold,
            record.thighFold,
            record.calfFold,
          ];
          for (final fold in folds) {
            if (fold != null) {
              sum += fold;
              count++;
            }
          }
          if (count > 0) {
            value = sum;
          }
          break;
      }

      if (value != null) {
        dataPoints.add(FlSpot(i.toDouble(), value));
        if (value < minY) minY = value;
        if (value > maxY) maxY = value;
      }
    }

    if (dataPoints.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardBoxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evolución de medidas',
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _buildMetricDropdown(),
              ],
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Sin suficientes datos para mostrar evolución',
                style: TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    final padding = (maxY - minY) * 0.1;
    final adjustedMinY = minY - padding;
    final adjustedMaxY = maxY + padding;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Evolución de medidas',
                style: TextStyle(
                  color: kTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _buildMetricDropdown(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: adjustedMinY,
                maxY: adjustedMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (adjustedMaxY - adjustedMinY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: kAppBarColor.withAlpha(40),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: (adjustedMaxY - adjustedMinY) / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: kTextColorSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedRecords.length) {
                          final date = sortedRecords[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(
                                color: kTextColorSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                      color: kAppBarColor.withAlpha(60),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: kAppBarColor.withAlpha(60),
                      width: 1,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: dataPoints,
                    isCurved: true,
                    color: kPrimaryColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: kPrimaryColor,
                          strokeWidth: 2,
                          strokeColor: kCardColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: kPrimaryColor.withAlpha(30),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => kAppBarColor,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < sortedRecords.length) {
                          final date = sortedRecords[index].date;
                          return LineTooltipItem(
                            '${DateFormat('dd/MM/yy').format(date)}\n${spot.y.toStringAsFixed(1)}',
                            const TextStyle(
                              color: kTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kAppBarColor.withAlpha(60), width: 1),
      ),
      child: DropdownButton<String>(
        value: _selectedMetric,
        isDense: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down, color: kPrimaryColor, size: 20),
        style: const TextStyle(
          color: kTextColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        dropdownColor: kCardColor,
        items: const [
          DropdownMenuItem(value: 'Peso', child: Text('Peso')),
          DropdownMenuItem(
            value: '% Grasa corporal',
            child: Text('% Grasa corporal'),
          ),
          DropdownMenuItem(
            value: '% Masa muscular',
            child: Text('% Masa muscular'),
          ),
          DropdownMenuItem(
            value: 'Sumatoria de pliegues',
            child: Text('Sumatoria de pliegues'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedMetric = value;
            });
          }
        },
      ),
    );
  }
}
