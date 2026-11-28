import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/social_organization_model.dart';
import '../../../../data/repositories/social_organization_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/social_organizations/social_org_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopNgoMandalsView extends ConsumerStatefulWidget {
  const DesktopNgoMandalsView({super.key});

  @override
  ConsumerState<DesktopNgoMandalsView> createState() => _DesktopNgoMandalsViewState();
}

class _DesktopNgoMandalsViewState extends ConsumerState<DesktopNgoMandalsView> {
  bool _loading = true;
  List<SocialOrganizationModel> _orgs = [];
  String _selectedType = 'All';
  String _searchTerm = '';
  String _statusFilter = 'all';
  int _displayedLimit = 20;

  List<SocialOrganizationModel> get _visibleOrgs =>
      _filteredOrgs.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
  }

  Future<void> _fetchOrganizations() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(socialOrgRepoProvider);
      final list = await repo.getOrganizations(type: _selectedType);
      if (mounted) {
        setState(() {
          _orgs = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _orgs = [];
          _loading = false;
        });
      }
    }
  }

  List<SocialOrganizationModel> get _filteredOrgs {
    final normalizedSearch = AppTranslations.normalizeAsciiDigits(_searchTerm).trim().toLowerCase();

    return _orgs.where((o) {
      final matchesSearch = normalizedSearch.isEmpty ||
          o.name.toLowerCase().contains(normalizedSearch) ||
          (o.nameMarathi?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (o.nameEnglish?.toLowerCase().contains(normalizedSearch) ?? false) ||
          o.presidentName.toLowerCase().contains(normalizedSearch) ||
          AppTranslations.normalizeAsciiDigits(o.presidentMobile).contains(normalizedSearch) ||
          o.area.toLowerCase().contains(normalizedSearch);

      final matchesStatus = _statusFilter == 'all' ||
          o.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _orgNameFor(SocialOrganizationModel item, String lang) {
    if (lang == 'en' && item.nameEnglish != null && item.nameEnglish!.trim().isNotEmpty) {
      return item.nameEnglish!.trim();
    }
    return item.displayName;
  }

  String _orgTypeLabel(String type, String lang) {
    switch (type) {
      case 'ngo':
        return AppTranslations.pick(
          lang,
          en: 'NGO / Foundation',
          mr: 'एन.जी.ओ / सामाजिक संस्था',
          hi: 'एनजीओ / सामाजिक संस्था',
        );
      case 'sports_cricket':
        return AppTranslations.pick(
          lang,
          en: 'Sports & Cricket Club',
          mr: 'क्रीडा व क्रिकेट क्लब',
          hi: 'खेल और क्रिकेट क्लब',
        );
      case 'ganpati_mandal':
        return AppTranslations.pick(
          lang,
          en: 'Festival Mandal',
          mr: 'गणपती मंडळ',
          hi: 'गणपति मंडल',
        );
      case 'navratri_mandal':
        return AppTranslations.pick(
          lang,
          en: 'Cultural Group',
          mr: 'नवरात्रौत्सव मंडळ',
          hi: 'सांस्कृतिक मंडल',
        );
      default:
        return AppTranslations.pick(
          lang,
          en: 'Other Organization',
          mr: 'इतर संस्था व मंडळ',
          hi: 'अन्य संगठन',
        );
    }
  }

  void _showAddOrgModal({SocialOrganizationModel? item}) {
    final initialLang = ref.read(desktopLanguageProvider);
    final initialName = item != null ? _orgNameFor(item, initialLang) : '';
    final nameController = TextEditingController(text: initialName);
    final presNameController = TextEditingController(text: item?.presidentName ?? '');
    final presMobileController = TextEditingController(
      text: item != null ? AppTranslations.formatDigits(item.presidentMobile, initialLang) : '',
    );
    final areaController = TextEditingController(
      text: item?.area ?? AppTranslations.getAreaName('Ward 12', initialLang),
    );
    final membersCountController = TextEditingController(text: (item?.membersCount ?? 25).toString());
    final establishedController = TextEditingController(text: item?.establishedYear ?? '2015');
    final supportController = TextEditingController(text: item?.supportReceived ?? '');
    String type = item?.type ?? 'ngo';

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
                      en: 'Add Organization / Mandal',
                      mr: 'संस्था / मंडळ जोडा',
                      hi: 'संगठन / मंडल जोड़ें',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Edit Organization',
                      mr: 'संस्था संपादित करा',
                      hi: 'संगठन संपादित करें',
                    ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Community groups, Ganeshotsav mandals, and social trusts',
                mr: 'सामाजिक संस्था, गणेशोत्सव मंडळे आणि सार्वजनिक न्यास',
                hi: 'सामुदायिक समूह, गणेशोत्सव मंडल और सामाजिक ट्रस्ट',
              ),
              icon: Icons.diversity_3_rounded,
              width: 600,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(ctx),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: item == null
                      ? AppTranslations.pick(
                          lang,
                          en: 'Add Organization',
                          mr: 'संस्था जोडा',
                          hi: 'संगठन जोड़ें',
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
                        : (DynamicTranslationService.containsDevanagari(rawName) ? rawName : item?.nameMarathi);
                    final savedNameEn = nameUnchanged
                        ? item.nameEnglish
                        : (!DynamicTranslationService.containsDevanagari(rawName) ? rawName : item?.nameEnglish);

                    final newOrg = SocialOrganizationModel(
                      id: item?.id ?? 'soc-${DateTime.now().millisecondsSinceEpoch}',
                      name: savedName,
                      nameMarathi: savedNameMr,
                      nameEnglish: savedNameEn,
                      type: type,
                      area: areaController.text.trim(),
                      presidentName: presNameController.text.trim(),
                      presidentMobile: AppTranslations.normalizeAsciiDigits(presMobileController.text.trim()),
                      membersCount: int.tryParse(
                            AppTranslations.normalizeAsciiDigits(membersCountController.text.trim()),
                          ) ??
                          25,
                      establishedYear: AppTranslations.normalizeAsciiDigits(establishedController.text.trim()),
                      supportReceived: supportController.text.trim(),
                      eventsConducted: item?.eventsConducted ?? const [],
                      description: item?.description ?? '',
                      status: item?.status ?? 'Active',
                      createdAt: item?.createdAt ?? DateTime.now(),
                    );

                    final repo = ref.read(socialOrgRepoProvider);
                    if (item == null) {
                      await repo.addOrganization(newOrg);
                    } else {
                      await repo.updateOrganization(newOrg);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchOrganizations();
                  },
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organization Name
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Organization Name *',
                      mr: 'संस्थेचे / मंडळाचे नाव *',
                      hi: 'संगठन / मंडल का नाम *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Navtarun Youth Club...',
                        mr: 'उदा. नवतरुण युवक मंडळ...',
                        hi: 'उदा. नवतरुण युवक मंडल...',
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

                  // Type & Area
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'Type *', mr: 'प्रकार *', hi: 'प्रकार *'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              value: type,
                              height: 44,
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFFE2E8F0),
                              items: [
                                DropdownMenuItem(value: 'ngo', child: Text(_orgTypeLabel('ngo', lang))),
                                DropdownMenuItem(value: 'sports_cricket', child: Text(_orgTypeLabel('sports_cricket', lang))),
                                DropdownMenuItem(value: 'ganpati_mandal', child: Text(_orgTypeLabel('ganpati_mandal', lang))),
                                DropdownMenuItem(value: 'navratri_mandal', child: Text(_orgTypeLabel('navratri_mandal', lang))),
                                DropdownMenuItem(value: 'other', child: Text(_orgTypeLabel('other', lang))),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => type = val);
                              },
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
                              AppTranslations.pick(lang, en: 'Ward / Area', mr: 'प्रभाग / परिसर', hi: 'वार्ड / क्षेत्र'),
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
                    ],
                  ),
                  const SizedBox(height: 16),

                  // President Name & Mobile
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'President / Head',
                                mr: 'अध्यक्ष / प्रमुख',
                                hi: 'अध्यक्ष / प्रमुख',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: presNameController,
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'Name of President...',
                                  mr: 'अध्यक्षांचे नाव...',
                                  hi: 'अध्यक्ष का नाम...',
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
                              AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: presMobileController,
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

                  // Support Notes
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Support Provided',
                      mr: 'दिलेली मदत / सहकार्य',
                      hi: 'प्रदान की गई सहायता',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: supportController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Assistance provided, equipment, stage setup, civic support...',
                        mr: 'दिलेली मदत, साहित्य, मंडप व्यवस्था, नागरी सहकार्य...',
                        hi: 'प्रदान की गई सहायता, उपकरण, मंच व्यवस्था, नागरिक सहयोग...',
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

  void _showDeleteConfirm(SocialOrganizationModel item) {
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
              en: 'Delete Organization',
              mr: 'संस्था हटवायची का?',
              hi: 'संगठन हटाएं?',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Are you sure you want to delete this organization?',
                  mr: 'तुम्हाला खात्री आहे की तुम्ही ही संस्था हटवू इच्छिता?',
                  hi: 'क्या आप वाकई इस संगठन को हटाना चाहते हैं?',
                ),
              ),
              const SizedBox(height: 8),
              AppTranslatedText(
                _orgNameFor(item, lang),
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
                final repo = ref.read(socialOrgRepoProvider);
                await repo.deleteOrganization(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchOrganizations();
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
    final filtered = _filteredOrgs;
    final visible = _visibleOrgs;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 20),

          // Type Pills Row
          _buildTypePills(lang),
          const SizedBox(height: 16),

          // Search Row
          _buildSearchRow(lang),
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
              label: AppTranslations.pick(lang, en: 'organizations', mr: 'संस्था', hi: 'संगठन'),
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
                  const Icon(Icons.corporate_fare_rounded, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'NGO & Mandals Info',
                        mr: 'NGO व मंडळ माहिती',
                        hi: 'एनजीओ और मंडल जानकारी',
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
                  en: 'Directory of NGOs, sports clubs, festival organizations and community trusts',
                  mr: 'एनजीओ, क्रीडा क्लब, उत्सव मंडळे आणि सामाजिक संस्थांची निर्देशिका',
                  hi: 'एनजीओ, स्पोर्ट्स क्लब, उत्सव मंडलों और सामुदायिक ट्रस्टों की निर्देशिका',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions Row matching SocialOrganizations.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                SocialOrgReportGenerator.generateAndPrintReport(
                  context: context,
                  organizations: _filteredOrgs,
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
              onPressed: () => _showAddOrgModal(),
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
                      en: 'Add Organization',
                      mr: 'संस्था जोडा',
                      hi: 'संगठन जोड़ें',
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

  Widget _buildTypePills(String lang) {
    final types = [
      {'key': 'All', 'label': AppTranslations.getAll(lang)},
      {
        'key': 'ngo',
        'label': AppTranslations.pick(lang, en: 'NGO / Social Trust', mr: 'NGO / सामाजिक संस्था', hi: 'एनजीओ / सामाजिक ट्रस्ट'),
      },
      {
        'key': 'sports_cricket',
        'label': AppTranslations.pick(lang, en: 'Sports Club', mr: 'क्रीडा मंडळ', hi: 'स्पोर्ट्स क्लब'),
      },
      {
        'key': 'ganpati_mandal',
        'label': AppTranslations.pick(lang, en: 'Festival Committee', mr: 'उत्सव मंडळ', hi: 'उत्सव समिति'),
      },
      {
        'key': 'navratri_mandal',
        'label': AppTranslations.pick(lang, en: 'Cultural Association', mr: 'सांस्कृतिक मंडळ', hi: 'सांस्कृतिक संघ'),
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final key = t['key']!;
        final label = t['label']!;
        final isSelected = _selectedType == key;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedType = key;
              _displayedLimit = 20;
            });
            _fetchOrganizations();
          },
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0284C7) : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchRow(String lang) {
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
                  en: 'Search organization by name, president or area...',
                  mr: 'संस्थेचे नाव, अध्यक्ष किंवा परिसराने शोधा...',
                  hi: 'संगठन, अध्यक्ष या क्षेत्र के नाम से खोजें...',
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

        // Status Filter
        AppDropdown<String>(
          value: _statusFilter,
          height: 44,
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

  Widget _buildCardGrid(List<SocialOrganizationModel> items, String lang) {
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
            const Icon(Icons.corporate_fare_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No organizations found',
                mr: 'कोणत्याही संस्था आढळल्या नाहीत',
                hi: 'कोई संगठन नहीं मिला',
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
            mainAxisExtent: 250,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final estYearStr = AppTranslations.formatDigits(
              item.establishedYear.isNotEmpty ? item.establishedYear : '-',
              lang,
            );
            final membersStr = AppTranslations.formatDigits(item.membersCount, lang);

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
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Text(
                            _orgTypeLabel(item.type, lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Est: $estYearStr',
                          mr: 'स्थापना: $estYearStr',
                          hi: 'स्थापित: $estYearStr',
                        ),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  AppTranslatedText(
                    _orgNameFor(item, lang),
                    targetLanguage: lang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),

                  // Area
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppTranslatedText(
                          AppTranslations.getAreaName(item.area.isNotEmpty ? item.area : 'Ward 12', lang),
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // President
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.pick(lang, en: 'President: ', mr: 'अध्यक्ष: ', hi: 'अध्यक्ष: '),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      Flexible(
                        child: item.presidentName.trim().isNotEmpty
                            ? AppTranslatedText(
                                item.presidentName,
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
                      if (item.presidentMobile.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${AppTranslations.formatDigits(item.presidentMobile, lang)})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
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
                          AppTranslations.pick(
                            lang,
                            en: 'Members: $membersStr',
                            mr: 'सदस्य: $membersStr',
                            hi: 'सदस्य: $membersStr',
                          ),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                              onPressed: () => _showAddOrgModal(item: item),
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
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
