import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loki/core/constants/starter_templates.dart';
import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/app_logger.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';
import 'package:loki/features/weaknesses/domain/repositories/weakness_repository.dart';

class WeaknessFirestoreRepositoryImpl implements WeaknessRepository {
  WeaknessFirestoreRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String? get _uid => _firebaseAuth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _weaknessesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('weaknesses');

  CollectionReference<Map<String, dynamic>> _habitsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('habits');

  @override
  Future<Result<List<Weakness>, Failure>> getWeaknesses({
    bool includeArchived = false,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      Query<Map<String, dynamic>> query = _weaknessesCol(uid);
      if (!includeArchived) {
        query = query.where('status', isEqualTo: WeaknessStatus.active.name);
      }
      final snap = await query.get();
      return Success(snap.docs.map((d) => _fromMap(d.data())).toList());
    } on FirebaseException catch (e, st) {
      AppLogger.error('WeaknessRepo', 'getWeaknesses failed', e, st);
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<Weakness, Failure>> saveWeakness(Weakness weakness) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      await _weaknessesCol(uid).doc(weakness.id).set(_toMap(weakness));
      return Success(weakness);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> archiveWeakness(
    String weaknessId, {
    required bool archiveLinkedHabits,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final batch = _firestore.batch();
      batch.update(_weaknessesCol(uid).doc(weaknessId), {
        'status': WeaknessStatus.archived.name,
        'updatedAt': Timestamp.now(),
      });

      final linked = await _habitsCol(
        uid,
      ).where('weaknessId', isEqualTo: weaknessId).get();
      for (final doc in linked.docs) {
        if (archiveLinkedHabits) {
          batch.update(doc.reference, {
            'status': HabitStatus.archived.name,
            'updatedAt': Timestamp.now(),
          });
        } else {
          batch.update(doc.reference, {
            'weaknessId': null,
            'updatedAt': Timestamp.now(),
          });
        }
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> seedStarterWeaknessesIfEmpty() async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final existing = await _weaknessesCol(uid).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return const Success(null);
      }
      final now = DateTime.now();
      final batch = _firestore.batch();
      for (final item in StarterTemplates.weaknesses) {
        final w = Weakness(
          id: item.id,
          title: item.title,
          actionOrientation: item.actionOrientation,
          metricLabel: item.metricLabel,
          metricUnit: item.metricUnit,
          status: WeaknessStatus.active,
          isStarterTemplate: true,
          createdAt: now,
          updatedAt: now,
        );
        batch.set(_weaknessesCol(uid).doc(w.id), _toMap(w));
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  Map<String, dynamic> _toMap(Weakness w) => {
    'id': w.id,
    'title': w.title,
    'actionOrientation': w.actionOrientation,
    'metricLabel': w.metricLabel,
    'metricUnit': w.metricUnit,
    'status': w.status.name,
    'isStarterTemplate': w.isStarterTemplate,
    'createdAt': Timestamp.fromDate(w.createdAt),
    'updatedAt': Timestamp.fromDate(w.updatedAt),
  };

  Weakness _fromMap(Map<String, dynamic> map) => Weakness(
    id: map['id'] as String,
    title: map['title'] as String,
    actionOrientation: map['actionOrientation'] as String,
    metricLabel: map['metricLabel'] as String?,
    metricUnit: map['metricUnit'] as String?,
    status: WeaknessStatus.values.byName(map['status'] as String),
    isStarterTemplate: (map['isStarterTemplate'] as bool?) ?? false,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
  );
}
