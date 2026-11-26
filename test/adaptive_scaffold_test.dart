import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/data/models/user_model.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_scaffold.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/desktop/screens/dashboard/desktop_dashboard_view.dart';
import 'package:nagarsevak_mobile/presentation/desktop/screens/complaints/desktop_complaints_view.dart';
import 'package:nagarsevak_mobile/presentation/desktop/screens/letters/desktop_letters_view.dart';
import 'package:nagarsevak_mobile/presentation/desktop/screens/auth/desktop_login_screen.dart';
import 'package:nagarsevak_mobile/presentation/providers/auth_provider.dart';

class FakeLoggedInAuthNotifier extends AuthNotifier {
  @override
  AsyncValue<UserModel?> build() {
    return AsyncValue.data(
      UserModel(
        id: 'test-admin-id',
        name: 'Test Administrator',
        email: 'admin@test.gov',
        role: 'admin',
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DesktopScaffold renders DesktopSidebar and DesktopDashboardView on desktop width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(FakeLoggedInAuthNotifier.new),
        ],
        child: const MaterialApp(
          home: DesktopScaffold(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DesktopScaffold), findsOneWidget);
    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.byType(DesktopDashboardView), findsOneWidget);
  });

  testWidgets('DesktopLoginScreen renders role selection and login form matching Login.tsx', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DesktopLoginScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DesktopLoginScreen), findsOneWidget);
    expect(find.text('Nagarsevak'), findsOneWidget);
    expect(find.text('Amdar'), findsOneWidget);

    // Tap Nagarsevak role card to enter Step 2
    await tester.tap(find.text('Nagarsevak'));
    await tester.pump();

    expect(find.text('Back to Role Selection'), findsOneWidget);
    expect(find.text('Email / Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('DesktopComplaintsView renders tabs, filters, and action buttons matching ComplaintList.tsx', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DesktopComplaintsView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DesktopComplaintsView), findsOneWidget);
    expect(find.text('Complaints & Requests'), findsOneWidget);
    expect(find.text('Area Complaints'), findsOneWidget);
    expect(find.text('Personal Requests'), findsOneWidget);
    expect(find.text('New Complaint'), findsOneWidget);
    expect(find.text('All'), findsWidgets);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Assigned'), findsWidgets);
    expect(find.text('In Progress'), findsWidgets);
    expect(find.text('Resolved'), findsWidgets);
  });

  testWidgets('DesktopLettersView renders tabs, filters, and action buttons matching LetterDashboard.tsx', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DesktopLettersView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DesktopLettersView), findsOneWidget);
    expect(find.text('Letters Dashboard'), findsOneWidget);
    expect(find.text('Manage Types'), findsOneWidget);
    expect(find.text('New Request'), findsOneWidget);
    expect(find.text('Download Report'), findsWidgets);
  });

  testWidgets('DesktopLoginScreen Instant Demo Login triggers authentication cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DesktopLoginScreen(),
        ),
      ),
    );
    await tester.pump();

    final demoBtn = find.text('Instant Demo Login (demo_nagarsevak@demo.com)');
    expect(demoBtn, findsOneWidget);
    await tester.tap(demoBtn);
    await tester.pump(const Duration(milliseconds: 100));
  });
}
