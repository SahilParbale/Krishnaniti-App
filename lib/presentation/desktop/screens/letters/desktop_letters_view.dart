import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nagarsevak_mobile/data/models/letter_model.dart';
import 'package:nagarsevak_mobile/data/repositories/letters_repository.dart';
import 'package:nagarsevak_mobile/presentation/screens/letters/new_letter_bottom_sheet.dart';
import 'package:nagarsevak_mobile/presentation/screens/letters/letter_type_manager_sheet.dart';
import 'package:nagarsevak_mobile/presentation/screens/letters/letter_report_generator.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_load_more_footer.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import 'package:nagarsevak_mobile/presentation/providers/language_provider.dart';

/// Desktop Letters Dashboard View matching LetterDashboard.tsx verbatim:
/// - Sticky Header: Icon + Title + Found counter + Help + Manage Types + New Request / Upload
/// - Tabs: Outgoing (N) vs Incoming (N) + Grid / Report toggle
/// - Filter Toolbar: Search (6 cols) + Area dropdown (3 cols) + Date dropdown (3 cols)
/// - Main Content Grid: 1/3 Left List + 2/3 Right Live Letterhead Preview Pane
class DesktopLettersView extends ConsumerStatefulWidget {
  const DesktopLettersView({super.key});

  @override
  ConsumerState<DesktopLettersView> createState() => _DesktopLettersViewState();
}

class _DesktopLettersViewState extends ConsumerState<DesktopLettersView> {
  String _activeTab = 'outgoing'; // 'outgoing' | 'incoming'
  String _viewMode = 'grid'; // 'grid' | 'table'
  String _searchQuery = '';
  String _selectedArea = 'All';
  String _selectedDate = 'All';
  String _previewLang = 'mr'; // 'mr' | 'hi' | 'en'

  bool _loading = true;
  List<LetterModel> _outgoingLetters = [];
  List<LetterModel> _incomingLetters = [];
  LetterModel? _selectedLetter;
  int _displayedLimit = 20;

  List<LetterModel> get _visibleLetters =>
      _filteredLetters.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final repo = ref.read(lettersRepoProvider);
      final outgoing = await repo.getLetters(isIncoming: false, limit: 100);
      final incoming = await repo.getLetters(isIncoming: true, limit: 100);
      if (mounted) {
        setState(() {
          _outgoingLetters = outgoing;
          _incomingLetters = incoming;
          _loading = false;
          if (_activeTab == 'outgoing' && _outgoingLetters.isNotEmpty) {
            _selectedLetter = _outgoingLetters.first;
          } else if (_activeTab == 'incoming' && _incomingLetters.isNotEmpty) {
            _selectedLetter = _incomingLetters.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<LetterModel> get _currentList =>
      _activeTab == 'outgoing' ? _outgoingLetters : _incomingLetters;

  List<String> get _uniqueAreas {
    final areas = <String>{};
    for (final l in _currentList) {
      if (l.area != null && l.area!.trim().isNotEmpty) {
        areas.add(l.area!.trim());
      }
    }
    final sorted = areas.toList()..sort();
    return ['All', ...sorted];
  }

  List<String> get _uniqueDates {
    final dates = <String>{};
    for (final l in _currentList) {
      dates.add(DateFormat('yyyy-MM-dd').format(l.createdAt));
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return ['All', ...sorted];
  }

  List<LetterModel> get _filteredLetters {
    return _currentList.where((l) {
      if (_selectedArea != 'All' && l.area != _selectedArea) {
        return false;
      }
      if (_selectedDate != 'All') {
        final formattedDate = DateFormat('yyyy-MM-dd').format(l.createdAt);
        if (formattedDate != _selectedDate) {
          return false;
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = AppTranslations.normalizeAsciiDigits(_searchQuery).toLowerCase().trim();
        final matchTitle = l.title.toLowerCase().contains(q);
        final matchCitizen = l.citizenName.toLowerCase().contains(q);
        final matchSubject = l.subject.toLowerCase().contains(q);
        final matchMobile = AppTranslations.normalizeAsciiDigits(l.mobile).contains(q);
        if (!matchTitle && !matchCitizen && !matchSubject && !matchMobile) return false;
      }
      return true;
    }).toList();
  }

  void _openNewLetterModal(String tab) {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: 720,
          constraints: const BoxConstraints(maxHeight: 780),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: NewLetterBottomSheet(initialTab: tab),
        ),
      ),
    ).then((res) {
      if (res == true) _loadLetters(showLoading: false);
    });
  }

  void _openManageTypesModal() {
    LetterTypeManagerSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final items = _filteredLetters;
    final visibleItems = _visibleLetters;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // bg-slate-50
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row
            _buildHeader(lang, items.length),

            const SizedBox(height: 16),

            // 2. Tabs & View Toggle
            _buildTabsAndViewToggle(lang),

            const SizedBox(height: 16),

            // 3. Search & Filter Bar
            _buildFilterBar(lang),

            const SizedBox(height: 20),

            // 4. Main Content: Grid vs Table
            if (_loading)
              _buildLoadingState()
            else if (_viewMode == 'table')
              _buildLettersTable(visibleItems, lang)
            else
              _buildMainGrid(visibleItems, lang),

            // 5. Pagination Load More Footer
            if (!_loading && items.isNotEmpty)
              AppLoadMoreFooter(
                currentCount: visibleItems.length,
                totalCount: items.length,
                pageSize: 20,
                onLoadMore: () {
                  setState(() => _displayedLimit += 20);
                },
                label: lang == 'mr' ? 'पत्रे' : (lang == 'hi' ? 'पत्र' : 'letters'),
                isMarathi: lang == 'mr',
              ),
          ],
        ),
      ),
    );
  }

  // --- Header Row ---
  Widget _buildHeader(String lang, int foundCount) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_rounded, size: 28, color: Color(0xFF0369A1)),
            const SizedBox(width: 10),
            Text(
              AppTranslations.t('letters.title', lang: lang),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Text(
                AppTranslations.formatFound(foundCount, lang),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0369A1),
                ),
              ),
            ),
          ],
        ),

        // Action Buttons: Download Report + Manage Types + New Request / Upload
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                LetterReportGenerator.generateAndPrintLetterReport(
                  context: context,
                  letters: _activeTab == 'outgoing' ? _outgoingLetters : _incomingLetters,
                  title: _activeTab == 'outgoing'
                      ? (lang == 'mr'
                          ? 'जावक पत्र अधिकृत नोंदवही'
                          : (lang == 'hi' ? 'जावक पत्र आधिकारिक रजिस्टर' : 'Outgoing Letters Report'))
                      : (lang == 'mr'
                          ? 'आवक पत्र अधिकृत नोंदवही'
                          : (lang == 'hi' ? 'आवक पत्र आधिकारिक रजिस्टर' : 'Incoming Letters Report')),
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(lang),
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 10),

            if (_activeTab == 'outgoing') ...[
              OutlinedButton(
                onPressed: _openManageTypesModal,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF475569)),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.t('letters.manage_types', lang: lang),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _openNewLetterModal('outgoing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'New Request',
                        mr: 'नवीन विनंती',
                        hi: 'नया अनुरोध',
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.1),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => _openNewLetterModal('incoming'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload_file_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      lang == 'mr' ? 'आवक पत्र जोडा' : (lang == 'hi' ? 'आवक पत्र अपलोड करें' : 'Upload Incoming'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- Tabs & View Toggle Row ---
  Widget _buildTabsAndViewToggle(String lang) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildTabButton(
                title: '${AppTranslations.pick(lang, en: 'Outward Register', mr: 'जावक नोंदवही', hi: 'जावक रजिस्टर')} (${AppTranslations.formatDigits(_outgoingLetters.length, lang)})',
                isActive: _activeTab == 'outgoing',
                onTap: () {
                  setState(() {
                    _activeTab = 'outgoing';
                    _selectedLetter = _outgoingLetters.isNotEmpty ? _outgoingLetters.first : null;
                    _displayedLimit = 20;
                  });
                },
              ),
              const SizedBox(width: 24),
              _buildTabButton(
                title: '${AppTranslations.pick(lang, en: 'Inward Register', mr: 'आवक नोंदवही', hi: 'आवक रजिस्टर')} (${AppTranslations.formatDigits(_incomingLetters.length, lang)})',
                isActive: _activeTab == 'incoming',
                onTap: () {
                  setState(() {
                    _activeTab = 'incoming';
                    _selectedLetter = _incomingLetters.isNotEmpty ? _incomingLetters.first : null;
                    _displayedLimit = 20;
                  });
                },
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  label: lang == 'mr' ? 'ग्रिड' : (lang == 'hi' ? 'ग्रिड' : 'Grid'),
                  isActive: _viewMode == 'grid',
                  onTap: () => setState(() => _viewMode = 'grid'),
                ),
                const SizedBox(width: 4),
                _buildViewToggleButton(
                  icon: Icons.table_rows_rounded,
                  label: lang == 'mr' ? 'तक्ता' : (lang == 'hi' ? 'तालिका' : 'Table'),
                  isActive: _viewMode == 'table',
                  onTap: () => setState(() => _viewMode = 'table'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalizedAreaText(
    String raw,
    String lang, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return Text(raw, style: style, maxLines: maxLines, overflow: overflow);
    }
    final mapped = AppTranslations.getAreaName(trimmed, lang);
    final changed = mapped.trim().toLowerCase() != trimmed.toLowerCase() &&
        mapped != AppTranslations.formatDigits(trimmed, lang);
    if (changed || (lang == 'en' && !DynamicTranslationService.containsDevanagari(trimmed))) {
      return Text(mapped, style: style, maxLines: maxLines, overflow: overflow);
    }
    return AppTranslatedText(
      trimmed,
      targetLanguage: lang,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Widget _buildLettersTable(List<LetterModel> items, String lang) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(AppTranslations.pick(lang, en: 'Ref / Outward No.', mr: 'संदर्भ / जावक क्र.', hi: 'संदर्भ / जावक क्र.'), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('subject', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.pick(lang, en: 'Citizen', mr: 'नागरिक', hi: 'नागरिक'), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('category', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('date', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('status', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.pick(lang, en: 'Actions', mr: 'कृती', hi: 'कार्रवाई'), style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: items.map((l) {
            final dateStr = AppTranslations.formatDate(l.createdAt, lang);
            final categoryRaw = l.letterType ?? l.department ?? '-';
            return DataRow(
              cells: [
                DataCell(Text(AppTranslations.formatDigits(l.id, lang), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0369A1)))),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: AppTranslatedText(
                      l.subject,
                      targetLanguage: lang,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  AppTranslatedText(
                    l.recipient ?? l.citizenName,
                    isName: true,
                    targetLanguage: lang,
                  ),
                ),
                DataCell(
                  categoryRaw == '-'
                      ? const Text('-')
                      : AppTranslatedText(categoryRaw, targetLanguage: lang),
                ),
                DataCell(Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      AppTranslations.getStatus(l.status, lang),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF0284C7)),
                    tooltip: AppTranslations.pick(lang, en: 'Preview Letter', mr: 'पत्राचे पूर्वावलोकन', hi: 'पत्र पूर्वावलोकन'),
                    onPressed: () {
                      setState(() {
                        _selectedLetter = l;
                        _viewMode = 'grid';
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF0284C7) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Filter Bar ---
  Widget _buildFilterBar(String lang) {
    return Row(
      children: [
        // Main Search (6 cols)
        Expanded(
          flex: 6,
          child: TextField(
            onChanged: (v) => setState(() {
              _searchQuery = v;
              _displayedLimit = 20;
            }),
            decoration: InputDecoration(
              hintText: lang == 'mr'
                  ? 'विषय किंवा नागरिकाच्या नावाने पत्र शोधा...'
                  : (lang == 'hi'
                      ? 'विषय या नागरिक के नाम से पत्र खोजें...'
                      : 'Search letters by subject, citizen name...'),
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Area Search Dropdown (3 cols)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedArea,
            height: 42,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueAreas.map((area) {
              final label = area == 'All'
                  ? (lang == 'mr' ? 'सर्व परिसर' : (lang == 'hi' ? 'सभी क्षेत्र' : 'All Areas'))
                  : AppTranslations.getAreaName(area, lang);
              return DropdownMenuItem(
                value: area,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedArea = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),

        // Date Search Dropdown (3 cols matching LetterDashboard.tsx)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedDate,
            height: 42,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueDates.map((date) {
              String label;
              if (date == 'All') {
                label = AppTranslations.pick(lang, en: 'All Dates', mr: 'सर्व तारखा', hi: 'सभी तिथियां');
              } else {
                final parsed = DateTime.tryParse(date);
                label = parsed != null
                    ? AppTranslations.formatDate(parsed, lang, pattern: 'MMM d, yyyy')
                    : AppTranslations.formatDigits(date, lang);
              }
              return DropdownMenuItem(
                value: date,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDate = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // --- Main 3-Column Layout: 1/3 List + 2/3 Live Preview ---
  Widget _buildMainGrid(List<LetterModel> items, String lang) {
    if (items.isEmpty) {
      return _buildEmptyState(lang);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Col 1 (1/3 width): Left Letters List
        Expanded(
          flex: 1,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 640),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final letter = items[index];
                final isSelected = _selectedLetter?.id == letter.id;

                if (_activeTab == 'outgoing') {
                  return _buildOutgoingListItem(letter, isSelected, lang);
                } else {
                  return _buildIncomingListItem(letter, isSelected, lang);
                }
              },
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Cols 2 & 3 (2/3 width): Right Live Letterhead Preview Pane
        Expanded(
          flex: 2,
          child: _selectedLetter != null
              ? _buildPreviewPane(_selectedLetter!, lang)
              : _buildSelectLetterPlaceholder(lang),
        ),
      ],
    );
  }

  // Outgoing List Item (matching LetterDashboard.tsx lines 880-930)
  Widget _buildOutgoingListItem(LetterModel letter, bool isSelected, String lang) {
    Color borderLeftColor = Colors.transparent;
    Color bgColor = isSelected ? const Color(0xFFF0F9FF) : Colors.white;

    final statusLower = letter.status.toLowerCase();
    if (statusLower == 'approved') {
      borderLeftColor = const Color(0xFF22C55E); // green-500
    } else if (statusLower == 'rejected') {
      borderLeftColor = const Color(0xFFEF4444); // red-500
    } else if (statusLower == 'pending') {
      borderLeftColor = const Color(0xFFF59E0B); // yellow-500
    }

    final dateStr = AppTranslations.formatDateTime(letter.createdAt, lang, datePattern: 'd MMM');

    return InkWell(
      onTap: () => setState(() => _selectedLetter = letter),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(color: borderLeftColor, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppTranslatedText(
                    letter.letterType ?? letter.title,
                    targetLanguage: lang,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusPill(letter.status, lang),
              ],
            ),
            const SizedBox(height: 4),
            AppTranslatedText(
              letter.citizenName,
              isName: true,
              targetLanguage: lang,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (letter.subject.isNotEmpty && letter.subject != letter.title) ...[
              const SizedBox(height: 2),
              AppTranslatedText(
                letter.subject,
                targetLanguage: lang,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                if (letter.area != null && letter.area!.trim().isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildLocalizedAreaText(
                        letter.area!,
                        lang,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Incoming List Item (matching LetterDashboard.tsx lines 950-980)
  Widget _buildIncomingListItem(LetterModel letter, bool isSelected, String lang) {
    final targetDate = letter.receivedDate ?? letter.createdAt;
    final dateStr = AppTranslations.formatDate(targetDate, lang, pattern: 'dd/MM/yyyy');

    return InkWell(
      onTap: () => setState(() => _selectedLetter = letter),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          border: isSelected
              ? const Border(left: BorderSide(color: Color(0xFF0284C7), width: 4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppTranslatedText(
                    letter.title,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (letter.fileType ?? '').contains('pdf')
                        ? AppTranslations.pick(lang, en: 'PDF', mr: 'PDF', hi: 'PDF')
                        : AppTranslations.pick(lang, en: 'Image', mr: 'फोटो', hi: 'छवि'),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            if (letter.description != null && letter.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              AppTranslatedText(
                letter.description!,
                targetLanguage: lang,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                if (letter.area != null && letter.area!.trim().isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildLocalizedAreaText(
                        letter.area!,
                        lang,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Right Live Letterhead Preview Pane (matching LetterDashboard.tsx lines 1020-1120) ---
  Widget _buildPreviewPane(LetterModel letter, String lang) {
    final dateStr = AppTranslations.formatDate(letter.createdAt, _previewLang, pattern: 'dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Top Bar: Title + Language Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTranslatedText(
                        letter.letterType ?? letter.title,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            AppTranslations.pick(lang, en: 'Request From: ', mr: 'अर्जदार: ', hi: 'अनुरोधकर्ता: '),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          Flexible(
                            child: AppTranslatedText(
                              letter.citizenName,
                              isName: true,
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Language toggle (Marathi | Hindi | English)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildPreviewLangButton('mr', AppTranslations.pick(lang, en: 'Marathi', mr: 'मराठी', hi: 'मराठी')),
                      _buildPreviewLangButton('hi', AppTranslations.pick(lang, en: 'Hindi', mr: 'हिंदी', hi: 'हिंदी')),
                      _buildPreviewLangButton('en', AppTranslations.pick(lang, en: 'English', mr: 'इंग्रजी', hi: 'अंग्रेजी')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Letter Paper Container (White letterhead sheet with border)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Politician Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTranslatedText(
                            'Rajesh Sharma',
                            isName: true,
                            targetLanguage: _previewLang,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppTranslations.pick(
                              _previewLang,
                              en: 'Nagar Sevak - Ward 12',
                              mr: 'नगरसेवक - प्रभाग १२',
                              hi: 'नगरसेवक - वार्ड १२',
                            ),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                      Text(
                        '${AppTranslations.pick(_previewLang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक')}: $dateStr',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFCBD5E1), thickness: 1),
                  const SizedBox(height: 24),

                  // 2. Letter Title
                  Center(
                    child: Text(
                      AppTranslations.pick(
                        _previewLang,
                        en: 'TO WHOMSOEVER IT MAY CONCERN',
                        mr: 'संबंधित सर्व अधिकारी / कार्यालयांस सविनय निवेदन',
                        hi: 'सर्व संबंधितों के सूचनार्थ (प्रमाणपत्र)',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Hydrated Letter Body (dynamically translated across EN/MR/HI)
                  _TranslatedLetterBody(
                    letter: letter,
                    previewLang: _previewLang,
                  ),

                  const SizedBox(height: 48),

                  // 4. Sign-off
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppTranslations.pick(_previewLang, en: 'Regards,', mr: 'आपला नम्र,', hi: 'भवदीय,'),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 36), // Signature gap
                        AppTranslatedText(
                          'Rajesh Sharma',
                          isName: true,
                          targetLanguage: _previewLang,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          AppTranslations.pick(_previewLang, en: '(Nagar Sevak)', mr: '(नगरसेवक)', hi: '(नगरसेवक)'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),
                  const Divider(color: Color(0xFFF1F5F9)),

                  // 5. Letterhead Footer
                  Center(
                    child: Text(
                      AppTranslations.pick(
                        _previewLang,
                        en: 'Office: Ward Office, Main Road | Contact: 98XXXXXXXX',
                        mr: 'कार्यालय: प्रभाग कार्यालय, मुख्य रस्ता | संपर्क: ९८XXXXXXXX',
                        hi: 'कार्यालय: वार्ड कार्यालय, मुख्य मार्ग | संपर्क: ९८XXXXXXXX',
                      ),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: Text(AppTranslations.pick(lang, en: 'Print', mr: 'प्रिंट करा', hi: 'प्रिंट करें')),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        LetterReportGenerator.generateAndPrintSingleLetter(
                          context: context,
                          letter: letter,
                          lang: lang,
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: Text(
                        AppTranslations.getDownloadReport(lang),
                        style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F9FF),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),

                // Approval actions for Pending requests
                if (_activeTab == 'outgoing' && letter.status.toLowerCase() == 'pending') ...[
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(lettersRepoProvider).updateLetterStatus(letter.id, 'Approved');
                          _loadLetters();
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: Text(AppTranslations.pick(lang, en: 'Approve', mr: 'मंजूर करा', hi: 'स्वीकृत करें')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(lettersRepoProvider).updateLetterStatus(letter.id, 'Rejected');
                          _loadLetters();
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: Text(AppTranslations.pick(lang, en: 'Reject', mr: 'नाकारा', hi: 'अस्वीकार करें')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewLangButton(String key, String label) {
    final isSelected = _previewLang == key;
    return InkWell(
      onTap: () => setState(() => _previewLang = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, [String lang = 'en']) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    final lower = status.toLowerCase();
    if (lower == 'approved') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    } else if (lower == 'rejected') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (lower == 'pending') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        AppTranslations.getStatus(status, lang),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildSelectLetterPlaceholder(String lang) {
    return Container(
      height: 480,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.article_outlined, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Select a letter to preview',
              mr: 'पूर्वावलोकनासाठी पत्र निवडा',
              hi: 'पूर्वावलोकन के लिए एक पत्र चुनें',
            ),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            lang == 'mr'
                ? 'कोणतेही पत्र आढळले नाही'
                : (lang == 'hi' ? 'कोई पत्र नहीं मिला' : 'No letters found'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Text(
            lang == 'mr'
                ? 'आपले शोध निकष तपासून पहा'
                : (lang == 'hi' ? 'अपने खोज मानदंड जांचें' : 'Try adjusting your search criteria'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _TranslatedLetterBody extends StatefulWidget {
  final LetterModel letter;
  final String previewLang;

  const _TranslatedLetterBody({
    required this.letter,
    required this.previewLang,
  });

  @override
  State<_TranslatedLetterBody> createState() => _TranslatedLetterBodyState();
}

class _TranslatedLetterBodyState extends State<_TranslatedLetterBody> {
  late String _name;
  late String _address;
  late String _purpose;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _TranslatedLetterBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter.id != widget.letter.id ||
        oldWidget.letter.citizenName != widget.letter.citizenName ||
        oldWidget.letter.address != widget.letter.address ||
        oldWidget.letter.purpose != widget.letter.purpose ||
        oldWidget.previewLang != widget.previewLang) {
      _resolve();
    }
  }

  void _resolve() {
    final lang = widget.previewLang;
    final rawName = widget.letter.citizenName;
    final rawAddress = widget.letter.address.isNotEmpty ? widget.letter.address : 'Ward 12';
    final rawPurpose = widget.letter.purpose.isNotEmpty
        ? widget.letter.purpose
        : (widget.letter.letterType ?? widget.letter.title);

    _name = DynamicTranslationService.getCachedTranslation(rawName, lang, isName: true) ??
        AppTranslations.formatDigits(rawName, lang);
    final areaHit = AppTranslations.getAreaName(rawAddress, lang);
    final addrChanged = areaHit.trim().toLowerCase() != rawAddress.trim().toLowerCase() &&
        areaHit != AppTranslations.formatDigits(rawAddress, lang);
    _address = addrChanged
        ? areaHit
        : (DynamicTranslationService.getCachedTranslation(rawAddress, lang) ??
            AppTranslations.formatDigits(rawAddress, lang));
    _purpose = DynamicTranslationService.getCachedTranslation(rawPurpose, lang) ??
        AppTranslations.formatDigits(rawPurpose, lang);

    final needName = DynamicTranslationService.getCachedTranslation(rawName, lang, isName: true) == null;
    final needAddr = !addrChanged && DynamicTranslationService.getCachedTranslation(rawAddress, lang) == null;
    final needPurpose = DynamicTranslationService.getCachedTranslation(rawPurpose, lang) == null;

    if (!needName && !needAddr && !needPurpose) return;

    final reqToken = ++_token;
    Future.wait([
      needName ? DynamicTranslationService.transliterateName(rawName, lang) : Future.value(_name),
      needAddr ? DynamicTranslationService.translateText(rawAddress, lang) : Future.value(_address),
      needPurpose ? DynamicTranslationService.translateText(rawPurpose, lang) : Future.value(_purpose),
    ]).then((vals) {
      if (mounted && reqToken == _token) {
        setState(() {
          _name = vals[0];
          _address = vals[1];
          _purpose = vals[2];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.previewLang;
    final body = AppTranslations.pick(
      lang,
      en: 'This is to certify that Mr./Ms. $_name, residing at $_address, is a resident of Ward 12 to the best of my knowledge.\n\nThis letter is issued upon their request for the purpose of $_purpose.\nI wish them all the best for their future endeavors.',
      mr: 'याद्वारे प्रमाणित करण्यात येते की, श्री./सौ. $_name, राहणार $_address, हे माझ्या माहितीनुसार प्रभाग १२ चे रहिवासी आहेत.\n\nहे शिफारस पत्र त्यांच्या $_purpose या कारणास्तव केलेल्या विनंतीनुसार देण्यात येत आहे.\nत्यांच्या पुढील वाटचालीस मनःपूर्वक शुभेच्छा.',
      hi: 'एतद्द्वारा प्रमाणित किया जाता है कि श्री/श्रीमती $_name, निवासी $_address, मेरी जानकारी के अनुसार वार्ड १२ के स्थायी निवासी हैं।\n\nयह पत्र उनके $_purpose के अनुरोध पर जारी किया जा रहा है।\nमैं उनके उज्ज्वल भविष्य की कामना करता हूँ।',
    );
    return Text(
      body,
      style: const TextStyle(
        fontSize: 14,
        height: 1.7,
        color: Color(0xFF1E293B),
      ),
    );
  }
}
