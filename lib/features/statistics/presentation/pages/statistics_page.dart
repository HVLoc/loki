import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:loki/features/statistics/presentation/widgets/monthly_heatmap_widget.dart';

class StatisticsPage extends GetView<StatisticsController> {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('stats_title'.tr),
        border: Border(bottom: BorderSide(color: c.border, width: 0.6)),
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(44, 32),
          onPressed: () =>
              controller.selectDate(LocalDateUtils.stripTime(DateTime.now())),
          child: Text(
            'Hôm nay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.primary,
            ),
          ),
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
                      backgroundColor: c.surfaceMuted,
                      thumbColor: c.surface,
                      groupValue: controller.isMonthlyMode.value,
                      children: {
                        false: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Text(
                            'daily'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        true: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Text(
                            'monthly'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
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
                    return LokiCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      borderRadius: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(40, 40),
                            onPressed: () => controller.changeMonth(-1),
                            child: Icon(
                              CupertinoIcons.chevron_left,
                              size: 20,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            'Tháng ${cur.month}/${cur.year}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(40, 40),
                            onPressed: () => controller.changeMonth(1),
                            child: Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  Obx(() {
                    final monthly = controller.monthlySummary.value;
                    if (!controller.isMonthlyMode.value || monthly == null) {
                      return const SizedBox.shrink();
                    }
                    final ratePct = (monthly.overallCompletionRate * 100)
                        .round();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LokiCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Hoàn thành tháng',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                  LokiPillBadge(
                                    label: '$ratePct%',
                                    color: c.primary,
                                    backgroundColor: c.primarySoft,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: monthly.overallCompletionRate,
                                  minHeight: 7,
                                  backgroundColor: c.surfaceMuted,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    c.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
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
                        if (monthly.habitMetrics.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'Tổng hợp theo thói quen',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          LokiCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: List.generate(
                                monthly.habitMetrics.length,
                                (i) {
                                  final m = monthly.habitMetrics[i];
                                  return Column(
                                    children: [
                                      if (i > 0)
                                        Divider(
                                          height: 1,
                                          indent: 16,
                                          endIndent: 16,
                                          color: c.border,
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    m.habitTitle,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: c.textPrimary,
                                                    ),
                                                  ),
                                                  if (m.weaknessTitle != null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 2,
                                                          ),
                                                      child: Text(
                                                        m.weaknessTitle!,
                                                        style: TextStyle(
                                                          fontSize: 12.5,
                                                          color:
                                                              c.textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            LokiPillBadge(
                                              label:
                                                  '${m.activeDaysInMonth} ngày'
                                                  '${m.totalMetricValue > 0 ? ' • ${m.totalMetricValue.toStringAsFixed(0)} ${m.metricUnit ?? ''}' : ''}',
                                              color: c.accentAmber,
                                              backgroundColor:
                                                  c.accentAmberSoft,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                  const SizedBox(height: 18),
                  Obx(() {
                    final daily = controller.dailySummary.value;
                    if (daily == null) return const SizedBox.shrink();
                    final dailyPct = (daily.completionRate * 100).round();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ngày ${daily.date}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                              LokiPillBadge(
                                label: '$dailyPct%',
                                color: c.primary,
                                backgroundColor: c.primarySoft,
                              ),
                            ],
                          ),
                        ),
                        LokiCard(
                          padding: EdgeInsets.zero,
                          child: daily.details.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Center(
                                    child: Text(
                                      'Không có thói quen nào được lên lịch.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: List.generate(daily.details.length, (
                                    i,
                                  ) {
                                    final d = daily.details[i];
                                    final isDone =
                                        d.status == HabitLogStatus.completed;
                                    final isSkipped =
                                        d.status == HabitLogStatus.skipped;
                                    return Column(
                                      children: [
                                        if (i > 0)
                                          Divider(
                                            height: 1,
                                            indent: 16,
                                            endIndent: 16,
                                            color: c.border,
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isDone
                                                    ? CupertinoIcons
                                                          .check_mark_circled_solid
                                                    : isSkipped
                                                    ? CupertinoIcons
                                                          .pause_circle_fill
                                                    : CupertinoIcons.circle,
                                                size: 20,
                                                color: isDone
                                                    ? c.primary
                                                    : isSkipped
                                                    ? c.accentAmber
                                                    : c.textSecondary,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      d.habitTitle,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: c.textPrimary,
                                                      ),
                                                    ),
                                                    if (d.note != null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 2,
                                                            ),
                                                        child: Text(
                                                          d.note!,
                                                          style: TextStyle(
                                                            fontSize: 12.5,
                                                            color:
                                                                c.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                        ),
                      ],
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
