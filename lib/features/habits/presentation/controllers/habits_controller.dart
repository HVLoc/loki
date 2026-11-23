import 'dart:async';

import 'package:get/get.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/entities/habit_target_history.dart';
import 'package:loki/features/habits/domain/services/reminder_scheduler.dart';
import 'package:loki/features/habits/domain/usecases/habit_usecases.dart';
import 'package:uuid/uuid.dart';

class HabitsController extends GetxController {
  HabitsController({
    required GetTodayHabitsUseCase getTodayHabits,
    required LogHabitCheckInUseCase logHabitCheckIn,
    required SaveHabitUseCase saveHabit,
    SwitchHabitTargetUseCase? switchHabitTarget,
    required ReminderScheduler reminderScheduler,
  }) : this._(
         getTodayHabits: getTodayHabits,
         logHabitCheckIn: logHabitCheckIn,
         saveHabit: saveHabit,
         switchHabitTarget: switchHabitTarget,
         reminderScheduler: reminderScheduler,
       );

  HabitsController._({
    required this._getTodayHabits,
    required this._logHabitCheckIn,
    required this._saveHabit,
    required this._switchHabitTarget,
    required this._reminderScheduler,
  });

  final GetTodayHabitsUseCase _getTodayHabits;
  final LogHabitCheckInUseCase _logHabitCheckIn;
  final SaveHabitUseCase _saveHabit;
  final SwitchHabitTargetUseCase? _switchHabitTarget;
  final ReminderScheduler _reminderScheduler;

  final RxList<TodayHabitItem> todayItems = <TodayHabitItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool notificationDenied = false.obs;

  StreamSubscription<ReminderActionEvent>? _reminderSub;
  static const Uuid _uuid = Uuid();

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
    loadTodayHabits();
  }

  Future<void> _initNotifications() async {
    await _reminderScheduler.syncLocalTimezone();
    final perm = await _reminderScheduler.requestPermissionIfNeeded();
    notificationDenied.value = !(perm.dataOrNull ?? true);
    _reminderSub = _reminderScheduler.onReminderAction.listen((event) async {
      final match = todayItems
          .where((item) => item.habit.id == event.habitId)
          .firstOrNull;
      if (match == null) return;
      if (event.action == ReminderActionType.complete) {
        await completeHabit(match.habit);
      } else if (event.action == ReminderActionType.snooze) {
        await _reminderScheduler.snoozeHabitReminder(
          match.habit.id,
          match.habit.title,
          const Duration(minutes: 15),
        );
      }
    });
  }

  Future<void> loadTodayHabits({DateTime? now}) async {
    isLoading.value = true;
    errorMessage.value = '';
    final res = await _getTodayHabits(now: now);
    res.fold(
      (items) => todayItems.assignAll(items),
      (failure) => errorMessage.value = failure.message,
    );
    isLoading.value = false;
  }

  Future<void> completeHabit(
    Habit habit, {
    DateTime? now,
    double? metricValue,
    String? note,
  }) async {
    final res = await _logHabitCheckIn.complete(
      habitId: habit.id,
      targetSnapshot: habit.currentTarget,
      now: now,
      metricValue: metricValue,
      note: note,
    );
    if (res.isFailure) {
      errorMessage.value = res.failureOrNull!.message;
      return;
    }
    await loadTodayHabits(now: now);
  }

  Future<void> skipHabit(Habit habit, {DateTime? now, String? reason}) async {
    final res = await _logHabitCheckIn.skip(
      habitId: habit.id,
      now: now,
      skipReason: reason,
    );
    if (res.isFailure) {
      errorMessage.value = res.failureOrNull!.message;
      return;
    }
    await loadTodayHabits(now: now);
  }

  Future<void> undoCheckIn(Habit habit, {DateTime? now}) async {
    final res = await _logHabitCheckIn.undo(habitId: habit.id, now: now);
    if (res.isFailure) {
      errorMessage.value = res.failureOrNull!.message;
      return;
    }
    await loadTodayHabits(now: now);
  }

  Future<bool> saveNewOrEditedHabit({
    Habit? existing,
    required String title,
    String? currentTarget,
    String? weaknessId,
    String? anchorHabitText,
    int? targetDurationMinutes,
    bool metricPromptEnabled = false,
    String? metricUnit,
    required int weekdaysMask,
    int? reminderTimeMinutes,
  }) async {
    final now = DateTime.now();
    final todayStr = LocalDateUtils.format(now);
    final normalizedTarget = currentTarget?.trim().isEmpty == true
        ? null
        : currentTarget?.trim();
    if (existing == null) {
      final habitId = _uuid.v4();
      final habit = Habit(
        id: habitId,
        weaknessId: weaknessId,
        title: title.trim(),
        currentTarget: normalizedTarget,
        anchorHabitText: anchorHabitText?.trim().isEmpty == true
            ? null
            : anchorHabitText?.trim(),
        targetDurationMinutes: targetDurationMinutes,
        metricPromptEnabled: metricPromptEnabled,
        metricUnit: metricUnit,
        status: HabitStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final schedule = HabitScheduleVersion(
        id: 'v_$todayStr',
        habitId: habitId,
        effectiveFrom: todayStr,
        weekdaysMask: weekdaysMask,
        reminderTimeMinutes: reminderTimeMinutes,
        createdAt: now,
      );
      final res = await _saveHabit.create(
        habit: habit,
        initialSchedule: schedule,
      );
      if (res.isFailure) {
        errorMessage.value = res.failureOrNull!.message;
        return false;
      }
    } else {
      final updated = existing.copyWith(
        weaknessId: weaknessId,
        clearWeaknessId: weaknessId == null,
        title: title.trim(),
        currentTarget: normalizedTarget,
        clearCurrentTarget: normalizedTarget == null,
        anchorHabitText: anchorHabitText?.trim(),
        targetDurationMinutes: targetDurationMinutes,
        metricPromptEnabled: metricPromptEnabled,
        metricUnit: metricUnit,
        updatedAt: now,
      );
      final newSchedule = HabitScheduleVersion(
        id: 'v_$todayStr',
        habitId: existing.id,
        effectiveFrom: todayStr,
        weekdaysMask: weekdaysMask,
        reminderTimeMinutes: reminderTimeMinutes,
        createdAt: now,
      );
      final res = await _saveHabit.update(
        habit: updated,
        newScheduleFromToday: newSchedule,
      );
      if (res.isFailure) {
        errorMessage.value = res.failureOrNull!.message;
        return false;
      }
    }
    await loadTodayHabits();
    return true;
  }

  Future<bool> switchTarget({
    required String habitId,
    required String? newTarget,
    required bool markPreviousCompleted,
  }) async {
    final useCase = _switchHabitTarget;
    if (useCase == null) return false;
    final res = await useCase(
      habitId: habitId,
      newTarget: newTarget,
      markPreviousCompleted: markPreviousCompleted,
    );
    if (res.isFailure) {
      errorMessage.value = res.failureOrNull!.message;
      return false;
    }
    await loadTodayHabits();
    return true;
  }

  Future<List<HabitTargetHistory>> fetchTargetHistory(String habitId) async {
    final useCase = _switchHabitTarget;
    if (useCase == null) return const [];
    final res = await useCase.history(habitId);
    return res.dataOrNull ?? const [];
  }

  @override
  void onClose() {
    _reminderSub?.cancel();
    super.onClose();
  }
}
