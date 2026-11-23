import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/app_logger.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';
import 'package:loki/features/life_plan/domain/repositories/life_plan_repository.dart';

class LifePlanFirestoreRepositoryImpl implements LifePlanRepository {
  LifePlanFirestoreRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String? get _uid => _firebaseAuth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _wheelCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('wheelAssessments');

  CollectionReference<Map<String, dynamic>> _goalsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('longTermGoals');

  @override
  Future<Result<List<WheelAssessment>, Failure>> getWheelAssessments() async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final snap = await _wheelCol(
        uid,
      ).orderBy('assessedAt', descending: true).get();
      return Success(snap.docs.map((d) => _wheelFromMap(d.data())).toList());
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<WheelAssessment, Failure>> saveWheelAssessment(
    WheelAssessment assessment,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      await _wheelCol(uid).doc(assessment.id).set(_wheelToMap(assessment));
      return Success(assessment);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<LongTermGoal>, Failure>> getGoals({
    GoalHorizon? horizon,
    bool includeArchived = false,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      Query<Map<String, dynamic>> query = _goalsCol(uid);
      if (horizon != null) {
        query = query.where('horizon', isEqualTo: horizon.name);
      }
      if (!includeArchived) {
        query = query.where(
          'status',
          whereIn: [GoalStatus.active.name, GoalStatus.completed.name],
        );
      }
      final snap = await query.get();
      return Success(snap.docs.map((d) => _goalFromMap(d.data())).toList());
    } on FirebaseException catch (e, st) {
      AppLogger.error('LifePlanRepo', 'getGoals failed', e, st);
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<LongTermGoal, Failure>> saveGoalWithRevision(
    LongTermGoal goal, {
    String? changeReason,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final goalRef = _goalsCol(uid).doc(goal.id);
      final revisionsRef = goalRef.collection('revisions');
      final existingRevs = await revisionsRef.get();
      final nextRevNum = existingRevs.docs.length + 1;

      final revision = GoalRevision(
        id: 'rev_$nextRevNum',
        goalId: goal.id,
        revisionNumber: nextRevNum,
        snapshotTitle: goal.title,
        snapshotHorizon: goal.horizon,
        snapshotNextMonthPlan: goal.nextMonthPlan,
        snapshotProgressPercent: goal.progressPercent,
        changeReason: changeReason,
        revisedAt: goal.updatedAt,
      );

      final batch = _firestore.batch();
      batch.set(goalRef, _goalToMap(goal));
      batch.set(revisionsRef.doc('$nextRevNum'), _revisionToMap(revision));
      await batch.commit();
      return Success(goal);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<GoalRevision>, Failure>> getGoalRevisions(
    String goalId,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final snap = await _goalsCol(uid)
          .doc(goalId)
          .collection('revisions')
          .orderBy('revisionNumber', descending: true)
          .get();
      return Success(snap.docs.map((d) => _revisionFromMap(d.data())).toList());
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  Map<String, dynamic> _wheelToMap(WheelAssessment w) => {
    'id': w.id,
    'assessedAt': Timestamp.fromDate(w.assessedAt),
    'quarterLabel': w.quarterLabel,
    'reviewNotes': w.reviewNotes,
    'scores': w.scores
        .map(
          (s) => {
            'dimensionKey': s.dimensionKey,
            'label': s.label,
            'score': s.score,
          },
        )
        .toList(),
  };

  WheelAssessment _wheelFromMap(Map<String, dynamic> map) {
    final rawScores = (map['scores'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (s) => WheelDimensionScore(
            dimensionKey: s['dimensionKey'] as String,
            label: s['label'] as String,
            score: s['score'] as int,
          ),
        )
        .toList();
    return WheelAssessment(
      id: map['id'] as String,
      assessedAt: (map['assessedAt'] as Timestamp).toDate(),
      quarterLabel: map['quarterLabel'] as String,
      reviewNotes: map['reviewNotes'] as String?,
      scores: rawScores,
    );
  }

  Map<String, dynamic> _goalToMap(LongTermGoal g) => {
    'id': g.id,
    'title': g.title,
    'horizon': g.horizon.name,
    'dimensionKey': g.dimensionKey,
    'nextMonthPlan': g.nextMonthPlan,
    'progressPercent': g.progressPercent,
    'status': g.status.name,
    'createdAt': Timestamp.fromDate(g.createdAt),
    'updatedAt': Timestamp.fromDate(g.updatedAt),
  };

  LongTermGoal _goalFromMap(Map<String, dynamic> map) => LongTermGoal(
    id: map['id'] as String,
    title: map['title'] as String,
    horizon: GoalHorizon.values.byName(map['horizon'] as String),
    dimensionKey: map['dimensionKey'] as String?,
    nextMonthPlan: map['nextMonthPlan'] as String,
    progressPercent: map['progressPercent'] as int,
    status: GoalStatus.values.byName(map['status'] as String),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> _revisionToMap(GoalRevision r) => {
    'id': r.id,
    'goalId': r.goalId,
    'revisionNumber': r.revisionNumber,
    'snapshotTitle': r.snapshotTitle,
    'snapshotHorizon': r.snapshotHorizon.name,
    'snapshotNextMonthPlan': r.snapshotNextMonthPlan,
    'snapshotProgressPercent': r.snapshotProgressPercent,
    'changeReason': r.changeReason,
    'revisedAt': Timestamp.fromDate(r.revisedAt),
  };

  GoalRevision _revisionFromMap(Map<String, dynamic> map) => GoalRevision(
    id: map['id'] as String,
    goalId: map['goalId'] as String,
    revisionNumber: map['revisionNumber'] as int,
    snapshotTitle: map['snapshotTitle'] as String,
    snapshotHorizon: GoalHorizon.values.byName(
      map['snapshotHorizon'] as String,
    ),
    snapshotNextMonthPlan: map['snapshotNextMonthPlan'] as String,
    snapshotProgressPercent: map['snapshotProgressPercent'] as int,
    changeReason: map['changeReason'] as String?,
    revisedAt: (map['revisedAt'] as Timestamp).toDate(),
  );
}
