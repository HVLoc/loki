import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';
import 'package:loki/features/life_plan/domain/repositories/life_plan_repository.dart';

class GetWheelAssessmentsUseCase {
  const GetWheelAssessmentsUseCase(this._repository);
  final LifePlanRepository _repository;

  Future<Result<List<WheelAssessment>, Failure>> call() =>
      _repository.getWheelAssessments();
}

class SaveWheelAssessmentUseCase {
  const SaveWheelAssessmentUseCase(this._repository);
  final LifePlanRepository _repository;

  Future<Result<WheelAssessment, Failure>> call(WheelAssessment assessment) {
    if (assessment.scores.length != 8) {
      return Future.value(
        const FailureResult(
          ValidationFailure('Wheel of Life requires exactly 8 dimensions'),
        ),
      );
    }
    for (final s in assessment.scores) {
      if (s.score < 1 || s.score > 10) {
        return Future.value(
          const FailureResult(
            ValidationFailure('Dimension score must be between 1 and 10'),
          ),
        );
      }
    }
    return _repository.saveWheelAssessment(assessment);
  }
}

class GetGoalsUseCase {
  const GetGoalsUseCase(this._repository);
  final LifePlanRepository _repository;

  Future<Result<List<LongTermGoal>, Failure>> call({GoalHorizon? horizon}) =>
      _repository.getGoals(horizon: horizon);
}

class SaveGoalWithRevisionUseCase {
  const SaveGoalWithRevisionUseCase(this._repository);
  final LifePlanRepository _repository;

  Future<Result<LongTermGoal, Failure>> call(
    LongTermGoal goal, {
    String? changeReason,
  }) {
    if (goal.title.trim().isEmpty) {
      return Future.value(
        const FailureResult(ValidationFailure('Goal title is required')),
      );
    }
    if (goal.progressPercent < 0 || goal.progressPercent > 100) {
      return Future.value(
        const FailureResult(
          ValidationFailure('Progress must be between 0 and 100'),
        ),
      );
    }
    return _repository.saveGoalWithRevision(goal, changeReason: changeReason);
  }
}

class GetGoalRevisionsUseCase {
  const GetGoalRevisionsUseCase(this._repository);
  final LifePlanRepository _repository;

  Future<Result<List<GoalRevision>, Failure>> call(String goalId) =>
      _repository.getGoalRevisions(goalId);
}
