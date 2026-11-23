# Domain Repository & Service Contracts

**Feature**: `001-habit-weakness-tracker` | **Date**: 2026-11-23

All contracts live in `domain/repositories/` or `domain/services/` using pure Dart types and return
`Result<T, Failure>` (sealed `Success` / `Error`) so presentation controllers never catch raw
Firebase, platform, or network exceptions (`Constitution V`).

## 1. `AuthRepository`
- `Future<Result<AuthUser, Failure>> ensureSignedInAnonymously()`
- `Future<Result<AuthUser, Failure>> linkWithGoogle()`
- `Future<Result<AuthUser, Failure>> linkWithEmailPassword(String email, String password)`
- `Future<Result<AuthUser, Failure>> signInWithEmailPassword(String email, String password)`
- `Future<Result<void, Failure>> signOut()`
- `AuthUser? getCurrentUser()`
- `Stream<AuthUser?> watchAuthState()`

## 2. `WeaknessRepository`
- `Future<Result<List<Weakness>, Failure>> getWeaknesses({bool includeArchived = false})`
- `Future<Result<Weakness, Failure>> saveWeakness(Weakness weakness)`
- `Future<Result<void, Failure>> archiveWeakness(String weaknessId, {required bool archiveLinkedHabits})`
- `Future<Result<void, Failure>> seedStarterWeaknessesIfEmpty()`

## 3. `HabitRepository`
- `Future<Result<List<HabitWithSchedule>, Failure>> getHabitsForDate(String localDate)`
- `Future<Result<List<Habit>, Failure>> getAllHabits({bool includeArchived = false})`
- `Future<Result<Habit, Failure>> createHabit(Habit habit, HabitScheduleVersion initialSchedule)`
- `Future<Result<Habit, Failure>> updateHabitDetails(Habit habit)`
- `Future<Result<HabitScheduleVersion, Failure>> updateHabitSchedule(String habitId, HabitScheduleVersion newScheduleFromToday)`
- `Future<Result<void, Failure>> deleteOrArchiveHabit(String habitId, {required bool hardDelete})`

## 4. `HabitLogRepository`
- `Future<Result<HabitLog, Failure>> upsertLog(HabitLog log)` (1-tap Complete or Skip)
- `Future<Result<void, Failure>> deleteLog(String habitId, String localDate)` (Undo)
- `Future<Result<List<HabitLog>, Failure>> getLogsByDate(String localDate)`
- `Future<Result<List<HabitLog>, Failure>> getLogsByMonth(int year, int month)`
- `Future<Result<List<HabitLog>, Failure>> getLogsForHabit(String habitId)`

## 5. `LifePlanRepository`
- `Future<Result<List<WheelAssessment>, Failure>> getWheelAssessments()`
- `Future<Result<WheelAssessment, Failure>> saveWheelAssessment(WheelAssessment assessment)`
- `Future<Result<List<LongTermGoal>, Failure>> getGoals({GoalHorizon? horizon, bool includeArchived = false})`
- `Future<Result<LongTermGoal, Failure>> saveGoalWithRevision(LongTermGoal goal, {String? changeReason})`
- `Future<Result<List<GoalRevision>, Failure>> getGoalRevisions(String goalId)`

## 6. `ReminderScheduler` (Domain Port → `flutter_local_notifications` Adapter)
- `Future<Result<bool, Failure>> requestPermissionIfNeeded()`
- `Future<Result<void, Failure>> scheduleHabitReminder(Habit habit, HabitScheduleVersion schedule)`
- `Future<Result<void, Failure>> cancelHabitReminder(String habitId)`
- `Future<Result<void, Failure>> snoozeHabitReminder(String habitId, Duration delay)`
- `Stream<ReminderActionEvent> get onReminderAction` (`complete`, `snooze`, `open`)
