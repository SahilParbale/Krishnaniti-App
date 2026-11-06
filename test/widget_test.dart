import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/main.dart';

void main() {
  testWidgets('NagarsevakApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NagarsevakApp(),
      ),
    );
    expect(find.byType(NagarsevakApp), findsOneWidget);
  });
}
