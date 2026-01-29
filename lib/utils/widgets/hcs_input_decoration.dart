import 'package:flutter/material.dart';

InputDecoration hcsDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
  EdgeInsets? contentPadding,
}) {
  final themeDecoration = Theme.of(context).inputDecorationTheme;

  return const InputDecoration()
      .applyDefaults(themeDecoration)
      .copyWith(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        errorText: errorText,
        contentPadding: contentPadding,
        floatingLabelBehavior: FloatingLabelBehavior.never,
      );
}
