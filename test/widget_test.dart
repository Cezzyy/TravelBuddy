import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:travelbuddy/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    // Verify the splash placeholder screen renders
    expect(find.text('Splash'), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
