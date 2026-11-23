import 'package:get/get.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/statistics/domain/entities/stats_models.dart';
import 'package:loki/features/statistics/domain/usecases/stats_usecases.dart';
import 'package:loki/features/weaknesses/domain/repositories/weakness_repository.dart';

class StatisticsController extends GetxController {
  StatisticsController({
    required GetDailyStatsUseCase getDailyStats,
    required GetMonthlyStatsUseCase getMonthlyStats,
  }) : this._(getDailyStats: getDailyStats, getMonthlyStats: getMonthlyStats);

  StatisticsController._({
    required this._getDailyStats,
    required this._getMonthlyStats,
  });

  final GetDailyStatsUseCase _getDailyStats;
  final GetMonthlyStatsUseCase _getMonthlyStats;

  final RxBool isMonthlyMode = true.obs;
  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rxn<DailySummary> dailySummary = Rxn<DailySummary>();
  final Rxn<MonthlySummary> monthlySummary = Rxn<MonthlySummary>();

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    final d = selectedDate.value;
    final dailyRes = await _getDailyStats(LocalDateUtils.format(d));
    dailyRes.fold((s) => dailySummary.value = s, (_) {});

    final monthlyRes = await _getMonthlyStats(d.year, d.month);
    monthlyRes.fold((s) => monthlySummary.value = s, (_) {});
    isLoading.value = false;
  }

  Future<void> selectDate(DateTime date) async {
    final prev = selectedDate.value;
    selectedDate.value = date;
    final dailyRes = await _getDailyStats(LocalDateUtils.format(date));
    dailyRes.fold((s) => dailySummary.value = s, (_) {});
    if (prev.year != date.year || prev.month != date.month) {
      final monthlyRes = await _getMonthlyStats(date.year, date.month);
      monthlyRes.fold((s) => monthlySummary.value = s, (_) {});
    }
  }

  Future<void> changeMonth(int delta) async {
    final cur = selectedDate.value;
    final next = DateTime(cur.year, cur.month + delta, 1);
    await selectDate(next);
  }
}

class StatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => GetDailyStatsUseCase(
        habitRepository: Get.find<HabitRepository>(),
        habitLogRepository: Get.find<HabitLogRepository>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => GetMonthlyStatsUseCase(
        habitRepository: Get.find<HabitRepository>(),
        habitLogRepository: Get.find<HabitLogRepository>(),
        weaknessRepository: Get.find<WeaknessRepository>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => StatisticsController(
        getDailyStats: Get.find<GetDailyStatsUseCase>(),
        getMonthlyStats: Get.find<GetMonthlyStatsUseCase>(),
      ),
      fenix: true,
    );
  }
}
