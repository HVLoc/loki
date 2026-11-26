import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';

Future<({double? metric, String? note})?> showOptionalMetricSheet(
  BuildContext context, {
  required String habitTitle,
  String? unit,
}) {
  final metricCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  return showCupertinoModalPopup<({double? metric, String? note})>(
    context: context,
    builder: (ctx) {
      final c = AppTheme.colors(ctx);
      return CupertinoPopupSurface(
        child: Material(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    habitTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LokiUnderlineField(
                    label: unit == null
                        ? 'metric_optional_hint'.tr
                        : '${'metric_optional_hint'.tr} ($unit)',
                    controller: metricCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: 'VD: 25',
                  ),
                  const SizedBox(height: 16),
                  LokiUnderlineField(
                    label: 'Ghi chú',
                    controller: noteCtrl,
                    placeholder: 'Note',
                  ),
                  const SizedBox(height: 16),
                  LokiPrimaryButton(
                    label: 'save'.tr,
                    icon: CupertinoIcons.check_mark_circled_solid,
                    onPressed: () {
                      final metric = double.tryParse(metricCtrl.text.trim());
                      final note = noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim();
                      Navigator.of(ctx).pop((metric: metric, note: note));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<String?> showSkipReasonDialog(BuildContext context, String habitTitle) {
  final reasonCtrl = TextEditingController();
  return showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text('${'skip'.tr}: $habitTitle'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: reasonCtrl,
          placeholder: 'skip_reason_hint'.tr,
          padding: const EdgeInsets.all(10),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: Text('cancel'.tr),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
          child: Text('skip'.tr),
        ),
      ],
    ),
  );
}

Future<({String? newTarget, bool markPreviousCompleted})?>
showSwitchTargetSheet(
  BuildContext context, {
  required String habitTitle,
  String? currentTarget,
}) async {
  final choice = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(habitTitle),
      message: Text(
        currentTarget == null
            ? 'Đặt mục tiêu/hành động cụ thể đang thực hiện'
            : 'Đang làm: $currentTarget',
      ),
      actions: [
        if (currentTarget != null)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đã xong mục tiêu này & Chuyển mới'),
          ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            currentTarget == null
                ? 'Đặt mục tiêu đang làm'
                : 'Đổi sang mục tiêu khác',
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(ctx).pop(null),
        child: Text('cancel'.tr),
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;

  final ctrl = TextEditingController();
  final newTarget = await showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(
        choice ? 'Mục tiêu tiếp theo' : 'Nhập mục tiêu/hành động mới',
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: ctrl,
          placeholder: 'VD: Quyển B, Tiếng Trung HSK 1...',
          padding: const EdgeInsets.all(10),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: Text('cancel'.tr),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          child: Text('save'.tr),
        ),
      ],
    ),
  );
  if (newTarget == null) return null;
  return (newTarget: newTarget, markPreviousCompleted: choice);
}
