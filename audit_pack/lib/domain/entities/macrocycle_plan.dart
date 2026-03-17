import 'package:hcs_app_lap/domain/entities/week_plan.dart';

class MacrocyclePlan {
  // Renombrado de 'weeks' a 'weeklyPlans' para consistencia con el motor
  final List<WeekPlan> weeklyPlans;

  MacrocyclePlan({required this.weeklyPlans});

  // Alias para compatibilidad inversa si alguna UI vieja busca 'weeks'
  List<WeekPlan> get weeks => weeklyPlans;

  Map<String, dynamic> toMap() => {
    'weeklyPlans': weeklyPlans.map((w) => w.toMap()).toList(),
  };

  factory MacrocyclePlan.fromMap(Map<String, dynamic> map) {
    // Soporta ambas llaves por seguridad
    final raw = (map['weeklyPlans'] ?? map['weeks']) as List<dynamic>? ?? [];
    final list = raw
        .map((e) => WeekPlan.fromMap(e as Map<String, dynamic>))
        .toList();
    return MacrocyclePlan(weeklyPlans: list);
  }

  Map<String, dynamic> toJson() => toMap();

  factory MacrocyclePlan.fromJson(Map<String, dynamic> json) =>
      MacrocyclePlan.fromMap(json);
}
