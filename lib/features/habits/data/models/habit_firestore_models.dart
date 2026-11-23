import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loki/features/habits/domain/entities/habit.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/entities/habit_schedule_version.dart';
import 'package:loki/features/habits/domain/entities/habit_target_history.dart';

class HabitFirestoreMapper {
  HabitFirestoreMapper._();

  static Map<String, dynamic> habitToMap(Habit h) => {
    'id': h.id,
    'weaknessId': h.weaknessId,
    'title': h.title,
    'currentTarget': h.currentTarget,
    'anchorHabitText': h.anchorHabitText,
    'targetDurationMinutes': h.targetDurationMinutes,
    'metricPromptEnabled': h.metricPromptEnabled,
    'metricUnit': h.metricUnit,
    'status': h.status.name,
    'createdAt': Timestamp.fromDate(h.createdAt),
    'updatedAt': Timestamp.fromDate(h.updatedAt),
  };

  static Habit habitFromMap(Map<String, dynamic> map) => Habit(
    id: map['id'] as String,
    weaknessId: map['weaknessId'] as String?,
    title: map['title'] as String,
    currentTarget: map['currentTarget'] as String?,
    anchorHabitText: map['anchorHabitText'] as String?,
    targetDurationMinutes: map['targetDurationMinutes'] as int?,
    metricPromptEnabled: (map['metricPromptEnabled'] as bool?) ?? false,
    metricUnit: map['metricUnit'] as String?,
    status: HabitStatus.values.byName(map['status'] as String),
    createdAt: _parseTimestamp(map['createdAt']),
    updatedAt: _parseTimestamp(map['updatedAt']),
  );

  static Map<String, dynamic> scheduleToMap(HabitScheduleVersion s) => {
    'id': s.id,
    'habitId': s.habitId,
    'effectiveFrom': s.effectiveFrom,
    'weekdaysMask': s.weekdaysMask,
    'reminderTimeMinutes': s.reminderTimeMinutes,
    'createdAt': Timestamp.fromDate(s.createdAt),
  };

  static HabitScheduleVersion scheduleFromMap(Map<String, dynamic> map) =>
      HabitScheduleVersion(
        id: map['id'] as String,
        habitId: map['habitId'] as String,
        effectiveFrom: map['effectiveFrom'] as String,
        weekdaysMask: map['weekdaysMask'] as int,
        reminderTimeMinutes: map['reminderTimeMinutes'] as int?,
        createdAt: _parseTimestamp(map['createdAt']),
      );

  static Map<String, dynamic> logToMap(HabitLog l) => {
    'id': l.id,
    'habitId': l.habitId,
    'logDate': l.logDate,
    'status': l.status.name,
    'targetSnapshot': l.targetSnapshot,
    'skipReason': l.skipReason,
    'metricValue': l.metricValue,
    'note': l.note,
    'loggedAt': Timestamp.fromDate(l.loggedAt),
  };

  static HabitLog logFromMap(Map<String, dynamic> map) => HabitLog(
    id: map['id'] as String,
    habitId: map['habitId'] as String,
    logDate: map['logDate'] as String,
    status: HabitLogStatus.values.byName(map['status'] as String),
    targetSnapshot: map['targetSnapshot'] as String?,
    skipReason: map['skipReason'] as String?,
    metricValue: (map['metricValue'] as num?)?.toDouble(),
    note: map['note'] as String?,
    loggedAt: _parseTimestamp(map['loggedAt']),
  );

  static Map<String, dynamic> targetHistoryToMap(HabitTargetHistory t) => {
    'id': t.id,
    'habitId': t.habitId,
    'targetTitle': t.targetTitle,
    'outcome': t.outcome.name,
    'endedAt': Timestamp.fromDate(t.endedAt),
  };

  static HabitTargetHistory targetHistoryFromMap(Map<String, dynamic> map) =>
      HabitTargetHistory(
        id: map['id'] as String,
        habitId: map['habitId'] as String,
        targetTitle: map['targetTitle'] as String,
        outcome: TargetOutcome.values.byName(map['outcome'] as String),
        endedAt: _parseTimestamp(map['endedAt']),
      );

  static DateTime _parseTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
