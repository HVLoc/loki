import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';
import 'package:loki/features/auth/presentation/controllers/auth_controller.dart';

class AccountSettingsPage extends GetView<AuthController> {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('settings'.tr),
        border: Border(bottom: BorderSide(color: c.border, width: 0.6)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Obx(() {
              final user = controller.currentUser.value;
              final isAnon = user == null || user.isAnonymous;
              return LokiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isAnon ? c.accentAmberSoft : c.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAnon
                                ? CupertinoIcons.person_crop_circle
                                : CupertinoIcons.checkmark_seal_fill,
                            size: 26,
                            color: isAnon ? c.accentAmber : c.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'account_sync'.tr,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAnon
                                    ? 'anonymous_session'.tr
                                    : '${user.email ?? user.uid} (Synced)',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: c.border),
                    CupertinoListTile(
                      padding: const EdgeInsets.only(top: 10),
                      leading: Icon(
                        CupertinoIcons.person_badge_plus,
                        color: c.primary,
                      ),
                      title: Text(
                        'link_google'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      trailing: const CupertinoListTileChevron(),
                      onTap: controller.linkWithGoogle,
                    ),
                  ],
                ),
              );
            }),
            Obx(() {
              if (controller.statusMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 12, left: 4, right: 4),
                child: Text(
                  controller.statusMessage.value,
                  style: TextStyle(
                    color: c.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
            const SizedBox(height: 18),
            Text(
              'Giao diện & Ngôn ngữ',
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
                children: [
                  Obx(
                    () => CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.moon_stars_fill,
                        color: c.accentAmber,
                      ),
                      title: Text(
                        'theme_dark'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      trailing: CupertinoSwitch(
                        activeTrackColor: c.primary,
                        value: controller.isDarkMode.value,
                        onChanged: controller.toggleDarkMode,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: c.border,
                  ),
                  Obx(
                    () => CupertinoListTile(
                      leading: Icon(CupertinoIcons.globe, color: c.primary),
                      title: Text(
                        'language'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      additionalInfo: Text(
                        controller.localeCode.value == 'vi_VN'
                            ? 'Tiếng Việt'
                            : 'English',
                        style: TextStyle(color: c.textSecondary),
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
            ),
          ],
        ),
      ),
    );
  }
}
