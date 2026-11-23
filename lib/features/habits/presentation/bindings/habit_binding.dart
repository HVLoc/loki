import 'package:get/get.dart';
import 'package:loki/features/habits/data/repositories/habit_firestore_repository_impl.dart';
import 'package:loki/features/habits/data/repositories/habit_log_firestore_repository_impl.dart';
import 'package:loki/features/habits/data/services/notification_adapter.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/habits/domain/services/reminder_scheduler.dart';
import 'package:loki/features/habits/domain/usecases/habit_usecases.dart';
import 'package:loki/features/habits/domain/usecases/streak_calculator.dart';
import 'package:loki/features/habits/presentation/controllers/habits_controller.dart';

class HabitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HabitRepository>(
      () => HabitFirestoreRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut<HabitLogRepository>(
      () => HabitLogFirestoreRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut<ReminderScheduler>(() => NotificationAdapter(), fenix: true);
    Get.lazyPut(
      () => GetTodayHabitsUseCase(
        habitRepository: Get.find<HabitRepository>(),
        habitLogRepository: Get.find<HabitLogRepository>(),
        streakCalculator: const StreakCalculator(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => LogHabitCheckInUseCase(Get.find<HabitLogRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SaveHabitUseCase(
        Get.find<HabitRepository>(),
        Get.find<ReminderScheduler>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => SwitchHabitTargetUseCase(Get.find<HabitRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => HabitsController(
        getTodayHabits: Get.find<GetTodayHabitsUseCase>(),
        logHabitCheckIn: Get.find<LogHabitCheckInUseCase>(),
        saveHabit: Get.find<SaveHabitUseCase>(),
        switchHabitTarget: Get.find<SwitchHabitTargetUseCase>(),
        reminderScheduler: Get.find<ReminderScheduler>(),
      ),
      fenix: true,
    );
  }
}
