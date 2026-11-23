import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/i18n/app_translations.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/habits/domain/services/reminder_scheduler.dart';
import 'package:loki/features/habits/domain/usecases/habit_usecases.dart';
import 'package:loki/features/habits/domain/usecases/streak_calculator.dart';
import 'package:loki/features/habits/presentation/controllers/habits_controller.dart';
import 'package:loki/features/habits/presentation/pages/today_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockHabitRepo extends Mock implements HabitRepository {}

class _MockLogRepo extends Mock implements HabitLogRepository {}

class _MockReminderScheduler extends Mock implements ReminderScheduler {}

void main() {
  late _MockHabitRepo habitRepo;
  late _MockLogRepo logRepo;
  late _MockReminderScheduler scheduler;

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
    scheduler = _MockReminderScheduler();

    when(
      () => scheduler.onReminderAction,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => scheduler.syncLocalTimezone(),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => scheduler.requestPermissionIfNeeded(),
    ).thenAnswer((_) async => const Success(true));
  });

  tearDown(Get.reset);

  testWidgets('TodayPage shows empty state when no habits scheduled', (
    tester,
  ) async {
    when(
      () => habitRepo.getHabitsForDate(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => logRepo.getLogsByDate(any()),
    ).thenAnswer((_) async => const Success([]));

    Get.put(
      HabitsController(
        getTodayHabits: GetTodayHabitsUseCase(
          habitRepository: habitRepo,
          habitLogRepository: logRepo,
          streakCalculator: const StreakCalculator(),
        ),
        logHabitCheckIn: LogHabitCheckInUseCase(logRepo),
        saveHabit: SaveHabitUseCase(habitRepo, scheduler),
        reminderScheduler: scheduler,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('vi', 'VN'),
        home: const TodayPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chưa có thói quen nào'), findsOneWidget);
  });

  testWidgets('TodayPage renders habit card and completes in 1 tap', (
    tester,
  ) async {
    final habit = Habit(
      id: 'h1',
      title: 'Học Tiếng Anh 25p',
      anchorHabitText: 'Uống cà phê sáng',
      targetDurationMinutes: 25,
      status: HabitStatus.active,
      createdAt: DateTime(2026, 11, 20),
      updatedAt: DateTime(2026, 11, 20),
    );
    final schedule = HabitScheduleVersion(
      id: 's1',
      habitId: 'h1',
      effectiveFrom: '2026-11-20',
      weekdaysMask: 127,
      createdAt: DateTime(2026, 11, 20),
    );

    when(() => habitRepo.getHabitsForDate(any())).thenAnswer(
      (_) async => Success([
        HabitWithSchedule(
          habit: habit,
          activeSchedule: schedule,
          allSchedules: [schedule],
        ),
      ]),
    );
    when(
      () => logRepo.getLogsByDate(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => logRepo.getLogsForHabit('h1'),
    ).thenAnswer((_) async => const Success([]));
    when(() => logRepo.upsertLog(any())).thenAnswer(
      (inv) async => Success(inv.positionalArguments.first as HabitLog),
    );

    Get.put(
      HabitsController(
        getTodayHabits: GetTodayHabitsUseCase(
          habitRepository: habitRepo,
          habitLogRepository: logRepo,
          streakCalculator: const StreakCalculator(),
        ),
        logHabitCheckIn: LogHabitCheckInUseCase(logRepo),
        saveHabit: SaveHabitUseCase(habitRepo, scheduler),
        reminderScheduler: scheduler,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('vi', 'VN'),
        home: const TodayPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Học Tiếng Anh 25p'), findsOneWidget);
    expect(find.text('Sau khi: Uống cà phê sáng'), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
  });
}
