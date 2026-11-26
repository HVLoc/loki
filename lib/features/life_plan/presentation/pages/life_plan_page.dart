import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';
import 'package:loki/features/life_plan/presentation/controllers/life_plan_controller.dart';
import 'package:loki/features/life_plan/presentation/widgets/wheel_radar_widget.dart';

class LifePlanPage extends GetView<LifePlanController> {
  const LifePlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);

    return Obx(
      () => LoadingOverlayPro(
        isLoading: controller.isSaving.value,
        progressIndicator: LoadingBouncingLine.circle(
          backgroundColor: c.primary,
        ),
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('life_plan_title'.tr),
            border: Border(bottom: BorderSide(color: c.border, width: 0.6)),
          ),
          child: SafeArea(
            child: LokiFabScrollView(
              fabLabel: 'Thêm mục tiêu',
              onFabPressed: () => _showGoalDialog(context),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: controller.loadAll),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    sliver: SliverList.list(
                      children: [
                        Obx(() {
                          final latestWheel =
                              controller.assessments.firstOrNull;
                          final currentScores =
                              latestWheel?.scores ??
                              LifePlanController.defaultDimensions
                                  .map(
                                    (d) => WheelDimensionScore(
                                      dimensionKey: d.key,
                                      label: d.label,
                                      score: 5,
                                    ),
                                  )
                                  .toList();
                          final avgScore = currentScores.isEmpty
                              ? 0.0
                              : currentScores
                                        .map((e) => e.score)
                                        .reduce((a, b) => a + b) /
                                    currentScores.length;

                          return LokiCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'wheel_of_life'.tr,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: c.textPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Trung bình: ${avgScore.toStringAsFixed(1)}/10',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: c.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      minimumSize: const Size(44, 34),
                                      color: c.primarySoft,
                                      borderRadius: BorderRadius.circular(12),
                                      onPressed: () => _showWheelEditDialog(
                                        context,
                                        currentScores,
                                      ),
                                      child: Text(
                                        'Đánh giá',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: c.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                WheelRadarWidget(scores: currentScores),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        Text(
                          'goals_1_3_5'.tr,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => CupertinoSlidingSegmentedControl<GoalHorizon>(
                            backgroundColor: c.surfaceMuted,
                            thumbColor: c.surface,
                            groupValue: controller.selectedHorizon.value,
                            children: {
                              GoalHorizon.oneYear: Text(
                                '1 năm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                              GoalHorizon.threeYears: Text(
                                '3 năm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                              GoalHorizon.fiveYears: Text(
                                '5 năm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                            },
                            onValueChanged: (v) {
                              if (v != null) {
                                controller.selectedHorizon.value = v;
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Obx(() {
                          final filteredGoals = controller.goals
                              .where(
                                (g) =>
                                    g.horizon ==
                                    controller.selectedHorizon.value,
                              )
                              .toList();
                          if (filteredGoals.isEmpty) {
                            return const LokiEmptyState(
                              icon: CupertinoIcons.compass,
                              title: 'Chưa có mục tiêu',
                              subtitle:
                                  'Chưa có mục tiêu ở mốc thời gian này. Hãy thêm mục tiêu đầu tiên bên dưới.',
                            );
                          }
                          return Column(
                            children: filteredGoals
                                .map(
                                  (g) => LokiCard(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                g.title,
                                                style: TextStyle(
                                                  fontSize: 16.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: c.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            LokiPillBadge(
                                              label: '${g.progressPercent}%',
                                              color: c.primary,
                                              backgroundColor: c.primarySoft,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: g.progressPercent / 100,
                                            minHeight: 7,
                                            backgroundColor: c.surfaceMuted,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  c.primary,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: c.surfaceMuted,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'Kế hoạch tháng tới: ${g.nextMonthPlan}',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              color: c.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            CupertinoButton(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              minimumSize: const Size(44, 34),
                                              color: c.surfaceMuted,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              onPressed: () =>
                                                  _showRevisions(context, g),
                                              child: Text(
                                                'revision_history'.tr,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: c.textSecondary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            CupertinoButton(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              minimumSize: const Size(44, 34),
                                              color: c.primarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              onPressed: () => _showGoalDialog(
                                                context,
                                                existing: g,
                                              ),
                                              child: Text(
                                                'Cập nhật',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: c.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWheelEditDialog(
    BuildContext context,
    List<WheelDimensionScore> initial,
  ) async {
    final mutable = [...initial];
    final c = AppTheme.colors(context);
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => Obx(
        () => LoadingOverlayPro(
          isLoading: controller.isSaving.value,
          progressIndicator: LoadingBouncingLine.circle(
            backgroundColor: c.primary,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) => CupertinoAlertDialog(
              title: Text('wheel_of_life'.tr),
              content: SizedBox(
                height: 320,
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(mutable.length, (i) {
                      final item = mutable[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.label}: ${item.score}/10'),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoSlider(
                                min: 1,
                                max: 10,
                                divisions: 9,
                                value: item.score.toDouble(),
                                onChanged: (v) {
                                  setState(() {
                                    mutable[i] = WheelDimensionScore(
                                      dimensionKey: item.dimensionKey,
                                      label: item.label,
                                      score: v.round(),
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('cancel'.tr),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                          await controller.saveWheelScores(mutable);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                  child: Text('save'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGoalDialog(
    BuildContext context, {
    LongTermGoal? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final planCtrl = TextEditingController(text: existing?.nextMonthPlan ?? '');
    final reasonCtrl = TextEditingController();
    var progress = existing?.progressPercent ?? 0;
    final horizon = existing?.horizon ?? controller.selectedHorizon.value;

    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => CupertinoAlertDialog(
          title: Text(existing == null ? 'Thêm mục tiêu' : 'Cập nhật mục tiêu'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: titleCtrl,
                  placeholder: 'Mục tiêu *',
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: planCtrl,
                  placeholder: 'Kế hoạch tháng tới',
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 10),
                Text('Tiến độ: $progress%'),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlider(
                    min: 0,
                    max: 100,
                    divisions: 20,
                    value: progress.toDouble(),
                    onChanged: (v) => setState(() => progress = v.round()),
                  ),
                ),
                if (existing != null)
                  CupertinoTextField(
                    controller: reasonCtrl,
                    placeholder: 'Lý do thay đổi kế hoạch (tuỳ chọn)',
                    padding: const EdgeInsets.all(10),
                  ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('cancel'.tr),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await controller.saveGoal(
                  existing: existing,
                  title: titleCtrl.text,
                  horizon: horizon,
                  nextMonthPlan: planCtrl.text,
                  progressPercent: progress,
                  changeReason: reasonCtrl.text.trim().isEmpty
                      ? null
                      : reasonCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRevisions(BuildContext context, LongTermGoal goal) async {
    final revs = await controller.fetchRevisions(goal.id);
    if (!context.mounted) return;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoPopupSurface(
        child: Material(
          color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
          child: SizedBox(
            height: 360,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: revs.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, i) {
                final r = revs[i];
                return CupertinoListTile(
                  title: Text(
                    'v${r.revisionNumber}: ${r.snapshotTitle} (${r.snapshotProgressPercent}%)',
                  ),
                  subtitle: Text(
                    'Kế hoạch: ${r.snapshotNextMonthPlan}'
                    '${r.changeReason != null ? '\nLý do: ${r.changeReason}' : ''}',
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
