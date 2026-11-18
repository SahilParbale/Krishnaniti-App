import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../data/models/letter_model.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'letter_detail_screen.dart';
import 'new_letter_bottom_sheet.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_pdf_button.dart';
import 'letter_report_generator.dart';

class LettersScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onTabChange;

  const LettersScreen({super.key, this.onTabChange});

  @override
  ConsumerState<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends ConsumerState<LettersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // Tabs: true = Outgoing Letters, false = Incoming Letters
  bool _isOutgoing = true;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _searchQuery = '';
  String _areaSearch = '';
  String _dateSearch = '';
  String _selectedStatus = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'
  bool _isLoading = false;

  List<LetterModel> _outgoingLetters = [];
  List<LetterModel> _incomingLetters = [];

  @override
  void initState() {
    super.initState();
    _fetchLetters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _areaController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchLetters() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(lettersRepoProvider);
      final outRes = await repo.getLetters(isIncoming: false);
      final inRes = await repo.getLetters(isIncoming: true);

      if (mounted) {
        setState(() {
          _outgoingLetters = outRes;
          _incomingLetters = inRes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LetterModel> get _currentList {
    return _isOutgoing ? _outgoingLetters : _incomingLetters;
  }

  DateTime _getLetterDate(LetterModel l) {
    return _isOutgoing ? l.createdAt : (l.receivedDate ?? l.createdAt);
  }

  // Helper: Get Unique Areas with Counts matching Nagarsevak-Managment getAreaSuggestions
  List<MapEntry<String, int>> get _areaSuggestions {
    final stats = <String, int>{};
    for (final r in _currentList) {
      if (r.area != null && r.area!.trim().isNotEmpty) {
        final a = r.area!.trim();
        stats[a] = (stats[a] ?? 0) + 1;
      }
    }
    final entries = stats.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  // Helper: Get Unique Dates with Counts matching Nagarsevak-Managment getDateSuggestions
  List<MapEntry<String, int>> get _dateSuggestions {
    final stats = <String, int>{};
    for (final r in _currentList) {
      final d = _getLetterDate(r);
      final dateStr = DateFormat('MMM d, yyyy').format(d);
      stats[dateStr] = (stats[dateStr] ?? 0) + 1;
    }
    return stats.entries.toList();
  }

  List<LetterModel> get _filteredLetters {
    return _currentList.where((l) {
      if (_isOutgoing && _selectedStatus != 'All') {
        if (l.status.toLowerCase() != _selectedStatus.toLowerCase()) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = l.id.toLowerCase().contains(q) ||
            l.title.toLowerCase().contains(q) ||
            l.citizenName.toLowerCase().contains(q) ||
            (l.area != null && l.area!.toLowerCase().contains(q)) ||
            (l.letterType != null && l.letterType!.toLowerCase().contains(q)) ||
            (l.description != null && l.description!.toLowerCase().contains(q));
        if (!matches) return false;
      }

      if (_areaSearch.isNotEmpty) {
        final a = _areaSearch.toLowerCase();
        if (l.area == null || !l.area!.toLowerCase().contains(a)) {
          return false;
        }
      }

      if (_dateSearch.isNotEmpty) {
        final d = _getLetterDate(l);
        final dateStr1 = DateFormat('MMM d, yyyy').format(d).toLowerCase();
        final dateStr2 = DateFormat('dd MMM yyyy').format(d).toLowerCase();
        final dateStr3 = DateFormat('dd/MM/yyyy').format(d).toLowerCase();
        final dateStr4 = DateFormat('yyyy-MM-dd').format(d).toLowerCase();
        final ds = _dateSearch.toLowerCase();
        final matchesDate = dateStr1.contains(ds) ||
            dateStr2.contains(ds) ||
            dateStr3.contains(ds) ||
            dateStr4.contains(ds);
        if (!matchesDate) return false;
      }

      return true;
    }).toList();
  }

  void _openDetailScreen(LetterModel letter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LetterDetailScreen(letter: letter),
      ),
    ).then((_) => _fetchLetters());
  }

  void _shareOnWhatsApp(LetterModel letter) async {
    final text = Uri.encodeComponent(
      'Official Correspondence: ${letter.title}\n'
      'Type: ${letter.letterType ?? 'Official Letter'}\n'
      'Status: ${letter.status}\n'
      'Citizen: ${letter.citizenName}\n'
      'Nagarsevak Office, Prabhag 12',
    );
    final cleanMobile = letter.mobile.replaceAll(RegExp(r'\D'), '');
    final uri = cleanMobile.isNotEmpty
        ? Uri.parse('https://wa.me/91$cleanMobile?text=$text')
        : Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Open Create Outgoing Letter Modal
  Future<void> _openCreateLetterModal() async {
    final result = await NewLetterBottomSheet.show(context, initialTab: 'outgoing');
    if (result == true && mounted) {
      _fetchLetters();
    }
  }

  // Open Scan / Upload Incoming Letter Modal
  Future<void> _openUploadIncomingModal() async {
    final result = await NewLetterBottomSheet.show(context, initialTab: 'incoming');
    if (result == true && mounted) {
      _fetchLetters();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isMr = ref.watch(isMarathiProvider);
    final filtered = _filteredLetters;

    final outCount = _outgoingLetters.length;
    final inCount = _incomingLetters.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: NagarsevakAppDrawer(
          currentTabIndex: 2,
          onTabChange: widget.onTabChange,
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Open Menu Drawer',
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Letters',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Inward and outward official municipal correspondence',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: const [],
        ),
        body: Column(
          children: [
            // Top Inward / Outward Navigation Tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Outgoing Tab Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isOutgoing = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _isOutgoing ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _isOutgoing
                                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_made_rounded,
                                size: 16,
                                color: _isOutgoing ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${isMr ? AppStrings.outgoingLettersMr : AppStrings.outgoingLetters} ($outCount)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _isOutgoing ? FontWeight.w800 : FontWeight.w600,
                                    color: _isOutgoing ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Incoming Tab Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isOutgoing = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: !_isOutgoing ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !_isOutgoing
                                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_received_rounded,
                                size: 16,
                                color: !_isOutgoing ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${isMr ? AppStrings.incomingLettersMr : AppStrings.incomingLetters} ($inCount)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: !_isOutgoing ? FontWeight.w800 : FontWeight.w600,
                                    color: !_isOutgoing ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar & Advanced Filters (Search, Search by Area, Filter by Date)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: General Search & Status Dropdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: isMr ? 'पत्र, नागरिक किंवा विषय शोधा...' : 'Search letters, citizen, subject...',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 9),
                            ),
                          ),
                        ),
                      ),

                      // Status filter for Outgoing letters (Themed Component)
                      if (_isOutgoing) ...[
                        const SizedBox(width: 8),
                        AppDropdown<String>(
                          title: isMr ? 'स्थिती निवडा' : 'Filter by Status',
                          value: _selectedStatus,
                          height: 40,
                          isExpanded: false,
                          backgroundColor: const Color(0xFFF8FAFC),
                          borderColor: const Color(0xFFE2E8F0),
                          items: [
                            DropdownMenuItem(value: 'All', child: Text(isMr ? 'सर्व स्थिती' : 'All Status', style: const TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Pending', child: Text(isMr ? 'प्रलंबित' : 'Pending', style: const TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Approved', child: Text(isMr ? 'मंजूर' : 'Approved', style: const TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Rejected', child: Text(isMr ? 'नाकारले' : 'Rejected', style: const TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ],
                      const SizedBox(width: 8),

                      // Download Letters Register PDF Button
                      AppPdfButton.icon(
                        tooltip: isMr ? 'पत्र नोंदवही अहवाल डाउनलोड करा' : 'Download Letter Register PDF',
                        onPressed: () {
                          LetterReportGenerator.generateAndPrintLetterReport(
                            letters: _filteredLetters,
                            statusFilter: _selectedStatus != 'All' ? _selectedStatus : null,
                            areaFilter: _areaSearch.isNotEmpty ? _areaSearch : null,
                            title: _isOutgoing
                                ? (isMr ? 'जावक पत्र अधिकृत नोंदवही (Outgoing Letters)' : 'Official Outgoing Letters Register')
                                : (isMr ? 'आवक पत्र अधिकृत नोंदवही (Incoming Letters)' : 'Official Incoming Letters Register'),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 2: Search by Area & Filter by Date (Krishnaniti Themed Pickers)
                  Row(
                    children: [
                      // Area Search / Filter Button
                      Expanded(
                        child: InkWell(
                          onTap: () => _openAreaPickerSheet(context, isMr),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: _areaSearch.isNotEmpty ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _areaSearch.isNotEmpty
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Color(0xFF0284C7), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _areaSearch.isNotEmpty
                                        ? _areaSearch
                                        : (isMr ? AppStrings.searchAreaPlaceholderMr : AppStrings.searchAreaPlaceholder),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _areaSearch.isNotEmpty ? FontWeight.w600 : FontWeight.w500,
                                      color: _areaSearch.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                if (_areaSearch.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _areaController.clear();
                                      setState(() => _areaSearch = '');
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.close_rounded, size: 15, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF0284C7)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Date Search / Filter Button
                      Expanded(
                        child: InkWell(
                          onTap: () => _openDateFilterSheet(context, isMr),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: _dateSearch.isNotEmpty ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _dateSearch.isNotEmpty
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: Color(0xFF0284C7), size: 15),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _dateSearch.isNotEmpty
                                        ? _dateSearch
                                        : (isMr ? AppStrings.filterDatePlaceholderMr : AppStrings.filterDatePlaceholder),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _dateSearch.isNotEmpty ? FontWeight.w600 : FontWeight.w500,
                                      color: _dateSearch.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                if (_dateSearch.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _dateController.clear();
                                      setState(() => _dateSearch = '');
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.close_rounded, size: 15, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF0284C7)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Active Filter Chips / Clear All Row
                  if (_areaSearch.isNotEmpty || _dateSearch.isNotEmpty || (_isOutgoing && _selectedStatus != 'All')) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_areaSearch.isNotEmpty)
                            _buildActiveFilterChip(
                              label: '${isMr ? 'क्षेत्र: ' : 'Area: '}$_areaSearch',
                              onDelete: () {
                                _areaController.clear();
                                setState(() => _areaSearch = '');
                              },
                            ),
                          if (_dateSearch.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _buildActiveFilterChip(
                              label: '${isMr ? 'तारीख: ' : 'Date: '}$_dateSearch',
                              onDelete: () {
                                _dateController.clear();
                                setState(() => _dateSearch = '');
                              },
                            ),
                          ],
                          if (_isOutgoing && _selectedStatus != 'All') ...[
                            const SizedBox(width: 6),
                            _buildActiveFilterChip(
                              label: '${isMr ? 'स्थिती: ' : 'Status: '}$_selectedStatus',
                              onDelete: () => setState(() => _selectedStatus = 'All'),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _clearAllFilters,
                            child: Text(
                              isMr ? 'सर्व साफ करा' : 'Clear all',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Letters List
            Expanded(
              child: _isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)))
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mail_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isMr ? AppStrings.noDataFoundMr : AppStrings.noDataFound,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                if (_searchQuery.isNotEmpty || _areaSearch.isNotEmpty || _dateSearch.isNotEmpty || (_isOutgoing && _selectedStatus != 'All')) ...[
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _clearAllFilters,
                                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                    label: Text(
                                      isMr ? 'फिल्टर साफ करा' : 'Clear Filters',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0284C7),
                                      side: const BorderSide(color: Color(0xFF0284C7)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                      : RefreshIndicator(
                          onRefresh: _fetchLetters,
                          color: const Color(0xFF0284C7),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final item = filtered[idx];
                              return _LetterCard(
                                letter: item,
                                isMr: isMr,
                                onTap: () => _openDetailScreen(item),
                                onWhatsApp: () => _shareOnWhatsApp(item),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),

        // Floating Action Button (+ New Outgoing or + Scan Incoming)
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isOutgoing ? _openCreateLetterModal : _openUploadIncomingModal,
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: Icon(_isOutgoing ? Icons.add_rounded : Icons.document_scanner_outlined, size: 20),
          label: Text(
            _isOutgoing
                ? (isMr ? AppStrings.newLetterMr : AppStrings.newLetter)
                : (isMr ? AppStrings.scanLetterMr : AppStrings.scanLetter),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDate(BuildContext context, bool isMr) async {
    final picked = await showThemedDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      final formatted = DateFormat('MMM d, yyyy').format(picked);
      _dateController.text = formatted;
      setState(() {
        _dateSearch = formatted;
      });
    }
  }

  void _clearAllFilters() {
    _searchController.clear();
    _areaController.clear();
    _dateController.clear();
    setState(() {
      _searchQuery = '';
      _areaSearch = '';
      _dateSearch = '';
      _selectedStatus = 'All';
    });
  }

  void _openAreaPickerSheet(BuildContext context, bool isMr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _LettersAreaPickerSheet(
        initialArea: _areaSearch,
        areas: _areaSuggestions,
        isMr: isMr,
        onSelect: (selected) {
          Navigator.pop(ctx);
          _areaController.text = selected ?? '';
          setState(() {
            _areaSearch = selected ?? '';
          });
        },
      ),
    );
  }

  void _openDateFilterSheet(BuildContext context, bool isMr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _LettersDateFilterSheet(
        initialDate: _dateSearch,
        dates: _dateSuggestions,
        isMr: isMr,
        onPickCalendar: () async {
          Navigator.pop(ctx);
          await _pickCustomDate(context, isMr);
        },
        onSelect: (selected) {
          Navigator.pop(ctx);
          _dateController.text = selected ?? '';
          setState(() {
            _dateSearch = selected ?? '';
          });
        },
      ),
    );
  }

  Widget _buildActiveFilterChip({required String label, required VoidCallback onDelete}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LETTER CARD WIDGET
// -----------------------------------------------------------------------------
class _LetterCard extends StatelessWidget {
  final LetterModel letter;
  final bool isMr;
  final VoidCallback onTap;
  final VoidCallback onWhatsApp;

  const _LetterCard({
    required this.letter,
    required this.isMr,
    required this.onTap,
    required this.onWhatsApp,
  });

  Color get _leftBorderColor {
    if (letter.isIncoming) return const Color(0xFF0284C7);
    final s = letter.status.toLowerCase();
    if (s == 'approved') return const Color(0xFF16A34A);
    if (s == 'rejected') return const Color(0xFFDC2626);
    if (s == 'pending') return const Color(0xFFEAB308);
    return const Color(0xFFCBD5E1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Color Bar matching status
              Container(width: 4.5, color: _leftBorderColor),

              // Card Body
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Type Pill & Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: letter.isIncoming ? const Color(0xFFE0F2FE) : const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                letter.letterType ?? 'Official',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: letter.isIncoming ? const Color(0xFF0369A1) : const Color(0xFF7E22CE),
                                ),
                              ),
                            ),
                            _buildStatusBadge(letter.status, isMr),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Title / Subject
                        Text(
                          letter.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Citizen Name / Department
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                letter.citizenName,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 8),

                        // Footer Row: Area, Date, WhatsApp, Details Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (letter.area != null && letter.area!.isNotEmpty) ...[
                                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        letter.area!,
                                        maxLines: 1,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('MMM d').format(letter.receivedDate ?? letter.createdAt),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: onWhatsApp,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF6EE7B7)),
                                    ),
                                    child: const Icon(Icons.chat_rounded, size: 14, color: Color(0xFF059669)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Details',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF0284C7)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isMr) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF166534);
        label = isMr ? 'मंजूर' : 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFB91C1C);
        label = isMr ? 'नाकारले' : 'Rejected';
        break;
      case 'received':
        bg = const Color(0xFFDBEAFE);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF1E40AF);
        label = isMr ? 'प्राप्त' : 'Received';
        break;
      default:
        bg = const Color(0xFFFEFCE8);
        border = const Color(0xFFFDE047);
        text = const Color(0xFF854D0E);
        label = isMr ? 'प्रलंबित' : 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}

/// Themed Krishnaniti bottom sheet modal picker for letter areas.
class _LettersAreaPickerSheet extends StatefulWidget {
  final String initialArea;
  final List<MapEntry<String, int>> areas;
  final bool isMr;
  final ValueChanged<String?> onSelect;

  const _LettersAreaPickerSheet({
    required this.initialArea,
    required this.areas,
    required this.isMr,
    required this.onSelect,
  });

  @override
  State<_LettersAreaPickerSheet> createState() => _LettersAreaPickerSheetState();
}

class _LettersAreaPickerSheetState extends State<_LettersAreaPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<MapEntry<String, int>> _filteredAreas;

  @override
  void initState() {
    super.initState();
    _filteredAreas = widget.areas;
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
        _filteredAreas = widget.areas;
      } else {
        _filteredAreas = widget.areas.where((a) => a.key.toLowerCase().contains(q)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.75;
    final isMr = widget.isMr;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
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
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF0284C7),
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
                        isMr ? 'क्षेत्र निवडा' : 'Filter by Area',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.areas.length} ${isMr ? 'क्षेत्रे उपलब्ध' : 'areas available'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Live Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: isMr ? 'क्षेत्र शोधा...' : 'Search area...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
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
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Options List
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(12, 8, 12, mediaQuery.viewInsets.bottom + 16),
              children: [
                // "All Areas" Reset Option
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () => widget.onSelect(null),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.initialArea.isEmpty
                            ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            size: 18,
                            color: widget.initialArea.isEmpty ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isMr ? 'सर्व क्षेत्रे (Clear Filter)' : 'All Areas (Clear Filter)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: widget.initialArea.isEmpty ? FontWeight.w700 : FontWeight.w500,
                                color: widget.initialArea.isEmpty ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (widget.initialArea.isEmpty)
                            const Icon(Icons.check_rounded, color: Color(0xFF0284C7), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(height: 8, thickness: 0.5, color: Color(0xFFE2E8F0)),

                if (_filteredAreas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        isMr ? AppStrings.noAreasFoundMr : AppStrings.noAreasFound,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else
                  ..._filteredAreas.map((item) {
                    final isSelected = widget.initialArea == item.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: InkWell(
                        onTap: () => widget.onSelect(item.key),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${item.value}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_rounded, color: Color(0xFF0284C7), size: 18),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Themed Krishnaniti bottom sheet modal picker for letter dates.
class _LettersDateFilterSheet extends StatefulWidget {
  final String initialDate;
  final List<MapEntry<String, int>> dates;
  final bool isMr;
  final VoidCallback onPickCalendar;
  final ValueChanged<String?> onSelect;

  const _LettersDateFilterSheet({
    required this.initialDate,
    required this.dates,
    required this.isMr,
    required this.onPickCalendar,
    required this.onSelect,
  });

  @override
  State<_LettersDateFilterSheet> createState() => _LettersDateFilterSheetState();
}

class _LettersDateFilterSheetState extends State<_LettersDateFilterSheet> {
  final _searchCtrl = TextEditingController();
  late List<MapEntry<String, int>> _filteredDates;

  @override
  void initState() {
    super.initState();
    _filteredDates = widget.dates;
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
        _filteredDates = widget.dates;
      } else {
        _filteredDates = widget.dates.where((d) => d.key.toLowerCase().contains(q)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.75;
    final isMr = widget.isMr;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
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
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF0284C7),
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
                        isMr ? 'तारीख निवडा' : 'Filter by Date',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.dates.length} ${isMr ? 'तारखा नोंदवलेल्या' : 'letter dates recorded'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Calendar Quick Pick Action Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: InkWell(
              onTap: widget.onPickCalendar,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF0284C7)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isMr ? 'कॅलेंडरमधून तारीख निवडा (Custom Date)' : 'Pick any date from calendar',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF0284C7)),
                  ],
                ),
              ),
            ),
          ),

          // Live Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: isMr ? 'तारीख शोधा (उदा. Oct 2026)...' : 'Search date (e.g. Oct 2026)...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
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
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Options List
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(12, 8, 12, mediaQuery.viewInsets.bottom + 16),
              children: [
                // "All Dates" Reset Option
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () => widget.onSelect(null),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.initialDate.isEmpty
                            ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            size: 18,
                            color: widget.initialDate.isEmpty ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isMr ? 'सर्व तारखा (Clear Date Filter)' : 'All Dates (Clear Date Filter)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: widget.initialDate.isEmpty ? FontWeight.w700 : FontWeight.w500,
                                color: widget.initialDate.isEmpty ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (widget.initialDate.isEmpty)
                            const Icon(Icons.check_rounded, color: Color(0xFF0284C7), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(height: 8, thickness: 0.5, color: Color(0xFFE2E8F0)),

                if (_filteredDates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        isMr ? 'कोणतीही तारीख सापडली नाही' : 'No dates found',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else
                  ..._filteredDates.map((item) {
                    final isSelected = widget.initialDate == item.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: InkWell(
                        onTap: () => widget.onSelect(item.key),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 17,
                                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${item.value} ${isMr ? 'पत्रे' : 'letters'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_rounded, color: Color(0xFF0284C7), size: 18),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
