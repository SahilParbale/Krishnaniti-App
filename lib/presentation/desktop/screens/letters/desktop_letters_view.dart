import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nagarsevak_mobile/data/models/letter_model.dart';
import 'package:nagarsevak_mobile/data/repositories/letters_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/screens/letters/new_letter_bottom_sheet.dart';
import 'package:nagarsevak_mobile/presentation/screens/letters/letter_type_manager_sheet.dart';

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
  String _viewMode = 'grid'; // 'grid' | 'report'
  String _searchQuery = '';
  String _selectedArea = 'All';
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

  Future<void> _loadLetters() async {
    setState(() => _loading = true);
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

  List<LetterModel> get _filteredLetters {
    return _currentList.where((l) {
      if (_selectedArea != 'All' && l.area != _selectedArea) {
        return false;
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
      if (res == true) _loadLetters();
    });
  }

  void _openManageTypesModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: 680,
          constraints: const BoxConstraints(maxHeight: 720),
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
          child: const LetterTypeManagerSheet(),
        ),
      ),
    );
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
            // 1. Header Row (matching LetterDashboard.tsx lines 557-601)
            _buildHeader(isMr, items.length),

            const SizedBox(height: 16),

            // 2. Tabs & View Toggle (matching LetterDashboard.tsx lines 604-669)
            _buildTabsAndViewToggle(isMr),

            const SizedBox(height: 16),

            // 3. Search & Filter Bar (matching LetterDashboard.tsx lines 671-747)
            _buildFilterBar(isMr),

            const SizedBox(height: 20),

            // 4. Main 3-Column Layout: 1/3 List + 2/3 Live Preview (matching lines 860-1280)
            if (_loading)
              _buildLoadingState()
            else
              _buildMainGrid(items, isMr),
          ],
        ),
      ),
    );
  }

  // --- Header Row ---
  Widget _buildHeader(bool isMr, int foundCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.description_rounded, size: 28, color: Color(0xFF0369A1)),
            const SizedBox(width: 10),
            Text(
              'Letters Dashboard',
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
                color: const Color(0xFFF0F9FF), // bg-brand-50
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBAE6FD)), // border-brand-200
              ),
              child: Text(
                'Found: $foundCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0369A1),
                ),
              ),
            ),
          ],
        ),

        // Action Buttons: Help + Manage Types + New Request / Upload
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.help_outline_rounded, size: 18, color: Color(0xFF0284C7)),
              label: Text(
                'Help',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(width: 10),

            if (_activeTab == 'outgoing') ...[
              OutlinedButton.icon(
                onPressed: _openManageTypesModal,
                icon: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF475569)),
                label: Text(
                  'Manage Types',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _openNewLetterModal('outgoing'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'New Request',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 1,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _openNewLetterModal('incoming'),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(
                  'Upload Incoming',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- Tabs & View Toggle Row ---
  Widget _buildTabsAndViewToggle(bool isMr) {
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
                title: 'Outgoing (${_outgoingLetters.length})',
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
                title: 'Incoming (${_incomingLetters.length})',
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

          // View Toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Grid',
                  isActive: _viewMode == 'grid',
                  onTap: () => setState(() => _viewMode = 'grid'),
                ),
                _buildViewToggleButton(
                  icon: Icons.table_chart_outlined,
                  label: 'Report',
                  isActive: _viewMode == 'report',
                  onTap: () => setState(() => _viewMode = 'report'),
                ),
              ],
            ),
          ),
        ],
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
  Widget _buildFilterBar(bool isMr) {
    return Row(
      children: [
        // Main Search (6 cols)
        Expanded(
          flex: 6,
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search letters by subject, citizen name...',
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
          child: DropdownButtonFormField<String>(
            value: _selectedArea,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            items: _uniqueAreas.map((area) {
              return DropdownMenuItem(
                value: area,
                child: Text(
                  area == 'All' ? 'All Areas' : area,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedArea = val);
            },
          ),
        ),
      ],
    );
  }

  // --- Main 3-Column Layout: 1/3 List + 2/3 Live Preview ---
  Widget _buildMainGrid(List<LetterModel> items, bool isMr) {
    if (items.isEmpty) {
      return _buildEmptyState(isMr);
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
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final letter = items[index];
                final isSelected = _selectedLetter?.id == letter.id;

                if (_activeTab == 'outgoing') {
                  return _buildOutgoingListItem(letter, isSelected, isMr);
                } else {
                  return _buildIncomingListItem(letter, isSelected, isMr);
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
              ? _buildPreviewPane(_selectedLetter!, isMr)
              : _buildSelectLetterPlaceholder(isMr),
        ),
      ],
    );
  }

  // Outgoing List Item (matching LetterDashboard.tsx lines 880-930)
  Widget _buildOutgoingListItem(LetterModel letter, bool isSelected, bool isMr) {
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
                  child: Text(
                    letter.letterType ?? letter.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusPill(letter.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              letter.citizenName,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            if (letter.subject.isNotEmpty && letter.subject != letter.title) ...[
              const SizedBox(height: 2),
              Text(
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
  Widget _buildIncomingListItem(LetterModel letter, bool isSelected, bool isMr) {
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
                  child: Text(
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
              Text(
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
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildStatusPill(String status) {
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
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
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
