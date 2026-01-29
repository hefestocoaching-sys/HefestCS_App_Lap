import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
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
      await dotenv.load(fileName: envFile);
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

  // Es una buena práctica inicializar el locale antes de establecerlo como default.
  await initializeDateFormatting('es', null);
  Intl.defaultLocale = 'es';

  await _loadEnvIfAvailable();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: HcsAppLap()));
}
