import 'package:flutter_test/flutter_test.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/usecases/streak_calculator.dart';

void main() {
  const calculator = StreakCalculator();

  HabitScheduleVersion makeSchedule({
    required String effectiveFrom,
    int weekdaysMask = LocalDateUtils.allWeekdaysMask,
  }) => HabitScheduleVersion(
    id: 'sch_$effectiveFrom',
    habitId: 'h1',
    effectiveFrom: effectiveFrom,
    weekdaysMask: weekdaysMask,
    createdAt: DateTime(2026, 11, 1),
  );

  HabitLog makeLog(String date, HabitLogStatus status) => HabitLog(
    id: 'h1_$date',
    habitId: 'h1',
    logDate: date,
    status: status,
    loggedAt: DateTime(2026, 11, 20),
  );

  test(
    'counts consecutive scheduled completed days and ignores unscheduled days',
    () {
      // Mon-Wed-Fri schedule: (1<<0)|(1<<2)|(1<<4) = 21
      const monWedFri = 21;
      final schedules = [
        makeSchedule(effectiveFrom: '2026-11-16', weekdaysMask: monWedFri),
      ];
      // 2026-11-16 Mon, 18 Wed, 20 Fri, 23 Mon
      final logs = [
        makeLog('2026-11-16', HabitLogStatus.completed),
        makeLog('2026-11-18', HabitLogStatus.completed),
        makeLog('2026-11-20', HabitLogStatus.completed),
        makeLog('2026-11-23', HabitLogStatus.completed),
      ];

      final summary = calculator.calculate(
        schedules: schedules,
        logs: logs,
        today: DateTime(2026, 11, 23),
      );

      expect(summary.currentStreak, 4);
      expect(summary.longestStreak, 4);
    },
  );

  test('freezes streak on intentional Skip without resetting to zero', () {
    final schedules = [makeSchedule(effectiveFrom: '2026-11-20')];
    final logs = [
      makeLog('2026-11-20', HabitLogStatus.completed),
      makeLog('2026-11-21', HabitLogStatus.completed),
      makeLog('2026-11-22', HabitLogStatus.skipped),
      makeLog('2026-11-23', HabitLogStatus.completed),
    ];

    final summary = calculator.calculate(
      schedules: schedules,
      logs: logs,
      today: DateTime(2026, 11, 23),
    );

    expect(summary.currentStreak, 3);
    expect(summary.longestStreak, 3);
  });

  test('resets currentStreak when a past scheduled day was missed', () {
    final schedules = [makeSchedule(effectiveFrom: '2026-11-18')];
    final logs = [
      makeLog('2026-11-18', HabitLogStatus.completed),
      makeLog('2026-11-19', HabitLogStatus.completed),
      makeLog('2026-11-20', HabitLogStatus.completed),
      // 2026-11-21 missed!
      makeLog('2026-11-22', HabitLogStatus.completed),
      makeLog('2026-11-23', HabitLogStatus.completed),
    ];

    final summary = calculator.calculate(
      schedules: schedules,
      logs: logs,
      today: DateTime(2026, 11, 23),
    );

    expect(summary.currentStreak, 2);
    expect(summary.longestStreak, 3);
  });

  test('resolves forward-only schedule versions per historical date', () {
    // Before 2026-11-20: daily. From 2026-11-20: Mon-Wed-Fri only (21).
    final schedules = [
      makeSchedule(effectiveFrom: '2026-11-18', weekdaysMask: 127),
      makeSchedule(effectiveFrom: '2026-11-20', weekdaysMask: 21),
    ];
    // 18 (Wed), 19 (Thu - daily), 20 (Fri), 21 (Sat - unscheduled), 22 (Sun - unscheduled), 23 (Mon)
    final logs = [
      makeLog('2026-11-18', HabitLogStatus.completed),
      makeLog('2026-11-19', HabitLogStatus.completed),
      makeLog('2026-11-20', HabitLogStatus.completed),
      makeLog('2026-11-23', HabitLogStatus.completed),
    ];

    final summary = calculator.calculate(
      schedules: schedules,
      logs: logs,
      today: DateTime(2026, 11, 23),
    );

    expect(summary.currentStreak, 4);
  });
}
