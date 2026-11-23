import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:loki/features/auth/presentation/controllers/auth_controller.dart';

class AccountSettingsPage extends GetView<AuthController> {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('settings'.tr)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Obx(() {
              final user = controller.currentUser.value;
              return CupertinoListSection.insetGrouped(
                header: Text('account_sync'.tr),
                children: [
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.cloud),
                    title: Text(
                      user == null || user.isAnonymous
                          ? 'anonymous_session'.tr
                          : '${user.email ?? user.uid} (Synced)',
                    ),
                  ),
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.person_badge_plus),
                    title: Text('link_google'.tr),
                    trailing: const CupertinoListTileChevron(),
                    onTap: controller.linkWithGoogle,
                  ),
                ],
              );
            }),
            CupertinoListSection.insetGrouped(
              header: Text('link_email'.tr),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: CupertinoTextField(
                    controller: emailCtrl,
                    placeholder: 'Email',
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: CupertinoTextField(
                    controller: passCtrl,
                    obscureText: true,
                    placeholder: 'Password',
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CupertinoButton.filled(
                    onPressed: () =>
                        controller.linkWithEmail(emailCtrl.text, passCtrl.text),
                    child: Text('link_email'.tr),
                  ),
                ),
              ],
            ),
            Obx(() {
              if (controller.statusMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  controller.statusMessage.value,
                  style: TextStyle(
                    color: CupertinoTheme.of(context).primaryColor,
                    fontSize: 13,
                  ),
                ),
              );
            }),
            CupertinoListSection.insetGrouped(
              header: const Text('Giao diện & Ngôn ngữ'),
              children: [
                Obx(
                  () => CupertinoListTile(
                    leading: const Icon(CupertinoIcons.moon),
                    title: Text('theme_dark'.tr),
                    trailing: CupertinoSwitch(
                      value: controller.isDarkMode.value,
                      onChanged: controller.toggleDarkMode,
                    ),
                  ),
                ),
                Obx(
                  () => CupertinoListTile(
                    leading: const Icon(CupertinoIcons.globe),
                    title: Text('language'.tr),
                    additionalInfo: Text(
                      controller.localeCode.value == 'vi_VN'
                          ? 'Tiếng Việt'
                          : 'English',
                    ),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => controller.switchLocale(
                      controller.localeCode.value == 'vi_VN'
                          ? 'en_US'
                          : 'vi_VN',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
