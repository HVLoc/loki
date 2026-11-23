import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/constants/app_routes.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/features/habits/domain/entities/habit_log.dart';
import 'package:loki/features/habits/domain/usecases/habit_usecases.dart';
import 'package:loki/features/habits/presentation/controllers/habits_controller.dart';
import 'package:loki/features/habits/presentation/widgets/habit_action_sheets.dart';

class TodayPage extends GetView<HabitsController> {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDark = cupertinoTheme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('tab_today'.tr)),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemYellow.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.bell_slash,
                              color: CupertinoColors.systemOrange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'notification_denied_banner'.tr,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  controller.notificationDenied.value = false,
                              child: const Icon(
                                CupertinoIcons.xmark_circle_fill,
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 64,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.sparkles,
                                  size: 52,
                                  color: primaryColor,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Gieo thói quen tốt mỗi ngày',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'today_empty'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final total = controller.todayItems.length;
                      final doneCount = controller.todayItems
                          .where(
                            (e) =>
                                e.todayLog?.status == HabitLogStatus.completed,
                          )
                          .length;
                      final progress = total == 0 ? 0.0 : doneCount / total;
                      final bestStreak = controller.todayItems.fold<int>(
                        0,
                        (max, e) =>
                            e.currentStreak > max ? e.currentStreak : max,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DailyHeroCard(
                            doneCount: doneCount,
                            totalCount: total,
                            progress: progress,
                            bestStreak: bestStreak,
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: controller.todayItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, index) => _CupertinoHabitCard(
                              item: controller.todayItems[index],
                              controller: controller,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => Get.toNamed(AppRoutes.habitForm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.add_circled_solid,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'add_habit'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyHeroCard extends StatelessWidget {
  const _DailyHeroCard({
    required this.doneCount,
    required this.totalCount,
    required this.progress,
    required this.bestStreak,
    required this.primaryColor,
    required this.isDark,
  });

  final int doneCount;
  final int totalCount;
  final double progress;
  final int bestStreak;
  final Color primaryColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: isDark ? 0.78 : 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gieo thói quen hôm nay',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.flame_fill,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$bestStreak',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$doneCount/$totalCount thói quen hoàn thành ($pct%)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CupertinoHabitCard extends StatelessWidget {
  const _CupertinoHabitCard({
    required this.item,
    required this.controller,
    required this.isDark,
  });

  final TodayHabitItem item;
  final HabitsController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final log = item.todayLog;
    final isCompleted = log?.status == HabitLogStatus.completed;
    final isSkipped = log?.status == HabitLogStatus.skipped;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final streakColor = isDark
        ? AppTheme.streakAmberDark
        : AppTheme.streakAmberLight;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.habitForm, arguments: item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.habit.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: streakColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.flame_fill,
                        size: 14,
                        color: streakColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'streak_days'.trParams({
                          'count': '${item.currentStreak}',
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: streakColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.habit.currentTarget != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Đang làm: ${item.habit.currentTarget!}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 36),
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
                    child: const Text('Đổi', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
            if (item.habit.anchorHabitText != null) ...[
              const SizedBox(height: 6),
              Text(
                '${'after_habit_prefix'.tr}${item.habit.anchorHabitText!}',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
            if (item.habit.targetDurationMinutes != null) ...[
              const SizedBox(height: 4),
              Text(
                '${item.habit.targetDurationMinutes} min',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (!isCompleted && !isSkipped) ...[
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () async {
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
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'complete'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: CupertinoColors.tertiarySystemFill.resolveFrom(
                      context,
                    ),
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
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isCompleted ? primaryColor : streakColor)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.pause_circle_fill,
                          size: 16,
                          color: isCompleted ? primaryColor : streakColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCompleted ? 'complete'.tr : 'skip'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? primaryColor : streakColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    onPressed: () => controller.undoCheckIn(item.habit),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.arrow_uturn_left, size: 16),
                        const SizedBox(width: 4),
                        Text('undo'.tr),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
