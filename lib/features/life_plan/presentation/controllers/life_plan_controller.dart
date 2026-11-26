import 'package:get/get.dart';
import 'package:loki/features/life_plan/data/repositories/life_plan_firestore_repository_impl.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';
import 'package:loki/features/life_plan/domain/repositories/life_plan_repository.dart';
import 'package:loki/features/life_plan/domain/usecases/life_plan_usecases.dart';
import 'package:uuid/uuid.dart';

class LifePlanController extends GetxController {
  LifePlanController({
    required GetWheelAssessmentsUseCase getWheelAssessments,
    required SaveWheelAssessmentUseCase saveWheelAssessment,
    required GetGoalsUseCase getGoals,
    required SaveGoalWithRevisionUseCase saveGoalWithRevision,
    required GetGoalRevisionsUseCase getGoalRevisions,
  }) : this._(
         getWheelAssessments: getWheelAssessments,
         saveWheelAssessment: saveWheelAssessment,
         getGoals: getGoals,
         saveGoalWithRevision: saveGoalWithRevision,
         getGoalRevisions: getGoalRevisions,
       );

  LifePlanController._({
    required this._getWheelAssessments,
    required this._saveWheelAssessment,
    required this._getGoals,
    required this._saveGoalWithRevision,
    required this._getGoalRevisions,
  });

  final GetWheelAssessmentsUseCase _getWheelAssessments;
  final SaveWheelAssessmentUseCase _saveWheelAssessment;
  final GetGoalsUseCase _getGoals;
  final SaveGoalWithRevisionUseCase _saveGoalWithRevision;
  final GetGoalRevisionsUseCase _getGoalRevisions;

  final RxList<WheelAssessment> assessments = <WheelAssessment>[].obs;
  final RxList<LongTermGoal> goals = <LongTermGoal>[].obs;
  final Rx<GoalHorizon> selectedHorizon = GoalHorizon.oneYear.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  static const Uuid _uuid = Uuid();

  static const List<({String key, String label})> defaultDimensions = [
    (key: 'career', label: 'Sự nghiệp'),
    (key: 'finance', label: 'Tài chính'),
    (key: 'health', label: 'Sức khoẻ'),
    (key: 'family', label: 'Gia đình'),
    (key: 'growth', label: 'Phát triển bản thân'),
    (key: 'relationships', label: 'Quan hệ xã hội'),
    (key: 'recreation', label: 'Giải trí & Nghỉ ngơi'),
    (key: 'contribution', label: 'Đóng góp'),
  ];

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    final wheelRes = await _getWheelAssessments();
    wheelRes.fold((list) => assessments.assignAll(list), (_) {});
    final goalsRes = await _getGoals();
    goalsRes.fold((list) => goals.assignAll(list), (_) {});
    isLoading.value = false;
  }

  Future<void> saveWheelScores(List<WheelDimensionScore> scores) async {
    isSaving.value = true;
    try {
      final now = DateTime.now();
      final quarter = ((now.month - 1) ~/ 3) + 1;
      final assessment = WheelAssessment(
        id: _uuid.v4(),
        assessedAt: now,
        quarterLabel: '${now.year}-Q$quarter',
        scores: scores,
      );
      await _saveWheelAssessment(assessment);
      await loadAll();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveGoal({
    LongTermGoal? existing,
    required String title,
    required GoalHorizon horizon,
    required String nextMonthPlan,
    required int progressPercent,
    String? changeReason,
  }) async {
    isSaving.value = true;
    try {
      final now = DateTime.now();
      final goal = LongTermGoal(
        id: existing?.id ?? _uuid.v4(),
        title: title.trim(),
        horizon: horizon,
        dimensionKey: existing?.dimensionKey,
        nextMonthPlan: nextMonthPlan.trim(),
        progressPercent: progressPercent.clamp(0, 100),
        status: progressPercent >= 100
            ? GoalStatus.completed
            : GoalStatus.active,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await _saveGoalWithRevision(goal, changeReason: changeReason);
      await loadAll();
    } finally {
      isSaving.value = false;
    }
  }

  Future<List<GoalRevision>> fetchRevisions(String goalId) async {
    final res = await _getGoalRevisions(goalId);
    return res.dataOrNull ?? const [];
  }
}

class LifePlanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LifePlanRepository>(
      () => LifePlanFirestoreRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut(
      () => GetWheelAssessmentsUseCase(Get.find<LifePlanRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SaveWheelAssessmentUseCase(Get.find<LifePlanRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetGoalsUseCase(Get.find<LifePlanRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SaveGoalWithRevisionUseCase(Get.find<LifePlanRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetGoalRevisionsUseCase(Get.find<LifePlanRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => LifePlanController(
        getWheelAssessments: Get.find<GetWheelAssessmentsUseCase>(),
        saveWheelAssessment: Get.find<SaveWheelAssessmentUseCase>(),
        getGoals: Get.find<GetGoalsUseCase>(),
        saveGoalWithRevision: Get.find<SaveGoalWithRevisionUseCase>(),
        getGoalRevisions: Get.find<GetGoalRevisionsUseCase>(),
      ),
      fenix: true,
    );
  }
}
