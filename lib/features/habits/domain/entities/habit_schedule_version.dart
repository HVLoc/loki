class HabitScheduleVersion {
  const HabitScheduleVersion({
    required this.id,
    required this.habitId,
    required this.effectiveFrom,
    required this.weekdaysMask,
    this.reminderTimeMinutes,
    required this.createdAt,
  });

  final String id;
  final String habitId;

  /// Local calendar date (`YYYY-MM-DD`) from which this schedule takes effect.
  final String effectiveFrom;

  /// 7-bit mask (Mon = 1 .. Sun = 64; 127 = daily).
  final int weekdaysMask;

  /// Minutes since midnight (0..1439) or null when reminder is disabled.
  final int? reminderTimeMinutes;

  final DateTime createdAt;
}
