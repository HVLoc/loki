import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';
import 'package:loki/features/weaknesses/domain/entities/weakness.dart';
import 'package:loki/features/weaknesses/presentation/controllers/weaknesses_controller.dart';

class WeaknessFormPage extends StatefulWidget {
  const WeaknessFormPage({super.key});

  @override
  State<WeaknessFormPage> createState() => _WeaknessFormPageState();
}

class _WeaknessFormPageState extends State<WeaknessFormPage> {
  final _titleCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  final _metricCtrl = TextEditingController();

  Weakness? _editing;
  String? _titleError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is Weakness) {
      _editing = arg;
      _titleCtrl.text = arg.title;
      _actionCtrl.text = arg.actionOrientation;
      _metricCtrl.text = arg.metricLabel ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _actionCtrl.dispose();
    _metricCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(WeaknessesController ctrl) async {
    if (_submitting) return;
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Vui lòng nhập điểm yếu');
      return;
    }
    setState(() => _submitting = true);
    final ok = await ctrl.addOrUpdateWeakness(
      existing: _editing,
      title: _titleCtrl.text,
      actionOrientation: _actionCtrl.text,
      metricLabel: _metricCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final ctrl = Get.find<WeaknessesController>();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_editing == null ? 'Thêm điểm yếu' : 'Sửa điểm yếu'),
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
                    'Thông tin điểm yếu',
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
                          label: 'Điểm yếu',
                          required: true,
                          autofocus: _editing == null,
                          controller: _titleCtrl,
                          placeholder: 'VD: Tiếng Anh kém',
                          errorText: _titleError,
                          onChanged: (_) {
                            if (_titleError != null) {
                              setState(() => _titleError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        LokiUnderlineField(
                          label: 'Định hướng khắc phục',
                          controller: _actionCtrl,
                          minLines: 2,
                          maxLines: 5,
                          placeholder: 'VD: Học 25 phút mỗi ngày',
                        ),
                        const SizedBox(height: 18),
                        LokiUnderlineField(
                          label: 'Chỉ số đo',
                          controller: _metricCtrl,
                          placeholder: 'VD: Số ngày học/tháng, trang sách',
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
                onPressed: _submitting ? null : () => _submit(ctrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
