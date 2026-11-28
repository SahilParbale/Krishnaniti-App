import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/housing_society_model.dart';
import '../../../../data/repositories/housing_society_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/housing_societies/housing_society_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopHousingSocietiesView extends ConsumerStatefulWidget {
  const DesktopHousingSocietiesView({super.key});

  @override
  ConsumerState<DesktopHousingSocietiesView> createState() => _DesktopHousingSocietiesViewState();
}

class _DesktopHousingSocietiesViewState extends ConsumerState<DesktopHousingSocietiesView> {
  bool _loading = true;
  List<HousingSocietyModel> _societies = [];
  String _searchTerm = '';
  String _selectedArea = 'All';
  String _statusFilter = 'all';
  List<String> _availableAreas = ['All'];
  int _displayedLimit = 20;

  List<HousingSocietyModel> get _visibleSocieties =>
      _filteredSocieties.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  Future<void> _fetchSocieties() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(housingSocietyRepoProvider);
      final list = await repo.getSocieties();
      final areas = await repo.getUniqueAreas();

      if (mounted) {
        setState(() {
          _societies = list;
          _availableAreas = areas;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _societies = [];
          _loading = false;
        });
      }
    }
  }

  List<HousingSocietyModel> get _filteredSocieties {
    final normalizedSearch = AppTranslations.normalizeAsciiDigits(_searchTerm).trim().toLowerCase();

    return _societies.where((s) {
      final matchesSearch = normalizedSearch.isEmpty ||
          s.name.toLowerCase().contains(normalizedSearch) ||
          (s.nameMarathi?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (s.nameEnglish?.toLowerCase().contains(normalizedSearch) ?? false) ||
          s.chairmanName.toLowerCase().contains(normalizedSearch) ||
          s.secretaryName.toLowerCase().contains(normalizedSearch) ||
          AppTranslations.normalizeAsciiDigits(s.chairmanMobile).contains(normalizedSearch) ||
          AppTranslations.normalizeAsciiDigits(s.secretaryMobile).contains(normalizedSearch) ||
          s.area.toLowerCase().contains(normalizedSearch);

      final matchesArea = _selectedArea == 'All' || s.area.toLowerCase() == _selectedArea.toLowerCase();
      final matchesStatus = _statusFilter == 'all' || s.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesArea && matchesStatus;
    }).toList();
  }

  void _showAddEditModal({HousingSocietyModel? item}) {
    final initialLang = ref.read(desktopLanguageProvider);
    final initialName = item != null ? item.displayNameFor(initialLang) : '';
    final nameController = TextEditingController(text: initialName);
    final areaController = TextEditingController(
      text: item?.area ?? AppTranslations.getAreaName('Ward 12', initialLang),
    );
    final chairmanController = TextEditingController(text: item?.chairmanName ?? '');
    final chairMobileController = TextEditingController(
      text: item != null ? AppTranslations.formatDigits(item.chairmanMobile, initialLang) : '',
    );
    final secretaryController = TextEditingController(text: item?.secretaryName ?? '');
    final secMobileController = TextEditingController(
      text: item != null ? AppTranslations.formatDigits(item.secretaryMobile, initialLang) : '',
    );
    final voterCountController = TextEditingController(
      text: AppTranslations.formatDigits(item?.voterCount ?? 100, initialLang),
    );
    final favVoterController = TextEditingController(
      text: AppTranslations.formatDigits(item?.favourableVoterCount ?? 60, initialLang),
    );
    final notesController = TextEditingController(text: item?.notes ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            return DesktopModalDialog(
              title: item == null
                  ? AppTranslations.pick(
                      lang,
                      en: 'Register New Society',
                      mr: 'नवीन सोसायटी नोंदवा',
                      hi: 'नई सोसायटी पंजीकृत करें',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Edit Society Details',
                      mr: 'सोसायटी तपशील संपादित करा',
                      hi: 'सोसायटी विवरण संपादित करें',
                    ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Register and track housing societies, office bearers, and voter count',
                mr: 'गृहनिर्माण संस्था, पदाधिकारी आणि मतदार संख्या नोंदवा व मागोवा ठेवा',
                hi: 'हाउसिंग सोसायटी, पदाधिकारियों और मतदाता संख्या को पंजीकृत और ट्रैक करें',
              ),
              icon: Icons.domain_rounded,
              width: 600,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(ctx),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: item == null
                      ? AppTranslations.pick(
                          lang,
                          en: 'Register Society',
                          mr: 'सोसायटी नोंदवा',
                          hi: 'सोसायटी पंजीकृत करें',
                        )
                      : AppTranslations.pick(
                          lang,
                          en: 'Save Changes',
                          mr: 'बदल जतन करा',
                          hi: 'बदलाव सहेजें',
                        ),
                  onPressed: () async {
                    final rawName = nameController.text.trim();
                    if (rawName.isEmpty) return;

                    final nameUnchanged = item != null && rawName == initialName;
                    final savedName = nameUnchanged ? item.name : rawName;
                    final savedNameMr = nameUnchanged
                        ? item.nameMarathi
                        : (DynamicTranslationService.containsDevanagari(rawName) ? rawName : (item?.nameMarathi ?? rawName));
                    final savedNameEn = nameUnchanged
                        ? item.nameEnglish
                        : (!DynamicTranslationService.containsDevanagari(rawName) ? rawName : item?.nameEnglish);

                    final newSoc = HousingSocietyModel(
                      id: item?.id ?? 'soc-${DateTime.now().millisecondsSinceEpoch}',
                      tenantId: item?.tenantId,
                      name: savedName,
                      nameMarathi: savedNameMr,
                      nameEnglish: savedNameEn,
                      area: areaController.text.trim(),
                      address: item?.address ?? '',
                      chairmanName: chairmanController.text.trim(),
                      chairmanMobile: AppTranslations.normalizeAsciiDigits(chairMobileController.text.trim()),
                      secretaryName: secretaryController.text.trim(),
                      secretaryMobile: AppTranslations.normalizeAsciiDigits(secMobileController.text.trim()),
                      voterCount: int.tryParse(
                            AppTranslations.normalizeAsciiDigits(voterCountController.text.trim()),
                          ) ??
                          0,
                      favourableVoterCount: int.tryParse(
                            AppTranslations.normalizeAsciiDigits(favVoterController.text.trim()),
                          ) ??
                          0,
                      notes: notesController.text.trim(),
                      status: item?.status ?? 'Active',
                      createdAt: item?.createdAt,
                    );

                    final repo = ref.read(housingSocietyRepoProvider);
                    if (item == null) {
                      await repo.addSociety(newSoc);
                    } else {
                      await repo.updateSociety(newSoc);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchSocieties();
                  },
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Society Name
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Society Name *',
                      mr: 'सोसायटीचे नाव *',
                      hi: 'सोसायटी का नाम *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Gokuldham Co-op Housing Society...',
                        mr: 'उदा. गोकुळधाम को-ऑप. हौसिंग सोसायटी...',
                        hi: 'उदा. गोकुलधाम को-ऑप. हाउसिंग सोसायटी...',
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

                  // Area & Voters
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Area / Location *',
                                mr: 'परिसर / ठिकाण *',
                                hi: 'क्षेत्र / स्थान *',
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
                                  mr: 'उदा. मुख्य रस्ता',
                                  hi: 'उदा. मुख्य मार्ग',
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
                                en: 'Total Voters',
                                mr: 'एकूण मतदार',
                                hi: 'कुल मतदाता',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: voterCountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
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
                                en: 'Favourable Voters',
                                mr: 'अनुकूल मतदार',
                                hi: 'अनुकूल मतदाता',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: favVoterController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
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

                  // Chairman Name & Mobile
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Chairman Name',
                                mr: 'चेअरमनचे नाव',
                                hi: 'चेयरमैन का नाम',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: chairmanController,
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'Name of Chairman...',
                                  mr: 'चेअरमनचे नाव...',
                                  hi: 'चेयरमैन का नाम...',
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
                                en: 'Chairman Mobile',
                                mr: 'चेअरमन मोबाईल',
                                hi: 'चेयरमैन मोबाइल',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: chairMobileController,
                              keyboardType: TextInputType.phone,
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

                  // Secretary Name & Mobile
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Secretary Name',
                                mr: 'सेक्रेटरीचे नाव',
                                hi: 'सचिव का नाम',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: secretaryController,
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'Name of Secretary...',
                                  mr: 'सेक्रेटरीचे नाव...',
                                  hi: 'सचिव का नाम...',
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
                                en: 'Secretary Mobile',
                                mr: 'सेक्रेटरी मोबाईल',
                                hi: 'सचिव मोबाइल',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: secMobileController,
                              keyboardType: TextInputType.phone,
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

                  // Notes
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Local Issues & Demands',
                      mr: 'स्थानिक समस्या व मागण्या',
                      hi: 'स्थानीय समस्याएं और मांगें',
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
                        en: 'Water supply, internal roads, streetlight or waste disposal issues...',
                        mr: 'पाणी पुरवठा, अंतर्गत रस्ते, पथदिवे किंवा कचरा व्यवस्थापनाच्या समस्या...',
                        hi: 'जल आपूर्ति, आंतरिक सड़कें, स्ट्रीट लाइट या कचरा प्रबंधन की समस्याएं...',
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
        ),
      ),
    );
  }

  void _showDeleteConfirm(HousingSocietyModel item) {
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
              en: 'Delete Society',
              mr: 'सोसायटी हटवायची का?',
              hi: 'सोसायटी हटाएं?',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Are you sure you want to delete this society?',
                  mr: 'तुम्हाला खात्री आहे की तुम्ही ही सोसायटी हटवू इच्छिता?',
                  hi: 'क्या आप वाकई इस सोसायटी को हटाना चाहते हैं?',
                ),
              ),
              const SizedBox(height: 8),
              AppTranslatedText(
                item.displayNameFor(lang),
                targetLanguage: lang,
                prefix: '"',
                suffix: '"',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(housingSocietyRepoProvider);
                await repo.deleteSociety(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchSocieties();
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
    final filtered = _filteredSocieties;
    final visible = _visibleSocieties;
    final totalVoters = filtered.fold<int>(0, (sum, s) => sum + s.voterCount);
    final favVoters = filtered.fold<int>(0, (sum, s) => sum + s.favourableVoterCount);
    final avgSupport = totalVoters > 0 ? ((favVoters / totalVoters) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 20),

          // 4 Stats Cards
          _buildStatsRow(filtered.length, totalVoters, favVoters, avgSupport, lang),
          const SizedBox(height: 24),

          // Filter bar
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
              label: AppTranslations.pick(lang, en: 'societies', mr: 'सोसायटी', hi: 'सोसायटियाँ'),
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
                  Flexible(
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Housing Societies',
                        mr: 'गृहनिर्माण सोसायट्या',
                        hi: 'हाउसिंग सोसायटियां',
                      ),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Total: $countStr',
                        mr: 'एकूण: $countStr',
                        hi: 'कुल: $countStr',
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Co-operative housing societies, chairpersons, secretaries and voter outreach',
                  mr: 'सहकारी गृहनिर्माण संस्था, चेअरमन, सेक्रेटरी आणि मतदार संपर्क',
                  hi: 'सहकारी आवास समितियां, अध्यक्ष, सचिव और मतदाता संपर्क',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions Row matching HousingSocieties.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                HousingSocietyReportGenerator.generateAndPrintReport(
                  context: context,
                  societies: _filteredSocieties,
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

            // Add Button
            ElevatedButton(
              onPressed: () => _showAddEditModal(),
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
                      en: 'Register Society',
                      mr: 'सोसायटी नोंदवा',
                      hi: 'सोसायटी पंजीकृत करें',
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

  Widget _buildStatsRow(int totalSoc, int totalVoters, int favVoters, int avgSupport, String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Total Societies', mr: 'एकूण सोसायट्या', hi: 'कुल सोसायटियाँ'),
            AppTranslations.formatDigits(totalSoc, lang),
            Icons.apartment_rounded,
            const Color(0xFF4F46E5),
            const Color(0xFFEEF2FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Total Voters', mr: 'एकूण मतदार', hi: 'कुल मतदाता'),
            AppTranslations.formatDigits(totalVoters, lang),
            Icons.people_alt_outlined,
            const Color(0xFF0284C7),
            const Color(0xFFF0F9FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Favourable Voters', mr: 'अनुकूल मतदार', hi: 'अनुकूल मतदाता'),
            AppTranslations.formatDigits(favVoters, lang),
            Icons.how_to_reg_rounded,
            const Color(0xFF16A34A),
            const Color(0xFFF0FDF4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Support Rate', mr: 'समर्थन प्रमाण', hi: 'समर्थन दर'),
            AppTranslations.formatDigits('$avgSupport%', lang),
            Icons.pie_chart_outline_rounded,
            const Color(0xFF9333EA),
            const Color(0xFFFAF5FF),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
        Expanded(
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
                  en: 'Search society by name, chairman or secretary...',
                  mr: 'सोसायटीचे नाव, चेअरमन किंवा सेक्रेटरी शोधा...',
                  hi: 'सोसायटी, चेयरमैन या सचिव के नाम से खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Area Filter
        AppDropdown<String>(
          value: _selectedArea,
          height: 40,
          width: 170,
          prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          items: _availableAreas.map((a) {
            return DropdownMenuItem(
              value: a,
              child: Text(a == 'All' ? AppTranslations.getAllAreas(lang) : AppTranslations.getAreaName(a, lang)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedArea = val;
                _displayedLimit = 20;
              });
            }
          },
        ),
        const SizedBox(width: 12),

        // Status Filter
        AppDropdown<String>(
          value: _statusFilter,
          height: 40,
          width: 150,
          prefixIcon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF94A3B8)),
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(AppTranslations.pick(lang, en: 'All Status', mr: 'सर्व स्थिती', hi: 'सभी स्थिति')),
            ),
            DropdownMenuItem(
              value: 'Active',
              child: Text(AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय')),
            ),
            DropdownMenuItem(
              value: 'Inactive',
              child: Text(AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय')),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _statusFilter = val;
                _displayedLimit = 20;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<HousingSocietyModel> items, String lang) {
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
            const Icon(Icons.home_work_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No housing societies found',
                mr: 'कोणत्याही गृहनिर्माण सोसायट्या आढळल्या नाहीत',
                hi: 'कोई हाउसिंग सोसायटी नहीं मिली',
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
            mainAxisExtent: 280,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final pctStr = AppTranslations.formatDigits('${item.supportPercentage}%', lang);
            final favStr = AppTranslations.formatDigits(item.favourableVoterCount, lang);
            final totalStr = AppTranslations.formatDigits(item.voterCount, lang);
            final otherStr = AppTranslations.formatDigits(item.otherVotersCount, lang);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(4)),
                          child: AppTranslatedText(
                            AppTranslations.getAreaName(item.area.isNotEmpty ? item.area : 'Ward 12', lang),
                            targetLanguage: lang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: '$pctStr Favourable',
                            mr: '$pctStr अनुकूल',
                            hi: '$pctStr अनुकूल',
                          ),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  AppTranslatedText(
                    item.displayNameFor(lang),
                    targetLanguage: lang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  // Chairman
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.pick(lang, en: 'Chairman: ', mr: 'चेअरमन: ', hi: 'चेयरमैन: '),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      Flexible(
                        child: item.chairmanName.trim().isNotEmpty
                            ? AppTranslatedText(
                                item.chairmanName,
                                isName: true,
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              )
                            : Text(
                                AppTranslations.pick(lang, en: 'Not recorded', mr: 'नोंद नाही', hi: 'दर्ज नहीं'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                      ),
                      if (item.chairmanMobile.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${AppTranslations.formatDigits(item.chairmanMobile, lang)})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Secretary
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.pick(lang, en: 'Secretary: ', mr: 'सेक्रेटरी: ', hi: 'सचिव: '),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      Flexible(
                        child: item.secretaryName.trim().isNotEmpty
                            ? AppTranslatedText(
                                item.secretaryName,
                                isName: true,
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              )
                            : Text(
                                AppTranslations.pick(lang, en: 'Not recorded', mr: 'नोंद नाही', hi: 'दर्ज नहीं'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                      ),
                      if (item.secretaryMobile.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${AppTranslations.formatDigits(item.secretaryMobile, lang)})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Voter progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Voters: $favStr / $totalStr',
                          mr: 'मतदार: $favStr / $totalStr',
                          hi: 'मतदाता: $favStr / $totalStr',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Other: $otherStr',
                          mr: 'इतर: $otherStr',
                          hi: 'अन्य: $otherStr',
                        ),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: item.voterCount > 0 ? (item.favourableVoterCount / item.voterCount).clamp(0.0, 1.0) : 0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      minHeight: 6,
                    ),
                  ),

                  const Spacer(),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.status == 'Active'
                              ? AppTranslations.pick(lang, en: 'Active Society', mr: 'सक्रिय सोसायटी', hi: 'सक्रिय सोसायटी')
                              : AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                              onPressed: () => _showAddEditModal(item: item),
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
            mainAxisExtent: 260,
          ),
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
