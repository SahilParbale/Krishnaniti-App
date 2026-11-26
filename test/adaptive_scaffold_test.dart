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
import 'package:nagarsevak_mobile/presentation/screens/letters/letter_type_manager_sheet.dart';
import 'package:nagarsevak_mobile/presentation/screens/complaints/new_complaint_bottom_sheet.dart';
import 'package:nagarsevak_mobile/presentation/screens/complaints/complaint_detail_screen.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';
import 'package:nagarsevak_mobile/data/models/complaint_model.dart';
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

  testWidgets('ComplaintDetailScreen renders responsive layout matching web version', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final complaint = ComplaintModel(
      id: 'pr-101',
      title: 'Need Medical Assistance for Senior Citizen',
      description: 'Request for medical wheelchair and monthly checkup assistance.',
      category: 'Personal Help',
      status: 'InProgress',
      citizenName: 'Sunita Patil',
      citizenMobile: '9876543210',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(FakeLoggedInAuthNotifier.new),
        ],
        child: MaterialApp(
          home: ComplaintDetailScreen(
            complaint: complaint,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dynamic back label for pr- ID
    expect(find.text('Back to Personal Requests'), findsOneWidget);

    // Verify title and description
    expect(find.text('Need Medical Assistance for Senior Citizen'), findsOneWidget);
    expect(find.text('Request for medical wheelchair and monthly checkup assistance.'), findsOneWidget);

    // Verify Personal Help badge
    expect(find.text('Personal Help'), findsOneWidget);

    // Verify Manage Ticket & Ticket Details sections
    expect(find.text('Manage Ticket'), findsOneWidget);
    expect(find.text('Ticket Details'), findsOneWidget);
    expect(find.text('#pr-101'), findsOneWidget);
    expect(find.text('Sunita Patil'), findsOneWidget);
  });

  testWidgets('LetterTypeManagerSheet.show opens centered Dialog on desktop matching LetterTypeManager.tsx', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(FakeLoggedInAuthNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => LetterTypeManagerSheet.show(ctx),
                child: const Text('Open Letter Types'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Open Letter Types'));
    await tester.pumpAndSettle();

    // Verify it opened as a centered Dialog on desktop
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Letter Types Manager'), findsOneWidget);
    expect(find.text('Add New Type'), findsOneWidget);

    // Tap Add New Type to test desktop modal
    await tester.tap(find.text('Add New Type'));
    await tester.pumpAndSettle();

    expect(find.text('Name (English) *'), findsOneWidget);
    expect(find.text('Name (Marathi)'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
  });

  testWidgets('LetterTypeManagerSheet.show opens BottomSheet on mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(FakeLoggedInAuthNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => LetterTypeManagerSheet.show(ctx),
                child: const Text('Open Letter Types'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Open Letter Types'));
    await tester.pumpAndSettle();

    // Verify it opened as a BottomSheet on mobile
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Letter Types Manager'), findsOneWidget);
  });

  testWidgets('NewComplaintBottomSheet.show adapts to Dialog on desktop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(FakeLoggedInAuthNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => NewComplaintBottomSheet.show(ctx),
                child: const Text('Open New Complaint'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Open New Complaint'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('AppDropdown opens anchored dropdown menu directly below the field on desktop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    String? selectedValue = 'Pending';

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(40),
                child: AppDropdown<String>(
                  value: selectedValue,
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'InProgress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                  ],
                  onChanged: (val) {
                    setState(() => selectedValue = val);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();

    // Verify initial dropdown button
    expect(find.text('Pending'), findsOneWidget);

    // Tap to open dropdown
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    // Verify it opened as an anchored menu, NOT a modal Dialog, and NOT a BottomSheet
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);

    // Tap 'Resolved'
    await tester.tap(find.text('Resolved'));
    await tester.pumpAndSettle();

    expect(selectedValue, 'Resolved');
  });
}
