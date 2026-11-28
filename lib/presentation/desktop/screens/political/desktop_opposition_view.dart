import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/opposition_model.dart';
import '../../../../data/repositories/opposition_repository.dart';
import '../../../screens/opposition/opposition_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopOppositionView extends ConsumerStatefulWidget {
  const DesktopOppositionView({super.key});

  @override
  ConsumerState<DesktopOppositionView> createState() => _DesktopOppositionViewState();
}

class _DesktopOppositionViewState extends ConsumerState<DesktopOppositionView> {
  bool _loading = true;
  List<OppositionMemberModel> _members = [];
  String _searchTerm = '';
  String _partyFilter = 'All';
  String _typeFilter = 'all'; // 'all', 'candidates', 'workers'
  String _areaFilter = 'All';
  int _displayedLimit = 20;

  List<OppositionMemberModel> get _visibleMembers =>
      _filteredMembers.take(_displayedLimit).toList();

  List<String> get _uniqueAreas {
    final areas = _members
        .map((m) => (m.area ?? '').trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...areas];
  }

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(oppositionRepoProvider);
      final list = await repo.getMembers();
      if (mounted) {
        setState(() {
          _members = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _members = [];
          _loading = false;
        });
      }
    }
  }

  List<OppositionMemberModel> get _filteredMembers {
    final normSearch = AppTranslations.normalizeAsciiDigits(_searchTerm).toLowerCase();
    return _members.where((m) {
      final matchesSearch = _searchTerm.isEmpty ||
          m.name.toLowerCase().contains(normSearch) ||
          m.party.toLowerCase().contains(normSearch) ||
          (m.mobile != null && AppTranslations.normalizeAsciiDigits(m.mobile!).contains(normSearch)) ||
          (m.area?.toLowerCase().contains(normSearch) ?? false);

      final matchesParty = _partyFilter == 'All' || m.party == _partyFilter;

      final matchesType = _typeFilter == 'all' ||
          (_typeFilter == 'candidates' && m.isCandidate) ||
          (_typeFilter == 'workers' && !m.isCandidate);

      final matchesArea = _areaFilter == 'All' ||
          (m.area != null && m.area!.toLowerCase().contains(_areaFilter.toLowerCase()));

      return matchesSearch && matchesParty && matchesType && matchesArea;
    }).toList();
  }

  void _showAddMemberModal({OppositionMemberModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final mobileController = TextEditingController(text: item?.mobile ?? '');
    final partyController = TextEditingController(text: item?.party ?? 'Opposition Party');
    final roleController = TextEditingController(text: item?.role ?? 'Opposition Candidate');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    final strongholdsController = TextEditingController(text: (item?.strongholds ?? []).join(', '));
    final notesController = TextEditingController(text: item?.notes ?? '');
    bool isCandidate = item?.isCandidate ?? false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return ValueListenableBuilder<String>(
            valueListenable: appLanguageValueNotifier,
            builder: (ctx, lang, _) {
              return DesktopModalDialog(
                title: item == null
                    ? AppTranslations.pick(
                        lang,
                        en: 'Add Opposition Leader',
                        mr: 'विरोधी नेता जोडा',
                        hi: 'विपक्षी नेता जोड़ें',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Edit Leader Details',
                        mr: 'नेत्याची माहिती संपादित करा',
                        hi: 'नेता विवरण संपादित करें',
                      ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Track opposition profiles, political party, and local influence',
                  mr: 'विरोधी नेते, राजकीय पक्ष आणि स्थानिक प्रभाव ट्रॅक करा',
                  hi: 'विपक्षी प्रोफाइल, राजनीतिक दल और स्थानीय प्रभाव ट्रैक करें',
                ),
                icon: Icons.shield_outlined,
                width: 600,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(ctx),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: item == null
                        ? AppTranslations.pick(
                            lang,
                            en: 'Add Leader',
                            mr: 'नेता जोडा',
                            hi: 'नेता जोड़ें',
                          )
                        : AppTranslations.pick(
                            lang,
                            en: 'Save Changes',
                            mr: 'बदल जतन करा',
                            hi: 'परिवर्तन सहेजें',
                          ),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final strongholds = strongholdsController.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();

                      final newMember = OppositionMemberModel(
                        id: item?.id ?? 'opp-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        party: partyController.text.trim(),
                        mobile: mobileController.text.trim().isNotEmpty
                            ? AppTranslations.normalizeAsciiDigits(mobileController.text.trim())
                            : null,
                        role: roleController.text.trim(),
                        area: areaController.text.trim(),
                        strongholds: strongholds,
                        notes: notesController.text.trim(),
                        isCandidate: isCandidate,
                        createdAt: item?.createdAt ?? DateTime.now(),
                      );

                      final repo = ref.read(oppositionRepoProvider);
                      if (item == null) {
                        await repo.addMember(newMember);
                      } else {
                        await repo.updateMember(newMember);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchMembers();
                    },
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Leader Name *',
                        mr: 'नेत्याचे नाव *',
                        hi: 'नेता का नाम *',
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Sunil Y. Thorat...',
                          mr: 'उदा. सुनील य. थोरात...',
                          hi: 'जैसे सुनील वाई. थोरात...',
                        ),
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Party & Mobile
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Political Party *',
                                  mr: 'राजकीय पक्ष *',
                                  hi: 'राजनीतिक दल *',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: partyController,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Opposition Party Name',
                                    mr: 'उदा. विरोधी पक्षाचे नाव',
                                    hi: 'जैसे विपक्षी दल का नाम',
                                  ),
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Mobile',
                                  mr: 'मोबाईल',
                                  hi: 'मोबाइल',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mobileController,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.formatDigits('98XXXXXXXX', lang),
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Candidate Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isCandidate,
                          onChanged: (val) => setModalState(() => isCandidate = val ?? false),
                          activeColor: const Color(0xFFDC2626),
                        ),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Is Official Candidate',
                            mr: 'अधिकृत उमेदवार आहे का?',
                            hi: 'क्या आधिकारिक उम्मीदवार हैं?',
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Area & Strongholds
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Ward / Area',
                                  mr: 'प्रभाग / परिसर',
                                  hi: 'वार्ड / क्षेत्र',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaController,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Main Street',
                                    mr: 'उदा. मेन रोड / प्रभाग १२',
                                    hi: 'जैसे मुख्य मार्ग / वार्ड १२',
                                  ),
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Strongholds / Influence Area',
                                  mr: 'प्रभाव क्षेत्र / बालेकिल्ला',
                                  hi: 'प्रभाव क्षेत्र / गढ़',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: strongholdsController,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Booth No. 24, 25',
                                    mr: 'उदा. बूथ क्र. २४, २५',
                                    hi: 'जैसे बूथ सं. २४, २५',
                                  ),
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Notes & Political Strategy',
                        mr: 'नोंदी आणि राजकीय रणनीती',
                        hi: 'नोट्स और राजनीतिक रणनीति',
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Political background, local strengths and weaknesses...',
                          mr: 'राजकीय पार्श्वभूमी, स्थानिक ताकद आणि कमकुवत बाजू...',
                          hi: 'राजनीतिक पृष्ठभूमि, स्थानीय ताकत और कमजोरियां...',
                        ),
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(OppositionMemberModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppTranslations.pick(
              lang,
              en: 'Delete Profile',
              mr: 'प्रोफाइल हटवा',
              hi: 'प्रोफ़ाइल हटाएं',
            ),
          ),
          content: AppTranslatedText(
            item.name,
            isName: true,
            targetLanguage: lang,
            builder: (context, translatedName) => Text(
              AppTranslations.pick(
                lang,
                en: 'Are you sure you want to delete "$translatedName"?',
                mr: 'तुम्हाला खात्री आहे की तुम्ही "$translatedName" यांना हटवू इच्छिता?',
                hi: 'क्या आप वाकई "$translatedName" को हटाना चाहते हैं?',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(oppositionRepoProvider);
                await repo.deleteMember(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchMembers();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: Text(
                AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredMembers;
    final visible = _visibleMembers;
    final candidateCount = _members.where((m) => m.isCandidate).length;
    final workerCount = _members.length - candidateCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 20),

          // Stats
          _buildStatsRow(candidateCount, workerCount, lang),
          const SizedBox(height: 24),

          // Search & Filter
          _buildFilterBar(lang),
          const SizedBox(height: 24),

          // Content Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildCardGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(
                lang,
                en: 'opposition members',
                mr: 'विरोधी सदस्य',
                hi: 'विपक्षी सदस्य',
              ),
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, String lang) {
    final countStr = AppTranslations.formatDigits(count, lang);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Opposition Info',
                      mr: 'विरोधी पक्ष माहिती',
                      hi: 'विपक्षी जानकारी',
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Total: $countStr',
                        mr: 'एकूण: $countStr',
                        hi: 'कुल: $countStr',
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Track opposition candidates, key cadres and local political strongholds',
                  mr: 'विरोधी उमेदवार, प्रमुख कार्यकर्ते आणि स्थानिक राजकीय बालेकिल्ले ट्रॅक करा',
                  hi: 'विपक्षी उम्मीदवारों, प्रमुख कार्यकर्ताओं और स्थानीय राजनीतिक गढ़ों को ट्रैक करें',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions Row matching OppositionManagement.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                final repo = ref.read(oppositionRepoProvider);
                OppositionReportGenerator.generateAndPrintReport(
                  context: context,
                  members: _filteredMembers,
                  getCandidateName: repo.getCandidateName,
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

            // Add Member
            ElevatedButton(
              onPressed: () => _showAddMemberModal(),
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
                      en: 'Add Profile',
                      mr: 'प्रोफाइल जोडा',
                      hi: 'प्रोफ़ाइल जोड़ें',
                    ),
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

  Widget _buildStatsRow(int candidates, int workers, String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Total Tracked', mr: 'एकूण नोंदणीकृत', hi: 'कुल ट्रैक किए गए'),
            AppTranslations.formatDigits(_members.length, lang),
            Icons.groups_outlined,
            const Color(0xFF475569),
            const Color(0xFFF1F5F9),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Candidates', mr: 'उमेदवार', hi: 'उम्मीदवार'),
            AppTranslations.formatDigits(candidates, lang),
            Icons.campaign_rounded,
            const Color(0xFFDC2626),
            const Color(0xFFFEF2F2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Key Workers', mr: 'प्रमुख कार्यकर्ते', hi: 'प्रमुख कार्यकर्ता'),
            AppTranslations.formatDigits(workers, lang),
            Icons.person_pin_circle_outlined,
            const Color(0xFFD97706),
            const Color(0xFFFFFBEB),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(String lang) {
    return Row(
      children: [
        // Main Search (flex 4)
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search leader by name, party, area...',
                  mr: 'नाव, पक्ष, परिसरानुसार नेता शोधा...',
                  hi: 'नाम, दल, क्षेत्र के अनुसार नेता खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Record Type Filter (flex 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _typeFilter,
            height: 44,
            prefixIcon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(AppTranslations.pick(lang, en: 'All Types', mr: 'सर्व प्रकार', hi: 'सभी प्रकार')),
              ),
              DropdownMenuItem(
                value: 'candidates',
                child: Text(AppTranslations.pick(lang, en: 'Opposition Candidate', mr: 'विरोधी उमेदवार', hi: 'विपक्षी उम्मीदवार')),
              ),
              DropdownMenuItem(
                value: 'workers',
                child: Text(AppTranslations.pick(lang, en: 'Opposition Worker', mr: 'विरोधी कार्यकर्ता', hi: 'विपक्षी कार्यकर्ता')),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _typeFilter = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),

        // Party Filter (flex 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _partyFilter,
            height: 44,
            prefixIcon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: [
              DropdownMenuItem(
                value: 'All',
                child: Text(AppTranslations.pick(lang, en: 'All Opposition Parties', mr: 'सर्व विरोधी पक्ष', hi: 'सभी विपक्षी दल')),
              ),
              DropdownMenuItem(
                value: 'INC',
                child: Text(AppTranslations.pick(lang, en: 'Congress (INC)', mr: 'काँग्रेस (INC)', hi: 'कांग्रेस (INC)')),
              ),
              DropdownMenuItem(
                value: 'NCP',
                child: Text(AppTranslations.pick(lang, en: 'NCP', mr: 'राष्ट्रवादी (NCP)', hi: 'एनसीपी (NCP)')),
              ),
              DropdownMenuItem(
                value: 'UBT',
                child: Text(AppTranslations.pick(lang, en: 'Shivsena (UBT)', mr: 'शिवसेना (UBT)', hi: 'शिवसेना (UBT)')),
              ),
              DropdownMenuItem(
                value: 'MNS',
                child: Text(AppTranslations.pick(lang, en: 'MNS', mr: 'मनसे (MNS)', hi: 'मनसे (MNS)')),
              ),
              DropdownMenuItem(
                value: 'BJP',
                child: Text(AppTranslations.pick(lang, en: 'BJP', mr: 'भाजप (BJP)', hi: 'भाजपा (BJP)')),
              ),
              DropdownMenuItem(
                value: 'Independent',
                child: Text(AppTranslations.pick(lang, en: 'Independent', mr: 'अपक्ष', hi: 'निर्दलीय')),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _partyFilter = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),

        // Area Filter (flex 2)
        Expanded(
          flex: 2,
          child: AppDropdown<String>(
            value: _areaFilter,
            height: 44,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueAreas.map((area) {
              final label = area == 'All'
                  ? AppTranslations.getAllAreas(lang)
                  : AppTranslations.getAreaName(area, lang);
              return DropdownMenuItem(
                value: area,
                child: AppTranslatedText(
                  label,
                  targetLanguage: lang,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _areaFilter = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<OppositionMemberModel> items, String lang) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No opposition members found',
                mr: 'कोणतेही विरोधी सदस्य सापडले नाहीत',
                hi: 'कोई विपक्षी सदस्य नहीं मिला',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final roleText = (item.role != null && item.role!.trim().isNotEmpty) ? item.role! : 'Cadre';
            final areaRaw = (item.area != null && item.area!.trim().isNotEmpty) ? item.area! : 'Ward 12';
            final areaLabel = AppTranslations.getAreaName(areaRaw, lang);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: item.isCandidate ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: AppTranslatedText(
                            item.partyFullLabelFor(lang),
                            targetLanguage: lang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isCandidate ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          item.typeLabel(lang),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.isCandidate ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name
                  AppTranslatedText(
                    item.name,
                    isName: true,
                    targetLanguage: lang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),

                  // Role / Area
                  Row(
                    children: [
                      Flexible(
                        child: AppTranslatedText(
                          roleText,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Flexible(
                        child: AppTranslatedText(
                          areaLabel,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Strongholds
                  if (item.strongholds.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.strongholds.take(3).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: AppTranslatedText(
                            s,
                            targetLanguage: lang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                          ),
                        );
                      }).toList(),
                    ),

                  const Spacer(),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.mobile != null && item.mobile!.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                AppTranslations.formatDigits(item.mobile!, lang),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                              ),
                            ],
                          )
                        else
                          const SizedBox(),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                              onPressed: () => _showAddMemberModal(item: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                              tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                              onPressed: () => _showDeleteConfirm(item),
                            ),
                          ],
                        ),
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

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 240,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
