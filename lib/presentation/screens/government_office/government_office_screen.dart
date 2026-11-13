import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/government_office_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/government_office_repository.dart';
import '../../../data/repositories/team_repository.dart';
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

  String _activeTab = 'Offices'; // 'Offices' | 'Cooperative'
  String _viewMode = 'grid'; // 'grid' | 'table'

  bool _isLoading = true;
  List<GovernmentOfficeModel> _allOffices = [];
  List<TeamMemberModel> _allStaff = [];

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
    try {
      final officeRepo = ref.read(governmentOfficeRepoProvider);
      final teamRepo = ref.read(teamRepoProvider);
      final offices = await officeRepo.getOffices();
      final staff = await teamRepo.getTeamMembers(category: 'Cooperative');
      if (mounted) {
        setState(() {
          _allOffices = offices;
          _allStaff = staff;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<GovernmentOfficeModel> get _filteredOffices {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _allOffices;

    return _allOffices.where((o) {
      return o.name.toLowerCase().contains(query) ||
          o.officerName.toLowerCase().contains(query) ||
          o.contactNumber.toLowerCase().contains(query) ||
          o.address.toLowerCase().contains(query) ||
          o.area.toLowerCase().contains(query);
    }).toList();
  }

  List<TeamMemberModel> get _filteredStaff {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _allStaff;

    return _allStaff.where((s) {
      final inKeywords = s.keywords.any((k) => k.toLowerCase().contains(query));
      return s.name.toLowerCase().contains(query) ||
          (s.nameMarathi?.toLowerCase().contains(query) ?? false) ||
          s.mobile.contains(query) ||
          (s.area?.toLowerCase().contains(query) ?? false) ||
          s.role.toLowerCase().contains(query) ||
          inKeywords;
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

  static Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          if (isRequired) ...[
            const SizedBox(width: 2),
            const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
      prefix: prefix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }

  /// Unified Modal Bottom Sheet styled identically to Requests & Complaints, Letters, and Diary.
  /// Allows switching between Government Office and Cooperative Worker side-by-side so the user
  /// is not forced to exit the page to go to the second entity.
  void _showAddModal({String? initialTab, TeamMemberModel? editingStaff}) {
    final isMr = ref.read(isMarathiProvider);
    String modalTab = editingStaff != null ? 'Cooperative' : (initialTab ?? _activeTab);

    // Office Form Controllers
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final officerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final areaCtrl = TextEditingController();

    // Staff Form Controllers
    final staffNameCtrl = TextEditingController(text: editingStaff?.name ?? '');
    String initMobile = editingStaff?.mobile ?? '';
    initMobile = initMobile.replaceAll('+91', '').trim();
    final staffMobileCtrl = TextEditingController(text: initMobile);
    final staffRoleCtrl = TextEditingController(text: editingStaff?.role ?? '');
    final staffAreaCtrl = TextEditingController(text: editingStaff?.area ?? '');
    final staffKeywordsCtrl = TextEditingController(text: editingStaff?.keywords.join(', ') ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  // Downward Dismiss Drag Handle (styled like complaints & letters)
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header with Title and Close Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          editingStaff != null
                              ? (isMr ? 'कर्मचारी बदल करा' : 'Edit Worker')
                              : (isMr ? 'नवीन नोंद जोडा' : 'Add New Entry'),
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: 14,
                        left: 18,
                        right: 18,
                        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tab Pills (Side-by-Side: Government Office | Cooperative Worker)
                          // Users can switch directly between the two without exiting the page!
                          if (editingStaff == null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _TabPill(
                                      label: isMr ? 'सरकारी कार्यालय' : 'Government Office',
                                      icon: Icons.apartment_rounded,
                                      isActive: modalTab == 'Offices',
                                      onTap: () => setModalState(() => modalTab = 'Offices'),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _TabPill(
                                      label: isMr ? 'सहकारी कर्मचारी' : 'Cooperative Worker',
                                      icon: Icons.handyman_rounded,
                                      isActive: modalTab == 'Cooperative',
                                      onTap: () => setModalState(() => modalTab = 'Cooperative'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // FORM A: Government Office (Strictly 5 fields from Nagarsevak-Managment)
                          if (modalTab == 'Offices') ...[
                            // 1. Office Name (Full Width)
                            _buildFieldLabel(isMr ? 'कार्याल याचे नाव' : 'Office Name', isRequired: true),
                            TextField(
                              controller: nameCtrl,
                              decoration: _inputDecoration(
                                hintText: isMr ? 'उदा. प्रभाग कार्यालय क्र. १२' : 'e.g. PMC Ward Office No. 12',
                                prefixIcon: Icons.apartment_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 2. Address (Full Width)
                            _buildFieldLabel(isMr ? 'पत्ता' : 'Address', isRequired: true),
                            TextField(
                              controller: addrCtrl,
                              maxLines: 2,
                              decoration: _inputDecoration(
                                hintText: isMr ? 'उदा. शनिवार वाड्यासमोर, पुणे - ४११०३०' : 'e.g. Near Shaniwar Wada, Pune - 411030',
                                prefixIcon: Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 3 & 4. Officer In-Charge + Contact Number (Side-by-Side)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(isMr ? 'अधिकारी / प्रमुख' : 'Officer In-charge', isRequired: true),
                                      TextField(
                                        controller: officerCtrl,
                                        decoration: _inputDecoration(
                                          hintText: isMr ? 'उदा. श्री. रमेश गायकवाड' : 'e.g. Shri. Ramesh Gaikwad',
                                          prefixIcon: Icons.person_outline_rounded,
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
                                      _buildFieldLabel(isMr ? 'संपर्क' : 'Contact', isRequired: true),
                                      TextField(
                                        controller: phoneCtrl,
                                        keyboardType: TextInputType.phone,
                                        decoration: _inputDecoration(
                                          hintText: isMr ? 'उदा. ०२०-२५५०११४०' : 'e.g. 020-25501140',
                                          prefixIcon: Icons.phone_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 5. Location / Area (Full Width)
                            _buildFieldLabel(isMr ? 'ठिकाण' : 'Location / Area', isRequired: true),
                            TextField(
                              controller: areaCtrl,
                              decoration: _inputDecoration(
                                hintText: isMr ? 'उदा. शनिवार पेठ' : 'e.g. Shaniwar Peth',
                                prefixIcon: Icons.map_outlined,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Single Submit Button (Wired directly to repo)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.business_rounded, size: 18),
                                onPressed: () async {
                                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isMr ? 'कृपया सर्व आवश्यक माहिती भरा' : 'Please fill required fields'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  final newOffice = GovernmentOfficeModel(
                                    id: 'gov-${DateTime.now().millisecondsSinceEpoch}',
                                    name: nameCtrl.text.trim(),
                                    officerName: officerCtrl.text.trim().isNotEmpty ? officerCtrl.text.trim() : 'Officer In-Charge',
                                    contactNumber: phoneCtrl.text.trim(),
                                    address: addrCtrl.text.trim(),
                                    area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                                    createdAt: DateTime.now().toIso8601String(),
                                  );

                                  final repo = ref.read(governmentOfficeRepoProvider);
                                  await repo.addOffice(newOffice);
                                  await _loadData();

                                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isMr ? 'सरकारी कार्यालय यशस्वीरित्या जोडले गेले!' : 'Office added successfully!'),
                                        backgroundColor: const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                label: Text(
                                  isMr ? 'कार्यालय जतन करा' : 'Save Office',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ),
                          ]

                          // FORM B: Cooperative Staff (Strictly 5 fields from Nagarsevak-Managment)
                          else ...[
                            // 1. Name (Full Width)
                            _buildFieldLabel(isMr ? 'नाव' : 'Name', isRequired: true),
                            TextField(
                              controller: staffNameCtrl,
                              decoration: _inputDecoration(
                                hintText: isMr ? 'उदा. रमेश पाटील' : 'e.g. Ramesh Patil',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 2 & 3. Mobile Number (+91) + Role / Designation (Side-by-Side)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(isMr ? 'मोबाइल नंबर' : 'Mobile Number', isRequired: true),
                                      Row(
                                        children: [
                                          Container(
                                            height: 44,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              border: Border.all(color: const Color(0xFFCBD5E1)),
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                            ),
                                            child: const Text(
                                              '+91',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                            ),
                                          ),
                                          Expanded(
                                            child: SizedBox(
                                              height: 44,
                                              child: TextField(
                                                controller: staffMobileCtrl,
                                                keyboardType: TextInputType.phone,
                                                maxLength: 10,
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                decoration: const InputDecoration(
                                                  counterText: '',
                                                  hintText: '9876543210',
                                                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                                                    borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(isMr ? 'भूमिका / पद' : 'Role / Designation', isRequired: true),
                                      SizedBox(
                                        height: 44,
                                        child: TextField(
                                          controller: staffRoleCtrl,
                                          decoration: _inputDecoration(
                                            hintText: isMr ? 'उदा. वायरमन' : 'e.g. Electrician',
                                            prefixIcon: Icons.badge_outlined,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 4 & 5. Area / Ward + Auto-assign Keywords (Side-by-Side)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(isMr ? 'क्षेत्र / प्रभाग' : 'Area / Ward'),
                                      TextField(
                                        controller: staffAreaCtrl,
                                        decoration: _inputDecoration(
                                          hintText: isMr ? 'उदा. प्रभाग १२' : 'e.g. Ward 12',
                                          prefixIcon: Icons.map_outlined,
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
                                      _buildFieldLabel(isMr ? 'ऑटो-कीवर्ड' : 'Keywords'),
                                      TextField(
                                        controller: staffKeywordsCtrl,
                                        decoration: _inputDecoration(
                                          hintText: isMr ? 'उदा. पाणी, वीज' : 'e.g. water, electric',
                                          prefixIcon: Icons.tag_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Single Submit Button (Wired directly)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.handyman_rounded, size: 18),
                                onPressed: () async {
                                  if (staffNameCtrl.text.trim().isEmpty || staffRoleCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isMr ? 'कृपया नाव आणि पद प्रविष्ट करा' : 'Please fill name and role'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  final cleanMobile = staffMobileCtrl.text.trim();
                                  if (cleanMobile.length != 10) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isMr
                                            ? 'कृपया वैध १० अंकी मोबाइल क्रमांक प्रविष्ट करा'
                                            : 'Please enter valid 10-digit mobile number'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  final fullMobile = '+91$cleanMobile';
                                  final keywordsList = staffKeywordsCtrl.text
                                      .split(',')
                                      .map((k) => k.trim())
                                      .where((k) => k.isNotEmpty)
                                      .toList();

                                  final teamRepo = ref.read(teamRepoProvider);

                                  if (editingStaff != null) {
                                    final updated = editingStaff.copyWith(
                                      name: staffNameCtrl.text.trim(),
                                      mobile: fullMobile,
                                      role: staffRoleCtrl.text.trim(),
                                      area: staffAreaCtrl.text.trim().isNotEmpty ? staffAreaCtrl.text.trim() : null,
                                      category: 'Cooperative',
                                      keywords: keywordsList,
                                    );
                                    await teamRepo.updateTeamMember(updated);
                                  } else {
                                    final newStaff = TeamMemberModel(
                                      id: 'stf-${DateTime.now().millisecondsSinceEpoch}',
                                      name: staffNameCtrl.text.trim(),
                                      mobile: fullMobile,
                                      role: staffRoleCtrl.text.trim(),
                                      area: staffAreaCtrl.text.trim().isNotEmpty ? staffAreaCtrl.text.trim() : null,
                                      category: 'Cooperative',
                                      keywords: keywordsList,
                                      joinedDate: DateTime.now(),
                                      canAssignWork: false,
                                    );
                                    await teamRepo.addTeamMember(newStaff);
                                  }

                                  await _loadData();

                                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          editingStaff != null
                                              ? (isMr ? 'कर्मचारी माहिती अद्यतनित केली!' : 'Worker updated successfully!')
                                              : (isMr ? 'कर्मचारी यशस्वीरित्या जोडला गेला!' : 'Worker added successfully!'),
                                        ),
                                        backgroundColor: const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                label: Text(
                                  editingStaff != null
                                      ? (isMr ? 'अपडेट करा' : 'Update')
                                      : (isMr ? 'जतन करा' : 'Save'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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

  void _showDeleteConfirmation(GovernmentOfficeModel item) {
    final isMr = ref.read(isMarathiProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(isMr ? 'कार्यालय हटवा' : 'Delete Office Entry'),
          ],
        ),
        content: Text(
          isMr
              ? 'आपण खात्रीपूर्वक "${item.name}" हे कार्यालय हटवू इच्छिता? ही क्रिया पूर्ववत करता येणार नाही.'
              : 'Are you sure you want to delete "${item.name}"? This cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? 'रद्द करा' : 'Cancel', style: const TextStyle(color: Color(0xFF64748B))),
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
                  SnackBar(
                    content: Text(isMr ? 'कार्यालय हटवले गेले' : 'Office entry deleted'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(isMr ? 'हटवा' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteStaffConfirmation(TeamMemberModel member) {
    final isMr = ref.read(isMarathiProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(isMr ? 'कर्मचारी हटवा' : 'Delete Worker'),
          ],
        ),
        content: Text(
          isMr
              ? 'आपण खात्रीपूर्वक "${member.name}" यांना यादीतून हटवू इच्छिता?'
              : 'Are you sure you want to delete "${member.name}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? 'रद्द करा' : 'Cancel', style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final teamRepo = ref.read(teamRepoProvider);
              await teamRepo.deleteTeamMember(member.id);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isMr ? 'कर्मचारी हटवला गेला' : 'Worker deleted successfully'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(isMr ? 'हटवा' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final displayedOffices = _filteredOffices;
    final displayedStaff = _filteredStaff;

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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _activeTab == 'Offices'
                    ? (isMr ? 'सरकारी कार्यालये' : 'Government Offices')
                    : (isMr ? 'शासकीय कर्मचारी' : 'Government Employees'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                isMr
                    ? 'महत्वाच्या सरकारी कार्यालयांची व संपर्काची यादी'
                    : 'Directory of important government offices and contacts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: Icon(_activeTab == 'Offices' ? Icons.add_business_rounded : Icons.person_add_alt_1_rounded),
          label: Text(
            _activeTab == 'Offices'
                ? (isMr ? 'नवीन कार्यालय' : 'Add Office')
                : (isMr ? 'नवीन कर्मचारी' : 'Add Staff'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showAddModal(initialTab: _activeTab),
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
                      // Two Tab Bar Switcher (Offices vs Cooperative)
                      _buildTabBar(isMr),

                      // Executive Stat Strip
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            if (_activeTab == 'Offices') ...[
                              _statBox(
                                title: isMr ? 'एकूण कार्यालये' : 'Total Offices',
                                count: '${displayedOffices.length}',
                                color: const Color(0xFF0284C7),
                                bgColor: const Color(0xFFEFF6FF),
                              ),
                              const SizedBox(width: 8),
                              _statBox(
                                title: isMr ? 'कार्यरत विभाग' : 'Active Areas',
                                count: '${_allOffices.map((o) => o.area).toSet().length}',
                                color: const Color(0xFF16A34A),
                                bgColor: const Color(0xFFF0FDF4),
                              ),
                            ] else ...[
                              _statBox(
                                title: isMr ? 'सहकारी कर्मचारी' : 'Total Workers',
                                count: '${displayedStaff.length}',
                                color: const Color(0xFF0284C7),
                                bgColor: const Color(0xFFEFF6FF),
                              ),
                              const SizedBox(width: 8),
                              _statBox(
                                title: isMr ? 'भूमिका प्रकार' : 'Job Roles',
                                count: '${_allStaff.map((s) => s.role).toSet().length}',
                                color: const Color(0xFF16A34A),
                                bgColor: const Color(0xFFF0FDF4),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Search Bar & Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: _activeTab == 'Offices'
                                      ? (isMr ? 'कार्यालय, अधिकारी किंवा विभाग शोधा...' : 'Search by office, officer or area...')
                                      : (isMr ? 'नाव किंवा मोबाइल नंबर शोधा...' : 'Search Name or Mobile...'),
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
                            if (_activeTab == 'Offices') ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _viewMode = _viewMode == 'grid' ? 'table' : 'grid';
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 48,
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
                                  GovOfficeReportGenerator.generateAndPrintOfficeReport(
                                    offices: displayedOffices,
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 48,
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
                          ],
                        ),
                      ),

                      // Content Views
                      if (_activeTab == 'Offices') ...[
                        if (displayedOffices.isEmpty)
                          _buildEmptyState(
                            isMr ? 'कोणतेही कार्यालय सापडले नाही' : 'No Government Offices Found',
                            isMr ? 'कृपया शोध निकष बदला किंवा नवीन कार्यालय जोडा.' : 'Try adjusting your search terms or add an office.',
                          )
                        else if (_viewMode == 'grid')
                          _buildOfficeGrid(displayedOffices, isMr)
                        else
                          _buildOfficeTable(displayedOffices, isMr),
                      ] else ...[
                        if (displayedStaff.isEmpty)
                          _buildEmptyState(
                            isMr ? 'कोणतेही सहकारी कर्मचारी आढळले नाहीत' : 'No Cooperative Workers Found',
                            isMr ? 'कृपया या श्रेणीमध्ये नवीन कर्मचारी जोडा.' : 'Start by adding workers to this category.',
                          )
                        else
                          _buildStaffGrid(displayedStaff, isMr),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTabBar(bool isMr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _activeTab = 'Offices';
                _searchCtrl.clear();
              }),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'Offices' ? const Color(0xFFE0F2FE) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 18,
                      color: _activeTab == 'Offices' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMr ? 'सरकारी कार्यालये' : 'Offices',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _activeTab == 'Offices' ? FontWeight.bold : FontWeight.w600,
                        color: _activeTab == 'Offices' ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _activeTab = 'Cooperative';
                _searchCtrl.clear();
              }),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'Cooperative' ? const Color(0xFFE0F2FE) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.handyman_rounded,
                      size: 18,
                      color: _activeTab == 'Cooperative' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMr ? 'सहकारी कर्मचारी' : 'Cooperative',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _activeTab == 'Cooperative' ? FontWeight.bold : FontWeight.w600,
                        color: _activeTab == 'Cooperative' ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildEmptyState(String title, String desc) {
    return Container(
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
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeGrid(List<GovernmentOfficeModel> items, bool isMr) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = items[index];

        return Container(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Icon(Icons.apartment_rounded, size: 22, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.area,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                    tooltip: isMr ? 'हटवा' : 'Delete',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showDeleteConfirmation(item),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Officer In-Charge
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.officerName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.address,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Contact
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    item.contactNumber,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions: Call Now & Maps & Details
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.call, size: 16),
                      label: Text(
                        isMr ? 'कॉल करा' : 'Call Now',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _makePhoneCall(item.contactNumber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _openMaps(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Icon(Icons.directions_outlined, size: 18, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GovernmentOfficeDetailScreen(office: item)),
                      );
                      if (res == true) _loadData();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffGrid(List<TeamMemberModel> items, bool isMr) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final member = items[index];

        return Container(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Icon(Icons.handyman_rounded, size: 22, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMr ? member.roleLabelMarathi : member.role,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                        tooltip: isMr ? 'बदल करा' : 'Edit',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showAddModal(editingStaff: member),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        tooltip: isMr ? 'हटवा' : 'Delete',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showDeleteStaffConfirmation(member),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Mobile
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    member.mobile,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ],
              ),

              // Area (if present)
              if (member.area != null && member.area!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member.area!,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],

              // Keywords chips (if present)
              if (member.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: member.keywords.map((k) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        k,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),

              // Call Now Button
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: Text(
                    isMr ? 'कॉल करा' : 'Call Now',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _makePhoneCall(member.mobile),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfficeTable(List<GovernmentOfficeModel> items, bool isMr) {
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
              DataColumn(label: Text(isMr ? 'पत्ता' : 'Address', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'अधिकारी' : 'Officer In-Charge', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'संपर्क क्रमांक' : 'Contact No', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'ठिकाण' : 'Location', style: const TextStyle(fontWeight: FontWeight.bold))),
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
                      width: 180,
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        item.address,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}

class _TabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
