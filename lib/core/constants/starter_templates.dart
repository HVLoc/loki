/// Six starter weakness templates derived from the user's growth table.
final class StarterTemplateItem {
  const StarterTemplateItem({
    required this.id,
    required this.title,
    required this.actionOrientation,
    this.metricLabel,
    this.metricUnit,
  });

  final String id;
  final String title;
  final String actionOrientation;
  final String? metricLabel;
  final String? metricUnit;
}

final class StarterTemplates {
  StarterTemplates._();

  static const List<StarterTemplateItem> weaknesses = [
    StarterTemplateItem(
      id: 'starter_english',
      title: 'Tiếng Anh kém',
      actionOrientation: '20–30 phút/ngày: học đầy đủ theo lộ trình của Prep',
      metricLabel: 'Số ngày học/tháng; tự đọc hiểu tài liệu; điểm test',
      metricUnit: 'phút',
    ),
    StarterTemplateItem(
      id: 'starter_habit_retention',
      title: 'Khó duy trì thói quen (lâu nhất 1 tháng)',
      actionOrientation:
          'Bắt đầu cực nhỏ (2–5 phút/ngày); gắn thói quen mới vào thói quen cũ (habit stacking); đánh dấu theo dõi hằng ngày.',
      metricLabel: 'Chuỗi ngày liên tục (streak)',
      metricUnit: 'ngày',
    ),
    StarterTemplateItem(
      id: 'starter_manager_comms',
      title: 'Giao tiếp ngoài công việc với cấp trên còn yếu',
      actionOrientation:
          'Tham gia các hoạt động chung, ăn trưa/cà phê với cấp trên.',
      metricLabel: 'Số buổi giao tiếp/tháng',
      metricUnit: 'buổi',
    ),
    StarterTemplateItem(
      id: 'starter_long_term_plan',
      title: 'Chưa có kế hoạch dài hạn cho cuộc sống',
      actionOrientation:
          'Dùng Bánh xe cuộc đời (Wheel of Life) đánh giá 8 khía cạnh; đặt mục tiêu 1 năm – 3 năm – 5 năm; rà soát mỗi quý.',
      metricLabel: 'Kế hoạch tháng tới & % mục tiêu năm đạt được',
      metricUnit: '%',
    ),
    StarterTemplateItem(
      id: 'starter_new_knowledge',
      title: 'Học tập kiến thức mới',
      actionOrientation:
          'Xây dựng lộ trình học rõ ràng và duy trì kỷ luật học kiến thức mới hằng ngày.',
      metricLabel: 'Số buổi học kiến thức mới/tháng',
      metricUnit: 'phút',
    ),
    StarterTemplateItem(
      id: 'starter_business_books',
      title: 'Sách chỉ đọc văn học',
      actionOrientation: 'Đọc thêm sách về kinh doanh, kinh tế.',
      metricLabel: 'Số sách kinh doanh/kinh tế đọc trong tháng',
      metricUnit: 'cuốn',
    ),
  ];
}
