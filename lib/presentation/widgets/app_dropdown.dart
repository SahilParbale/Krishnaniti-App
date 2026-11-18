import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Helper to recursively extract plain text from any child widget
/// (such as Text, Row, Column, Flexible, etc.) for search filtering and display.
String _extractText(Widget widget) {
  if (widget is Text) {
    return widget.data ?? '';
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

/// Unified, themed dropdown component matching the Krishnaniti civic application theme.
/// Replaces clunky default Flutter dropdowns with an elegant bottom-sheet picker.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
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
    this.prefixIcon,
    this.height = 40,
    this.width,
    this.isDense = true,
    this.isExpanded = true,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  }) : hintText = hintText ?? hint;

  void _openPicker(BuildContext context) {
    if (onChanged == null) return;
    FocusScope.of(context).unfocus();

    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _AppDropdownModalSheet<T>(
        title: hintText ?? 'Select Option',
        icon: prefixIcon,
        items: items,
        selectedValue: value,
        onSelect: (val) {
          Navigator.pop(ctx);
          onChanged?.call(val);
        },
      ),
    );
  }

  Widget _buildSelectedDisplay() {
    if (value != null) {
      final selectedItem = items.cast<DropdownMenuItem<T>?>().firstWhere(
        (it) => it?.value == value,
        orElse: () => null,
      );
      if (selectedItem != null) {
        return DefaultTextStyle(
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: selectedItem.child,
        );
      }
    }
    return Text(
      hintText ?? 'Select Option',
      style: const TextStyle(
        fontSize: 12.5,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Container(
          width: width,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (prefixIcon != null) ...[
                prefixIcon!,
                const SizedBox(width: 6),
              ],
              if (isExpanded)
                Expanded(child: _buildSelectedDisplay())
              else
                Flexible(child: _buildSelectedDisplay()),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.brandPrimary,
                size: 20,
              ),
            ],
          ),
        );

        return InkWell(
          onTap: onChanged != null ? () => _openPicker(context) : null,
          borderRadius: BorderRadius.circular(10),
          child: content,
        );
      },
    );
  }
}

/// Form-field dropdown with built-in Krishnaniti styling and label + required asterisk.
/// Uses the unified Krishnaniti modal sheet picker matching the Society selector.
class AppDropdownFormField<T> extends FormField<T> {
  final String? label;
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

            void openPicker(BuildContext context) {
              if (onChanged == null) return;
              FocusScope.of(context).unfocus();

              showModalBottomSheet<T>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black54,
                builder: (ctx) => _AppDropdownModalSheet<T>(
                  title: label ?? hintText ?? 'Select Option',
                  subtitle: '${items.length} options available',
                  icon: prefixIcon,
                  items: items,
                  selectedValue: effectiveValue,
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
                  return DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: selectedItem.child,
                  );
                }
              }
              return Text(
                hintText ?? (label != null ? 'Select $label' : 'Select Option'),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }

            final context = state.context;

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
                          label,
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
                InkWell(
                  onTap: onChanged != null ? () => openPicker(context) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: fillColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: state.hasError
                            ? const Color(0xFFEF4444)
                            : (borderColor ?? AppColors.slate300),
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
                          color: AppColors.brandPrimary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.hasError && state.errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      state.errorText!,
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
}

/// Themed Krishnaniti bottom sheet modal selector for dropdowns.
/// Displays a drag handle, header with icon & close button, live search if > 5 options,
/// and items with highlight, subtle blue background, and active checkmark.
class _AppDropdownModalSheet<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?> onSelect;

  const _AppDropdownModalSheet({
    required this.title,
    this.subtitle,
    this.icon,
    required this.items,
    required this.selectedValue,
    required this.onSelect,
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
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final text = _extractText(item.child).toLowerCase();
          return text.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSearchable = widget.items.length > 5;
    final maxSheetHeight = mediaQuery.size.height * 0.75;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxSheetHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
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
          // Centered Drag Handle
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
                  tooltip: 'Close',
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
                  hintText: 'Search options...',
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
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No matching options found',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.brandPrimary : AppColors.textPrimary,
                                    ),
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
