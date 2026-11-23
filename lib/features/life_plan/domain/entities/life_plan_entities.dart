class WheelDimensionScore {
  const WheelDimensionScore({
    required this.dimensionKey,
    required this.label,
    required this.score,
  });

  final String dimensionKey;
  final String label;
  final int score; // 1..10
}

class WheelAssessment {
  const WheelAssessment({
    required this.id,
    required this.assessedAt,
    required this.quarterLabel,
    required this.scores,
    this.reviewNotes,
  });

  final String id;
  final DateTime assessedAt;
  final String quarterLabel;
  final List<WheelDimensionScore> scores;
  final String? reviewNotes;
}

enum GoalHorizon { oneYear, threeYears, fiveYears }

enum GoalStatus { active, completed, archived }

class LongTermGoal {
  const LongTermGoal({
    required this.id,
    required this.title,
    required this.horizon,
    this.dimensionKey,
    required this.nextMonthPlan,
    required this.progressPercent,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final GoalHorizon horizon;
  final String? dimensionKey;
  final String nextMonthPlan;
  final int progressPercent; // 0..100
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class GoalRevision {
  const GoalRevision({
    required this.id,
    required this.goalId,
    required this.revisionNumber,
    required this.snapshotTitle,
    required this.snapshotHorizon,
    required this.snapshotNextMonthPlan,
    required this.snapshotProgressPercent,
    this.changeReason,
    required this.revisedAt,
  });

  final String id;
  final String goalId;
  final int revisionNumber;
  final String snapshotTitle;
  final GoalHorizon snapshotHorizon;
  final String snapshotNextMonthPlan;
  final int snapshotProgressPercent;
  final String? changeReason;
  final DateTime revisedAt;
}
