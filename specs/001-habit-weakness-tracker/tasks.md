---

description: "Actionable, dependency-ordered task list for Habit & Weakness Tracker (Firebase + Clean Architecture + GetX)"
---

# Tasks: Habit & Weakness Tracker

**Input**: Design documents from `/specs/001-habit-weakness-tracker/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/domain-repositories.md`, `quickstart.md`

**Tests**: Required by Constitution Principle III (Test-Driven Quality - NON-NEGOTIABLE). Write unit, repository (`fake_cloud_firestore` / `firebase_auth_mocks`), controller, and widget tests FIRST and verify they fail before implementation.

**Organization**: Tasks are grouped by user story so each story can be implemented, tested, and demonstrated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Exact file paths are included in every task description.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize Flutter `3.44.7` project structure, Firebase & GetX dependencies, and strict linting.

- [X] T001 Initialize Flutter project and `pubspec.yaml` pinning Flutter `3.44.7` and dependencies (`get`, `dio`, `flutter_secure_storage`, `shared_preferences`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `flutter_local_notifications`, `timezone`, `fl_chart`, `uuid`, `mocktail`, `fake_cloud_firestore`, `firebase_auth_mocks`) in `pubspec.yaml`
- [X] T002 [P] Configure strict static analysis with `flutter_lints` in `analysis_options.yaml`
- [X] T003 [P] Create Clean Architecture directory skeleton (`lib/core/`, `lib/features/auth/`, `lib/features/habits/`, `lib/features/weaknesses/`, `lib/features/statistics/`, `lib/features/life_plan/`, `test/`) per `plan.md`
- [X] T004 Create app entry points and `GetMaterialApp` bootstrap (initializing `FirebaseBootstrap` and anonymous session before home shell) in `lib/main.dart` and `lib/app.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure, Firebase offline persistence, and Anonymous-first Auth required before any user story.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 [P] Write unit tests for `LocalDateUtils` and `Result<T, Failure>` in `test/core/utils/local_date_utils_test.dart`
- [X] T006 [P] Write unit tests for `FirebaseAuthRepositoryImpl` (auto anonymous sign-in, Google/Email linking, error mapping) using `firebase_auth_mocks` in `test/features/auth/data/firebase_auth_repository_impl_test.dart`
- [X] T007 [P] Implement `Failure` hierarchy (including Firebase Auth/Firestore failure mapping) and sealed `Result<T, Failure>` in `lib/core/error/failures.dart` and `lib/core/error/result.dart`
- [X] T008 [P] Implement `LocalDateUtils` (local `YYYY-MM-DD` formatting, weekday mask helpers, month bounds) and `AppLogger` (redacting tokens/PII) in `lib/core/utils/local_date_utils.dart` and `lib/core/utils/app_logger.dart`
- [X] T009 Implement `FirebaseBootstrap` configuring `FirebaseFirestore.instance.settings` with `persistenceEnabled: true` and `CACHE_SIZE_UNLIMITED` in `lib/core/firebase/firebase_bootstrap.dart`
- [X] T010 [P] Implement `SecureStorageService`, `PrefsService`, and reserved `DioClient` in `lib/core/storage/secure_storage_service.dart`, `lib/core/storage/prefs_service.dart`, and `lib/core/network/dio_client.dart`
- [X] T011 [P] Implement `AuthUser` entity, `AuthRepository` interface, `EnsureAnonymousSessionUseCase`, `LinkAccountUseCase`, and `FirebaseAuthRepositoryImpl` in `lib/features/auth/`
- [X] T012 [P] Implement Light & Dark `ThemeData` tokens following `ui-ux-pro-max` and `AppTranslations` (`vi_VN`, `en_US`) in `lib/core/theme/app_theme.dart` and `lib/core/i18n/app_translations.dart`
- [X] T013 Implement centralized `AppRoutes`, `AppPages`, `AuthBinding`/`AuthController` (Settings account-linking sheet), and 4-tab home navigation shell in `lib/core/constants/app_routes.dart`, `lib/core/constants/app_pages.dart`, `lib/features/auth/presentation/`, and `lib/features/home/presentation/home_shell_page.dart`

**Checkpoint**: Foundation + Firebase offline cache + Anonymous Auth ready — user story implementation can now begin.

---

## Phase 3: User Story 1 - Daily Habit Check-in & Smart Reminders (Priority: P1) 🎯 MVP

**Goal**: Users can view today's scheduled habits, receive interactive local reminders, perform fast 1-tap Complete or Skip (preserving streak), and create/edit habits with forward-only schedules synced to Firestore.

**Independent Test**: Create a habit with a reminder time, view it on Today tab, tap Complete (or Skip with reason) offline or online, and verify streak & Today status update immediately.

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T014 [P] [US1] Write unit tests for `StreakCalculator` (scheduled-day evaluation, Skip freeze, unscheduled day skip-over, forward-only `HabitScheduleVersion`) in `test/features/habits/domain/streak_calculator_test.dart`
- [X] T015 [P] [US1] Write Firestore repository tests for `HabitFirestoreRepositoryImpl` & `HabitLogFirestoreRepositoryImpl` using `fake_cloud_firestore` in `test/features/habits/data/habit_firestore_repository_test.dart`
- [X] T016 [P] [US1] Write `HabitsController` unit tests (`Get.testMode = true`, `Get.reset()` teardown, 1-tap complete, skip, undo) in `test/features/habits/presentation/habits_controller_test.dart`
- [X] T017 [P] [US1] Write `TodayPage` widget test covering 1-tap check-in, Skip dialog, and empty state in `test/features/habits/presentation/today_page_test.dart`

### Implementation for User Story 1

- [X] T018 [P] [US1] Create pure Dart entities `Habit`, `HabitScheduleVersion`, and `HabitLog` in `lib/features/habits/domain/entities/habit.dart`, `lib/features/habits/domain/entities/habit_schedule_version.dart`, and `lib/features/habits/domain/entities/habit_log.dart`
- [X] T019 [P] [US1] Create `HabitRepository`, `HabitLogRepository`, and `ReminderScheduler` contracts in `lib/features/habits/domain/repositories/habit_repository.dart`, `lib/features/habits/domain/repositories/habit_log_repository.dart`, and `lib/features/habits/domain/services/reminder_scheduler.dart`
- [X] T020 [US1] Implement `StreakCalculator` and habit use cases (`GetTodayHabitsUseCase`, `LogHabitCheckInUseCase`, `SaveHabitUseCase`, `UpdateHabitScheduleUseCase`) in `lib/features/habits/domain/usecases/`
- [X] T021 [P] [US1] Implement Firestore DTO mappers for `Habit`, `HabitScheduleVersion`, and `HabitLog` (`users/{uid}/habits/...` and `users/{uid}/habitLogs/{habitId}_{logDate}`) in `lib/features/habits/data/models/`
- [X] T022 [US1] Implement `HabitFirestoreRepositoryImpl` and `HabitLogFirestoreRepositoryImpl` in `lib/features/habits/data/repositories/habit_firestore_repository_impl.dart` and `lib/features/habits/data/repositories/habit_log_firestore_repository_impl.dart`
- [X] T023 [US1] Implement `NotificationAdapter` (`flutter_local_notifications` + `timezone` with Complete/Snooze/Open actions and `tz.local` re-sync on app resume) in `lib/features/habits/data/services/notification_adapter.dart`
- [X] T024 [US1] Implement `HabitBinding` and `HabitsController` in `lib/features/habits/presentation/bindings/habit_binding.dart` and `lib/features/habits/presentation/controllers/habits_controller.dart`
- [X] T025 [US1] Build `TodayPage` with narrow `Obx` habit cards, 1-tap check-in, and streak badges in `lib/features/habits/presentation/pages/today_page.dart`
- [X] T026 [US1] Build optional non-blocking metric/note & Skip-reason bottom sheet in `lib/features/habits/presentation/widgets/habit_action_sheets.dart`
- [X] T027 [US1] Build `HabitFormPage` (create/edit habit, weekdays, duration, reminder time, forward-only schedule update) in `lib/features/habits/presentation/pages/habit_form_page.dart`

**Checkpoint**: User Story 1 (MVP) is fully functional, offline-capable, synced to Firestore, and independently testable.

---

## Phase 4: User Story 2 - Weakness-to-Habit Mapping & Habit Stacking (Priority: P2)

**Goal**: Users start with 6 editable starter weakness templates under `users/{uid}/weaknesses/`, link habits with habit-stacking anchors ("Sau khi..."), and manage weakness archiving safely.

**Independent Test**: Open Weaknesses tab, review the 6 pre-seeded weaknesses, add/link a habit with an anchor cue, and verify it displays in both Weaknesses and Today tabs.

### Tests for User Story 2 ⚠️

- [X] T028 [P] [US2] Write unit & `fake_cloud_firestore` repository tests for `SeedStarterWeaknessesUseCase` and `ArchiveWeaknessUseCase` in `test/features/weaknesses/domain/weakness_usecases_test.dart`
- [X] T029 [P] [US2] Write `WeaknessesController` and `WeaknessesPage` widget tests in `test/features/weaknesses/presentation/weaknesses_page_test.dart`

### Implementation for User Story 2

- [X] T030 [P] [US2] Create `Weakness` entity and `WeaknessRepository` interface in `lib/features/weaknesses/domain/entities/weakness.dart` and `lib/features/weaknesses/domain/repositories/weakness_repository.dart`
- [X] T031 [P] [US2] Define the 6 starter weakness templates from `spec.md` in `lib/core/constants/starter_templates.dart`
- [X] T032 [US2] Implement `WeaknessModel` and `WeaknessFirestoreRepositoryImpl` (`users/{uid}/weaknesses/{weaknessId}`) in `lib/features/weaknesses/data/`
- [X] T033 [US2] Implement weakness use cases (`GetWeaknessesUseCase`, `SaveWeaknessUseCase`, `ArchiveWeaknessUseCase`, `SeedStarterWeaknessesUseCase`) in `lib/features/weaknesses/domain/usecases/`
- [X] T034 [US2] Implement `WeaknessBinding` and `WeaknessesController` in `lib/features/weaknesses/presentation/bindings/weakness_binding.dart` and `lib/features/weaknesses/presentation/controllers/weaknesses_controller.dart`
- [X] T035 [US2] Build `WeaknessesPage` and `WeaknessDetailPage` (with linked habits & archive prompt) in `lib/features/weaknesses/presentation/pages/weaknesses_page.dart` and `lib/features/weaknesses/presentation/pages/weakness_detail_page.dart`
- [X] T036 [US2] Extend `HabitFormPage` and `TodayPage` cards to select linked weakness and display habit-stacking anchor cues in `lib/features/habits/presentation/pages/habit_form_page.dart`
- [X] T037 [US2] Trigger `SeedStarterWeaknessesUseCase` after anonymous session initialization on first run in `lib/app.dart`

**Checkpoint**: User Stories 1 AND 2 work independently and integrate cleanly.

---

## Phase 5: User Story 3 - Daily & Monthly Interactive Statistics (Priority: P3)

**Goal**: Users inspect interactive Daily and Monthly statistics (completion rates, monthly calendar heatmap, active days/month, and weakness-specific metric totals) under 300ms from Firestore cache.

**Independent Test**: Log completions across multiple dates, open Statistics tab, switch Daily/Monthly views, tap a calendar day, and verify inline breakdown updates in < 300ms.

### Tests for User Story 3 ⚠️

- [X] T038 [P] [US3] Write unit & benchmark tests for `GetDailyStatsUseCase` and `GetMonthlyStatsUseCase` (historical schedule resolution, empty-month 0% handling, 2-year ~35k-log <300ms benchmark) in `test/features/statistics/domain/stats_usecases_test.dart`
- [X] T039 [P] [US3] Write `StatisticsController` and `StatisticsPage` widget tests (tapping heatmap day cell) in `test/features/statistics/presentation/statistics_page_test.dart`

### Implementation for User Story 3

- [X] T040 [P] [US3] Create `DailySummary` and `MonthlySummary` domain entities in `lib/features/statistics/domain/entities/daily_summary.dart` and `lib/features/statistics/domain/entities/monthly_summary.dart`
- [X] T041 [P] [US3] Implement `StatsAggregationService` helper over `HabitRepository`, `HabitLogRepository`, and `WeaknessRepository` in `lib/features/statistics/data/stats_aggregation_service.dart`
- [X] T042 [US3] Implement `GetDailyStatsUseCase` and `GetMonthlyStatsUseCase` in `lib/features/statistics/domain/usecases/get_daily_stats_use_case.dart` and `lib/features/statistics/domain/usecases/get_monthly_stats_use_case.dart`
- [X] T043 [US3] Implement `StatsBinding` and `StatisticsController` in `lib/features/statistics/presentation/bindings/stats_binding.dart` and `lib/features/statistics/presentation/controllers/statistics_controller.dart`
- [X] T044 [US3] Build interactive `MonthlyHeatmapWidget` (7-column tappable calendar grid with theme tokens and `Semantics`) in `lib/features/statistics/presentation/widgets/monthly_heatmap_widget.dart`
- [X] T045 [US3] Build `StatisticsPage` with Daily/Monthly switcher, inline selected-day breakdown, and per-weakness metric totals in `lib/features/statistics/presentation/pages/statistics_page.dart`
- [X] T046 [US3] Add `fl_chart` monthly completion trend chart in `lib/features/statistics/presentation/widgets/monthly_trend_chart.dart`
- [X] T047 [US3] Wire `StatsBinding` into `AppPages` and `HomeShellPage` tab 3 in `lib/core/constants/app_pages.dart`

**Checkpoint**: Daily & Monthly statistics work accurately and fast across historical schedule changes.

---

## Phase 6: User Story 4 - Wheel of Life & 1–3–5 Year Goal Reviews (Priority: P4)

**Goal**: Users score 8 Wheel of Life dimensions (1–10), manage 1–3–5 year goals & next-month plans with full Firestore `WriteBatch` revision history, and record quarterly reviews.

**Independent Test**: Score 8 Wheel of Life dimensions, create a 1-year goal with a next-month plan, edit it with a reason, and verify both versions appear in revision history.

### Tests for User Story 4 ⚠️

- [X] T048 [P] [US4] Write unit & `fake_cloud_firestore` tests for `SaveGoalWithRevisionUseCase` and `SaveWheelAssessmentUseCase` in `test/features/life_plan/domain/life_plan_usecases_test.dart`
- [X] T049 [P] [US4] Write `LifePlanController` and `LifePlanPage` widget tests in `test/features/life_plan/presentation/life_plan_page_test.dart`

### Implementation for User Story 4

- [X] T050 [P] [US4] Create `WheelAssessment`, `LongTermGoal`, `GoalRevision`, and `LifePlanRepository` in `lib/features/life_plan/domain/entities/` and `lib/features/life_plan/domain/repositories/life_plan_repository.dart`
- [X] T051 [US4] Implement `LifePlanFirestoreRepositoryImpl` (`users/{uid}/wheelAssessments/` and `users/{uid}/longTermGoals/{goalId}/revisions/` using Firestore `WriteBatch`) in `lib/features/life_plan/data/`
- [X] T052 [US4] Implement life-plan use cases (`GetWheelAssessmentsUseCase`, `SaveWheelAssessmentUseCase`, `GetGoalsUseCase`, `SaveGoalWithRevisionUseCase`, `GetGoalRevisionsUseCase`) in `lib/features/life_plan/domain/usecases/`
- [X] T053 [US4] Implement `LifePlanBinding` and `LifePlanController` in `lib/features/life_plan/presentation/bindings/life_plan_binding.dart` and `lib/features/life_plan/presentation/controllers/life_plan_controller.dart`
- [X] T054 [US4] Build `WheelRadarWidget` (`fl_chart` `RadarChart` + 8-dimension sliders) in `lib/features/life_plan/presentation/widgets/wheel_radar_widget.dart`
- [X] T055 [US4] Build `LifePlanPage` (1–3–5 year tabs, next-month plan, quarterly review snapshot) and `GoalRevisionSheet` in `lib/features/life_plan/presentation/pages/life_plan_page.dart` and `lib/features/life_plan/presentation/widgets/goal_revision_sheet.dart`
- [X] T056 [US4] Wire `LifePlanBinding` into `AppPages` and `HomeShellPage` tab 4 in `lib/core/constants/app_pages.dart`

**Checkpoint**: All 4 user stories are independently functional and testable.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility, localization, theme consistency, Firebase security rules, and final Constitution Quality Gates.

- [X] T057 [P] Document & add Firestore Security Rules (`users/{uid}/...` strict owner-only access) in `firestore.rules`
- [X] T058 [P] Audit `Semantics` labels, 48x48dp touch targets, and Light/Dark contrast across all 4 feature modules + Settings account linking
- [X] T059 [P] Verify `vi_VN` and `en_US` translations cover 100% of user-facing strings in `lib/core/i18n/app_translations.dart`
- [X] T060 Add graceful notification-permission-denied banner and settings shortcut in `lib/features/habits/presentation/pages/today_page.dart`
- [X] T061 Run `dart format --output=none --set-exit-if-changed .` and `flutter analyze` with zero errors/warnings
- [X] T062 Run full `flutter test` suite and verify all scenarios in `specs/001-habit-weakness-tracker/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS** all user stories (includes `FirebaseBootstrap` & `AuthRepository` anonymous session).
- **User Stories (Phase 3+)**: All depend on Phase 2 completion.
  - Recommended sequential MVP order: `US1 (P1)` → `US2 (P2)` → `US3 (P3)` → `US4 (P4)`.
  - `US4` is fully independent of `US1–US3` and can run in parallel once Phase 2 is done.
- **Polish (Final Phase)**: Depends on all desired user stories being complete.

### Parallel Example: User Story 1

```bash
# Run US1 test tasks in parallel first (TDD):
T014: StreakCalculator unit test in test/features/habits/domain/streak_calculator_test.dart
T015: HabitFirestoreRepositoryImpl test (fake_cloud_firestore)
T016: HabitsController unit test in test/features/habits/presentation/habits_controller_test.dart
T017: TodayPage widget test in test/features/habits/presentation/today_page_test.dart

# Create US1 domain entities & contracts in parallel:
T018: Habit, HabitScheduleVersion, HabitLog entities
T019: HabitRepository, HabitLogRepository, ReminderScheduler interfaces
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete **Phase 1 (Setup)** and **Phase 2 (Foundational)** (Firebase Auth + Firestore offline persistence).
2. Complete **Phase 3 (US1 — Daily Habit Check-in & Smart Reminders)**.
3. **STOP and VALIDATE**: Run `flutter test` and verify US1 offline + cloud sync end-to-end before moving to US2.

### Incremental Delivery
1. Foundation (`Phase 1–2`) → Ready.
2. Add `US1` → Daily check-in + reminders + streak MVP.
3. Add `US2` → 6 starter weaknesses + habit stacking.
4. Add `US3` → Daily/Monthly interactive heatmap & metric totals.
5. Add `US4` → Wheel of Life + 1–3–5 year goals with revision history.
6. Final `Phase 7` → `firestore.rules`, Accessibility, i18n, Quality Gates (`dart format`, `flutter analyze`, `flutter test`).
