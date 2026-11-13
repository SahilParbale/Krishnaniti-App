import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';

/// Intelligent Mobile Screen Touch Leading Action Button.
/// - Shows a crisp Back Button (`<-`) when on any sub-screen, with haptic feedback & sliding pop.
/// - Shows a Menu Drawer Icon (`☰`) when at root/home, with haptic feedback to open sidebar.
class AppBarLeadingNavButton extends ConsumerWidget {
  final VoidCallback? onBack;
  final bool forceDrawer;
  final bool forceBack;
  final Color iconColor;

  const AppBarLeadingNavButton({
    super.key,
    this.onBack,
    this.forceDrawer = false,
    this.forceBack = false,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPop = ref.watch(canPopProvider);
    final isMr = ref.watch(isMarathiProvider);
    final showBack = (canPop || forceBack) && !forceDrawer;

    if (showBack) {
      return IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: iconColor, size: 24),
        tooltip: isMr ? 'मागे जा' : 'Back',
        onPressed: () {
          HapticFeedback.lightImpact();
          if (onBack != null) {
            onBack!();
          } else {
            ref.read(activeScreenProvider.notifier).popScreen();
          }
        },
      );
    }

    return Builder(
      builder: (scaffoldCtx) => IconButton(
        icon: Icon(Icons.menu_rounded, color: iconColor, size: 24),
        tooltip: isMr ? 'मेनू उघडा' : 'Open Menu Drawer',
        onPressed: () {
          HapticFeedback.lightImpact();
          Scaffold.of(scaffoldCtx).openDrawer();
        },
      ),
    );
  }
}
