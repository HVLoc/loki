import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki/features/habits/data/repositories/habit_firestore_repository_impl.dart';
import 'package:loki/features/habits/data/repositories/habit_log_firestore_repository_impl.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late HabitFirestoreRepositoryImpl habitRepo;
  late HabitLogFirestoreRepositoryImpl logRepo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'uid-test-1', isAnonymous: true),
    );
    habitRepo = HabitFirestoreRepositoryImpl(
      firestore: fakeFirestore,
      firebaseAuth: mockAuth,
    );
    logRepo = HabitLogFirestoreRepositoryImpl(
      firestore: fakeFirestore,
      firebaseAuth: mockAuth,
    );
  });

  test(
    'createHabit and getHabitsForDate return active habit with schedule',
    () async {
      final habit = Habit(
        id: 'h-english',
        weaknessId: 'starter_english',
        title: 'Học Tiếng Anh Prep',
        anchorHabitText: 'Sau khi uống cà phê sáng',
        targetDurationMinutes: 25,
        metricPromptEnabled: false,
        status: HabitStatus.active,
        createdAt: DateTime(2026, 11, 23),
        updatedAt: DateTime(2026, 11, 23),
      );
      final schedule = HabitScheduleVersion(
        id: 'sch-1',
        habitId: 'h-english',
        effectiveFrom: '2026-11-23',
        weekdaysMask: 127,
        reminderTimeMinutes: 8 * 60,
        createdAt: DateTime(2026, 11, 23),
      );

      final createRes = await habitRepo.createHabit(habit, schedule);
      expect(createRes.isSuccess, isTrue);

      final forToday = await habitRepo.getHabitsForDate('2026-11-23');
      expect(forToday.isSuccess, isTrue);
      expect(forToday.dataOrNull!.length, 1);
      expect(forToday.dataOrNull!.first.habit.title, 'Học Tiếng Anh Prep');
      expect(
        forToday.dataOrNull!.first.activeSchedule.reminderTimeMinutes,
        480,
      );
    },
  );

  test(
    'upsertLog and deleteLog are idempotent per habitId + logDate',
    () async {
      final log = HabitLog(
        id: 'h-english_2026-11-23',
        habitId: 'h-english',
        logDate: '2026-11-23',
        status: HabitLogStatus.completed,
        metricValue: 25,
        loggedAt: DateTime(2026, 11, 23, 8, 30),
      );

      final upserted = await logRepo.upsertLog(log);
      expect(upserted.isSuccess, isTrue);

      final byDate = await logRepo.getLogsByDate('2026-11-23');
      expect(byDate.dataOrNull!.length, 1);
      expect(byDate.dataOrNull!.first.metricValue, 25);

      final deleted = await logRepo.deleteLog('h-english', '2026-11-23');
      expect(deleted.isSuccess, isTrue);

      final afterDelete = await logRepo.getLogsByDate('2026-11-23');
      expect(afterDelete.dataOrNull, isEmpty);
    },
  );

  test(
    'switchHabitTarget preserves habit & records completed/switched history',
    () async {
      final habit = Habit(
        id: 'h-book',
        title: 'Đọc sách kinh doanh',
        currentTarget: 'Quyển A',
        status: HabitStatus.active,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );
      await habitRepo.createHabit(
        habit,
        HabitScheduleVersion(
          id: 'sch-book',
          habitId: 'h-book',
          effectiveFrom: '2026-11-01',
          weekdaysMask: 127,
          createdAt: DateTime(2026, 11, 1),
        ),
      );

      final switched = await habitRepo.switchHabitTarget(
        habitId: 'h-book',
        newTarget: 'Quyển B',
        markPreviousCompleted: true,
      );
      expect(switched.isSuccess, isTrue);
      expect(switched.dataOrNull!.currentTarget, 'Quyển B');

      final history = await habitRepo.getTargetHistory('h-book');
      expect(history.isSuccess, isTrue);
      expect(history.dataOrNull!.length, 1);
      expect(history.dataOrNull!.first.targetTitle, 'Quyển A');
      expect(history.dataOrNull!.first.outcome.name, 'completed');
    },
  );
}
