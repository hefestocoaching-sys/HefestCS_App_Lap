import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/training_feature/screens/training_dashboard_screen.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDateIso = dateIsoFrom(ref.watch(globalDateProvider));
    return PopScope(
      canPop: true,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: kCardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: TrainingDashboardScreen(activeDateIso: activeDateIso),
          ),
        ),
      ),
    );
  }
}
