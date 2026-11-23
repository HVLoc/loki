import 'package:get/get.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';
import 'package:loki/features/weaknesses/domain/usecases/weakness_usecases.dart';
import 'package:uuid/uuid.dart';

class WeaknessesController extends GetxController {
  WeaknessesController({
    required GetWeaknessesUseCase getWeaknesses,
    required SaveWeaknessUseCase saveWeakness,
    required ArchiveWeaknessUseCase archiveWeakness,
    required SeedStarterWeaknessesUseCase seedStarterWeaknesses,
  }) : this._(
         getWeaknesses: getWeaknesses,
         saveWeakness: saveWeakness,
         archiveWeakness: archiveWeakness,
         seedStarterWeaknesses: seedStarterWeaknesses,
       );

  WeaknessesController._({
    required this._getWeaknesses,
    required this._saveWeakness,
    required this._archiveWeakness,
    required this._seedStarterWeaknesses,
  });

  final GetWeaknessesUseCase _getWeaknesses;
  final SaveWeaknessUseCase _saveWeakness;
  final ArchiveWeaknessUseCase _archiveWeakness;
  final SeedStarterWeaknessesUseCase _seedStarterWeaknesses;

  final RxList<Weakness> weaknesses = <Weakness>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  static const Uuid _uuid = Uuid();

  @override
  void onInit() {
    super.onInit();
    loadWeaknesses(seedIfEmpty: true);
  }

  Future<void> loadWeaknesses({bool seedIfEmpty = false}) async {
    isLoading.value = true;
    errorMessage.value = '';
    if (seedIfEmpty) {
      await _seedStarterWeaknesses();
    }
    final res = await _getWeaknesses();
    res.fold(
      (list) => weaknesses.assignAll(list),
      (f) => errorMessage.value = f.message,
    );
    isLoading.value = false;
  }

  Future<bool> addOrUpdateWeakness({
    Weakness? existing,
    required String title,
    required String actionOrientation,
    String? metricLabel,
    String? metricUnit,
  }) async {
    final now = DateTime.now();
    final target = existing == null
        ? Weakness(
            id: _uuid.v4(),
            title: title.trim(),
            actionOrientation: actionOrientation.trim(),
            metricLabel: metricLabel?.trim().isEmpty == true
                ? null
                : metricLabel?.trim(),
            metricUnit: metricUnit?.trim().isEmpty == true
                ? null
                : metricUnit?.trim(),
            status: WeaknessStatus.active,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            title: title.trim(),
            actionOrientation: actionOrientation.trim(),
            metricLabel: metricLabel?.trim(),
            metricUnit: metricUnit?.trim(),
            updatedAt: now,
          );
    final res = await _saveWeakness(target);
    if (res.isFailure) {
      errorMessage.value = res.failureOrNull!.message;
      return false;
    }
    await loadWeaknesses();
    return true;
  }

  Future<void> archiveWeakness(
    String weaknessId, {
    required bool archiveLinkedHabits,
  }) async {
    final res = await _archiveWeakness(
      weaknessId,
      archiveLinkedHabits: archiveLinkedHabits,
    );
    if (res.isFailure) {
      errorMessage.value = res.failureOrNull!.message;
      return;
    }
    await loadWeaknesses();
  }
}
