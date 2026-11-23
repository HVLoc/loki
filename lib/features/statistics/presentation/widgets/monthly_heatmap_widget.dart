import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final firstDay = DateTime(year, month, 1);
    final leadingBlanks = firstDay.weekday - 1;
    final daysInMonth = LocalDateUtils.monthBounds(year, month).daysInMonth;
    final selectedStr = LocalDateUtils.format(selectedDate);

    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('T2'),
            Text('T3'),
            Text('T4'),
            Text('T5'),
            Text('T6'),
            Text('T7'),
            Text('CN'),
          ],
        ),
        const SizedBox(height: 8),
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

            final bgColor = rate <= 0
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  )
                : theme.colorScheme.primary.withValues(
                    alpha: 0.25 + (0.75 * rate),
                  );

            return Semantics(
              button: true,
              label: '$dateStr ${(rate * 100).round()}%',
              child: GestureDetector(
                onTap: () => onSelectDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.secondary,
                            width: 2,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: rate > 0.5
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
