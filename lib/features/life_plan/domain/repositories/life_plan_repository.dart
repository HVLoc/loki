import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';

abstract interface class LifePlanRepository {
  Future<Result<List<WheelAssessment>, Failure>> getWheelAssessments();
  Future<Result<WheelAssessment, Failure>> saveWheelAssessment(
    WheelAssessment assessment,
  );
  Future<Result<List<LongTermGoal>, Failure>> getGoals({
    GoalHorizon? horizon,
    bool includeArchived = false,
  });
  Future<Result<LongTermGoal, Failure>> saveGoalWithRevision(
    LongTermGoal goal, {
    String? changeReason,
  });
  Future<Result<List<GoalRevision>, Failure>> getGoalRevisions(String goalId);
}
