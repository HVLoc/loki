# Research & Technical Decisions: Habit & Weakness Tracker

**Feature**: `001-habit-weakness-tracker` | **Date**: 2026-11-23

## 1. Cloud Persistence & Offline Sync (`cloud_firestore` + `firebase_auth`)

- **Decision**: Use **Cloud Firestore** (`cloud_firestore`) with built-in offline persistence enabled (`persistenceEnabled: true`, `cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED`) paired with **Firebase Authentication** (`firebase_auth` + `google_sign_in`), while keeping `shared_preferences` for lightweight UI preferences (theme mode, locale) and `flutter_secure_storage` for any local sensitive tokens/keys.
- **Rationale**:
  - Satisfies **FR-011** & **FR-012**: Users start immediately via automatic Anonymous sign-in (`signInAnonymously()`), read/write seamlessly offline from Firestore's local cache (<300ms perceived response for `SC-003`), and automatically sync to the cloud when connectivity returns.
  - Users can upgrade their anonymous account later via `linkWithCredential()` (Google or Email/Password) in Settings without losing existing habits, logs, or goals.
  - Deterministic document IDs (`users/{uid}/habitLogs/{habitId}_{YYYY-MM-DD}`) make 1-tap Complete, Skip, and Undo idempotent even across offline/online transitions.
- **Alternatives considered**:
  - `sqflite` local-only: Does not satisfy cloud backup or multi-device sync (`FR-011`, `FR-012`).
  - Firebase Realtime Database: Less expressive for range queries on `logDate` and lacks Firestore's structured subcollections and offline query cache ergonomics.

## 2. Forward-Only Habit Schedule Versioning & Streak Evaluation

- **Decision**: Store habit schedule changes as append-only documents in `users/{uid}/habits/{habitId}/scheduleVersions/{versionId}` (`effectiveFrom` local date `YYYY-MM-DD`, `weekdaysMask`, `reminderTimeMinutes`), and compute streaks dynamically from `HabitLog` + active schedule version for each calendar date.
- **Rationale**:
  - Satisfies **Q1 (A)**: Editing a habit's frequency or reminder creates/updates a schedule version effective from today onward; historical dates resolve against the schedule version active on that date, so past monthly completion percentages never drift retroactively.
  - Satisfies **Q3 (A)**: Streak calculation walks backward from today across **scheduled dates only**:
    - `completed` → increments streak.
    - `skipped` (intentional skip with optional reason) → **freezes** streak (does not increment, does not reset).
    - unscheduled day → skipped over without breaking streak.
    - missed scheduled day (before today, no log) → breaks streak at 0.
- **Alternatives considered**:
  - Mutating `Habit.weekdays` in place: Retroactively corrupts past completion rates.

## 3. Local Interactive Notifications (`flutter_local_notifications` + `timezone`)

- **Decision**: Use `flutter_local_notifications` paired with `timezone` for local scheduled reminders and interactive notification actions (`COMPLETE`, `SNOOZE_15M`, `OPEN`), syncing `tz.local` on app launch/resume.
- **Rationale**:
  - Reliable local delivery on iOS/Android even when offline, with direct notification shade quick actions (`FR-005`, `SC-001`).
  - Graceful fallback banner when notification permission is denied.
- **Alternatives considered**:
  - FCM server-scheduled push notifications: Requires backend Cloud Functions/cron infrastructure unnecessary for per-device local reminders.

## 4. Charts & Interactive Monthly Heatmap (`fl_chart` + Custom Calendar Grid)

- **Decision**: Use `fl_chart` for the 8-axis Wheel of Life `RadarChart` and monthly trend charts, and build a lightweight custom `MonthlyHeatmapWidget` in Flutter for interactive day-cell tapping.
- **Rationale**:
  - Pure Flutter, integrates cleanly with Light/Dark `ThemeData` tokens and `Semantics` accessibility labels.

## 5. Clean Architecture + GetX + Testability with Firebase

- **Decision**: Feature-first Clean Architecture under `lib/features/<feature>/` (`domain/`, `data/`, `presentation/`) plus `lib/core/` (`firebase/`, `theme/`, `i18n/`, `routes/`, `error/`).
- **Rationale**:
  - Domain entities, repository interfaces (`AuthRepository`, `WeaknessRepository`, `HabitRepository`, `HabitLogRepository`, `LifePlanRepository`), and use cases remain **100% pure Dart** with zero `firebase_*` or `get` imports (`Constitution I & III`).
  - Data layer repositories wrap `FirebaseFirestore` / `FirebaseAuth` using `fake_cloud_firestore` and `firebase_auth_mocks` in unit tests so `flutter test` runs fast and deterministically offline without hitting live Firebase servers.
