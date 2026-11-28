import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/letter_model.dart';
import '../../providers/language_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'letter_detail_screen.dart';
import 'letter_form_constants.dart';
import 'new_letter_bottom_sheet.dart';
import 'letter_type_manager_sheet.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
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

  int _displayedLimit = 20;

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

  Future<void> _fetchLetters({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
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
    final lang = ref.read(appLanguageProvider);
    return _currentList.where((l) {
      if (_isOutgoing && _selectedStatus != 'All') {
        if (l.status.toLowerCase() != _selectedStatus.toLowerCase()) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = AppTranslations.normalizeAsciiDigits(_searchQuery).toLowerCase();
        final typeRaw = l.letterType ?? '';
        String? typeLocalized;
        if (typeRaw.isNotEmpty) {
          for (final opt in kLetterTypeOptions) {
            if (opt.key.toLowerCase() == typeRaw.toLowerCase()) {
              typeLocalized = opt.getLabel(lang);
              break;
            }
          }
          typeLocalized ??= DynamicTranslationService.getCachedTranslation(typeRaw, lang);
        }
        final areaLocalized = l.area != null ? AppTranslations.getAreaName(l.area!, lang) : null;
        final titleLocalized = DynamicTranslationService.getCachedTranslation(l.title, lang);
        final citizenLocalized = DynamicTranslationService.getCachedTranslation(
          l.citizenName,
          lang,
          isName: true,
        );

        final matches = AppTranslations.normalizeAsciiDigits(l.id).toLowerCase().contains(q) ||
            AppTranslations.normalizeAsciiDigits(l.title).toLowerCase().contains(q) ||
            (titleLocalized != null &&
                AppTranslations.normalizeAsciiDigits(titleLocalized).toLowerCase().contains(q)) ||
            AppTranslations.normalizeAsciiDigits(l.citizenName).toLowerCase().contains(q) ||
            (citizenLocalized != null &&
                AppTranslations.normalizeAsciiDigits(citizenLocalized).toLowerCase().contains(q)) ||
            (l.area != null &&
                AppTranslations.normalizeAsciiDigits(l.area!).toLowerCase().contains(q)) ||
            (areaLocalized != null &&
                AppTranslations.normalizeAsciiDigits(areaLocalized).toLowerCase().contains(q)) ||
            (l.letterType != null &&
                AppTranslations.normalizeAsciiDigits(l.letterType!).toLowerCase().contains(q)) ||
            (typeLocalized != null &&
                AppTranslations.normalizeAsciiDigits(typeLocalized).toLowerCase().contains(q)) ||
            (l.description != null &&
                AppTranslations.normalizeAsciiDigits(l.description!).toLowerCase().contains(q)) ||
            (l.mobile.isNotEmpty &&
                AppTranslations.normalizeAsciiDigits(l.mobile).toLowerCase().contains(q));
        if (!matches) return false;
      }

      if (_areaSearch.isNotEmpty) {
        final a = AppTranslations.normalizeAsciiDigits(_areaSearch).toLowerCase();
        final areaRaw = l.area != null
            ? AppTranslations.normalizeAsciiDigits(l.area!).toLowerCase()
            : '';
        final areaLoc = l.area != null
            ? AppTranslations.normalizeAsciiDigits(AppTranslations.getAreaName(l.area!, lang)).toLowerCase()
            : '';
        if (l.area == null || (!areaRaw.contains(a) && !areaLoc.contains(a))) {
          return false;
        }
      }

      if (_dateSearch.isNotEmpty) {
        final d = _getLetterDate(l);
        final ds = AppTranslations.normalizeAsciiDigits(_dateSearch).toLowerCase();
        final candidates = [
          DateFormat('MMM d, yyyy').format(d),
          DateFormat('dd MMM yyyy').format(d),
          DateFormat('dd/MM/yyyy').format(d),
          DateFormat('yyyy-MM-dd').format(d),
          AppTranslations.formatDate(d, lang, pattern: 'MMM d, yyyy'),
          AppTranslations.formatDate(d, lang, pattern: 'dd MMM yyyy'),
          AppTranslations.formatDate(d, lang, pattern: 'dd/MM/yyyy'),
        ];
        final matchesDate = candidates.any(
          (c) => AppTranslations.normalizeAsciiDigits(c).toLowerCase().contains(ds),
        );
        if (!matchesDate) return false;
      }

      return true;
    }).toList();
  }

  List<LetterModel> get _visibleLetters =>
      _filteredLetters.take(_displayedLimit).toList();

  void _openDetailScreen(LetterModel letter) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LetterDetailScreen(letter: letter),
      ),
    ).then((res) {
      if (res == true) _fetchLetters(showLoading: false);
    });
  }

  String _formatDateSearchDisplay(String rawDate, String lang) {
    final parsed = DateFormat('MMM d, yyyy').tryParse(rawDate);
    if (parsed != null) {
      return AppTranslations.formatDate(parsed, lang, pattern: 'MMM d, yyyy');
    }
    return AppTranslations.formatDigits(rawDate, lang);
  }

  String _resolveTypeDisplaySync(String? rawType, String lang) {
    if (rawType == null || rawType.trim().isEmpty) {
      return AppTranslations.pick(lang, en: 'Official Letter', mr: 'अधिकृत पत्र', hi: 'आधिकारिक पत्र');
    }
    for (final opt in kLetterTypeOptions) {
      if (opt.key.toLowerCase() == rawType.trim().toLowerCase()) {
        return opt.getLabel(lang);
      }
    }
    return rawType;
  }

  Future<void> _shareOnWhatsApp(LetterModel letter) async {
    final lang = ref.read(appLanguageProvider);
    final trTitle = await DynamicTranslationService.translateOrRaw(letter.title, lang);
    final rawType = _resolveTypeDisplaySync(letter.letterType, lang);
    final trType = await DynamicTranslationService.translateOrRaw(rawType, lang);
    final trCitizen = letter.citizenName == 'Citizen'
        ? AppTranslations.pick(lang, en: 'Citizen', mr: 'नागरिक', hi: 'नागरिक')
        : await DynamicTranslationService.translateOrRaw(letter.citizenName, lang, isName: true);
    final trStatus = letter.status.toLowerCase() == 'received'
        ? AppTranslations.pick(lang, en: 'Received', mr: 'प्राप्त', hi: 'प्राप्त')
        : AppTranslations.getStatus(letter.status, lang);

    final message = AppTranslations.pick(
      lang,
      en: 'Official Correspondence: $trTitle\n'
          'Type: $trType\n'
          'Status: $trStatus\n'
          'Citizen: $trCitizen\n'
          'Nagarsevak Office, Prabhag 12',
      mr: 'अधिकृत पत्रव्यवहार: $trTitle\n'
          'प्रकार: $trType\n'
          'स्थिती: $trStatus\n'
          'नागरिक: $trCitizen\n'
          'नगरसेवक कार्यालय, प्रभाग १२',
      hi: 'आधिकारिक पत्राचार: $trTitle\n'
          'प्रकार: $trType\n'
          'स्थिति: $trStatus\n'
          'नागरिक: $trCitizen\n'
          'नगरसेवक कार्यालय, वार्ड १२',
    );
    final text = Uri.encodeComponent(message);
    final cleanMobile = AppTranslations.normalizeAsciiDigits(letter.mobile).replaceAll(RegExp(r'\D'), '');
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
    final lang = ref.watch(appLanguageProvider);
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
              tooltip: AppTranslations.pick(
                lang,
                en: 'Open Menu Drawer',
                mr: 'मेनू उघडा',
                hi: 'मेनू खोलें',
              ),
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
            children: [
              Text(
                AppTranslations.getNavTitle('letters', lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                lang == 'mr'
                    ? 'आवक आणि जावक अधिकृत पत्रव्यवहार'
                    : (lang == 'hi'
                        ? 'आवक और जावक आधिकारिक पत्र व्यवहार'
                        : 'Inward and outward official municipal correspondence'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
              tooltip: lang == 'mr'
                  ? 'पत्रांचे प्रकार व्यवस्थापित करा'
                  : (lang == 'hi' ? 'पत्र प्रकार प्रबंधित करें' : 'Manage Letter Types'),
              onPressed: () => LetterTypeManagerSheet.show(context),
            ),
          ],
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
                            _displayedLimit = 20;
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
                                  '${lang == "mr" ? "जावक पत्रे" : (lang == "hi" ? "जावक पत्र" : "Outgoing Letters")} (${AppTranslations.formatDigits(outCount, lang)})',
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
                            _displayedLimit = 20;
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
                                  '${lang == "mr" ? "आवक पत्रे" : (lang == "hi" ? "आवक पत्र" : "Incoming Letters")} (${AppTranslations.formatDigits(inCount, lang)})',
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
                            onChanged: (val) => setState(() {
                              _searchQuery = val.trim();
                              _displayedLimit = 20;
                            }),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: lang == 'mr' ? 'पत्र, नागरिक किंवा विषय शोधा...' : (lang == 'hi' ? 'पत्र, नागरिक या विषय खोजें...' : 'Search letters, citizen, subject...'),
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _displayedLimit = 20;
                                        });
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
                          title: lang == 'mr' ? 'स्थिती निवडा' : (lang == 'hi' ? 'स्थिति चुनें' : 'Filter by Status'),
                          value: _selectedStatus,
                          height: 40,
                          isExpanded: false,
                          backgroundColor: const Color(0xFFF8FAFC),
                          borderColor: const Color(0xFFE2E8F0),
                          items: [
                            DropdownMenuItem(value: 'All', child: Text(lang == 'mr' ? 'सर्व स्थिती' : (lang == 'hi' ? 'सभी स्थिति' : 'All Status'), style: const TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Pending', child: Text(AppTranslations.getStatus('Pending', lang), style: const TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Approved', child: Text(AppTranslations.getStatus('Approved', lang), style: const TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Rejected', child: Text(AppTranslations.getStatus('Rejected', lang), style: const TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStatus = val;
                                _displayedLimit = 20;
                              });
                            }
                          },
                        ),
                      ],
                      const SizedBox(width: 8),

                      // Download Letters Register PDF Button
                      AppPdfButton.icon(
                        tooltip: lang == 'mr' ? 'अहवाल डाउनलोड करा' : (lang == 'hi' ? 'रिपोर्ट डाउनलोड करें' : 'Download Report'),
                        onPressed: () {
                          LetterReportGenerator.generateAndPrintLetterReport(
                            letters: _filteredLetters,
                            statusFilter: _selectedStatus != 'All' ? _selectedStatus : null,
                            areaFilter: _areaSearch.isNotEmpty ? _areaSearch : null,
                            lang: lang,
                            title: _isOutgoing
                                ? (lang == 'mr' ? 'जावक पत्र अधिकृत नोंदवही (Outgoing Letters)' : (lang == 'hi' ? 'जावक पत्र आधिकारिक रजिस्टर' : 'Official Outgoing Letters Register'))
                                : (lang == 'mr' ? 'आवक पत्र अधिकृत नोंदवही (Incoming Letters)' : (lang == 'hi' ? 'आवक पत्र आधिकारिक रजिस्टर' : 'Official Incoming Letters Register')),
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
                          onTap: () => _openAreaPickerSheet(context, lang),
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
                                  child: _areaSearch.isNotEmpty
                                      ? AppTranslatedText(
                                          AppTranslations.getAreaName(_areaSearch, lang),
                                          targetLanguage: lang,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                        )
                                      : Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Search area...',
                                            mr: 'भाग शोधा...',
                                            hi: 'क्षेत्र खोजें...',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF94A3B8),
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
                          onTap: () => _openDateFilterSheet(context, lang),
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
                                        ? _formatDateSearchDisplay(_dateSearch, lang)
                                        : AppTranslations.pick(
                                            lang,
                                            en: 'Filter by date...',
                                            mr: 'तारीख निवडा...',
                                            hi: 'तिथि चुनें...',
                                          ),
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
                              label: AppTranslations.getAreaName(_areaSearch, lang),
                              prefix: AppTranslations.pick(lang, en: 'Area: ', mr: 'भाग: ', hi: 'क्षेत्र: '),
                              translateDynamic: true,
                              lang: lang,
                              onDelete: () {
                                _areaController.clear();
                                setState(() => _areaSearch = '');
                              },
                            ),
                          if (_dateSearch.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _buildActiveFilterChip(
                              label: '${AppTranslations.pick(lang, en: 'Date: ', mr: 'तारीख: ', hi: 'तिथि: ')}${_formatDateSearchDisplay(_dateSearch, lang)}',
                              lang: lang,
                              onDelete: () {
                                _dateController.clear();
                                setState(() => _dateSearch = '');
                              },
                            ),
                          ],
                          if (_isOutgoing && _selectedStatus != 'All') ...[
                            const SizedBox(width: 6),
                            _buildActiveFilterChip(
                              label: '${AppTranslations.pick(lang, en: 'Status: ', mr: 'स्थिती: ', hi: 'स्थिति: ')}${AppTranslations.getStatus(_selectedStatus, lang)}',
                              lang: lang,
                              onDelete: () => setState(() => _selectedStatus = 'All'),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _clearAllFilters,
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Clear all',
                                mr: 'सर्व साफ करा',
                                hi: 'सभी साफ़ करें',
                              ),
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
                  ? const AppShimmerList(count: 6)
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
                                AppTranslations.pick(
                                  lang,
                                  en: 'No records found',
                                  mr: 'कोणतीही माहिती आढळली नाही',
                                  hi: 'कोई रिकॉर्ड नहीं मिला',
                                ),
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              if (_searchQuery.isNotEmpty || _areaSearch.isNotEmpty || _dateSearch.isNotEmpty || (_isOutgoing && _selectedStatus != 'All')) ...[
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                  label: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Clear Filters',
                                      mr: 'फिल्टर साफ करा',
                                      hi: 'फ़िल्टर साफ़ करें',
                                    ),
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
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                            itemCount: _visibleLetters.length +
                                (filtered.isNotEmpty ? 1 : 0),
                            itemBuilder: (ctx, idx) {
                              if (idx == _visibleLetters.length) {
                                  return AppLoadMoreFooter(
                                    currentCount: _visibleLetters.length,
                                    totalCount: filtered.length,
                                    pageSize: 20,
                                    onLoadMore: () {
                                      setState(() => _displayedLimit += 20);
                                    },
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'letters',
                                      mr: 'पत्रे',
                                      hi: 'पत्र',
                                    ),
                                    isMarathi: lang == 'mr',
                                  );
                              }
                              final item = _visibleLetters[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _LetterCard(
                                  letter: item,
                                  lang: lang,
                                  onTap: () => _openDetailScreen(item),
                                  onWhatsApp: () => _shareOnWhatsApp(item),
                                ),
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
                ? AppTranslations.pick(lang, en: 'New Letter', mr: 'नवीन जावक पत्र', hi: 'नया जावक पत्र')
                : AppTranslations.pick(lang, en: 'Scan Incoming Letter', mr: 'आवक पत्र स्कॅन करा', hi: 'आवक पत्र स्कैन करें'),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDate(BuildContext context) async {
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
      _displayedLimit = 20;
    });
  }

  void _openAreaPickerSheet(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _LettersAreaPickerSheet(
        initialArea: _areaSearch,
        areas: _areaSuggestions,
        lang: lang,
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

  void _openDateFilterSheet(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _LettersDateFilterSheet(
        initialDate: _dateSearch,
        dates: _dateSuggestions,
        lang: lang,
        onPickCalendar: () async {
          Navigator.pop(ctx);
          await _pickCustomDate(context);
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

  Widget _buildActiveFilterChip({
    required String label,
    String prefix = '',
    bool translateDynamic = false,
    required String lang,
    required VoidCallback onDelete,
  }) {
    const chipStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155));
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
          if (translateDynamic)
            AppTranslatedText(
              label,
              prefix: prefix,
              targetLanguage: lang,
              style: chipStyle,
            )
          else
            Text(
              '$prefix$label',
              style: chipStyle,
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
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onWhatsApp;

  const _LetterCard({
    required this.letter,
    this.lang = 'en',
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
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: letter.isIncoming ? const Color(0xFFE0F2FE) : const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _buildLetterTypeText(
                                  letter.letterType,
                                  lang,
                                  TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: letter.isIncoming ? const Color(0xFF0369A1) : const Color(0xFF7E22CE),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(letter.status, lang),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Title / Subject
                        AppTranslatedText(
                          letter.title,
                          targetLanguage: lang,
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
                              child: letter.citizenName == 'Citizen'
                                  ? Text(
                                      AppTranslations.pick(lang, en: 'Citizen', mr: 'नागरिक', hi: 'नागरिक'),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : AppTranslatedText(
                                      letter.citizenName,
                                      isName: true,
                                      targetLanguage: lang,
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
                                      child: _buildAreaText(letter.area!, lang),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 3),
                                  Text(
                                    AppTranslations.formatDate(
                                      letter.receivedDate ?? letter.createdAt,
                                      lang,
                                      pattern: 'MMM d',
                                    ),
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
                                    children: [
                                      Text(
                                        AppTranslations.getDetails(lang),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF0284C7)),
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

  Widget _buildLetterTypeText(String? rawType, String lang, TextStyle style) {
    if (rawType == null || rawType.trim().isEmpty) {
      return Text(
        AppTranslations.pick(lang, en: 'Official', mr: 'अधिकृत', hi: 'आधिकारिक'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final clean = rawType.trim();
    for (final opt in kLetterTypeOptions) {
      if (opt.key.toLowerCase() == clean.toLowerCase()) {
        return Text(
          opt.getLabel(lang),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      }
    }
    return AppTranslatedText(
      clean,
      targetLanguage: lang,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Widget _buildAreaText(String rawArea, String lang) {
    final locArea = AppTranslations.getAreaName(rawArea, lang);
    const areaStyle = TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500);
    if (locArea != rawArea.trim()) {
      return Text(
        locArea,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: areaStyle,
      );
    }
    return AppTranslatedText(
      rawArea,
      targetLanguage: lang,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: areaStyle,
    );
  }

  Widget _buildStatusBadge(String status, String lang) {
    Color bg;
    Color border;
    Color text;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF166534);
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFB91C1C);
        break;
      case 'received':
        bg = const Color(0xFFDBEAFE);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF1E40AF);
        break;
      default:
        bg = const Color(0xFFFEFCE8);
        border = const Color(0xFFFDE047);
        text = const Color(0xFF854D0E);
    }

    final label = status.toLowerCase() == 'received'
        ? AppTranslations.pick(lang, en: 'Received', mr: 'प्राप्त', hi: 'प्राप्त')
        : AppTranslations.getStatus(status, lang);

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
  final String lang;
  final ValueChanged<String?> onSelect;

  const _LettersAreaPickerSheet({
    required this.initialArea,
    required this.areas,
    this.lang = 'en',
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
    final q = AppTranslations.normalizeAsciiDigits(query.trim()).toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredAreas = widget.areas;
      } else {
        _filteredAreas = widget.areas.where((a) {
          final raw = AppTranslations.normalizeAsciiDigits(a.key).toLowerCase();
          final loc = AppTranslations.normalizeAsciiDigits(
            AppTranslations.getAreaName(a.key, widget.lang),
          ).toLowerCase();
          final cached = AppTranslations.normalizeAsciiDigits(
            DynamicTranslationService.getCachedTranslation(a.key, widget.lang) ?? '',
          ).toLowerCase();
          return raw.contains(q) || loc.contains(q) || (cached.isNotEmpty && cached.contains(q));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.75;
    final lang = widget.lang;

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
                        AppTranslations.pick(
                          lang,
                          en: 'Filter by Area',
                          mr: 'क्षेत्र निवडा',
                          hi: 'क्षेत्र के अनुसार फ़िल्टर करें',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppTranslations.formatDigits(widget.areas.length, lang)} ${AppTranslations.pick(lang, en: 'areas available', mr: 'क्षेत्रे उपलब्ध', hi: 'क्षेत्र उपलब्ध')}',
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
                  tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
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
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search area...',
                  mr: 'क्षेत्र शोधा...',
                  hi: 'क्षेत्र खोजें...',
                ),
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
                              AppTranslations.pick(
                                lang,
                                en: 'All Areas (Clear Filter)',
                                mr: 'सर्व क्षेत्रे (फिल्टर काढा)',
                                hi: 'सभी क्षेत्र (फ़िल्टर हटाएं)',
                              ),
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
                        AppTranslations.pick(
                          lang,
                          en: 'No areas found',
                          mr: 'कोणतेही क्षेत्र सापडले नाही',
                          hi: 'कोई क्षेत्र नहीं मिला',
                        ),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else
                  ..._filteredAreas.map((item) {
                    final isSelected = widget.initialArea == item.key;
                    final locArea = AppTranslations.getAreaName(item.key, lang);
                    final itemStyle = TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                    );
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
                                child: locArea != item.key.trim()
                                    ? Text(locArea, style: itemStyle)
                                    : AppTranslatedText(
                                        item.key,
                                        targetLanguage: lang,
                                        style: itemStyle,
                                      ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  AppTranslations.formatDigits(item.value, lang),
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
  final String lang;
  final VoidCallback onPickCalendar;
  final ValueChanged<String?> onSelect;

  const _LettersDateFilterSheet({
    required this.initialDate,
    required this.dates,
    this.lang = 'en',
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

  String _formatEntryDate(String key) {
    final parsed = DateFormat('MMM d, yyyy').tryParse(key);
    if (parsed != null) {
      return AppTranslations.formatDate(parsed, widget.lang, pattern: 'MMM d, yyyy');
    }
    return AppTranslations.formatDigits(key, widget.lang);
  }

  void _filter(String query) {
    final q = AppTranslations.normalizeAsciiDigits(query.trim()).toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredDates = widget.dates;
      } else {
        _filteredDates = widget.dates.where((d) {
          if (AppTranslations.normalizeAsciiDigits(d.key).toLowerCase().contains(q)) {
            return true;
          }
          final parsed = DateFormat('MMM d, yyyy').tryParse(d.key);
          if (parsed != null) {
            final loc1 = AppTranslations.normalizeAsciiDigits(
              AppTranslations.formatDate(parsed, widget.lang, pattern: 'MMM d, yyyy'),
            ).toLowerCase();
            final loc2 = AppTranslations.normalizeAsciiDigits(
              AppTranslations.formatDate(parsed, widget.lang, pattern: 'dd MMM yyyy'),
            ).toLowerCase();
            final loc3 = AppTranslations.normalizeAsciiDigits(
              AppTranslations.formatDate(parsed, widget.lang, pattern: 'dd/MM/yyyy'),
            ).toLowerCase();
            return loc1.contains(q) || loc2.contains(q) || loc3.contains(q);
          }
          return false;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.75;
    final lang = widget.lang;

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
                        AppTranslations.pick(
                          lang,
                          en: 'Filter by Date',
                          mr: 'तारीख निवडा',
                          hi: 'तिथि के अनुसार फ़िल्टर करें',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppTranslations.formatDigits(widget.dates.length, lang)} ${AppTranslations.pick(lang, en: 'letter dates recorded', mr: 'तारखा नोंदवलेल्या', hi: 'पत्र तिथियां दर्ज')}',
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
                  tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
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
                        AppTranslations.pick(
                          lang,
                          en: 'Pick any date from calendar',
                          mr: 'कॅलेंडरमधून तारीख निवडा',
                          hi: 'कैलेंडर से कोई भी तिथि चुनें',
                        ),
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
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search date (e.g. Oct 2026)...',
                  mr: 'तारीख शोधा (उदा. ऑक्टो २०२६)...',
                  hi: 'तिथि खोजें (उदा. अक्टू २०२६)...',
                ),
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
                              AppTranslations.pick(
                                lang,
                                en: 'All Dates (Clear Date Filter)',
                                mr: 'सर्व तारखा (फिल्टर काढा)',
                                hi: 'सभी तिथियां (फ़िल्टर हटाएं)',
                              ),
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
                        AppTranslations.pick(
                          lang,
                          en: 'No dates found',
                          mr: 'कोणतीही तारीख सापडली नाही',
                          hi: 'कोई तिथि नहीं मिली',
                        ),
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
                                  _formatEntryDate(item.key),
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
                                  '${AppTranslations.formatDigits(item.value, lang)} ${AppTranslations.pick(lang, en: 'letters', mr: 'पत्रे', hi: 'पत्र')}',
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
