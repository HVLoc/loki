enum WeaknessStatus { active, archived }

class Weakness {
  const Weakness({
    required this.id,
    required this.title,
    required this.actionOrientation,
    this.metricLabel,
    this.metricUnit,
    required this.status,
    this.isStarterTemplate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String actionOrientation;
  final String? metricLabel;
  final String? metricUnit;
  final WeaknessStatus status;
  final bool isStarterTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Weakness copyWith({
    String? title,
    String? actionOrientation,
    String? metricLabel,
    String? metricUnit,
    WeaknessStatus? status,
    DateTime? updatedAt,
  }) {
    return Weakness(
      id: id,
      title: title ?? this.title,
      actionOrientation: actionOrientation ?? this.actionOrientation,
      metricLabel: metricLabel ?? this.metricLabel,
      metricUnit: metricUnit ?? this.metricUnit,
      status: status ?? this.status,
      isStarterTemplate: isStarterTemplate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
