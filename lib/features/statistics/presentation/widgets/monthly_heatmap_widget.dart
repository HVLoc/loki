import 'package:flutter/material.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/utils/local_date_utils.dart';

class MonthlyHeatmapWidget extends StatelessWidget {
  const MonthlyHeatmapWidget({
    super.key,
    required this.year,
    required this.month,
    required this.dayRates,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final int year;
  final int month;
  final Map<String, double> dayRates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final firstDay = DateTime(year, month, 1);
    final leadingBlanks = firstDay.weekday - 1;
    final daysInMonth = LocalDateUtils.monthBounds(year, month).daysInMonth;
    final selectedStr = LocalDateUtils.format(selectedDate);
    final todayStr = LocalDateUtils.format(DateTime.now());

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
              .map(
                (label) => Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (ctx, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final day = index - leadingBlanks + 1;
            final date = DateTime(year, month, day);
            final dateStr = LocalDateUtils.format(date);
            final rate = dayRates[dateStr] ?? 0.0;
            final isSelected = dateStr == selectedStr;
            final isToday = dateStr == todayStr;

            final bgColor = rate <= 0
                ? c.surfaceMuted
                : c.primary.withValues(alpha: 0.22 + (0.78 * rate));

            return Semantics(
              button: true,
              label: '$dateStr ${(rate * 100).round()}%',
              child: GestureDetector(
                onTap: () => onSelectDate(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: c.accentAmber, width: 2.2)
                        : isToday
                        ? Border.all(
                            color: c.primary.withValues(alpha: 0.65),
                            width: 1.2,
                          )
                        : Border.all(color: c.border, width: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: rate > 0.55 ? Colors.white : c.textPrimary,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
