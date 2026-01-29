import 'dart:convert';
import 'dart:io';

import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final engine = TrainingProgramEngine();
  final profile = TrainingProfile(
    id: 'golden-client-01',
    daysPerWeek: 4,
    timePerSessionMinutes: 60,
    trainingLevel: TrainingLevel.intermediate,
    equipment: const ['barbell', 'dumbbell', 'machine', 'cable'],
    baseVolumePerMuscle: const {
      'chest': 12,
      'back': 14,
      'shoulders': 10,
      'quads': 10,
    },
  );

  final plan = engine.generatePlan(
    planId: 'golden-plan-01',
    clientId: 'golden-client-01',
    planName: 'Golden Plan 01',
    startDate: DateTime.utc(2025, 12, 20),
    profile: profile,
    exerciseCatalog: ExerciseCatalog.fromFilePath(
      'lib/data/exercise_catalog.json',
    ),
  );

  final generated = jsonEncode(plan.toJson());
  final fixturePath = p.join('test', 'fixtures', 'golden_plan_case01.json');
  await File(fixturePath).writeAsString(generated);

  stdout.writeln('Updated $fixturePath (${generated.length} chars)');
}
