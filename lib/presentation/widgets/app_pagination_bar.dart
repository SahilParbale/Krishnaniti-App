import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../providers/language_provider.dart';

/// Professional bottom pagination bar (Audit & Electoral Data Style)
/// Fully localized into English, Marathi, and Hindi with Devanagari numerals.
class AppPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;
  final bool isLoading;

  const AppPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.onPageSizeChanged,
    this.pageSizeOptions = const [10, 20, 50, 100],
    this.isLoading = false,
  });

  bool get hasPrevious => currentPage > 1 && !isLoading;
  bool get hasNext => currentPage < totalPages && !isLoading;

  int get startItem => totalItems == 0 ? 0 : (currentPage - 1) * pageSize + 1;
  int get endItem => min(currentPage * pageSize, totalItems);

  void _showJumpToPageDialog(BuildContext context, String lang) {
    if (totalPages <= 1) return;

    final controller = TextEditingController(text: '$currentPage');
    final locTotal = AppTranslations.formatDigits(totalPages, lang);
    final locOne = AppTranslations.formatDigits(1, lang);
    final midPage = (totalPages / 2).ceil();
    final locMid = AppTranslations.formatDigits(midPage, lang);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.brand600, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppTranslations.pick(lang, en: 'Jump to Page', mr: 'पृष्ठावर जा', hi: 'पृष्ठ पर जाएं'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Enter page number ($locOne to $locTotal):',
                  mr: 'पृष्ठ क्रमांक प्रविष्ट करा ($locOne ते $locTotal):',
                  hi: 'पृष्ठ संख्या दर्ज करें ($locOne से $locTotal):',
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.slate600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppTranslations.pick(
                    lang,
                    en: 'Page $locOne - $locTotal',
                    mr: 'पृष्ठ $locOne - $locTotal',
                    hi: 'पृष्ठ $locOne - $locTotal',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.slate300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.brand600, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (currentPage > 1)
                    ActionChip(
                      label: Text(
                        AppTranslations.pick(lang, en: 'First ($locOne)', mr: 'पहिले ($locOne)', hi: 'पहला ($locOne)'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onPageChanged(1);
                      },
                    ),
                  if (totalPages > 2)
                    ActionChip(
                      label: Text(
                        AppTranslations.pick(lang, en: 'Mid ($locMid)', mr: 'मध्य ($locMid)', hi: 'मध्य ($locMid)'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onPageChanged(midPage);
                      },
                    ),
                  if (currentPage < totalPages)
                    ActionChip(
                      label: Text(
                        AppTranslations.pick(lang, en: 'Last ($locTotal)', mr: 'शेवट ($locTotal)', hi: 'अंतिम ($locTotal)'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onPageChanged(totalPages);
                      },
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                style: const TextStyle(color: AppColors.slate600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final normalized = AppTranslations.normalizeAsciiDigits(controller.text.trim());
                final page = int.tryParse(normalized);
                if (page != null && page >= 1 && page <= totalPages) {
                  Navigator.pop(ctx);
                  onPageChanged(page);
                }
              },
              child: Text(AppTranslations.pick(lang, en: 'Go', mr: 'जा', hi: 'जाएं')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTotalPages = max(1, totalPages);

    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final locStart = AppTranslations.formatDigits(startItem, lang);
        final locEnd = AppTranslations.formatDigits(endItem, lang);
        final locTotal = AppTranslations.formatDigits(totalItems, lang);
        final locCurr = AppTranslations.formatDigits(currentPage, lang);
        final locTotPages = AppTranslations.formatDigits(effectiveTotalPages, lang);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppColors.slate200, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 8,
            bottom: 8 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      totalItems == 0
                          ? AppTranslations.pick(lang, en: 'No records found', mr: 'कोणत्याही नोंदी आढळल्या नाहीत', hi: 'कोई रिकॉर्ड नहीं मिला')
                          : AppTranslations.pick(
                              lang,
                              en: 'Showing $locStart–$locEnd of $locTotal records',
                              mr: '$locTotal पैकी $locStart–$locEnd नोंदी',
                              hi: '$locTotal में से $locStart–$locEnd रिकॉर्ड',
                            ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onPageSizeChanged != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppTranslations.pick(lang, en: 'Per page: ', mr: 'प्रति पृष्ठ: ', hi: 'प्रति पृष्ठ: '),
                          style: const TextStyle(fontSize: 11.5, color: AppColors.slate500),
                        ),
                        DropdownButton<int>(
                          value: pageSize,
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand700,
                          ),
                          icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.slate600),
                          items: pageSizeOptions.map((size) {
                            return DropdownMenuItem<int>(
                              value: size,
                              child: Text(AppTranslations.formatDigits(size, lang)),
                            );
                          }).toList(),
                          onChanged: (newSize) {
                            if (newSize != null && newSize != pageSize) {
                              onPageSizeChanged!(newSize);
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: hasPrevious ? () => onPageChanged(currentPage - 1) : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      label: Text(
                        AppTranslations.pick(lang, en: 'Prev', mr: 'मागील', hi: 'पिछला'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasPrevious ? AppColors.brand700 : AppColors.slate400,
                        backgroundColor: hasPrevious ? AppColors.brand50 : AppColors.slate50,
                        side: BorderSide(
                          color: hasPrevious ? AppColors.brand200 : AppColors.slate200,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: () => _showJumpToPageDialog(context, lang),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: AppColors.brand600,
                                  ),
                                ),
                              ),
                            Flexible(
                              child: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Page $locCurr of $locTotPages',
                                  mr: 'पृष्ठ $locCurr / $locTotPages',
                                  hi: 'पृष्ठ $locCurr / $locTotPages',
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.unfold_more_rounded, size: 14, color: AppColors.slate400),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: hasNext ? () => onPageChanged(currentPage + 1) : null,
                      icon: Text(
                        AppTranslations.pick(lang, en: 'Next', mr: 'पुढील', hi: 'अगला'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      label: const Icon(Icons.chevron_right_rounded, size: 18),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: hasNext ? Colors.white : AppColors.slate400,
                        backgroundColor: hasNext ? AppColors.brand600 : AppColors.slate100,
                        elevation: hasNext ? 1 : 0,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Clean, compact inline pagination control designed for inside detail cards,
/// sub-collections, modal sheets, and embedded sections.
class AppInlinePagination extends StatelessWidget {
  final int currentPage;
  final int? totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String label;

  const AppInlinePagination({
    super.key,
    required this.currentPage,
    this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.label = 'records',
  });

  int get calculatedTotalPages => totalPages ?? max(1, (totalItems / pageSize).ceil());
  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < calculatedTotalPages;

  int get startItem => totalItems == 0 ? 0 : (currentPage - 1) * pageSize + 1;
  int get endItem => min(currentPage * pageSize, totalItems);

  @override
  Widget build(BuildContext context) {
    if (totalItems <= pageSize) return const SizedBox.shrink();

    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final locStart = AppTranslations.formatDigits(startItem, lang);
        final locEnd = AppTranslations.formatDigits(endItem, lang);
        final locTotal = AppTranslations.formatDigits(totalItems, lang);
        final locCurr = AppTranslations.formatDigits(currentPage, lang);
        final locPages = AppTranslations.formatDigits(calculatedTotalPages, lang);
        final locLabel = AppTranslations.translateDirect(label, lang: lang);

        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Showing $locStart–$locEnd of $locTotal $locLabel',
                    mr: '$locTotal पैकी $locStart–$locEnd $locLabel',
                    hi: '$locTotal में से $locStart–$locEnd $locLabel',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: hasPrevious ? () => onPageChanged(currentPage - 1) : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: hasPrevious ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasPrevious ? const Color(0xFFCBD5E1) : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 16,
                        color: hasPrevious ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$locCurr / $locPages',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: hasNext ? () => onPageChanged(currentPage + 1) : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: hasNext ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasNext ? const Color(0xFFCBD5E1) : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: hasNext ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
