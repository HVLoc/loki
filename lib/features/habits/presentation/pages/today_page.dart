import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/constants/app_routes.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/usecases/habit_usecases.dart';
import 'package:loki/features/habits/presentation/controllers/habits_controller.dart';
import 'package:loki/features/habits/presentation/widgets/habit_action_sheets.dart';

class TodayPage extends GetView<HabitsController> {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('tab_today'.tr),
        border: Border(bottom: BorderSide(color: c.border, width: 0.6)),
      ),
      child: SafeArea(
        child: LokiFabScrollView(
          fabLabel: 'add_habit'.tr,
          onFabPressed: () => Get.toNamed(AppRoutes.habitForm),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => controller.loadTodayHabits(),
              ),
              SliverToBoxAdapter(
                child: Obx(() {
                  if (!controller.notificationDenied.value) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: c.accentAmberSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.accentAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.bell_slash_fill,
                          size: 18,
                          color: c.accentAmber,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'notification_denied_banner'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(32, 32),
                          onPressed: () =>
                              controller.notificationDenied.value = false,
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 18,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.todayItems.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: CupertinoActivityIndicator(radius: 14),
                      ),
                    );
                  }
                  if (controller.todayItems.isEmpty) {
                    return LokiEmptyState(
                      icon: CupertinoIcons.sparkles,
                      title: 'Gieo thói quen tốt mỗi ngày',
                      subtitle: 'today_empty'.tr,
                    );
                  }

                  final items = controller.todayItems;
                  final total = items.length;
                  final pending = items
                      .where(
                        (e) =>
                            e.todayLog?.status != HabitLogStatus.completed &&
                            e.todayLog?.status != HabitLogStatus.skipped,
                      )
                      .toList();
                  final finished = items
                      .where(
                        (e) =>
                            e.todayLog?.status == HabitLogStatus.completed ||
                            e.todayLog?.status == HabitLogStatus.skipped,
                      )
                      .toList();
                  final doneCount = items
                      .where(
                        (e) => e.todayLog?.status == HabitLogStatus.completed,
                      )
                      .length;
                  final progress = total == 0 ? 0.0 : doneCount / total;
                  final bestStreak = items.fold<int>(
                    0,
                    (max, e) => e.currentStreak > max ? e.currentStreak : max,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BentoSummaryHeader(
                        doneCount: doneCount,
                        totalCount: total,
                        progress: progress,
                        bestStreak: bestStreak,
                      ),
                      if (pending.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Cần làm hôm nay',
                          trailing: '${pending.length} việc',
                          trailingColor: c.primary,
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: pending.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, index) => _HabitFocusTile(
                            item: pending[index],
                            controller: controller,
                          ),
                        ),
                      ],
                      if (finished.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Đã xử lý',
                          trailing: '${finished.length}/$total',
                          trailingColor: c.textSecondary,
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: finished.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, index) => _HabitFocusTile(
                            item: finished[index],
                            controller: controller,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    required this.trailingColor,
  });

  final String title;
  final String trailing;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: trailingColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoSummaryHeader extends StatelessWidget {
  const _BentoSummaryHeader({
    required this.doneCount,
    required this.totalCount,
    required this.progress,
    required this.bestStreak,
  });

  final int doneCount;
  final int totalCount;
  final double progress;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final pct = (progress * 100).round();
    final isAllDone = totalCount > 0 && doneCount == totalCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: c.isDark
                        ? [const Color(0xFFB93838), const Color(0xFFE55353)]
                        : [const Color(0xFFE55353), const Color(0xFFF06E6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: c.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: c.primary.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isAllDone ? 'Hoàn tất hôm nay!' : 'Tiến độ hôm nay',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$doneCount/$totalCount',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.6,
                                height: 1.1,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.24,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: LokiCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.accentAmberSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CupertinoIcons.flame_fill,
                        size: 18,
                        color: c.accentAmber,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$bestStreak',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                            height: 1.05,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kỷ lục ngày',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitFocusTile extends StatelessWidget {
  const _HabitFocusTile({required this.item, required this.controller});

  final TodayHabitItem item;
  final HabitsController controller;

  Future<void> _handleComplete(BuildContext context) async {
    if (item.habit.metricPromptEnabled) {
      final extra = await showOptionalMetricSheet(
        context,
        habitTitle: item.habit.title,
        unit: item.habit.metricUnit,
      );
      await controller.completeHabit(
        item.habit,
        metricValue: extra?.metric,
        note: extra?.note,
      );
    } else {
      await controller.completeHabit(item.habit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final log = item.todayLog;
    final isCompleted = log?.status == HabitLogStatus.completed;
    final isSkipped = log?.status == HabitLogStatus.skipped;

    final cardBg = isCompleted
        ? (c.isDark ? const Color(0xFF1F1618) : const Color(0xFFFFF6F6))
        : isSkipped
        ? (c.isDark ? const Color(0xFF211D15) : const Color(0xFFFFFBEB))
        : c.surface;

    final borderColor = isCompleted
        ? c.primary.withValues(alpha: 0.28)
        : isSkipped
        ? c.accentAmber.withValues(alpha: 0.28)
        : c.border;

    return LokiCard(
      onTap: () => Get.toNamed(AppRoutes.habitForm, arguments: item),
      backgroundColor: cardBg,
      borderColor: borderColor,
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.habit.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isCompleted ? c.textSecondary : c.textPrimary,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (item.habit.anchorHabitText != null ||
                        item.habit.targetDurationMinutes != null) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (item.habit.anchorHabitText != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.link,
                                  size: 12,
                                  color: c.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${'after_habit_prefix'.tr}${item.habit.anchorHabitText!}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (item.habit.targetDurationMinutes != null)
                            Text(
                              '• ${item.habit.targetDurationMinutes}p',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: c.primary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LokiPillBadge(
                icon: CupertinoIcons.flame_fill,
                label: 'streak_days'.trParams({
                  'count': '${item.currentStreak}',
                }),
                color: c.accentAmber,
                backgroundColor: c.accentAmberSoft,
              ),
            ],
          ),
          if (item.habit.currentTarget != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Đang làm: ${item.habit.currentTarget!}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(44, 30),
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () async {
                    final res = await showSwitchTargetSheet(
                      context,
                      habitTitle: item.habit.title,
                      currentTarget: item.habit.currentTarget,
                    );
                    if (res != null) {
                      await controller.switchTarget(
                        habitId: item.habit.id,
                        newTarget: res.newTarget,
                        markPreviousCompleted: res.markPreviousCompleted,
                      );
                    }
                  },
                  child: Text(
                    'Đổi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isCompleted && !isSkipped) ...[
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: c.primary,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => _handleComplete(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          size: 17,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'complete'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () async {
                    final reason = await showSkipReasonDialog(
                      context,
                      item.habit.title,
                    );
                    if (reason != null) {
                      await controller.skipHabit(item.habit, reason: reason);
                    }
                  },
                  child: Text(
                    'skip'.tr,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ] else ...[
                LokiPillBadge(
                  icon: isCompleted
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.pause_circle_fill,
                  label: isCompleted ? 'complete'.tr : 'skip'.tr,
                  color: isCompleted ? c.primary : c.accentAmber,
                  backgroundColor: isCompleted
                      ? c.primarySoft
                      : c.accentAmberSoft,
                ),
                const Spacer(),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(44, 32),
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () => controller.undoCheckIn(item.habit),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_uturn_left,
                        size: 13,
                        color: c.textPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'undo'.tr,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
