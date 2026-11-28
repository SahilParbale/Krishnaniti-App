import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/sadasya_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/sadasya_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'sadasya_profile_screen.dart';
import 'sadasya_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class SadasyaScreen extends ConsumerStatefulWidget {
  const SadasyaScreen({super.key});

  @override
  ConsumerState<SadasyaScreen> createState() => _SadasyaScreenState();
}

class _SadasyaScreenState extends ConsumerState<SadasyaScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  List<SadasyaModel> _allMembers = [];
  String _selectedArea = 'All';
  String _voterFilter = 'all'; // 'all', 'voter', 'non-voter'
  String _displayMode = 'cards'; // 'cards' or 'table'
  Map<String, int> _areaCounts = {};

  int _displayedLimit = 20;

  List<SadasyaModel> get _visibleMembers =>
      _filteredMembers.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final repo = ref.read(sadasyaRepoProvider);

    final members = await repo.getSadasyas();
    final areas = await repo.getAreasWithCount();

    if (mounted) {
      setState(() {
        _allMembers = members;
        _areaCounts = areas;
        _isLoading = false;
      });
    }
  }

  List<SadasyaModel> get _filteredMembers {
    final lang = ref.read(appLanguageProvider);
    var list = List<SadasyaModel>.from(_allMembers);

    // Search query filter
    final q = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim().toLowerCase());
    if (q.isNotEmpty) {
      list = list.where((m) {
        final displayName = m.displayNameFor(lang).toLowerCase();
        final cachedName = (DynamicTranslationService.getCachedTranslation(
                  m.displayNameFor(lang),
                  lang,
                  isName: true,
                ) ??
                '')
            .toLowerCase();
        final displayAddr = m.displayAddressFor(lang).toLowerCase();
        final cachedAddr = (DynamicTranslationService.getCachedTranslation(
                  m.displayAddressFor(lang),
                  lang,
                ) ??
                '')
            .toLowerCase();
        return m.name.toLowerCase().contains(q) ||
            (m.nameMarathi?.toLowerCase().contains(q) ?? false) ||
            (m.nameEnglish?.toLowerCase().contains(q) ?? false) ||
            displayName.contains(q) ||
            cachedName.contains(q) ||
            AppTranslations.normalizeAsciiDigits(m.mobile)
                .replaceAll(' ', '')
                .contains(q.replaceAll(' ', '')) ||
            (m.voterId?.toLowerCase().contains(q) ?? false) ||
            m.displayAddress.toLowerCase().contains(q) ||
            displayAddr.contains(q) ||
            cachedAddr.contains(q);
      }).toList();
    }

    // Area filter
    if (_selectedArea != 'All') {
      list = list.where((m) => m.area == _selectedArea).toList();
    }

    // Voter filter
    if (_voterFilter == 'voter') {
      list = list.where((m) => m.isVoter).toList();
    } else if (_voterFilter == 'non-voter') {
      list = list.where((m) => !m.isVoter).toList();
    }

    return list;
  }

  Future<void> _makeCall(String number) async {
    final clean = AppTranslations.normalizeAsciiDigits(number).replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String number, String name, String lang) async {
    final clean = AppTranslations.normalizeAsciiDigits(number).replaceAll(RegExp(r'[^\d]'), '');
    final translatedName = await DynamicTranslationService.translateOrRaw(
      name,
      lang,
      isName: true,
    );
    final greeting = AppTranslations.pick(
      lang,
      en: 'Hello $translatedName,',
      mr: 'नमस्कार $translatedName,',
      hi: 'नमस्ते $translatedName,',
    );
    final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(greeting)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final totalCount = _allMembers.length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NagarsevakAppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(lang),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        color: const Color(0xFF0284C7),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Summary Banner
              _buildHeaderBanner(totalCount, lang),

              const SizedBox(height: 14),

              const SizedBox(height: 16),

              // Controls: Search, Area Pills & View Switcher
              _buildSearchAndFilters(lang),

              const SizedBox(height: 12),

              // List / Table
              if (_isLoading)
                const AppShimmerList(count: 6)
              else if (_filteredMembers.isEmpty)
                _buildEmptyState(lang)
              else if (_displayMode == 'table' || isDesktop)
                _buildTableView(lang)
              else
                _buildCardsView(lang),

              if (!_isLoading && _filteredMembers.isNotEmpty)
                AppLoadMoreFooter(
                  currentCount: _visibleMembers.length,
                  totalCount: _filteredMembers.length,
                  pageSize: 20,
                  onLoadMore: () {
                    setState(() => _displayedLimit += 20);
                  },
                  label: AppTranslations.pick(
                    lang,
                    en: 'members',
                    mr: 'सदस्य',
                    hi: 'सदस्य',
                  ),
                  isMarathi: lang == 'mr',
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMemberDialog,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          AppTranslations.pick(
            lang,
            en: 'Add Member',
            mr: 'सदस्य जोडा',
            hi: 'सदस्य जोड़ें',
          ),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String lang) {
    return AppBar(
      backgroundColor: const Color(0xFF0284C7),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          tooltip: AppTranslations.pick(
            lang,
            en: 'Open Menu Drawer',
            mr: 'मेनू ड्रॉवर उघडा',
            hi: 'मेनू ड्रॉवर खोलें',
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
              en: 'Sadasya (Members)',
              mr: 'सदस्य (कार्यकर्ते)',
              hi: 'सदस्य (कार्यकर्ता)',
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
              en: 'Party workers, active booth members and volunteer register',
              mr: 'पक्ष कार्यकर्ते, सक्रिय बूथ सदस्य आणि स्वयंसेवक नोंदणी',
              hi: 'पार्टी कार्यकर्ता, सक्रिय बूथ सदस्य और स्वयंसेवक रजिस्टर',
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
    );
  }

  Widget _buildHeaderBanner(int totalCount, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 550;

        final titleSection = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, color: Color(0xFF0284C7), size: 24),
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
                      en: 'Ward 12 Party Organization & Cadre',
                      mr: 'प्रभाग १२ पक्ष संघटना व कार्यकर्ते',
                      hi: 'वार्ड १२ पार्टी संगठन और कार्यकर्ता',
                    ),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Booth in-charges, ward coordinators & registered members',
                      mr: 'बूथ प्रमुख, प्रभाग समन्वयक आणि नोंदणीकृत सदस्य',
                      hi: 'बूथ प्रभारी, वार्ड समन्वयक और पंजीकृत सदस्य',
                    ),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        );

        final actionsSection = Row(
          mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: isNarrow ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Total: $totalCount',
                  mr: 'एकूण: ${AppTranslations.formatDigits(totalCount, lang)}',
                  hi: 'कुल: ${AppTranslations.formatDigits(totalCount, lang)}',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppPdfButton.icon(
                  tooltip: AppTranslations.getDownloadReport(lang),
                  onPressed: () => _exportPdfReport(lang),
                ),
              ],
            ),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),
                    actionsSection,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleSection),
                    const SizedBox(width: 12),
                    actionsSection,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters(String lang) {
    final totalMembers = AppTranslations.formatDigits(_allMembers.length, lang);
    final voterMembers = AppTranslations.formatDigits(_allMembers.where((m) => m.isVoter).length, lang);
    final nonVoterMembers = AppTranslations.formatDigits(_allMembers.where((m) => !m.isVoter).length, lang);

    return Column(
      children: [
        // Search Bar & View Mode Toggle
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() => _displayedLimit = 20),
                decoration: InputDecoration(
                  hintText: AppTranslations.pick(
                    lang,
                    en: 'Search by name, mobile, or address...',
                    mr: 'नाव, मोबाईल किंवा पत्त्यावरून शोधा...',
                    hi: 'नाम, मोबाइल या पते से खोजें...',
                  ),
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _displayedLimit = 20);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Card / Table toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildViewButton(
                    icon: Icons.view_agenda_outlined,
                    tooltip: AppTranslations.pick(
                      lang,
                      en: 'Card View',
                      mr: 'कार्ड दृश्य',
                      hi: 'कार्ड दृश्य',
                    ),
                    isSelected: _displayMode == 'cards',
                    onTap: () => setState(() => _displayMode = 'cards'),
                  ),
                  _buildViewButton(
                    icon: Icons.table_chart_outlined,
                    tooltip: AppTranslations.pick(
                      lang,
                      en: 'Table View',
                      mr: 'तक्ता दृश्य',
                      hi: 'तालिका दृश्य',
                    ),
                    isSelected: _displayMode == 'table',
                    onTap: () => setState(() => _displayMode = 'table'),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Voter Type Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTypeFilterChip(
                'all',
                AppTranslations.pick(
                  lang,
                  en: 'All Members ($totalMembers)',
                  mr: 'सर्व सदस्य ($totalMembers)',
                  hi: 'सभी सदस्य ($totalMembers)',
                ),
              ),
              const SizedBox(width: 8),
              _buildTypeFilterChip(
                'voter',
                AppTranslations.pick(
                  lang,
                  en: 'Registered Voters ($voterMembers)',
                  mr: 'नोंदणीकृत मतदार ($voterMembers)',
                  hi: 'पंजीकृत मतदाता ($voterMembers)',
                ),
              ),
              const SizedBox(width: 8),
              _buildTypeFilterChip(
                'non-voter',
                AppTranslations.pick(
                  lang,
                  en: 'Party Members Only ($nonVoterMembers)',
                  mr: 'केवळ पक्ष सदस्य ($nonVoterMembers)',
                  hi: 'केवल पार्टी सदस्य ($nonVoterMembers)',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Area Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAreaChip('All', AppTranslations.getAllAreas(lang), lang),
              ..._areaCounts.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildAreaChip(
                    entry.key,
                    AppTranslations.getAreaName(entry.key, lang),
                    lang,
                    count: entry.value,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String key, String label) {
    final isSelected = _voterFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _voterFilter = key;
        _displayedLimit = 20;
      }),
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    );
  }

  Widget _buildAreaChip(String areaKey, String label, String lang, {int? count}) {
    final isSelected = _selectedArea == areaKey;
    final textStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      color: isSelected ? const Color(0xFF0369A1) : const Color(0xFF64748B),
    );
    return FilterChip(
      label: areaKey == 'All'
          ? Text(label, style: textStyle)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTranslatedText(
                  label,
                  targetLanguage: lang,
                  style: textStyle,
                ),
                if (count != null)
                  Text(
                    ' (${AppTranslations.formatDigits(count, lang)})',
                    style: textStyle,
                  ),
              ],
            ),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _selectedArea = areaKey;
        _displayedLimit = 20;
      }),
      selectedColor: const Color(0xFFE0F2FE),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildCardsView(String lang) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _visibleMembers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = _visibleMembers[index];
        final displayName = member.displayNameFor(lang);
        final areaText = AppTranslations.getAreaName(
          member.area ?? member.ward ?? 'Shaniwar Peth',
          lang,
        );

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: InkWell(
            onTap: () => _openProfileScreen(member, lang),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFE0F2FE),
                        child: Text(
                          member.initials,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              displayName,
                              targetLanguage: lang,
                              isName: true,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (lang == 'en' &&
                                member.nameEnglish != null &&
                                member.nameEnglish != displayName)
                              Text(
                                member.nameEnglish!,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: member.isVoter ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: member.isVoter ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: member.isVoter ? 'Registered Voter' : 'Party Member',
                                      mr: member.isVoter ? 'नोंदणीकृत मतदार' : 'पक्ष सदस्य',
                                      hi: member.isVoter ? 'पंजीकृत मतदाता' : 'पार्टी सदस्य',
                                    ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: member.isVoter ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                if (member.role != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: AppTranslatedText(
                                      AppTranslations.getRoleName(member.role!, lang),
                                      targetLanguage: lang,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val == 'profile') {
                            _openProfileScreen(member, lang);
                          } else if (val == 'edit') {
                            _openEditMemberDialog(member);
                          } else if (val == 'delete') {
                            _confirmDeleteMember(member);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.account_circle_outlined, size: 18, color: Color(0xFF0284C7)),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'View Profile',
                                    mr: 'प्रोफाइल पहा',
                                    hi: 'प्रोफ़ाइल देखें',
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Edit Member',
                                    mr: 'सदस्य संपादित करा',
                                    hi: 'सदस्य संपादित करें',
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Remove',
                                    mr: 'काढा',
                                    hi: 'हटाएं',
                                  ),
                                  style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  // Area & Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: AppTranslatedText(
                          areaText,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTranslatedText(
                          member.displayAddressFor(lang),
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Contact Quick Action Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Text(
                            AppTranslations.formatDigits(member.mobile, lang),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _makeCall(member.mobile),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.call_rounded, size: 13, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Call',
                                      mr: 'कॉल करा',
                                      hi: 'कॉल करें',
                                    ),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _openWhatsApp(member.mobile, displayName, lang),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'WhatsApp',
                                      mr: 'व्हॉट्सअॅप',
                                      hi: 'व्हाट्सऐप',
                                    ),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
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
          ),
        );
      },
    );
  }

  Widget _buildTableView(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 18,
            columns: [
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Name', mr: 'नाव', hi: 'नाम'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Type', mr: 'प्रकार', hi: 'प्रकार'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Role', mr: 'पद', hi: 'भूमिका'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Action', mr: 'कृती', hi: 'कार्रवाई'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: _visibleMembers.map((m) {
              return DataRow(
                cells: [
                  DataCell(
                    AppTranslatedText(
                      m.displayNameFor(lang),
                      targetLanguage: lang,
                      isName: true,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _openProfileScreen(m, lang),
                  ),
                  DataCell(Text(AppTranslations.formatDigits(m.mobile, lang))),
                  DataCell(
                    AppTranslatedText(
                      AppTranslations.getAreaName(m.area ?? m.ward ?? '-', lang),
                      targetLanguage: lang,
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: AppTranslatedText(
                        m.displayAddressFor(lang),
                        targetLanguage: lang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.isVoter ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: m.isVoter ? 'Voter' : 'Member',
                          mr: m.isVoter ? 'मतदार' : 'सदस्य',
                          hi: m.isVoter ? 'मतदाता' : 'सदस्य',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: m.isVoter ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    m.role != null
                        ? AppTranslatedText(
                            AppTranslations.getRoleName(m.role!, lang),
                            targetLanguage: lang,
                          )
                        : const Text('-'),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_rounded, size: 16, color: Color(0xFF0284C7)),
                          onPressed: () => _makeCall(m.mobile),
                          tooltip: AppTranslations.pick(lang, en: 'Call', mr: 'कॉल', hi: 'कॉल'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                          onPressed: () => _openEditMemberDialog(m),
                          tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादन', hi: 'संपादित करें'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No party members found',
              mr: 'पक्ष सदस्य आढळले नाहीत',
              hi: 'कोई पार्टी सदस्य नहीं मिला',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Adjust your filters or click "Add Member" button',
              mr: 'तुमचे फिल्टर बदला किंवा "सदस्य जोडा" बटणावर क्लिक करा',
              hi: 'अपने फ़िल्टर बदलें या "सदस्य जोड़ें" बटन पर क्लिक करें',
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _openProfileScreen(SadasyaModel member, String lang) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SadasyaProfileScreen(
          member: member,
          onEdit: () {
            Navigator.pop(context);
            _openEditMemberDialog(member);
          },
          onDelete: () async {
            Navigator.pop(context);
            final repo = ref.read(sadasyaRepoProvider);
            await repo.deleteSadasya(member.id);
            await _loadMembers();
            final translatedName = await DynamicTranslationService.translateOrRaw(
              member.displayNameFor(lang),
              lang,
              isName: true,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppTranslations.pick(
                      lang,
                      en: '$translatedName removed from members list.',
                      mr: '$translatedName सदस्य यादीतून काढण्यात आले.',
                      hi: '$translatedName को सदस्य सूची से हटा दिया गया।',
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _exportPdfReport(String lang) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Generating party cadre official PDF report...',
              mr: 'पक्ष कार्यकर्त्यांचा अधिकृत PDF अहवाल तयार करत आहे...',
              hi: 'पार्टी कार्यकर्ताओं की आधिकारिक PDF रिपोर्ट तैयार की जा रही है...',
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await SadasyaReportGenerator.generateAndPrintReport(
        members: _filteredMembers,
        areaFilter: _selectedArea,
        typeFilter: _voterFilter,
        lang: lang,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Error generating PDF: $e',
                mr: 'PDF तयार करताना त्रुटी: $e',
                hi: 'PDF बनाने में त्रुटि: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAddMemberDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddSadasyaModal(
        onMemberAdded: () async {
          await _loadMembers();
        },
      ),
    );
  }

  void _openEditMemberDialog(SadasyaModel member) {
    final lang = ref.read(appLanguageProvider);
    final displayName = DynamicTranslationService.getCachedTranslation(
          member.displayNameFor(lang),
          lang,
          isName: true,
        ) ??
        member.displayNameFor(lang);
    final nameCtrl = TextEditingController(text: member.name);
    final mobileCtrl = TextEditingController(text: member.mobile);
    final ageCtrl = TextEditingController(text: member.age > 0 ? member.age.toString() : '');
    final areaCtrl = TextEditingController(text: member.area ?? 'Shaniwar Peth');
    final addressCtrl = TextEditingController(text: member.displayAddress);
    final wardCtrl = TextEditingController(text: member.ward ?? '12');
    String gender = member.gender;

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

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return AppFieldLabel(label: text, isRequired: isRequired);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
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
                icon: Icons.edit_note_rounded,
                title: AppTranslations.pick(
                  lang,
                  en: 'Edit Member Details',
                  mr: 'सदस्य माहिती सुधारा',
                  hi: 'सदस्य विवरण संपादित करें',
                ),
                subtitle: displayName,
                onClose: () => Navigator.pop(ctx),
              ),

              // 2. SCROLLABLE FORM BODY & SUBMIT BUTTON
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  children: [
                    // Full Name & Mobile Number side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(
                                AppTranslations.pick(lang, en: 'Full Name', mr: 'पूर्ण नाव', hi: 'पूरा नाम'),
                                isRequired: true,
                              ),
                              TextField(
                                controller: nameCtrl,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Rahul Shinde',
                                    mr: 'उदा. राहुल शिंदे',
                                    hi: 'उदा. राहुल शिंदे',
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
                              fieldLabel(
                                AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                                isRequired: true,
                              ),
                              TextField(
                                controller: mobileCtrl,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                decoration: inputDec(
                                  prefixText: AppTranslations.formatDigits('+91 ', lang),
                                  hint: AppTranslations.formatDigits('98xxxxxxxx', lang),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Age & Gender side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(AppTranslations.pick(lang, en: 'Age', mr: 'वय', hi: 'उम्र')),
                              TextField(
                                controller: ageCtrl,
                                keyboardType: TextInputType.number,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(lang, en: 'e.g. 32', mr: 'उदा. ३२', hi: 'उदा. ३२'),
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
                              AppDropdownFormField<String>(
                                label: AppTranslations.pick(lang, en: 'Gender', mr: 'लिंग', hi: 'लिंग'),
                                value: gender,
                                items: [
                                  DropdownMenuItem(value: 'M', child: Text(AppTranslations.getGender('M', lang))),
                                  DropdownMenuItem(value: 'F', child: Text(AppTranslations.getGender('F', lang))),
                                  DropdownMenuItem(value: 'O', child: Text(AppTranslations.getGender('O', lang))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => gender = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Area & Role side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(AppTranslations.pick(lang, en: 'Area / Region', mr: 'परिसर / भाग', hi: 'क्षेत्र / इलाका')),
                              TextField(
                                controller: areaCtrl,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Shaniwar Peth',
                                    mr: 'उदा. शनिवार पेठ',
                                    hi: 'उदा. शनिवार पेठ',
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
                              fieldLabel(AppTranslations.pick(lang, en: 'Ward Number', mr: 'प्रभाग क्र.', hi: 'वार्ड नंबर')),
                              TextField(
                                controller: wardCtrl,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(lang, en: 'e.g. 12', mr: 'उदा. १२', hi: 'उदा. १२'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Address
                    fieldLabel(AppTranslations.pick(lang, en: 'Residential Address', mr: 'पत्ता', hi: 'निवासी पता')),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: inputDec(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'House no, street...',
                          mr: 'घर क्र., गल्ली, परिसर...',
                          hi: 'मकान नं., गली, क्षेत्र...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final mobile = AppTranslations.normalizeAsciiDigits(mobileCtrl.text.trim());
                          if (name.isEmpty || mobile.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Please enter name and mobile',
                                    mr: 'कृपया नाव आणि मोबाईल नंबर भरा',
                                    hi: 'कृपया नाम और मोबाइल नंबर दर्ज करें',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          final normalizedAge = AppTranslations.normalizeAsciiDigits(ageCtrl.text.trim());
                          final normalizedWard = AppTranslations.normalizeAsciiDigits(wardCtrl.text.trim());
                          final updated = member.copyWith(
                            name: name,
                            nameMarathi: name,
                            mobile: mobile,
                            age: int.tryParse(normalizedAge) ?? member.age,
                            gender: gender,
                            area: areaCtrl.text.trim(),
                            ward: normalizedWard,
                            address: addressCtrl.text.trim(),
                            addressMarathi: addressCtrl.text.trim(),
                            role: member.role,
                          );

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          final repo = ref.read(sadasyaRepoProvider);
                          await repo.updateSadasya(updated);
                          await _loadMembers();

                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Member details updated successfully!',
                                  mr: 'सदस्य माहिती अद्यतनित केली!',
                                  hi: 'सदस्य विवरण सफलतापूर्वक अपडेट किया गया!',
                                ),
                              ),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'बदलाव सहेजें'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMember(SadasyaModel member) {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppTranslations.pick(
            lang,
            en: 'Confirm Remove Member',
            mr: 'सदस्य काढण्याची खात्री करा',
            hi: 'सदस्य हटाने की पुष्टि करें',
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: FutureBuilder<String>(
          future: DynamicTranslationService.translateOrRaw(
            member.displayNameFor(lang),
            lang,
            isName: true,
          ),
          initialData: member.displayNameFor(lang),
          builder: (_, snap) {
            final tName = snap.data ?? member.displayNameFor(lang);
            return Text(
              AppTranslations.pick(
                lang,
                en: 'Are you sure you want to remove "$tName" from members list?',
                mr: 'तुम्हाला खात्री आहे की "$tName" यांना सदस्य यादीतून काढायचे आहे?',
                hi: 'क्या आप वाकई "$tName" को सदस्य सूची से हटाना चाहते हैं?',
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final repo = ref.read(sadasyaRepoProvider);
              await repo.deleteSadasya(member.id);
              await _loadMembers();
              final tName = await DynamicTranslationService.translateOrRaw(
                member.displayNameFor(lang),
                lang,
                isName: true,
              );

              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    AppTranslations.pick(
                      lang,
                      en: '$tName removed from members list.',
                      mr: '$tName सदस्य यादीतून काढण्यात आले.',
                      hi: '$tName को सदस्य सूची से हटा दिया गया।',
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: Text(
              AppTranslations.pick(lang, en: 'Remove', mr: 'काढा', hi: 'हटाएं'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal Sheet with Dual Tabs (Search Voter / Direct Entry) matching SadasyaList.tsx
class _AddSadasyaModal extends ConsumerStatefulWidget {
  final Future<void> Function() onMemberAdded;

  const _AddSadasyaModal({required this.onMemberAdded});

  @override
  ConsumerState<_AddSadasyaModal> createState() => _AddSadasyaModalState();
}

class _AddSadasyaModalState extends ConsumerState<_AddSadasyaModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Voter Search Tab State
  final TextEditingController _voterSearchCtrl = TextEditingController();
  List<VoterModel> _voterResults = [];
  bool _isSearchingVoters = false;
  VoterModel? _selectedVoter;
  final TextEditingController _confirmMobileCtrl = TextEditingController(text: '+91 ');
  final TextEditingController _confirmAreaCtrl = TextEditingController(text: 'Shaniwar Peth');
  final TextEditingController _confirmWardCtrl = TextEditingController(text: '12');

  // Manual Tab State
  final TextEditingController _manualNameCtrl = TextEditingController();
  final TextEditingController _manualMobileCtrl = TextEditingController(text: '+91 ');
  final TextEditingController _manualAgeCtrl = TextEditingController();
  final TextEditingController _manualAreaCtrl = TextEditingController(text: 'Shaniwar Peth');
  final TextEditingController _manualAddressCtrl = TextEditingController();
  final TextEditingController _manualWardCtrl = TextEditingController(text: '12');
  String _manualGender = 'M';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voterSearchCtrl.dispose();
    _confirmMobileCtrl.dispose();
    _confirmAreaCtrl.dispose();
    _confirmWardCtrl.dispose();
    _manualNameCtrl.dispose();
    _manualMobileCtrl.dispose();
    _manualAgeCtrl.dispose();
    _manualAreaCtrl.dispose();
    _manualAddressCtrl.dispose();
    _manualWardCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchVoters(String query) async {
    final cleanQ = AppTranslations.normalizeAsciiDigits(query.trim());
    if (cleanQ.isEmpty) {
      setState(() => _voterResults = []);
      return;
    }

    setState(() => _isSearchingVoters = true);
    final repo = ref.read(votersRepoProvider);

    try {
      final results = await repo.searchVoters(query: cleanQ, pageSize: 20);
      if (mounted) {
        setState(() {
          _voterResults = results;
          _isSearchingVoters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingVoters = false);
    }
  }

  InputDecoration _inputDec({String? hint, String? prefixText}) {
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

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return AppFieldLabel(label: text, isRequired: isRequired);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

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
            icon: Icons.person_add_alt_1_rounded,
            title: AppTranslations.pick(
              lang,
              en: 'Add New Party Member',
              mr: 'नवीन पक्ष सदस्य नोंदणी',
              hi: 'नया पार्टी सदस्य पंजीकरण',
            ),
            subtitle: AppTranslations.pick(
              lang,
              en: 'Register cadre members via voter roll or direct entry',
              mr: 'मतदार यादीतून किंवा थेट फॉर्म भरून सदस्य जोडा',
              hi: 'मतदाता सूची से या सीधे फॉर्म भरकर सदस्य जोड़ें',
            ),
            onClose: () => Navigator.pop(context),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0284C7),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0284C7),
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.how_to_vote_rounded, size: 18),
                text: AppTranslations.pick(
                  lang,
                  en: 'Add from Voter List',
                  mr: 'मतदार यादीतून जोडा',
                  hi: 'मतदाता सूची से जोड़ें',
                ),
              ),
              Tab(
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                text: AppTranslations.pick(
                  lang,
                  en: 'Direct Registration',
                  mr: 'थेट नोंदणी',
                  hi: 'सीधा पंजीकरण',
                ),
              ),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVoterSearchTab(lang),
                _buildManualEntryTab(lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoterSearchTab(String lang) {
    if (_selectedVoter != null) {
      // Step 2: Confirm selected voter
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0284C7)),
                  onPressed: () => setState(() => _selectedVoter = null),
                ),
                const SizedBox(width: 4),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Confirm Member Details',
                    mr: 'सदस्य तपशील निश्चित करा',
                    hi: 'सदस्य विवरण की पुष्टि करें',
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTranslatedText(
                    _selectedVoter!.displayName,
                    targetLanguage: lang,
                    isName: true,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'EPIC: ${_selectedVoter!.epicNo} • Age: ${_selectedVoter!.age} • Booth: ${_selectedVoter!.booth}',
                      mr: 'EPIC: ${AppTranslations.formatDigits(_selectedVoter!.epicNo, lang)} • वय: ${AppTranslations.formatDigits(_selectedVoter!.age, lang)} • बूथ: ${AppTranslations.formatDigits(_selectedVoter!.booth, lang)}',
                      hi: 'EPIC: ${AppTranslations.formatDigits(_selectedVoter!.epicNo, lang)} • उम्र: ${AppTranslations.formatDigits(_selectedVoter!.age, lang)} • बूथ: ${AppTranslations.formatDigits(_selectedVoter!.booth, lang)}',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppTranslations.pick(lang, en: 'Address: ', mr: 'पत्ता: ', hi: 'पता: ')),
                      Expanded(
                        child: AppTranslatedText(
                          _selectedVoter!.address,
                          targetLanguage: lang,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mobile & Area side-by-side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(
                        AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                        isRequired: true,
                      ),
                      TextField(
                        controller: _confirmMobileCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: _inputDec(
                          prefixText: AppTranslations.formatDigits('+91 ', lang),
                          hint: AppTranslations.formatDigits('98xxxxxxxx', lang),
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
                      _fieldLabel(
                        AppTranslations.pick(lang, en: 'Area / Region', mr: 'परिसर / भाग', hi: 'क्षेत्र / इलाका'),
                        isRequired: true,
                      ),
                      TextField(
                        controller: _confirmAreaCtrl,
                        decoration: _inputDec(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Shaniwar Peth',
                            mr: 'उदा. शनिवार पेठ',
                            hi: 'उदा. शनिवार पेठ',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ward No
            _fieldLabel(
              AppTranslations.pick(lang, en: 'Ward Number', mr: 'प्रभाग क्र.', hi: 'वार्ड नंबर'),
              isRequired: true,
            ),
            TextField(
              controller: _confirmWardCtrl,
              decoration: _inputDec(
                hint: AppTranslations.pick(lang, en: 'e.g. 12', mr: 'उदा. १२', hi: 'उदा. १२'),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveSelectedVoterAsMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Add as Member',
                    mr: 'सदस्य म्हणून जोडा',
                    hi: 'सदस्य के रूप में जोड़ें',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _voterSearchCtrl,
            onChanged: _searchVoters,
            decoration: InputDecoration(
              hintText: AppTranslations.pick(
                lang,
                en: 'Search by voter name, EPIC No. or mobile...',
                mr: 'मतदाराचे नाव, EPIC किंवा मोबाईलने शोधा...',
                hi: 'मतदाता नाम, EPIC नंबर या मोबाइल से खोजें...',
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),
          const SizedBox(height: 12),
          if (_isSearchingVoters)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_voterResults.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Type voter name or EPIC number above to search voters',
                    mr: 'मतदार शोधण्यासाठी वरील चौकटीत नाव किंवा EPIC नंबर टाका',
                    hi: 'मतदाता खोजने के लिए ऊपर नाम या EPIC नंबर दर्ज करें',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _voterResults.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final v = _voterResults[idx];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE0F2FE),
                      child: Text(
                        v.displayName.isNotEmpty ? v.displayName.characters.first : 'M',
                        style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: AppTranslatedText(
                      v.displayName,
                      targetLanguage: lang,
                      isName: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'EPIC: ${v.epicNo} • Booth: ${v.booth} • Age: ${v.age}',
                        mr: 'EPIC: ${AppTranslations.formatDigits(v.epicNo, lang)} • बूथ: ${AppTranslations.formatDigits(v.booth, lang)} • वय: ${AppTranslations.formatDigits(v.age, lang)}',
                        hi: 'EPIC: ${AppTranslations.formatDigits(v.epicNo, lang)} • बूथ: ${AppTranslations.formatDigits(v.booth, lang)} • उम्र: ${AppTranslations.formatDigits(v.age, lang)}',
                      ),
                    ),
                    trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7)),
                    onTap: () {
                      setState(() {
                        _selectedVoter = v;
                        if (v.mobile != null && v.mobile!.isNotEmpty) {
                          _confirmMobileCtrl.text = v.mobile!;
                        }
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualEntryTab(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name & Mobile side-by-side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(
                      AppTranslations.pick(lang, en: 'Full Name', mr: 'पूर्ण नाव', hi: 'पूरा नाम'),
                      isRequired: true,
                    ),
                    TextField(
                      controller: _manualNameCtrl,
                      decoration: _inputDec(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'e.g. Rahul Shinde',
                          mr: 'उदा. राहुल शिंदे',
                          hi: 'उदा. राहुल शिंदे',
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
                    _fieldLabel(
                      AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                      isRequired: true,
                    ),
                    TextField(
                      controller: _manualMobileCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: _inputDec(
                        prefixText: AppTranslations.formatDigits('+91 ', lang),
                        hint: AppTranslations.formatDigits('98xxxxxxxx', lang),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Age & Gender side-by-side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(AppTranslations.pick(lang, en: 'Age', mr: 'वय', hi: 'उम्र')),
                    TextField(
                      controller: _manualAgeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec(
                        hint: AppTranslations.pick(lang, en: 'e.g. 32', mr: 'उदा. ३२', hi: 'उदा. ३२'),
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
                    AppDropdownFormField<String>(
                      label: AppTranslations.pick(lang, en: 'Gender', mr: 'लिंग', hi: 'लिंग'),
                      value: _manualGender,
                      items: [
                        DropdownMenuItem(value: 'M', child: Text(AppTranslations.getGender('M', lang))),
                        DropdownMenuItem(value: 'F', child: Text(AppTranslations.getGender('F', lang))),
                        DropdownMenuItem(value: 'O', child: Text(AppTranslations.getGender('O', lang))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _manualGender = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Area & Ward No side-by-side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(
                      AppTranslations.pick(lang, en: 'Area / Locality', mr: 'परिसर', hi: 'क्षेत्र / इलाका'),
                      isRequired: true,
                    ),
                    TextField(
                      controller: _manualAreaCtrl,
                      decoration: _inputDec(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'e.g. Shaniwar Peth',
                          mr: 'उदा. शनिवार पेठ',
                          hi: 'उदा. शनिवार पेठ',
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
                    _fieldLabel(
                      AppTranslations.pick(lang, en: 'Ward Number', mr: 'प्रभाग क्र.', hi: 'वार्ड नंबर'),
                      isRequired: true,
                    ),
                    TextField(
                      controller: _manualWardCtrl,
                      decoration: _inputDec(
                        hint: AppTranslations.pick(lang, en: 'e.g. 12', mr: 'उदा. १२', hi: 'उदा. १२'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Residential Address
          _fieldLabel(
            AppTranslations.pick(lang, en: 'Residential Address', mr: 'पत्ता', hi: 'निवासी पता'),
            isRequired: true,
          ),
          TextField(
            controller: _manualAddressCtrl,
            maxLines: 2,
            decoration: _inputDec(
              hint: AppTranslations.pick(
                lang,
                en: 'House no, street...',
                mr: 'घर क्र., गल्ली, परिसर...',
                hi: 'मकान नं., गली, क्षेत्र...',
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveManualMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                AppTranslations.pick(lang, en: 'Register Member', mr: 'सदस्य नोंदणी करा', hi: 'सदस्य पंजीकृत करें'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _saveSelectedVoterAsMember() async {
    final lang = ref.read(appLanguageProvider);
    final voter = _selectedVoter;
    if (voter == null) return;

    final mobile = AppTranslations.normalizeAsciiDigits(_confirmMobileCtrl.text.trim());
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter mobile number',
              mr: 'कृपया मोबाईल नंबर भरा',
              hi: 'कृपया मोबाइल नंबर दर्ज करें',
            ),
          ),
        ),
      );
      return;
    }

    final normalizedWard = AppTranslations.normalizeAsciiDigits(_confirmWardCtrl.text.trim());
    final newMember = SadasyaModel(
      id: 'sad-${DateTime.now().millisecondsSinceEpoch}',
      name: voter.displayName,
      nameMarathi: voter.nameMarathi,
      nameEnglish: voter.nameEnglish,
      mobile: mobile,
      age: voter.age,
      gender: voter.gender,
      ward: normalizedWard.isNotEmpty ? normalizedWard : 'Ward 12',
      area: _confirmAreaCtrl.text.trim().isNotEmpty ? _confirmAreaCtrl.text.trim() : 'Shaniwar Peth',
      address: voter.address,
      addressMarathi: voter.address,
      addressEnglish: voter.address,
      isVoter: true,
      voterId: voter.epicNo,
      linkedVoterId: voter.id,
      status: 'Active',
      role: 'Active Member',
      registeredAt: DateTime.now(),
    );

    final repo = ref.read(sadasyaRepoProvider);
    await repo.addSadasya(newMember);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      await widget.onMemberAdded();
      final tName = await DynamicTranslationService.translateOrRaw(
        voter.displayName,
        lang,
        isName: true,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: '$tName registered as party member!',
              mr: '$tName यांची पक्ष सदस्य म्हणून नोंदणी झाली!',
              hi: '$tName पार्टी सदस्य के रूप में पंजीकृत हो गए!',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _saveManualMember() async {
    final lang = ref.read(appLanguageProvider);
    final name = _manualNameCtrl.text.trim();
    final mobile = AppTranslations.normalizeAsciiDigits(_manualMobileCtrl.text.trim());
    final address = _manualAddressCtrl.text.trim();
    final area = _manualAreaCtrl.text.trim();

    if (name.isEmpty || mobile.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter name, mobile and address',
              mr: 'कृपया नाव, मोबाईल आणि पत्ता भरा',
              hi: 'कृपया नाम, मोबाइल और पता दर्ज करें',
            ),
          ),
        ),
      );
      return;
    }

    final normalizedAge = AppTranslations.normalizeAsciiDigits(_manualAgeCtrl.text.trim());
    final normalizedWard = AppTranslations.normalizeAsciiDigits(_manualWardCtrl.text.trim());
    final newMember = SadasyaModel(
      id: 'sad-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      nameMarathi: name,
      mobile: mobile,
      age: int.tryParse(normalizedAge) ?? 0,
      gender: _manualGender,
      ward: normalizedWard.isNotEmpty ? normalizedWard : 'Ward 12',
      area: area.isNotEmpty ? area : 'Shaniwar Peth',
      address: address,
      addressMarathi: address,
      isVoter: false,
      status: 'Active',
      role: 'Active Member',
      registeredAt: DateTime.now(),
    );

    final repo = ref.read(sadasyaRepoProvider);
    await repo.addSadasya(newMember);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      await widget.onMemberAdded();
      final tName = await DynamicTranslationService.translateOrRaw(
        name,
        lang,
        isName: true,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: '$tName registered as new party member!',
              mr: '$tName यांची नवीन पक्ष सदस्य म्हणून नोंदणी झाली!',
              hi: '$tName नए पार्टी सदस्य के रूप में पंजीकृत हो गए!',
            ),
          ),
        ),
      );
    }
  }
}