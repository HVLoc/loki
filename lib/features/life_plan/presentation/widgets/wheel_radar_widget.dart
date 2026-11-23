import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';

class WheelRadarWidget extends StatelessWidget {
  const WheelRadarWidget({super.key, required this.scores});

  final List<WheelDimensionScore> scores;

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    if (scores.length != 8) return const SizedBox.shrink();

    final primary = cupertinoTheme.primaryColor;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final gridColor = CupertinoColors.separator.resolveFrom(context);

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
            gridBorderData: BorderSide(color: gridColor),
            tickBorderData: BorderSide(
              color: gridColor.withValues(alpha: 0.45),
            ),
            radarBorderData: BorderSide(color: primary),
            titlePositionPercentageOffset: 0.2,
            titleTextStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
            getTitle: (index, _) => RadarChartTitle(text: scores[index].label),
            dataSets: [
              RadarDataSet(
                fillColor: primary.withValues(alpha: 0.22),
                borderColor: primary,
                entryRadius: 3,
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
