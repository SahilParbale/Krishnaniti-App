import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nagarsevak_mobile/data/models/letter_model.dart';
import 'package:nagarsevak_mobile/data/repositories/letters_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/screens/letters/new_letter_bottom_sheet.dart';
import 'package:nagarsevak_mobile/presentation/screens/letters/letter_type_manager_sheet.dart';
import 'package:nagarsevak_mobile/presentation/screens/letters/letter_report_generator.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';
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
  String _previewLang = 'mr'; // 'mr' | 'en'

  bool _loading = true;
  List<LetterModel> _outgoingLetters = [];
  List<LetterModel> _incomingLetters = [];
  LetterModel? _selectedLetter;

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
      dates.add(DateFormat('MMM d, yyyy').format(l.createdAt));
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
        final formattedDate = DateFormat('MMM d, yyyy').format(l.createdAt);
        if (!formattedDate.toLowerCase().contains(_selectedDate.toLowerCase())) {
          return false;
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = l.title.toLowerCase().contains(q);
        final matchCitizen = l.citizenName.toLowerCase().contains(q);
        final matchSubject = l.subject.toLowerCase().contains(q);
        if (!matchTitle && !matchCitizen && !matchSubject) return false;
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
    final isMr = lang == 'mr';
    final items = _filteredLetters;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // bg-slate-50
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
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
              _buildLettersTable(items, lang)
            else
              _buildMainGrid(items, lang),
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
                '${lang == "mr" ? "सापडले" : (lang == "hi" ? "मिले" : "Found")}: $foundCount',
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
                lang == 'mr' ? 'अहवाल डाउनलोड करा' : (lang == 'hi' ? 'रिपोर्ट डाउनलोड करें' : 'Download Report'),
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
                      AppTranslations.t('letters.new_request', lang: lang),
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
                title: '${AppTranslations.t("letters.outward_register", lang: lang)} (${_outgoingLetters.length})',
                isActive: _activeTab == 'outgoing',
                onTap: () {
                  setState(() {
                    _activeTab = 'outgoing';
                    _selectedLetter = _outgoingLetters.isNotEmpty ? _outgoingLetters.first : null;
                  });
                },
              ),
              const SizedBox(width: 24),
              _buildTabButton(
                title: '${AppTranslations.t("letters.inward_register", lang: lang)} (${_incomingLetters.length})',
                isActive: _activeTab == 'incoming',
                onTap: () {
                  setState(() {
                    _activeTab = 'incoming';
                    _selectedLetter = _incomingLetters.isNotEmpty ? _incomingLetters.first : null;
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
            DataColumn(label: Text(lang == 'mr' ? 'संदर्भ / जावक क्र.' : (lang == 'hi' ? 'संदर्भ / जावक क्र.' : 'Ref / Outward No.'), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('subject', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('citizen', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('category', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('date', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('status', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(lang == 'mr' ? 'कृती' : (lang == 'hi' ? 'कार्रवाई' : 'Actions'), style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: items.map((l) {
            final dateStr = DateFormat('dd MMM yyyy').format(l.createdAt);
            return DataRow(
              cells: [
                DataCell(Text(l.id, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0369A1)))),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: AppTranslatedText(
                      l.subject,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(l.recipient ?? l.citizenName)),
                DataCell(Text(l.letterType ?? l.department ?? '-')),
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
                    tooltip: 'Preview Letter',
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
            onChanged: (v) => setState(() => _searchQuery = v),
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
                  : area;
              return DropdownMenuItem(
                value: area,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedArea = val);
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
              final label = date == 'All'
                  ? (lang == 'mr' ? 'सर्व तारखा' : (lang == 'hi' ? 'सभी तिथियां' : 'All Dates'))
                  : date;
              return DropdownMenuItem(
                value: date,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedDate = val);
            },
          ),
        ),
      ],
    );
  }

  // --- Main 3-Column Layout: 1/3 List + 2/3 Live Preview ---
  Widget _buildMainGrid(List<LetterModel> items, String lang) {
    if (items.isEmpty) {
      return _buildEmptyState(lang == 'mr');
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
              ? _buildPreviewPane(_selectedLetter!, lang == 'mr')
              : _buildSelectLetterPlaceholder(lang == 'mr'),
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

    final dateStr = DateFormat('MMM d, h:mm a').format(letter.createdAt);

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
            Text(
              letter.citizenName,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            if (letter.subject.isNotEmpty && letter.subject != letter.title) ...[
              const SizedBox(height: 2),
              AppTranslatedText(
                letter.subject,
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
                if (letter.area != null)
                  Text(
                    letter.area!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
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
    final dateStr = letter.receivedDate != null
        ? DateFormat('dd/MM/yyyy').format(letter.receivedDate!)
        : DateFormat('dd/MM/yyyy').format(letter.createdAt);

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
                    (letter.fileType ?? '').contains('pdf') ? 'PDF' : 'Image',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            if (letter.description != null && letter.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              AppTranslatedText(
                letter.description!,
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
                if (letter.area != null)
                  Text(
                    letter.area!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Right Live Letterhead Preview Pane (matching LetterDashboard.tsx lines 1020-1120) ---
  Widget _buildPreviewPane(LetterModel letter, bool isMr) {
    final dateStr = DateFormat('dd/MM/yyyy').format(letter.createdAt);

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter.letterType ?? letter.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Request From: ${letter.citizenName}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),

                // Language toggle (Marathi | English)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildPreviewLangButton('mr', 'Marathi'),
                      _buildPreviewLangButton('en', 'English'),
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
                          Text(
                            'Rajesh Sharma',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Nagar Sevak - Ward 12',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                      Text(
                        'Date: $dateStr',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFCBD5E1), thickness: 1),
                  const SizedBox(height: 24),

                  // 2. Letter Title (TO WHOMSOEVER IT MAY CONCERN in English)
                  if (_previewLang == 'en') ...[
                    const Center(
                      child: Text(
                        'TO WHOMSOEVER IT MAY CONCERN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. Hydrated Letter Body
                  Text(
                    _getHydratedLetterBody(letter, _previewLang),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: Color(0xFF1E293B),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 4. Sign-off
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Regards,',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 36), // Signature gap
                        Text(
                          'Rajesh Sharma',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '(Nagar Sevak)',
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
                      _previewLang == 'mr'
                          ? 'Office: Ward Office, Main Street | Contact: 98XXXXXXXX'
                          : 'Office: Ward Office, Main Road | Contact: 98XXXXXXXX',
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
                      label: const Text('Print'),
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
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: const Text('Download Report', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 13)),
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
                        label: const Text('Approve'),
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
                        label: const Text('Reject'),
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

  String _getHydratedLetterBody(LetterModel letter, String lang) {
    final name = letter.citizenName;
    final address = letter.address.isNotEmpty ? letter.address : 'Ward 12';
    final purpose = letter.purpose.isNotEmpty ? letter.purpose : letter.letterType ?? letter.title;

    if (lang == 'mr') {
      return 'This is to certify that Mr./Ms. $name, residing at $address, is a bonafide resident of Ward 12 to the best of my knowledge.\n\nThis letter is issued upon their request for $purpose.\nI wish them all the best in their future endeavors.';
    } else {
      return 'This is to certify that Mr./Ms. $name, residing at $address, is a resident of Ward 12 to the best of my knowledge.\n\nThis letter is issued upon their request for the purpose of $purpose.\nI wish them all the best for their future endeavors.';
    }
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

  Widget _buildSelectLetterPlaceholder(bool isMr) {
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
            'Select a letter to preview',
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

  Widget _buildEmptyState(bool isMr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No letters found',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search criteria',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
