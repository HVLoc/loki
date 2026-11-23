import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/entities/habit_target_history.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/habits/domain/services/reminder_scheduler.dart';
import 'package:loki/features/habits/domain/usecases/streak_calculator.dart';

class TodayHabitItem {
  const TodayHabitItem({
    required this.habit,
    required this.activeSchedule,
    required this.todayLog,
    required this.currentStreak,
    required this.longestStreak,
  });

  final Habit habit;
  final HabitScheduleVersion activeSchedule;
  final HabitLog? todayLog;
  final int currentStreak;
  final int longestStreak;
}

class GetTodayHabitsUseCase {
  const GetTodayHabitsUseCase({
    required this.habitRepository,
    required this.habitLogRepository,
    required this.streakCalculator,
  });

  final HabitRepository habitRepository;
  final HabitLogRepository habitLogRepository;
  final StreakCalculator streakCalculator;

  Future<Result<List<TodayHabitItem>, Failure>> call({DateTime? now}) async {
    final targetDate = LocalDateUtils.stripTime(now ?? DateTime.now());
    final dateStr = LocalDateUtils.format(targetDate);

    final habitsRes = await habitRepository.getHabitsForDate(dateStr);
    if (habitsRes.isFailure) {
      return FailureResult(habitsRes.failureOrNull!);
    }

    final todayLogsRes = await habitLogRepository.getLogsByDate(dateStr);
    if (todayLogsRes.isFailure) {
      return FailureResult(todayLogsRes.failureOrNull!);
    }

    final todayLogMap = <String, HabitLog>{
      for (final log in todayLogsRes.dataOrNull!) log.habitId: log,
    };

    final items = <TodayHabitItem>[];
    for (final entry in habitsRes.dataOrNull!) {
      if (!LocalDateUtils.isScheduledOnDate(
        targetDate,
        entry.activeSchedule.weekdaysMask,
      )) {
        continue;
      }
      final habitLogsRes = await habitLogRepository.getLogsForHabit(
        entry.habit.id,
      );
      final logs = habitLogsRes.dataOrNull ?? const <HabitLog>[];
      final streak = streakCalculator.calculate(
        schedules: entry.allSchedules,
        logs: logs,
        today: targetDate,
      );
      items.add(
        TodayHabitItem(
          habit: entry.habit,
          activeSchedule: entry.activeSchedule,
          todayLog: todayLogMap[entry.habit.id],
          currentStreak: streak.currentStreak,
          longestStreak: streak.longestStreak,
        ),
      );
    }
    return Success(items);
  }
}

class LogHabitCheckInUseCase {
  const LogHabitCheckInUseCase(this._logRepository);

  final HabitLogRepository _logRepository;

  Future<Result<HabitLog, Failure>> complete({
    required String habitId,
    String? targetSnapshot,
    DateTime? now,
    double? metricValue,
    String? note,
  }) {
    final timestamp = now ?? DateTime.now();
    final dateStr = LocalDateUtils.format(timestamp);
    return _logRepository.upsertLog(
      HabitLog(
        id: '${habitId}_$dateStr',
        habitId: habitId,
        logDate: dateStr,
        status: HabitLogStatus.completed,
        targetSnapshot: targetSnapshot,
        metricValue: metricValue,
        note: note,
        loggedAt: timestamp,
      ),
    );
  }

  Future<Result<HabitLog, Failure>> skip({
    required String habitId,
    DateTime? now,
    String? skipReason,
  }) {
    final timestamp = now ?? DateTime.now();
    final dateStr = LocalDateUtils.format(timestamp);
    return _logRepository.upsertLog(
      HabitLog(
        id: '${habitId}_$dateStr',
        habitId: habitId,
        logDate: dateStr,
        status: HabitLogStatus.skipped,
        skipReason: skipReason,
        loggedAt: timestamp,
      ),
    );
  }

  Future<Result<void, Failure>> undo({required String habitId, DateTime? now}) {
    final dateStr = LocalDateUtils.format(now ?? DateTime.now());
    return _logRepository.deleteLog(habitId, dateStr);
  }
}

class SaveHabitUseCase {
  const SaveHabitUseCase(this._habitRepository, this._reminderScheduler);

  final HabitRepository _habitRepository;
  final ReminderScheduler _reminderScheduler;

  Future<Result<Habit, Failure>> create({
    required Habit habit,
    required HabitScheduleVersion initialSchedule,
  }) async {
    if (habit.title.trim().isEmpty) {
      return const FailureResult(ValidationFailure('Habit title is required'));
    }
    final res = await _habitRepository.createHabit(habit, initialSchedule);
    if (res.isSuccess && initialSchedule.reminderTimeMinutes != null) {
      await _reminderScheduler.scheduleHabitReminder(habit, initialSchedule);
    }
    return res;
  }

  Future<Result<Habit, Failure>> update({
    required Habit habit,
    HabitScheduleVersion? newScheduleFromToday,
  }) async {
    if (habit.title.trim().isEmpty) {
      return const FailureResult(ValidationFailure('Habit title is required'));
    }
    final res = await _habitRepository.updateHabitDetails(habit);
    if (res.isFailure) return res;

    if (newScheduleFromToday != null) {
      final schRes = await _habitRepository.updateHabitSchedule(
        habit.id,
        newScheduleFromToday,
      );
      if (schRes.isFailure) {
        return FailureResult(schRes.failureOrNull!);
      }
      if (newScheduleFromToday.reminderTimeMinutes != null &&
          habit.status == HabitStatus.active) {
        await _reminderScheduler.scheduleHabitReminder(
          habit,
          newScheduleFromToday,
        );
      } else {
        await _reminderScheduler.cancelHabitReminder(habit.id);
      }
    }
    return res;
  }
}

class SwitchHabitTargetUseCase {
  const SwitchHabitTargetUseCase(this._habitRepository);

  final HabitRepository _habitRepository;

  Future<Result<Habit, Failure>> call({
    required String habitId,
    required String? newTarget,
    required bool markPreviousCompleted,
  }) {
    final trimmed = newTarget?.trim();
    return _habitRepository.switchHabitTarget(
      habitId: habitId,
      newTarget: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      markPreviousCompleted: markPreviousCompleted,
    );
  }

  Future<Result<List<HabitTargetHistory>, Failure>> history(String habitId) =>
      _habitRepository.getTargetHistory(habitId);
}
