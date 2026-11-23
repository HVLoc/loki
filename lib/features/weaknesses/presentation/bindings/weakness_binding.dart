import 'package:get/get.dart';
import 'package:loki/features/weaknesses/data/repositories/weakness_firestore_repository_impl.dart';
import 'package:loki/features/weaknesses/domain/repositories/weakness_repository.dart';
import 'package:loki/features/weaknesses/domain/usecases/weakness_usecases.dart';
import 'package:loki/features/weaknesses/presentation/controllers/weaknesses_controller.dart';

class WeaknessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeaknessRepository>(
      () => WeaknessFirestoreRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut(
      () => GetWeaknessesUseCase(Get.find<WeaknessRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SaveWeaknessUseCase(Get.find<WeaknessRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => ArchiveWeaknessUseCase(Get.find<WeaknessRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SeedStarterWeaknessesUseCase(Get.find<WeaknessRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => WeaknessesController(
        getWeaknesses: Get.find<GetWeaknessesUseCase>(),
        saveWeakness: Get.find<SaveWeaknessUseCase>(),
        archiveWeakness: Get.find<ArchiveWeaknessUseCase>(),
        seedStarterWeaknesses: Get.find<SeedStarterWeaknessesUseCase>(),
      ),
      fenix: true,
    );
  }
}
