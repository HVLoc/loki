import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/habits/domain/usecases/streak_calculator.dart';
import 'package:loki/features/statistics/domain/entities/stats_models.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';
import 'package:loki/features/weaknesses/domain/repositories/weakness_repository.dart';

class GetDailyStatsUseCase {
  const GetDailyStatsUseCase({
    required this.habitRepository,
    required this.habitLogRepository,
  });

  final HabitRepository habitRepository;
  final HabitLogRepository habitLogRepository;

  Future<Result<DailySummary, Failure>> call(String localDate) async {
    final habitsRes = await habitRepository.getHabitsForDate(localDate);
    if (habitsRes.isFailure) return FailureResult(habitsRes.failureOrNull!);

    final logsRes = await habitLogRepository.getLogsByDate(localDate);
    if (logsRes.isFailure) return FailureResult(logsRes.failureOrNull!);

    final dateObj = LocalDateUtils.parse(localDate);
    final logByHabit = <String, HabitLog>{
      for (final log in logsRes.dataOrNull!) log.habitId: log,
    };

    var scheduled = 0;
    var completed = 0;
    var skipped = 0;
    final details = <DailyHabitDetail>[];

    for (final entry in habitsRes.dataOrNull!) {
      if (!LocalDateUtils.isScheduledOnDate(
        dateObj,
        entry.activeSchedule.weekdaysMask,
      )) {
        continue;
      }
      scheduled += 1;
      final log = logByHabit[entry.habit.id];
      if (log?.status == HabitLogStatus.completed) completed += 1;
      if (log?.status == HabitLogStatus.skipped) skipped += 1;
      details.add(
        DailyHabitDetail(
          habitId: entry.habit.id,
          habitTitle: entry.habit.title,
          weaknessId: entry.habit.weaknessId,
          status: log?.status,
          metricValue: log?.metricValue,
          note:
              [
                if (log?.targetSnapshot != null)
                  'Mục tiêu: ${log!.targetSnapshot}',
                if (log?.note != null) log!.note!,
                if (log?.skipReason != null) log!.skipReason!,
              ].join(' • ').isEmpty
              ? null
              : [
                  if (log?.targetSnapshot != null)
                    'Mục tiêu: ${log!.targetSnapshot}',
                  if (log?.note != null) log!.note!,
                  if (log?.skipReason != null) log!.skipReason!,
                ].join(' • '),
        ),
      );
    }

    final effectiveDenom = scheduled - skipped;
    final rate = effectiveDenom <= 0 ? 0.0 : completed / effectiveDenom;
    return Success(
      DailySummary(
        date: localDate,
        scheduledCount: scheduled,
        completedCount: completed,
        skippedCount: skipped,
        completionRate: rate.clamp(0.0, 1.0),
        details: details,
      ),
    );
  }
}

class GetMonthlyStatsUseCase {
  const GetMonthlyStatsUseCase({
    required this.habitRepository,
    required this.habitLogRepository,
    required this.weaknessRepository,
  });

  final HabitRepository habitRepository;
  final HabitLogRepository habitLogRepository;
  final WeaknessRepository weaknessRepository;

  Future<Result<MonthlySummary, Failure>> call(int year, int month) async {
    final habitsRes = await habitRepository.getAllHabits(includeArchived: true);
    if (habitsRes.isFailure) return FailureResult(habitsRes.failureOrNull!);

    final logsRes = await habitLogRepository.getLogsByMonth(year, month);
    if (logsRes.isFailure) return FailureResult(logsRes.failureOrNull!);

    final weaknessesRes = await weaknessRepository.getWeaknesses(
      includeArchived: true,
    );
    final weaknessMap = <String, Weakness>{
      for (final w in weaknessesRes.dataOrNull ?? const <Weakness>[]) w.id: w,
    };

    final habits = habitsRes.dataOrNull!;
    final schedulesByHabit = <String, List<HabitScheduleVersion>>{};
    for (final h in habits) {
      final schRes = await habitRepository.getScheduleVersions(h.id);
      final list = [...(schRes.dataOrNull ?? const <HabitScheduleVersion>[])]
        ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
      schedulesByHabit[h.id] = list;
    }

    return Success(
      aggregate(
        year: year,
        month: month,
        habits: habits,
        schedulesByHabit: schedulesByHabit,
        monthLogs: logsRes.dataOrNull!,
        weaknessMap: weaknessMap,
      ),
    );
  }

  /// Pure synchronous aggregation enabling fast <300ms computation & benchmarking.
  MonthlySummary aggregate({
    required int year,
    required int month,
    required List<Habit> habits,
    required Map<String, List<HabitScheduleVersion>> schedulesByHabit,
    required List<HabitLog> monthLogs,
    required Map<String, Weakness> weaknessMap,
  }) {
    final logLookup = <String, HabitLog>{
      for (final l in monthLogs) '${l.habitId}_${l.logDate}': l,
    };
    final activeDaysCount = <String, int>{for (final h in habits) h.id: 0};
    final metricSum = <String, double>{for (final h in habits) h.id: 0};

    final dayRates = <String, double>{};
    var totalCompleted = 0;
    var totalEffectiveScheduled = 0;

    for (final dateStr in LocalDateUtils.daysInMonthList(year, month)) {
      final dateObj = LocalDateUtils.parse(dateStr);
      var dayScheduled = 0;
      var dayCompleted = 0;
      var daySkipped = 0;

      for (final h in habits) {
        final versions = schedulesByHabit[h.id] ?? const [];
        final active = StreakCalculator.resolveScheduleForDate(
          versions,
          dateStr,
        );
        if (active == null ||
            !LocalDateUtils.isScheduledOnDate(dateObj, active.weekdaysMask)) {
          continue;
        }
        dayScheduled += 1;
        final log = logLookup['${h.id}_$dateStr'];
        if (log?.status == HabitLogStatus.completed) {
          dayCompleted += 1;
          activeDaysCount[h.id] = (activeDaysCount[h.id] ?? 0) + 1;
          metricSum[h.id] = (metricSum[h.id] ?? 0) + (log?.metricValue ?? 0);
        } else if (log?.status == HabitLogStatus.skipped) {
          daySkipped += 1;
        }
      }

      final effectiveDay = dayScheduled - daySkipped;
      dayRates[dateStr] = effectiveDay <= 0
          ? 0.0
          : (dayCompleted / effectiveDay).clamp(0.0, 1.0);
      totalCompleted += dayCompleted;
      if (effectiveDay > 0) totalEffectiveScheduled += effectiveDay;
    }

    final overall = totalEffectiveScheduled <= 0
        ? 0.0
        : (totalCompleted / totalEffectiveScheduled).clamp(0.0, 1.0);

    final metrics = habits
        .where(
          (h) =>
              h.status != HabitStatus.archived ||
              (activeDaysCount[h.id] ?? 0) > 0,
        )
        .map(
          (h) => MonthlyHabitMetric(
            habitId: h.id,
            habitTitle: h.title,
            weaknessTitle: h.weaknessId == null
                ? null
                : weaknessMap[h.weaknessId]?.title,
            activeDaysInMonth: activeDaysCount[h.id] ?? 0,
            totalMetricValue: metricSum[h.id] ?? 0,
            metricUnit: h.metricUnit,
          ),
        )
        .toList();

    return MonthlySummary(
      year: year,
      month: month,
      overallCompletionRate: overall,
      dayCompletionRates: dayRates,
      habitMetrics: metrics,
    );
  }
}
