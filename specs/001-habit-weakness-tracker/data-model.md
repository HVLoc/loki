# Data Model: Habit & Weakness Tracker

**Feature**: `001-habit-weakness-tracker` | **Date**: 2026-11-23

## 1. Domain Entities (Pure Dart)

### `AuthUser`
Represents the current user's identity state.
- `uid`: `String` (Firebase Auth UID)
- `isAnonymous`: `bool`
- `email`: `String?`
- `displayName`: `String?`

### `Weakness`
Represents a personal growth area or weakness to overcome.
- `id`: `String` (UUID)
- `title`: `String` (non-empty, max 120 chars; e.g., `"Tiếng Anh kém"`)
- `actionOrientation`: `String` (concrete direction; e.g., `"20–30 phút/ngày: học đầy đủ theo lộ trình của Prep"`)
- `metricLabel`: `String?` (optional primary metric label; e.g., `"Số ngày học/tháng"`, `"Số sách đọc trong tháng"`)
- `metricUnit`: `String?` (optional unit; e.g., `"ngày"`, `"cuốn"`, `"phút"`)
- `status`: `WeaknessStatus` (`active`, `archived`)
- `isStarterTemplate`: `bool`
- `createdAt`: `DateTime`
- `updatedAt`: `DateTime`

### `Habit`
Represents a recurring habit optionally linked to a `Weakness` and an existing anchor habit (habit stacking).
- `id`: `String` (UUID)
- `weaknessId`: `String?` (nullable reference → `Weakness.id`)
- `title`: `String` (non-empty, max 120 chars)
- `anchorHabitText`: `String?` (optional habit-stacking cue, e.g., `"Sau khi uống cà phê sáng"`)
- `targetDurationMinutes`: `int?` (optional, > 0; e.g., `25` or `5`)
- `metricPromptEnabled`: `bool` (default `false` for 1-tap completion; `true` for habits like book reading)
- `metricUnit`: `String?` (e.g., `"phút"`, `"trang"`, `"cuốn"`)
- `status`: `HabitStatus` (`active`, `paused`, `archived`)
- `createdAt`: `DateTime`
- `updatedAt`: `DateTime`

### `HabitScheduleVersion`
Append-only schedule configuration enabling forward-only edits (**Q1: A**) without altering past statistics.
- `id`: `String` (UUID)
- `habitId`: `String`
- `effectiveFrom`: `String` (local calendar date `YYYY-MM-DD`)
- `weekdaysMask`: `int` (7-bit mask Mon=1..Sun=64; `127` = daily)
- `reminderTimeMinutes`: `int?` (minutes since midnight `0..1439`, or `null` if reminder off)
- `createdAt`: `DateTime`

**Resolution rule**: For any local date `D`, the active schedule for `habitId` is the `HabitScheduleVersion` with the largest `effectiveFrom <= D`.

### `HabitLog`
Represents a single local calendar day's check-in for a habit.
- `id`: `String` (deterministic `${habitId}_$logDate`)
- `habitId`: `String`
- `logDate`: `String` (local calendar date `YYYY-MM-DD`)
- `status`: `HabitLogStatus` (`completed`, `skipped`)
- `skipReason`: `String?` (optional when `status == skipped`)
- `metricValue`: `double?` (optional numeric entry, e.g., `30` minutes or `1` book)
- `note`: `String?` (optional reflection note)
- `loggedAt`: `DateTime`

### `WheelAssessment`
Point-in-time Wheel of Life evaluation across 8 customizable dimensions.
- `id`: `String` (UUID)
- `assessedAt`: `DateTime`
- `quarterLabel`: `String` (e.g., `"2026-Q4"`)
- `scores`: `List<WheelDimensionScore>` (exactly 8 items: `dimensionKey`, `label`, `score` in `1..10`)
- `reviewNotes`: `String?`

### `LongTermGoal` & `GoalRevision`
Supports 1-year, 3-year, and 5-year goals plus next-month action plans with full change history (**Q2: B**).
- `LongTermGoal`:
  - `id`: `String` (UUID)
  - `title`: `String` (non-empty)
  - `horizon`: `GoalHorizon` (`oneYear`, `threeYears`, `fiveYears`)
  - `dimensionKey`: `String?` (optional link to a Wheel of Life dimension)
  - `nextMonthPlan`: `String` (concrete upcoming-month action plan)
  - `progressPercent`: `int` (`0..100`)
  - `status`: `GoalStatus` (`active`, `completed`, `archived`)
  - `createdAt`: `DateTime`
  - `updatedAt`: `DateTime`
- `GoalRevision`:
  - `id`: `String` (UUID)
  - `goalId`: `String`
  - `revisionNumber`: `int` (monotonic `1, 2, ...`)
  - `snapshotTitle`: `String`
  - `snapshotHorizon`: `GoalHorizon`
  - `snapshotNextMonthPlan`: `String`
  - `snapshotProgressPercent`: `int`
  - `changeReason`: `String?` (optional note explaining why the plan changed)
  - `revisedAt`: `DateTime`

## 2. Cloud Firestore Collection Hierarchy & Security Rules

All user data is strictly scoped under `users/{uid}/`:

```text
users/{uid}/
├── weaknesses/{weaknessId}
├── habits/{habitId}
│   └── scheduleVersions/{versionId}
├── habitLogs/{habitId}_{logDate}
├── wheelAssessments/{assessmentId}
└── longTermGoals/{goalId}
    └── revisions/{revisionNumber}
```

### Firestore Security Rules Principle
- `allow read, write: if request.auth != null && request.auth.uid == uid;`
- Offline persistence enabled (`Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)`), ensuring all reads/writes succeed immediately offline and sync automatically when online.

## 3. State Transitions & Business Rules

### Daily Check-in State Machine (`HabitLog` for date `D`)
- `pending` (no `HabitLog` for `D`) → `completed` (1-tap Complete, optional metric/note)
- `pending` → `skipped` (Skip with optional reason; freezes streak)
- `completed` or `skipped` → `pending` (Undo deletes `habitLogs/{habitId}_{D}` and recalculates streak)

### Streak Calculation (**Q3: A**)
- Evaluated backward from `today` (or `today - 1` if `today` is still pending) over calendar dates `d >= earliestEffectiveFrom`:
  1. Look up `HabitScheduleVersion` active on `d`. If `d` is **not** scheduled in `weekdaysMask`, skip `d`.
  2. Look up `HabitLog` for `(habitId, d)`:
     - `completed` → `streak += 1`.
     - `skipped` → **freeze** (`streak` unchanged, continue walking backward).
     - `null` (missed scheduled day before today) → stop.
- `longestStreak`: Maximum consecutive scheduled-day `completed` run across all history (with `skipped` freezing rather than breaking).
