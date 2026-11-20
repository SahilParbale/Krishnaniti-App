import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nagarsevak_mobile/main.dart';
import 'package:nagarsevak_mobile/data/models/user_model.dart';
import 'package:nagarsevak_mobile/presentation/providers/auth_provider.dart';

class FakeLoggedOutAuthNotifier extends AuthNotifier {
  @override
  AsyncValue<UserModel?> build() {
    return const AsyncValue.data(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NagarsevakApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(FakeLoggedOutAuthNotifier.new),
        ],
        child: const NagarsevakApp(),
      ),
    );
    expect(find.byType(NagarsevakApp), findsOneWidget);
  });
}
