import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/improvement_model.dart';
import '../../../data/repositories/improvements_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'improvement_detail_screen.dart';
import 'improvement_report_generator.dart';

class PossibleImprovementsScreen extends ConsumerStatefulWidget {
  const PossibleImprovementsScreen({super.key});

  @override
  ConsumerState<PossibleImprovementsScreen> createState() => _PossibleImprovementsScreenState();
}

class _PossibleImprovementsScreenState extends ConsumerState<PossibleImprovementsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _viewMode = 'grid'; // 'grid' or 'report'
  String _selectedStatus = 'All'; // 'All', 'Pending', 'Planned', 'In Progress', 'Complete'
  String _selectedArea = 'All';

  bool _isLoading = true;
  List<ImprovementModel> _allImprovements = [];

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
    final repo = ref.read(improvementsRepoProvider);
    final items = await repo.getImprovements();
    if (mounted) {
      setState(() {
        _allImprovements = items;
        _isLoading = false;
      });
    }
  }

  List<String> get _uniqueAreas {
    final areas = _allImprovements.map((i) => i.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
    areas.sort();
    return ['All', ...areas];
  }

  List<ImprovementModel> get _filteredImprovements {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allImprovements.where((imp) {
      if (_selectedStatus != 'All' && imp.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_selectedArea != 'All' && imp.area.toLowerCase() != _selectedArea.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final titleMatch = imp.title.toLowerCase().contains(query);
        final descMatch = imp.description.toLowerCase().contains(query);
        final locMatch = imp.location.toLowerCase().contains(query);
        final areaMatch = imp.area.toLowerCase().contains(query);
        if (!titleMatch && !descMatch && !locMatch && !areaMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'All') return _allImprovements.length;
    return _allImprovements.where((i) => i.status.toLowerCase() == status.toLowerCase()).length;
  }

  Future<void> _handleVote(ImprovementModel imp) async {
    final repo = ref.read(improvementsRepoProvider);
    final newVotes = await repo.voteImprovement(imp.id);
    if (mounted) {
      setState(() {
        final idx = _allImprovements.indexWhere((i) => i.id == imp.id);
        if (idx != -1) {
          _allImprovements[idx] = _allImprovements[idx].copyWith(votes: newVotes);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote registered successfully!'),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  void _showAddModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Ward 12');
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 90))));
    final benCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String status = 'Pending';
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
                          'Propose New Civic Improvement',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Improvement Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Pedestrian Foot-Over-Bridge, Skywalk, CCTV...',
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
                                      'Strategic civic development proposal for "$title" in Prabhag 12. Focuses on boosting resident infrastructure convenience, pedestrian safety, and long-term urban sustainability with high community utility.';
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
                        hintText: 'Enter detailed community need and proposed urban scope...',
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
                              const Text('Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Main Chowk, Sambhaji Park',
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
                              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: status,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Pending', child: Text('Pending Review')),
                                  DropdownMenuItem(value: 'Planned', child: Text('Planned')),
                                  DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                                  DropdownMenuItem(value: 'Complete', child: Text('Complete')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => status = val);
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
                              const Text('Target Completion Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: dateCtrl,
                                decoration: InputDecoration(
                                  hintText: 'YYYY-MM-DD',
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
                              const Text('Estimated Budget (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: budgetCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 1500000',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          if (titleCtrl.text.trim().isEmpty || locCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter proposal title and location')),
                            );
                            return;
                          }

                          final newImp = ImprovementModel(
                            id: 'imp-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isNotEmpty
                                ? descCtrl.text.trim()
                                : 'Civic improvement proposed by Ward 12 citizens.',
                            votes: 1,
                            location: locCtrl.text.trim(),
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                            status: status,
                            completionDate: dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : null,
                            peopleBenefited: int.tryParse(benCtrl.text.trim()),
                            estimatedBudget: double.tryParse(budgetCtrl.text.trim()),
                            createdAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            proposedBy: 'Local Resident',
                          );

                          final repo = ref.read(improvementsRepoProvider);
                          await repo.addImprovement(newImp);
                          await _loadData();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New proposal submitted successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Submit Proposal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
    final displayed = _filteredImprovements;

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
                'Possible Improvements',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Proposed civic development works',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: const [],
        ),
        body: Column(
          children: [
            // Search & Filter Header
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
                            hintText: isMr ? 'सुधारणा, प्रकल्प, ठिकाण शोधा...' : 'Search proposals, keywords, area...',
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
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          ImprovementReportGenerator.generateAndPrintImprovementReport(
                            improvements: displayed,
                            statusFilter: _selectedStatus,
                            areaFilter: _selectedArea != 'All' ? _selectedArea : null,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(Icons.download_rounded, size: 20, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Area Dropdown
                  Container(
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
                        isExpanded: true,
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
                  const SizedBox(height: 10),

                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusFilterChip('All', isMr ? 'सर्व' : 'All', _countForStatus('All'), const Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        _statusFilterChip('Pending', isMr ? 'प्रलंबित' : 'Pending', _countForStatus('Pending'), const Color(0xFFEA580C)),
                        const SizedBox(width: 6),
                        _statusFilterChip('Planned', isMr ? 'नियोजित' : 'Planned', _countForStatus('Planned'), const Color(0xFF7E22CE)),
                        const SizedBox(width: 6),
                        _statusFilterChip('In Progress', isMr ? 'प्रगतीपथावर' : 'In Progress', _countForStatus('In Progress'), const Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        _statusFilterChip('Complete', isMr ? 'पूर्ण' : 'Complete', _countForStatus('Complete'), const Color(0xFF16A34A)),
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
                              Icon(Icons.lightbulb_outline_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isMr ? 'कोणत्याही सुधारणा आढळल्या नाहीत' : 'No improvement proposals found matching filters',
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
            isMr ? 'नवीन सुचवा' : 'Propose New',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          ),
          onPressed: _showAddModal,
        ),
      ),
    );
  }

  Widget _statusFilterChip(String key, String label, int count, Color activeColor) {
    final isSelected = _selectedStatus.toLowerCase() == key.toLowerCase();
    return InkWell(
      onTap: () => setState(() => _selectedStatus = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<ImprovementModel> list, bool isMr) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final imp = list[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: imp.statusBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ImprovementDetailScreen(improvement: imp)),
              );
              _loadData();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Status badge & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: imp.statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: imp.statusBorderColor),
                        ),
                        child: Text(
                          isMr ? imp.statusDisplayMr : imp.statusDisplayEn,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: imp.statusColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            imp.createdAt,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    imp.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description line clamp
                  Text(
                    imp.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location & Beneficiaries Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            '${imp.location} (${imp.area})',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (imp.peopleBenefited != null)
                        Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, size: 13, color: Color(0xFF0369A1)),
                            const SizedBox(width: 4),
                            Text(
                              '${NumberFormat.decimalPattern().format(imp.peopleBenefited)} ${isMr ? "लाभार्थी" : "People"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  // Bottom Voting Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${imp.votes}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isMr ? 'मते' : 'VOTES',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      // Vote Button
                      InkWell(
                        onTap: () => _handleVote(imp),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Text(
                                isMr ? 'मत द्या' : 'Vote',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildReportTableView(List<ImprovementModel> list, bool isMr) {
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
              DataColumn(label: Text(isMr ? 'सुधारणा प्रस्ताव' : 'Proposal Title', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'ठिकाण' : 'Location', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'स्थिती' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'मते' : 'Votes', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'तारीख' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(list.length, (index) {
              final imp = list[index];
              return DataRow(
                onSelectChanged: (_) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ImprovementDetailScreen(improvement: imp)),
                  );
                  _loadData();
                },
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(imp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(imp.description, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text('${imp.location}\n(${imp.area})', style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: imp.statusBgColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: imp.statusBorderColor),
                      ),
                      child: Text(
                        isMr ? imp.statusDisplayMr : imp.statusDisplayEn,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: imp.statusColor),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${imp.votes} Votes',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  DataCell(Text(imp.createdAt, style: const TextStyle(fontSize: 12))),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

