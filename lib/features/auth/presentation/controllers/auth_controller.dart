import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/core/storage/prefs_service.dart';
import 'package:loki/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:loki/features/auth/domain/entities/auth_user.dart';
import 'package:loki/features/auth/domain/repositories/auth_repository.dart';
import 'package:loki/features/auth/domain/usecases/auth_usecases.dart';

class AuthController extends GetxController {
  AuthController({
    required EnsureAnonymousSessionUseCase ensureAnonymous,
    required LinkAccountUseCase linkAccount,
    required AuthRepository authRepository,
    required PrefsService prefsService,
  }) : this._(
         ensureAnonymous: ensureAnonymous,
         linkAccount: linkAccount,
         authRepository: authRepository,
         prefsService: prefsService,
       );

  AuthController._({
    required this._ensureAnonymous,
    required this._linkAccount,
    required this._authRepository,
    required this._prefsService,
  });

  final EnsureAnonymousSessionUseCase _ensureAnonymous;
  final LinkAccountUseCase _linkAccount;
  final AuthRepository _authRepository;
  final PrefsService _prefsService;

  final Rxn<AuthUser> currentUser = Rxn<AuthUser>();
  final RxBool isDarkMode = false.obs;
  final RxString localeCode = 'vi_VN'.obs;
  final RxString statusMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _prefsService.isDarkMode;
    localeCode.value = _prefsService.localeCode;
    currentUser.value = _authRepository.getCurrentUser();
    _ensureAnonymous().then((res) {
      res.fold(
        (u) => currentUser.value = u,
        (f) {
          if (f.code == 'admin-restricted-operation') {
            statusMessage.value =
                'Hãy liên kết/đăng nhập Google hoặc Email để đồng bộ dữ liệu.';
          }
        },
      );
    });
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode.value = value;
    await _prefsService.setDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> switchLocale(String code) async {
    localeCode.value = code;
    await _prefsService.setLocaleCode(code);
    final parts = code.split('_');
    Get.updateLocale(Locale(parts[0], parts[1]));
  }

  Future<void> linkWithGoogle() async {
    final res = await _linkAccount.withGoogle();
    res.fold((user) {
      currentUser.value = user;
      statusMessage.value = 'Đã liên kết Google thành công!';
    }, (f) => statusMessage.value = f.message);
  }

  Future<void> linkWithEmail(String email, String password) async {
    final res = await _linkAccount.withEmailPassword(email, password);
    res.fold((user) {
      currentUser.value = user;
      statusMessage.value = 'Đã liên kết Email thành công!';
    }, (f) => statusMessage.value = f.message);
  }
}

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(
      () => FirebaseAuthRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut(
      () => EnsureAnonymousSessionUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => LinkAccountUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => AuthController(
        ensureAnonymous: Get.find<EnsureAnonymousSessionUseCase>(),
        linkAccount: Get.find<LinkAccountUseCase>(),
        authRepository: Get.find<AuthRepository>(),
        prefsService: Get.find<PrefsService>(),
      ),
      fenix: true,
    );
  }
}
