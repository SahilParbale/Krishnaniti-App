import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../shell/desktop_sidebar.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/team_model.dart';
import '../../../../data/repositories/team_repository.dart';
import '../../../screens/team/team_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopTeamView extends ConsumerStatefulWidget {
  const DesktopTeamView({super.key});

  @override
  ConsumerState<DesktopTeamView> createState() => _DesktopTeamViewState();
}

class _DesktopTeamViewState extends ConsumerState<DesktopTeamView> {
  bool _loading = true;
  List<TeamMemberModel> _teamMembers = [];
  String _activeTab = 'Office'; // 'Office', 'Party', 'Cooperative'
  String _searchTerm = '';
  String _selectedArea = 'All';
  String _selectedWing = 'All';
  int _displayedLimit = 20;

  List<TeamMemberModel> get _visibleMembers =>
      _filteredMembers.take(_displayedLimit).toList();

  List<String> get _uniqueAreas {
    final areas = _teamMembers
        .map((m) => (m.area ?? '').trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...areas];
  }

  List<String> get _uniqueWings {
    final wings = _teamMembers
        .map((m) => (m.partyWing ?? '').trim())
        .where((w) => w.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...wings];
  }

  @override
  void initState() {
    super.initState();
    _fetchTeam();
  }

  Future<void> _fetchTeam() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(teamRepoProvider);
      final list = await repo.getTeamMembers(category: _activeTab);
      if (mounted) {
        setState(() {
          _teamMembers = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _teamMembers = [];
          _loading = false;
        });
      }
    }
  }

  List<TeamMemberModel> get _filteredMembers {
    final rawQuery = _searchTerm.trim().toLowerCase();
    final normalizedQuery = AppTranslations.normalizeAsciiDigits(rawQuery);
    return _teamMembers.where((m) {
      final matchesSearch = rawQuery.isEmpty ||
          m.name.toLowerCase().contains(normalizedQuery) ||
          (m.nameMarathi?.toLowerCase().contains(rawQuery) ?? false) ||
          AppTranslations.normalizeAsciiDigits(m.mobile).contains(normalizedQuery) ||
          m.role.toLowerCase().contains(normalizedQuery) ||
          m.roleLabel('mr').toLowerCase().contains(rawQuery) ||
          m.roleLabel('hi').toLowerCase().contains(rawQuery) ||
          AppTranslations.normalizeAsciiDigits(m.area ?? '').toLowerCase().contains(normalizedQuery) ||
          AppTranslations.getAreaName(m.area ?? '', 'mr').toLowerCase().contains(rawQuery) ||
          AppTranslations.getAreaName(m.area ?? '', 'hi').toLowerCase().contains(rawQuery);

      final matchesArea = _selectedArea == 'All' ||
          (m.area != null && m.area!.toLowerCase().contains(_selectedArea.toLowerCase()));

      final matchesWing = _selectedWing == 'All' ||
          (m.partyWing != null && m.partyWing!.toLowerCase() == _selectedWing.toLowerCase());

      return matchesSearch && matchesArea && matchesWing;
    }).toList();
  }

  void _showAddStaffModal({TeamMemberModel? item}) {
    final currentLang = ref.read(desktopLanguageProvider);
    final nameController = TextEditingController(text: item?.displayNameFor(currentLang) ?? '');
    final mobileController = TextEditingController(
      text: item != null ? AppTranslations.formatDigits(item.mobile, currentLang) : '',
    );
    final roleController = TextEditingController(
      text: item?.role ??
          AppTranslations.pick(
            currentLang,
            en: 'Office Admin',
            mr: 'कार्यालय प्रशासक',
            hi: 'कार्यालय प्रशासक',
          ),
    );
    final areaController = TextEditingController(
      text: item?.area ?? AppTranslations.getAreaName('Ward 12', currentLang),
    );
    final emailController = TextEditingController(text: item?.email ?? '');
    String category = item?.category ?? _activeTab;
    String? nameError;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final lang = dialogRef.watch(desktopLanguageProvider);
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return DesktopModalDialog(
                title: item == null
                    ? AppTranslations.pick(lang, en: 'Add Team Member', mr: 'टीम सदस्य जोडा', hi: 'टीम सदस्य जोड़ें')
                    : AppTranslations.pick(lang, en: 'Edit Staff Details', mr: 'कर्मचारी तपशील संपादित करा', hi: 'स्टाफ विवरण संपादित करें'),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Staff and administrative team assignments',
                  mr: 'कर्मचारी आणि प्रशासकीय टीम नियुक्त्या',
                  hi: 'स्टाफ और प्रशासनिक टीम जिम्मेदारियां',
                ),
                icon: Icons.badge_rounded,
                width: 600,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(
                    ctx,
                    text: AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                  ),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: item == null
                        ? AppTranslations.pick(lang, en: 'Add Member', mr: 'सदस्य जोडा', hi: 'सदस्य जोड़ें')
                        : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'परिवर्तन सहेजें'),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        setModalState(() {
                          nameError = AppTranslations.pick(
                            lang,
                            en: 'Please enter full name',
                            mr: 'कृपया पूर्ण नाव प्रविष्ट करा',
                            hi: 'कृपया पूरा नाम दर्ज करें',
                          );
                        });
                        return;
                      }
                      final newMember = TeamMemberModel(
                        id: item?.id ?? 'stf-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        nameMarathi: nameController.text.trim(),
                        mobile: AppTranslations.normalizeAsciiDigits(mobileController.text.trim()),
                        role: roleController.text.trim(),
                        area: AppTranslations.normalizeAsciiDigits(areaController.text.trim()),
                        category: category,
                        email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                      );

                      final repo = ref.read(teamRepoProvider);
                      if (item == null) {
                        await repo.addTeamMember(newMember);
                      } else {
                        await repo.updateTeamMember(newMember);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchTeam();
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
                      onChanged: (_) {
                        if (nameError != null) {
                          setModalState(() => nameError = null);
                        }
                      },
                      decoration: desktopInputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Sagar R. Shinde...',
                          mr: 'उदा. सागर रा. शिंदे...',
                          hi: 'उदा. सागर रा. शिंदे...',
                        ),
                        errorText: nameError,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mobile & Role
                    Row(
                      children: [
                        Expanded(
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
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.formatDigits('98XXXXXXXX', lang),
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
                                AppTranslations.pick(lang, en: 'Role *', mr: 'पद / भूमिका *', hi: 'पद / भूमिका *'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: roleController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Office Admin, Supervisor...',
                                    mr: 'उदा. कार्यालय प्रशासक, पर्यवेक्षक...',
                                    hi: 'उदा. कार्यालय प्रशासक, पर्यवेक्षक...',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                                AppTranslations.pick(lang, en: 'Category', mr: 'श्रेणी', hi: 'श्रेणी'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              AppDropdown<String>(
                                value: category,
                                height: 44,
                                backgroundColor: const Color(0xFFF8FAFC),
                                borderColor: AppColors.slate200,
                                items: [
                                  DropdownMenuItem(
                                    value: 'Office',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालयीन टीम', hi: 'कार्यालय टीम'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Party',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'Party Workers', mr: 'पक्ष कार्यकर्ते', hi: 'पार्टी कार्यकर्ता'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Cooperative',
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'Government Employees', mr: 'शासकीय कर्मचारी', hi: 'सरकारी कर्मचारी'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => category = val);
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
                                AppTranslations.pick(lang, en: 'Assigned Area', mr: 'नेमलेला परिसर', hi: 'निर्धारित क्षेत्र'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Ward 12',
                                    mr: 'उदा. प्रभाग १२',
                                    hi: 'उदा. वार्ड १२',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email
                    Text(
                      AppTranslations.pick(lang, en: 'Email Address', mr: 'ईमेल पत्ता', hi: 'ईमेल पता'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      decoration: desktopInputDecoration(hintText: 'staff@office.gov.in'),
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

  void _showDeleteConfirm(TeamMemberModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final lang = dialogRef.watch(desktopLanguageProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppTranslations.pick(lang, en: 'Delete Staff', mr: 'कर्मचारी हटवा', hi: 'स्टाफ हटाएं')),
            content: AppTranslatedText(
              item.displayNameFor(lang),
              isName: true,
              targetLanguage: lang,
              builder: (_, translatedName) => Text(
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
                child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final repo = ref.read(teamRepoProvider);
                  await repo.deleteTeamMember(item.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchTeam();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                child: Text(
                  AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredMembers;
    final visible = _visibleMembers;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 20),

          // Tab Bar
          _buildTabBar(lang),
          const SizedBox(height: 16),

          // Search Row
          _buildSearchRow(lang),
          const SizedBox(height: 24),

          // Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildCardGrid(visible, lang),

          // Load More Footer
          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: 'members',
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, String lang) {
    final formattedCount = AppTranslations.formatDigits(count, lang);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppTranslations.pick(lang, en: 'My Team', mr: 'माझी टीम', hi: 'मेरी टीम'),
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
                      en: 'Total: $formattedCount',
                      mr: 'एकूण: $formattedCount',
                      hi: 'कुल: $formattedCount',
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
                en: 'Office team, government liaisons, and political party workers',
                mr: 'कार्यालयीन टीम, शासकीय समन्वयक आणि पक्ष कार्यकर्ते',
                hi: 'कार्यालय टीम, सरकारी समन्वयक और पार्टी कार्यकर्ता',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions Row matching StaffList.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                TeamReportGenerator.generateAndPrintReport(
                  context: context,
                  staffList: _filteredMembers,
                  activeCategory: _activeTab,
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
              onPressed: () => _showAddStaffModal(),
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
                    AppTranslations.pick(lang, en: 'Add Staff', mr: 'कर्मचारी जोडा', hi: 'स्टाफ जोड़ें'),
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

  Widget _buildTabBar(String lang) {
    final tabs = [
      {
        'key': 'Office',
        'label': AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालयीन टीम', hi: 'कार्यालय टीम'),
        'icon': Icons.apartment_rounded,
      },
      {
        'key': 'Party',
        'label': AppTranslations.pick(lang, en: 'Party Workers', mr: 'पक्ष कार्यकर्ते', hi: 'पार्टी कार्यकर्ता'),
        'icon': Icons.flag_outlined,
      },
      {
        'key': 'Cooperative',
        'label': AppTranslations.pick(lang, en: 'Government Employees', mr: 'शासकीय कर्मचारी', hi: 'सरकारी कर्मचारी'),
        'icon': Icons.business_outlined,
      },
    ];

    return Row(
      children: tabs.map((t) {
        final key = t['key'] as String;
        final label = t['label'] as String;
        final icon = t['icon'] as IconData;
        final isSelected = _activeTab == key;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: () {
              setState(() {
                _activeTab = key;
                _displayedLimit = 20;
              });
              _fetchTeam();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569))),
                ],
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
        // Name / Mobile Search (Col 6)
        Expanded(
          flex: 6,
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
                  en: 'Search staff by name, role, mobile...',
                  mr: 'नाव, पद, मोबाईलद्वारे कर्मचारी शोधा...',
                  hi: 'नाम, पद, मोबाइल से स्टाफ खोजें...',
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

        // Area Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedArea,
            height: 44,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueAreas.map((area) {
              if (area == 'All') {
                return DropdownMenuItem(
                  value: area,
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Text(
                      AppTranslations.getAllAreas(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }
              final areaLabel = AppTranslations.getAreaName(area, lang);
              return DropdownMenuItem(
                value: area,
                child: areaLabel != area
                    ? Padding(
                        padding: EdgeInsets.zero,
                        child: Text(areaLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                      )
                    : Text(area, overflow: TextOverflow.ellipsis),
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
        ),
        const SizedBox(width: 14),

        // Wing Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedWing,
            height: 44,
            prefixIcon: const Icon(Icons.flag_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: [
              DropdownMenuItem(
                value: 'All',
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'All Wings / Cells',
                      mr: 'सर्व आघाड्या / सेल',
                      hi: 'सभी प्रकोष्ठ / सेल',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ..._uniqueWings.where((w) => w != 'All').map((wing) {
                return DropdownMenuItem(value: wing, child: Text(wing, overflow: TextOverflow.ellipsis));
              }),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedWing = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  static const Set<String> _knownRoleKeys = {
    'office admin',
    'supervisor',
    'staff',
    'executive',
    'driver',
    'peon',
    'helper',
    'sanitation worker',
    'karyakarta',
    'it cell head',
    'pro',
  };

  static const Set<String> _knownCategoryKeys = {
    'office',
    'party',
    'cooperative',
  };

  Widget _buildCardGrid(List<TeamMemberModel> items, String lang) {
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
            const Icon(Icons.badge_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No staff members found',
                mr: 'कोणतेही कर्मचारी आढळले नाहीत',
                hi: 'कोई स्टाफ सदस्य नहीं मिला',
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
            mainAxisExtent: 240,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final memberName = item.displayNameFor(lang);
            final isKnownRole = _knownRoleKeys.contains(item.role.trim().toLowerCase());
            final isKnownCategory = _knownCategoryKeys.contains(item.category.trim().toLowerCase());
            final rawArea = (item.area != null && item.area!.trim().isNotEmpty) ? item.area!.trim() : 'Ward 12';
            final mappedArea = AppTranslations.getAreaName(rawArea, lang);

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
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF0F9FF),
                        child: AppTranslatedText(
                          memberName,
                          isName: true,
                          targetLanguage: lang,
                          builder: (_, translatedName) {
                            final initial = translatedName.trim().isNotEmpty
                                ? translatedName.trim()[0].toUpperCase()
                                : AppTranslations.pick(lang, en: 'U', mr: 'स', hi: 'स');
                            return Text(
                              initial,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              memberName,
                              isName: true,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            if (isKnownRole)
                              Text(
                                item.roleLabel(lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0284C7)),
                              )
                            else
                              AppTranslatedText(
                                item.role,
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0284C7)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Phone
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
                        child: mappedArea != rawArea
                            ? Text(
                                mappedArea,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              )
                            : AppTranslatedText(
                                rawArea,
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Bottom Actions
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isKnownCategory)
                          Text(
                            item.categoryLabel(lang),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          )
                        else
                          AppTranslatedText(
                            item.category,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                              onPressed: () => _showAddStaffModal(item: item),
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
            mainAxisExtent: 220,
          ),
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
