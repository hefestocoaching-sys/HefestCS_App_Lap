import 'package:hcs_app_lap/core/enums/mechanic_profile.dart';

class ExerciseDefinition {
  final String id;
  final String name;
  final MechanicProfile mechanicProfile;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.mechanicProfile,
  });
}
