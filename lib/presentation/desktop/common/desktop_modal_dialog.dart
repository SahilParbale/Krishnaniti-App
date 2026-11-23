import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Unified desktop modal dialog shell for input popups and forms
class DesktopModalDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final List<Widget>? actions;
  final double width;
  final double maxHeight;
  final VoidCallback? onClose;

  const DesktopModalDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.actions,
    this.width = 620,
    this.maxHeight = 760,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Center(
        child: Container(
          width: width,
          constraints: BoxConstraints(maxHeight: maxHeight),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.slate100, width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.brand50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.brand200, width: 1),
                        ),
                        child: Icon(icon, color: AppColors.brand600, size: 20),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.slate400),
                      hoverColor: AppColors.slate100,
                      splashRadius: 18,
                      tooltip: 'Close',
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Form Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
                  child: child,
                ),
              ),

              // Footer Actions
              if (actions != null && actions!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: AppColors.slate100, width: 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper method to open any dialog as a unified desktop popup
Future<T?> showDesktopModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: builder,
  );
}

/// Standardized desktop input decoration for form fields inside modals
InputDecoration desktopInputDecoration({
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    errorText: errorText,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.slate200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.slate200),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: AppColors.brand600, width: 1.5),
    ),
  );
}
