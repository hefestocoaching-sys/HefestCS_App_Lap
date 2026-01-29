class NutritionExtraKeys {
  // Legacy
  static const kcalAdjustment = 'kcalAdjustment';
  static const weightGoal = 'weightGoal';

  // Core
  static const typicalDayEating = 'typicalDayEating';
  static const typicalDayEatingEntries = 'typicalDayEatingEntries';
  static const dietHistory = 'dietHistory';
  static const supplementsPre = 'supplementsPre';
  static const supplementsIntra = 'supplementsIntra';
  static const supplementsPost = 'supplementsPost';
  static const supplementsHealth = 'supplementsHealth';
  static const preferredMealsPerDay = 'preferredMealsPerDay';
  static const weekdayCookingTime = 'weekdayCookingTime';
  static const weekendCookingTime = 'weekendCookingTime';
  static const foodAccess = 'foodAccess';
  static const budgetLevel = 'budgetLevel';
  static const eatingBehaviorNotes = 'eatingBehaviorNotes';
  static const evaluationRecords = 'evaluationRecords';
  static const macrosRecords = 'macrosRecords';
  static const mealPlanRecords = 'mealPlanRecords';
  static const adherenceLogRecords = 'adherenceLogRecords';
  static const selectedMacrosRecordDateIso = 'selectedMacrosRecordDateIso';
  static const selectedMealPlanRecordDateIso = 'selectedMealPlanRecordDateIso';

  // NEW v2: Déficit porcentual
  static const deficitPct = 'deficitPct'; // 0.10..0.25
  static const floorPct = 'floorPct'; // default 0.95
  static const deficitKcalAvg = 'deficitKcalAvg'; // promedio real post-piso
  static const estimatedKgWeek = 'estimatedKgWeek';
  static const estimatedKgMonth = 'estimatedKgMonth';

  const NutritionExtraKeys._();
}
