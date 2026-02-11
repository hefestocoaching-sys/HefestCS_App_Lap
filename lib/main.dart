import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:hcs_app_lap/core/services/sync_service.dart';
import 'package:hcs_app_lap/core/config/feature_flags.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/services/food_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'app.dart'; // Asumiendo que HcsAppLap está definido en app.dart

Future<void> _loadEnvIfAvailable() async {
  const envFile = '.env';
  final file = File(envFile);
  if (await file.exists()) {
    try {
      await dotenv.load();
    } catch (e) {
      debugPrint('⚠️ No se pudo cargar $envFile: $e');
    }
  } else {
    debugPrint(
      '⚠️ Archivo .env no encontrado; ejecutando con valores por defecto.',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await foodDB.loadDatabase();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await _loadEnvIfAvailable();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Activar Firebase App Check (solo plataformas soportadas)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );
    } catch (e) {
      logger.warning('Firebase App Check activation failed', {'error': e});
    }
  } else {
    logger.info('Firebase App Check skipped for unsupported platform');
  }

  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';

  if (FeatureFlags.enableBackgroundSync) {
    SyncService.instance.start();
  }

  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

  runApp(const ProviderScope(child: HcsAppLap()));
}
