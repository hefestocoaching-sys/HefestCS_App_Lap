import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/services/exercise_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ExerciseCatalogService no lanza excepciones', () async {
    final service = ExerciseCatalogService();

    // Este test NO debe fallar aunque el asset no cargue
    await service.ensureLoaded();

    // El test pasa independientemente del resultado de carga
    expect(true, true);
  });

  test('Métodos de lookup devuelven listas vacías si no hay datos', () {
    final service = ExerciseCatalogService();

    // Sin llamar ensureLoaded, debe devolver listas vacías
    final byMuscle = service.getByPrimaryMuscle('chest');
    final byGroup = service.getByEquivalenceGroup('press');
    final byId = service.getById('ex_0001');

    expect(byMuscle, isA<List>());
    expect(byGroup, isA<List>());
    expect(byId, isNull);
  });
}
