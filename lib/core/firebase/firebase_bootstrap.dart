import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:loki/core/utils/app_logger.dart';

/// Initializes Firebase Core and enables unlimited Cloud Firestore offline persistence.
final class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<bool> initialize({FirebaseOptions? options}) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      AppLogger.info(
        'FirebaseBootstrap',
        'Firebase & offline persistence ready',
      );
      return true;
    } catch (e, st) {
      AppLogger.error(
        'FirebaseBootstrap',
        'Firebase init skipped or failed (configure via flutterfire)',
        e,
        st,
      );
      return false;
    }
  }
}
