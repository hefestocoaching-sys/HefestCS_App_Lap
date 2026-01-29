import 'package:flutter/material.dart';

/// Builds a decoration derived from the global InputDecorationTheme.
InputDecoration hcsDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
  EdgeInsetsGeometry? contentPadding,
}) {
  final theme = Theme.of(context).inputDecorationTheme;
  return const InputDecoration()
      .applyDefaults(theme)
      .copyWith(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        errorText: errorText,
        contentPadding: contentPadding,
      );
}
