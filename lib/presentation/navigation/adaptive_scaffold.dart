import 'package:flutter/material.dart';
import 'main_scaffold.dart';
import '../desktop/shell/desktop_scaffold.dart';
import '../screens/landing/landing_screen.dart';
import '../desktop/screens/auth/desktop_login_screen.dart';

/// Clean adaptive shell that dynamically routes to DesktopScaffold on screens >= 1024px,
/// while preserving the exact mobile MainScaffold on touch/mobile screens.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return const DesktopScaffold();
        }
        return const MainScaffold();
      },
    );
  }
}

/// Adaptive onboarding & login router that serves the 2-column desktop portal login
/// on desktop displays (>= 1024px), while showing the mobile carousel onboarding on phones.
class AdaptiveLandingScreen extends StatelessWidget {
  const AdaptiveLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return const DesktopLoginScreen();
        }
        return const LandingScreen();
      },
    );
  }
}
