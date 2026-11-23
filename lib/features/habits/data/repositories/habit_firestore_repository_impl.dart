import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/app_logger.dart';
import 'package:loki/features/habits/data/models/habit_firestore_models.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/entities/habit_target_history.dart';
import 'package:loki/features/habits/domain/repositories/habit_repository.dart';
import 'package:loki/features/habits/domain/usecases/streak_calculator.dart';

class HabitFirestoreRepositoryImpl implements HabitRepository {
  HabitFirestoreRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> _habitsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('habits');

  CollectionReference<Map<String, dynamic>> _schedulesCol(
    String uid,
    String habitId,
  ) => _habitsCol(uid).doc(habitId).collection('scheduleVersions');

  String? get _uid => _firebaseAuth.currentUser?.uid;

  @override
  Future<Result<List<HabitWithSchedule>, Failure>> getHabitsForDate(
    String localDate,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final habitsSnap = await _habitsCol(
        uid,
      ).where('status', isEqualTo: HabitStatus.active.name).get();

      final items = <HabitWithSchedule>[];
      for (final doc in habitsSnap.docs) {
        final habit = HabitFirestoreMapper.habitFromMap(doc.data());
        final schSnap = await _schedulesCol(
          uid,
          habit.id,
        ).orderBy('effectiveFrom').get();
        final allSchedules = schSnap.docs
            .map((d) => HabitFirestoreMapper.scheduleFromMap(d.data()))
            .toList();
        final active = StreakCalculator.resolveScheduleForDate(
          allSchedules,
          localDate,
        );
        if (active != null) {
          items.add(
            HabitWithSchedule(
              habit: habit,
              activeSchedule: active,
              allSchedules: allSchedules,
            ),
          );
        }
      }
      return Success(items);
    } on FirebaseException catch (e, st) {
      AppLogger.error('HabitRepo', 'getHabitsForDate failed', e, st);
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e, st) {
      AppLogger.error('HabitRepo', 'getHabitsForDate unexpected', e, st);
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Habit>, Failure>> getAllHabits({
    bool includeArchived = false,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      Query<Map<String, dynamic>> query = _habitsCol(uid);
      if (!includeArchived) {
        query = query.where(
          'status',
          whereIn: [HabitStatus.active.name, HabitStatus.paused.name],
        );
      }
      final snap = await query.get();
      final habits = snap.docs
          .map((d) => HabitFirestoreMapper.habitFromMap(d.data()))
          .toList();
      return Success(habits);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<HabitScheduleVersion>, Failure>> getScheduleVersions(
    String habitId,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final snap = await _schedulesCol(
        uid,
        habitId,
      ).orderBy('effectiveFrom').get();
      return Success(
        snap.docs
            .map((d) => HabitFirestoreMapper.scheduleFromMap(d.data()))
            .toList(),
      );
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<Habit, Failure>> createHabit(
    Habit habit,
    HabitScheduleVersion initialSchedule,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final batch = _firestore.batch();
      batch.set(
        _habitsCol(uid).doc(habit.id),
        HabitFirestoreMapper.habitToMap(habit),
      );
      batch.set(
        _schedulesCol(uid, habit.id).doc(initialSchedule.id),
        HabitFirestoreMapper.scheduleToMap(initialSchedule),
      );
      await batch.commit();
      return Success(habit);
    } on FirebaseException catch (e, st) {
      AppLogger.error('HabitRepo', 'createHabit failed', e, st);
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<Habit, Failure>> updateHabitDetails(Habit habit) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      await _habitsCol(uid)
          .doc(habit.id)
          .set(HabitFirestoreMapper.habitToMap(habit), SetOptions(merge: true));
      return Success(habit);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<HabitScheduleVersion, Failure>> updateHabitSchedule(
    String habitId,
    HabitScheduleVersion newScheduleFromToday,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      // Forward-only: use effectiveFrom as doc ID if edited multiple times today
      final docId = 'v_${newScheduleFromToday.effectiveFrom}';
      await _schedulesCol(uid, habitId)
          .doc(docId)
          .set(HabitFirestoreMapper.scheduleToMap(newScheduleFromToday));
      return Success(newScheduleFromToday);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<Habit, Failure>> switchHabitTarget({
    required String habitId,
    required String? newTarget,
    required bool markPreviousCompleted,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final docRef = _habitsCol(uid).doc(habitId);
      final snap = await docRef.get();
      if (!snap.exists || snap.data() == null) {
        return const FailureResult(StorageFailure('Habit not found'));
      }
      final existing = HabitFirestoreMapper.habitFromMap(snap.data()!);
      final now = DateTime.now();
      final batch = _firestore.batch();

      final prevTarget = existing.currentTarget;
      if (prevTarget != null && prevTarget.trim().isNotEmpty) {
        final historyId = 'th_${now.microsecondsSinceEpoch}';
        final entry = HabitTargetHistory(
          id: historyId,
          habitId: habitId,
          targetTitle: prevTarget,
          outcome: markPreviousCompleted
              ? TargetOutcome.completed
              : TargetOutcome.switched,
          endedAt: now,
        );
        batch.set(
          docRef.collection('targetHistory').doc(historyId),
          HabitFirestoreMapper.targetHistoryToMap(entry),
        );
      }

      final updated = existing.copyWith(
        currentTarget: newTarget,
        clearCurrentTarget: newTarget == null,
        updatedAt: now,
      );
      batch.set(docRef, HabitFirestoreMapper.habitToMap(updated));
      await batch.commit();
      return Success(updated);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<HabitTargetHistory>, Failure>> getTargetHistory(
    String habitId,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      final snap = await _habitsCol(uid)
          .doc(habitId)
          .collection('targetHistory')
          .orderBy('endedAt', descending: true)
          .get();
      return Success(
        snap.docs
            .map((d) => HabitFirestoreMapper.targetHistoryFromMap(d.data()))
            .toList(),
      );
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteOrArchiveHabit(
    String habitId, {
    required bool hardDelete,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('User not authenticated'));
    }
    try {
      if (hardDelete) {
        await _habitsCol(uid).doc(habitId).delete();
      } else {
        await _habitsCol(uid).doc(habitId).update({
          'status': HabitStatus.archived.name,
          'updatedAt': Timestamp.now(),
        });
      }
      return const Success(null);
    } on FirebaseException catch (e) {
      return FailureResult(StorageFailure(e.message ?? e.code, code: e.code));
    } catch (e) {
      return FailureResult(StorageFailure(e.toString()));
    }
  }
}
