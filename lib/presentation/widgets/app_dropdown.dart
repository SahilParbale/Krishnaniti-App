import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/services/translation_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/language_provider.dart';

/// Helper to recursively extract plain text from any child widget
/// (such as Text, Row, Column, Flexible, AppTranslatedText, etc.) for search filtering and display.
String _extractText(Widget widget) {
  if (widget is Text) {
    return widget.data ?? '';
  } else if (widget is AppTranslatedText) {
    return widget.text;
  } else if (widget is Row) {
    return widget.children.map(_extractText).where((s) => s.isNotEmpty).join(' ');
  } else if (widget is Column) {
    return widget.children.map(_extractText).where((s) => s.isNotEmpty).join(' ');
  } else if (widget is Flexible) {
    return _extractText(widget.child);
  } else if (widget is Expanded) {
    return _extractText(widget.child);
  } else if (widget is Padding && widget.child != null) {
    return _extractText(widget.child!);
  } else if (widget is Container && widget.child != null) {
    return _extractText(widget.child!);
  } else if (widget is DefaultTextStyle) {
    return _extractText(widget.child);
  }
  return '';
}

/// Reactive dropdown text label that works seamlessly with OR without a ProviderScope.
/// Translates English <-> Marathi <-> Hindi (including future dynamic DB items & numbers).
class _TranslatedDropdownText extends StatefulWidget {
  final String text;
  final String lang;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  const _TranslatedDropdownText(
    this.text, {
    required this.lang,
    required this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<_TranslatedDropdownText> createState() => _TranslatedDropdownTextState();
}

class _TranslatedDropdownTextState extends State<_TranslatedDropdownText> {
  String _resolved = '';
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _syncOrTranslate();
  }

  @override
  void didUpdateWidget(covariant _TranslatedDropdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.lang != widget.lang) {
      _syncOrTranslate();
    }
  }

  void _syncOrTranslate() {
    final clean = widget.text.trim();
    if (clean.isEmpty) {
      _resolved = widget.text;
      return;
    }

    final cached = DynamicTranslationService.getCachedTranslation(clean, widget.lang);
    if (cached != null) {
      _resolved = cached;
      return;
    }

    _resolved = AppTranslations.formatDigits(widget.text, widget.lang);
    final reqToken = ++_token;

    // Heuristic: ALL-CAPS multi-letter society/entity names transliterate cleanly if title-cased via translateOrRaw
    DynamicTranslationService.translateText(clean, widget.lang).then((val) {
      if (mounted && reqToken == _token && val != _resolved) {
        setState(() {
          _resolved = val;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final instant = DynamicTranslationService.getCachedTranslation(widget.text.trim(), widget.lang);
    final textToShow = instant ?? _resolved;
    return Text(
      AppTranslations.formatDigits(textToShow, widget.lang),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// Helper to derive a localized, contextual, user-facing title for the dropdown modal
String _resolveDropdownTitle<T>({
  String? explicitTitle,
  String? label,
  String? hintText,
  required List<DropdownMenuItem<T>> items,
  required String lang,
}) {
  String trLabel(String s) {
    final clean = s.trim();
    final cached = DynamicTranslationService.getCachedTranslation(clean, lang);
    return AppTranslations.formatDigits(cached ?? clean, lang);
  }

  if (explicitTitle != null &&
      explicitTitle.trim().isNotEmpty &&
      !_isGenericOption(explicitTitle)) {
    return trLabel(explicitTitle);
  }
  if (label != null &&
      label.trim().isNotEmpty &&
      !_isGenericOption(label)) {
    return trLabel(label);
  }
  if (hintText != null &&
      hintText.trim().isNotEmpty &&
      !_isGenericOption(hintText)) {
    return trLabel(hintText);
  }

  // Deduce from items
  for (final item in items) {
    final text = _extractText(item.child).trim();
    if (text.isEmpty) continue;

    if (text.startsWith('All ') || text.startsWith('all ')) {
      final noun = text.substring(4).trim();
      if (noun.isNotEmpty) return trLabel('Select $noun');
    }
    if ((text.startsWith('Select ') || text.startsWith('Choose ')) && !_isGenericOption(text)) {
      return trLabel(text);
    }
    if (text.startsWith('Filter by ')) {
      return trLabel(text);
    }
    if (text.startsWith('सर्व ')) {
      final noun = text.substring(5).trim();
      if (noun.isNotEmpty) {
        return lang == 'mr' ? '$noun निवडा' : trLabel('Select $noun');
      }
    }
    if (text.startsWith('सभी ')) {
      final noun = text.substring(4).trim();
      if (noun.isNotEmpty) {
        return lang == 'hi' ? '$noun चुनें' : trLabel('Select $noun');
      }
    }
    if (text.endsWith(' निवडा') && text != 'पर्याय निवडा') {
      return lang == 'mr' ? text : trLabel(text);
    }
    if (text.endsWith(' चुनें') && text != 'विकल्प चुनें') {
      return lang == 'hi' ? text : trLabel(text);
    }
  }

  return AppTranslations.pick(
    lang,
    en: 'Select Option',
    mr: 'पर्याय निवडा',
    hi: 'विकल्प चुनें',
  );
}

bool _isGenericOption(String text) {
  final lower = text.trim().toLowerCase();
  return lower == 'select option' ||
      lower == 'select options' ||
      lower == 'select...' ||
      lower == 'select' ||
      lower == 'पर्याय निवडा' ||
      lower == 'विकल्प चुनें';
}

/// Wrapper to differentiate between tapping a null option and tapping outside to dismiss
class _DropdownValueWrapper<T> {
  final T? value;
  const _DropdownValueWrapper(this.value);
}

/// Opens an anchored desktop dropdown menu positioned directly below the trigger field
Future<void> _openAnchoredDesktopDropdown<T>({
  required BuildContext context,
  required List<DropdownMenuItem<T>> items,
  required T? currentValue,
  required ValueChanged<T?> onSelected,
  required String lang,
}) async {
  final RenderBox? button = context.findRenderObject() as RenderBox?;
  if (button == null || !button.hasSize) return;

  final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) return;

  final double buttonWidth = button.size.width;
  final double buttonHeight = button.size.height;
  final Offset buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);

  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromLTWH(
      buttonTopLeft.dx,
      buttonTopLeft.dy + buttonHeight + 4,
      buttonWidth,
      buttonHeight,
    ),
    Offset.zero & overlay.size,
  );

  final selected = await showMenu<_DropdownValueWrapper<T>>(
    context: context,
    position: position,
    elevation: 8,
    shadowColor: Colors.black.withValues(alpha: 0.14),
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
    ),
    constraints: BoxConstraints(
      minWidth: math.max(buttonWidth, 180),
      maxWidth: math.max(buttonWidth, 280),
      maxHeight: 280,
    ),
    items: items.map((item) {
      final isSelected = item.value == currentValue;
      final itemStyle = TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF334155),
      );
      Widget childText;
      if (item.child is Text) {
        final t = item.child as Text;
        childText = _TranslatedDropdownText(
          t.data ?? '',
          lang: lang,
          style: itemStyle,
          overflow: TextOverflow.ellipsis,
        );
      } else {
        childText = DefaultTextStyle(
          style: itemStyle,
          overflow: TextOverflow.ellipsis,
          child: item.child,
        );
      }

      return PopupMenuItem<_DropdownValueWrapper<T>>(
        value: _DropdownValueWrapper<T>(item.value),
        height: 38,
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0284C7))
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Expanded(child: childText),
            ],
          ),
        ),
      );
    }).toList(),
  );

  if (selected != null) {
    onSelected(selected.value);
  }
}

/// Unified, themed dropdown component matching the Krishnaniti civic application theme.
/// Automatically translates labels, hints, options, search prompts, and numerals into EN / MR / HI.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final String? label;
  final String? title;
  final Widget? prefixIcon;
  final double height;
  final double? width;
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
    this.label,
    this.title,
    this.prefixIcon,
    this.height = 40,
    this.width,
    this.isDense = true,
    this.isExpanded = true,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  }) : hintText = hintText ?? hint;

  void _openPicker(BuildContext context, String lang) {
    if (onChanged == null) return;
    FocusScope.of(context).unfocus();

    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      _openAnchoredDesktopDropdown<T>(
        context: context,
        items: items,
        currentValue: value,
        onSelected: (val) => onChanged?.call(val),
        lang: lang,
      );
      return;
    }

    final modalTitle = _resolveDropdownTitle(
      explicitTitle: title,
      label: label,
      hintText: hintText,
      items: items,
      lang: lang,
    );
    final optionsWord = AppTranslations.pick(
      lang,
      en: 'options available',
      mr: 'पर्याय उपलब्ध',
      hi: 'विकल्प उपलब्ध',
    );

    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _AppDropdownModalSheet<T>(
        title: modalTitle,
        subtitle: '${AppTranslations.formatDigits(items.length, lang)} $optionsWord',
        icon: prefixIcon,
        items: items,
        selectedValue: value,
        lang: lang,
        onSelect: (val) {
          Navigator.pop(ctx);
          onChanged?.call(val);
        },
      ),
    );
  }

  Widget _buildSelectedDisplay(String lang) {
    if (value != null) {
      final selectedItem = items.cast<DropdownMenuItem<T>?>().firstWhere(
        (it) => it?.value == value,
        orElse: () => null,
      );
      if (selectedItem != null) {
        const selectedStyle = TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF334155),
        );
        if (selectedItem.child is Text) {
          final t = selectedItem.child as Text;
          return _TranslatedDropdownText(
            t.data ?? '',
            lang: lang,
            style: selectedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return DefaultTextStyle(
          style: selectedStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: selectedItem.child,
        );
      }
    }
    final displayHint = hintText ??
        label ??
        title ??
        AppTranslations.pick(lang, en: 'Select', mr: 'निवडा', hi: 'चुनें');
    return _TranslatedDropdownText(
      displayHint,
      lang: lang,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final content = Container(
              width: width,
              height: height,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor ?? const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 8),
                  ],
                  if (isExpanded)
                    Expanded(child: _buildSelectedDisplay(lang))
                  else
                    Flexible(child: _buildSelectedDisplay(lang)),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF94A3B8),
                    size: 19,
                  ),
                ],
              ),
            );

            return Builder(
              builder: (itemCtx) => InkWell(
                onTap: onChanged != null ? () => _openPicker(itemCtx, lang) : null,
                borderRadius: BorderRadius.circular(10),
                child: content,
              ),
            );
          },
        );
      },
    );
  }
}

/// Form-field dropdown with built-in Krishnaniti styling, label + required asterisk, and 3-language support.
class AppDropdownFormField<T> extends FormField<T> {
  final String? label;
  final String? title;
  final bool isRequired;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final Widget? prefixIcon;
  final Color? fillColor;
  final Color? borderColor;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;

  AppDropdownFormField({
    super.key,
    this.label,
    this.title,
    this.isRequired = false,
    T? value,
    required this.items,
    this.onChanged,
    super.validator,
    String? hint,
    String? hintText,
    this.prefixIcon,
    this.fillColor,
    this.borderColor,
    this.isExpanded = true,
    this.padding,
  })  : hintText = hintText ?? hint,
        super(
          initialValue: value,
          builder: (FormFieldState<T> state) {
            final effectiveValue = value ?? state.value;

            return ValueListenableBuilder<String>(
              valueListenable: appLanguageValueNotifier,
              builder: (context, lang, _) {
                void openPicker(BuildContext btnCtx) {
                  if (onChanged == null) return;
                  FocusScope.of(btnCtx).unfocus();

                  final isDesktop = MediaQuery.of(btnCtx).size.width >= 768;
                  if (isDesktop) {
                    _openAnchoredDesktopDropdown<T>(
                      context: btnCtx,
                      items: items,
                      currentValue: effectiveValue,
                      onSelected: (val) {
                        state.didChange(val);
                        onChanged(val);
                      },
                      lang: lang,
                    );
                    return;
                  }

                  final modalTitle = _resolveDropdownTitle(
                    explicitTitle: title,
                    label: label,
                    hintText: hintText ?? hint,
                    items: items,
                    lang: lang,
                  );
                  final optionsWord = AppTranslations.pick(
                    lang,
                    en: 'options available',
                    mr: 'पर्याय उपलब्ध',
                    hi: 'विकल्प उपलब्ध',
                  );

                  showModalBottomSheet<T>(
                    context: btnCtx,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.black54,
                    builder: (ctx) => _AppDropdownModalSheet<T>(
                      title: modalTitle,
                      subtitle: '${AppTranslations.formatDigits(items.length, lang)} $optionsWord',
                      icon: prefixIcon,
                      items: items,
                      selectedValue: effectiveValue,
                      lang: lang,
                      onSelect: (val) {
                        Navigator.pop(ctx);
                        state.didChange(val);
                        onChanged(val);
                      },
                    ),
                  );
                }

                Widget buildSelectedDisplay() {
                  if (effectiveValue != null) {
                    final selectedItem = items.cast<DropdownMenuItem<T>?>().firstWhere(
                      (it) => it?.value == effectiveValue,
                      orElse: () => null,
                    );
                    if (selectedItem != null) {
                      const selectedStyle = TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      );
                      if (selectedItem.child is Text) {
                        final t = selectedItem.child as Text;
                        return _TranslatedDropdownText(
                          t.data ?? '',
                          lang: lang,
                          style: selectedStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return DefaultTextStyle(
                        style: selectedStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: selectedItem.child,
                      );
                    }
                  }
                  final fallbackSelect = AppTranslations.pick(lang, en: 'Select', mr: 'निवडा', hi: 'चुनें');
                  final displayHint = hintText ??
                      hint ??
                      label ??
                      title ??
                      fallbackSelect;
                  return _TranslatedDropdownText(
                    displayHint,
                    lang: lang,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
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
                              child: _TranslatedDropdownText(
                                label,
                                lang: lang,
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
                    Builder(
                      builder: (btnCtx) => InkWell(
                        onTap: onChanged != null ? () => openPicker(btnCtx) : null,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: fillColor ?? Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: state.hasError
                                  ? const Color(0xFFEF4444)
                                  : (borderColor ?? const Color(0xFFE2E8F0)),
                              width: state.hasError ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (prefixIcon != null) ...[
                                prefixIcon,
                                const SizedBox(width: 8),
                              ],
                              Expanded(child: buildSelectedDisplay()),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF94A3B8),
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (state.hasError && state.errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: _TranslatedDropdownText(
                          state.errorText!,
                          lang: lang,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
}

/// Themed Krishnaniti bottom sheet modal selector for dropdowns.
class _AppDropdownModalSheet<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?> onSelect;
  final String lang;

  const _AppDropdownModalSheet({
    required this.title,
    this.subtitle,
    this.icon,
    required this.items,
    required this.selectedValue,
    required this.onSelect,
    required this.lang,
  });

  @override
  State<_AppDropdownModalSheet<T>> createState() => _AppDropdownModalSheetState<T>();
}

class _AppDropdownModalSheetState<T> extends State<_AppDropdownModalSheet<T>> {
  final _searchCtrl = TextEditingController();
  late List<DropdownMenuItem<T>> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = AppTranslations.normalizeAsciiDigits(query.trim()).toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final raw = _extractText(item.child);
          final cached = DynamicTranslationService.getCachedTranslation(raw, widget.lang) ?? '';
          final rawNorm = AppTranslations.normalizeAsciiDigits(raw).toLowerCase();
          final trNorm = AppTranslations.normalizeAsciiDigits(cached).toLowerCase();
          return rawNorm.contains(q) || trNorm.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 768;
    final isSearchable = widget.items.length > 5;
    final maxSheetHeight = isDesktop ? 560.0 : mediaQuery.size.height * 0.75;
    final lang = widget.lang;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxSheetHeight,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isDesktop
            ? null
            : const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDesktop)
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

          // Standardized Themed Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: widget.icon is Icon
                      ? Icon(
                          (widget.icon as Icon).icon,
                          color: AppColors.brandPrimary,
                          size: 20,
                        )
                      : const Icon(
                          Icons.tune_rounded,
                          color: AppColors.brandPrimary,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                  tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                ),
              ],
            ),
          ),

          // Live Search Bar (if > 5 items)
          if (isSearchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: AppTranslations.pick(
                    lang,
                    en: 'Search options...',
                    mr: 'पर्याय शोधा...',
                    hi: 'विकल्प खोजें...',
                  ),
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filter('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.slate200),

          // Scrollable Items List
          Flexible(
            child: _filteredItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No matching options found',
                          mr: 'कोणतेही जुळणारे पर्याय आढळले नाहीत',
                          hi: 'कोई मेल खाने वाला विकल्प नहीं मिला',
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(12, 8, 12, mediaQuery.viewInsets.bottom + 16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item.value == widget.selectedValue;
                      final itemStyle = TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.brandPrimary : AppColors.textPrimary,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: InkWell(
                          onTap: () => widget.onSelect(item.value),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandPrimary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25))
                                  : Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: item.child is Text
                                      ? _TranslatedDropdownText(
                                          (item.child as Text).data ?? '',
                                          lang: lang,
                                          style: itemStyle,
                                        )
                                      : DefaultTextStyle(
                                          style: itemStyle,
                                          child: item.child,
                                        ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.brandPrimary,
                                    size: 19,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
