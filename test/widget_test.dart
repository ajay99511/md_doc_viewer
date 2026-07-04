import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_explorer/main.dart';

void main() {
  // SharedPreferences has no platform implementation under flutter_test;
  // provide an in-memory store so settings can load without throwing.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App boots and renders a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MDExplorerApp()));
    // A single pump (no settle — the spatial background animates forever).
    await tester.pump();
    expect(find.byType(MDExplorerApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
