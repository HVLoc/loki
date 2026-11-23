import 'package:get/get.dart';
import 'package:loki/core/constants/app_routes.dart';
import 'package:loki/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loki/features/auth/presentation/pages/account_settings_page.dart';
import 'package:loki/features/habits/presentation/bindings/habit_binding.dart';
import 'package:loki/features/habits/presentation/pages/habit_form_page.dart';
import 'package:loki/features/home/presentation/home_shell_page.dart';
import 'package:loki/features/life_plan/presentation/controllers/life_plan_controller.dart';
import 'package:loki/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:loki/features/weaknesses/presentation/bindings/weakness_binding.dart';

final class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeShellPage(),
      bindings: [
        AuthBinding(),
        HabitBinding(),
        WeaknessBinding(),
        StatsBinding(),
        LifePlanBinding(),
      ],
    ),
    GetPage(name: AppRoutes.habitForm, page: () => const HabitFormPage()),
    GetPage(
      name: AppRoutes.accountSettings,
      page: () => const AccountSettingsPage(),
    ),
  ];
}
