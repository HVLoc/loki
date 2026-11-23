import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';

enum ReminderActionType { complete, snooze, open }

class ReminderActionEvent {
  const ReminderActionEvent({required this.habitId, required this.action});

  final String habitId;
  final ReminderActionType action;
}

abstract interface class ReminderScheduler {
  Future<Result<bool, Failure>> requestPermissionIfNeeded();
  Future<Result<void, Failure>> syncLocalTimezone();
  Future<Result<void, Failure>> scheduleHabitReminder(
    Habit habit,
    HabitScheduleVersion schedule,
  );
  Future<Result<void, Failure>> cancelHabitReminder(String habitId);
  Future<Result<void, Failure>> snoozeHabitReminder(
    String habitId,
    String habitTitle,
    Duration delay,
  );
  Stream<ReminderActionEvent> get onReminderAction;
}
