import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/navigation/client_open_origin.dart';
import 'package:hcs_app_lap/features/main_shell/screen/main_shell_screen.dart';

Future<void> openClientChart(
  BuildContext context,
  String clientId,
  ClientOpenOrigin origin,
) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          MainShellScreen(initialClientId: clientId, openOrigin: origin),
    ),
  );
}
