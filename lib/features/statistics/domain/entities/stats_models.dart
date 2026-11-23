import 'package:loki/features/habits/domain/entities/habit_log.dart';

class DailyHabitDetail {
  const DailyHabitDetail({
    required this.habitId,
    required this.habitTitle,
    this.weaknessId,
    required this.status,
    this.metricValue,
    this.note,
  });

  final String habitId;
  final String habitTitle;
  final String? weaknessId;
  final HabitLogStatus? status; // null = missed/pending
  final double? metricValue;
  final String? note;
}

class DailySummary {
  const DailySummary({
    required this.date,
    required this.scheduledCount,
    required this.completedCount,
    required this.skippedCount,
    required this.completionRate,
    required this.details,
  });

  final String date;
  final int scheduledCount;
  final int completedCount;
  final int skippedCount;
  final double completionRate; // 0.0 .. 1.0
  final List<DailyHabitDetail> details;
}

class MonthlyHabitMetric {
  const MonthlyHabitMetric({
    required this.habitId,
    required this.habitTitle,
    this.weaknessTitle,
    required this.activeDaysInMonth,
    required this.totalMetricValue,
    this.metricUnit,
  });

  final String habitId;
  final String habitTitle;
  final String? weaknessTitle;
  final int activeDaysInMonth;
  final double totalMetricValue;
  final String? metricUnit;
}

class MonthlySummary {
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.overallCompletionRate,
    required this.dayCompletionRates,
    required this.habitMetrics,
  });

  final int year;
  final int month;
  final double overallCompletionRate;
  final Map<String, double> dayCompletionRates; // YYYY-MM-DD -> 0.0..1.0
  final List<MonthlyHabitMetric> habitMetrics;
}
