import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/government_office_model.dart';
import '../../../../data/repositories/government_office_repository.dart';
import '../../../screens/government_office/gov_office_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopGovernmentOfficeView extends ConsumerStatefulWidget {
  const DesktopGovernmentOfficeView({super.key});

  @override
  ConsumerState<DesktopGovernmentOfficeView> createState() => _DesktopGovernmentOfficeViewState();
}

class _DesktopGovernmentOfficeViewState extends ConsumerState<DesktopGovernmentOfficeView> {
  bool _loading = true;
  List<GovernmentOfficeModel> _offices = [];
  String _searchTerm = '';
  int _displayedLimit = 20;

  List<GovernmentOfficeModel> get _visibleOffices =>
      _filteredOffices.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchOffices();
  }

  Future<void> _fetchOffices() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(governmentOfficeRepoProvider);
      final list = await repo.getOffices();
      if (mounted) {
        setState(() {
          _offices = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _offices = [];
          _loading = false;
        });
      }
    }
  }

  List<GovernmentOfficeModel> get _filteredOffices {
    final q = AppTranslations.normalizeAsciiDigits(_searchTerm.trim()).toLowerCase();
    return _offices.where((o) {
      final matchesSearch = q.isEmpty ||
          o.name.toLowerCase().contains(q) ||
          o.officerName.toLowerCase().contains(q) ||
          o.area.toLowerCase().contains(q) ||
          o.category.toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(o.contactNumber).toLowerCase().contains(q);

      return matchesSearch;
    }).toList();
  }

  String? _knownCategoryLabel(String category, String lang) {
    switch (category.trim().toLowerCase()) {
      case 'municipal pmc':
        return AppTranslations.pick(
          lang,
          en: 'Municipal Corporation (PMC)',
          mr: 'महानगरपालिका (PMC)',
          hi: 'नगर निगम (PMC)',
        );
      case 'police':
        return AppTranslations.pick(lang, en: 'Police Station', mr: 'पोलीस स्टेशन', hi: 'पुलिस स्टेशन');
      case 'msedcl electricity':
        return AppTranslations.pick(
          lang,
          en: 'MSEDCL Electricity',
          mr: 'महावितरण (वीज विभाग)',
          hi: 'महावितरण (बिजली विभाग)',
        );
      case 'water supply':
        return AppTranslations.pick(
          lang,
          en: 'Water Supply Department',
          mr: 'पाणी पुरवठा विभाग',
          hi: 'जल आपूर्ति विभाग',
        );
      case 'health & hospital':
        return AppTranslations.pick(
          lang,
          en: 'Health & Hospital',
          mr: 'आरोग्य व रुग्णालय',
          hi: 'स्वास्थ्य एवं अस्पताल',
        );
      case 'fire & disaster':
        return AppTranslations.pick(
          lang,
          en: 'Fire & Disaster Response',
          mr: 'अग्निशमन व आपत्ती व्यवस्थापन',
          hi: 'अग्निशमन एवं आपदा प्रबंधन',
        );
      case 'revenue & post':
        return AppTranslations.pick(
          lang,
          en: 'Revenue & Post',
          mr: 'महसूल व टपाल',
          hi: 'राजस्व एवं डाक',
        );
      default:
        return null;
    }
  }

  void _showAddOfficeModal() {
    final nameController = TextEditingController();
    final officerController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();
    final areaController = TextEditingController(text: 'Ward 12');
    String selectedCategory = 'Municipal PMC';
    bool isEmergency = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            return DesktopModalDialog(
              title: AppTranslations.pick(
                lang,
                en: 'Add Government Office',
                mr: 'शासकीय कार्यालय जोडा',
                hi: 'सरकारी कार्यालय जोड़ें',
              ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Directory of public and civic administrative offices',
                mr: 'सार्वजनिक आणि नागरी प्रशासकीय कार्यालयांची निर्देशिका',
                hi: 'सार्वजनिक और नागरिक प्रशासनिक कार्यालयों की निर्देशिका',
              ),
              icon: Icons.account_balance_rounded,
              width: 600,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(ctx),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: AppTranslations.pick(lang, en: 'Save Office', mr: 'कार्यालय जतन करा', hi: 'कार्यालय सहेजें'),
                  onPressed: () async {
                    final normalizedContact = AppTranslations.normalizeAsciiDigits(contactController.text.trim());
                    if (nameController.text.trim().isEmpty || normalizedContact.isEmpty) return;
                    final newOffice = GovernmentOfficeModel(
                      id: 'office-${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text.trim(),
                      officerName: officerController.text.trim().isEmpty
                          ? 'Officer In-Charge'
                          : officerController.text.trim(),
                      contactNumber: normalizedContact,
                      address: addressController.text.trim(),
                      area: areaController.text.trim().isEmpty ? 'Ward 12' : areaController.text.trim(),
                      category: selectedCategory,
                      isEmergency: isEmergency,
                      createdAt: DateTime.now().toIso8601String(),
                    );

                    final repo = ref.read(governmentOfficeRepoProvider);
                    await repo.addOffice(newOffice);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchOffices();
                  },
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Office Name
                  Text(
                    AppTranslations.pick(lang, en: 'Office Name *', mr: 'कार्यालयाचे नाव *', hi: 'कार्यालय का नाम *'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Municipal Ward Office No. 12',
                        mr: 'उदा. महानगरपालिका प्रभाग कार्यालय क्र. १२',
                        hi: 'जैसे नगर निगम वार्ड कार्यालय क्र. १२',
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

                  // Category & Area
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Department / Category *',
                                mr: 'विभाग / प्रकार *',
                                hi: 'विभाग / श्रेणी *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              value: selectedCategory,
                              height: 44,
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFFE2E8F0),
                              items: [
                                DropdownMenuItem(value: 'Municipal PMC', child: Text(_knownCategoryLabel('Municipal PMC', lang)!)),
                                DropdownMenuItem(value: 'Police', child: Text(_knownCategoryLabel('Police', lang)!)),
                                DropdownMenuItem(value: 'MSEDCL Electricity', child: Text(_knownCategoryLabel('MSEDCL Electricity', lang)!)),
                                DropdownMenuItem(value: 'Water Supply', child: Text(_knownCategoryLabel('Water Supply', lang)!)),
                                DropdownMenuItem(value: 'Health & Hospital', child: Text(_knownCategoryLabel('Health & Hospital', lang)!)),
                                DropdownMenuItem(value: 'Fire & Disaster', child: Text(_knownCategoryLabel('Fire & Disaster', lang)!)),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedCategory = val);
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

                  // Officer Name & Contact
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Officer In-Charge *',
                                mr: 'प्रमुख अधिकारी *',
                                hi: 'प्रभारी अधिकारी *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: officerController,
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Mr. R. K. Patil',
                                  mr: 'उदा. श्री. आर. के. पाटील',
                                  hi: 'जैसे श्री आर. के. पाटिल',
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
                                en: 'Contact Number *',
                                mr: 'संपर्क क्रमांक *',
                                hi: 'संपर्क नंबर *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: contactController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. 020-25501000',
                                  mr: 'उदा. ०२०-२५५०१०००',
                                  hi: 'जैसे ०२०-२५५०१०००',
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

                  // Address
                  Text(
                    AppTranslations.pick(lang, en: 'Address *', mr: 'पत्ता *', hi: 'पता *'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Full office address...',
                        mr: 'कार्यालयाचा पूर्ण पत्ता...',
                        hi: 'कार्यालय का पूरा पता...',
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

                  // Emergency Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: isEmergency,
                        onChanged: (val) => setModalState(() => isEmergency = val ?? false),
                      ),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Emergency Service',
                          mr: 'अत्यावश्यक सेवा',
                          hi: 'आपातकालीन सेवा',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirm(GovernmentOfficeModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppTranslations.pick(lang, en: 'Delete Office', mr: 'कार्यालय हटवा', hi: 'कार्यालय हटाएं')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Are you sure you want to delete this office?',
                  mr: 'तुम्हाला खात्री आहे की तुम्ही हे कार्यालय हटवू इच्छिता?',
                  hi: 'क्या आप वाकई इस कार्यालय को हटाना चाहते हैं?',
                ),
              ),
              const SizedBox(height: 6),
              AppTranslatedText(
                item.name,
                targetLanguage: lang,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                final repo = ref.read(governmentOfficeRepoProvider);
                await repo.deleteOffice(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchOffices();
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
    final filtered = _filteredOffices;
    final visible = _visibleOffices;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
          const SizedBox(height: 20),

          // Search Bar
          _buildSearchBar(lang),
          const SizedBox(height: 24),

          // Content Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildOfficeGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: 'offices',
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_outlined, size: 26, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Government Offices',
                    mr: 'शासकीय कार्यालये',
                    hi: 'सरकारी कार्यालय',
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.pick(
                lang,
                en: 'Government departments, officers in-charge and emergency contact numbers',
                mr: 'शासकीय विभाग, प्रभारी अधिकारी आणि तातडीचे संपर्क क्रमांक',
                hi: 'सरकारी विभाग, प्रभारी अधिकारी और आपातकालीन संपर्क नंबर',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                GovOfficeReportGenerator.generateAndPrintOfficeReport(
                  context: context,
                  offices: _filteredOffices,
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
            const SizedBox(width: 12),

            // Add Office (ns-btn-primary matching GovtOffices.tsx)
            ElevatedButton(
              onPressed: _showAddOfficeModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), // bg-brand-600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // rounded-xl
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white), // Plus w-4 h-4
                  const SizedBox(width: 8), // gap-2
                  Text(
                    AppTranslations.pick(lang, en: 'Add Office', mr: 'कार्यालय जोडा', hi: 'कार्यालय जोड़ें'),
                    style: const TextStyle(
                      fontSize: 14, // text-sm
                      fontWeight: FontWeight.w600, // font-semibold
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

  Widget _buildSearchBar(String lang) {
    return Container(
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
            en: 'Search office by name, department, officer or area...',
            mr: 'नाव, विभाग, अधिकारी किंवा परिसरानुसार कार्यालय शोधा...',
            hi: 'नाम, विभाग, अधिकारी या क्षेत्र के अनुसार कार्यालय खोजें...',
          ),
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  tooltip: AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'साफ़ करें'),
                  onPressed: () => setState(() => _searchTerm = ''),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildOfficeGrid(List<GovernmentOfficeModel> items, String lang) {
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
            const Icon(Icons.business_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No offices found',
                mr: 'कोणतेही कार्यालय आढळले नाही',
                hi: 'कोई कार्यालय नहीं मिला',
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
            final knownCat = _knownCategoryLabel(item.category, lang);
            final catStyle = TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: item.isEmergency ? const Color(0xFFB91C1C) : const Color(0xFF0369A1),
            );
            final isDefaultOfficer =
                item.officerName.trim().toLowerCase() == 'officer in-charge';

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
                  // Top Row: Category badge & Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.isEmergency ? const Color(0xFFFEF2F2) : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: item.isEmergency ? const Color(0xFFFECACA) : const Color(0xFFBAE6FD)),
                          ),
                          child: knownCat != null
                              ? Text(knownCat, maxLines: 1, overflow: TextOverflow.ellipsis, style: catStyle)
                              : AppTranslatedText(item.category, targetLanguage: lang, maxLines: 1, overflow: TextOverflow.ellipsis, style: catStyle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: AppTranslatedText(
                          AppTranslations.getAreaName(item.area, lang),
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Office Name
                  AppTranslatedText(
                    item.name,
                    targetLanguage: lang,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                  ),
                  const SizedBox(height: 12),

                  // Officer In-Charge
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: isDefaultOfficer
                            ? Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Officer In-Charge',
                                  mr: 'प्रभारी अधिकारी',
                                  hi: 'प्रभारी अधिकारी',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              )
                            : AppTranslatedText(
                                item.officerName,
                                isName: true,
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AppTranslatedText(
                          item.address,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Bottom Action: Call button & Delete
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () async {
                            final asciiPhone = AppTranslations.normalizeAsciiDigits(item.contactNumber);
                            final uri = Uri.parse('tel:$asciiPhone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, size: 13, color: Color(0xFF16A34A)),
                                const SizedBox(width: 6),
                                Text(
                                  AppTranslations.formatDigits(item.contactNumber, lang),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                          onPressed: () => _showDeleteConfirm(item),
                          tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
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
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
