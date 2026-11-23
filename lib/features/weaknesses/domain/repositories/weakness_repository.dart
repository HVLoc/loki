import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';

abstract interface class WeaknessRepository {
  Future<Result<List<Weakness>, Failure>> getWeaknesses({
    bool includeArchived = false,
  });
  Future<Result<Weakness, Failure>> saveWeakness(Weakness weakness);
  Future<Result<void, Failure>> archiveWeakness(
    String weaknessId, {
    required bool archiveLinkedHabits,
  });
  Future<Result<void, Failure>> seedStarterWeaknessesIfEmpty();
}
