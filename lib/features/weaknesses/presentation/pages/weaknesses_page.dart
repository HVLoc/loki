import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:loki/core/constants/app_routes.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';
import 'package:loki/features/weaknesses/presentation/controllers/weaknesses_controller.dart';

class WeaknessesPage extends GetView<WeaknessesController> {
  const WeaknessesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('weaknesses_title'.tr),
        border: Border(bottom: BorderSide(color: c.border, width: 0.6)),
      ),
      child: SafeArea(
        child: LokiFabScrollView(
          fabLabel: 'Thêm điểm yếu',
          onFabPressed: () => Get.toNamed(AppRoutes.weaknessForm),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => controller.loadWeaknesses(),
              ),
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.weaknesses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: CupertinoActivityIndicator(radius: 14),
                      ),
                    );
                  }
                  if (controller.weaknesses.isEmpty) {
                    return const LokiEmptyState(
                      icon: CupertinoIcons.scope,
                      title: 'Nhận diện điểm cần cải thiện',
                      subtitle:
                          'Thêm điểm yếu để gắn các thói quen hằng ngày và theo dõi tiến bộ.',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c.accentAmberSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  CupertinoIcons.scope,
                                  size: 18,
                                  color: c.accentAmber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${controller.weaknesses.length} điểm yếu đang theo dõi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Chạm vào thẻ để gắn thói quen hoặc chỉnh sửa',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: controller.weaknesses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final w = controller.weaknesses[index];
                          return LokiCard(
                            onTap: () => _showActions(context, w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: c.primarySoft,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.bolt_fill,
                                        size: 18,
                                        color: c.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            w.title,
                                            style: TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w700,
                                              color: c.textPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            w.actionOrientation,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.4,
                                              color: c.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(36, 36),
                                      onPressed: () => _showActions(context, w),
                                      child: Icon(
                                        CupertinoIcons.ellipsis_circle,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (w.metricLabel != null) ...[
                                  const SizedBox(height: 12),
                                  LokiPillBadge(
                                    icon: CupertinoIcons.chart_bar_alt_fill,
                                    label: w.metricLabel!,
                                    color: c.primary,
                                    backgroundColor: c.primarySoft,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
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

  Future<void> _showActions(BuildContext context, Weakness w) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(w.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.toNamed(AppRoutes.habitForm, arguments: w.id);
            },
            child: const Text('Thêm thói quen gắn điểm yếu'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.toNamed(AppRoutes.weaknessForm, arguments: w);
            },
            child: const Text('Chỉnh sửa'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _confirmArchive(context, w);
            },
            child: const Text('Lưu trữ'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('cancel'.tr),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context, Weakness w) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Lưu trữ "${w.title}"?'),
        content: const Text(
          'Bạn muốn giữ các thói quen liên kết dưới dạng độc lập hay lưu trữ cùng?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              await controller.archiveWeakness(
                w.id,
                archiveLinkedHabits: false,
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Giữ thói quen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await controller.archiveWeakness(w.id, archiveLinkedHabits: true);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Lưu trữ cả hai'),
          ),
        ],
      ),
    );
  }
}
