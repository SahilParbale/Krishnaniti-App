import 'package:flutter/material.dart';

/// Centralised responsive breakpoint helper for the Desktop Shell.
///
/// Usage — from a widget's build method:
/// ```dart
/// final r = DesktopResponsive.of(context);
/// // or inside LayoutBuilder:
/// LayoutBuilder(builder: (ctx, constraints) {
///   final r = DesktopResponsive.layout(constraints);
///   ...
/// })
/// ```
class DesktopResponsive {
  final double width;
  const DesktopResponsive(this.width);

  /// Create from the nearest [MediaQuery].
  static DesktopResponsive of(BuildContext context) =>
      DesktopResponsive(MediaQuery.sizeOf(context).width);

  /// Create from [BoxConstraints] inside a [LayoutBuilder].
  static DesktopResponsive layout(BoxConstraints constraints) =>
      DesktopResponsive(constraints.maxWidth);

  // ── Breakpoint booleans ─────────────────────────────────────────────────
  /// < 1100 px  — small laptop / tablet-landscape
  bool get isCompact => width < 1100;

  /// 1100–1440 px — standard laptop
  bool get isStandard => width >= 1100 && width < 1440;

  /// 1440–1800 px — large laptop / small external monitor
  bool get isWide => width >= 1440 && width < 1800;

  /// ≥ 1800 px  — large monitor / 4K
  bool get isXLarge => width >= 1800;

  // ── Grid column counts ───────────────────────────────────────────────────
  /// Columns for stat / KPI cards (preserves 4-column desktop row, 2 on compact).
  int get statCardColumns => isCompact ? 2 : 4;

  /// Columns for general content grids (preserves 3-column desktop layout, adapts on compact).
  int get gridColumns => width < 650 ? 1 : (isCompact ? 2 : 3);

  /// Columns for detail / info grids (ward map, provisions, etc.).
  int get detailGridColumns => isCompact ? 1 : (isWide || isXLarge ? 3 : 2);

  // ── Spacing & padding ────────────────────────────────────────────────────
  /// Outer horizontal + vertical padding for screen content.
  double get contentPadding => isCompact ? 16 : (isStandard ? 24 : (isWide ? 28 : 32));

  /// Padding specifically for the header bar.
  double get headerPadding => isCompact ? 16 : 28;

  /// Height of the top header bar.
  double get headerHeight => isCompact ? 60 : 72;

  /// Card aspect ratio used in grid views.
  double get cardAspectRatio => isCompact ? 1.4 : (isStandard ? 1.6 : 1.8);

  // ── Layout helpers ───────────────────────────────────────────────────────
  /// Whether to show secondary / detail panel inline (master-detail).
  bool get showInlineDetail => !isCompact;

  /// Maximum width for centred form / settings content.
  double get formMaxWidth => isCompact ? double.infinity : (isStandard ? 760 : 860);

  /// Maximum width for a dialog / modal.
  double maxDialogWidth(double preferred) =>
      preferred.clamp(320, width * (isCompact ? 0.90 : 0.80));

  // ── Convenience EdgeInsets ───────────────────────────────────────────────
  EdgeInsets get screenPadding => EdgeInsets.all(contentPadding);

  EdgeInsets get screenPaddingH =>
      EdgeInsets.symmetric(horizontal: contentPadding, vertical: contentPadding);

  // ── Typography scale factor ──────────────────────────────────────────────
  /// Multiply base font sizes by this to scale across breakpoints.
  double get fontScale => isCompact ? 0.92 : 1.0;
}

/// A widget that rebuilds whenever the window is resized — wraps [LayoutBuilder]
/// and provides a [DesktopResponsive] to its builder.
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, DesktopResponsive r) builder;

  const ResponsiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) => builder(ctx, DesktopResponsive.of(ctx)),
    );
  }
}

