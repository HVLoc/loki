enum HabitStatus { active, paused, archived }

class Habit {
  const Habit({
    required this.id,
    this.weaknessId,
    required this.title,
    this.currentTarget,
    this.anchorHabitText,
    this.targetDurationMinutes,
    this.metricPromptEnabled = false,
    this.metricUnit,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? weaknessId;
  final String title;
  final String? currentTarget;
  final String? anchorHabitText;
  final int? targetDurationMinutes;
  final bool metricPromptEnabled;
  final String? metricUnit;
  final HabitStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit copyWith({
    String? weaknessId,
    bool clearWeaknessId = false,
    String? title,
    String? currentTarget,
    bool clearCurrentTarget = false,
    String? anchorHabitText,
    int? targetDurationMinutes,
    bool? metricPromptEnabled,
    String? metricUnit,
    HabitStatus? status,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id,
      weaknessId: clearWeaknessId ? null : (weaknessId ?? this.weaknessId),
      title: title ?? this.title,
      currentTarget: clearCurrentTarget
          ? null
          : (currentTarget ?? this.currentTarget),
      anchorHabitText: anchorHabitText ?? this.anchorHabitText,
      targetDurationMinutes:
          targetDurationMinutes ?? this.targetDurationMinutes,
      metricPromptEnabled: metricPromptEnabled ?? this.metricPromptEnabled,
      metricUnit: metricUnit ?? this.metricUnit,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
