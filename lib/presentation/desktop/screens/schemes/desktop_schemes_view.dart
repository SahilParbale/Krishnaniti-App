import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import 'package:nagarsevak_mobile/data/models/scheme_model.dart';
import 'package:nagarsevak_mobile/data/repositories/schemes_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/common/desktop_modal_dialog.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/screens/schemes/scheme_report_generator.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';

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

  bool _loading = true;
  List<SchemeModel> _schemes = [];

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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => DesktopModalDialog(
          title: 'Add Government Scheme',
          subtitle: 'Create a welfare scheme with eligibility criteria and benefits',
          icon: Icons.account_balance_rounded,
          width: 580,
          onClose: () => Navigator.pop(ctx),
          actions: [
            DesktopModalDialog.cancelButton(ctx),
            const SizedBox(width: 12),
            DesktopModalDialog.primaryButton(
              text: 'Save Scheme',
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
              const Text('Scheme Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: desktopInputDecoration(hintText: 'e.g. Pradhan Mantri Awas Yojana...'),
              ),
              const SizedBox(height: 14),
              const Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              AppDropdown<String>(
                value: category,
                height: 44,
                backgroundColor: const Color(0xFFF8FAFC),
                borderColor: const Color(0xFFE2E8F0),
                items: _categories.map((c) => DropdownMenuItem(value: c['id']!, child: Text(c['en']!))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => category = val);
                },
              ),
              const SizedBox(height: 14),
              const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: desktopInputDecoration(hintText: 'Summary of the scheme...'),
              ),
              const SizedBox(height: 14),
              const Text('Eligibility Criteria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: eligCtrl,
                maxLines: 2,
                decoration: desktopInputDecoration(hintText: 'Who qualifies for this benefit...'),
              ),
              const SizedBox(height: 14),
              const Text('Benefits', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: benCtrl,
                maxLines: 2,
                decoration: desktopInputDecoration(hintText: 'Financial subsidy, training, or kit...'),
              ),
              const SizedBox(height: 14),
              const Text('Required Documents', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: docCtrl,
                maxLines: 2,
                decoration: desktopInputDecoration(hintText: 'Aadhaar, income certificate, ration card...'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final items = _filteredSchemes;

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
              _buildSchemesGrid(items, lang)
            else
              _buildReportTable(items, lang),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(String lang, int count) {
    final title = AppTranslations.t('schemes.title', lang: lang);
    final subtitle = AppTranslations.t('schemes.subtitle', lang: lang);
    final totalLabel = lang == 'mr' ? 'एकूण' : (lang == 'hi' ? 'कुल' : 'Total');

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
                    '$totalLabel: $count',
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
                AppTranslations.t('common.download_report', lang: lang),
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
                onTap: () => setState(() => _activeTab = 'schemes'),
              ),
              const SizedBox(width: 24),
              _buildTabButton(
                title: lang == 'mr' ? 'अर्ज' : (lang == 'hi' ? 'आवेदन' : 'Applications'),
                isActive: _activeTab == 'applications',
                onTap: () => setState(() => _activeTab = 'applications'),
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
              onTap: () => setState(() => _activeCategory = c['id']!),
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
      onChanged: (v) => setState(() => _searchQuery = v),
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
    final isMr = lang == 'mr';
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final scheme = items[index];
        final isExpanded = _expandedSchemeId == scheme.id;
        final name = scheme.localizedName(isMr);
        final desc = scheme.localizedDescription(isMr);
        final elig = scheme.localizedEligibility(isMr);
        final ben = scheme.localizedBenefits(isMr);
        final docs = scheme.localizedDocuments(isMr);

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
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                if (scheme.category.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(scheme.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            AppTranslatedText(
                              desc,
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
                        _buildDetailSection(lang == 'mr' ? 'पात्रता:' : (lang == 'hi' ? 'पात्रता:' : 'Eligibility:'), elig, Icons.check_circle_outline_rounded, const Color(0xFF16A34A)),
                        const SizedBox(height: 14),
                      ],
                      if (ben.isNotEmpty) ...[
                        _buildDetailSection(lang == 'mr' ? 'लाभ:' : (lang == 'hi' ? 'लाभ:' : 'Benefits:'), ben, Icons.card_giftcard_rounded, const Color(0xFF0284C7)),
                        const SizedBox(height: 14),
                      ],
                      if (docs.isNotEmpty) ...[
                        _buildDetailSection(lang == 'mr' ? 'कागदपत्रे:' : (lang == 'hi' ? 'दस्तावेज़:' : 'Documents:'), docs, Icons.attachment_rounded, const Color(0xFFD97706)),
                        const SizedBox(height: 14),
                      ],

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text(lang == 'mr' ? 'माहिती पुस्तिका डाउनलोड करा' : (lang == 'hi' ? 'विवरणिका डाउनलोड करें' : 'Download Brochure')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: Text(lang == 'mr' ? 'नागरिकासाठी अर्ज करा' : (lang == 'hi' ? 'नागरिक के लिए आवेदन करें' : 'Apply for Citizen')),
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

  Widget _buildDetailSection(String title, String content, IconData icon, Color iconColor) {
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
              AppTranslatedText(content, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Report Table View (matching SchemeList.tsx lines 318-368) ---
  Widget _buildReportTable(List<SchemeModel> items, String lang) {
    final isMr = lang == 'mr';
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
                DataCell(Text('$idx')),
                DataCell(AppTranslatedText(s.localizedName(isMr), style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(s.category)),
                DataCell(AppTranslatedText(s.localizedEligibility(isMr))),
                DataCell(AppTranslatedText(s.localizedBenefits(isMr))),
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
