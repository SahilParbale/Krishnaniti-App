import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/government_office_model.dart';
import '../../../data/repositories/government_office_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'gov_office_report_generator.dart';
import 'government_office_detail_screen.dart';

class GovernmentOfficeScreen extends ConsumerStatefulWidget {
  const GovernmentOfficeScreen({super.key});

  @override
  ConsumerState<GovernmentOfficeScreen> createState() => _GovernmentOfficeScreenState();
}

class _GovernmentOfficeScreenState extends ConsumerState<GovernmentOfficeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedArea = 'All';
  String _viewMode = 'grid'; // 'grid' | 'table'
  bool _emergencyOnly = false;

  bool _isLoading = true;
  List<GovernmentOfficeModel> _allOffices = [];

  final List<String> _categories = [
    'All',
    'Municipal PMC',
    'Police',
    'MSEDCL Electricity',
    'Water Supply',
    'Health & Hospital',
    'Fire & Disaster',
    'Revenue & Post',
  ];

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
    final repo = ref.read(governmentOfficeRepoProvider);
    final items = await repo.getOffices();
    if (mounted) {
      setState(() {
        _allOffices = items;
        _isLoading = false;
      });
    }
  }

  List<String> get _areas {
    final list = _allOffices.map((o) => o.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
    list.sort();
    return ['All', ...list];
  }

  List<GovernmentOfficeModel> get _filteredOffices {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allOffices.where((o) {
      if (_selectedCategory != 'All' && o.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (_selectedArea != 'All' && !o.area.toLowerCase().contains(_selectedArea.toLowerCase())) {
        return false;
      }
      if (_emergencyOnly && !o.isEmergency) {
        return false;
      }
      if (query.isNotEmpty) {
        final nameMatch = o.name.toLowerCase().contains(query);
        final officerMatch = o.officerName.toLowerCase().contains(query);
        final phoneMatch = o.contactNumber.toLowerCase().contains(query);
        final secPhoneMatch = o.secondaryContact?.toLowerCase().contains(query) ?? false;
        final addrMatch = o.address.toLowerCase().contains(query);
        final areaMatch = o.area.toLowerCase().contains(query);
        final catMatch = o.category.toLowerCase().contains(query);
        if (!nameMatch && !officerMatch && !phoneMatch && !secPhoneMatch && !addrMatch && !areaMatch && !catMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling $phoneNumber...')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $phoneNumber...')),
        );
      }
    }
  }

  Future<void> _openMaps(GovernmentOfficeModel office) async {
    final query = Uri.encodeComponent('${office.name}, ${office.address}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showAddModal() {
    final nameCtrl = TextEditingController();
    final officerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final secPhoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Ward 12');
    final timingCtrl = TextEditingController(text: '9:45 AM - 5:45 PM');
    final emailCtrl = TextEditingController();

    String category = _selectedCategory != 'All' ? _selectedCategory : 'Municipal PMC';
    bool isEmergency = false;

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
                          'Add Government Office',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Category & Emergency Checkbox
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: category,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: _categories
                                    .where((c) => c != 'All')
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => category = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: isEmergency,
                              activeColor: const Color(0xFFDC2626),
                              onChanged: (val) {
                                if (val != null) setModalState(() => isEmergency = val);
                              },
                            ),
                            const Text('24x7 Emergency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Office Name
                    const Text('Office / Authority Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. PMC Ward Office No. 12',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Officer In-Charge
                    const Text('Officer In-Charge & Designation *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: officerCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Shri. Ramesh Gaikwad (Asst. Commissioner)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Primary Phone & Secondary Phone
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Primary Contact No *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 020-25501140',
                                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
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
                              const Text('Alternate Phone / Helpline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: secPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 112 / Toll-free',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Full Address
                    const Text('Address *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addrCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Near Landmark, Road, Peth, Pune - 411030',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Area & Working Hours
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Area / Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Working Hours *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: timingCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 9:45 AM - 5:45 PM',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Email
                    const Text('Official Email (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'e.g. ward12@punecorporation.org',
                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
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
                          if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter name and primary phone number')),
                            );
                            return;
                          }

                          final newOffice = GovernmentOfficeModel(
                            id: 'gov-${DateTime.now().millisecondsSinceEpoch}',
                            name: nameCtrl.text.trim(),
                            officerName: officerCtrl.text.trim().isNotEmpty ? officerCtrl.text.trim() : 'Officer In-Charge',
                            contactNumber: phoneCtrl.text.trim(),
                            secondaryContact: secPhoneCtrl.text.trim().isNotEmpty ? secPhoneCtrl.text.trim() : null,
                            address: addrCtrl.text.trim().isNotEmpty ? addrCtrl.text.trim() : 'Ward 12, Pune',
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                            category: category,
                            timing: timingCtrl.text.trim().isNotEmpty ? timingCtrl.text.trim() : '9:45 AM - 5:45 PM',
                            email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                            isEmergency: isEmergency,
                            createdAt: DateTime.now().toIso8601String(),
                          );

                          final repo = ref.read(governmentOfficeRepoProvider);
                          await repo.addOffice(newOffice);
                          await _loadData();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Government office added successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Government Office', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showDeleteConfirmation(GovernmentOfficeModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Office Entry'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This cannot be undone.',
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
              final repo = ref.read(governmentOfficeRepoProvider);
              await repo.deleteOffice(item.id);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Office entry deleted'), backgroundColor: Colors.red),
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
    final displayed = _filteredOffices;

    final totalCount = displayed.length;
    final emergencyCount = displayed.where((o) => o.isEmergency).length;
    final municipalCount = displayed.where((o) => o.category.toLowerCase().contains('municipal')).length;
    final policeCount = displayed.where((o) => o.category.toLowerCase().contains('police')).length;

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
                'Government Offices',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Ward municipal offices, police stations & emergency directory',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: [
            // Download PDF
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: isMr ? 'अहवाल डाउनलोड करा' : 'Download Directory',
              onPressed: () {
                GovOfficeReportGenerator.generateAndPrintOfficeReport(
                  offices: displayed,
                  categoryFilter: _selectedCategory != 'All' ? _selectedCategory : null,
                  areaFilter: _selectedArea != 'All' ? _selectedArea : null,
                );
              },
            ),
            // View Mode Switcher
            IconButton(
              icon: Icon(
                _viewMode == 'grid' ? Icons.table_chart_rounded : Icons.grid_view_rounded,
                color: Colors.white,
              ),
              tooltip: _viewMode == 'grid' ? 'Switch to Table' : 'Switch to Cards',
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == 'grid' ? 'table' : 'grid';
                });
              },
            ),
            // Refresh
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _loadData,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_business_rounded),
          label: Text(
            isMr ? 'नवीन कार्यालय' : 'Add Office',
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
                              title: isMr ? 'एकूण कार्यालये' : 'Total Offices',
                              count: '$totalCount',
                              color: const Color(0xFF0284C7),
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                            const SizedBox(width: 8),
                            _statBox(
                              title: isMr ? 'आपत्कालीन' : '24x7 Emergency',
                              count: '$emergencyCount',
                              color: const Color(0xFFDC2626),
                              bgColor: const Color(0xFFFEF2F2),
                            ),
                            const SizedBox(width: 8),
                            _statBox(
                              title: isMr ? 'मनपा विभाग' : 'Municipal PMC',
                              count: '$municipalCount',
                              color: const Color(0xFF0369A1),
                              bgColor: const Color(0xFFE0F2FE),
                            ),
                            const SizedBox(width: 8),
                            _statBox(
                              title: isMr ? 'पोलीस ठाणी' : 'Police & Safety',
                              count: '$policeCount',
                              color: const Color(0xFF1E40AF),
                              bgColor: const Color(0xFFEEF2FF),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Search and Filters
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            // Search field
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: isMr
                                    ? 'कार्यालय, अधिकारी, पत्ता किंवा फोन नंबर शोधा...'
                                    : 'Search office, officer, phone, or address...',
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
                            const SizedBox(height: 10),

                            // Category Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Emergency toggle pill
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      selected: _emergencyOnly,
                                      avatar: Icon(
                                        Icons.emergency_outlined,
                                        size: 16,
                                        color: _emergencyOnly ? Colors.white : const Color(0xFFDC2626),
                                      ),
                                      label: Text(
                                        isMr ? 'आपत्कालीन हेल्पलाईन' : 'Emergency Only',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _emergencyOnly ? Colors.white : const Color(0xFFDC2626),
                                        ),
                                      ),
                                      selectedColor: const Color(0xFFDC2626),
                                      backgroundColor: const Color(0xFFFEF2F2),
                                      side: const BorderSide(color: Color(0xFFFECACA)),
                                      onSelected: (val) => setState(() => _emergencyOnly = val),
                                    ),
                                  ),
                                  ..._categories.map((cat) {
                                    final isSelected = _selectedCategory == cat;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        selected: isSelected,
                                        showCheckmark: false,
                                        label: Text(
                                          cat == 'All'
                                              ? (isMr ? 'सर्व कार्यालये' : 'All Offices')
                                              : (isMr ? _getCatLabelMr(cat) : cat),
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
                                          if (val) setState(() => _selectedCategory = cat);
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Area Filter Dropdown
                            Container(
                              height: 44,
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
                                        a == 'All' ? (isMr ? 'सर्व परिसर / प्रभाग' : 'All Areas / Locations') : a,
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
                          ],
                        ),
                      ),

                      // Content List
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
                              Icon(Icons.location_city_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isMr ? 'कोणतेही कार्यालय सापडले नाही' : 'No Government Offices Found',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMr ? 'कृपया शोध निकष बदला किंवा नवीन कार्यालय जोडा.' : 'Try adjusting your search terms or add an office.',
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

  Widget _buildGridCardView(List<GovernmentOfficeModel> items, bool isMr) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = items[index];

        return InkWell(
          onTap: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GovernmentOfficeDetailScreen(office: item)),
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
                // Top Category & Area Tags
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: item.categoryBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.categoryIcon, size: 18, color: item.categoryColor),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.categoryBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: item.categoryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        isMr ? item.categoryDisplayMr : item.category,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.categoryColor),
                      ),
                    ),
                    if (item.isEmergency) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Text(
                          '24x7',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.area,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Office Name
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Officer In-Charge
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.officerName,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.address,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Call & Map Action Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.contactNumber,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.call, size: 13),
                        label: Text(isMr ? 'कॉल' : 'Call', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _makePhoneCall(item.contactNumber),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.directions_outlined, size: 18, color: Color(0xFF0284C7)),
                        tooltip: 'Open Maps',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _openMaps(item),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),

                // Footer row with Details link and Delete action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GovernmentOfficeDetailScreen(office: item)),
                        );
                        if (res == true) _loadData();
                      },
                      child: Row(
                        children: [
                          Text(
                            isMr ? 'सविस्तर संपर्क माहिती' : 'View Full Details',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0284C7)),
                        ],
                      ),
                    ),
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
          ),
        );
      },
    );
  }

  Widget _buildTableView(List<GovernmentOfficeModel> items, bool isMr) {
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
              DataColumn(label: Text(isMr ? 'कार्यालय नाव' : 'Office Name', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'अधिकारी' : 'Officer In-Charge', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'संपर्क क्रमांक' : 'Contact No', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'विभाग' : 'Category', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'परिसर' : 'Area', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'कृती' : 'Actions', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;

              return DataRow(
                cells: [
                  DataCell(Text('$idx')),
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(item.timing, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(item.officerName, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    InkWell(
                      onTap: () => _makePhoneCall(item.contactNumber),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.call, size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            item.contactNumber,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.categoryBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMr ? item.categoryDisplayMr : item.category,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: item.categoryColor),
                      ),
                    ),
                  ),
                  DataCell(Text(item.area, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone_forwarded, size: 16, color: Color(0xFF16A34A)),
                          tooltip: 'Call',
                          onPressed: () => _makePhoneCall(item.contactNumber),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                          tooltip: 'View Details',
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GovernmentOfficeDetailScreen(office: item)),
                            );
                            if (res == true) _loadData();
                          },
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
    );
  }

  static String _getCatLabelMr(String cat) {
    switch (cat.toLowerCase()) {
      case 'police':
        return 'पोलीस ठाणे';
      case 'fire & disaster':
      case 'emergency':
        return 'अग्निशमन';
      case 'msedcl electricity':
        return 'महावितरण';
      case 'water supply':
        return 'पाणी पुरवठा';
      case 'health & hospital':
        return 'आरोग्य';
      case 'revenue & post':
        return 'महसूल';
      case 'municipal pmc':
      default:
        return 'मनपा क्षेत्रीय';
    }
  }
}

