import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/work_history_model.dart';
import '../../../data/repositories/work_history_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'ahwal_report_generator.dart';
import 'work_detail_screen.dart';
import 'work_report_generator.dart';

class WorkHistoryScreen extends ConsumerStatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  ConsumerState<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends ConsumerState<WorkHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _viewMode = 'grid'; // 'grid' or 'report'
  String _selectedStatus = 'All'; // 'All', 'Completed', 'InProgress', 'Planned'
  String _selectedSource = 'All'; // 'All', 'Manual', 'Complaint', 'Help'
  String _selectedArea = 'All';

  bool _isLoading = true;
  List<WorkHistoryModel> _allWorks = [];

  // Ahwal Selection Mode State
  bool _selectionMode = false;
  final Set<String> _selectedWorkIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(workHistoryRepoProvider);
    final works = await repo.getWorks();
    if (mounted) {
      setState(() {
        _allWorks = works;
        _isLoading = false;
      });
    }
  }

  List<String> get _uniqueAreas {
    final areas = _allWorks.map((w) => w.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
    areas.sort();
    return ['All', ...areas];
  }

  List<WorkHistoryModel> get _filteredWorks {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allWorks.where((w) {
      // Status filter
      if (_selectedStatus != 'All' && w.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      // Source filter
      if (_selectedSource != 'All' && w.source.toLowerCase() != _selectedSource.toLowerCase()) {
        return false;
      }
      // Area filter
      if (_selectedArea != 'All' && w.area.toLowerCase() != _selectedArea.toLowerCase()) {
        return false;
      }
      // Query filter
      if (query.isNotEmpty) {
        final titleMatch = w.title.toLowerCase().contains(query);
        final descMatch = w.description.toLowerCase().contains(query);
        final locMatch = w.location.toLowerCase().contains(query);
        final areaMatch = w.area.toLowerCase().contains(query);
        final citizenMatch = w.citizenName?.toLowerCase().contains(query) ?? false;
        if (!titleMatch && !descMatch && !locMatch && !areaMatch && !citizenMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedWorkIds.clear();
    });
  }

  void _toggleWorkSelection(String id) {
    setState(() {
      if (_selectedWorkIds.contains(id)) {
        _selectedWorkIds.remove(id);
      } else {
        _selectedWorkIds.add(id);
      }
    });
  }

  void _onCardTap(WorkHistoryModel work) async {
    if (_selectionMode) {
      _toggleWorkSelection(work.id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkDetailScreen(work: work)),
    );
    _loadData();
  }

  void _showAddWorkModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Ward 12');
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final benCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String status = 'Planned';
    String source = 'Manual';
    bool isGeneratingAI = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Development Project / Work',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Project Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. CC Road Concreting, LED High-Mast Lighting...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Description / Scope *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        // AI Auto Draft Button
                        TextButton.icon(
                          onPressed: titleCtrl.text.trim().isEmpty || isGeneratingAI
                              ? null
                              : () async {
                                  setModalState(() => isGeneratingAI = true);
                                  await Future.delayed(const Duration(milliseconds: 600));
                                  final title = titleCtrl.text.trim();
                                  final draft =
                                      'Municipal development undertaking for "$title" executed in Prabhag Ward 12. Work encompasses comprehensive engineering assessment, laying high-grade materials conforming to standard civic specifications, and active monitoring to ensure long-term durability and citizen convenience.';
                                  descCtrl.text = draft;
                                  setModalState(() => isGeneratingAI = false);
                                },
                          icon: isGeneratingAI
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                                )
                              : const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF0284C7)),
                          label: const Text(
                            'AI Auto Draft',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter technical scope, milestones, and materials...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category / Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: source,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Manual', child: Text('Civil Work')),
                                  DropdownMenuItem(value: 'Complaint', child: Text('Grievance')),
                                  DropdownMenuItem(value: 'Help', child: Text('Direct Help')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => source = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: status,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Planned', child: Text('Planned')),
                                  DropdownMenuItem(value: 'InProgress', child: Text('In Progress')),
                                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => status = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Lane 4, Market Chowk',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Area / Locality', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Shaniwar Peth',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Benefited Citizens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: benCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 5000',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expenditure (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: amtCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 750000',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Target / Completion Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: dateCtrl,
                      decoration: InputDecoration(
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter project title')),
                            );
                            return;
                          }

                          final newWork = WorkHistoryModel(
                            id: 'work-${DateTime.now().millisecondsSinceEpoch}',
                            source: source,
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isNotEmpty
                                ? descCtrl.text.trim()
                                : 'Development work initiated for Ward 12 residents.',
                            location: locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : 'Ward 12',
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                            status: status,
                            date: dateCtrl.text.trim(),
                            peopleBenefited: int.tryParse(benCtrl.text.trim()),
                            amount: double.tryParse(amtCtrl.text.trim()),
                            feedbackRating: 5.0,
                            feedbackCount: 0,
                          );

                          final repo = ref.read(workHistoryRepoProvider);
                          await repo.addWork(newWork);
                          await _loadData();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New work project added successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final displayed = _filteredWorks;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const NagarsevakAppDrawer(currentTabIndex: 0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Open Menu Drawer',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Ward Development Works',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Development works, grievances & welfare',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: [
            // Ahwal Mode Button
            IconButton(
              icon: Icon(
                _selectionMode ? Icons.check_circle_rounded : Icons.assignment_outlined,
                color: Colors.white,
              ),
              tooltip: isMr ? 'अहवाल तयार करा' : 'Generate Ahwal',
              onPressed: _toggleSelectionMode,
            ),
            // PDF Export Directory
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: isMr ? 'अहवाल डाउनलोड करा' : 'Download Report',
              onPressed: () {
                WorkReportGenerator.generateAndPrintWorkReport(
                  works: displayed,
                  statusFilter: _selectedStatus,
                  areaFilter: _selectedArea != 'All' ? _selectedArea : null,
                );
              },
            ),
            // Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _loadData,
            ),
          ],
        ),
        body: Column(
          children: [
            // Selection Action Bar (when in Ahwal mode)
            if (_selectionMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F9FF),
                  border: Border(bottom: BorderSide(color: Color(0xFFBAE6FD))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_selectedWorkIds.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr ? 'कामे निवडली (Ahwal Dossier)' : 'Works Selected for Ahwal',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            isMr ? 'अहवाल अहवालात समाविष्ट करण्यासाठी कामे निवडा' : 'Select works to compile into the Ahwal report.',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleSelectionMode,
                      child: Text(isMr ? 'रद्द करा' : 'Cancel', style: const TextStyle(color: Color(0xFF64748B))),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: Text(
                        isMr ? 'अहवाल पहा' : 'Preview Ahwal',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _selectedWorkIds.isEmpty
                          ? null
                          : () {
                              final selected = _allWorks.where((w) => _selectedWorkIds.contains(w.id)).toList();
                              AhwalReportGenerator.generateAndPrintAhwal(selectedWorks: selected);
                            },
                    ),
                  ],
                ),
              ),

            // Search & Filters Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Bar + View Mode switcher
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: isMr ? 'कामे, ठिकाण, नागरिक शोधा...' : 'Search works, locations, citizen...',
                            hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View Mode Toggle (Grid vs Table)
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.grid_view_rounded,
                                size: 19,
                                color: _viewMode == 'grid' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              tooltip: 'Grid View',
                              onPressed: () => setState(() => _viewMode = 'grid'),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.table_chart_outlined,
                                size: 19,
                                color: _viewMode == 'report' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              tooltip: 'Report Table View',
                              onPressed: () => setState(() => _viewMode = 'report'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Area Dropdown & Status Filter Row
                  Row(
                    children: [
                      // Area Dropdown
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedArea,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                              items: _uniqueAreas.map((area) {
                                return DropdownMenuItem(
                                  value: area,
                                  child: Text(area == 'All' ? (isMr ? 'सर्व भाग (All Areas)' : 'All Areas') : area),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedArea = val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Source Dropdown
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSource,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                              items: [
                                DropdownMenuItem(value: 'All', child: Text(isMr ? 'सर्व स्रोत' : 'All Sources')),
                                DropdownMenuItem(value: 'Manual', child: Text(isMr ? 'विकासकामे' : 'Civil Works')),
                                DropdownMenuItem(value: 'Complaint', child: Text(isMr ? 'तक्रारीतून' : 'From Grievances')),
                                DropdownMenuItem(value: 'Help', child: Text(isMr ? 'थेट मदत' : 'Direct Welfare')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedSource = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusFilterChip('All', isMr ? 'सर्व कामे' : 'All Works', Colors.grey.shade700),
                        const SizedBox(width: 6),
                        _statusFilterChip('Completed', isMr ? 'पूर्ण झालेली' : 'Completed', const Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        _statusFilterChip('InProgress', isMr ? 'प्रगतीपथावर' : 'In Progress', const Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        _statusFilterChip('Planned', isMr ? 'नियोजित' : 'Planned', const Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayed.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isMr ? 'कोणतीही कामे आढळली नाहीत' : 'No work records found matching filters',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : _viewMode == 'report'
                          ? _buildReportTableView(displayed, isMr)
                          : _buildGridView(displayed, isMr),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            isMr ? 'नवीन काम जोडा' : 'Add Work',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          ),
          onPressed: _showAddWorkModal,
        ),
      ),
    );
  }

  Widget _statusFilterChip(String key, String label, Color activeColor) {
    final isSelected = _selectedStatus.toLowerCase() == key.toLowerCase();
    return InkWell(
      onTap: () => setState(() => _selectedStatus = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<WorkHistoryModel> works, bool isMr) {
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: works.length,
      itemBuilder: (ctx, index) {
        final w = works[index];
        final isSelectedInAhwal = _selectedWorkIds.contains(w.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectionMode && isSelectedInAhwal
                  ? const Color(0xFF0284C7)
                  : w.status.toLowerCase() == 'completed'
                      ? const Color(0xFFBBF7D0)
                      : w.status.toLowerCase().contains('progress')
                          ? const Color(0xFFBAE6FD)
                          : const Color(0xFFE2E8F0),
              width: _selectionMode && isSelectedInAhwal ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _onCardTap(w),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Badges & Selection Checkbox
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: w.statusBgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isMr ? w.statusDisplayMr : w.statusDisplayEn,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: w.statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Source Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(w.sourceIcon, size: 12, color: const Color(0xFF475569)),
                                const SizedBox(width: 4),
                                Text(
                                  isMr ? w.sourceDisplayMr : w.sourceDisplayEn,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Checkbox if Selection Mode
                      if (_selectionMode)
                        Checkbox(
                          value: isSelectedInAhwal,
                          activeColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (_) => _toggleWorkSelection(w.id),
                        )
                      else
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    w.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description line clamp
                  Text(
                    w.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feedback rating pill (if manual with reviews)
                  if (w.feedbackCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${w.feedbackRating} (${w.feedbackCount} ${isMr ? "प्रतिक्रिया" : "Reviews"})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  // Metadata Row: Location, Date, Benefited, Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            '${w.location} (${w.area})',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (w.amount != null)
                        Text(
                          numFormat.format(w.amount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            w.date,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      if (w.peopleBenefited != null)
                        Text(
                          '${NumberFormat.decimalPattern().format(w.peopleBenefited)} ${isMr ? "नागरिक लाभार्थी" : "Citizens"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontWeight: FontWeight.w600),
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

  Widget _buildReportTableView(List<WorkHistoryModel> works, bool isMr) {
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: [
              DataColumn(label: Text(isMr ? 'क्र.' : '#', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'प्रकल्प शीर्षक' : 'Project Title', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'ठिकाण व भाग' : 'Location & Area', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'स्थिती' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'श्रेणी' : 'Category', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'तारीख' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'खर्च' : 'Expenditure', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(works.length, (index) {
              final w = works[index];
              return DataRow(
                onSelectChanged: (_) => _onCardTap(w),
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(w.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(w.description, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text('${w.location}\n(${w.area})', style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: w.statusBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMr ? w.statusDisplayMr : w.statusDisplayEn,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: w.statusColor),
                      ),
                    ),
                  ),
                  DataCell(Text(isMr ? w.sourceDisplayMr : w.sourceDisplayEn, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(w.date, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Text(
                      w.amount != null ? numFormat.format(w.amount) : '--',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
