<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/repositories/voters_repository.dart';
import '../../../screens/voters/voter_slip_generator.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../widgets/app_dropdown.dart';

class DesktopVotersView extends ConsumerStatefulWidget {
  const DesktopVotersView({super.key});

  @override
  ConsumerState<DesktopVotersView> createState() => _DesktopVotersViewState();
}

class _DesktopVotersViewState extends ConsumerState<DesktopVotersView> {
  bool _loading = true;
  List<VoterModel> _voters = [];
  int _totalCount = 0;
  int _currentPage = 1;
  static const int _pageSize = 24;

  String _searchQuery = '';
  String _addressFilter = '';
  String _houseNoFilter = '';
  String _casteFilter = '';
  String _selectedBooth = 'All';
  String _selectedFavour = 'All';
  String _selectedGender = 'All';
  String _selectedAgeRange = 'All';
  final bool _isFriendOnly = false;
  List<String> _availableBooths = [];
  String _viewMode = 'grid'; // 'grid' | 'table'

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _casteController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _casteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchBooths();
    _fetchVoters();
  }

  Future<void> _fetchBooths() async {
    try {
      final repo = ref.read(votersRepoProvider);
      final booths = await repo.getBoothsList();
      if (mounted) {
        setState(() {
          _availableBooths = ['All', ...booths];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchVoters() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(votersRepoProvider);
      final res = await repo.getPaginatedVoters(
        page: _currentPage,
        pageSize: _pageSize,
        query: AppTranslations.normalizeAsciiDigits(_searchQuery),
        boothFilter: _selectedBooth,
        favourFilter: _selectedFavour,
        genderFilter: _selectedGender,
        ageRangeFilter: _selectedAgeRange,
        addressFilter: AppTranslations.normalizeAsciiDigits(_addressFilter),
        houseNoFilter: AppTranslations.normalizeAsciiDigits(_houseNoFilter),
        casteFilter: _casteFilter,
        isFriendOnly: _isFriendOnly,
      );

      if (mounted) {
        setState(() {
          _voters = res.items;
          _totalCount = res.totalCount;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _voters = [];
          _loading = false;
        });
      }
    }
  }

  void _showAddVoterModal() {
    final currentLang = ref.read(desktopLanguageProvider);
    final nameMrController = TextEditingController();
    final nameEnController = TextEditingController();
    final epicController = TextEditingController();
    final boothController = TextEditingController(
      text: AppTranslations.formatDigits('12', currentLang),
    );
    final ageController = TextEditingController();
    final mobileController = TextEditingController();
    final addressController = TextEditingController();
    final houseNoController = TextEditingController();
    String gender = 'M';
    final String favour = 'Neutral';
    String? epicError;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final lang = dialogRef.watch(desktopLanguageProvider);
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return DesktopModalDialog(
                title: AppTranslations.pick(lang, en: 'Add Voter', mr: 'मतदार जोडा', hi: 'मतदाता जोड़ें'),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Register a new citizen in the ward voter registry',
                  mr: 'प्रभाग मतदार यादीत नवीन मतदाराची नोंदणी करा',
                  hi: 'वार्ड मतदाता सूची में नए मतदाता का पंजीकरण करें',
                ),
                icon: Icons.how_to_reg_rounded,
                width: 600,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(
                    ctx,
                    text: AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                  ),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: AppTranslations.pick(lang, en: 'Save Voter', mr: 'मतदार जतन करा', hi: 'मतदाता सहेजें'),
                    onPressed: () async {
                      if (epicController.text.trim().isEmpty) {
                        setModalState(() {
                          epicError = AppTranslations.pick(
                            lang,
                            en: 'Please enter EPIC number',
                            mr: 'कृपया ओळखपत्र क्रमांक (EPIC) प्रविष्ट करा',
                            hi: 'कृपया मतदाता पहचान पत्र क्रमांक (EPIC) दर्ज करें',
                          );
                        });
                        return;
                      }
                      final normalizedAge = AppTranslations.normalizeAsciiDigits(ageController.text.trim());
                      final normalizedMobile = AppTranslations.normalizeAsciiDigits(mobileController.text.trim());
                      final newVoter = VoterModel(
                        id: 'vot-${DateTime.now().millisecondsSinceEpoch}',
                        nameMarathi: nameMrController.text.trim().isNotEmpty
                            ? nameMrController.text.trim()
                            : nameEnController.text.trim(),
                        nameEnglish: nameEnController.text.trim().isNotEmpty
                            ? nameEnController.text.trim()
                            : nameMrController.text.trim(),
                        epicNo: AppTranslations.normalizeAsciiDigits(epicController.text.trim()),
                        booth: AppTranslations.normalizeAsciiDigits(boothController.text.trim()),
                        age: int.tryParse(normalizedAge) ?? 0,
                        gender: gender,
                        mobile: normalizedMobile.isNotEmpty ? normalizedMobile : null,
                        houseNo: houseNoController.text.trim().isNotEmpty
                            ? AppTranslations.normalizeAsciiDigits(houseNoController.text.trim())
                            : null,
                        address: addressController.text.trim(),
                        favour: favour,
                      );

                      final repo = ref.read(votersRepoProvider);
                      await repo.addVoter(newVoter);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchVoters();
                    },
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Names
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Voter Name *',
                                  mr: 'मतदाराचे नाव *',
                                  hi: 'मतदाता का नाम *',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameMrController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Ramesh P. Kadam',
                                    mr: 'उदा. रमेश पां. कदम',
                                    hi: 'उदा. रमेश पां. कदम',
                                  ),
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
                                  en: 'Name (English)',
                                  mr: 'नाव (इंग्रजी)',
                                  hi: 'नाम (अंग्रेज़ी)',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameEnController,
                                decoration: desktopInputDecoration(hintText: 'e.g. Ramesh Pandurang Kadam'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // EPIC & Booth
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'EPIC No. *',
                                  mr: 'ओळखपत्र क्र. (EPIC) *',
                                  hi: 'मतदाता पहचान पत्र क्र. *',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: epicController,
                                onChanged: (_) {
                                  if (epicError != null) {
                                    setModalState(() => epicError = null);
                                  }
                                },
                                decoration: desktopInputDecoration(
                                  hintText: 'ABC1234567',
                                  errorText: epicError,
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
                                AppTranslations.pick(lang, en: 'Booth No', mr: 'बूथ क्र.', hi: 'बूथ क्र.'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: boothController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(lang, en: 'e.g. 104', mr: 'उदा. १०४', hi: 'उदा. १०४'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Age, Gender, Mobile
                    Row(
                      children: [
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
                                decoration: desktopInputDecoration(hintText: AppTranslations.formatDigits('35', lang)),
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
                                AppTranslations.pick(lang, en: 'Gender', mr: 'लिंग', hi: 'लिंग'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              AppDropdown<String>(
                                value: gender,
                                height: 44,
                                backgroundColor: const Color(0xFFF8FAFC),
                                borderColor: const Color(0xFFE2E8F0),
                                items: [
                                  DropdownMenuItem(
                                    value: 'M',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(AppTranslations.getGender('M', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'F',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(AppTranslations.getGender('F', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'O',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(AppTranslations.getGender('O', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => gender = val);
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
                                AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mobileController,
                                keyboardType: TextInputType.phone,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.formatDigits('98XXXXXXXX', lang),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // House No & Address
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'House No', mr: 'घर क्र.', hi: 'मकान नं.'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: houseNoController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(lang, en: 'A-102', mr: 'ए-१०२', hi: 'ए-१०२'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: addressController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'Lane No. 3, Shaniwar Peth, Pune',
                                    mr: 'गल्ली क्र. ३, शनिवार पेठ, पुणे',
                                    hi: 'गली नं. ३, शनिवार पेठ, पुणे',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
          const SizedBox(height: 20),

          // Filters Row
          _buildFiltersRow(lang),
          const SizedBox(height: 24),

          // Grid or Table View
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildTableView(lang)
          else
            _buildGridView(lang),

          const SizedBox(height: 24),
          // Pagination Controls
          _buildPaginationControls(lang),
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    final formattedTotal = AppTranslations.formatDigits(_totalCount, lang);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search_rounded, size: 26, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Text(
                  AppTranslations.pick(lang, en: 'Voter Search', mr: 'मतदार शोध', hi: 'मतदाता खोज'),
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
                      en: 'Total: $formattedTotal',
                      mr: 'एकूण: $formattedTotal',
                      hi: 'कुल: $formattedTotal',
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
                en: 'Voter directory, polling booths, family trees and voting favor',
                mr: 'मतदार यादी, मतदान केंद्रे, कुटुंब वृक्ष आणि मतदार कल',
                hi: 'मतदाता सूची, मतदान केंद्र, परिवार वृक्ष और मतदाता रुझान',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Add Voter
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                VoterSlipGenerator.downloadVotersListReport(
                  context: context,
                  voters: _voters,
                  totalCount: _totalCount,
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

            // Add Voter
            ElevatedButton(
              onPressed: _showAddVoterModal,
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
                    AppTranslations.pick(lang, en: 'Add Voter', mr: 'मतदार जोडा', hi: 'मतदाता जोड़ें'),
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

  Widget _buildFiltersRow(String lang) {
    final searchTooltip = AppTranslations.pick(lang, en: 'Search', mr: 'शोधा', hi: 'खोजें');
    final clearTooltip = AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'साफ़ करें');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Text Filters (Name, Address, House No, Caste)
          Row(
            children: [
              // Search Name / EPIC / Mobile
              Expanded(
                flex: 3,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) {
                      _searchQuery = val;
                      _currentPage = 1;
                      _fetchVoters();
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Search voter by name, EPIC, mobile...',
                        mr: 'नाव, EPIC, मोबाईलद्वारे मतदार शोधा...',
                        hi: 'नाम, EPIC, मोबाइल से मतदाता खोजें...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        tooltip: searchTooltip,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                        onPressed: () {
                          _searchQuery = _searchController.text;
                          _currentPage = 1;
                          _fetchVoters();
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Address Filter
              Expanded(
                flex: 2,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _addressController,
                    onSubmitted: (val) {
                      _addressFilter = val;
                      _currentPage = 1;
                      _fetchVoters();
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Search Address...',
                        mr: 'पत्ता शोधा...',
                        hi: 'पता खोजें...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _addressFilter.isNotEmpty
                          ? IconButton(
                              tooltip: clearTooltip,
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _addressController.clear();
                                _addressFilter = '';
                                _currentPage = 1;
                                _fetchVoters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // House No Filter
              SizedBox(
                width: 130,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _houseNoController,
                    onSubmitted: (val) {
                      _houseNoFilter = val;
                      _currentPage = 1;
                      _fetchVoters();
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(lang, en: 'House No', mr: 'घर क्र.', hi: 'मकान नं.'),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.home_outlined, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _houseNoFilter.isNotEmpty
                          ? IconButton(
                              tooltip: clearTooltip,
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _houseNoController.clear();
                                _houseNoFilter = '';
                                _currentPage = 1;
                                _fetchVoters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Caste Filter
              Expanded(
                flex: 2,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _casteController,
                    onSubmitted: (val) {
                      _casteFilter = val;
                      _currentPage = 1;
                      _fetchVoters();
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Caste / Community...',
                        mr: 'जात / समाज...',
                        hi: 'जाति / समुदाय...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _casteFilter.isNotEmpty
                          ? IconButton(
                              tooltip: clearTooltip,
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _casteController.clear();
                                _casteFilter = '';
                                _currentPage = 1;
                                _fetchVoters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Dropdowns & View Mode
          Row(
            children: [
              // Booth Filter
              AppDropdown<String>(
                value: _selectedBooth,
                height: 40,
                width: 145,
                prefixIcon: const Icon(Icons.how_to_vote_outlined, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: _availableBooths.map((b) {
                  final label = b == 'All'
                      ? AppTranslations.pick(lang, en: 'All Booths', mr: 'सर्व बूथ', hi: 'सभी बूथ')
                      : AppTranslations.pick(
                          lang,
                          en: 'Booth ${AppTranslations.formatDigits(b, lang)}',
                          mr: 'बूथ ${AppTranslations.formatDigits(b, lang)}',
                          hi: 'बूथ ${AppTranslations.formatDigits(b, lang)}',
                        );
                  return DropdownMenuItem(
                    value: b,
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBooth = val);
                    _currentPage = 1;
                    _fetchVoters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Age Range Filter
              AppDropdown<String>(
                value: _selectedAgeRange,
                height: 40,
                width: 145,
                prefixIcon: const Icon(Icons.cake_outlined, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'All Ages', mr: 'सर्व वयोगट', hi: 'सभी आयु'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '18-25',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: '18 - 25 yrs', mr: '१८ - २५ वर्षे', hi: '१८ - २५ वर्ष'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '26-40',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: '26 - 40 yrs', mr: '२६ - ४० वर्षे', hi: '२६ - ४० वर्ष'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '41-60',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: '41 - 60 yrs', mr: '४१ - ६० वर्षे', hi: '४१ - ६० वर्ष'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '60+',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: '60+ yrs', mr: '६०+ वर्षे', hi: '६०+ वर्ष'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAgeRange = val);
                    _currentPage = 1;
                    _fetchVoters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Gender Filter
              AppDropdown<String>(
                value: _selectedGender,
                height: 40,
                width: 140,
                prefixIcon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'All Genders', mr: 'सर्व लिंग', hi: 'सभी लिंग'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'M',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(AppTranslations.getGender('M', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'F',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(AppTranslations.getGender('F', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'O',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(AppTranslations.getGender('O', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedGender = val);
                    _currentPage = 1;
                    _fetchVoters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Favour Filter
              AppDropdown<String>(
                value: _selectedFavour,
                height: 40,
                width: 150,
                prefixIcon: const Icon(Icons.sentiment_satisfied_alt_outlined, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'All Favour', mr: 'सर्व कल', hi: 'सभी रुझान'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Favourable',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'Favourable', mr: 'अनुकूल', hi: 'अनुकूल'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Neutral',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'Neutral', mr: 'तटस्थ', hi: 'तटस्थ'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Against',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'Against', mr: 'प्रतिकूल', hi: 'प्रतिकूल'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Swing',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'Swing', mr: 'अनिश्चित', hi: 'अनिश्चित'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedFavour = val);
                    _currentPage = 1;
                    _fetchVoters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Reset filters button
              InkWell(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _addressController.clear();
                    _houseNoController.clear();
                    _casteController.clear();
                    _searchQuery = '';
                    _addressFilter = '';
                    _houseNoFilter = '';
                    _casteFilter = '';
                    _selectedBooth = 'All';
                    _selectedAgeRange = 'All';
                    _selectedGender = 'All';
                    _selectedFavour = 'All';
                    _currentPage = 1;
                  });
                  _fetchVoters();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF475569)),
                      const SizedBox(width: 6),
                      Text(
                        AppTranslations.pick(lang, en: 'Reset', mr: 'रीसेट', hi: 'रीसेट'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // View Mode Toggle
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
        ],
      ),
    );
  }

  Widget _buildGridView(String lang) {
    if (_voters.isEmpty) {
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
            const Icon(Icons.how_to_reg_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No voters found matching criteria',
                mr: 'निकषांशी जुळणारे मतदार आढळले नाहीत',
                hi: 'मानदंडों से मेल खाने वाले कोई मतदाता नहीं मिले',
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
          itemCount: _voters.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 220,
          ),
          itemBuilder: (context, index) {
            final voter = _voters[index];
            final srText = voter.serialNo != null ? AppTranslations.formatDigits(voter.serialNo, lang) : '-';
            final boothText = AppTranslations.formatDigits(voter.booth, lang);
            final ageText = AppTranslations.formatDigits(voter.age, lang);
            final yrsLabel = AppTranslations.pick(lang, en: 'yrs', mr: 'वर्षे', hi: 'वर्ष');

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Name + Favour Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppTranslatedText(
                          voter.displayNameFor(lang),
                          isName: true,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _favourColor(voter.favour).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          voter.favourLabel(lang),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _favourColor(voter.favour)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // EPIC No & Serial
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text(voter.epicNo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF334155))),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Sr No: $srText',
                          mr: 'अनु. क्र.: $srText',
                          hi: 'क्र. सं.: $srText',
                        ),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const Spacer(),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Booth: $boothText',
                          mr: 'बूथ: $boothText',
                          hi: 'बूथ: $boothText',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Age, Gender, Mobile
                  Row(
                    children: [
                      Text(
                        '${voter.genderLabel(lang)} · $ageText $yrsLabel',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                      const Spacer(),
                      if (voter.mobile != null && voter.mobile!.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.formatDigits(voter.mobile!, lang),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Expanded(
                    child: AppTranslatedText(
                      voter.address,
                      targetLanguage: lang,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
                    ),
                  ),

                  // Quick favour toggle buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _favourButton(
                        AppTranslations.pick(lang, en: 'Favourable', mr: 'अनुकूल', hi: 'अनुकूल'),
                        'Favourable',
                        voter.id,
                        voter.favour == 'Favourable',
                      ),
                      const SizedBox(width: 6),
                      _favourButton(
                        AppTranslations.pick(lang, en: 'Neutral', mr: 'तटस्थ', hi: 'तटस्थ'),
                        'Neutral',
                        voter.id,
                        voter.favour == 'Neutral',
                      ),
                      const SizedBox(width: 6),
                      _favourButton(
                        AppTranslations.pick(lang, en: 'Against', mr: 'प्रतिकूल', hi: 'प्रतिकूल'),
                        'Against',
                        voter.id,
                        voter.favour == 'Against',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _favourButton(String label, String value, String voterId, bool isSelected) {
    return InkWell(
      onTap: () async {
        final repo = ref.read(votersRepoProvider);
        await repo.updateFavour(voterId, value);
        _fetchVoters();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? _favourColor(value) : Colors.transparent,
          border: Border.all(color: isSelected ? _favourColor(value) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Color _favourColor(String? favour) {
    switch (favour?.toLowerCase()) {
      case 'favourable':
        return const Color(0xFF16A34A);
      case 'against':
        return const Color(0xFFDC2626);
      case 'swing':
        return const Color(0xFFD97706);
      case 'neutral':
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildTableView(String lang) {
    if (_voters.isEmpty) {
      return _buildGridView(lang);
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
                      AppTranslations.pick(lang, en: 'Voter Name', mr: 'मतदाराचे नाव', hi: 'मतदाता का नाम'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'EPIC No.', mr: 'ओळखपत्र क्र.', hi: 'मतदाता कार्ड क्र.'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Age / Gender', mr: 'वय / लिंग', hi: 'आयु / लिंग'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Booth No', mr: 'बूथ क्र.', hi: 'बूथ क्र.'),
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
                      AppTranslations.pick(lang, en: 'Favour', mr: 'कल', hi: 'रुझान'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
                rows: _voters.map((v) {
                  return DataRow(
                    cells: [
                      DataCell(
                        AppTranslatedText(
                          v.displayNameFor(lang),
                          isName: true,
                          targetLanguage: lang,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ),
                      DataCell(Text(v.epicNo, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF334155)))),
                      DataCell(
                        Text(
                          '${AppTranslations.formatDigits(v.age, lang)} / ${v.genderLabel(lang)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                      DataCell(
                        Text(
                          AppTranslations.formatDigits(v.booth, lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: AppTranslatedText(
                            v.address,
                            targetLanguage: lang,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _favourColor(v.favour).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                          child: Text(v.favourLabel(lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _favourColor(v.favour))),
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

  Widget _buildPaginationControls(String lang) {
    final maxPages = (_totalCount / _pageSize).ceil();
    final pageText = AppTranslations.formatDigits(_currentPage, lang);
    final maxPagesText = AppTranslations.formatDigits(maxPages, lang);
    final totalText = AppTranslations.formatDigits(_totalCount, lang);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppTranslations.pick(
            lang,
            en: 'Page $pageText of $maxPagesText (Total $totalText voters)',
            mr: 'पान $pageText / $maxPagesText (एकूण $totalText मतदार)',
            hi: 'पृष्ठ $pageText / $maxPagesText (कुल $totalText मतदाता)',
          ),
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _currentPage > 1
                  ? () {
                      setState(() => _currentPage--);
                      _fetchVoters();
                    }
                  : null,
              child: Text(AppTranslations.pick(lang, en: 'Previous', mr: 'मागील', hi: 'पिछला')),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _currentPage < maxPages
                  ? () {
                      setState(() => _currentPage++);
                      _fetchVoters();
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              child: Text(
                AppTranslations.pick(lang, en: 'Next', mr: 'पुढील', hi: 'अगला'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
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
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 220,
          ),
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }
}
=======
import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/repositories/voters_repository.dart';
import '../../../screens/voters/voter_slip_generator.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../widgets/app_dropdown.dart';

class DesktopVotersView extends ConsumerStatefulWidget {
  const DesktopVotersView({super.key});

  @override
  ConsumerState<DesktopVotersView> createState() => _DesktopVotersViewState();
}

class _DesktopVotersViewState extends ConsumerState<DesktopVotersView> {
  bool _loading = true;
  List<VoterModel> _voters = [];
  int _totalCount = 0;
  int _currentPage = 1;
  static const int _pageSize = 24;

  String _searchQuery = '';
  String _addressFilter = '';
  String _houseNoFilter = '';
  String _casteFilter = '';
  String _selectedBooth = 'All';
  String _selectedFavour = 'All';
  String _selectedGender = 'All';
  String _selectedAgeRange = 'All';
  final bool _isFriendOnly = false;
  List<String> _availableBooths = [];
  String _viewMode = 'grid'; // 'grid' | 'table'

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _casteController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _casteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchBooths();
    _fetchVoters();
  }

  Future<void> _fetchBooths() async {
    try {
      final repo = ref.read(votersRepoProvider);
      final booths = await repo.getBoothsList();
      if (mounted) {
        setState(() {
          _availableBooths = ['All', ...booths];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchVoters() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(votersRepoProvider);
      final res = await repo.getPaginatedVoters(
        page: _currentPage,
        pageSize: _pageSize,
        query: AppTranslations.normalizeAsciiDigits(_searchQuery),
        boothFilter: _selectedBooth,
        favourFilter: _selectedFavour,
        genderFilter: _selectedGender,
        ageRangeFilter: _selectedAgeRange,
        addressFilter: AppTranslations.normalizeAsciiDigits(_addressFilter),
        houseNoFilter: AppTranslations.normalizeAsciiDigits(_houseNoFilter),
        casteFilter: _casteFilter,
        isFriendOnly: _isFriendOnly,
      );

      if (mounted) {
        setState(() {
          _voters = res.items;
          _totalCount = res.totalCount;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _voters = [];
          _loading = false;
        });
      }
    }
  }

  void _showAddVoterModal() {
    final currentLang = ref.read(desktopLanguageProvider);
    final nameMrController = TextEditingController();
    final nameEnController = TextEditingController();
    final epicController = TextEditingController();
    final boothController = TextEditingController(
      text: AppTranslations.formatDigits('12', currentLang),
    );
    final ageController = TextEditingController();
    final mobileController = TextEditingController();
    final addressController = TextEditingController();
    final houseNoController = TextEditingController();
    String gender = 'M';
    final String favour = 'Neutral';
    String? epicError;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final lang = dialogRef.watch(desktopLanguageProvider);
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return DesktopModalDialog(
                title: AppTranslations.pick(lang, en: 'Add Voter', mr: 'मतदार जोडा', hi: 'मतदाता जोड़ें'),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Register a new citizen in the ward voter registry',
                  mr: 'प्रभाग मतदार यादीत नवीन मतदाराची नोंदणी करा',
                  hi: 'वार्ड मतदाता सूची में नए मतदाता का पंजीकरण करें',
                ),
                icon: Icons.how_to_reg_rounded,
                width: 600,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(
                    ctx,
                    text: AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                  ),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: AppTranslations.pick(lang, en: 'Save Voter', mr: 'मतदार जतन करा', hi: 'मतदाता सहेजें'),
                    onPressed: () async {
                      if (epicController.text.trim().isEmpty) {
                        setModalState(() {
                          epicError = AppTranslations.pick(
                            lang,
                            en: 'Please enter EPIC number',
                            mr: 'कृपया ओळखपत्र क्रमांक (EPIC) प्रविष्ट करा',
                            hi: 'कृपया मतदाता पहचान पत्र क्रमांक (EPIC) दर्ज करें',
                          );
                        });
                        return;
                      }
                      final normalizedAge = AppTranslations.normalizeAsciiDigits(ageController.text.trim());
                      final normalizedMobile = AppTranslations.normalizeAsciiDigits(mobileController.text.trim());
                      final newVoter = VoterModel(
                        id: 'vot-${DateTime.now().millisecondsSinceEpoch}',
                        nameMarathi: nameMrController.text.trim().isNotEmpty
                            ? nameMrController.text.trim()
                            : nameEnController.text.trim(),
                        nameEnglish: nameEnController.text.trim().isNotEmpty
                            ? nameEnController.text.trim()
                            : nameMrController.text.trim(),
                        epicNo: AppTranslations.normalizeAsciiDigits(epicController.text.trim()),
                        booth: AppTranslations.normalizeAsciiDigits(boothController.text.trim()),
                        age: int.tryParse(normalizedAge) ?? 0,
                        gender: gender,
                        mobile: normalizedMobile.isNotEmpty ? normalizedMobile : null,
                        houseNo: houseNoController.text.trim().isNotEmpty
                            ? AppTranslations.normalizeAsciiDigits(houseNoController.text.trim())
                            : null,
                        address: addressController.text.trim(),
                        favour: favour,
                      );

                      final repo = ref.read(votersRepoProvider);
                      await repo.addVoter(newVoter);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchVoters();
                    },
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Names
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Voter Name *',
                                  mr: 'मतदाराचे नाव *',
                                  hi: 'मतदाता का नाम *',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameMrController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Ramesh P. Kadam',
                                    mr: 'उदा. रमेश पां. कदम',
                                    hi: 'उदा. रमेश पां. कदम',
                                  ),
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
                                  en: 'Name (English)',
                                  mr: 'नाव (इंग्रजी)',
                                  hi: 'नाम (अंग्रेज़ी)',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameEnController,
                                decoration: desktopInputDecoration(hintText: 'e.g. Ramesh Pandurang Kadam'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // EPIC & Booth
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'EPIC No. *',
                                  mr: 'ओळखपत्र क्र. (EPIC) *',
                                  hi: 'मतदाता पहचान पत्र क्र. *',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: epicController,
                                onChanged: (_) {
                                  if (epicError != null) {
                                    setModalState(() => epicError = null);
                                  }
                                },
                                decoration: desktopInputDecoration(
                                  hintText: 'ABC1234567',
                                  errorText: epicError,
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
                                AppTranslations.pick(lang, en: 'Booth No', mr: 'बूथ क्र.', hi: 'बूथ क्र.'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: boothController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(lang, en: 'e.g. 104', mr: 'उदा. १०४', hi: 'उदा. १०४'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Age, Gender, Mobile
                    Row(
                      children: [
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
                                decoration: desktopInputDecoration(hintText: AppTranslations.formatDigits('35', lang)),
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
                                AppTranslations.pick(lang, en: 'Gender', mr: 'लिंग', hi: 'लिंग'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              AppDropdown<String>(
                                value: gender,
                                height: 44,
                                backgroundColor: const Color(0xFFF8FAFC),
                                borderColor: const Color(0xFFE2E8F0),
                                items: [
                                  DropdownMenuItem(
                                    value: 'M',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(AppTranslations.getGender('M', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'F',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(AppTranslations.getGender('F', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'O',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(AppTranslations.getGender('O', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => gender = val);
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
                                AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mobileController,
                                keyboardType: TextInputType.phone,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.formatDigits('98XXXXXXXX', lang),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // House No & Address
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'House No', mr: 'घर क्र.', hi: 'मकान नं.'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: houseNoController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(lang, en: 'A-102', mr: 'ए-१०२', hi: 'ए-१०२'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: addressController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'Lane No. 3, Shaniwar Peth, Pune',
                                    mr: 'गल्ली क्र. ३, शनिवार पेठ, पुणे',
                                    hi: 'गली नं. ३, शनिवार पेठ, पुणे',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
          const SizedBox(height: 20),

          // Filters Row
          _buildFiltersRow(lang),
          const SizedBox(height: 24),

          // Grid or Table View
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildTableView(lang)
          else
            _buildGridView(lang),

          const SizedBox(height: 24),
          // Pagination Controls
          _buildPaginationControls(lang),
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    final formattedTotal = AppTranslations.formatDigits(_totalCount, lang);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppTranslations.pick(lang, en: 'Voter Search', mr: 'मतदार शोध', hi: 'मतदाता खोज'),
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
                      en: 'Total: $formattedTotal',
                      mr: 'एकूण: $formattedTotal',
                      hi: 'कुल: $formattedTotal',
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
                en: 'Voter directory, polling booths, family trees and voting favor',
                mr: 'मतदार यादी, मतदान केंद्रे, कुटुंब वृक्ष आणि मतदार कल',
                hi: 'मतदाता सूची, मतदान केंद्र, परिवार वृक्ष और मतदाता रुझान',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Add Voter
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                VoterSlipGenerator.downloadVotersListReport(
                  context: context,
                  voters: _voters,
                  totalCount: _totalCount,
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

            // Add Voter
            ElevatedButton(
              onPressed: _showAddVoterModal,
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
                    AppTranslations.pick(lang, en: 'Add Voter', mr: 'मतदार जोडा', hi: 'मतदाता जोड़ें'),
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

  Widget _buildFiltersRow(String lang) {
    final searchTooltip = AppTranslations.pick(lang, en: 'Search', mr: 'शोधा', hi: 'खोजें');
    final clearTooltip = AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'साफ़ करें');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Text Filters (Name, Address, House No, Caste)
          Row(
            children: [
              // Search Name / EPIC / Mobile
              Expanded(
                flex: 3,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) {
                      _searchQuery = val;
                      _currentPage = 1;
                      _fetchVoters();
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Search voter by name, EPIC, mobile...',
                        mr: 'नाव, EPIC, मोबाईलद्वारे मतदार शोधा...',
                        hi: 'नाम, EPIC, मोबाइल से मतदाता खोजें...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        tooltip: searchTooltip,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                        onPressed: () {
                          _searchQuery = _searchController.text;
                          _currentPage = 1;
                          _fetchVoters();
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Address Filter
              Expanded(
                flex: 2,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _addressController,
                    onSubmitted: (val) {
                      _addressFilter = val;
                      _currentPage = 1;
                      _fetchVoters();
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Search Address...',
                        mr: 'पत्ता शोधा...',
                        hi: 'पता खोजें...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _addressFilter.isNotEmpty
                          ? IconButton(
                              tooltip: clearTooltip,
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _addressController.clear();
                                _addressFilter = '';
                                _currentPage = 1;
                                _fetchVoters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // House No Filter
              SizedBox(
                width: 130,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _houseNoController,
                    onSubmitted: (val) {
                      _houseNoFilter = val;
                      _currentPage = 1;
                      _fetchVoters();
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(lang, en: 'House No', mr: 'घर क्र.', hi: 'मकान नं.'),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.home_outlined, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _houseNoFilter.isNotEmpty
                          ? IconButton(
                              tooltip: clearTooltip,
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _houseNoController.clear();
                                _houseNoFilter = '';
                                _currentPage = 1;
                                _fetchVoters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Caste Filter
              Expanded(
                flex: 2,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _casteController,
                    onSubmitted: (val) {
                      _casteFilter = val;
                      _currentPage = 1;
                      _fetchVoters();
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Caste / Community...',
                        mr: 'जात / समाज...',
                        hi: 'जाति / समुदाय...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _casteFilter.isNotEmpty
                          ? IconButton(
                              tooltip: clearTooltip,
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _casteController.clear();
                                _casteFilter = '';
                                _currentPage = 1;
                                _fetchVoters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Dropdowns & View Mode
          Row(
            children: [
              // Booth Filter
              AppDropdown<String>(
                value: _selectedBooth,
                height: 40,
                width: 145,
                prefixIcon: const Icon(Icons.how_to_vote_outlined, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: _availableBooths.map((b) {
                  final label = b == 'All'
                      ? AppTranslations.pick(lang, en: 'All Booths', mr: 'सर्व बूथ', hi: 'सभी बूथ')
                      : AppTranslations.pick(
                          lang,
                          en: 'Booth ${AppTranslations.formatDigits(b, lang)}',
                          mr: 'बूथ ${AppTranslations.formatDigits(b, lang)}',
                          hi: 'बूथ ${AppTranslations.formatDigits(b, lang)}',
                        );
                  return DropdownMenuItem(
                    value: b,
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBooth = val);
                    _currentPage = 1;
                    _fetchVoters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Age Range Filter
              AppDropdown<String>(
                value: _selectedAgeRange,
                height: 40,
                width: 145,
                prefixIcon: const Icon(Icons.cake_outlined, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'All Ages', mr: 'सर्व वयोगट', hi: 'सभी आयु'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '18-25',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: '18 - 25 yrs', mr: '१८ - २५ वर्षे', hi: '१८ - २५ वर्ष'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '26-40',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: '26 - 40 yrs', mr: '२६ - ४० वर्षे', hi: '२६ - ४० वर्ष'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '41-60',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: '41 - 60 yrs', mr: '४१ - ६० वर्षे', hi: '४१ - ६० वर्ष'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '60+',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: '60+ yrs', mr: '६०+ वर्षे', hi: '६०+ वर्ष'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAgeRange = val);
                    _currentPage = 1;
                    _fetchVoters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Gender Filter
              AppDropdown<String>(
                value: _selectedGender,
                height: 40,
                width: 140,
                prefixIcon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'All Genders', mr: 'सर्व लिंग', hi: 'सभी लिंग'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'M',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(AppTranslations.getGender('M', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'F',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(AppTranslations.getGender('F', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'O',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(AppTranslations.getGender('O', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedGender = val);
                    _currentPage = 1;
                    _fetchVoters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Favour Filter
              AppDropdown<String>(
                value: _selectedFavour,
                height: 40,
                width: 150,
                prefixIcon: const Icon(Icons.sentiment_satisfied_alt_outlined, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'All Favour', mr: 'सर्व कल', hi: 'सभी रुझान'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Favourable',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'Favourable', mr: 'अनुकूल', hi: 'अनुकूल'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Neutral',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'Neutral', mr: 'तटस्थ', hi: 'तटस्थ'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Against',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'Against', mr: 'प्रतिकूल', hi: 'प्रतिकूल'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Swing',
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppTranslations.pick(lang, en: 'Swing', mr: 'अनिश्चित', hi: 'अनिश्चित'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedFavour = val);
                    _currentPage = 1;
                    _fetchVoters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Reset filters button
              InkWell(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _addressController.clear();
                    _houseNoController.clear();
                    _casteController.clear();
                    _searchQuery = '';
                    _addressFilter = '';
                    _houseNoFilter = '';
                    _casteFilter = '';
                    _selectedBooth = 'All';
                    _selectedAgeRange = 'All';
                    _selectedGender = 'All';
                    _selectedFavour = 'All';
                    _currentPage = 1;
                  });
                  _fetchVoters();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF475569)),
                      const SizedBox(width: 6),
                      Text(
                        AppTranslations.pick(lang, en: 'Reset', mr: 'रीसेट', hi: 'रीसेट'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // View Mode Toggle
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
        ],
      ),
    );
  }

  Widget _buildGridView(String lang) {
    if (_voters.isEmpty) {
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
            const Icon(Icons.how_to_reg_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No voters found matching criteria',
                mr: 'निकषांशी जुळणारे मतदार आढळले नाहीत',
                hi: 'मानदंडों से मेल खाने वाले कोई मतदाता नहीं मिले',
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
          itemCount: _voters.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 220,
          ),
          itemBuilder: (context, index) {
            final voter = _voters[index];
            final srText = voter.serialNo != null ? AppTranslations.formatDigits(voter.serialNo, lang) : '-';
            final boothText = AppTranslations.formatDigits(voter.booth, lang);
            final ageText = AppTranslations.formatDigits(voter.age, lang);
            final yrsLabel = AppTranslations.pick(lang, en: 'yrs', mr: 'वर्षे', hi: 'वर्ष');

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Name + Favour Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppTranslatedText(
                          voter.displayNameFor(lang),
                          isName: true,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _favourColor(voter.favour).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          voter.favourLabel(lang),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _favourColor(voter.favour)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // EPIC No & Serial
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text(voter.epicNo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF334155))),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Sr No: $srText',
                          mr: 'अनु. क्र.: $srText',
                          hi: 'क्र. सं.: $srText',
                        ),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const Spacer(),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Booth: $boothText',
                          mr: 'बूथ: $boothText',
                          hi: 'बूथ: $boothText',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Age, Gender, Mobile
                  Row(
                    children: [
                      Text(
                        '${voter.genderLabel(lang)} · $ageText $yrsLabel',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                      const Spacer(),
                      if (voter.mobile != null && voter.mobile!.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.formatDigits(voter.mobile!, lang),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Expanded(
                    child: AppTranslatedText(
                      voter.address,
                      targetLanguage: lang,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
                    ),
                  ),

                  // Quick favour toggle buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _favourButton(
                        AppTranslations.pick(lang, en: 'Favourable', mr: 'अनुकूल', hi: 'अनुकूल'),
                        'Favourable',
                        voter.id,
                        voter.favour == 'Favourable',
                      ),
                      const SizedBox(width: 6),
                      _favourButton(
                        AppTranslations.pick(lang, en: 'Neutral', mr: 'तटस्थ', hi: 'तटस्थ'),
                        'Neutral',
                        voter.id,
                        voter.favour == 'Neutral',
                      ),
                      const SizedBox(width: 6),
                      _favourButton(
                        AppTranslations.pick(lang, en: 'Against', mr: 'प्रतिकूल', hi: 'प्रतिकूल'),
                        'Against',
                        voter.id,
                        voter.favour == 'Against',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _favourButton(String label, String value, String voterId, bool isSelected) {
    return InkWell(
      onTap: () async {
        final repo = ref.read(votersRepoProvider);
        await repo.updateFavour(voterId, value);
        _fetchVoters();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? _favourColor(value) : Colors.transparent,
          border: Border.all(color: isSelected ? _favourColor(value) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Color _favourColor(String? favour) {
    switch (favour?.toLowerCase()) {
      case 'favourable':
        return const Color(0xFF16A34A);
      case 'against':
        return const Color(0xFFDC2626);
      case 'swing':
        return const Color(0xFFD97706);
      case 'neutral':
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildTableView(String lang) {
    if (_voters.isEmpty) {
      return _buildGridView(lang);
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
                      AppTranslations.pick(lang, en: 'Voter Name', mr: 'मतदाराचे नाव', hi: 'मतदाता का नाम'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'EPIC No.', mr: 'ओळखपत्र क्र.', hi: 'मतदाता कार्ड क्र.'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Age / Gender', mr: 'वय / लिंग', hi: 'आयु / लिंग'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Booth No', mr: 'बूथ क्र.', hi: 'बूथ क्र.'),
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
                      AppTranslations.pick(lang, en: 'Favour', mr: 'कल', hi: 'रुझान'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
                rows: _voters.map((v) {
                  return DataRow(
                    cells: [
                      DataCell(
                        AppTranslatedText(
                          v.displayNameFor(lang),
                          isName: true,
                          targetLanguage: lang,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ),
                      DataCell(Text(v.epicNo, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF334155)))),
                      DataCell(
                        Text(
                          '${AppTranslations.formatDigits(v.age, lang)} / ${v.genderLabel(lang)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                      DataCell(
                        Text(
                          AppTranslations.formatDigits(v.booth, lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: AppTranslatedText(
                            v.address,
                            targetLanguage: lang,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _favourColor(v.favour).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                          child: Text(v.favourLabel(lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _favourColor(v.favour))),
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

  Widget _buildPaginationControls(String lang) {
    final maxPages = (_totalCount / _pageSize).ceil();
    final pageText = AppTranslations.formatDigits(_currentPage, lang);
    final maxPagesText = AppTranslations.formatDigits(maxPages, lang);
    final totalText = AppTranslations.formatDigits(_totalCount, lang);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppTranslations.pick(
            lang,
            en: 'Page $pageText of $maxPagesText (Total $totalText voters)',
            mr: 'पान $pageText / $maxPagesText (एकूण $totalText मतदार)',
            hi: 'पृष्ठ $pageText / $maxPagesText (कुल $totalText मतदाता)',
          ),
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _currentPage > 1
                  ? () {
                      setState(() => _currentPage--);
                      _fetchVoters();
                    }
                  : null,
              child: Text(AppTranslations.pick(lang, en: 'Previous', mr: 'मागील', hi: 'पिछला')),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _currentPage < maxPages
                  ? () {
                      setState(() => _currentPage++);
                      _fetchVoters();
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              child: Text(
                AppTranslations.pick(lang, en: 'Next', mr: 'पुढील', hi: 'अगला'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
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
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 220,
          ),
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }
}
>>>>>>> 17bec4832fa7973ec0a7a95e6bdb86fded9bbc1c
