import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki/features/life_plan/data/repositories/life_plan_firestore_repository_impl.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';
import 'package:loki/features/life_plan/domain/usecases/life_plan_usecases.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late LifePlanFirestoreRepositoryImpl repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'uid-life-1', isAnonymous: true),
    );
    repo = LifePlanFirestoreRepositoryImpl(
      firestore: firestore,
      firebaseAuth: auth,
    );
  });

  test('saves WheelAssessment with 8 dimensions', () async {
    final scores = List.generate(
      8,
      (i) => WheelDimensionScore(
        dimensionKey: 'd_$i',
        label: 'Dim $i',
        score: (i % 10) + 1,
      ),
    );
    final saveWheel = SaveWheelAssessmentUseCase(repo);
    final res = await saveWheel(
      WheelAssessment(
        id: 'w1',
        assessedAt: DateTime(2026, 11, 23),
        quarterLabel: '2026-Q4',
        scores: scores,
      ),
    );

    expect(res.isSuccess, isTrue);
    final loaded = await repo.getWheelAssessments();
    expect(loaded.dataOrNull!.length, 1);
    expect(loaded.dataOrNull!.first.scores.length, 8);
  });

  test(
    'saveGoalWithRevision records revision history on every edit (Q2: B)',
    () async {
      final saveGoal = SaveGoalWithRevisionUseCase(repo);
      final v1 = LongTermGoal(
        id: 'g1',
        title: 'Đọc 12 sách kinh doanh',
        horizon: GoalHorizon.oneYear,
        nextMonthPlan: 'Đọc 1 cuốn trong tháng 12',
        progressPercent: 10,
        status: GoalStatus.active,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );
      await saveGoal(v1, changeReason: 'Khởi tạo mục tiêu');

      final v2 = LongTermGoal(
        id: 'g1',
        title: 'Đọc 12 sách kinh doanh & kinh tế',
        horizon: GoalHorizon.oneYear,
        nextMonthPlan: 'Đọc 2 cuốn trong tháng 12',
        progressPercent: 25,
        status: GoalStatus.active,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 23),
      );
      await saveGoal(v2, changeReason: 'Tăng tốc kế hoạch tháng tới');

      final revs = await repo.getGoalRevisions('g1');
      expect(revs.isSuccess, isTrue);
      expect(revs.dataOrNull!.length, 2);
      expect(revs.dataOrNull!.first.revisionNumber, 2);
      expect(
        revs.dataOrNull!.first.changeReason,
        'Tăng tốc kế hoạch tháng tới',
      );
      expect(revs.dataOrNull!.last.snapshotProgressPercent, 10);
    },
  );
}
