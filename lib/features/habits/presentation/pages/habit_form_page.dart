import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/utils/local_date_utils.dart';
import 'package:loki/features/habits/domain/usecases/habit_usecases.dart';
import 'package:loki/features/habits/presentation/controllers/habits_controller.dart';
import 'package:loki/features/weaknesses/presentation/controllers/weaknesses_controller.dart';

class HabitFormPage extends StatefulWidget {
  const HabitFormPage({super.key});

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _anchorCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  TodayHabitItem? _editing;
  String? _selectedWeaknessId;
  int _weekdaysMask = LocalDateUtils.allWeekdaysMask;
  TimeOfDay? _reminderTime;
  bool _metricPromptEnabled = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is TodayHabitItem) {
      _editing = arg;
      _titleCtrl.text = arg.habit.title;
      _targetCtrl.text = arg.habit.currentTarget ?? '';
      _anchorCtrl.text = arg.habit.anchorHabitText ?? '';
      if (arg.habit.targetDurationMinutes != null) {
        _durationCtrl.text = '${arg.habit.targetDurationMinutes}';
      }
      _selectedWeaknessId = arg.habit.weaknessId;
      _metricPromptEnabled = arg.habit.metricPromptEnabled;
      _weekdaysMask = arg.activeSchedule.weekdaysMask;
      final mins = arg.activeSchedule.reminderTimeMinutes;
      if (mins != null) {
        _reminderTime = TimeOfDay(hour: mins ~/ 60, minute: mins % 60);
      }
    } else if (arg is String) {
      _selectedWeaknessId = arg;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _anchorCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReminderCupertino() async {
    var temp = DateTime(
      2026,
      1,
      1,
      _reminderTime?.hour ?? 8,
      _reminderTime?.minute ?? 0,
    );
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('cancel'.tr),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: Text('save'.tr),
                  onPressed: () {
                    setState(() {
                      _reminderTime = TimeOfDay(
                        hour: temp.hour,
                        minute: temp.minute,
                      );
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: temp,
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm(HabitsController habitsCtrl) async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Vui lòng nhập tên thói quen');
      return;
    }
    final mins = _reminderTime == null
        ? null
        : _reminderTime!.hour * 60 + _reminderTime!.minute;
    final ok = await habitsCtrl.saveNewOrEditedHabit(
      existing: _editing?.habit,
      title: _titleCtrl.text,
      currentTarget: _targetCtrl.text,
      weaknessId: _selectedWeaknessId,
      anchorHabitText: _anchorCtrl.text,
      targetDurationMinutes: int.tryParse(_durationCtrl.text.trim()),
      metricPromptEnabled: _metricPromptEnabled,
      weekdaysMask: _weekdaysMask,
      reminderTimeMinutes: mins,
    );
    if (ok && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final habitsCtrl = Get.find<HabitsController>();
    final weaknessesCtrl = Get.isRegistered<WeaknessesController>()
        ? Get.find<WeaknessesController>()
        : null;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_editing == null ? 'add_habit'.tr : 'edit_habit'.tr),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  CupertinoListSection.insetGrouped(
                    header: const Text('Thông tin thói quen'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CupertinoTextField(
                              controller: _titleCtrl,
                              placeholder: 'Tên thói quen *',
                              padding: const EdgeInsets.all(12),
                              onChanged: (_) {
                                if (_titleError != null) {
                                  setState(() => _titleError = null);
                                }
                              },
                            ),
                            if (_titleError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _titleError!,
                                  style: const TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: CupertinoTextField(
                          controller: _targetCtrl,
                          placeholder:
                              'Mục tiêu đang làm (VD: Quyển A, Tiếng Anh Prep)',
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: CupertinoTextField(
                          controller: _anchorCtrl,
                          placeholder:
                              'Habit Stacking (VD: Sau khi uống cà phê sáng)',
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: CupertinoTextField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          placeholder:
                              'Thời lượng mục tiêu (phút, VD: 5 hoặc 25)',
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  if (weaknessesCtrl != null)
                    CupertinoListSection.insetGrouped(
                      header: Text('tab_weaknesses'.tr),
                      children: [
                        Obx(() {
                          final selectedTitle =
                              weaknessesCtrl.weaknesses
                                  .where((w) => w.id == _selectedWeaknessId)
                                  .firstOrNull
                                  ?.title ??
                              'Không gắn điểm yếu';
                          return CupertinoListTile(
                            title: Text(
                              selectedTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const CupertinoListTileChevron(),
                            onTap: () => showCupertinoModalPopup<void>(
                              context: context,
                              builder: (ctx) => CupertinoActionSheet(
                                title: Text('tab_weaknesses'.tr),
                                actions: [
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      setState(
                                        () => _selectedWeaknessId = null,
                                      );
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text('Không gắn điểm yếu'),
                                  ),
                                  ...weaknessesCtrl.weaknesses.map(
                                    (w) => CupertinoActionSheetAction(
                                      onPressed: () {
                                        setState(
                                          () => _selectedWeaknessId = w.id,
                                        );
                                        Navigator.of(ctx).pop();
                                      },
                                      child: Text(w.title),
                                    ),
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text('cancel'.tr),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  CupertinoListSection.insetGrouped(
                    header: const Text('Lịch thực hiện (từ hôm nay trở đi)'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(7, (idx) {
                            const labels = [
                              'T2',
                              'T3',
                              'T4',
                              'T5',
                              'T6',
                              'T7',
                              'CN',
                            ];
                            final selected = (_weekdaysMask & (1 << idx)) != 0;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    if ((_weekdaysMask & ~(1 << idx)) != 0) {
                                      _weekdaysMask &= ~(1 << idx);
                                    }
                                  } else {
                                    _weekdaysMask |= (1 << idx);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? CupertinoTheme.of(context).primaryColor
                                      : CupertinoColors.tertiarySystemFill
                                            .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  labels[idx],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : CupertinoColors.label.resolveFrom(
                                            context,
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.alarm),
                        title: Text(
                          _reminderTime == null
                              ? 'Không đặt giờ nhắc'
                              : 'Giờ nhắc: ${_reminderTime!.format(context)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _pickReminderCupertino,
                      ),
                      CupertinoListTile(
                        title: const Text(
                          'Nhập số liệu khi xong',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: CupertinoSwitch(
                          value: _metricPromptEnabled,
                          onChanged: (v) =>
                              setState(() => _metricPromptEnabled = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => _submitForm(habitsCtrl),
                  child: Text(
                    'save'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
