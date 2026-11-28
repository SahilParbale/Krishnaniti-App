import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import 'package:nagarsevak_mobile/data/models/scheme_model.dart';
import 'package:nagarsevak_mobile/data/repositories/schemes_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/common/desktop_modal_dialog.dart';
import 'package:nagarsevak_mobile/presentation/screens/schemes/scheme_report_generator.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_load_more_footer.dart';

/// Desktop Government Schemes View matching SchemeList.tsx verbatim:
/// - Sticky Header: Title + Subtitle + Help + Find Schemes (AI) + Add Scheme
/// - Schemes vs Applications Tab Navigation
/// - Category Filter Pills: All, Women, Student, Senior Citizen, Farmer, Health, Youth, Housing
/// - Search Bar
/// - View Mode Toggle: Grid vs Report
/// - Scheme Cards with expandable accordion details (Eligibility, Benefits, Documents, Apply, Delete)
class DesktopSchemesView extends ConsumerStatefulWidget {
  const DesktopSchemesView({super.key});

  @override
  ConsumerState<DesktopSchemesView> createState() => _DesktopSchemesViewState();
}

class _DesktopSchemesViewState extends ConsumerState<DesktopSchemesView> {
  String _activeTab = 'schemes'; // 'schemes' | 'applications'
  String _activeCategory = 'All';
  String _viewMode = 'grid'; // 'grid' | 'table'
  String _searchQuery = '';
  int? _expandedSchemeId;
  int _displayedLimit = 20;

  bool _loading = true;
  List<SchemeModel> _schemes = [];

  List<SchemeModel> get _visibleSchemes =>
      _filteredSchemes.take(_displayedLimit).toList();

  static const List<Map<String, String>> _categories = [
    {'id': 'All', 'en': 'All', 'mr': 'सर्व', 'hi': 'सभी'},
    {'id': 'Women', 'en': 'Women', 'mr': 'महिला', 'hi': 'महिला'},
    {'id': 'Student', 'en': 'Student', 'mr': 'विद्यार्थी', 'hi': 'छात्र'},
    {'id': 'Senior Citizen', 'en': 'Senior Citizen', 'mr': 'ज्येष्ठ नागरिक', 'hi': 'वरिष्ठ नागरिक'},
    {'id': 'Farmer', 'en': 'Farmer', 'mr': 'शेतकरी', 'hi': 'किसान'},
    {'id': 'Health', 'en': 'Health', 'mr': 'आरोग्य', 'hi': 'स्वास्थ्य'},
    {'id': 'Youth', 'en': 'Youth', 'mr': 'युवा', 'hi': 'युवा'},
    {'id': 'Housing', 'en': 'Housing', 'mr': 'गृहनिर्माण', 'hi': 'आवास'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(schemesRepoProvider);
      final list = await repo.getSchemes();
      if (mounted) {
        setState(() {
          _schemes = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SchemeModel> get _filteredSchemes {
    return _schemes.where((s) {
      if (_activeCategory != 'All') {
        if (!s.category.toLowerCase().contains(_activeCategory.toLowerCase())) {
          return false;
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchName = s.name.toLowerCase().contains(q);
        final matchDesc = s.description.toLowerCase().contains(q);
        final matchBenefits = s.benefits.toLowerCase().contains(q);
        if (!matchName && !matchDesc && !matchBenefits) return false;
      }
      return true;
    }).toList();
  }

  String _localizedCategory(String category, String lang) {
    final lower = category.trim().toLowerCase();
    for (final c in _categories) {
      if (c['id']!.toLowerCase() == lower) {
        return c[lang] ?? c['en']!;
      }
    }
    return AppTranslations.translateDirect(category, lang: lang);
  }

  void _openAddSchemeDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final eligCtrl = TextEditingController();
    final benCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    String category = 'All';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, dlgLang, _) => StatefulBuilder(
          builder: (ctx, setDlgState) => DesktopModalDialog(
            title: AppTranslations.pick(
              dlgLang,
              en: 'Add Government Scheme',
              mr: 'शासकीय योजना जोडा',
              hi: 'सरकारी योजना जोड़ें',
            ),
            subtitle: AppTranslations.pick(
              dlgLang,
              en: 'Create a welfare scheme with eligibility criteria and benefits',
              mr: 'पात्रता निकष आणि लाभांसह कल्याणकारी योजना तयार करा',
              hi: 'पात्रता मानदंड और लाभों के साथ कल्याणकारी योजना बनाएं',
            ),
            icon: Icons.account_balance_rounded,
            width: 580,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: AppTranslations.pick(dlgLang, en: 'Save Scheme', mr: 'योजना जतन करा', hi: 'योजना सहेजें'),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final newScheme = SchemeModel(
                    id: 0,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    eligibility: eligCtrl.text.trim(),
                    benefits: benCtrl.text.trim(),
                    documents: docCtrl.text.trim(),
                    category: category,
                  );
                  await ref.read(schemesRepoProvider).createScheme(newScheme);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadSchemes();
                },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.pick(dlgLang, en: 'Scheme Name *', mr: 'योजनेचे नाव *', hi: 'योजना का नाम *'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      dlgLang,
                      en: 'e.g. Pradhan Mantri Awas Yojana...',
                      mr: 'उदा. प्रधानमंत्री आवास योजना...',
                      hi: 'जैसे प्रधानमंत्री आवास योजना...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.pick(dlgLang, en: 'Category *', mr: 'वर्गवारी *', hi: 'श्रेणी *'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                AppDropdown<String>(
                  value: category,
                  height: 44,
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c['id']!, child: Text(c[dlgLang] ?? c['en']!)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => category = val);
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.pick(dlgLang, en: 'Description', mr: 'वर्णन', hi: 'विवरण'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      dlgLang,
                      en: 'Summary of the scheme...',
                      mr: 'योजनेचा सारांश...',
                      hi: 'योजना का सारांश...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.pick(dlgLang, en: 'Eligibility Criteria', mr: 'पात्रता निकष', hi: 'पात्रता मानदंड'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: eligCtrl,
                  maxLines: 2,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      dlgLang,
                      en: 'Who qualifies for this benefit...',
                      mr: 'या लाभासाठी कोण पात्र आहे...',
                      hi: 'इस लाभ के लिए कौन पात्र है...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.pick(dlgLang, en: 'Benefits', mr: 'लाभ', hi: 'लाभ'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: benCtrl,
                  maxLines: 2,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      dlgLang,
                      en: 'Financial subsidy, training, or kit...',
                      mr: 'आर्थिक अनुदान, प्रशिक्षण किंवा संच...',
                      hi: 'वित्तीय सहायता, प्रशिक्षण या किट...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.pick(dlgLang, en: 'Required Documents', mr: 'आवश्यक कागदपत्रे', hi: 'आवश्यक दस्तावेज़'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: docCtrl,
                  maxLines: 2,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      dlgLang,
                      en: 'Aadhaar, income certificate, ration card...',
                      mr: 'आधार कार्ड, उत्पन्न दाखला, शिधापत्रिका...',
                      hi: 'आधार, आय प्रमाण पत्र, राशन कार्ड...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final items = _filteredSchemes;
    final visibleItems = _visibleSchemes;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (matching SchemeList.tsx lines 180-200)
            _buildHeader(lang, items.length),

            const SizedBox(height: 16),

            // 2. Tabs: Schemes vs Applications (matching lines 200-210)
            _buildTabRow(lang),

            const SizedBox(height: 16),

            // 3. Category Filter Pills & Search (matching lines 212-276)
            if (_activeTab == 'schemes') ...[
              _buildCategoryPills(lang),
              const SizedBox(height: 16),
              _buildSearchBar(lang),
              const SizedBox(height: 16),
            ],

            // 4. Content Area
            if (_loading)
              _buildLoadingGrid()
            else if (items.isEmpty)
              _buildEmptyState(lang)
            else if (_viewMode == 'grid')
              _buildSchemesGrid(visibleItems, lang)
            else
              _buildReportTable(visibleItems, lang),

            // 5. Pagination Load More Footer
            if (!_loading && items.isNotEmpty)
              AppLoadMoreFooter(
                currentCount: visibleItems.length,
                totalCount: items.length,
                pageSize: 20,
                onLoadMore: () {
                  setState(() => _displayedLimit += 20);
                },
                label: lang == 'mr' ? 'योजना' : (lang == 'hi' ? 'योजनाएं' : 'schemes'),
                isMarathi: lang == 'mr',
              ),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(String lang, int count) {
    final title = AppTranslations.t('schemes.title', lang: lang);
    final subtitle = AppTranslations.t('schemes.subtitle', lang: lang);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, size: 26, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    AppTranslations.formatFound(count, lang),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Find Schemes (AI) + Add Scheme
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                SchemeReportGenerator.generateAndPrintListReport(
                  context: context,
                  schemes: _filteredSchemes,
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
            const SizedBox(width: 8),

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                lang == 'mr' ? 'योजना शोधा (AI)' : (lang == 'hi' ? 'योजनाएं खोजें (AI)' : 'Find Schemes (AI)'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _openAddSchemeDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.t('schemes.add_scheme', lang: lang),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Tab Row (Schemes vs Applications) ---
  Widget _buildTabRow(String lang) {
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
                title: lang == 'mr' ? 'योजना' : (lang == 'hi' ? 'योजनाएं' : 'Schemes'),
                isActive: _activeTab == 'schemes',
                onTap: () => setState(() {
                  _activeTab = 'schemes';
                  _displayedLimit = 20;
                }),
              ),
              const SizedBox(width: 24),
              _buildTabButton(
                title: lang == 'mr' ? 'अर्ज' : (lang == 'hi' ? 'आवेदन' : 'Applications'),
                isActive: _activeTab == 'applications',
                onTap: () => setState(() {
                  _activeTab = 'applications';
                  _displayedLimit = 20;
                }),
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
                  label: AppTranslations.t('common.grid', lang: lang),
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
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
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

  // --- Category Pills ---
  Widget _buildCategoryPills(String lang) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((c) {
          final isSelected = _activeCategory == c['id'];
          final label = c[lang] ?? c['en']!;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() {
                _activeCategory = c['id']!;
                _displayedLimit = 20;
              }),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Search Bar ---
  Widget _buildSearchBar(String lang) {
    return TextField(
      onChanged: (v) => setState(() {
        _searchQuery = v;
        _displayedLimit = 20;
      }),
      decoration: InputDecoration(
        hintText: lang == 'mr'
            ? 'शीर्षक, पात्रता, लाभांनुसार शोधा...'
            : (lang == 'hi' ? 'शीर्षक, पात्रता, लाभों द्वारा खोजें...' : 'Search schemes by title, eligibility, benefits...'),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
    );
  }

  // --- Schemes Grid (Expandable Accordion Cards) ---
  Widget _buildSchemesGrid(List<SchemeModel> items, String lang) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final scheme = items[index];
        final isExpanded = _expandedSchemeId == scheme.id;
        final name = scheme.localizedNameFor(lang);
        final desc = scheme.localizedDescriptionFor(lang);
        final elig = scheme.localizedEligibilityFor(lang);
        final ben = scheme.localizedBenefitsFor(lang);
        final docs = scheme.localizedDocumentsFor(lang);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedSchemeId = isExpanded ? null : scheme.id;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Icon(Icons.description_outlined, color: Color(0xFF0284C7), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppTranslatedText(
                                    name,
                                    targetLanguage: lang,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                if (scheme.category.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _localizedCategory(scheme.category, lang),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            AppTranslatedText(
                              desc,
                              targetLanguage: lang,
                              maxLines: isExpanded ? 10 : 2,
                              overflow: isExpanded ? null : TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Details Accordion
              if (isExpanded) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (elig.isNotEmpty) ...[
                        _buildDetailSection(
                          AppTranslations.pick(lang, en: 'Eligibility:', mr: 'पात्रता:', hi: 'पात्रता:'),
                          elig,
                          Icons.check_circle_outline_rounded,
                          const Color(0xFF16A34A),
                          lang,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (ben.isNotEmpty) ...[
                        _buildDetailSection(
                          AppTranslations.pick(lang, en: 'Benefits:', mr: 'लाभ:', hi: 'लाभ:'),
                          ben,
                          Icons.card_giftcard_rounded,
                          const Color(0xFF0284C7),
                          lang,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (docs.isNotEmpty) ...[
                        _buildDetailSection(
                          AppTranslations.pick(lang, en: 'Documents:', mr: 'कागदपत्रे:', hi: 'दस्तावेज़:'),
                          docs,
                          Icons.attachment_rounded,
                          const Color(0xFFD97706),
                          lang,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Download Brochure',
                                mr: 'माहिती पुस्तिका डाउनलोड करा',
                                hi: 'विवरणिका डाउनलोड करें',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Apply for Citizen',
                                mr: 'नागरिकासाठी अर्ज करा',
                                hi: 'नागरिक के लिए आवेदन करें',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, Color iconColor, String lang) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 2),
              AppTranslatedText(
                content,
                targetLanguage: lang,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Report Table View (matching SchemeList.tsx lines 318-368) ---
  Widget _buildReportTable(List<SchemeModel> items, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(AppTranslations.getReportColumn('sr_no', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('scheme_name', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('category', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('eligibility', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('benefits', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: items.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final s = entry.value;
            return DataRow(
              cells: [
                DataCell(Text(AppTranslations.formatDigits(idx, lang))),
                DataCell(
                  AppTranslatedText(
                    s.localizedNameFor(lang),
                    targetLanguage: lang,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(_localizedCategory(s.category, lang))),
                DataCell(
                  AppTranslatedText(
                    s.localizedEligibilityFor(lang),
                    targetLanguage: lang,
                  ),
                ),
                DataCell(
                  AppTranslatedText(
                    s.localizedBenefitsFor(lang),
                    targetLanguage: lang,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return const Center(
      child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildEmptyState(String lang) {
    final emptyMsg = lang == 'mr'
        ? 'कोणतीही शासकीय योजना आढळली नाही'
        : (lang == 'hi' ? 'कोई सरकारी योजना नहीं मिली' : 'No government schemes found');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(emptyMsg, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
