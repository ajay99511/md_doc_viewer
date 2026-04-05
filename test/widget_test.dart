import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:md_explorer/main.dart';

void main() {
  testWidgets('App loads with ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MDExplorerApp()));
    expect(find.text('MD Explorer'), findsOneWidget);
  });
}
