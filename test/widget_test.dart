// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/app.dart';

void main() {
  testWidgets('App mounts with ProviderScope', (WidgetTester tester) async {
    // Wrap app with ProviderScope to ensure Riverpod has a root scope in tests.
    await tester.pumpWidget(const ProviderScope(child: HcsAppLap()));

    // Allow frames to settle.
    await tester.pumpAndSettle();

    expect(find.byType(HcsAppLap), findsOneWidget);
  });
}
