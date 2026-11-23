import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/i18n/app_translations.dart';
import 'package:loki/core/storage/prefs_service.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/features/auth/domain/entities/auth_user.dart';
import 'package:loki/features/auth/domain/repositories/auth_repository.dart';
import 'package:loki/features/auth/domain/usecases/auth_usecases.dart';
import 'package:loki/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loki/features/auth/presentation/pages/account_settings_page.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/habits/domain/services/reminder_scheduler.dart';
import 'package:loki/features/habits/domain/usecases/habit_usecases.dart';
import 'package:loki/features/habits/domain/usecases/streak_calculator.dart';
import 'package:loki/features/habits/presentation/controllers/habits_controller.dart';
import 'package:loki/features/habits/presentation/pages/habit_form_page.dart';
import 'package:loki/features/home/presentation/home_shell_page.dart';
import 'package:loki/features/life_plan/domain/repositories/life_plan_repository.dart';
import 'package:loki/features/life_plan/domain/usecases/life_plan_usecases.dart';
import 'package:loki/features/life_plan/presentation/controllers/life_plan_controller.dart';
import 'package:loki/features/statistics/domain/usecases/stats_usecases.dart';
import 'package:loki/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';
import 'package:loki/features/weaknesses/domain/repositories/weakness_repository.dart';
import 'package:loki/features/weaknesses/domain/usecases/weakness_usecases.dart';
import 'package:loki/features/weaknesses/presentation/controllers/weaknesses_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockHabitRepo extends Mock implements HabitRepository {}

class _MockLogRepo extends Mock implements HabitLogRepository {}

class _MockScheduler extends Mock implements ReminderScheduler {}

class _MockWeaknessRepo extends Mock implements WeaknessRepository {}

class _MockLifePlanRepo extends Mock implements LifePlanRepository {}

void main() {
  const viewports = <({String name, Size size})>[
    (name: 'narrow_mobile_360x740', size: Size(360, 740)),
    (name: 'standard_mobile_390x844', size: Size(390, 844)),
    (name: 'tablet_768x1024', size: Size(768, 1024)),
  ];

  Future<void> registerControllers() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final prefsService = PrefsService(prefs);

    final authRepo = _MockAuthRepo();
    when(
      () => authRepo.getCurrentUser(),
    ).thenReturn(const AuthUser(uid: 'u1', isAnonymous: true));
    when(() => authRepo.ensureSignedInAnonymously()).thenAnswer(
      (_) async => const Success(AuthUser(uid: 'u1', isAnonymous: true)),
    );

    final habitRepo = _MockHabitRepo();
    final logRepo = _MockLogRepo();
    final scheduler = _MockScheduler();
    when(
      () => scheduler.onReminderAction,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => scheduler.syncLocalTimezone(),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => scheduler.requestPermissionIfNeeded(),
    ).thenAnswer((_) async => const Success(true));
    when(() => habitRepo.getHabitsForDate(any())).thenAnswer(
      (_) async => Success([
        HabitWithSchedule(
          habit: Habit(
            id: 'h1',
            title: 'Học ngoại ngữ 25p/ngày',
            currentTarget: 'Tiếng Anh (Prep)',
            anchorHabitText: 'Sau khi uống cà phê sáng',
            targetDurationMinutes: 25,
            status: HabitStatus.active,
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
          activeSchedule: HabitScheduleVersion(
            id: 's1',
            habitId: 'h1',
            effectiveFrom: '2026-11-01',
            weekdaysMask: 127,
            createdAt: DateTime(2026, 11, 1),
          ),
          allSchedules: [
            HabitScheduleVersion(
              id: 's1',
              habitId: 'h1',
              effectiveFrom: '2026-11-01',
              weekdaysMask: 127,
              createdAt: DateTime(2026, 11, 1),
            ),
          ],
        ),
      ]),
    );
    when(
      () => habitRepo.getAllHabits(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => logRepo.getLogsByDate(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => logRepo.getLogsByMonth(any(), any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => logRepo.getLogsForHabit(any()),
    ).thenAnswer((_) async => const Success([]));

    final weaknessRepo = _MockWeaknessRepo();
    when(
      () => weaknessRepo.seedStarterWeaknessesIfEmpty(),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => weaknessRepo.getWeaknesses(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer(
      (_) async => Success([
        Weakness(
          id: 'w1',
          title: 'Tiếng Anh kém',
          actionOrientation: '20–30 phút/ngày: học đầy đủ theo lộ trình Prep',
          metricLabel: 'Số ngày học/tháng',
          status: WeaknessStatus.active,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        ),
      ]),
    );

    final lifeRepo = _MockLifePlanRepo();
    when(
      () => lifeRepo.getWheelAssessments(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => lifeRepo.getGoals(horizon: any(named: 'horizon')),
    ).thenAnswer((_) async => const Success([]));

    Get.put(
      AuthController(
        ensureAnonymous: EnsureAnonymousSessionUseCase(authRepo),
        linkAccount: LinkAccountUseCase(authRepo),
        authRepository: authRepo,
        prefsService: prefsService,
      ),
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
    Get.put(
      WeaknessesController(
        getWeaknesses: GetWeaknessesUseCase(weaknessRepo),
        saveWeakness: SaveWeaknessUseCase(weaknessRepo),
        archiveWeakness: ArchiveWeaknessUseCase(weaknessRepo),
        seedStarterWeaknesses: SeedStarterWeaknessesUseCase(weaknessRepo),
      ),
    );
    Get.put(
      StatisticsController(
        getDailyStats: GetDailyStatsUseCase(
          habitRepository: habitRepo,
          habitLogRepository: logRepo,
        ),
        getMonthlyStats: GetMonthlyStatsUseCase(
          habitRepository: habitRepo,
          habitLogRepository: logRepo,
          weaknessRepository: weaknessRepo,
        ),
      ),
    );
    Get.put(
      LifePlanController(
        getWheelAssessments: GetWheelAssessmentsUseCase(lifeRepo),
        saveWheelAssessment: SaveWheelAssessmentUseCase(lifeRepo),
        getGoals: GetGoalsUseCase(lifeRepo),
        saveGoalWithRevision: SaveGoalWithRevisionUseCase(lifeRepo),
        getGoalRevisions: GetGoalRevisionsUseCase(lifeRepo),
      ),
    );
  }

  Widget wrapCupertinoApp(Widget home) {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('vi', 'VN'),
      home: home,
      builder: (ctx, child) {
        final cupertinoTheme = AppTheme.cupertinoFor(Theme.of(ctx).brightness);
        return CupertinoTheme(
          data: cupertinoTheme,
          child: DefaultTextStyle(
            style: cupertinoTheme.textTheme.textStyle,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  for (final vp in viewports) {
    testWidgets(
      'All 4 Cupertino tabs + forms render cleanly without overflow on ${vp.name}',
      (tester) async {
        tester.view.physicalSize = vp.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await registerControllers();

        await tester.pumpWidget(wrapCupertinoApp(const HomeShellPage()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Switch through Weaknesses, Statistics, Life Plan, and Settings tabs
        for (final label in ['Điểm yếu', 'Thống kê', 'Kế hoạch', 'Cài đặt']) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          final err = tester.takeException();
          expect(err, isNull, reason: 'Tab $label at ${vp.name}: $err');
        }

        // Verify HabitFormPage & AccountSettingsPage have zero overflow
        await tester.pumpWidget(wrapCupertinoApp(const HabitFormPage()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(wrapCupertinoApp(const AccountSettingsPage()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
