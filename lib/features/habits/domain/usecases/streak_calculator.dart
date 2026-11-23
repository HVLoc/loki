import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';

class StreakSummary {
  const StreakSummary({
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;
}

/// Evaluates scheduled-day streaks with intentional Skip freezing (Q3: A).
class StreakCalculator {
  const StreakCalculator();

  static HabitScheduleVersion? resolveScheduleForDate(
    List<HabitScheduleVersion> sortedAscending,
    String dateStr,
  ) {
    HabitScheduleVersion? active;
    for (final v in sortedAscending) {
      if (v.effectiveFrom.compareTo(dateStr) <= 0) {
        active = v;
      } else {
        break;
      }
    }
    return active;
  }

  StreakSummary calculate({
    required List<HabitScheduleVersion> schedules,
    required List<HabitLog> logs,
    DateTime? today,
  }) {
    if (schedules.isEmpty) {
      return const StreakSummary(currentStreak: 0, longestStreak: 0);
    }

    final sortedSchedules = [...schedules]
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    final earliestDate = LocalDateUtils.parse(
      sortedSchedules.first.effectiveFrom,
    );
    final todayDate = LocalDateUtils.stripTime(today ?? DateTime.now());
    if (todayDate.isBefore(earliestDate)) {
      return const StreakSummary(currentStreak: 0, longestStreak: 0);
    }

    final logByDate = <String, HabitLog>{
      for (final log in logs) log.logDate: log,
    };

    // Walk forward from earliestDate to todayDate to compute longestStreak
    var running = 0;
    var longest = 0;
    var cursor = earliestDate;
    while (!cursor.isAfter(todayDate)) {
      final dateStr = LocalDateUtils.format(cursor);
      final active = resolveScheduleForDate(sortedSchedules, dateStr);
      if (active != null &&
          LocalDateUtils.isScheduledOnDate(cursor, active.weekdaysMask)) {
        final log = logByDate[dateStr];
        if (log?.status == HabitLogStatus.completed) {
          running += 1;
          if (running > longest) {
            longest = running;
          }
        } else if (log?.status == HabitLogStatus.skipped) {
          // Freeze streak: keep running intact without incrementing.
        } else if (cursor.isBefore(todayDate)) {
          running = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    // Current streak is running at todayDate (if today is pending, running already
    // preserves the streak built through yesterday!).
    return StreakSummary(currentStreak: running, longestStreak: longest);
  }
}
