import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';
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
    final c = AppTheme.colors(context);
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
        height: 290,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'cancel'.tr,
                      style: TextStyle(color: c.textSecondary),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  CupertinoButton(
                    child: Text(
                      'save'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c.primary,
                      ),
                    ),
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
            ),
            Divider(height: 1, color: c.border),
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
    final c = AppTheme.colors(context);
    final habitsCtrl = Get.find<HabitsController>();
    final weaknessesCtrl = Get.isRegistered<WeaknessesController>()
        ? Get.find<WeaknessesController>()
        : null;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_editing == null ? 'add_habit'.tr : 'edit_habit'.tr),
        border: Border(bottom: BorderSide(color: c.border, width: 0.6)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    'Thông tin thói quen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LokiCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LokiUnderlineField(
                          label: 'Tên thói quen',
                          required: true,
                          controller: _titleCtrl,
                          placeholder: 'VD: Đọc sách 20 phút',
                          errorText: _titleError,
                          onChanged: (_) {
                            if (_titleError != null) {
                              setState(() => _titleError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        LokiUnderlineField(
                          label: 'Mục tiêu đang làm',
                          controller: _targetCtrl,
                          placeholder: 'VD: Quyển A, Tiếng Anh Prep',
                        ),
                        const SizedBox(height: 18),
                        LokiUnderlineField(
                          label: 'Habit Stacking',
                          controller: _anchorCtrl,
                          placeholder: 'VD: Sau khi uống cà phê sáng',
                        ),
                        const SizedBox(height: 18),
                        LokiUnderlineField(
                          label: 'Thời lượng mục tiêu (phút)',
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: 'VD: 5 hoặc 25',
                        ),
                      ],
                    ),
                  ),
                  if (weaknessesCtrl != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      'tab_weaknesses'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LokiCard(
                      padding: EdgeInsets.zero,
                      child: Obx(() {
                        final selectedTitle =
                            weaknessesCtrl.weaknesses
                                .where((w) => w.id == _selectedWeaknessId)
                                .firstOrNull
                                ?.title ??
                            'Không gắn điểm yếu';
                        return CupertinoListTile(
                          leading: Icon(
                            CupertinoIcons.scope,
                            color: c.accentAmber,
                          ),
                          title: Text(
                            selectedTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          trailing: const CupertinoListTileChevron(),
                          onTap: () => showCupertinoModalPopup<void>(
                            context: context,
                            builder: (ctx) => CupertinoActionSheet(
                              title: Text('tab_weaknesses'.tr),
                              actions: [
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    setState(() => _selectedWeaknessId = null);
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
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'Lịch thực hiện (từ hôm nay trở đi)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LokiCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
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
                              final selected =
                                  (_weekdaysMask & (1 << idx)) != 0;
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? c.primary
                                        : c.surfaceMuted,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected ? c.primary : c.border,
                                    ),
                                  ),
                                  child: Text(
                                    labels[idx],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : c.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        Divider(height: 1, color: c.border),
                        CupertinoListTile(
                          leading: Icon(CupertinoIcons.alarm, color: c.primary),
                          title: Text(
                            _reminderTime == null
                                ? 'Không đặt giờ nhắc'
                                : 'Giờ nhắc: ${_reminderTime!.format(context)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                          trailing: _reminderTime == null
                              ? const CupertinoListTileChevron()
                              : CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(32, 32),
                                  onPressed: () =>
                                      setState(() => _reminderTime = null),
                                  child: Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    size: 18,
                                    color: c.textSecondary,
                                  ),
                                ),
                          onTap: _pickReminderCupertino,
                        ),
                        Divider(height: 1, color: c.border),
                        CupertinoListTile(
                          leading: Icon(
                            CupertinoIcons.chart_bar_square,
                            color: c.accentAmber,
                          ),
                          title: Text(
                            'Nhập số liệu khi xong',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                          trailing: CupertinoSwitch(
                            activeTrackColor: c.primary,
                            value: _metricPromptEnabled,
                            onChanged: (v) =>
                                setState(() => _metricPromptEnabled = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            LokiBottomCtaBar(
              child: LokiPrimaryButton(
                label: 'save'.tr,
                icon: CupertinoIcons.check_mark_circled_solid,
                onPressed: () => _submitForm(habitsCtrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
