import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/improvement_model.dart';
import '../../../data/repositories/improvements_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'improvement_detail_screen.dart';
import 'improvement_report_generator.dart';
import '../../widgets/app_dropdown.dart';

/// PossibleImprovements Screen matching EXACTLY the web page:
/// Nagarsevak-Managment/src/pages/ward/PossibleImprovements.tsx
class PossibleImprovementsScreen extends ConsumerStatefulWidget {
  const PossibleImprovementsScreen({super.key});

  @override
  ConsumerState<PossibleImprovementsScreen> createState() => _PossibleImprovementsScreenState();
}

class _PossibleImprovementsScreenState extends ConsumerState<PossibleImprovementsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _areaSearchCtrl = TextEditingController();
  final TextEditingController _dateSearchCtrl = TextEditingController();

  String _viewMode = 'grid'; // 'grid' | 'report' matching PossibleImprovements.tsx line 41
  String _statusFilter = 'All'; // 'All' | 'Pending' | 'Planned' | 'In Progress' | 'Complete'

  bool _showAreaDropdown = false;
  bool _showDateDropdown = false;

  bool _loading = true;
  List<ImprovementModel> _improvements = [];
  int _displayedLimit = 20;

  List<ImprovementModel> get _visibleImprovements =>
      _filteredImprovements.take(_displayedLimit).toList();

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
    final repo = ref.read(improvementsRepoProvider);
    final items = await repo.getImprovements();
    if (mounted) {
      setState(() {
        _improvements = items;
        _loading = false;
        _displayedLimit = 20;
      });
    }
  }

  // Area suggestions with count matching PossibleImprovements.tsx lines 62-70
  List<Map<String, dynamic>> get _areaSuggestions {
    final Map<String, int> stats = {};
    for (final item in _improvements) {
      if (item.area.isNotEmpty) {
        stats[item.area] = (stats[item.area] ?? 0) + 1;
      }
    }
    final list = stats.entries.map((e) => {'area': e.key, 'count': e.value}).toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list;
  }

  // Date suggestions with count matching PossibleImprovements.tsx lines 73-82
  List<Map<String, dynamic>> get _dateSuggestions {
    final Map<String, int> stats = {};
    final Map<String, DateTime?> dtMap = {};
    for (final item in _improvements) {
      if (item.createdAt.isNotEmpty) {
        String dateStr;
        DateTime? parsed;
        try {
          parsed = DateTime.parse(item.createdAt);
          dateStr = AppTranslations.formatDate(parsed, 'en', pattern: 'MMM d, yyyy');
        } catch (_) {
          dateStr = item.createdAt;
        }
        stats[dateStr] = (stats[dateStr] ?? 0) + 1;
        dtMap[dateStr] = parsed;
      }
    }
    final list = stats.entries
        .map((e) => {'date': e.key, 'dt': dtMap[e.key], 'count': e.value})
        .toList();
    list.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return list;
  }

  // Filtered improvements matching lines 84-99
  List<ImprovementModel> get _filteredImprovements {
    final search = _searchCtrl.text.trim().toLowerCase();
    final areaSearch = _areaSearchCtrl.text.trim().toLowerCase();
    final normArea = AppTranslations.normalizeAsciiDigits(areaSearch);
    final dateSearch = _dateSearchCtrl.text.trim().toLowerCase();
    final normDate = AppTranslations.normalizeAsciiDigits(dateSearch);

    return _improvements.where((item) {
      final matchesSearch = search.isEmpty ||
          item.title.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search) ||
          item.location.toLowerCase().contains(search);

      final areaLower = item.area.toLowerCase();
      final matchesArea = areaSearch.isEmpty ||
          areaLower.contains(areaSearch) ||
          AppTranslations.normalizeAsciiDigits(areaLower).contains(normArea);

      String formattedDateEn = item.createdAt;
      String formattedDateMr = item.createdAt;
      String formattedDateHi = item.createdAt;
      try {
        final dt = DateTime.parse(item.createdAt);
        formattedDateEn = AppTranslations.formatDate(dt, 'en', pattern: 'MMM d, yyyy');
        formattedDateMr = AppTranslations.normalizeAsciiDigits(
          AppTranslations.formatDate(dt, 'mr', pattern: 'MMM d, yyyy'),
        );
        formattedDateHi = AppTranslations.normalizeAsciiDigits(
          AppTranslations.formatDate(dt, 'hi', pattern: 'MMM d, yyyy'),
        );
      } catch (_) {}

      final matchesDate = dateSearch.isEmpty ||
          formattedDateEn.toLowerCase().contains(normDate) ||
          formattedDateMr.toLowerCase().contains(normDate) ||
          formattedDateHi.toLowerCase().contains(normDate) ||
          item.createdAt.toLowerCase().contains(dateSearch);

      final matchesStatus = _statusFilter == 'All' ||
          item.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesArea && matchesDate && matchesStatus;
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'All') return _improvements.length;
    return _improvements.where((i) => i.status.toLowerCase() == status.toLowerCase()).length;
  }

  Future<void> _handleVote(ImprovementModel imp) async {
    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(improvementsRepoProvider);
    final newVotes = await repo.voteImprovement(imp.id);
    if (mounted) {
      setState(() {
        final idx = _improvements.indexWhere((i) => i.id == imp.id);
        if (idx != -1) {
          _improvements[idx] = _improvements[idx].copyWith(votes: newVotes);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Vote registered successfully!',
              mr: 'तुमचे मत यशस्वीरित्या नोंदवले गेले!',
              hi: 'आपका मत सफलतापूर्वक दर्ज किया गया!',
            ),
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status, String lang) {
    Color bg;
    Color text;
    Color border;
    String label;

    switch (status) {
      case 'Complete':
        bg = const Color(0xFFF0FDF4);
        text = const Color(0xFF15803D);
        border = const Color(0xFFBBF7D0);
        label = AppTranslations.pick(lang, en: 'Complete', mr: 'पूर्ण', hi: 'पूर्ण');
        break;
      case 'In Progress':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        border = const Color(0xFFBFDBFE);
        label = AppTranslations.pick(lang, en: 'In Progress', mr: 'सुरू', hi: 'प्रगति पर');
        break;
      case 'Planned':
        bg = const Color(0xFFFAF5FF);
        text = const Color(0xFF7E22CE);
        border = const Color(0xFFE9D5FF);
        label = AppTranslations.pick(lang, en: 'Planned', mr: 'नियोजित', hi: 'नियोजित');
        break;
      default:
        bg = const Color(0xFFFFF7ED);
        text = const Color(0xFFC2410C);
        border = const Color(0xFFFFEDD5);
        label = AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  // Add Improvement Modal matching lines 524-642
  void _openAddModal() {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final targetDt = DateTime.now().add(const Duration(days: 90));
    final dateCtrl = TextEditingController(
      text: '${targetDt.year}-${targetDt.month.toString().padLeft(2, '0')}-${targetDt.day.toString().padLeft(2, '0')}',
    );
    final benCtrl = TextEditingController();
    String status = 'Pending';

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
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                children: [
                  // 1. FIXED HEADER
                  AppModalHeader(
                    icon: Icons.lightbulb_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Propose Ward Improvement',
                      mr: 'संभाव्य प्रभाग सुधारणा प्रस्ताव',
                      hi: 'संभावित वार्ड सुधार प्रस्ताव',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Submit infrastructure or civic improvement proposals',
                      mr: 'प्रभागातील नवीन कामे व सुधारणांचे प्रस्ताव नोंदवा',
                      hi: 'वार्ड में नए कार्य व सुधार प्रस्ताव दर्ज करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // 2. SCROLLABLE FORM BODY & SUBMIT BUTTON
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        // 1. Title (Full Width - matching PossibleImprovements.tsx lines 535-545)
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Title / Proposed Work',
                            mr: 'सुधारणा कामाचे नाव',
                            hi: 'सुधार कार्य का नाम',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: inputDec(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'e.g. Pedestrian skywalk, Open gym...',
                              mr: 'उदा. पादचारी पूल, ओपन जिम...',
                              hi: 'उदा. पैदल पुल, ओपन जिम...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. Description (Full Width - matching PossibleImprovements.tsx lines 547-568)
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Detailed Description',
                            mr: 'तपशीलवार माहिती व आवश्यकता',
                            hi: 'विस्तृत विवरण व आवश्यकता',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: inputDec(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Why is this improvement needed? How will it help?',
                              mr: 'ही सुधारणा का आवश्यक आहे? नागरिकांना काय फायदा होईल?',
                              hi: 'यह सुधार क्यों आवश्यक है? नागरिकों को क्या लाभ होगा?',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. Location & Area side-by-side (matching PossibleImprovements.tsx lines 570-591)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Specific Spot / Location',
                                      mr: 'निश्चित ठिकाण / चौक',
                                      hi: 'निश्चित स्थान / चौक',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: locCtrl,
                                    decoration: inputDec(
                                      hint: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. Chowk, Crossing...',
                                        mr: 'उदा. चौक, रस्ता क्रॉसिंग...',
                                        hi: 'उदा. चौक, सड़क क्रॉसिंग...',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Prabhag Area',
                                      mr: 'प्रभाग परिसर',
                                      hi: 'वार्ड क्षेत्र',
                                    ),
                                  ),
                                  TextField(
                                    controller: areaCtrl,
                                    decoration: inputDec(
                                      hint: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. Sector 5, Shivaji Nagar...',
                                        mr: 'उदा. सेक्टर ५, शिवाजी नगर...',
                                        hi: 'उदा. सेक्टर ५, शिवाजी नगर...',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 4. Expected Target Date & Beneficiaries side-by-side (matching PossibleImprovements.tsx lines 593-611)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Expected Target Date',
                                      mr: 'अपेक्षित पूर्णता दिनांक',
                                      hi: 'अपेक्षित लक्ष्य तिथि',
                                    ),
                                  ),
                                  TextField(
                                    controller: dateCtrl,
                                    decoration: inputDec(hint: 'YYYY-MM-DD'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Estimated Beneficiaries',
                                      mr: 'अंदाजे लाभार्थी नागरिक',
                                      hi: 'अनुमानित लाभार्थी नागरिक',
                                    ),
                                  ),
                                  TextField(
                                    controller: benCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: inputDec(
                                      hint: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. 15000',
                                        mr: 'उदा. १५०००',
                                        hi: 'उदा. १५०००',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 5. Status (Full Width Dropdown - matching PossibleImprovements.tsx lines 613-623)
                        AppDropdownFormField<String>(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Status',
                                  mr: 'सद्यस्थिती',
                                  hi: 'वर्तमान स्थिति',
                                ),
                                value: status,
                          items: [
                            DropdownMenuItem(value: 'Pending', child: Text(AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित'))),
                            DropdownMenuItem(value: 'Planned', child: Text(AppTranslations.pick(lang, en: 'Planned', mr: 'नियोजित', hi: 'नियोजित'))),
                            DropdownMenuItem(value: 'In Progress', child: Text(AppTranslations.pick(lang, en: 'In Progress', mr: 'सुरू', hi: 'प्रगति पर'))),
                            DropdownMenuItem(value: 'Complete', child: Text(AppTranslations.pick(lang, en: 'Complete', mr: 'पूर्ण', hi: 'पूर्ण'))),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => status = val);
                          },
                        ),
                        const SizedBox(height: 22),

                        // Scrollable Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Please enter improvement title',
                                        mr: 'कृपया सुधारणा कामाचे नाव प्रविष्ट करा',
                                        hi: 'कृपया सुधार कार्य का नाम दर्ज करें',
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final newImp = ImprovementModel(
                                id: 'imp-${DateTime.now().millisecondsSinceEpoch}',
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim().isNotEmpty
                                    ? descCtrl.text.trim()
                                    : 'Proposed infrastructural improvement for Prabhag 12.',
                                location: locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : 'Ward 12',
                                area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                                status: status,
                                votes: 1,
                                completionDate: dateCtrl.text.trim(),
                                peopleBenefited: int.tryParse(benCtrl.text.trim()),
                                createdAt: DateTime.now().toIso8601String(),
                              );

                              final repo = ref.read(improvementsRepoProvider);
                              await repo.addImprovement(newImp);
                              await _fetchData();

                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Improvement proposed successfully!',
                                        mr: 'सुधारणा प्रस्ताव यशस्वीरित्या सादर केला!',
                                        hi: 'सुधार प्रस्ताव सफलतापूर्वक प्रस्तुत किया गया!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Submit Proposal',
                                mr: 'प्रस्ताव सादर करा',
                                hi: 'प्रस्ताव प्रस्तुत करें',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
    final filtered = _filteredImprovements;

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
                AppTranslations.pick(
                  lang,
                  en: 'Possible Improvements',
                  mr: 'संभाव्य सुधारणा',
                  hi: 'संभावित सुधार',
                ),
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
                AppTranslations.pick(
                  lang,
                  en: 'Citizen proposals, ideas & future project plans',
                  mr: 'नागरिकांच्या सूचना व पायाभूत सुविधांचे प्रस्ताव',
                  hi: 'नागरिकों के सुझाव व बुनियादी ढांचे के प्रस्ताव',
                ),
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
        body: _loading
            ? const AppShimmerList(count: 6)
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: const EdgeInsets.only(top: 10),
                  children: [
                    // Filters Card matching PossibleImprovements.tsx lines 282-383
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
                                  en: 'Search improvements, description or location...',
                                  mr: 'सुधारणा, वर्णन किंवा ठिकाण शोधा...',
                                  hi: 'सुधार, विवरण या स्थान खोजें...',
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
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'Search area...',
                                        mr: 'परिसर शोधा...',
                                        hi: 'क्षेत्र खोजें...',
                                      ),
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                                      suffixIcon: _areaSearchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                                              onPressed: () {
                                                _areaSearchCtrl.clear();
                                                setState(() {
                                                  _showAreaDropdown = false;
                                                  _displayedLimit = 20;
                                                });
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
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'Filter date...',
                                        mr: 'तारीख फिल्टर...',
                                        hi: 'तारीख फ़िल्टर...',
                                      ),
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 17, color: Color(0xFF94A3B8)),
                                      suffixIcon: _dateSearchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                                              onPressed: () {
                                                _dateSearchCtrl.clear();
                                                setState(() {
                                                  _showDateDropdown = false;
                                                  _displayedLimit = 20;
                                                });
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
                                    .where((a) {
                                      if (_areaSearchCtrl.text.isEmpty) return true;
                                      final q = _areaSearchCtrl.text.toLowerCase();
                                      final normQ = AppTranslations.normalizeAsciiDigits(q);
                                      final area = a['area'].toString().toLowerCase();
                                      return area.contains(q) ||
                                          AppTranslations.normalizeAsciiDigits(area)
                                              .contains(normQ);
                                    })
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
                                        _displayedLimit = 20;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          // Date Dropdown Box if open
                          if (_showDateDropdown && _dateSuggestions.isNotEmpty) ...[
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
                                children: _dateSuggestions
                                    .where((d) {
                                      if (_dateSearchCtrl.text.isEmpty) return true;
                                      final normQ = AppTranslations.normalizeAsciiDigits(
                                        _dateSearchCtrl.text,
                                      ).toLowerCase();
                                      final rawDate = d['date'].toString().toLowerCase();
                                      final dt = d['dt'] as DateTime?;
                                      final locDate = dt != null
                                          ? AppTranslations.normalizeAsciiDigits(
                                              AppTranslations.formatDate(dt, lang, pattern: 'MMM d, yyyy'),
                                            ).toLowerCase()
                                          : rawDate;
                                      return rawDate.contains(normQ) || locDate.contains(normQ);
                                    })
                                    .map((item) {
                                  final dt = item['dt'] as DateTime?;
                                  final displayDate = dt != null
                                      ? AppTranslations.formatDate(dt, lang, pattern: 'MMM d, yyyy')
                                      : AppTranslations.formatDigits(item['date'] as String, lang);
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(displayDate, style: const TextStyle(fontSize: 12.5)),
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
                                        _dateSearchCtrl.text = displayDate;
                                        _showDateDropdown = false;
                                        _displayedLimit = 20;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // 3) Horizontal Status Pills with counts matching lines 358-382
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatusPill('All', AppTranslations.pick(lang, en: 'All', mr: 'सर्व', hi: 'सभी'), lang),
                                _buildStatusPill('Pending', AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित'), lang),
                                _buildStatusPill('Planned', AppTranslations.pick(lang, en: 'Planned', mr: 'नियोजित', hi: 'नियोजित'), lang),
                                _buildStatusPill('In Progress', AppTranslations.pick(lang, en: 'In Progress', mr: 'सुरू', hi: 'प्रगति पर'), lang),
                                _buildStatusPill('Complete', AppTranslations.pick(lang, en: 'Complete', mr: 'पूर्ण', hi: 'पूर्ण'), lang),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Secondary Tools: Count, View Mode & PDF Export
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Text(
                              '${AppTranslations.pick(lang, en: "Total Items", mr: "उपलब्ध सुधारणा", hi: "कुल प्रस्ताव")}: ${AppTranslations.formatDigits('${filtered.length}', lang)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              // View Mode Toggle (Grid / Report Table)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => setState(() => _viewMode = 'grid'),
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _viewMode == 'grid' ? const Color(0xFF0284C7) : Colors.transparent,
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
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
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _viewMode == 'report' ? const Color(0xFF0284C7) : Colors.transparent,
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
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
                              const SizedBox(width: 8),
                              // PDF Export Button
                              AppPdfButton.outlined(
                                label: AppTranslations.getDownloadReport(lang),
                                tooltip: AppTranslations.getDownloadReport(lang),
                                onPressed: () {
                                  ImprovementReportGenerator.generateAndPrintImprovementReport(
                                    improvements: filtered,
                                    areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                                    statusFilter: _statusFilter,
                                    lang: lang,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Content: Report Table or Cards Grid
                    if (_viewMode == 'report') ...[
                      _buildReportTableView(lang, _visibleImprovements),
                    ] else ...[
                      _buildCardsGridView(lang, _visibleImprovements),
                    ],
                    AppLoadMoreFooter(
                      currentCount: _visibleImprovements.length,
                      totalCount: filtered.length,
                      pageSize: 20,
                      onLoadMore: () => setState(() => _displayedLimit += 20),
                      label: AppTranslations.pick(lang, en: 'improvements', mr: 'सुधारणा', hi: 'सुधार'),
                      isMarathi: lang == 'mr',
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _openAddModal,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            AppTranslations.pick(
              lang,
              en: 'Propose Improvement',
              mr: 'नवीन प्रस्ताव',
              hi: 'सुधार प्रस्तावित करें',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, String label, String lang) {
    final isSelected = _statusFilter.toLowerCase() == status.toLowerCase();
    final count = _countForStatus(status);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() {
          _statusFilter = status;
          _displayedLimit = 20;
        }),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppTranslations.formatDigits('$count', lang),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cards Grid View matching PossibleImprovements.tsx lines 445-521
  Widget _buildCardsGridView(String lang, List<ImprovementModel> items) {
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
            const Icon(Icons.lightbulb_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No proposals found for this filter',
                mr: 'कोणताही प्रस्ताव आढळला नाही',
                hi: 'इस फ़िल्टर के लिए कोई प्रस्ताव नहीं मिला',
              ),
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final item = items[idx];
          final parsedDate = item.createdAt.isNotEmpty ? DateTime.tryParse(item.createdAt) : null;
          final dateDisplay = parsedDate != null
              ? AppTranslations.formatDate(parsedDate, lang, pattern: 'dd MMM yyyy')
              : AppTranslations.formatDigits(item.createdAt.split('T').first, lang);

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImprovementDetailScreen(improvement: item),
                ),
              ).then((res) { if (res == true) _fetchData(showLoading: false); });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Stack(
                children: [
                  // Subtle Lightbulb Background Watermark matching line 464
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Opacity(
                      opacity: 0.06,
                      child: const Icon(
                        Icons.lightbulb,
                        size: 90,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Status badge & Date matching lines 468-482
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(item.status, lang),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                dateDisplay,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title matching line 485
                      AppTranslatedText(
                        item.title,
                        targetLanguage: lang,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Description matching line 486
                      AppTranslatedText(
                        item.description,
                        targetLanguage: lang,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 10),

                      // Location & Beneficiaries matching lines 489-502
                      if (item.location.isNotEmpty) ...[
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
                      if (item.peopleBenefited != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 13, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              '${AppTranslations.formatDigits('${item.peopleBenefited}', lang)} ${AppTranslations.pick(lang, en: "People Benefited", mr: "नागरिकांना लाभ", hi: "लाभार्थी नागरिक")}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),

                      // Bottom Vote Row matching lines 504-516
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppTranslations.formatDigits('${item.votes}', lang),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'VOTES',
                                  mr: 'नागरिक मते',
                                  hi: 'नागरिक मत',
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),

                          // Vote button
                          InkWell(
                            onTap: () => _handleVote(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 5),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Vote',
                                      mr: 'मत द्या',
                                      hi: 'मत दें',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Report Table View matching PossibleImprovements.tsx lines 385-443
  Widget _buildReportTableView(String lang, List<ImprovementModel> items) {
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
                  '${AppTranslations.pick(lang, en: "Report View", mr: "अहवाल तक्ता", hi: "रिपोर्ट तालिका")} (${AppTranslations.formatDigits('${items.length}', lang)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                AppPdfButton.outlined(
                  label: AppTranslations.getDownloadReport(lang),
                  tooltip: AppTranslations.getDownloadReport(lang),
                  onPressed: () {
                    ImprovementReportGenerator.generateAndPrintImprovementReport(
                      improvements: items,
                      areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                      statusFilter: _statusFilter,
                      lang: lang,
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Horizontally Scrollable Data Table matching exactly lines 390-396
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 20,
              columns: [
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Sr No', mr: 'क्र.', hi: 'क्र.'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Improvement Title', mr: 'प्रस्ताव शीर्षक', hi: 'प्रस्ताव शीर्षक'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Location / Area', mr: 'ठिकाण व परिसर', hi: 'स्थान व क्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Votes', mr: 'मते', hi: 'मत'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Date', mr: 'तारीख', hi: 'तारीख'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final parsedDate = item.createdAt.isNotEmpty ? DateTime.tryParse(item.createdAt) : null;
                final dateDisplay = parsedDate != null
                    ? AppTranslations.formatDate(parsedDate, lang, pattern: 'dd MMM yyyy')
                    : AppTranslations.formatDigits(item.createdAt.split('T').first, lang);
                return DataRow(
                  onSelectChanged: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImprovementDetailScreen(improvement: item),
                      ),
                    ).then((res) { if (res == true) _fetchData(showLoading: false); });
                  },
                  cells: [
                    DataCell(Text(AppTranslations.formatDigits('${idx + 1}', lang), style: const TextStyle(fontSize: 12))),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              item.title,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            AppTranslatedText(
                              item.description,
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
                      Text(
                        AppTranslations.formatDigits('${item.votes}', lang),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ),
                    DataCell(
                      Text(
                        dateDisplay,
                        style: const TextStyle(fontSize: 12),
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
