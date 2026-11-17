import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AppPdfButtonStyle {
  primary, // Solid brand sky blue background, white text
  outlined, // White background, border, brand blue text with red PDF badge icon
  tonal, // Light brand blue (#F0F9FF) background, border #BAE6FD
  iconOnly, // Compact square icon button with subtle border
}

/// Standardized civic PDF Report and Document Download Button.
/// Ensures consistent branding, colors, and loading states across all 39 screens.
class AppPdfButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppPdfButtonStyle style;
  final bool isCompact;
  final bool isLoading;
  final String? tooltip;
  final IconData icon;

  const AppPdfButton({
    super.key,
    this.label = 'Reports',
    required this.onPressed,
    this.style = AppPdfButtonStyle.outlined,
    this.isCompact = true,
    this.isLoading = false,
    this.tooltip = 'Reports',
    this.icon = Icons.picture_as_pdf_rounded,
  });

  /// Convenient constructor for primary filled button (e.g. at the bottom of sheets)
  const AppPdfButton.primary({
    super.key,
    this.label = 'Reports',
    required this.onPressed,
    this.isCompact = false,
    this.isLoading = false,
    this.tooltip = 'Reports',
    this.icon = Icons.picture_as_pdf_rounded,
  }) : style = AppPdfButtonStyle.primary;

  /// Convenient constructor for compact outlined pill button (e.g. in filter rows)
  const AppPdfButton.outlined({
    super.key,
    this.label = 'Reports',
    required this.onPressed,
    this.isCompact = true,
    this.isLoading = false,
    this.tooltip = 'Reports',
    this.icon = Icons.picture_as_pdf_rounded,
  }) : style = AppPdfButtonStyle.outlined;

  /// Convenient constructor for icon-only export button (e.g. in AppBar actions)
  const AppPdfButton.icon({
    super.key,
    required this.onPressed,
    this.tooltip = 'Reports',
    this.isLoading = false,
    this.icon = Icons.picture_as_pdf_rounded,
  })  : label = 'Reports',
        style = AppPdfButtonStyle.iconOnly,
        isCompact = true;

  @override
  Widget build(BuildContext context) {
    if (style == AppPdfButtonStyle.iconOnly) {
      final button = InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: isCompact ? 36 : 42,
          height: isCompact ? 36 : 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.brandBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary),
                )
              : Icon(icon, size: isCompact ? 18 : 20, color: AppColors.brandPrimary),
        ),
      );

      return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
    }

    final height = isCompact ? 38.0 : 46.0;

    switch (style) {
      case AppPdfButtonStyle.primary:
        return SizedBox(
          height: height,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon, size: isCompact ? 16 : 18, color: Colors.white),
            label: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 12 : 13.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              elevation: 1,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      case AppPdfButtonStyle.tonal:
        return SizedBox(
          height: height,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary),
                  )
                : Icon(icon, size: isCompact ? 16 : 18, color: AppColors.brandPrimary),
            label: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: AppColors.brandDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand50,
              foregroundColor: AppColors.brandDark,
              elevation: 0,
              side: const BorderSide(color: AppColors.brandBorder),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      case AppPdfButtonStyle.outlined:
      default:
        return SizedBox(
          height: height,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary),
                  )
                : Icon(icon, size: isCompact ? 16 : 18, color: AppColors.brandPrimary),
            label: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.brandPrimary,
              side: const BorderSide(color: AppColors.brandBorder),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
    }
  }
}
