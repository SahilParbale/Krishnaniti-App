import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AppButtonVariant {
  primary, // Brand blue #0284C7
  secondary, // Outlined with brand border
  tonal, // Light blue tint
  danger, // Red for deletions and sign out
}

/// Standardized action button for Krishnaniti apps.
/// Ensures consistent heights (42px compact, 48px regular), padding, typography, and loading states.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isCompact;
  final bool isFullWidth;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isCompact = false,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isCompact = false,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isCompact = false,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isCompact = false,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final height = isCompact ? 38.0 : 46.0;
    final fontSize = isCompact ? 12.5 : 13.5;

    Widget child;

    if (variant == AppButtonVariant.secondary) {
      child = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brandPrimary,
          side: const BorderSide(color: AppColors.brandBorder),
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _buildContent(fontSize, AppColors.brandPrimary),
      );
    } else if (variant == AppButtonVariant.danger) {
      child = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusPending,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _buildContent(fontSize, Colors.white),
      );
    } else if (variant == AppButtonVariant.tonal) {
      child = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand50,
          foregroundColor: AppColors.brandDark,
          elevation: 0,
          side: const BorderSide(color: AppColors.brandBorder),
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _buildContent(fontSize, AppColors.brandDark),
      );
    } else {
      // Primary
      child = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _buildContent(fontSize, Colors.white),
      );
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: child,
      );
    }

    return SizedBox(
      height: height,
      child: child,
    );
  }

  Widget _buildContent(double fontSize, Color contentColor) {
    if (isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: contentColor),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isCompact ? 16 : 18, color: contentColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
      overflow: TextOverflow.ellipsis,
    );
  }
}
