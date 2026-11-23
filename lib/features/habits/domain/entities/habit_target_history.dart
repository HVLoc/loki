enum TargetOutcome { completed, switched }

class HabitTargetHistory {
  const HabitTargetHistory({
    required this.id,
    required this.habitId,
    required this.targetTitle,
    required this.outcome,
    required this.endedAt,
  });

  final String id;
  final String habitId;
  final String targetTitle;
  final TargetOutcome outcome;
  final DateTime endedAt;
}
