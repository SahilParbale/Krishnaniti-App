import 'package:flutter/material.dart';

/// Exact color palette mirroring Nagarsevak-Managment Tailwind theme:
/// Brand Sky Blue (brand-600 #0284c7, brand-700 #0369a1),
/// Slate neutrals (slate-50 to slate-900), and status tokens.
class AppColors {
  AppColors._();

  // Brand Primaries (Sky Blue Palette from Nagarsevak-Managment)
  static const Color brand50 = Color(0xFFF0F9FF);
  static const Color brand100 = Color(0xFFE0F2FE);
  static const Color brand200 = Color(0xFFBAE6FD);
  static const Color brand300 = Color(0xFF7DD3FC);
  static const Color brand400 = Color(0xFF38BDF8);
  static const Color brand500 = Color(0xFF0EA5E9);
  static const Color brand600 = Color(0xFF0284C7); // Primary Brand
  static const Color brand700 = Color(0xFF0369A1); // Brand Dark / Hover
  static const Color brand800 = Color(0xFF075985);
  static const Color brand900 = Color(0xFF0C4A6E);
  static const Color brand950 = Color(0xFF082F49);

  // Aliases for clean semantic usage
  static const Color brandPrimary = brand600;
  static const Color brandDark = brand700;
  static const Color brandLight = brand100;
  static const Color brandSubtle = brand50;
  static const Color brandBorder = brand200;

  // Slate Palette (Neutrals matching web app)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Surfaces & Layout
  static const Color background = slate50;
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = slate100;
  static const Color border = slate200;
  static const Color borderFocus = brand400;

  // Typography Colors
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate600;
  static const Color textMuted = slate500;
  static const Color textInverse = Colors.white;

  // Status Colors (Matching Nagarsevak-Managment)
  static const Color statusPending = Color(0xFFDC2626); // Red 600
  static const Color statusPendingLight = Color(0xFFFEF2F2); // Red 50
  static const Color statusPendingBorder = Color(0xFFFECACA); // Red 200

  static const Color statusInProgress = Color(0xFFD97706); // Amber 600
  static const Color statusInProgressLight = Color(0xFFFFFBEB); // Amber 50
  static const Color statusInProgressBorder = Color(0xFFFDE68A); // Amber 200

  static const Color statusResolved = Color(0xFF16A34A); // Green 600
  static const Color statusResolvedLight = Color(0xFFF0FDF4); // Green 50
  static const Color statusResolvedBorder = Color(0xFFBBF7D0); // Green 200

  // Brand Gradients matching Nagarsevak-Managment: from-brand-600 to-brand-700
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brand600, brand700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
