import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/auth/presentation/login_screen.dart';
import 'package:hcs_app_lap/features/auth/presentation/splash_screen.dart';
import 'package:hcs_app_lap/features/main_shell/screen/main_shell_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // En tests/widget environments Firebase puede no estar inicializado.
    // En ese caso, degradamos a estado "no autenticado" para evitar crashes.
    Stream<User?>? authStream;
    try {
      authStream = FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return const LoginScreen();
    }

    return StreamBuilder<User?>(
      stream: authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          return const MainShellScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
