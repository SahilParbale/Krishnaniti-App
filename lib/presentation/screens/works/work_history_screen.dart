import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/work_history_model.dart';
import '../../../data/repositories/work_history_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'ahwal_report_generator.dart';
import 'work_detail_screen.dart';
import 'work_report_generator.dart';

/// WorkHistory Screen matching EXACTLY the web page:
/// Nagarsevak-Managment/src/pages/works/WorkHistory.tsx
class WorkHistoryScreen extends ConsumerStatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  ConsumerState<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends ConsumerState<WorkHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _areaSearchCtrl = TextEditingController();
  final TextEditingController _dateSearchCtrl = TextEditingController();

  String _viewMode = 'grid'; // 'grid' | 'report' matching WorkHistory.tsx line 42

  bool _showAreaDropdown = false;
  bool _showDateDropdown = false;

  bool _loading = true;
  List<WorkHistoryModel> _items = [];

  int _displayedLimit = 20;

  // Ahwal Selection Mode State matching lines 54-58
  bool _selectionMode = false;
  final Set<String> _selectedWorkIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _areaSearchCtrl.dispose();
    _dateSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final repo = ref.read(workHistoryRepoProvider);
    final works = await repo.getWorks();
    if (mounted) {
      setState(() {
        _items = works;
        _loading = false;
      });
    }
  }

  // Area Suggestions with counts matching WorkHistory.tsx lines 226-234
  List<Map<String, dynamic>> get _areaSuggestions {
    final Map<String, int> stats = {};
    for (final item in _items) {
      if (item.area.isNotEmpty) {
        stats[item.area] = (stats[item.area] ?? 0) + 1;
      }
    }
    final list = stats.entries.map((e) => {'area': e.key, 'count': e.value}).toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list;
  }

  String _formatWorkDate(String raw, String lang) {
    if (raw.trim().isEmpty) return '-';
    final dt = DateTime.tryParse(raw.trim());
    if (dt != null) {
      return AppTranslations.formatDate(dt, lang, pattern: 'MMM d, yyyy');
    }
    return AppTranslations.formatDigits(raw, lang);
  }

  // Date Suggestions with counts matching WorkHistory.tsx lines 237-246
  List<Map<String, dynamic>> _buildDateSuggestions(String lang) {
    final Map<String, ({String label, int count})> stats = {};
    for (final item in _items) {
      if (item.date.isNotEmpty) {
        final dt = DateTime.tryParse(item.date);
        final keyStr = dt != null ? DateFormat('MMM d, yyyy').format(dt) : item.date;
        final labelStr = _formatWorkDate(item.date, lang);
        final prev = stats[keyStr];
        stats[keyStr] = (label: labelStr, count: (prev?.count ?? 0) + 1);
      }
    }
    final list = stats.entries
        .map((e) => {'date': e.key, 'label': e.value.label, 'count': e.value.count})
        .toList();
    list.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return list;
  }

  // Filtered Items matching lines 248-262
  List<WorkHistoryModel> get _filteredItems {
    final search = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim()).toLowerCase();
    final areaSearch = AppTranslations.normalizeAsciiDigits(_areaSearchCtrl.text.trim()).toLowerCase();
    final dateSearch = AppTranslations.normalizeAsciiDigits(_dateSearchCtrl.text.trim()).toLowerCase();

    return _items.where((item) {
      final matchesSearch = search.isEmpty ||
          item.title.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search) ||
          item.location.toLowerCase().contains(search);

      final matchesArea = areaSearch.isEmpty ||
          item.area.toLowerCase().contains(areaSearch);

      String formattedDate = item.date;
      try {
        formattedDate = DateFormat('MMM d, yyyy').format(DateTime.parse(item.date));
      } catch (_) {}

      final matchesDate = dateSearch.isEmpty ||
          formattedDate.toLowerCase().contains(dateSearch) ||
          item.date.toLowerCase().contains(dateSearch) ||
          AppTranslations.normalizeAsciiDigits(_formatWorkDate(item.date, 'mr')).toLowerCase().contains(dateSearch) ||
          AppTranslations.normalizeAsciiDigits(_formatWorkDate(item.date, 'hi')).toLowerCase().contains(dateSearch);

      return matchesSearch && matchesArea && matchesDate;
    }).toList();
  }

  List<WorkHistoryModel> get _visibleWorks =>
      _filteredItems.take(_displayedLimit).toList();

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedWorkIds.clear();
    });
  }

  void _handleCardClick(WorkHistoryModel item) {
    if (_selectionMode) {
      setState(() {
        if (_selectedWorkIds.contains(item.id)) {
          _selectedWorkIds.remove(item.id);
        } else {
          _selectedWorkIds.add(item.id);
        }
      });
      return;
    }

    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkDetailScreen(work: item),
      ),
    ).then((res) {
      if (res == true) _fetchData(showLoading: false);
    });
  }

  // Status Badge matching lines 268-277
  Widget _buildStatusBadge(String status, String lang) {
    switch (status) {
      case 'Completed':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                AppTranslations.getStatus('completed', lang),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
              ),
            ],
          ),
        );
      case 'InProgress':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_rounded, size: 12, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Text(
                AppTranslations.getStatus('in_progress', lang),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                AppTranslations.getStatus('planned', lang),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
              ),
            ],
          ),
        );
    }
  }

  // Create Work Modal matching lines 625-715
  void _openAddWorkModal() {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final benCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String status = 'Planned';

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                  // 1. FIXED HEADER
                  AppModalHeader(
                    icon: Icons.handyman_rounded,
                    title: AppTranslations.pick(lang, en: 'Add New Development Work', mr: 'नवीन विकास काम नोंदवा', hi: 'नया विकास कार्य दर्ज करें'),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Record project title, ward location and cost',
                      mr: 'कामाचा तपशील, स्थान व खर्च नोंदवा',
                      hi: 'कार्य का विवरण, स्थान और लागत दर्ज करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // 2. SCROLLABLE FORM BODY
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      children: [
                        // Project Title
                        AppFieldLabel(
                          label: AppTranslations.pick(lang, en: 'Project Title', mr: 'कामाचे नाव / प्रकल्प शीर्षक', hi: 'कार्य का नाम / परियोजना शीर्षक'),
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: inputDec(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Enter project name / tender description...',
                              mr: 'प्रकल्पाचे नाव / कामाचे वर्णन प्रविष्ट करा...',
                              hi: 'परियोजना का नाम / कार्य विवरण दर्ज करें...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        AppFieldLabel(
                          label: AppTranslations.pick(lang, en: 'Description', mr: 'कामाचा तपशील / वर्णन', hi: 'कार्य का विवरण'),
                          isRequired: false,
                          optionalHint: AppTranslations.pick(lang, en: 'Optional', mr: 'ऐच्छिक', hi: 'वैकल्पिक'),
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: inputDec(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Detailed scope of civil work...',
                              mr: 'कामाचा विस्तृत तपशील, आवश्यकता किंवा उद्दिष्ट...',
                              hi: 'विकास कार्य का विस्तृत विवरण...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Side-by-side: Location & Area
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Location / Landmark', mr: 'स्थान / लँडमार्क', hi: 'स्थान / लैंडमार्क'),
                                    isRequired: false,
                                  ),
                                  TextField(
                                    controller: locCtrl,
                                    decoration: inputDec(
                                      hint: AppTranslations.pick(lang, en: 'Landmark / Chowk...', mr: 'उदा. मुख्य चौक, मंदिर परिसर', hi: 'उदा. मुख्य चौक, मंदिर परिसर'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Area / Locality', mr: 'परिसर / प्रभाग', hi: 'क्षेत्र / वार्ड'),
                                    isRequired: false,
                                  ),
                                  TextField(
                                    controller: areaCtrl,
                                    decoration: inputDec(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. Sector 5, Prabhag 12...', mr: 'उदा. सेक्टर 5, प्रभाग 12', hi: 'उदा. सेक्टर 5, वार्ड 12'),
                                        lang,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Side-by-side: Completion Date & People Benefited
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Completion Date', mr: 'अंदाजित / पूर्ण तारीख', hi: 'पूर्ण होने की तिथि'),
                                    isRequired: false,
                                  ),
                                  TextField(
                                    controller: dateCtrl,
                                    decoration: inputDec(hint: 'YYYY-MM-DD'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'People Benefited', mr: 'लाभार्थी संख्या', hi: 'लाभान्वित नागरिक'),
                                    isRequired: false,
                                  ),
                                  TextField(
                                    controller: benCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: inputDec(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. 5000', mr: 'उदा. 5000', hi: 'उदा. 5000'),
                                        lang,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Total Amount Spent
                        AppFieldLabel(
                          label: AppTranslations.pick(lang, en: 'Total Amount Spent (₹)', mr: 'एकूण खर्च रक्कम (₹)', hi: 'कुल व्यय राशि (₹)'),
                          isRequired: false,
                        ),
                        TextField(
                          controller: amtCtrl,
                          keyboardType: TextInputType.number,
                          decoration: inputDec(
                            hint: AppTranslations.formatDigits(
                              AppTranslations.pick(lang, en: 'e.g. 1450000', mr: 'उदा. 1450000', hi: 'उदा. 1450000'),
                              lang,
                            ),
                            prefixText: '₹ ',
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Image Upload via Camera & Phone Storage
                        AppImagePickerField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Work Progress Photo (Camera & Phone Storage)',
                            mr: 'कामाचा फोटो (कॅमेरा व मोबाइल स्टोरेज)',
                            hi: 'कार्य प्रगति फ़ोटो (कैमरा और फ़ोन स्टोरेज)',
                          ),
                          isRequired: false,
                          isMarathi: lang == 'mr',
                          onFilesChanged: (_) {},
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons (Scrolls together with form)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                onPressed: () => Navigator.pop(sheetCtx),
                                child: Text(
                                  AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.save_rounded, size: 18),
                                label: Text(
                                  AppTranslations.pick(lang, en: 'Save Project', mr: 'काम जतन करा', hi: 'कार्य सहेजें'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                onPressed: () async {
                                  if (titleCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppTranslations.pick(lang, en: 'Please enter project title', mr: 'कृपया कामाचे नाव प्रविष्ट करा', hi: 'कृपया कार्य का नाम दर्ज करें'),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final newWork = WorkHistoryModel(
                                    id: 'work-${DateTime.now().millisecondsSinceEpoch}',
                                    source: 'Manual',
                                    title: titleCtrl.text.trim(),
                                    description: descCtrl.text.trim().isNotEmpty
                                        ? descCtrl.text.trim()
                                        : 'Development work initiated for Prabhag residents.',
                                    location: locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : 'Ward 12',
                                    area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                                    status: status,
                                    date: AppTranslations.normalizeAsciiDigits(dateCtrl.text.trim()),
                                    peopleBenefited: int.tryParse(AppTranslations.normalizeAsciiDigits(benCtrl.text.trim())),
                                    amount: double.tryParse(AppTranslations.normalizeAsciiDigits(amtCtrl.text.trim())),
                                    feedbackRating: 5.0,
                                    feedbackCount: 0,
                                  );

                                  final repo = ref.read(workHistoryRepoProvider);
                                  await repo.addWork(newWork);
                                  await _fetchData();

                                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'New work project added successfully!',
                                            mr: 'नवीन विकास काम यशस्वीरित्या जोडले गेले!',
                                            hi: 'नया विकास कार्य सफलतापूर्वक जोड़ा गया!',
                                          ),
                                        ),
                                        backgroundColor: const Color(0xFF16A34A),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredItems;
    final dateSuggestions = _buildDateSuggestions(lang);

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
        drawer: const NagarsevakAppDrawer(currentTabIndex: 0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: AppTranslations.pick(lang, en: 'Open Menu Drawer', mr: 'मेनू उघडा', hi: 'मेनू खोलें'),
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
                AppTranslations.getNavTitle('work_history', lang),
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
                    ? 'विकासकामे व प्रगती अहवाल'
                    : (lang == 'hi'
                        ? 'विकास कार्य और प्रगति रिपोर्ट'
                        : 'Civic development works & progress'),
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
          actions: const [],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchData,
          color: const Color(0xFF0284C7),
          child: ListView(
            padding: const EdgeInsets.only(top: 10),
            children: [
                    // Action Bar matching WorkHistory.tsx
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_selectionMode) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: AppPdfButton(
                                    label: lang == 'mr' ? 'अहवाल' : (lang == 'hi' ? 'रिपोर्ट' : 'Download Report'),
                                    style: AppPdfButtonStyle.tonal,
                                    onPressed: () {
                                      WorkReportGenerator.generateAndPrintWorkReport(
                                        works: filtered,
                                        areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                                        lang: lang,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _toggleSelectionMode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF334155),
                                      elevation: 0,
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                    ),
                                    icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF0284C7)),
                                    label: Text(
                                      lang == 'mr' ? 'अहवाल तयार करा' : (lang == 'hi' ? 'अहवाल बनाएं' : 'Generate Ahwal'),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // View Mode Toggle
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => setState(() => _viewMode = 'grid'),
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: _viewMode == 'grid' ? const Color(0xFF0284C7) : Colors.transparent,
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                                          ),
                                          child: Icon(
                                            Icons.grid_view_rounded,
                                            size: 17,
                                            color: _viewMode == 'grid' ? Colors.white : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => setState(() => _viewMode = 'report'),
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: _viewMode == 'report' ? const Color(0xFF0284C7) : Colors.transparent,
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                                          ),
                                          child: Icon(
                                            Icons.table_chart_outlined,
                                            size: 17,
                                            color: _viewMode == 'report' ? Colors.white : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Selection Banner Active matching lines 348-375
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0284C7),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      AppTranslations.formatDigits('${_selectedWorkIds.length}', lang),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang == 'mr'
                                              ? 'कामे निवडली (Ahwal)'
                                              : (lang == 'hi' ? 'कार्य चयनित (Ahwal)' : 'Works Selected'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          lang == 'mr'
                                              ? 'अहवालात समाविष्ट करण्यासाठी कामे निवडा'
                                              : (lang == 'hi'
                                                  ? 'अहवाल में शामिल करने के लिए कार्य चुनें'
                                                  : 'Select works to include in Ahwal report.'),
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _toggleSelectionMode,
                                    child: Text(
                                      lang == 'mr' ? 'रद्द' : (lang == 'hi' ? 'रद्द करें' : 'Cancel'),
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    ),
                                  ),
                                  AppPdfButton.primary(
                                    label: lang == 'mr' ? 'अहवाल पहा' : (lang == 'hi' ? 'पूर्वावलोकन' : 'Preview'),
                                    isCompact: true,
                                    onPressed: _selectedWorkIds.isEmpty
                                        ? null
                                        : () {
                                            final selected = _items.where((w) => _selectedWorkIds.contains(w.id)).toList();
                                            AhwalReportGenerator.generateAndPrintAhwal(
                                              selectedWorks: selected,
                                              lang: lang,
                                            );
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Filters Grid matching WorkHistory.tsx lines 377-451
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 1) Main Search Input
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() => _displayedLimit = 20),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'Search works, description or location...',
                                  mr: 'कामे, वर्णन किंवा ठिकाण शोधा...',
                                  hi: 'कार्य, विवरण या स्थान खोजें...',
                                ),
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                prefixIcon: const Icon(Icons.search, size: 19, color: Color(0xFF94A3B8)),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _displayedLimit = 20);
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 2) Area & Date Search with dropdowns
                          Row(
                            children: [
                              // Area Search
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: TextField(
                                    controller: _areaSearchCtrl,
                                    onTap: () => setState(() => _showAreaDropdown = true),
                                    onChanged: (_) => setState(() => _showAreaDropdown = true),
                                    style: const TextStyle(fontSize: 12.5),
                                    decoration: InputDecoration(
                                      hintText: AppTranslations.pick(lang, en: 'Search area...', mr: 'परिसर शोधा...', hi: 'क्षेत्र खोजें...'),
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                                      suffixIcon: _areaSearchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                                              onPressed: () {
                                                _areaSearchCtrl.clear();
                                                setState(() => _showAreaDropdown = false);
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Date Search
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: TextField(
                                    controller: _dateSearchCtrl,
                                    onTap: () => setState(() => _showDateDropdown = true),
                                    onChanged: (_) => setState(() => _showDateDropdown = true),
                                    style: const TextStyle(fontSize: 12.5),
                                    decoration: InputDecoration(
                                      hintText: AppTranslations.pick(lang, en: 'Filter date...', mr: 'तारीख फिल्टर...', hi: 'तिथि फ़िल्टर...'),
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 17, color: Color(0xFF94A3B8)),
                                      suffixIcon: _dateSearchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                                              onPressed: () {
                                                _dateSearchCtrl.clear();
                                                setState(() => _showDateDropdown = false);
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Area Dropdown Box if open
                          if (_showAreaDropdown && _areaSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children: _areaSuggestions
                                    .where((a) =>
                                        _areaSearchCtrl.text.isEmpty ||
                                        a['area'].toString().toLowerCase().contains(_areaSearchCtrl.text.toLowerCase()))
                                    .map((item) {
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: AppTranslatedText(
                                      item['area'] as String,
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        AppTranslations.formatDigits('${item['count']}', lang),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _areaSearchCtrl.text = item['area'] as String;
                                        _showAreaDropdown = false;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          // Date Dropdown Box if open
                          if (_showDateDropdown && dateSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children: dateSuggestions
                                    .where((d) {
                                      if (_dateSearchCtrl.text.isEmpty) return true;
                                      final q = AppTranslations.normalizeAsciiDigits(_dateSearchCtrl.text).toLowerCase();
                                      return d['date'].toString().toLowerCase().contains(q) ||
                                          AppTranslations.normalizeAsciiDigits(d['label'].toString()).toLowerCase().contains(q);
                                    })
                                    .map((item) {
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(item['label'] as String, style: const TextStyle(fontSize: 12.5)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        AppTranslations.formatDigits('${item['count']}', lang),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _dateSearchCtrl.text = item['date'] as String;
                                        _showDateDropdown = false;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Main Content: Report Table or Cards Grid
                    if (_loading) ...[
                      const AppShimmerList(count: 6),
                    ] else if (_viewMode == 'report') ...[
                      _buildReportTableView(lang, _visibleWorks),
                    ] else ...[
                      _buildCardsGridView(lang, _visibleWorks),
                    ],

                    if (!_loading && filtered.isNotEmpty)
                      AppLoadMoreFooter(
                        currentCount: _visibleWorks.length,
                        totalCount: filtered.length,
                        pageSize: 20,
                        onLoadMore: () {
                          setState(() => _displayedLimit += 20);
                        },
                        label: lang == 'mr' ? 'कामे' : (lang == 'hi' ? 'कार्य' : 'works'),
                        isMarathi: lang == 'mr',
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _openAddWorkModal,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            lang == 'mr' ? 'नवीन काम नोंदवा' : (lang == 'hi' ? 'नया कार्य जोड़ें' : 'Add Work'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Cards Grid View matching lines 542-621
  Widget _buildCardsGridView(String lang, List<WorkHistoryModel> items) {
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.engineering_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              lang == 'mr'
                  ? 'कोणतेही काम आढळले नाही'
                  : (lang == 'hi' ? 'कोई कार्य नहीं मिला' : 'No work projects found'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final item = items[idx];
          final isSelected = _selectedWorkIds.contains(item.id);

          return InkWell(
            onTap: () => _handleCardClick(item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.status == 'Completed'
                    ? const Color(0xFFF0FDF4)
                    : item.status == 'InProgress'
                        ? const Color(0xFFFEFCE8)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : item.status == 'Completed'
                          ? const Color(0xFFBBF7D0)
                          : item.status == 'InProgress'
                              ? const Color(0xFFFEF08A)
                              : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Status badge & Source badge with Checkbox in Selection Mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(item.status, lang),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.build_outlined, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  item.source == 'Manual'
                                      ? (lang == 'mr' ? 'मॅन्युअल' : (lang == 'hi' ? 'मैनुअल' : 'Manual'))
                                      : item.source,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                          if (_selectionMode) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title matching line 577
                  Row(
                    children: [
                      Expanded(
                        child: AppTranslatedText(item.title,
                          targetLanguage: lang,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description matching line 581
                  AppTranslatedText(item.description,
                    targetLanguage: lang,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),

                  // Feedback rating banner matching lines 584-589
                  if (item.feedbackCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppTranslations.formatDigits('${item.feedbackCount}', lang)} ${lang == 'mr' ? "नागरिक अभिप्राय" : (lang == 'hi' ? "नागरिक प्रतिक्रिया" : "Feedbacks")}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                          Text(
                            AppTranslations.formatDigits('${item.feedbackRating} ★', lang),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),

                  // Bottom info: Date, Location, Beneficiaries, Amount spent
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            _formatWorkDate(item.date, lang),
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      if (item.amount != null)
                        Text(
                          AppTranslations.formatDigits('₹ ${item.amount!.toStringAsFixed(0)}', lang),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                    ],
                  ),
                  if (item.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppTranslatedText(
                            '${item.location}${item.area.isNotEmpty ? " (${item.area})" : ""}',
                            targetLanguage: lang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Report Table View matching lines 460-540
  Widget _buildReportTableView(String lang, List<WorkHistoryModel> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header Bar with Download Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.formatDigits(
                    '${lang == "mr" ? "अहवाल तक्ता" : (lang == "hi" ? "रिपोर्ट तालिका" : "Report View")} (${items.length})',
                    lang,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                AppPdfButton.outlined(
                  label: lang == 'mr' ? 'अहवाल' : (lang == 'hi' ? 'रिपोर्ट' : 'Download Report'),
                  onPressed: () {
                    WorkReportGenerator.generateAndPrintWorkReport(
                      works: items,
                      areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                      lang: lang,
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Horizontally Scrollable Data Table matching exactly lines 464-472
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 20,
              columns: [
                DataColumn(label: Text(AppTranslations.getReportColumn('sr_no', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.getReportColumn('work_title', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.getReportColumn('location', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.getReportColumn('status', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(lang == 'mr' ? 'स्रोत' : (lang == 'hi' ? 'स्रोत' : 'Source'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.getReportColumn('date', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.getReportColumn('amount', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return DataRow(
                  onSelectChanged: (_) => _handleCardClick(item),
                  cells: [
                    DataCell(Text(AppTranslations.formatDigits('${idx + 1}', lang), style: const TextStyle(fontSize: 12))),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(item.title,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            AppTranslatedText(item.description,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: AppTranslatedText(
                          '${item.location}${item.area.isNotEmpty ? " (${item.area})" : ""}',
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(_buildStatusBadge(item.status, lang)),
                    DataCell(
                      Row(
                        children: [
                          const Icon(Icons.build_outlined, size: 12, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          item.source == 'Manual'
                              ? Text(
                                  AppTranslations.pick(lang, en: 'Manual', mr: 'मॅन्युअल', hi: 'मैनुअल'),
                                  style: const TextStyle(fontSize: 11.5),
                                )
                              : AppTranslatedText(
                                  item.source,
                                  targetLanguage: lang,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(_formatWorkDate(item.date, lang), style: const TextStyle(fontSize: 12)),
                    ),
                    DataCell(
                      Text(
                        item.amount != null
                            ? AppTranslations.formatDigits('₹ ${item.amount!.toStringAsFixed(0)}', lang)
                            : '--',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}