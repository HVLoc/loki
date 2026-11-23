import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki/features/habits/data/repositories/habit_firestore_repository_impl.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/weaknesses/data/repositories/weakness_firestore_repository_impl.dart';
import 'package:loki/features/weaknesses/domain/usecases/weakness_usecases.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late WeaknessFirestoreRepositoryImpl weaknessRepo;
  late HabitFirestoreRepositoryImpl habitRepo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'uid-weak-1', isAnonymous: true),
    );
    weaknessRepo = WeaknessFirestoreRepositoryImpl(
      firestore: firestore,
      firebaseAuth: auth,
    );
    habitRepo = HabitFirestoreRepositoryImpl(
      firestore: firestore,
      firebaseAuth: auth,
    );
  });

  test('seeds 6 starter weaknesses idempotently', () async {
    final seed = SeedStarterWeaknessesUseCase(weaknessRepo);
    await seed();
    await seed();

    final res = await weaknessRepo.getWeaknesses();
    expect(res.isSuccess, isTrue);
    expect(res.dataOrNull!.length, 6);
  });

  test(
    'archiveWeakness unlinks habits when archiveLinkedHabits is false',
    () async {
      await SeedStarterWeaknessesUseCase(weaknessRepo)();
      final habit = Habit(
        id: 'h-eng',
        weaknessId: 'starter_english',
        title: 'Prep 25m',
        status: HabitStatus.active,
        createdAt: DateTime(2026, 11, 23),
        updatedAt: DateTime(2026, 11, 23),
      );
      await habitRepo.createHabit(
        habit,
        HabitScheduleVersion(
          id: 's1',
          habitId: 'h-eng',
          effectiveFrom: '2026-11-23',
          weekdaysMask: 127,
          createdAt: DateTime(2026, 11, 23),
        ),
      );

      await ArchiveWeaknessUseCase(weaknessRepo)(
        'starter_english',
        archiveLinkedHabits: false,
      );

      final remainingHabits = await habitRepo.getAllHabits();
      expect(remainingHabits.dataOrNull!.length, 1);
      expect(remainingHabits.dataOrNull!.first.weaknessId, isNull);
    },
  );
}
