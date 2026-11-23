import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/features/life_plan/domain/entities/life_plan_entities.dart';
import 'package:loki/features/life_plan/presentation/controllers/life_plan_controller.dart';
import 'package:loki/features/life_plan/presentation/widgets/wheel_radar_widget.dart';

class LifePlanPage extends GetView<LifePlanController> {
  const LifePlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('life_plan_title'.tr)),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
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

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'wheel_of_life'.tr,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      onPressed: () => _showWheelEditDialog(
                                        context,
                                        currentScores,
                                      ),
                                      child: const Text('Đánh giá'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                WheelRadarWidget(scores: currentScores),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 18),
                        Text(
                          'goals_1_3_5'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => CupertinoSlidingSegmentedControl<GoalHorizon>(
                            groupValue: controller.selectedHorizon.value,
                            children: const {
                              GoalHorizon.oneYear: Text('1 năm'),
                              GoalHorizon.threeYears: Text('3 năm'),
                              GoalHorizon.fiveYears: Text('5 năm'),
                            },
                            onValueChanged: (v) {
                              if (v != null) {
                                controller.selectedHorizon.value = v;
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          final filteredGoals = controller.goals
                              .where(
                                (g) =>
                                    g.horizon ==
                                    controller.selectedHorizon.value,
                              )
                              .toList();
                          if (filteredGoals.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: Text(
                                  'Chưa có mục tiêu ở mốc thời gian này.',
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: filteredGoals
                                .map(
                                  (g) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                g.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${g.progressPercent}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: CupertinoTheme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: g.progressPercent / 100,
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Kế hoạch tháng tới: ${g.nextMonthPlan}',
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            CupertinoButton(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              onPressed: () =>
                                                  _showRevisions(context, g),
                                              child: Text(
                                                'revision_history'.tr,
                                              ),
                                            ),
                                            CupertinoButton(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              onPressed: () => _showGoalDialog(
                                                context,
                                                existing: g,
                                              ),
                                              child: const Text('Cập nhật'),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => _showGoalDialog(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.add_circled_solid,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Thêm mục tiêu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  Future<void> _showWheelEditDialog(
    BuildContext context,
    List<WheelDimensionScore> initial,
  ) async {
    final mutable = [...initial];
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
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
              onPressed: () async {
                await controller.saveWheelScores(mutable);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text('save'.tr),
            ),
          ],
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
