import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart';
import 'package:hcs_app_lap/data/datasources/local/exercise_catalog_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verificar correccion de calves', () {
    final resolved = MuscleToCatalogResolver.resolve(MuscleGroup.calves);
    expect(resolved, contains('gastrocnemio'));
    expect(resolved, contains('soleo'));
    expect(resolved, isNot(contains('calves')));
  });

  test('Verificar catalogo carga correctamente', () async {
    final exercises = await ExerciseCatalogLoader.load();
    expect(exercises.isNotEmpty, true);

    final exerciseIds = exercises.map((e) => e.id).toList();
    expect(exerciseIds, contains('push_up'));
    expect(exerciseIds, contains('plank'));
    expect(exerciseIds, contains('tricep_pushdown_bar'));
  });
}
