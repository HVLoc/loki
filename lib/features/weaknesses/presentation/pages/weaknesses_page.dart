import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/constants/app_routes.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';
import 'package:loki/features/weaknesses/presentation/controllers/weaknesses_controller.dart';

class WeaknessesPage extends GetView<WeaknessesController> {
  const WeaknessesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('weaknesses_title'.tr),
      ),
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
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: controller.weaknesses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final w = controller.weaknesses[index];
                          return GestureDetector(
                            onTap: () => _showActions(context, w),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
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
                                          w.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () =>
                                            _showActions(context, w),
                                        child: const Icon(
                                          CupertinoIcons.ellipsis_circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    w.actionOrientation,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  if (w.metricLabel != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoTheme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        w.metricLabel!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: CupertinoTheme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
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
                  onPressed: () => _showWeaknessDialog(context),
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
                        'Thêm điểm yếu',
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
              _showWeaknessDialog(context, existing: w);
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

  Future<void> _showWeaknessDialog(
    BuildContext context, {
    Weakness? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final actionCtrl = TextEditingController(
      text: existing?.actionOrientation ?? '',
    );
    final metricCtrl = TextEditingController(text: existing?.metricLabel ?? '');

    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(existing == null ? 'Thêm điểm yếu' : 'Sửa điểm yếu'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              CupertinoTextField(
                controller: titleCtrl,
                placeholder: 'Điểm yếu *',
                padding: const EdgeInsets.all(10),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: actionCtrl,
                maxLines: 2,
                placeholder: 'Định hướng khắc phục',
                padding: const EdgeInsets.all(10),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: metricCtrl,
                placeholder: 'Chỉ số đo',
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
              final ok = await controller.addOrUpdateWeakness(
                existing: existing,
                title: titleCtrl.text,
                actionOrientation: actionCtrl.text,
                metricLabel: metricCtrl.text,
              );
              if (ok && ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text('save'.tr),
          ),
        ],
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
