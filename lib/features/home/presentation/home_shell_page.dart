import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/features/auth/presentation/pages/account_settings_page.dart';
import 'package:loki/features/habits/presentation/pages/today_page.dart';
import 'package:loki/features/life_plan/presentation/pages/life_plan_page.dart';
import 'package:loki/features/statistics/presentation/pages/statistics_page.dart';
import 'package:loki/features/weaknesses/presentation/pages/weaknesses_page.dart';

class HomeShellPage extends StatelessWidget {
  const HomeShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: c.isDark
            ? const Color(0xF013171D)
            : const Color(0xF2FFFFFF),
        activeColor: c.primary,
        inactiveColor: c.textSecondary,
        border: Border(top: BorderSide(color: c.border, width: 0.8)),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.checkmark_circle),
            activeIcon: const Icon(CupertinoIcons.checkmark_circle_fill),
            label: 'tab_today'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.scope),
            activeIcon: const Icon(CupertinoIcons.scope),
            label: 'tab_weaknesses'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chart_bar),
            activeIcon: const Icon(CupertinoIcons.chart_bar_fill),
            label: 'tab_stats'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.compass),
            activeIcon: const Icon(CupertinoIcons.compass_fill),
            label: 'tab_life_plan'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.settings),
            activeIcon: const Icon(CupertinoIcons.settings_solid),
            label: 'settings'.tr,
          ),
        ],
      ),
      tabBuilder: (context, index) {
        final page = switch (index) {
          0 => const TodayPage(),
          1 => const WeaknessesPage(),
          2 => const StatisticsPage(),
          3 => const LifePlanPage(),
          _ => const AccountSettingsPage(),
        };
        return DefaultTextStyle(
          style: CupertinoTheme.of(context).textTheme.textStyle,
          child: page,
        );
      },
    );
  }
}
