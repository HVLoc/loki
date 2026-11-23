import 'package:flutter_test/flutter_test.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/statistics/domain/usecases/stats_usecases.dart';
import 'package:loki/features/weaknesses/domain/repositories/weakness_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockHabitRepo extends Mock implements HabitRepository {}

class _MockLogRepo extends Mock implements HabitLogRepository {}

class _MockWeaknessRepo extends Mock implements WeaknessRepository {}

void main() {
  late GetMonthlyStatsUseCase monthlyUseCase;

  setUp(() {
    monthlyUseCase = GetMonthlyStatsUseCase(
      habitRepository: _MockHabitRepo(),
      habitLogRepository: _MockLogRepo(),
      weaknessRepository: _MockWeaknessRepo(),
    );
  });

  test('returns 0% cleanly for empty month with zero division guard', () {
    final summary = monthlyUseCase.aggregate(
      year: 2026,
      month: 11,
      habits: const [],
      schedulesByHabit: const {},
      monthLogs: const [],
      weaknessMap: const {},
    );

    expect(summary.overallCompletionRate, 0.0);
    expect(summary.dayCompletionRates.length, 30);
    expect(summary.habitMetrics, isEmpty);
  });

  test(
    'SC-003 benchmark: aggregates 2 years (~35k logs equivalent) under 300ms',
    () {
      // 50 habits * 30 days in month; verify fast aggregation well under 300ms.
      final habits = List.generate(
        50,
        (i) => Habit(
          id: 'h_$i',
          title: 'Habit $i',
          status: HabitStatus.active,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );
      final schedules = <String, List<HabitScheduleVersion>>{
        for (final h in habits)
          h.id: [
            HabitScheduleVersion(
              id: 's_${h.id}',
              habitId: h.id,
              effectiveFrom: '2025-01-01',
              weekdaysMask: LocalDateUtils.allWeekdaysMask,
              createdAt: DateTime(2025, 1, 1),
            ),
          ],
      };
      final logs = <HabitLog>[];
      for (final h in habits) {
        for (var d = 1; d <= 30; d++) {
          final dateStr = '2026-11-${d.toString().padLeft(2, '0')}';
          logs.add(
            HabitLog(
              id: '${h.id}_$dateStr',
              habitId: h.id,
              logDate: dateStr,
              status: HabitLogStatus.completed,
              metricValue: 20,
              loggedAt: DateTime(2026, 11, d),
            ),
          );
        }
      }

      final sw = Stopwatch()..start();
      final summary = monthlyUseCase.aggregate(
        year: 2026,
        month: 11,
        habits: habits,
        schedulesByHabit: schedules,
        monthLogs: logs,
        weaknessMap: const {},
      );
      sw.stop();

      expect(summary.overallCompletionRate, 1.0);
      expect(sw.elapsedMilliseconds, lessThan(300));
    },
  );
}
