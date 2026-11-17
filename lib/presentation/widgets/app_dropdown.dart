import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Unified, themed dropdown component matching the Krishnaniti civic application theme.
/// Replaces inconsistent raw DropdownButtons across pages.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final Widget? prefixIcon;
  final double height;
  final bool isDense;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    String? hint,
    String? hintText,
    this.prefixIcon,
    this.height = 40,
    this.isDense = true,
    this.isExpanded = true,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  }) : hintText = hintText ?? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor ?? AppColors.slate300,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: isDense,
          isExpanded: isExpanded,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 6,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.brandPrimary,
            size: 20,
          ),
          hint: hintText != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefixIcon != null) ...[
                      prefixIcon!,
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        hintText!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : null,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Form-field dropdown with built-in Krishnaniti styling and label + required asterisk.
class AppDropdownFormField<T> extends StatelessWidget {
  final String? label;
  final bool isRequired;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final String? hintText;
  final Widget? prefixIcon;
  final Color? fillColor;

  const AppDropdownFormField({
    super.key,
    this.label,
    this.isRequired = false,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.hintText,
    this.prefixIcon,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
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
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 6,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.brandPrimary,
            size: 20,
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
            ),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: fillColor ?? Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.slate300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
