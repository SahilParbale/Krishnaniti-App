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

/// WorkHistory Screen matching EXACTLY the web page:
/// Nagarsevak-Managment/src/pages/works/WorkHistory.tsx
class WorkHistoryScreen extends ConsumerStatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  ConsumerState<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends ConsumerState<WorkHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _areaSearchCtrl = TextEditingController();
  final TextEditingController _dateSearchCtrl = TextEditingController();

  String _viewMode = 'grid'; // 'grid' | 'report' matching WorkHistory.tsx line 42

  bool _showAreaDropdown = false;
  bool _showDateDropdown = false;

  bool _loading = true;
  List<WorkHistoryModel> _items = [];

  // Ahwal Selection Mode State matching lines 54-58
  bool _selectionMode = false;
  final Set<String> _selectedWorkIds = {};

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
    final repo = ref.read(workHistoryRepoProvider);
    final works = await repo.getWorks();
    if (mounted) {
      setState(() {
        _items = works;
        _loading = false;
      });
    }
  }

  // Area Suggestions with counts matching WorkHistory.tsx lines 226-234
  List<Map<String, dynamic>> get _areaSuggestions {
    final Map<String, int> stats = {};
    for (final item in _items) {
      if (item.area.isNotEmpty) {
        stats[item.area] = (stats[item.area] ?? 0) + 1;
      }
    }
    final list = stats.entries.map((e) => {'area': e.key, 'count': e.value}).toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list;
  }

  // Date Suggestions with counts matching WorkHistory.tsx lines 237-246
  List<Map<String, dynamic>> get _dateSuggestions {
    final Map<String, int> stats = {};
    for (final item in _items) {
      if (item.date.isNotEmpty) {
        String dateStr;
        try {
          final dt = DateTime.parse(item.date);
          dateStr = DateFormat('MMM d, yyyy').format(dt);
        } catch (_) {
          dateStr = item.date;
        }
        stats[dateStr] = (stats[dateStr] ?? 0) + 1;
      }
    }
    final list = stats.entries.map((e) => {'date': e.key, 'count': e.value}).toList();
    list.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return list;
  }

  // Filtered Items matching lines 248-262
  List<WorkHistoryModel> get _filteredItems {
    final search = _searchCtrl.text.trim().toLowerCase();
    final areaSearch = _areaSearchCtrl.text.trim().toLowerCase();
    final dateSearch = _dateSearchCtrl.text.trim().toLowerCase();

    return _items.where((item) {
      final matchesSearch = search.isEmpty ||
          item.title.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search) ||
          item.location.toLowerCase().contains(search);

      final matchesArea = areaSearch.isEmpty ||
          item.area.toLowerCase().contains(areaSearch);

      String formattedDate = item.date;
      try {
        formattedDate = DateFormat('MMM d, yyyy').format(DateTime.parse(item.date));
      } catch (_) {}

      final matchesDate = dateSearch.isEmpty ||
          formattedDate.toLowerCase().contains(dateSearch) ||
          item.date.toLowerCase().contains(dateSearch);

      return matchesSearch && matchesArea && matchesDate;
    }).toList();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedWorkIds.clear();
    });
  }

  void _handleCardClick(WorkHistoryModel item) {
    if (_selectionMode) {
      setState(() {
        if (_selectedWorkIds.contains(item.id)) {
          _selectedWorkIds.remove(item.id);
        } else {
          _selectedWorkIds.add(item.id);
        }
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkDetailScreen(work: item),
      ),
    ).then((_) => _fetchData());
  }

  // Status Badge matching lines 268-277
  Widget _buildStatusBadge(String status, bool isMr) {
    switch (status) {
      case 'Completed':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                isMr ? 'पूर्ण' : 'Completed',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
              ),
            ],
          ),
        );
      case 'InProgress':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_rounded, size: 12, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Text(
                isMr ? 'सुरू' : 'In Progress',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                isMr ? 'नियोजित' : 'Planned',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
              ),
            ],
          ),
        );
    }
  }

  // Create Work Modal matching lines 625-715
  void _openAddWorkModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final benCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String status = 'Planned';

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
                          'Add New Development Work',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(height: 20),

                    // Project Title
                    const Text('Project Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'Enter project name / tender description...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Detailed scope of civil work...',
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
                              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Landmark / Chowk...',
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
                              const Text('Area / Locality', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Sector 5, Prabhag 12...',
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
                    const Text('Work Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Planned', child: Text('Planned (नियोजित)')),
                        DropdownMenuItem(value: 'InProgress', child: Text('In Progress (सुरू)')),
                        DropdownMenuItem(value: 'Completed', child: Text('Completed (पूर्ण)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // People Benefited & Amount Spent
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('People Benefited', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Amount Spent (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: amtCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 1450000',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Completion Date
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
                            source: 'Manual',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isNotEmpty
                                ? descCtrl.text.trim()
                                : 'Development work initiated for Prabhag residents.',
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
                          await _fetchData();

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
    final filtered = _filteredItems;

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
          title: Text(
            isMr ? 'कामांचा इतिहास' : 'Work History',
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
                WorkReportGenerator.generateAndPrintWorkReport(
                  works: filtered,
                  areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
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
                    // Sticky Header Section matching WorkHistory.tsx lines 281-346
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isMr ? 'कामांचा इतिहास' : 'Work History',
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
                                          '${isMr ? "सापडली" : "Found"}: ${filtered.length}',
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
                                    isMr ? 'प्रभागात पूर्ण झालेली व सुरू असलेली विकासकामे' : 'Historical archive of completed works & projects',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),

                              // Add Work Button matching line 341
                              ElevatedButton.icon(
                                onPressed: _openAddWorkModal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  isMr ? 'नवीन काम' : 'Add Work',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Ahwal Action Bar matching lines 317-329 & 348-375
                          if (!_selectionMode) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      WorkReportGenerator.generateAndPrintWorkReport(
                                        works: filtered,
                                        areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF0F9FF),
                                      foregroundColor: const Color(0xFF0284C7),
                                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                    ),
                                    icon: const Icon(Icons.download_rounded, size: 16),
                                    label: Text(isMr ? 'PDF अहवाल' : 'Download Report', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _toggleSelectionMode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF334155),
                                      elevation: 0,
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                    ),
                                    icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF0284C7)),
                                    label: Text(isMr ? 'अहवाल तयार करा' : 'Generate Ahwal', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Selection Banner Active matching lines 348-375
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
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
                                          isMr ? 'कामे निवडली (Ahwal)' : 'Works Selected',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          isMr ? 'अहवालात समाविष्ट करण्यासाठी कामे निवडा' : 'Select works to include in Ahwal report.',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _toggleSelectionMode,
                                    child: Text(isMr ? 'रद्द' : 'Cancel', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf, size: 15),
                                    label: Text(
                                      isMr ? 'अहवाल पहा' : 'Preview',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: _selectedWorkIds.isEmpty
                                        ? null
                                        : () {
                                            final selected = _items.where((w) => _selectedWorkIds.contains(w.id)).toList();
                                            AhwalReportGenerator.generateAndPrintAhwal(selectedWorks: selected);
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Filters Grid matching WorkHistory.tsx lines 377-451
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
                                hintText: isMr ? 'कामे, वर्णन किंवा ठिकाण शोधा...' : 'Search works, description or location...',
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
          onPressed: _openAddWorkModal,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            isMr ? 'नवीन काम नोंदवा' : 'Add Work',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Cards Grid View matching lines 542-621
  Widget _buildCardsGridView(bool isMr, List<WorkHistoryModel> items) {
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
            const Icon(Icons.engineering_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              isMr ? 'कोणतेही काम आढळले नाही' : 'No work projects found',
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
          final isSelected = _selectedWorkIds.contains(item.id);

          return InkWell(
            onTap: () => _handleCardClick(item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.status == 'Completed'
                    ? const Color(0xFFF0FDF4)
                    : item.status == 'InProgress'
                        ? const Color(0xFFFEFCE8)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : item.status == 'Completed'
                          ? const Color(0xFFBBF7D0)
                          : item.status == 'InProgress'
                              ? const Color(0xFFFEF08A)
                              : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
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
                  // Top Row: Status badge & Source badge with Checkbox in Selection Mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(item.status, isMr),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.build_outlined, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  item.source == 'Manual'
                                      ? (isMr ? 'मॅन्युअल' : 'Manual')
                                      : item.source,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                          if (_selectionMode) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title matching line 577
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description matching line 581
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),

                  // Feedback rating banner matching lines 584-589
                  if (item.feedbackCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.feedbackCount} ${isMr ? "नागरिक अभिप्राय" : "Feedbacks"}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                          Text(
                            '${item.feedbackRating} ★',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),

                  // Bottom info: Date, Location, Beneficiaries, Amount spent
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            item.date,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      if (item.amount != null)
                        Text(
                          '₹ ${item.amount!.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                    ],
                  ),
                  if (item.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Report Table View matching lines 460-540
  Widget _buildReportTableView(bool isMr, List<WorkHistoryModel> items) {
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
                    WorkReportGenerator.generateAndPrintWorkReport(
                      works: items,
                      areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
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

          // Horizontally Scrollable Data Table matching exactly lines 464-472
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 20,
              columns: [
                DataColumn(label: Text(isMr ? 'क्र.' : 'Sr No', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'प्रकल्प शीर्षक' : 'Project Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'ठिकाण व परिसर' : 'Location / Area', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'स्थिती' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'स्रोत' : 'Source', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'तारीख' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(isMr ? 'रक्कम (₹)' : 'Amount (₹)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return DataRow(
                  onSelectChanged: (_) => _handleCardClick(item),
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
                      Row(
                        children: [
                          const Icon(Icons.build_outlined, size: 12, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(item.source, style: const TextStyle(fontSize: 11.5)),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(item.date, style: const TextStyle(fontSize: 12)),
                    ),
                    DataCell(
                      Text(
                        item.amount != null ? '₹ ${item.amount!.toStringAsFixed(0)}' : '--',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
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
