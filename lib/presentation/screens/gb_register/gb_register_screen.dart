import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gb_register_entry_model.dart';
import '../../../data/repositories/gb_register_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'gb_register_detail_screen.dart';
import 'gb_register_report_generator.dart';

class GbRegisterScreen extends ConsumerStatefulWidget {
  const GbRegisterScreen({super.key});

  @override
  ConsumerState<GbRegisterScreen> createState() => _GbRegisterScreenState();
}

class _GbRegisterScreenState extends ConsumerState<GbRegisterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _viewMode = 'grid'; // 'grid' | 'report'
  String _selectedMeetingType = 'All'; // 'All', 'GB', 'Standing Committee', 'Ward Committee', 'Special GB'
  String _selectedStatus = 'All'; // 'All', 'Raised', 'In Discussion', 'Action Taken', 'Rejected'
  String _selectedArea = 'All';

  bool _isLoading = true;
  List<GbRegisterEntryModel> _allEntries = [];

  final List<String> _meetingTypes = ['All', 'GB', 'Standing Committee', 'Ward Committee', 'Special GB'];
  final List<String> _statusList = ['All', 'Raised', 'In Discussion', 'Action Taken', 'Rejected'];

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
    final repo = ref.read(gbRegisterRepoProvider);
    final items = await repo.getEntries();
    if (mounted) {
      setState(() {
        _allEntries = items;
        _isLoading = false;
      });
    }
  }

  List<String> get _areas {
    final list = _allEntries.map((e) => e.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
    list.sort();
    return ['All', ...list];
  }

  List<GbRegisterEntryModel> get _filteredEntries {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allEntries.where((e) {
      if (_selectedMeetingType != 'All' && e.meetingType.toLowerCase() != _selectedMeetingType.toLowerCase()) {
        return false;
      }
      if (_selectedStatus != 'All' && e.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_selectedArea != 'All' && !e.area.toLowerCase().contains(_selectedArea.toLowerCase())) {
        return false;
      }
      if (query.isNotEmpty) {
        final subMatch = e.subject.toLowerCase().contains(query);
        final descMatch = e.description.toLowerCase().contains(query);
        final deptMatch = e.department.toLowerCase().contains(query);
        final areaMatch = e.area.toLowerCase().contains(query);
        final resMatch = e.resolutionNo?.toLowerCase().contains(query) ?? false;
        final tagMatch = e.tags.any((t) => t.toLowerCase().contains(query));
        if (!subMatch && !descMatch && !deptMatch && !areaMatch && !resMatch && !tagMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showAddModal() {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Water Supply Department');
    final areaCtrl = TextEditingController(text: 'Ward 12');
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final benCtrl = TextEditingController();
    final resCtrl = TextEditingController();
    final respCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    String meetingType = _selectedMeetingType != 'All' ? _selectedMeetingType : 'GB';
    String status = 'Raised';
    bool isGeneratingAi = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            void autoDraftDescription() {
              if (subjectCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a subject title first to auto-draft description'),
                    backgroundColor: Color(0xFFCA8A04),
                  ),
                );
                return;
              }

              setModalState(() => isGeneratingAi = true);
              Future.delayed(const Duration(milliseconds: 350), () {
                final isMr = ref.read(isMarathiProvider);
                final subject = subjectCtrl.text.trim();
                final dept = deptCtrl.text.trim();
                final area = areaCtrl.text.trim();

                String generated;
                if (isMr) {
                  generated =
                      'पुणे महानगरपालिका कार्यक्षेत्रातील $area परिसरामध्ये "$subject" संदर्भात तातडीने धोरणात्मक निर्णय घेणे अत्यावश्यक आहे. $dept कडे स्थानिक नागरिकांनी वारंवार पाठपुरावा करूनही अडचण प्रलंबित राहिली आहे. सबब, सदर विषयावर महासभेत / संबंधित समितीत तात्काळ प्रशासकीय मंजुरी, अंदाजपत्रकीय तरतूद व कामाचे आदेश काढण्यात यावेत ही विनंती.';
                } else {
                  generated =
                      'Formal legislative submission placed before the Assembly regarding "$subject" across $area. Citizens have lodged recurring representations with the $dept. It is respectfully moved that administrative sanction, technical feasibility review, and budgetary allocation be granted on priority.';
                }

                setModalState(() {
                  descCtrl.text = generated;
                  isGeneratingAi = false;
                });
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
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
                          'Record Assembly Motion (GB Register)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Meeting Type & Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Meeting Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: meetingType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: _meetingTypes
                                    .where((t) => t != 'All')
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => meetingType = val);
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
                              const Text('Meeting Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: dateCtrl,
                                decoration: InputDecoration(
                                  hintText: 'YYYY-MM-DD',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Subject
                    const Text('Subject / Question Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subjectCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Sanctioning of 24x7 Water Supply Mainline',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description with AI Auto-Draft
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Motion Description & Details *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        InkWell(
                          onTap: isGeneratingAi ? null : autoDraftDescription,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isGeneratingAi)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                                  )
                                else
                                  const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                const Text(
                                  'AI Auto-Draft',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter complete motion speech, demands, affected citizen concerns...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Department & Area
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Department *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: deptCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Roads & Civil',
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
                              const Text('Area / Ward *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

                    // Status & Beneficiaries
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: status,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: _statusList
                                    .where((s) => s != 'All')
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                                    .toList(),
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
                              const Text('Beneficiaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: benCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 12,000 Citizens',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Resolution No
                    const Text('Resolution Ref No (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: resCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. PMC/GB/RES/2024/412',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Official Response
                    const Text('Administration Floor Reply (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: respCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter administration verbal or written confirmation...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tags
                    const Text('Tags (comma separated)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: tagsCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Water, Pipeline, PMC GB',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
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
                          if (subjectCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a subject')),
                            );
                            return;
                          }

                          final tags = tagsCtrl.text
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();

                          final newEntry = GbRegisterEntryModel(
                            id: 'gb-${DateTime.now().millisecondsSinceEpoch}',
                            meetingType: meetingType,
                            meetingDate: dateCtrl.text.trim().isNotEmpty
                                ? dateCtrl.text.trim()
                                : DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            subject: subjectCtrl.text.trim(),
                            description: descCtrl.text.trim().isNotEmpty
                                ? descCtrl.text.trim()
                                : subjectCtrl.text.trim(),
                            department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : 'General Administration',
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                            status: status,
                            beneficiaries: benCtrl.text.trim().isNotEmpty ? benCtrl.text.trim() : null,
                            resolutionNo: resCtrl.text.trim().isNotEmpty ? resCtrl.text.trim() : null,
                            response: respCtrl.text.trim().isNotEmpty ? respCtrl.text.trim() : null,
                            tags: tags,
                            createdAt: DateTime.now().toIso8601String(),
                          );

                          final repo = ref.read(gbRegisterRepoProvider);
                          await repo.addEntry(newEntry);
                          await _loadData();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Assembly record registered successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Motion to Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showDeleteConfirmation(GbRegisterEntryModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Assembly Record'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete motion "${item.subject}"? This cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(gbRegisterRepoProvider);
              await repo.deleteEntry(item.id);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Motion record deleted'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final displayed = _filteredEntries;

    final totalCount = displayed.length;
    final actionTakenCount = displayed.where((e) => e.status.toLowerCase() == 'action taken' || e.status.toLowerCase() == 'sanctioned').length;
    final inDiscussionCount = displayed.where((e) => e.status.toLowerCase() == 'in discussion').length;
    final raisedCount = displayed.where((e) => e.status.toLowerCase() == 'raised').length;

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
                'GB Register',
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
                'GB motions, questions & resolutions',
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            isMr ? 'नवीन ठराव / प्रश्न' : 'Record Motion',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _showAddModal,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Executive Stat Strip
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            _statBox(
                              title: isMr ? 'एकूण ठराव' : 'Total Motions',
                              count: '$totalCount',
                              color: const Color(0xFF0284C7),
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                            const SizedBox(width: 8),
                            _statBox(
                              title: isMr ? 'कार्यवाही झाली' : 'Action Taken',
                              count: '$actionTakenCount',
                              color: const Color(0xFF16A34A),
                              bgColor: const Color(0xFFF0FDF4),
                            ),
                            const SizedBox(width: 8),
                            _statBox(
                              title: isMr ? 'चर्चेत' : 'In Discussion',
                              count: '$inDiscussionCount',
                              color: const Color(0xFF6366F1),
                              bgColor: const Color(0xFFEEF2FF),
                            ),
                            const SizedBox(width: 8),
                            _statBox(
                              title: isMr ? 'मांडलेले' : 'Raised',
                              count: '$raisedCount',
                              color: const Color(0xFFCA8A04),
                              bgColor: const Color(0xFFFEFCE8),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Search bar & Filters
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            // Search row with View Mode & Download
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText: isMr
                                          ? 'ठराव, विषय, खाते किंवा संदर्भ क्रमांक शोधा...'
                                          : 'Search motion subject, dept, area, resolution...',
                                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                                      suffixIcon: _searchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 18),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _viewMode = _viewMode == 'grid' ? 'report' : 'grid';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Icon(
                                      _viewMode == 'grid' ? Icons.table_chart_rounded : Icons.grid_view_rounded,
                                      size: 20,
                                      color: const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    GbRegisterReportGenerator.generateAndPrintGbReport(
                                      entries: displayed,
                                      meetingTypeFilter: _selectedMeetingType != 'All' ? _selectedMeetingType : null,
                                      statusFilter: _selectedStatus != 'All' ? _selectedStatus : null,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Icon(Icons.download_rounded, size: 20, color: Color(0xFF0284C7)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Meeting Type filter chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _meetingTypes.map((type) {
                                  final isSelected = _selectedMeetingType == type;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      selected: isSelected,
                                      showCheckmark: false,
                                      label: Text(
                                        type == 'All'
                                            ? (isMr ? 'सर्व सभा' : 'All Meetings')
                                            : (isMr ? _getMeetingTypeLabelMr(type) : type),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : const Color(0xFF475569),
                                        ),
                                      ),
                                      selectedColor: const Color(0xFF0284C7),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                      ),
                                      onSelected: (val) {
                                        if (val) setState(() => _selectedMeetingType = type);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status & Area Filters
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedStatus,
                                        isExpanded: true,
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                                        items: _statusList.map((s) {
                                          return DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              s == 'All' ? (isMr ? 'सर्व स्थिती' : 'All Status') : (isMr ? _getStatusLabelMr(s) : s),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedStatus = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _areas.contains(_selectedArea) ? _selectedArea : 'All',
                                        isExpanded: true,
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                                        items: _areas.map((a) {
                                          return DropdownMenuItem(
                                            value: a,
                                            child: Text(
                                              a == 'All' ? (isMr ? 'सर्व प्रभाग/परिसर' : 'All Areas') : a,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedArea = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // List / Table
                      if (displayed.isEmpty)
                        Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isMr ? 'कोणतेही ठराव किंवा प्रश्न सापडले नाहीत' : 'No GB Register Records Found',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMr ? 'कृपया शोध निकष बदला किंवा नवीन ठराव जोडा.' : 'Try adjusting your filters or record a new motion.',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else if (_viewMode == 'grid')
                        _buildGridCardView(displayed, isMr)
                      else
                        _buildTableView(displayed, isMr),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _statBox({
    required String title,
    required String count,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCardView(List<GbRegisterEntryModel> entries, bool isMr) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = entries[index];
        return InkWell(
          onTap: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GbRegisterDetailScreen(entry: item)),
            );
            if (res == true) _loadData();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meeting type & date & status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.meetingTypeBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: item.meetingTypeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        isMr ? item.meetingTypeDisplayMr : item.meetingTypeDisplayEn,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.meetingTypeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(item.meetingDate),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: item.statusBorderColor),
                      ),
                      child: Text(
                        isMr ? item.statusDisplayMr : item.statusDisplayEn,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subject Title
                Text(
                  item.subject,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Department & Area
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.department,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      item.area,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // Administration response snippet if available
                if (item.response != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              isMr ? 'प्रशासकीय कार्यवाही उत्तर:' : 'Administration Floor Reply:',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                            if (item.resolutionNo != null) ...[
                              const Spacer(),
                              Text(
                                item.resolutionNo!,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.response!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.35),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],

                // Tags
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: item.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const Divider(height: 20),

                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GbRegisterDetailScreen(entry: item)),
                        );
                        if (res == true) _loadData();
                      },
                      child: Row(
                        children: [
                          Text(
                            isMr ? 'सविस्तर पहा' : 'View Details',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0284C7)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showDeleteConfirmation(item),
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
    );
  }

  Widget _buildTableView(List<GbRegisterEntryModel> entries, bool isMr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: [
              DataColumn(label: Text(isMr ? 'अ.क्र.' : '#', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'दिनांक' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'सभेचा प्रकार' : 'Meeting Type', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'विषय / ठराव' : 'Subject & Motion', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'खाते' : 'Department', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'स्थिती' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'परिसर' : 'Area', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'कृती' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: entries.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;

              return DataRow(
                cells: [
                  DataCell(Text('$idx')),
                  DataCell(Text(_formatDate(item.meetingDate))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.meetingTypeBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMr ? item.meetingTypeDisplayMr : item.meetingTypeDisplayEn,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.meetingTypeColor),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.subject,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.resolutionNo != null)
                            Text(
                              item.resolutionNo!,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(item.department, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.statusBgColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: item.statusBorderColor),
                      ),
                      child: Text(
                        isMr ? item.statusDisplayMr : item.statusDisplayEn,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: item.statusColor),
                      ),
                    ),
                  ),
                  DataCell(Text(item.area, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                      tooltip: 'View Details',
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GbRegisterDetailScreen(entry: item)),
                        );
                        if (res == true) _loadData();
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String _getMeetingTypeLabelMr(String type) {
    switch (type.toLowerCase()) {
      case 'gb':
        return 'महासभा (GB)';
      case 'standing committee':
      case 'standing':
        return 'स्थायी समिती';
      case 'ward committee':
      case 'ward':
        return 'प्रभाग समिती';
      case 'special gb':
        return 'विशेष महासभा';
      default:
        return type;
    }
  }

  static String _getStatusLabelMr(String status) {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'sanctioned':
        return 'कार्यवाही झाली';
      case 'in discussion':
        return 'चर्चेत';
      case 'rejected':
        return 'नाकारले';
      case 'raised':
      default:
        return 'मांडलेला';
    }
  }
}
