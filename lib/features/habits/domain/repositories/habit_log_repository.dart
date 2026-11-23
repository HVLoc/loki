import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';

abstract interface class HabitLogRepository {
  Future<Result<HabitLog, Failure>> upsertLog(HabitLog log);
  Future<Result<void, Failure>> deleteLog(String habitId, String localDate);
  Future<Result<List<HabitLog>, Failure>> getLogsByDate(String localDate);
  Future<Result<List<HabitLog>, Failure>> getLogsByMonth(int year, int month);
  Future<Result<List<HabitLog>, Failure>> getLogsForHabit(String habitId);
}
