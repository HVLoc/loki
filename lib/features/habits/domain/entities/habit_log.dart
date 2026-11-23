enum HabitLogStatus { completed, skipped }

class HabitLog {
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.logDate,
    required this.status,
    this.targetSnapshot,
    this.skipReason,
    this.metricValue,
    this.note,
    required this.loggedAt,
  });

  final String id;
  final String habitId;
  final String logDate;
  final HabitLogStatus status;
  final String? targetSnapshot;
  final String? skipReason;
  final double? metricValue;
  final String? note;
  final DateTime loggedAt;
}
