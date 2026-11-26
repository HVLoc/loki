import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';

class WheelRadarWidget extends StatelessWidget {
  const WheelRadarWidget({super.key, required this.scores});

  final List<WheelDimensionScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.length != 8) return const SizedBox.shrink();

    final c = AppTheme.colors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 240,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 5,
            ticksTextStyle: const TextStyle(
              fontSize: 10,
              color: Colors.transparent,
            ),
            gridBorderData: BorderSide(color: c.border, width: 1),
            tickBorderData: BorderSide(
              color: c.border.withValues(alpha: 0.7),
              width: 1,
            ),
            radarBorderData: BorderSide(color: c.primary, width: 1.5),
            titlePositionPercentageOffset: 0.2,
            titleTextStyle: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
            getTitle: (index, _) => RadarChartTitle(text: scores[index].label),
            dataSets: [
              RadarDataSet(
                fillColor: c.primary.withValues(alpha: 0.24),
                borderColor: c.primary,
                borderWidth: 2,
                entryRadius: 3.5,
                dataEntries: scores
                    .map((s) => RadarEntry(value: s.score.toDouble()))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
