# Quickstart & Validation Guide: Habit & Weakness Tracker

**Feature**: `001-habit-weakness-tracker` | **Date**: 2026-11-23

## Prerequisites

- **Flutter SDK**: `3.44.7` (stable channel, sound null-safety)
- **Target Platforms**: iOS 14+ / Android API 24+
- **Firebase Project**: Configured via FlutterFire (`flutterfire configure` or `--dart-define` / platform configs without committing sensitive server keys) with **Authentication** (Anonymous, Google, Email/Password) and **Cloud Firestore** enabled.
- **Dependencies**: `get`, `dio`, `flutter_secure_storage`, `shared_preferences`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `flutter_local_notifications`, `timezone`, `fl_chart`, `uuid`

## Setup & Verification Commands

```bash
# 1. Install dependencies
flutter pub get

# 2. Verify formatting & static analysis (Constitution Quality Gate)
dart format --output=none --set-exit-if-changed .
flutter analyze

# 3. Run unit & widget tests (uses fake_cloud_firestore & firebase_auth_mocks)
flutter test

# 4. Run on simulator/emulator
flutter run
```

## End-to-End Validation Scenarios

1. **Anonymous Start & Starter Templates (FR-012, US2)**:
   - Launch fresh app → verify anonymous Firebase session is created automatically without blocking onboarding, and 6 starter weaknesses are seeded under `users/{uid}/weaknesses/`.
2. **Offline 1-Tap Check-in & Cloud Sync (FR-011, US1)**:
   - Turn on Airplane Mode → tap "Complete" on Today tab → verify instant completion and streak update.
   - Mark another habit "Skip" with reason → verify streak freezes.
   - Reconnect internet → verify Firestore automatically syncs pending writes to the cloud.
3. **Optional Account Linking (FR-012)**:
   - Open Settings → link anonymous session with Google or Email/Password → verify existing habits, logs, and goals remain intact under the linked account.
4. **Interactive Daily & Monthly Statistics (US3)**:
   - Open Statistics → toggle Daily/Monthly views → tap a calendar heatmap day → verify inline breakdown renders in < 300ms from Firestore local cache.
5. **Wheel of Life & Goal Revision History (US4)**:
   - Rate all 8 dimensions (`1..10`) → verify RadarChart updates.
   - Create and edit a 1-year goal with a change reason → verify `revisions` subcollection stores both versions with timestamps.
