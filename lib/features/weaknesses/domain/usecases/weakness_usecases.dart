import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';
import 'package:loki/features/weaknesses/domain/repositories/weakness_repository.dart';

class GetWeaknessesUseCase {
  const GetWeaknessesUseCase(this._repository);
  final WeaknessRepository _repository;

  Future<Result<List<Weakness>, Failure>> call({
    bool includeArchived = false,
  }) => _repository.getWeaknesses(includeArchived: includeArchived);
}

class SaveWeaknessUseCase {
  const SaveWeaknessUseCase(this._repository);
  final WeaknessRepository _repository;

  Future<Result<Weakness, Failure>> call(Weakness weakness) {
    if (weakness.title.trim().isEmpty) {
      return Future.value(
        const FailureResult(ValidationFailure('Weakness title is required')),
      );
    }
    return _repository.saveWeakness(weakness);
  }
}

class ArchiveWeaknessUseCase {
  const ArchiveWeaknessUseCase(this._repository);
  final WeaknessRepository _repository;

  Future<Result<void, Failure>> call(
    String weaknessId, {
    required bool archiveLinkedHabits,
  }) => _repository.archiveWeakness(
    weaknessId,
    archiveLinkedHabits: archiveLinkedHabits,
  );
}

class SeedStarterWeaknessesUseCase {
  const SeedStarterWeaknessesUseCase(this._repository);
  final WeaknessRepository _repository;

  Future<Result<void, Failure>> call() =>
      _repository.seedStarterWeaknessesIfEmpty();
}
