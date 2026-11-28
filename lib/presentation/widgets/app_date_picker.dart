import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../providers/language_provider.dart';

/// Shows a date picker explicitly themed to Krishnaniti's primary Sky Blue branding
/// and localized to the active app language (`en`, `mr`, `hi`).
Future<DateTime?> showThemedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  String? helpText,
}) async {
  final lang = appLanguageValueNotifier.value;
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: Locale(lang),
    initialEntryMode: initialEntryMode,
    helpText: helpText ?? AppTranslations.pick(lang, en: 'Select Date', mr: 'तारीख निवडा', hi: 'तिथि चुनें'),
    cancelText: AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
    confirmText: AppTranslations.pick(lang, en: 'OK', mr: 'ठीक आहे', hi: 'ठीक है'),
    builder: (ctx, child) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.brandPrimary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            headerBackgroundColor: AppColors.brandPrimary,
            headerForegroundColor: Colors.white,
            headerHeadlineStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              if (states.contains(WidgetState.disabled)) return AppColors.textMuted.withValues(alpha: 0.35);
              return AppColors.textPrimary;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.brandPrimary;
              return null;
            }),
            todayForegroundColor: WidgetStateProperty.all(AppColors.brandPrimary),
            todayBorder: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Standardized date selector field with clean calendar icon and 3-language localized display.
class AppDatePickerField extends StatelessWidget {
  final String? label;
  final bool isRequired;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String hintText;
  final DateFormat? dateFormat;

  const AppDatePickerField({
    super.key,
    this.label,
    this.isRequired = false,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.hintText = 'Select Date',
    this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final hasValue = selectedDate != null;
        final String displayText;
        if (hasValue) {
          displayText = AppTranslations.formatDate(
            selectedDate!,
            lang,
            pattern: dateFormat?.pattern ?? 'dd MMM yyyy',
          );
        } else {
          displayText = hintText == 'Select Date'
              ? AppTranslations.pick(lang, en: 'Select Date', mr: 'तारीख निवडा', hi: 'तिथि चुनें')
              : AppTranslations.formatDigits(AppTranslations.tr(hintText, lang: lang) ?? hintText, lang);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        AppTranslations.formatDigits(
                          AppTranslations.tr(label!, lang: lang) ?? label!,
                          lang,
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
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
                  ],
                ),
              ),
            InkWell(
              onTap: () async {
                final picked = await showThemedDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: firstDate ?? DateTime(2020),
                  lastDate: lastDate ?? DateTime(2035),
                );
                if (picked != null) {
                  onDateSelected(picked);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasValue ? AppColors.brandBorder : AppColors.slate300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.brandPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                          color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.brandPrimary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
