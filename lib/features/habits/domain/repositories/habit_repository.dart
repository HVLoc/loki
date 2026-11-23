import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/entities/habit_target_history.dart';

class HabitWithSchedule {
  const HabitWithSchedule({
    required this.habit,
    required this.activeSchedule,
    required this.allSchedules,
  });

  final Habit habit;
  final HabitScheduleVersion activeSchedule;
  final List<HabitScheduleVersion> allSchedules;
}

abstract interface class HabitRepository {
  Future<Result<List<HabitWithSchedule>, Failure>> getHabitsForDate(
    String localDate,
  );
  Future<Result<List<Habit>, Failure>> getAllHabits({
    bool includeArchived = false,
  });
  Future<Result<List<HabitScheduleVersion>, Failure>> getScheduleVersions(
    String habitId,
  );
  Future<Result<Habit, Failure>> createHabit(
    Habit habit,
    HabitScheduleVersion initialSchedule,
  );
  Future<Result<Habit, Failure>> updateHabitDetails(Habit habit);
  Future<Result<HabitScheduleVersion, Failure>> updateHabitSchedule(
    String habitId,
    HabitScheduleVersion newScheduleFromToday,
  );
  Future<Result<Habit, Failure>> switchHabitTarget({
    required String habitId,
    required String? newTarget,
    required bool markPreviousCompleted,
  });
  Future<Result<List<HabitTargetHistory>, Failure>> getTargetHistory(
    String habitId,
  );
  Future<Result<void, Failure>> deleteOrArchiveHabit(
    String habitId, {
    required bool hardDelete,
  });
}
