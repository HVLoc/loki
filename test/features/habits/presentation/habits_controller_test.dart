import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/habits/domain/services/reminder_scheduler.dart';
import 'package:loki/features/habits/domain/usecases/habit_usecases.dart';
import 'package:loki/features/habits/domain/usecases/streak_calculator.dart';
import 'package:loki/features/habits/presentation/controllers/habits_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockHabitRepo extends Mock implements HabitRepository {}

class _MockLogRepo extends Mock implements HabitLogRepository {}

class _MockReminderScheduler extends Mock implements ReminderScheduler {}

void main() {
  late _MockHabitRepo habitRepo;
  late _MockLogRepo logRepo;
  late _MockReminderScheduler reminderScheduler;
  late HabitsController controller;

  final sampleHabit = Habit(
    id: 'h1',
    title: 'Đọc sách kinh doanh',
    status: HabitStatus.active,
    createdAt: DateTime(2026, 11, 20),
    updatedAt: DateTime(2026, 11, 20),
  );
  final sampleSchedule = HabitScheduleVersion(
    id: 's1',
    habitId: 'h1',
    effectiveFrom: '2026-11-20',
    weekdaysMask: 127,
    createdAt: DateTime(2026, 11, 20),
  );

  setUpAll(() {
    registerFallbackValue(
      HabitLog(
        id: 'fallback',
        habitId: 'h1',
        logDate: '2026-11-23',
        status: HabitLogStatus.completed,
        loggedAt: DateTime(2026, 11, 23),
      ),
    );
  });

  setUp(() {
    Get.testMode = true;
    habitRepo = _MockHabitRepo();
    logRepo = _MockLogRepo();
    reminderScheduler = _MockReminderScheduler();

    when(
      () => reminderScheduler.onReminderAction,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => reminderScheduler.requestPermissionIfNeeded(),
    ).thenAnswer((_) async => const Success(true));
    when(() => habitRepo.getHabitsForDate(any())).thenAnswer(
      (_) async => Success([
        HabitWithSchedule(
          habit: sampleHabit,
          activeSchedule: sampleSchedule,
          allSchedules: [sampleSchedule],
        ),
      ]),
    );
    when(
      () => logRepo.getLogsForHabit('h1'),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => logRepo.getLogsByDate(any()),
    ).thenAnswer((_) async => const Success([]));

    controller = HabitsController(
      getTodayHabits: GetTodayHabitsUseCase(
        habitRepository: habitRepo,
        habitLogRepository: logRepo,
        streakCalculator: const StreakCalculator(),
      ),
      logHabitCheckIn: LogHabitCheckInUseCase(logRepo),
      saveHabit: SaveHabitUseCase(habitRepo, reminderScheduler),
      reminderScheduler: reminderScheduler,
    );
  });

  tearDown(Get.reset);

  test('loads today habits and performs 1-tap complete', () async {
    await controller.loadTodayHabits(now: DateTime(2026, 11, 23));
    expect(controller.todayItems.length, 1);
    expect(controller.todayItems.first.todayLog, isNull);

    final completedLog = HabitLog(
      id: 'h1_2026-11-23',
      habitId: 'h1',
      logDate: '2026-11-23',
      status: HabitLogStatus.completed,
      loggedAt: DateTime(2026, 11, 23),
    );
    when(() => logRepo.upsertLog(any())).thenAnswer(
      (inv) async => Success(inv.positionalArguments.first as HabitLog),
    );
    when(
      () => logRepo.getLogsByDate(any()),
    ).thenAnswer((_) async => Success([completedLog]));
    when(
      () => logRepo.getLogsForHabit('h1'),
    ).thenAnswer((_) async => Success([completedLog]));

    await controller.completeHabit(sampleHabit, now: DateTime(2026, 11, 23));

    expect(
      controller.todayItems.first.todayLog?.status,
      HabitLogStatus.completed,
    );
    expect(controller.todayItems.first.currentStreak, 1);
  });
}
