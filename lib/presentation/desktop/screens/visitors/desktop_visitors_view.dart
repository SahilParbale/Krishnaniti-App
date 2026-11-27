import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nagarsevak_mobile/data/models/visitor_model.dart';
import 'package:nagarsevak_mobile/data/repositories/visitors_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/common/desktop_modal_dialog.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/screens/visitors/visitor_report_generator.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import 'package:nagarsevak_mobile/presentation/providers/language_provider.dart';

/// Desktop Visitor Log View
/// - Full-width layout matching other desktop views
/// - Sticky Header: Title + Subtitle + [Download Report] + [Log Visitor] buttons
/// - Modal Dialog for Check-in / Registration & Edit
/// - Filters: Search bar, Area dropdown, Purpose pills
/// - Switchable Grid / Table views with card actions
class DesktopVisitorsView extends ConsumerStatefulWidget {
  const DesktopVisitorsView({super.key});

  @override
  ConsumerState<DesktopVisitorsView> createState() => _DesktopVisitorsViewState();
}

class _DesktopVisitorsViewState extends ConsumerState<DesktopVisitorsView> {
  String _viewMode = 'grid'; // 'grid' | 'table'
  String _searchQuery = '';
  String _selectedArea = 'All';
  String _selectedDate = 'All';
  String _purposeFilter = 'All';

  bool _loading = true;
  List<VisitorModel> _visitors = [];

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(visitorsRepoProvider);
      final list = await repo.getVisitors();
      if (mounted) {
        setState(() {
          _visitors = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _uniqueAreas {
    final areas = <String>{};
    for (final v in _visitors) {
      if (v.area != null && v.area!.trim().isNotEmpty) {
        areas.add(v.area!.trim());
      }
    }
    final sorted = areas.toList()..sort();
    return ['All', ...sorted];
  }

  List<String> get _uniqueDates {
    final dates = <String>{};
    for (final v in _visitors) {
      dates.add(DateFormat('yyyy-MM-dd').format(v.visitDate));
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return ['All', ...sorted];
  }

  List<VisitorModel> get _filteredVisitors {
    return _visitors.where((v) {
      if (_selectedArea != 'All' && v.area != _selectedArea) {
        return false;
      }
      if (_selectedDate != 'All' && DateFormat('yyyy-MM-dd').format(v.visitDate) != _selectedDate) {
        return false;
      }
      if (_purposeFilter != 'All' && v.purpose.toLowerCase() != _purposeFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchName = v.name.toLowerCase().contains(q);
        final matchPhone = v.mobile.contains(q);
        final matchRemarks = (v.remarks ?? '').toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchRemarks) return false;
      }
      return true;
    }).toList();
  }

  void _showVisitorModal({VisitorModel? item}) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final mobileCtrl = TextEditingController(text: item?.mobile ?? '');
    final areaCtrl = TextEditingController(text: item?.area ?? '');
    final referenceCtrl = TextEditingController(text: item?.reference ?? '');
    final remarksCtrl = TextEditingController(text: item?.remarks ?? '');
    String selectedPurpose = item?.purpose ?? 'Complaint';
    bool saving = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: item == null ? 'Log Visitor' : 'Edit Visitor Details',
            subtitle: item == null
                ? 'Register a new visitor at the ward office'
                : 'Update visitor visit information and notes',
            icon: Icons.people_alt_rounded,
            width: 580,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: item == null ? 'Log Visitor' : 'Save Changes',
                icon: Icons.check_rounded,
                isLoading: saving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setModalState(() => saving = true);
                  final repo = ref.read(visitorsRepoProvider);

                  if (item != null) {
                    await repo.updateVisitor(item.id, {
                      'name': nameCtrl.text.trim(),
                      'mobile': mobileCtrl.text.trim(),
                      'area': areaCtrl.text.trim(),
                      'purpose': selectedPurpose,
                      'reference': referenceCtrl.text.trim(),
                      'remarks': remarksCtrl.text.trim(),
                    });
                  } else {
                    final newVisitor = VisitorModel(
                      id: '',
                      name: nameCtrl.text.trim(),
                      mobile: mobileCtrl.text.trim(),
                      purpose: selectedPurpose,
                      area: areaCtrl.text.trim(),
                      reference: referenceCtrl.text.trim(),
                      remarks: remarksCtrl.text.trim(),
                      visitDate: DateTime.now(),
                    );
                    await repo.addVisitor(newVisitor);
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadVisitors();
                },
              ),
            ],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Full Name
                  const Text(
                    'Full Name *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Citizen full name',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Mobile & Purpose in a Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mobile
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mobile Number',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: mobileCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixText: '+91 ',
                                hintText: '10 digits mobile',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Purpose Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Purpose',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              value: selectedPurpose,
                              height: 44,
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFFE2E8F0),
                              items: [
                                'Complaint',
                                'Meeting',
                                'Greeting',
                                'Donation',
                                'Help',
                                'Other',
                              ].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedPurpose = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Area & Reference in a Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Area
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Area / Address',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: areaCtrl,
                              decoration: InputDecoration(
                                hintText: 'Area or venue',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Reference
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reference (Optional)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: referenceCtrl,
                              decoration: InputDecoration(
                                hintText: 'Referred by',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5)),
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

                  // 4. Remarks
                  const Text(
                    'Notes / Remarks',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: remarksCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter visit details or notes...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _startEdit(VisitorModel visitor) {
    _showVisitorModal(item: visitor);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isMr = lang == 'mr';
    final items = _filteredVisitors;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Sticky Header
            _buildHeader(lang),

            const SizedBox(height: 24),

            // 2. Full-Width Visitors Log Container
            _buildLogContainer(items, lang),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 26, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Text(
                  AppTranslations.t('visitors.title', lang: lang),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.t('visitors.subtitle', lang: lang),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Log Visitor
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                VisitorReportGenerator.generateAndPrintListReport(
                  context: context,
                  visitors: _filteredVisitors,
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                lang == 'mr' ? 'अहवाल डाउनलोड करा' : (lang == 'hi' ? 'रिपोर्ट डाउनलोड करें' : 'Download Report'),
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),

            // Log Visitor Button
            ElevatedButton(
              onPressed: () => _showVisitorModal(),
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
                    lang == 'mr' ? 'नवीन भेट नोंद' : (lang == 'hi' ? 'नई आगंतुक प्रविष्टि' : 'Log Visitor'),
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

  // --- Full-Width Log Container ---
  Widget _buildLogContainer(List<VisitorModel> items, String lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar of Log: Title + Found count + View Mode Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    lang == 'mr' ? 'कार्यालय भेट आढावा' : (lang == 'hi' ? 'कार्यालय आगंतुक अवलोकन' : 'Visitors Overview'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      '${lang == "mr" ? "सापडले" : (lang == "hi" ? "मिले" : "Found")}: ${items.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ),
              // View mode toggles
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
                      label: lang == 'mr' ? 'ग्रिड' : (lang == 'hi' ? 'ग्रिड' : 'Grid'),
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

          const SizedBox(height: 16),

          // Filters: Search, Area dropdown, Date dropdown
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: lang == 'mr'
                        ? 'नाव, मोबाईल, टिप्पणी द्वारे अभ्यागत शोधा...'
                        : (lang == 'hi' ? 'नाम, मोबाइल, टिप्पणी द्वारा आगंतुक खोजें...' : 'Search visitors by name, mobile, notes...'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: AppDropdown<String>(
                  value: _selectedArea,
                  height: 42,
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  items: _uniqueAreas.map((a) {
                    return DropdownMenuItem(
                      value: a,
                      child: Text(
                        a == 'All'
                            ? (lang == 'mr' ? 'सर्व भाग' : (lang == 'hi' ? 'सभी क्षेत्र' : 'All Areas'))
                            : a,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedArea = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: AppDropdown<String>(
                  value: _selectedDate,
                  height: 42,
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  items: _uniqueDates.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(
                        d == 'All'
                            ? (lang == 'mr' ? 'सर्व तारखा' : (lang == 'hi' ? 'सभी तिथियां' : 'All Dates'))
                            : d,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDate = val);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Purpose Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'All',
                'Complaint',
                'Meeting',
                'Greeting',
                'Donation',
                'Help',
                'Other',
              ].map((purpose) {
                final isSel = _purposeFilter == purpose;
                String label = purpose;
                if (purpose == 'All') label = AppTranslations.t('common.all', lang: lang);
                else if (purpose == 'Complaint') label = lang == 'mr' ? 'तक्रार' : (lang == 'hi' ? 'शिकायत' : 'Complaint');
                else if (purpose == 'Meeting') label = lang == 'mr' ? 'भेट / चर्चा' : (lang == 'hi' ? 'बैठक / चर्चा' : 'Meeting');
                else if (purpose == 'Greeting') label = lang == 'mr' ? 'निमंत्रण / सत्कार' : (lang == 'hi' ? 'निमंत्रण / स्वागत' : 'Greeting');
                else if (purpose == 'Donation') label = lang == 'mr' ? 'देणगी / निधी' : (lang == 'hi' ? 'दान / निधि' : 'Donation');
                else if (purpose == 'Help') label = lang == 'mr' ? 'मदत' : (lang == 'hi' ? 'सहायता' : 'Help');
                else if (purpose == 'Other') label = lang == 'mr' ? 'इतर' : (lang == 'hi' ? 'अन्य' : 'Other');

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSel,
                    showCheckmark: false,
                    label: Text(label),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFF0F9FF),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (_) {
                      setState(() => _purposeFilter = purpose);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Content
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (items.isEmpty)
            _buildEmptyState(lang == 'mr')
          else if (_viewMode == 'grid')
            _buildVisitorGrid(items, lang)
          else
            _buildVisitorTable(items, lang),
        ],
      ),
    );
  }

  // --- Grid View (3-by-3 format on desktop) ---
  Widget _buildVisitorGrid(List<VisitorModel> items, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.38,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final visitor = items[index];
            return _buildVisitorCard(visitor, lang);
          },
        );
      },
    );
  }

  Widget _buildVisitorCard(VisitorModel visitor, String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  visitor.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildPurposeBadge(visitor.purpose, lang),
            ],
          ),
          const SizedBox(height: 6),
          if (visitor.mobile.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text('+91 ${visitor.mobile}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (visitor.area != null && visitor.area!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(visitor.area!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (visitor.remarks != null && visitor.remarks!.isNotEmpty) ...[
            Expanded(
              child: AppTranslatedText(
                visitor.remarks!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ] else ...[
            const Spacer(),
          ],
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${visitor.formattedDate} • ${visitor.formattedTime}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit Visitor',
                      onPressed: () => _startEdit(visitor),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete Visitor',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Visitor'),
                            content: Text('Are you sure you want to delete ${visitor.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(visitorsRepoProvider).deleteVisitor(visitor.id);
                          _loadVisitors();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeBadge(String purpose, [String lang = 'en']) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    final pLower = purpose.toLowerCase();
    String label = purpose;
    if (pLower == 'complaint') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      label = lang == 'mr' ? 'तक्रार' : (lang == 'hi' ? 'शिकायत' : 'Complaint');
    } else if (pLower == 'meeting') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
      label = lang == 'mr' ? 'भेट / चर्चा' : (lang == 'hi' ? 'बैठक / चर्चा' : 'Meeting');
    } else if (pLower == 'greeting') {
      bg = const Color(0xFFF3E8FF);
      fg = const Color(0xFF7E22CE);
      label = lang == 'mr' ? 'निमंत्रण' : (lang == 'hi' ? 'निमंत्रण' : 'Greeting');
    } else if (pLower == 'donation' || pLower == 'help') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      label = pLower == 'donation'
          ? (lang == 'mr' ? 'देणगी' : (lang == 'hi' ? 'दान' : 'Donation'))
          : (lang == 'mr' ? 'मदत' : (lang == 'hi' ? 'सहायता' : 'Help'));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildVisitorTable(List<VisitorModel> items, String lang) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(AppTranslations.getReportColumn('name', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(AppTranslations.getReportColumn('contact', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(lang == 'mr' ? 'भेटीचे कारण' : (lang == 'hi' ? 'भेंट का उद्देश्य' : 'Purpose'), style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(AppTranslations.getReportColumn('area', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(AppTranslations.getReportColumn('date', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(lang == 'mr' ? 'कृती' : (lang == 'hi' ? 'कार्रवाई' : 'Actions'), style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
        rows: items.map((v) {
          return DataRow(
            cells: [
              DataCell(Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('+91 ${v.mobile}')),
              DataCell(_buildPurposeBadge(v.purpose, lang)),
              DataCell(Text(v.area ?? '-')),
              DataCell(Text('${v.formattedDate} • ${v.formattedTime}')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit',
                      onPressed: () => _startEdit(v),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(lang == 'mr' ? 'अभ्यागत हटवा' : (lang == 'hi' ? 'आगंतुक हटाएं' : 'Delete Visitor')),
                            content: Text(
                              lang == 'mr'
                                  ? 'तुम्ही नक्की ${v.name} यांची नोंद हटवू इच्छिता का?'
                                  : (lang == 'hi'
                                      ? 'क्या आप वाकई ${v.name} की प्रविष्टि हटाना चाहते हैं?'
                                      : 'Are you sure you want to delete ${v.name}?'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(lang == 'mr' ? 'रद्द करा' : (lang == 'hi' ? 'रद्द करें' : 'Cancel')),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  lang == 'mr' ? 'हटवा' : (lang == 'hi' ? 'हटाएं' : 'Delete'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(visitorsRepoProvider).deleteVisitor(v.id);
                          _loadVisitors();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
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

  Widget _buildEmptyState(bool isMr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          const Text('No visitors recorded yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
