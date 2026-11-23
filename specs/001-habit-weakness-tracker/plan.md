# Implementation Plan: Habit & Weakness Tracker

**Branch**: `001-habit-weakness-tracker` | **Date**: 2026-11-23 | **Spec**: [spec.md](file:///Users/lochv/LocHV_Data/github_repo/loki/specs/001-habit-weakness-tracker/spec.md)

**Input**: Feature specification from `/specs/001-habit-weakness-tracker/spec.md`

## Summary

Build an offline-first, Firebase-synced Flutter mobile application (`loki`) for personal habit
formation, weakness remediation, interactive daily/monthly statistics, and Wheel of Life + 1–3–5
year goal planning. The architecture follows **Clean Architecture** (`domain` / `data` /
`presentation`) with **GetX** for state management, lazy `Bindings` dependency injection, named
routing, and i18n `Translations`, backed by **Firebase Authentication** (anonymous-first with
optional Google/Email linking) and **Cloud Firestore** (offline persistence enabled) for
forward-only habit schedule versioning, scheduled-day streak evaluation (with Skip freeze), and
goal revision history.

## Technical Context

**Language/Version**: Flutter `3.44.7` (stable channel, Dart sound null-safety, `flutter_lints`)

**Primary Dependencies**: `get` (state, DI, named routes, i18n), `dio` (core HTTP client per constitution stack), `flutter_secure_storage`, `shared_preferences`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `flutter_local_notifications`, `timezone`, `fl_chart`, `uuid`

**Storage**: `cloud_firestore` (offline persistence enabled, user-scoped `users/{uid}/...` collections), `shared_preferences` (theme/locale), `flutter_secure_storage` (local sensitive keys/tokens)

**Testing**: `flutter_test`, `mocktail`, `fake_cloud_firestore`, `firebase_auth_mocks` (pure Dart unit tests for Domain use cases & streak/schedule logic, GetX controller tests with `Get.testMode = true` + `Get.reset()`, widget tests)

**Target Platform**: iOS 14+ & Android API 24+

**Project Type**: Mobile app (Flutter)

**Performance Goals**: < 15s daily check-in flow (`SC-001`), < 300ms Daily/Monthly statistics switching from Firestore offline cache across 2+ years of history (`SC-003`), 60 fps scrolling and chart rendering

**Constraints**: Offline-first read/write with automatic Firebase cloud sync (`FR-011`), anonymous-first auth with optional account linking (`FR-012`), Light & Dark `ThemeData`, `vi_VN`/`en_US` i18n, WCAG-compliant contrast + `Semantics` + 48x48dp touch targets, `ui-ux-pro-max` design standards

**Scale/Scope**: Single-user scoped Firestore dataset (`users/{uid}/...`, ~10–50 habits, 2+ years of daily logs, 4 primary tabs + Settings account linking)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Standard | Status | Plan Alignment |
|----------------------|--------|----------------|
| I. Clean Architecture & Feature Modularity | PASS | `domain/` (pure Dart, zero Firebase/GetX imports), `data/` (Firestore/Auth/Notification adapters), `presentation/` (GetX) |
| II. GetX State, DI & Navigation Discipline | PASS | `Bindings` per route, centralized named routes, no `BuildContext` in controllers, narrow `Obx` |
| III. Test-Driven Quality (NON-NEGOTIABLE) | PASS | Unit tests for domain & streak engine, repository tests with `fake_cloud_firestore`, controller & widget tests |
| IV. Simplicity & YAGNI | PASS | Direct Firestore SDK + manual mappers (zero build_runner codegen), anonymous-first auth |
| V. Observability & Defensive Error Handling | PASS | `Result<T, Failure>` mapping `FirebaseAuthException` & `FirebaseException`, structured logger, no PII/tokens in logs |
| Technical Constraints (Flutter 3.44.7, Security, UI/UX) | PASS | Pinned `3.44.7`, Firestore user-scoped rules, `flutter_secure_storage`, Light/Dark `ThemeData`, i18n, `Semantics` |

*Post-Phase 1 Re-Check*: No violations introduced by `data-model.md` or `contracts/domain-repositories.md`. `AuthRepository` cleanly isolates `firebase_auth` behind a pure Dart interface, and `fake_cloud_firestore` + `firebase_auth_mocks` keep unit/widget tests 100% offline and deterministic.

## Project Structure

### Documentation (this feature)

```text
specs/001-habit-weakness-tracker/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── domain-repositories.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── main.dart
├── app.dart
├── firebase_options.dart # Generated via flutterfire configure (gitignored/env-scoped if private)
├── core/
│   ├── constants/        # AppRoutes, AppKeys, StarterTemplates
│   ├── error/            # Failure, Result<T, Failure>
│   ├── firebase/         # FirebaseBootstrap (Firestore persistence config)
│   ├── i18n/             # AppTranslations (vi_VN, en_US)
│   ├── network/          # Dio client setup (reserved per constitution)
│   ├── storage/          # SecureStorageService, PrefsService
│   ├── theme/            # AppTheme (Light & Dark ThemeData, design tokens)
│   └── utils/            # LocalDateUtils, AppLogger
└── features/
    ├── auth/
    │   ├── domain/       # AuthUser entity, AuthRepository, EnsureAnonymousSessionUseCase, LinkAccountUseCase
    │   ├── data/         # FirebaseAuthRepositoryImpl
    │   └── presentation/ # AccountSettingsSheet/Page, AuthController, AuthBinding
    ├── habits/
    │   ├── domain/       # Habit, HabitScheduleVersion, HabitLog, Repos, StreakCalculator, UseCases
    │   ├── data/         # Firestore models/mappers, HabitFirestoreRepositoryImpl, HabitLogFirestoreRepositoryImpl, NotificationAdapter
    │   └── presentation/ # TodayPage, HabitFormPage, HabitsController, HabitBinding, widgets
    ├── weaknesses/
    │   ├── domain/       # Weakness entity, WeaknessRepository, UseCases
    │   ├── data/         # WeaknessFirestoreRepositoryImpl
    │   └── presentation/ # WeaknessesPage, WeaknessDetailPage, WeaknessesController, WeaknessBinding, widgets
    ├── statistics/
    │   ├── domain/       # DailySummary, MonthlySummary, GetDailyStatsUseCase, GetMonthlyStatsUseCase
    │   ├── data/         # Stats aggregation helper over Firestore-backed repositories
    │   └── presentation/ # StatisticsPage, StatisticsController, StatsBinding, MonthlyHeatmapWidget
    └── life_plan/
        ├── domain/       # WheelAssessment, LongTermGoal, GoalRevision, LifePlanRepository, UseCases
        ├── data/         # LifePlanFirestoreRepositoryImpl (batch revision snapshots)
        └── presentation/ # LifePlanPage, WheelRadarWidget, GoalRevisionSheet, LifePlanController, Binding

test/
├── features/
│   ├── auth/             # AuthRepositoryImpl (firebase_auth_mocks) & AuthController tests
│   ├── habits/           # StreakCalculator, HabitFirestoreRepository (fake_cloud_firestore), HabitsController, TodayPage tests
│   ├── weaknesses/       # Starter seeding & archive flow tests
│   ├── statistics/       # Daily/Monthly aggregation & 2-year query performance benchmark tests
│   └── life_plan/        # Wheel scoring & GoalRevision history tests
└── core/                 # LocalDateUtils & Result tests
```

**Structure Decision**: Feature-first Clean Architecture under `lib/features/<feature>/` paired with
shared infrastructure in `lib/core/` and mirrored test directories under `test/`. Firebase Auth and
Cloud Firestore are encapsulated strictly inside `data/` implementations so `domain/` and
`presentation/` remain decoupled and testable offline.

## Complexity Tracking

> No Constitution violations; table intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
