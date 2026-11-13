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

/// PossibleImprovements Screen matching EXACTLY the web page:
/// Nagarsevak-Managment/src/pages/ward/PossibleImprovements.tsx
class PossibleImprovementsScreen extends ConsumerStatefulWidget {
  const PossibleImprovementsScreen({super.key});

  @override
  ConsumerState<PossibleImprovementsScreen> createState() => _PossibleImprovementsScreenState();
}

class _PossibleImprovementsScreenState extends ConsumerState<PossibleImprovementsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _areaSearchCtrl = TextEditingController();
  final TextEditingController _dateSearchCtrl = TextEditingController();

  String _viewMode = 'grid'; // 'grid' | 'report' matching PossibleImprovements.tsx line 41
  String _statusFilter = 'All'; // 'All' | 'Pending' | 'Planned' | 'In Progress' | 'Complete'

  bool _showAreaDropdown = false;
  bool _showDateDropdown = false;

  bool _loading = true;
  List<ImprovementModel> _improvements = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _areaSearchCtrl.dispose();
    _dateSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final repo = ref.read(improvementsRepoProvider);
    final items = await repo.getImprovements();
    if (mounted) {
      setState(() {
        _improvements = items;
        _loading = false;
      });
    }
  }

  // Area suggestions with count matching PossibleImprovements.tsx lines 62-70
  List<Map<String, dynamic>> get _areaSuggestions {
    final Map<String, int> stats = {};
    for (final item in _improvements) {
      if (item.area.isNotEmpty) {
        stats[item.area] = (stats[item.area] ?? 0) + 1;
      }
    }
    final list = stats.entries.map((e) => {'area': e.key, 'count': e.value}).toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list;
  }

  // Date suggestions with count matching PossibleImprovements.tsx lines 73-82
  List<Map<String, dynamic>> get _dateSuggestions {
    final Map<String, int> stats = {};
    for (final item in _improvements) {
      if (item.createdAt.isNotEmpty) {
        String dateStr;
        try {
          final dt = DateTime.parse(item.createdAt);
          dateStr = DateFormat('MMM d, yyyy').format(dt);
        } catch (_) {
          dateStr = item.createdAt;
        }
        stats[dateStr] = (stats[dateStr] ?? 0) + 1;
      }
    }
    final list = stats.entries.map((e) => {'date': e.key, 'count': e.value}).toList();
    list.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return list;
  }

  // Filtered improvements matching lines 84-99
  List<ImprovementModel> get _filteredImprovements {
    final search = _searchCtrl.text.trim().toLowerCase();
    final areaSearch = _areaSearchCtrl.text.trim().toLowerCase();
    final dateSearch = _dateSearchCtrl.text.trim().toLowerCase();

    return _improvements.where((item) {
      final matchesSearch = search.isEmpty ||
          item.title.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search) ||
          item.location.toLowerCase().contains(search);

      final matchesArea = areaSearch.isEmpty ||
          item.area.toLowerCase().contains(areaSearch);

      String formattedDate = item.createdAt;
      try {
        formattedDate = DateFormat('MMM d, yyyy').format(DateTime.parse(item.createdAt));
      } catch (_) {}

      final matchesDate = dateSearch.isEmpty ||
          formattedDate.toLowerCase().contains(dateSearch) ||
          item.createdAt.toLowerCase().contains(dateSearch);

      final matchesStatus = _statusFilter == 'All' ||
          item.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesArea && matchesDate && matchesStatus;
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'All') return _improvements.length;
    return _improvements.where((i) => i.status.toLowerCase() == status.toLowerCase()).length;
  }

  Future<void> _handleVote(ImprovementModel imp) async {
    final repo = ref.read(improvementsRepoProvider);
    final newVotes = await repo.voteImprovement(imp.id);
    if (mounted) {
      setState(() {
        final idx = _improvements.indexWhere((i) => i.id == imp.id);
        if (idx != -1) {
          _improvements[idx] = _improvements[idx].copyWith(votes: newVotes);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote registered successfully!'),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status, bool isMr) {
    Color bg;
    Color text;
    Color border;
    String label;

    switch (status) {
      case 'Complete':
        bg = const Color(0xFFF0FDF4);
        text = const Color(0xFF15803D);
        border = const Color(0xFFBBF7D0);
        label = isMr ? 'पूर्ण' : 'Complete';
        break;
      case 'In Progress':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        border = const Color(0xFFBFDBFE);
        label = isMr ? 'सुरू' : 'In Progress';
        break;
      case 'Planned':
        bg = const Color(0xFFFAF5FF);
        text = const Color(0xFF7E22CE);
        border = const Color(0xFFE9D5FF);
        label = isMr ? 'नियोजित' : 'Planned';
        break;
      default:
        bg = const Color(0xFFFFF7ED);
        text = const Color(0xFFC2410C);
        border = const Color(0xFFFFEDD5);
        label = isMr ? 'प्रलंबित' : 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  // Add Improvement Modal matching lines 524-642
  void _openAddModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 90))));
    final benCtrl = TextEditingController();
    String status = 'Pending';

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
                          'Propose Possible Improvement',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(height: 20),

                    // Improvement Title
                    const Text('Title / Proposed Work *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Pedestrian skywalk, Open gym, Traffic signal...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    const Text('Detailed Description *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Why is this improvement needed? How will it help constituents?',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Location & Area
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Specific Spot / Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Chowk, Road crossing...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prabhag Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Sector 5, Shivaji Nagar...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Status Dropdown
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Pending', child: Text('Pending (प्रलंबित विचार)')),
                        DropdownMenuItem(value: 'Planned', child: Text('Planned (नियोजित)')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress (सुरू)')),
                        DropdownMenuItem(value: 'Complete', child: Text('Complete (पूर्ण)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Target Date & Benefited People
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expected Target Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estimated Beneficiaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: benCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 15000',
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
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter improvement title')),
                            );
                            return;
                          }

                          final newImp = ImprovementModel(
                            id: 'imp-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isNotEmpty
                                ? descCtrl.text.trim()
                                : 'Proposed infrastructural improvement for Prabhag 12.',
                            location: locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : 'Ward 12',
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                            status: status,
                            votes: 1,
                            completionDate: dateCtrl.text.trim(),
                            peopleBenefited: int.tryParse(benCtrl.text.trim()),
                            createdAt: DateTime.now().toIso8601String(),
                          );

                          final repo = ref.read(improvementsRepoProvider);
                          await repo.addImprovement(newImp);
                          await _fetchData();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Improvement proposed successfully!'),
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
    final filtered = _filteredImprovements;

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
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          titleSpacing: 0,
          title: Text(
            isMr ? 'संभाव्य सुधारणा' : 'Possible Improvements',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            // View Mode Toggle Button: Grid / Report Table
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: _viewMode == 'grid' ? Colors.white : Colors.white60,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tooltip: isMr ? 'ग्रिड दृश्य' : 'Grid View',
                    onPressed: () => setState(() => _viewMode = 'grid'),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.table_chart_outlined,
                      size: 18,
                      color: _viewMode == 'report' ? Colors.white : Colors.white60,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tooltip: isMr ? 'अहवाल तक्ता' : 'Report Table',
                    onPressed: () => setState(() => _viewMode = 'report'),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 22),
              tooltip: isMr ? 'PDF अहवाल' : 'Download Report',
              onPressed: () {
                ImprovementReportGenerator.generateAndPrintImprovementReport(
                  improvements: filtered,
                  areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                  statusFilter: _statusFilter,
                );
              },
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Sticky Header Section matching PossibleImprovements.tsx lines 226-280
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isMr ? 'संभाव्य सुधारणा' : 'Possible Improvements',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFBAE6FD)),
                                ),
                                child: Text(
                                  '${isMr ? "उपलब्ध" : "Found"}: ${filtered.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMr ? 'नागरिकांच्या सूचना व पायाभूत सुविधांचे प्रस्ताव' : 'Citizen proposals, ideas & future project plans',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),

                    // Filters Card matching PossibleImprovements.tsx lines 282-383
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                        children: [
                          // 1) Main Search Input
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: isMr ? 'सुधारणा, वर्णन किंवा ठिकाण शोधा...' : 'Search improvements, description or location...',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                prefixIcon: const Icon(Icons.search, size: 19, color: Color(0xFF94A3B8)),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 2) Area & Date Search with dropdowns
                          Row(
                            children: [
                              // Area Search
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: TextField(
                                    controller: _areaSearchCtrl,
                                    onTap: () => setState(() => _showAreaDropdown = true),
                                    onChanged: (_) => setState(() => _showAreaDropdown = true),
                                    style: const TextStyle(fontSize: 12.5),
                                    decoration: InputDecoration(
                                      hintText: isMr ? 'परिसर शोधा...' : 'Search area...',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                                      suffixIcon: _areaSearchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                                              onPressed: () {
                                                _areaSearchCtrl.clear();
                                                setState(() => _showAreaDropdown = false);
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Date Search
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: TextField(
                                    controller: _dateSearchCtrl,
                                    onTap: () => setState(() => _showDateDropdown = true),
                                    onChanged: (_) => setState(() => _showDateDropdown = true),
                                    style: const TextStyle(fontSize: 12.5),
                                    decoration: InputDecoration(
                                      hintText: isMr ? 'तारीख फिल्टर...' : 'Filter date...',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 17, color: Color(0xFF94A3B8)),
                                      suffixIcon: _dateSearchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                                              onPressed: () {
                                                _dateSearchCtrl.clear();
                                                setState(() => _showDateDropdown = false);
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Area Dropdown Box if open
                          if (_showAreaDropdown && _areaSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children: _areaSuggestions
                                    .where((a) =>
                                        _areaSearchCtrl.text.isEmpty ||
                                        a['area'].toString().toLowerCase().contains(_areaSearchCtrl.text.toLowerCase()))
                                    .map((item) {
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(item['area'] as String, style: const TextStyle(fontSize: 12.5)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${item['count']}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _areaSearchCtrl.text = item['area'] as String;
                                        _showAreaDropdown = false;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          // Date Dropdown Box if open
                          if (_showDateDropdown && _dateSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children: _dateSuggestions
                                    .where((d) =>
                                        _dateSearchCtrl.text.isEmpty ||
                                        d['date'].toString().toLowerCase().contains(_dateSearchCtrl.text.toLowerCase()))
                                    .map((item) {
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(item['date'] as String, style: const TextStyle(fontSize: 12.5)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${item['count']}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _dateSearchCtrl.text = item['date'] as String;
                                        _showDateDropdown = false;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // 3) Horizontal Status Pills with counts matching lines 358-382
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatusPill('All', isMr ? 'सर्व' : 'All'),
                                _buildStatusPill('Pending', isMr ? 'प्रलंबित' : 'Pending'),
                                _buildStatusPill('Planned', isMr ? 'नियोजित' : 'Planned'),
                                _buildStatusPill('In Progress', isMr ? 'सुरू' : 'In Progress'),
                                _buildStatusPill('Complete', isMr ? 'पूर्ण' : 'Complete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Content: Report Table or Cards Grid
                    if (_viewMode == 'report') ...[
                      _buildReportTableView(isMr, filtered),
                    ] else ...[
                      _buildCardsGridView(isMr, filtered),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _openAddModal,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            isMr ? 'नवीन प्रस्ताव' : 'Propose Improvement',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, String label) {
    final isSelected = _statusFilter.toLowerCase() == status.toLowerCase();
    final count = _countForStatus(status);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _statusFilter = status),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
      ),
    );
  }

  // Cards Grid View matching PossibleImprovements.tsx lines 445-521
  Widget _buildCardsGridView(bool isMr, List<ImprovementModel> items) {
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              isMr ? 'कोणताही प्रस्ताव आढळला नाही' : 'No proposals found for this filter',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final item = items[idx];

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImprovementDetailScreen(improvement: item),
                ),
              ).then((_) => _fetchData());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle Lightbulb Background Watermark matching line 464
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Opacity(
                      opacity: 0.06,
                      child: const Icon(
                        Icons.lightbulb,
                        size: 90,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Status badge & Date matching lines 468-482
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(item.status, isMr),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                item.createdAt.isNotEmpty ? item.createdAt.split('T').first : '',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title matching line 485
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Description matching line 486
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 10),

                      // Location & Beneficiaries matching lines 489-502
                      if (item.location.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${item.location}${item.area.isNotEmpty ? " (${item.area})" : ""}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.peopleBenefited != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 13, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              '${item.peopleBenefited} ${isMr ? "नागरिकांना लाभ" : "People Benefited"}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),

                      // Bottom Vote Row matching lines 504-516
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${item.votes}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isMr ? 'नागरिक मते' : 'VOTES',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),

                          // Vote button
                          InkWell(
                            onTap: () => _handleVote(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 5),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Report Table View matching PossibleImprovements.tsx lines 385-443
  Widget _buildReportTableView(bool isMr, List<ImprovementModel> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          // Table Header Bar with Download Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isMr ? "अहवाल तक्ता" : "Report View"} (${items.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ImprovementReportGenerator.generateAndPrintImprovementReport(
                      improvements: items,
                      areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                      statusFilter: _statusFilter,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F9FF),
                    foregroundColor: const Color(0xFF0284C7),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    isMr ? 'PDF अहवाल' : 'Download PDF',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Horizontally Scrollable Data Table matching exactly lines 390-396
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 20,
              columns: [
                DataColumn(label: Text(isMr ? 'क्र.' : 'Sr No', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'प्रस्ताव शीर्षक' : 'Improvement Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'ठिकाण व परिसर' : 'Location / Area', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'स्थिती' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'मते' : 'Votes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'तारीख' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return DataRow(
                  onSelectChanged: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImprovementDetailScreen(improvement: item),
                      ),
                    ).then((_) => _fetchData());
                  },
                  cells: [
                    DataCell(Text('${idx + 1}', style: const TextStyle(fontSize: 12))),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              item.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(
                          '${item.location}${item.area.isNotEmpty ? " (${item.area})" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(_buildStatusBadge(item.status, isMr)),
                    DataCell(
                      Text(
                        '${item.votes}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.createdAt.isNotEmpty ? item.createdAt.split('T').first : '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
