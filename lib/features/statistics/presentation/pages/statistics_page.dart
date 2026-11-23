import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:loki/features/statistics/presentation/widgets/monthly_heatmap_widget.dart';

class StatisticsPage extends GetView<StatisticsController> {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('stats_title'.tr),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              controller.selectDate(LocalDateUtils.stripTime(DateTime.now())),
          child: const Text('Hôm nay'),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: controller.refreshAll),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              sliver: SliverList.list(
                children: [
                  Obx(
                    () => CupertinoSlidingSegmentedControl<bool>(
                      groupValue: controller.isMonthlyMode.value,
                      children: {
                        false: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('daily'.tr),
                        ),
                        true: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('monthly'.tr),
                        ),
                      },
                      onValueChanged: (v) {
                        if (v != null) controller.isMonthlyMode.value = v;
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(() {
                    final cur = controller.selectedDate.value;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => controller.changeMonth(-1),
                          child: const Icon(CupertinoIcons.chevron_left),
                        ),
                        Text(
                          'Tháng ${cur.month}/${cur.year}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => controller.changeMonth(1),
                          child: const Icon(CupertinoIcons.chevron_right),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  Obx(() {
                    final monthly = controller.monthlySummary.value;
                    if (!controller.isMonthlyMode.value || monthly == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoàn thành tháng: ${(monthly.overallCompletionRate * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              MonthlyHeatmapWidget(
                                year: monthly.year,
                                month: monthly.month,
                                dayRates: monthly.dayCompletionRates,
                                selectedDate: controller.selectedDate.value,
                                onSelectDate: controller.selectDate,
                              ),
                            ],
                          ),
                        ),
                        if (monthly.habitMetrics.isNotEmpty)
                          CupertinoListSection.insetGrouped(
                            margin: const EdgeInsets.only(top: 16),
                            header: const Text('Tổng hợp theo thói quen'),
                            children: monthly.habitMetrics
                                .map(
                                  (m) => CupertinoListTile(
                                    title: Text(m.habitTitle),
                                    subtitle: m.weaknessTitle == null
                                        ? null
                                        : Text(m.weaknessTitle!),
                                    additionalInfo: Text(
                                      '${m.activeDaysInMonth} ngày'
                                      '${m.totalMetricValue > 0 ? ' • ${m.totalMetricValue.toStringAsFixed(0)} ${m.metricUnit ?? ''}' : ''}',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 14),
                  Obx(() {
                    final daily = controller.dailySummary.value;
                    if (daily == null) return const SizedBox.shrink();
                    return CupertinoListSection.insetGrouped(
                      margin: EdgeInsets.zero,
                      header: Text(
                        'Ngày ${daily.date} • ${(daily.completionRate * 100).round()}%',
                      ),
                      children: daily.details.isEmpty
                          ? [
                              const CupertinoListTile(
                                title: Text(
                                  'Không có thói quen nào được lên lịch.',
                                ),
                              ),
                            ]
                          : daily.details
                                .map(
                                  (d) => CupertinoListTile(
                                    leading: Icon(
                                      d.status == HabitLogStatus.completed
                                          ? CupertinoIcons
                                                .check_mark_circled_solid
                                          : d.status == HabitLogStatus.skipped
                                          ? CupertinoIcons.pause_circle_fill
                                          : CupertinoIcons.circle,
                                      color:
                                          d.status == HabitLogStatus.completed
                                          ? CupertinoTheme.of(
                                              context,
                                            ).primaryColor
                                          : CupertinoColors.secondaryLabel,
                                    ),
                                    title: Text(d.habitTitle),
                                    subtitle: d.note == null
                                        ? null
                                        : Text(d.note!),
                                  ),
                                )
                                .toList(),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
