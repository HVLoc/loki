# Feature Specification: Habit & Weakness Tracker

**Feature Branch**: `001-habit-weakness-tracker`

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Ứng dụng nhắc nhở xây dựng thói quen tốt. Khắc phục điểm yếu. Có tương tác và thống kê theo ngày, tháng." (kèm bảng 6 điểm yếu, định hướng khắc phục, chỉ số đo: Tiếng Anh kém, Khó duy trì thói quen - mốc 66 ngày & habit stacking, Giao tiếp ngoài công việc với cấp trên, Chưa có kế hoạch dài hạn - Bánh xe cuộc đời 8 khía cạnh & mục tiêu 1-3-5 năm, Học tập kiến thức mới, Đọc sách kinh doanh/kinh tế).

## Clarifications

### Session 2026-11-23

- Q: How should user identity and authentication work when storing data in Firebase? → A: Anonymous sign-in automatically on first launch, with optional Google or Email/Password account linking in Settings for backup and multi-device sync.
- Q: How should the app behave when the device is offline? → A: Full offline read/write capability with automatic cloud synchronization to Firebase when connectivity returns.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Daily Habit Check-in & Smart Reminders (Priority: P1)

As a user working to overcome personal weaknesses, I want to view my daily habits, receive timely
reminders, and interactively check them off (or log progress/skip) so that I can build consistency
without forgetting or feeling overwhelmed.

**Why this priority**: Daily execution and interactive reminders are the core loop of a habit-building
app; without this, no habit or weakness improvement can be tracked.

**Independent Test**: Can be fully tested by creating a habit with a reminder time, viewing it on
the Today screen, marking it completed (or skipped with a note), and verifying the daily status and
streak update immediately.

**Acceptance Scenarios**:

1. **Given** the user has active habits scheduled for today, **When** they open the Today view,
   **Then** they see each habit's name, target duration/action (e.g., "20–30 phút/ngày"), optional
   habit-stacking trigger ("Sau khi [thói quen cũ]"), and current streak.
2. **Given** a habit is due at a scheduled reminder time, **When** the reminder triggers, **Then**
   the user receives a notification with interactive quick actions to "Complete", "Snooze", or open
   the habit directly.
3. **Given** the user taps "Complete" on a habit for today, **When** the action is recorded,
   **Then** the habit is marked done for today, the consecutive scheduled-day streak increments,
   and an optional prompt allows logging extra metrics/notes without blocking the 1-tap completion.
4. **Given** the user cannot complete a habit today, **When** they mark it as "Skip" with an
   optional brief reason, **Then** the entry is logged as intentionally skipped and preserves
   (freezes) the current streak instead of resetting it to zero.

---

### User Story 2 - Weakness-to-Habit Mapping & Habit Stacking (Priority: P2)

As a user who has identified specific personal weaknesses, I want to manage my weaknesses, link
each weakness to concrete micro-habits and measurable indicators, and attach new habits to existing
routines (habit stacking) so that every daily action has clear purpose.

**Why this priority**: Directly addresses the user's core goal of turning identified weaknesses into
structured, actionable daily routines with measurable outcomes.

**Independent Test**: Can be tested by opening the Weaknesses section, reviewing/editing one of the
starter weaknesses (e.g., "Tiếng Anh kém"), adding or linking a habit with a habit-stacking anchor,
and verifying it appears in the daily schedule.

**Acceptance Scenarios**:

1. **Given** a first-time user opens the app, **When** onboarding completes, **Then** they can
   start with pre-populated editable weakness templates reflecting common growth areas (English,
   habit consistency, workplace networking, long-term planning, learning discipline, business/economics
   reading) or create custom weaknesses from scratch.
2. **Given** the user creates or edits a habit, **When** they link it to a weakness and optionally
   specify an existing anchor habit ("Sau khi..."), target duration (e.g., "2–5 phút/ngày"), and
   a measurable indicator (e.g., "Số ngày học/tháng", "Số sách đọc/tháng"), **Then** all linked
   details are saved and displayed in both the Weakness view and Today view.
3. **Given** the user updates a habit's schedule or frequency over time, **When** the change is
   saved, **Then** the new schedule takes effect from the change date forward while preserving all
   past daily and monthly statistics under the schedule active at that historical time.

---

### User Story 3 - Daily & Monthly Interactive Statistics (Priority: P3)

As a user tracking my self-improvement over time, I want to inspect interactive daily and monthly
statistics—including completion rates, streaks, calendar heatmaps, and weakness-specific metrics—so
that I can see my progress and spot drop-off patterns early.

**Why this priority**: Visual feedback and monthly aggregation sustain motivation beyond the 1-month
drop-off barrier and verify whether weaknesses are actually improving.

**Independent Test**: Can be tested by recording habit completions across multiple days and viewing
the Statistics tab to switch between Daily and Monthly views, tap specific calendar days, and filter
by weakness or habit.

**Acceptance Scenarios**:

1. **Given** the user opens the Daily Statistics view, **When** they select today or any past date,
   **Then** they see the completion percentage, completed vs. missed/skipped habits, and any logged
   notes or metric values for that day.
2. **Given** the user opens the Monthly Statistics view, **When** they browse a calendar month,
   **Then** they see a monthly completion heatmap/calendar, total active days in the month per
   habit, current and longest streak, and custom metric totals (e.g., English study days this
   month, business/economics books finished this month).
3. **Given** the user taps a specific day on the monthly calendar, **When** the day is selected,
   **Then** an interactive breakdown of that day's habits and reflections is shown without leaving
   the statistics screen.

---

### User Story 4 - Wheel of Life & 1–3–5 Year Goal Reviews (Priority: P4)

As a user without a clear long-term life plan, I want to score my 8 Wheel of Life dimensions,
define 1-year, 3-year, and 5-year goals with next-month action plans, and perform quarterly reviews
so that my daily habits stay aligned with my long-term direction.

**Why this priority**: Fulfills the long-term planning weakness ("Chưa có kế hoạch dài hạn cho cuộc
sống") while remaining cleanly separable from the daily habit core.

**Independent Test**: Can be tested by completing an 8-dimension Wheel of Life assessment, adding a
1-year goal with a next-month action item, and updating its completion percentage during a review.

**Acceptance Scenarios**:

1. **Given** the user opens the Life Plan section, **When** they rate the 8 life dimensions
   (e.g., Career, Finance, Health, Family, Personal Growth, Relationships, Recreation,
   Contribution) on a 1–10 scale, **Then** a visual Wheel of Life chart displays their current
   balance and highlights the lowest-scoring areas.
2. **Given** the user creates or updates long-term goals and work plans, **When** they modify a
   goal (1-year, 3-year, or 5-year horizon), target completion percentage, or "Next Month Plan",
   **Then** the updated plan is saved and the previous version is preserved in a revision history
   (with timestamp and optional reason) so changes over time remain traceable.
3. **Given** a quarterly review cycle arrives (or the user triggers a review manually), **When** they
   complete a quarterly review, **Then** the system records a snapshot of their Wheel of Life
   scores and annual goal completion percentage for historical comparison.

---

### Edge Cases

- What happens when the user misses multiple consecutive days? The current streak resets to 0
  without erasing historical completions, and the app offers a gentle "restart small (2–5 min)"
  prompt instead of punitive messaging.
- What happens when the user changes device timezone or travels across timezones? Daily check-ins
  and reminders anchor to the user's current local calendar date so days are not duplicated or lost.
- What happens when notification permissions are denied by the user? The app still functions fully
  with in-app visual due indicators and displays a non-intrusive banner explaining how to enable
  reminders in settings.
- What happens when a user archives or deletes a weakness that has linked habits? The user is
  prompted whether to keep the habits as unlinked/general habits or archive them together,
  preserving historical statistics.
- What happens when a habit has no activity in a selected month? Monthly statistics show 0% / empty
  state clearly without dividing by zero or hiding the habit unexpectedly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create, edit, pause/archive, and delete habits with a
  title, optional current action/target (e.g., book title or language focus), frequency (daily or
  specific weekdays), optional target duration/action, and optional habit-stacking anchor ("after
  existing habit..."). Schedule edits MUST apply from the effective change date forward without
  altering historical statistics; switching the active target MUST preserve streak continuity and
  record a target history entry (completed vs. switched).
- **FR-002**: System MUST allow users to create, edit, and archive personal weaknesses, each
  containing a description, action orientation, measurable indicators, and one or more linked
  habits.
- **FR-003**: System MUST provide editable starter templates during initial setup covering the
  six core weakness areas (English learning, habit retention & stacking, informal
  communication with superiors, Wheel of Life & 1–3–5 year planning, structured learning of new
  knowledge, and reading business/economics books).
- **FR-004**: System MUST support fast 1-tap daily check-ins for each scheduled habit: Complete,
  Skip (with optional reason), and Undo, plus optional (non-blocking) numeric/text metric logging
  (e.g., minutes studied, book progress, activity note).
- **FR-005**: System MUST allow users to configure per-habit reminder times and deliver local
  notifications with interactive quick actions (Complete, Snooze, Open).
- **FR-006**: System MUST compute and display real-time habit streaks (current streak and longest
  streak) evaluated across scheduled days only; unscheduled days and intentional Skips MUST preserve
  (freeze) the current streak without resetting it.
- **FR-007**: System MUST provide an interactive Daily Statistics view showing completion rate,
  completed/skipped/pending breakdown, and logged entries for any selected date.
- **FR-008**: System MUST provide an interactive Monthly Statistics view featuring a calendar
  heatmap, monthly completion rate, active days per month for each habit, and aggregated
  weakness indicators (e.g., books read per month, study days per month).
- **FR-009**: System MUST provide a Wheel of Life assessment across 8 customizable dimensions
  (1–10 rating) with visual comparison over time.
- **FR-010**: System MUST allow users to define, edit, and track 1-year, 3-year, and 5-year goals,
  next-month action plans, and quarterly review snapshots (% of annual goals achieved), preserving
  a timestamped revision history whenever plans or goals change over time.
- **FR-011**: System MUST persist all user habits, check-ins, weaknesses, goals, and statistics
  in user-scoped cloud storage (Firebase) with full offline read/write support and automatic
  synchronization when connectivity is restored.
- **FR-012**: System MUST automatically establish an anonymous user session on first launch so
  users can track immediately, and provide an optional Settings flow to link a Google or
  Email/Password account for multi-device backup and sync.

### Key Entities *(include if feature involves data)*

- **Weakness**: Represents an area for improvement (title, action orientation, measurable
  indicator definitions, status: active/archived).
- **Habit**: Represents a recurring action (title, linked weakness, habit-stacking anchor,
  target duration, schedule/weekdays with effective-from history, reminder time, current/best
  streak).
- **HabitLog**: Represents a single day's check-in for a habit (date, status:
  completed/skipped, optional numeric metric value, optional reflection note, timestamp).
- **WheelAssessment**: Represents a point-in-time evaluation across 8 life dimensions (assessment
  date, 8 dimension names and scores 1–10, review notes).
- **LongTermGoal**: Represents a 1-year, 3-year, or 5-year objective (title, horizon, linked
  dimension, next-month plan, progress percentage 0–100, quarterly review history, revision
  history).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete their daily habit check-in (marking 3–5 habits done) in under
  15 seconds from opening the app or tapping a reminder.
- **SC-002**: Users can create a new weakness-linked habit with a reminder and habit-stacking
  anchor in under 60 seconds.
- **SC-003**: Daily and Monthly statistics views render and respond to date/month switching
  instantly (under 300 milliseconds perceived response) for at least 2 years of daily history.
- **SC-004**: 100% of recorded habit check-ins, streaks, and Wheel of Life assessments persist
  accurately across app restarts and month transitions.
- **SC-005**: Users can complete an 8-dimension Wheel of Life assessment and view their balance
  chart in under 2 minutes.

## Assumptions

- **Cloud-Synced Offline-First Scope (v1)**: Data is stored in Firebase (scoped per
  authenticated user) with local offline persistence enabled so all daily check-ins and
  statistics work without internet and sync automatically when online.
- **Starter Templates**: The 6 weaknesses and metrics from the user's table are offered as
  pre-populated, fully editable starter items so the user can begin tracking immediately.
- **Language & Theme**: All user-facing copy supports localization (Vietnamese primary, English
  ready) and adapts to both Light and Dark themes.
- **Quarterly Review Cadence**: Quarterly reviews can be scheduled every 90 days or triggered
  on-demand by the user at any time.
