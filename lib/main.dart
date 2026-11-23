import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loki/app.dart';
import 'package:loki/core/firebase/firebase_bootstrap.dart';
import 'package:loki/core/storage/prefs_service.dart';
import 'package:loki/core/storage/secure_storage_service.dart';
import 'package:loki/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final prefsService = PrefsService(prefs);
  Get.put<PrefsService>(prefsService, permanent: true);
  Get.put<SecureStorageService>(SecureStorageService(), permanent: true);

  runApp(LokiApp(prefsService: prefsService));
}
