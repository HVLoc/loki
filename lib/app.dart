import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/constants/app_pages.dart';
import 'package:loki/core/constants/app_routes.dart';
import 'package:loki/core/i18n/app_translations.dart';
import 'package:loki/core/storage/prefs_service.dart';
import 'package:loki/core/theme/app_theme.dart';

class LokiApp extends StatelessWidget {
  const LokiApp({super.key, required this.prefsService});

  final PrefsService prefsService;

  @override
  Widget build(BuildContext context) {
    final localeParts = prefsService.localeCode.split('_');
    final initialLocale = localeParts.length == 2
        ? Locale(localeParts[0], localeParts[1])
        : const Locale('vi', 'VN');

    return GetMaterialApp(
      title: 'Loki',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: prefsService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
      builder: (ctx, child) {
        final brightness = Theme.of(ctx).brightness;
        final cupertinoTheme = AppTheme.cupertinoFor(brightness);
        return CupertinoTheme(
          data: cupertinoTheme,
          child: DefaultTextStyle.merge(
            style: const TextStyle(decoration: TextDecoration.none),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
