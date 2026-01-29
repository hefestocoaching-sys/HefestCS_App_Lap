import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'features/auth/presentation/auth_gate.dart';

class HcsAppLap extends StatelessWidget {
  const HcsAppLap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HCS App LAP',
      debugShowCheckedModeBanner: false,
      theme: appThemeData,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      home: const AuthGate(),
    );
  }
}
