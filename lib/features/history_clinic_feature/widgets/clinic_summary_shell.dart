import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class ClinicSummaryShell extends StatelessWidget {
  final Widget header; // ClinicClientHeaderWithTabs
  final Widget body; // TabBarView

  const ClinicSummaryShell({
    super.key,
    required this.header,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
