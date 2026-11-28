import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/sadasya_model.dart';
import '../../../../data/repositories/sadasya_repository.dart';
import '../../../screens/sadasya/sadasya_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopSadasyaView extends ConsumerStatefulWidget {
  const DesktopSadasyaView({super.key});

  @override
  ConsumerState<DesktopSadasyaView> createState() => _DesktopSadasyaViewState();
}

class _DesktopSadasyaViewState extends ConsumerState<DesktopSadasyaView> {
  bool _loading = true;
  List<SadasyaModel> _sadasyas = [];
  String _searchTerm = '';
  String _areaFilter = 'All';
  String _addressSearch = '';
  String _voterFilter = 'all'; // 'all', 'voter', 'non-voter'
  String _viewMode = 'grid'; // 'grid' | 'table'
  List<String> _availableAreas = [];
  int _displayedLimit = 20;

  List<SadasyaModel> get _visibleSadasyas =>
      _filteredSadasyas.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchSadasyas();
  }

  Future<void> _fetchSadasyas() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(sadasyaRepoProvider);
      final list = await repo.getSadasyas();
      if (mounted) {
        final areas = list.map((s) => s.area ?? '').where((a) => a.isNotEmpty).toSet().toList();
        setState(() {
          _sadasyas = list;
          _availableAreas = ['All', ...areas];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sadasyas = [];
          _loading = false;
        });
      }
    }
  }

  List<SadasyaModel> get _filteredSadasyas {
    final normSearch = AppTranslations.normalizeAsciiDigits(_searchTerm).toLowerCase();
    final normAddress = AppTranslations.normalizeAsciiDigits(_addressSearch).toLowerCase();
    return _sadasyas.where((s) {
      final matchesSearch = _searchTerm.isEmpty ||
          s.name.toLowerCase().contains(normSearch) ||
          (s.nameEnglish?.toLowerCase().contains(normSearch) ?? false) ||
          (s.nameMarathi?.toLowerCase().contains(normSearch) ?? false) ||
          AppTranslations.normalizeAsciiDigits(s.mobile).contains(normSearch) ||
          (s.voterId?.toLowerCase().contains(normSearch) ?? false);

      final matchesArea = _areaFilter == 'All' || (s.area ?? '').toLowerCase() == _areaFilter.toLowerCase();
      final matchesAddress = _addressSearch.isEmpty ||
          AppTranslations.normalizeAsciiDigits(s.displayAddress).toLowerCase().contains(normAddress) ||
          AppTranslations.normalizeAsciiDigits(s.address).toLowerCase().contains(normAddress) ||
          (s.addressEnglish != null &&
              AppTranslations.normalizeAsciiDigits(s.addressEnglish!).toLowerCase().contains(normAddress));

      bool matchesVoter = true;
      if (_voterFilter == 'voter') matchesVoter = s.isVoter;
      if (_voterFilter == 'non-voter') matchesVoter = !s.isVoter;

      return matchesSearch && matchesArea && matchesAddress && matchesVoter;
    }).toList();
  }

  void _showAddEditModal({SadasyaModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final mobileController = TextEditingController(text: item?.mobile ?? '');
    final ageController = TextEditingController(text: item != null && item.age > 0 ? item.age.toString() : '');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    final addressController = TextEditingController(text: item?.address ?? '');
    final roleController = TextEditingController(text: item?.role ?? 'Active Worker');
    bool isVoter = item?.isVoter ?? true;
    final voterIdController = TextEditingController(text: item?.voterId ?? '');

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
                    ? AppTranslations.pick(lang, en: 'Add Member', mr: 'सदस्य जोडा', hi: 'सदस्य जोड़ें')
                    : AppTranslations.pick(lang, en: 'Edit Member Details', mr: 'सदस्य माहिती संपादित करा', hi: 'सदस्य विवरण संपादित करें'),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Manage party members, active karyakartas and volunteers',
                  mr: 'पक्षाचे सदस्य, सक्रिय कार्यकर्ते आणि स्वयंसेवक व्यवस्थापित करा',
                  hi: 'पार्टी सदस्यों, सक्रिय कार्यकर्ताओं और स्वयंसेवकों को प्रबंधित करें',
                ),
                icon: Icons.people_alt_rounded,
                width: 600,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(ctx),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: item == null
                        ? AppTranslations.pick(lang, en: 'Add Member', mr: 'सदस्य जोडा', hi: 'सदस्य जोड़ें')
                        : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'परिवर्तन सहेजें'),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final cleanAge = AppTranslations.normalizeAsciiDigits(ageController.text.trim());
                      final cleanMobile = AppTranslations.normalizeAsciiDigits(mobileController.text.trim());
                      final newSadasya = SadasyaModel(
                        id: item?.id ?? 'sad-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        nameMarathi: item?.nameMarathi ?? nameController.text.trim(),
                        mobile: cleanMobile,
                        age: int.tryParse(cleanAge) ?? 0,
                        area: areaController.text.trim(),
                        address: addressController.text.trim(),
                        role: roleController.text.trim(),
                        isVoter: isVoter,
                        voterId: isVoter ? voterIdController.text.trim() : null,
                        registeredAt: item?.registeredAt ?? DateTime.now(),
                      );

                      final repo = ref.read(sadasyaRepoProvider);
                      if (item == null) {
                        await repo.addSadasya(newSadasya);
                      } else {
                        await repo.updateSadasya(newSadasya);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchSadasyas();
                    },
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      AppTranslations.pick(lang, en: 'Full Name *', mr: 'पूर्ण नाव *', hi: 'पूरा नाम *'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Rahul S. Patil...',
                          mr: 'उदा. राहुल सं. पाटील...',
                          hi: 'जैसे राहुल एस. पाटिल...',
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

                    // Mobile & Age
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Mobile *', mr: 'मोबाईल *', hi: 'मोबाइल *'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mobileController,
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Age', mr: 'वय', hi: 'आयु'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.formatDigits('32', lang),
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

                    // Area & Role
                    Row(
                      children: [
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
                                    en: 'e.g. Shastri Nagar',
                                    mr: 'उदा. शास्त्री नगर',
                                    hi: 'जैसे शास्त्री नगर',
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
                                AppTranslations.pick(lang, en: 'Role / Responsibility', mr: 'पद / जबाबदारी', hi: 'पद / जिम्मेदारी'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: roleController,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Booth In-charge',
                                    mr: 'उदा. बूथ प्रमुख',
                                    hi: 'जैसे बूथ प्रमुख',
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
                      AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Residential address and landmark...',
                          mr: 'निवासी पत्ता आणि जवळची खूण...',
                          hi: 'निवासी पता और नजदीकी पहचान...',
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

                    // Voter Checkbox & EPIC
                    Row(
                      children: [
                        Checkbox(
                          value: isVoter,
                          onChanged: (val) => setModalState(() => isVoter = val ?? true),
                          activeColor: const Color(0xFF0284C7),
                        ),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Is Registered Voter in Ward',
                            mr: 'प्रभागात नोंदणीकृत मतदार आहे का?',
                            hi: 'क्या वार्ड में पंजीकृत मतदाता हैं?',
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    if (isVoter) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: voterIdController,
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'EPIC No. (e.g. MH/12/345/678901)',
                            mr: 'मतदार ओळखपत्र क्र. (उदा. MH/12/345/678901)',
                            hi: 'ईपीआईसी नंबर (जैसे MH/12/345/678901)',
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(SadasyaModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppTranslations.pick(lang, en: 'Delete Member', mr: 'सदस्य हटवा', hi: 'सदस्य हटाएं'),
          ),
          content: AppTranslatedText(
            item.displayNameFor(lang),
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
                final repo = ref.read(sadasyaRepoProvider);
                await repo.deleteSadasya(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchSadasyas();
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
    final filtered = _filteredSadasyas;
    final visible = _visibleSadasyas;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 20),

          // Search and Filters Bar
          _buildFiltersBar(lang),
          const SizedBox(height: 24),

          // Content Grid or Table
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildReportTable(visible, lang)
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
              label: AppTranslations.pick(lang, en: 'members', mr: 'सदस्य', hi: 'सदस्य'),
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
                  const Icon(Icons.group_add_rounded, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Sadasya (Members)',
                      mr: 'सदस्य नोंदणी (Sadasya)',
                      hi: 'सदस्य (Sadasya)',
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
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
                  en: 'Registered party members, booth heads and active cadre directory',
                  mr: 'नोंदणीकृत पक्ष सदस्य, बूथ प्रमुख आणि सक्रिय कार्यकर्त्यांची यादी',
                  hi: 'पंजीकृत पार्टी सदस्यों, बूथ प्रमुखों और सक्रिय कार्यकर्ताओं की निर्देशिका',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions: Download Report + Add Member
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                SadasyaReportGenerator.generateAndPrintReport(
                  context: context,
                  members: _filteredSadasyas,
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
                    AppTranslations.pick(lang, en: 'Add Member', mr: 'सदस्य जोडा', hi: 'सदस्य जोड़ें'),
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

  Widget _buildFiltersBar(String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (val) => setState(() {
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search member by name, mobile, EPIC...',
                  mr: 'नाव, मोबाईल, EPIC क्र. ने सदस्य शोधा...',
                  hi: 'नाम, मोबाइल, ईपीआईसी से सदस्य खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Area Dropdown
          AppDropdown<String>(
            value: _areaFilter,
            height: 40,
            width: 155,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _availableAreas.map((a) {
              final label = a == 'All'
                  ? AppTranslations.getAllAreas(lang)
                  : AppTranslations.getAreaName(a, lang);
              return DropdownMenuItem(
                value: a,
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
          const SizedBox(width: 12),

          // Address Search Input
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (val) => setState(() {
                  _addressSearch = val;
                  _displayedLimit = 20;
                }),
                decoration: InputDecoration(
                  hintText: AppTranslations.pick(
                    lang,
                    en: 'Search Address...',
                    mr: 'पत्ता शोधा...',
                    hi: 'पता खोजें...',
                  ),
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.home_outlined, size: 18, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Voter Filter Dropdown
          AppDropdown<String>(
            value: _voterFilter,
            height: 40,
            width: 145,
            prefixIcon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: [
              DropdownMenuItem(value: 'all', child: Text(AppTranslations.getAll(lang))),
              DropdownMenuItem(
                value: 'voter',
                child: Text(AppTranslations.pick(lang, en: 'Voters', mr: 'मतदार', hi: 'मतदाता')),
              ),
              DropdownMenuItem(
                value: 'non-voter',
                child: Text(AppTranslations.pick(lang, en: 'Non-Voters', mr: 'बिगर-मतदार', hi: 'गैर-मतदाता')),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _voterFilter = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
          const SizedBox(width: 14),
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
                  label: AppTranslations.pick(lang, en: 'Grid', mr: 'ग्रिड', hi: 'ग्रिड'),
                  isActive: _viewMode == 'grid',
                  onTap: () => setState(() => _viewMode = 'grid'),
                ),
                const SizedBox(width: 4),
                _buildViewToggleButton(
                  icon: Icons.table_rows_rounded,
                  label: AppTranslations.pick(lang, en: 'Table', mr: 'तक्ता', hi: 'तालिका'),
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

  Widget _buildCardGrid(List<SadasyaModel> items, String lang) {
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
            const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No members found',
                mr: 'कोणतेही सदस्य सापडले नाहीत',
                hi: 'कोई सदस्य नहीं मिला',
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
            mainAxisExtent: 270,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final roleText = (item.role != null && item.role!.trim().isNotEmpty) ? item.role! : 'Active Worker';
            final areaRaw = (item.area != null && item.area!.trim().isNotEmpty) ? item.area! : 'Ward 12';
            final areaLabel = AppTranslations.getAreaName(areaRaw, lang);

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
                  // Top Avatar + Name + Status
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFF0F9FF),
                        child: Text(
                          item.initials,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1), fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              item.displayNameFor(lang),
                              isName: true,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            AppTranslatedText(
                              roleText,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isVoter ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          item.isVoter
                              ? AppTranslations.pick(lang, en: 'Voter', mr: 'मतदार', hi: 'मतदाता')
                              : AppTranslations.pick(lang, en: 'Non-Voter', mr: 'बिगर-मतदार', hi: 'गैर-मतदाता'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.isVoter ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mobile
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        AppTranslations.formatDigits(item.mobile, lang),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Area
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
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
                  const SizedBox(height: 6),

                  // Address
                  Expanded(
                    child: AppTranslatedText(
                      item.displayAddressFor(lang),
                      targetLanguage: lang,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.voterId != null && item.voterId!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Text(item.voterId!, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF475569))),
                          )
                        else
                          const SizedBox(),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                              onPressed: () => _showAddEditModal(item: item),
                              tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                              onPressed: () => _showDeleteConfirm(item),
                              tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
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

  Widget _buildReportTable(List<SadasyaModel> items, String lang) {
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
            const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No members found',
                mr: 'कोणतेही सदस्य सापडले नाहीत',
                hi: 'कोई सदस्य नहीं मिला',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columnSpacing: 24,
                horizontalMargin: 20,
                columns: [
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Member Name', mr: 'सदस्याचे नाव', hi: 'सदस्य का नाम'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'EPIC No.', mr: 'मतदार ओळखपत्र क्र.', hi: 'ईपीआईसी नंबर'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Actions', mr: 'कृती', hi: 'कार्रवाई'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
                rows: items.map((item) {
                  final roleText = (item.role != null && item.role!.trim().isNotEmpty) ? item.role! : 'Active Worker';
                  final hasArea = item.area != null && item.area!.trim().isNotEmpty;
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppTranslatedText(
                              item.displayNameFor(lang),
                              isName: true,
                              targetLanguage: lang,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            AppTranslatedText(
                              roleText,
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          AppTranslations.formatDigits(item.mobile, lang),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ),
                      DataCell(
                        hasArea
                            ? AppTranslatedText(
                                AppTranslations.getAreaName(item.area!, lang),
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              )
                            : const Text('-', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ),
                      DataCell(
                        AppTranslatedText(
                          item.displayAddressFor(lang),
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.voterId ?? '-',
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569)),
                        ),
                      ),
                      DataCell(
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
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
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
