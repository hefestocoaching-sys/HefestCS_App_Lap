import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/firebase_options.dart';

Future<void> bootstrapFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureAppCheck();
}

Future<void> _configureAppCheck() async {
  if (kIsWeb) {
    throw UnsupportedError(
      'Firebase App Check web bootstrap is not configured. Run flutterfire configure and provide a real reCAPTCHA site key before enabling Web.',
    );
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      return;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      await FirebaseAppCheck.instance.activate(
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleDeviceCheckProvider(),
      );
      return;
    case TargetPlatform.windows:
      logger.info(
        'Firebase App Check skipped on Windows because firebase_app_check has no Windows provider.',
      );
      return;
    case TargetPlatform.linux:
      logger.info(
        'Firebase App Check skipped on Linux because Firebase options are not configured for this platform.',
      );
      return;
    default:
      throw UnsupportedError(
        'Firebase App Check is not configured for $defaultTargetPlatform.',
      );
  }
}
