import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/app_logger.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/data/models/habit_firestore_models.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/repositories/habit_log_repository.dart';

class HabitLogFirestoreRepositoryImpl implements HabitLogRepository {
  HabitLogFirestoreRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> _logsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('habitLogs');

  String? get _uid => _firebaseAuth.currentUser?.uid;

  @override
  Future<Result<HabitLog, Failure>> upsertLog(HabitLog log) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final docId = '${log.habitId}_${log.logDate}';
      await _logsCol(uid).doc(docId).set(HabitFirestoreMapper.logToMap(log));
      return Success(log);
    } on FirebaseException catch (e, st) {
      AppLogger.error('HabitLogRepo', 'upsertLog failed', e, st);
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteLog(
    String habitId,
    String localDate,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      await _logsCol(uid).doc('${habitId}_$localDate').delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<HabitLog>, Failure>> getLogsByDate(
    String localDate,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final snap = await _logsCol(
        uid,
      ).where('logDate', isEqualTo: localDate).get();
      return Success(
        snap.docs
            .map((d) => HabitFirestoreMapper.logFromMap(d.data()))
            .toList(),
      );
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<HabitLog>, Failure>> getLogsByMonth(
    int year,
    int month,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final bounds = LocalDateUtils.monthBounds(year, month);
      final snap = await _logsCol(uid)
          .where('logDate', isGreaterThanOrEqualTo: bounds.start)
          .where('logDate', isLessThanOrEqualTo: bounds.end)
          .get();
      return Success(
        snap.docs
            .map((d) => HabitFirestoreMapper.logFromMap(d.data()))
            .toList(),
      );
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<HabitLog>, Failure>> getLogsForHabit(
    String habitId,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final snap = await _logsCol(
        uid,
      ).where('habitId', isEqualTo: habitId).get();
      return Success(
        snap.docs
            .map((d) => HabitFirestoreMapper.logFromMap(d.data()))
            .toList(),
      );
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }
}
