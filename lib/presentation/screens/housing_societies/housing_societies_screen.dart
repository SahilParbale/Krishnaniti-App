import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/housing_society_model.dart';
import '../../../data/repositories/housing_society_repository.dart';
import 'housing_society_detail_screen.dart';
import 'housing_society_report_generator.dart';

class HousingSocietiesScreen extends ConsumerStatefulWidget {
  const HousingSocietiesScreen({super.key});

  @override
  ConsumerState<HousingSocietiesScreen> createState() => _HousingSocietiesScreenState();
}

class _HousingSocietiesScreenState extends ConsumerState<HousingSocietiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedArea = 'all';
  String _selectedStatus = 'all';
  int _viewMode = 0; // 0 = Cards, 1 = Table

  bool _isLoading = true;
  List<HousingSocietyModel> _societies = [];
  List<String> _areas = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'voters': 0,
    'favourable': 0,
    'supportPercentage': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(housingSocietyRepoProvider);

    final list = await repo.getSocieties(
      searchQuery: _searchController.text,
      area: _selectedArea,
      status: _selectedStatus,
    );
    final stats = await repo.getStatistics();
    final areas = await repo.getUniqueAreas();

    if (mounted) {
      setState(() {
        _societies = list;
        _stats = stats;
        _areas = areas;
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label कॉपी केला: $text'),
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAddEditModal([HousingSocietyModel? societyToEdit]) {
    final nameMrCtrl = TextEditingController(text: societyToEdit?.nameMarathi ?? societyToEdit?.name ?? '');
    final nameEnCtrl = TextEditingController(text: societyToEdit?.nameEnglish ?? societyToEdit?.name ?? '');
    final chairmanNameCtrl = TextEditingController(text: societyToEdit?.chairmanName ?? '');
    final chairmanPhoneCtrl = TextEditingController(text: societyToEdit?.chairmanMobile ?? '');
    final secretaryNameCtrl = TextEditingController(text: societyToEdit?.secretaryName ?? '');
    final secretaryPhoneCtrl = TextEditingController(text: societyToEdit?.secretaryMobile ?? '');
    final votersCtrl = TextEditingController(text: (societyToEdit != null && societyToEdit.voterCount > 0) ? societyToEdit.voterCount.toString() : '');
    final favVotersCtrl = TextEditingController(text: (societyToEdit != null && societyToEdit.favourableVoterCount > 0) ? societyToEdit.favourableVoterCount.toString() : '');
    final areaCtrl = TextEditingController(text: societyToEdit?.area ?? '');
    final addressCtrl = TextEditingController(text: societyToEdit?.address ?? '');
    final notesCtrl = TextEditingController(text: societyToEdit?.notes ?? '');
    String status = societyToEdit?.status ?? 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        societyToEdit == null ? 'नवीन सोसायटी नोंदवा (Add Society)' : 'सोसायटी संपादन (Edit Society)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  TextField(
                    controller: nameMrCtrl,
                    decoration: InputDecoration(
                      labelText: 'सोसायटीचे नाव (मराठी) *',
                      hintText: 'उदा. गोकुळधाम सहकारी गृहनिर्माण संस्था',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: nameEnCtrl,
                    decoration: InputDecoration(
                      labelText: 'Society Name (English)',
                      hintText: 'e.g. Gokuldham Co-op Housing Society',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chairmanNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'चेअरमन नाव',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: chairmanPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'चेअरमन मोबाईल',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: secretaryNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'सेक्रेटरी नाव',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: secretaryPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'सेक्रेटरी मोबाईल',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: votersCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'एकूण मतदार संख्या',
                            hintText: 'उदा. 150',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: favVotersCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'फेवर मतदार संख्या',
                            hintText: 'उदा. 100',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: areaCtrl,
                    decoration: InputDecoration(
                      labelText: 'परिसर / गल्ली / प्रभाग',
                      hintText: 'उदा. शांती नगर, प्रभाग क्र. १२',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'पूर्ण पत्ता (Address)',
                      hintText: 'उदा. प्लॉट क्र. १२, शांती नगर',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'महत्वाच्या समस्या / मागण्या / टिप्पण्या',
                      hintText: 'उदा. रस्ते डांबरीकरण, पाणीपुरवठा, स्ट्रीटलाईट, इ.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: InputDecoration(
                      labelText: 'स्थिती (Status)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active (सक्रिय)')),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive (निष्क्रिय)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => status = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : nameEnCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('कृपया सोसायटीचे नाव प्रविष्ट करा.')),
                          );
                          return;
                        }

                        final vCount = int.tryParse(votersCtrl.text.trim()) ?? 0;
                        final favCount = int.tryParse(favVotersCtrl.text.trim()) ?? 0;

                        if (favCount > vCount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('फेवर मतदार संख्या एकूण मतदार संख्येपेक्षा जास्त असू शकत नाही!')),
                          );
                          return;
                        }

                        final model = HousingSocietyModel(
                          id: societyToEdit?.id ?? 'soc-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : name,
                          nameEnglish: nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : name,
                          chairmanName: chairmanNameCtrl.text.trim(),
                          chairmanMobile: chairmanPhoneCtrl.text.trim(),
                          secretaryName: secretaryNameCtrl.text.trim(),
                          secretaryMobile: secretaryPhoneCtrl.text.trim(),
                          voterCount: vCount,
                          favourableVoterCount: favCount,
                          area: areaCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          notes: notesCtrl.text.trim(),
                          status: status,
                          createdAt: societyToEdit?.createdAt ?? DateTime.now(),
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        final repo = ref.read(housingSocietyRepoProvider);
                        if (societyToEdit == null) {
                          await repo.addSociety(model);
                        } else {
                          await repo.updateSociety(model);
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (!mounted) return;
                        _loadData();

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(societyToEdit == null ? 'नवीन सोसायटी यशस्वीरीत्या नोंदवली गेली!' : 'माहिती अद्ययावत केली!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        societyToEdit == null ? 'सोसायटी नोंदवा (Register Society)' : 'बदल जतन करा (Save Changes)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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

  void _confirmDelete(HousingSocietyModel soc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('सोसायटी हटवा (Delete Society)'),
        content: Text('तुम्हाला नक्की ${soc.displayName(true)} ही सोसायटी हटवायची आहे का?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(housingSocietyRepoProvider);
              await repo.deleteSociety(soc.id);
              if (!mounted) return;
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('सोसायटी यशस्वीरित्या हटवली.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('हटवा'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'सोसायटी व मतदार माहिती',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'चेअरमन, सेक्रेटरी संपर्क आणि मतदार संख्यांचे विश्लेषण',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'पीडीएफ अहवाल (Download PDF)',
            onPressed: () => HousingSocietyReportGenerator.generateAndPrintReport(societies: _societies),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'ताजे करा',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('नवीन सोसायटी', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4 KPI Summary Widgets
              _buildStatsGrid(),

              const SizedBox(height: 16),

              // Search & Filter Box
              _buildSearchAndFilters(),

              const SizedBox(height: 16),

              // Mode Toggle & Result Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'एकूण सोसायट्या: ${_societies.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.grid_view_rounded,
                            size: 20,
                            color: _viewMode == 0 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                          ),
                          tooltip: 'कार्ड व्ह्यू (Cards)',
                          onPressed: () => setState(() => _viewMode = 0),
                        ),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        IconButton(
                          icon: Icon(
                            Icons.table_chart_outlined,
                            size: 20,
                            color: _viewMode == 1 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                          ),
                          tooltip: 'टेबल व्ह्यू (Table)',
                          onPressed: () => setState(() => _viewMode = 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content View
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                  ),
                )
              else if (_societies.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.apartment_outlined, size: 54, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'कोणतीही सोसायटी सापडली नाही.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'शोध निकष बदला किंवा नवीन सोसायटी नोंदवा.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openAddEditModal(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('सोसायटी नोंदवा'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_viewMode == 0)
                _buildCardsView()
              else
                _buildTableView(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final total = _stats['total'] ?? 0;
    final voters = _stats['voters'] ?? 0;
    final fav = _stats['favourable'] ?? 0;
    final pct = _stats['supportPercentage'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 1.7 : 1.45,
          children: [
            _buildStatCard(
              title: 'एकूण सोसायट्या',
              count: total.toString(),
              icon: Icons.apartment_rounded,
              color: const Color(0xFF4F46E5),
              bgColor: const Color(0xFFEEF2FF),
            ),
            _buildStatCard(
              title: 'एकूण मतदार',
              count: voters.toString(),
              icon: Icons.groups_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
            ),
            _buildStatCard(
              title: 'फेवर मतदार',
              count: fav.toString(),
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
            ),
            _buildStatCard(
              title: 'अंदाजे पाठिंबा',
              count: '$pct%',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => _loadData(),
            decoration: InputDecoration(
              hintText: 'सोसायटीचे नाव, अध्यक्ष, सचिव किंवा परिसर शोधा...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadData();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          const SizedBox(height: 10),
          Row(
            children: [
              // Area Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedArea,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('सर्व परिसर (All Areas)')),
                        ..._areas.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedArea = val);
                          _loadData();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('सर्व स्थिती (All Status)')),
                        DropdownMenuItem(value: 'Active', child: Text('सक्रिय (Active)')),
                        DropdownMenuItem(value: 'Inactive', child: Text('निष्क्रिय (Inactive)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _loadData();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoCol = constraints.maxWidth > 700;
        if (isTwoCol) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: _societies.length,
            itemBuilder: (context, index) => _buildSocietyCard(_societies[index]),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _societies.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) => _buildSocietyCard(_societies[index]),
        );
      },
    );
  }

  Widget _buildSocietyCard(HousingSocietyModel soc) {
    final supportPct = soc.supportPercentage;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HousingSocietyDetailScreen(society: soc),
            ),
          ).then((_) => _loadData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title & Action Icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          soc.displayName(true),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'सहकारी गृहनिर्माण संस्था',
                          style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                        tooltip: 'संपादन',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _openAddEditModal(soc),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                        tooltip: 'हटवा',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmDelete(soc),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Chairman & Secretary Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Chairman
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('चेअरमन: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            Text(
                              soc.chairmanName.isNotEmpty ? soc.chairmanName : '-',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        if (soc.chairmanMobile.isNotEmpty)
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _makePhoneCall(soc.chairmanMobile),
                                child: Text(
                                  soc.chairmanMobile,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyToClipboard(soc.chairmanMobile, 'चेअरमन मोबाईल'),
                                child: const Icon(Icons.copy, size: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          )
                        else
                          const Text('-', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    const Divider(height: 12),
                    // Secretary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('सेक्रेटरी: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            Text(
                              soc.secretaryName.isNotEmpty ? soc.secretaryName : '-',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        if (soc.secretaryMobile.isNotEmpty)
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _makePhoneCall(soc.secretaryMobile),
                                child: Text(
                                  soc.secretaryMobile,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyToClipboard(soc.secretaryMobile, 'सेक्रेटरी मोबाईल'),
                                child: const Icon(Icons.copy, size: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          )
                        else
                          const Text('-', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Voter Support Bar & Counts
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('एकूण मतदार: ${soc.voterCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        Text('फेवर मतदार: ${soc.favourableVoterCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        Text('$supportPct% पाठिंबा', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: soc.voterCount > 0 ? (soc.favourableVoterCount / soc.voterCount).clamp(0.0, 1.0) : 0.0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Area & Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            soc.area.isNotEmpty ? soc.area : 'प्रभाग क्र. १२',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: soc.status == 'Active' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: soc.status == 'Active' ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      soc.status == 'Active' ? 'सक्रिय' : 'निष्क्रिय',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: soc.status == 'Active' ? const Color(0xFF047857) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),

              // Notes alert preview if present
              if (soc.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 13, color: Color(0xFFB45309)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          soc.notes,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF0284C7)),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('सोसायटी नाव')),
              DataColumn(label: Text('परिसर')),
              DataColumn(label: Text('चेअरमन व मोबाईल')),
              DataColumn(label: Text('सेक्रेटरी व मोबाईल')),
              DataColumn(label: Text('एकूण मतदार')),
              DataColumn(label: Text('फेवर मतदार')),
              DataColumn(label: Text('पाठिंबा %')),
              DataColumn(label: Text('स्थिती')),
              DataColumn(label: Text('कृती')),
            ],
            rows: List.generate(_societies.length, (index) {
              final soc = _societies[index];
              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                  return index.isEven ? const Color(0xFFF8FAFC) : Colors.white;
                }),
                cells: [
                  DataCell(Text((index + 1).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HousingSocietyDetailScreen(society: soc),
                          ),
                        ).then((_) => _loadData());
                      },
                      child: Text(
                        soc.displayName(true),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  DataCell(Text(soc.area.isNotEmpty ? soc.area : '-')),
                  DataCell(
                    soc.chairmanMobile.isNotEmpty
                        ? InkWell(
                            onTap: () => _makePhoneCall(soc.chairmanMobile),
                            child: Text(
                              '${soc.chairmanName} (${soc.chairmanMobile})',
                              style: const TextStyle(color: Color(0xFF0284C7), decoration: TextDecoration.underline),
                            ),
                          )
                        : Text(soc.chairmanName.isNotEmpty ? soc.chairmanName : '-'),
                  ),
                  DataCell(
                    soc.secretaryMobile.isNotEmpty
                        ? InkWell(
                            onTap: () => _makePhoneCall(soc.secretaryMobile),
                            child: Text(
                              '${soc.secretaryName} (${soc.secretaryMobile})',
                              style: const TextStyle(color: Color(0xFF0284C7), decoration: TextDecoration.underline),
                            ),
                          )
                        : Text(soc.secretaryName.isNotEmpty ? soc.secretaryName : '-'),
                  ),
                  DataCell(Text(soc.voterCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(soc.favourableVoterCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${soc.supportPercentage}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: soc.status == 'Active' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        soc.status == 'Active' ? 'सक्रिय' : 'निष्क्रिय',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: soc.status == 'Active' ? const Color(0xFF047857) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                          tooltip: 'तपशील पहा',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HousingSocietyDetailScreen(society: soc),
                              ),
                            ).then((_) => _loadData());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                          tooltip: 'संपादन',
                          onPressed: () => _openAddEditModal(soc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          tooltip: 'हटवा',
                          onPressed: () => _confirmDelete(soc),
                        ),
                      ],
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

