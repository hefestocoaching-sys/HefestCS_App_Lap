import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class ClinicSummaryFrame extends StatelessWidget {
  final Widget header; // aquí va foto+nombre+objetivo+chips
  final TabController controller;
  final List<Tab> tabs;
  final Widget tabView; // TabBarView

  const ClinicSummaryFrame({
    super.key,
    required this.header,
    required this.controller,
    required this.tabs,
    required this.tabView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER CLIENT SUMMARY (band superior grande)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCardColor.withValues(alpha: 0.34),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: header,
          ),

          // TAB STRIP (esto es lo que falta en tu app: la banda integrada)
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: kCardColor.withValues(alpha: 0.22),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: controller,
                isScrollable: true,
                labelColor: kTextColor,
                unselectedLabelColor: kTextColorSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: kPrimaryColor.withValues(alpha: 0.9),
                    width: 2.5,
                  ),
                ),
                tabs: tabs,
              ),
            ),
          ),

          // CONTENT (dentro del mismo contenedor, igual al mockup)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: tabView,
            ),
          ),
        ],
      ),
    );
  }
}
