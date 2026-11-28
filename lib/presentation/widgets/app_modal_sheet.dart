import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../providers/language_provider.dart';

/// Standardized fixed header for all modal bottom sheets and popups across the app.
class AppModalHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final Color iconColor;
  final Color? iconBgColor;

  const AppModalHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onClose,
    this.iconColor = const Color(0xFF0284C7),
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = iconBgColor ?? iconColor.withValues(alpha: 0.1);
    final isDesktop = kIsWeb ||
        (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ||
        (MediaQuery.maybeOf(context)?.size.width ?? 0) >= 768;

    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final resolvedTitle = AppTranslations.formatDigits(
          AppTranslations.tr(title, lang: lang) ?? title,
          lang,
        );
        final resolvedSub = subtitle != null && subtitle!.isNotEmpty
            ? AppTranslations.formatDigits(
                AppTranslations.tr(subtitle!, lang: lang) ?? subtitle!,
                lang,
              )
            : null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDesktop)
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          resolvedTitle,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (resolvedSub != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            resolvedSub,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                      onPressed: onClose,
                      tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
        );
      },
    );
  }
}

/// Standardized field label with red asterisk for mandatory (100% required) fields.
class AppFieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? optionalHint;

  const AppFieldLabel({
    super.key,
    required this.label,
    this.isRequired = false,
    this.optionalHint,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final resolvedLabel = AppTranslations.formatDigits(
          AppTranslations.tr(label, lang: lang) ?? label,
          lang,
        );
        final resolvedOpt = optionalHint != null
            ? (optionalHint == 'Optional'
                ? AppTranslations.pick(lang, en: 'Optional', mr: 'ऐच्छिक', hi: 'वैकल्पिक')
                : AppTranslations.formatDigits(
                    AppTranslations.tr(optionalHint!, lang: lang) ?? optionalHint!,
                    lang,
                  ))
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  resolvedLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              if (!isRequired && resolvedOpt != null)
                Text(
                  ' ($resolvedOpt)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Standard input decoration helper matching the app's clean UI design.
InputDecoration appInputDecoration({
  String? hint,
  String? prefixText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool isDense = true,
}) {
  return InputDecoration(
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
    prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
    filled: true,
    fillColor: Colors.white,
    isDense: isDense,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
  );
}
