import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<({double? metric, String? note})?> showOptionalMetricSheet(
  BuildContext context, {
  required String habitTitle,
  String? unit,
}) {
  final metricCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  return showCupertinoModalPopup<({double? metric, String? note})>(
    context: context,
    builder: (ctx) => CupertinoPopupSurface(
      child: Material(
        color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  habitTitle,
                  style: CupertinoTheme.of(ctx).textTheme.navTitleTextStyle,
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: metricCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  placeholder: unit == null
                      ? 'metric_optional_hint'.tr
                      : '${'metric_optional_hint'.tr} ($unit)',
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: noteCtrl,
                  placeholder: 'Note',
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: () {
                    final metric = double.tryParse(metricCtrl.text.trim());
                    final note = noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim();
                    Navigator.of(ctx).pop((metric: metric, note: note));
                  },
                  child: Text('save'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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
