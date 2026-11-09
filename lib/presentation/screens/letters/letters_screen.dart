import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/letter_model.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'letter_detail_screen.dart';
import '../../navigation/app_drawer.dart';

class LettersScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onTabChange;

  const LettersScreen({super.key, this.onTabChange});

  @override
  ConsumerState<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends ConsumerState<LettersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // Tabs: true = Outgoing Letters, false = Incoming Letters
  bool _isOutgoing = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'
  bool _isLoading = false;

  List<LetterModel> _outgoingLetters = [];
  List<LetterModel> _incomingLetters = [];

  // Default Mock Outgoing Letters matching Nagarsevak-Managment
  final List<LetterModel> _defaultOutgoingLetters = [
    LetterModel(
      id: 'REQ-LTR-101',
      title: 'College Engineering Scholarship Recommendation',
      letterType: 'Recommendation Letter',
      department: 'Education Desk',
      recipient: 'Rohit Vinod Pawar',
      sender: 'Nagarsevak Office',
      userId: 'Rohit Vinod Pawar',
      area: 'Sector 3',
      details: {
        'name': 'Rohit Vinod Pawar',
        'subject': 'Higher Education Engineering Scholarship Endorsement',
        'address': 'Flat 402, Sai Shraddha Apts, Ward 12, Sector 3',
        'purpose': 'College fees endorsement for merit scholarship',
        'mobile': '9822044556',
      },
      status: 'Pending',
      isIncoming: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    LetterModel(
      id: 'REQ-LTR-102',
      title: 'Residence Proof for CM Relief Fund Hospitalization',
      letterType: 'Residence Proof Certificate',
      department: 'Welfare Desk',
      recipient: 'Parvati Bai Kamble',
      sender: 'Nagarsevak Office',
      userId: 'Parvati Bai Kamble',
      area: 'Shivaji Nagar',
      details: {
        'name': 'Parvati Bai Kamble',
        'subject': 'CM Medical Relief Fund Address Verification',
        'address': 'House No. 45, Shivaji Nagar, Ward 12',
        'purpose': 'Open heart surgery financial assistance at Sancheti Hospital',
        'mobile': '9822011223',
      },
      status: 'Approved',
      isIncoming: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    LetterModel(
      id: 'REQ-LTR-103',
      title: 'Commercial Electricity Meter Connection NOC',
      letterType: 'Electricity NOC Endorsement',
      department: 'Trade & Commerce',
      recipient: 'Amit Suresh Deshmukh',
      sender: 'Nagarsevak Office',
      userId: 'Amit Suresh Deshmukh',
      area: 'MG Road',
      details: {
        'name': 'Amit Suresh Deshmukh',
        'subject': 'New 3-Phase Commercial Electricity Meter NOC',
        'address': 'Shop No. 12, MG Road Market Complex, Ward 12',
        'purpose': 'MSEDCL New Power Connection',
        'mobile': '9876543212',
      },
      status: 'Approved',
      isIncoming: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    LetterModel(
      id: 'REQ-LTR-104',
      title: 'Police Department Recruitment Character Verification',
      letterType: 'Character Certificate',
      department: 'General Admin',
      recipient: 'Swapnil Ganesh Mane',
      sender: 'Nagarsevak Office',
      userId: 'Swapnil Ganesh Mane',
      area: 'Sector 4',
      details: {
        'name': 'Swapnil Ganesh Mane',
        'subject': 'Police Recruitment Bonafide Verification',
        'address': 'Lane 4, Near Ganpati Mandir, Sector 4, Ward 12',
        'purpose': 'Government employment document verification',
        'mobile': '9822033445',
      },
      status: 'Pending',
      isIncoming: false,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // Default Mock Incoming Letters matching Nagarsevak-Managment
  final List<LetterModel> _defaultIncomingLetters = [
    LetterModel(
      id: 'INC-LTR-201',
      title: 'Municipal Corporation Notice: Pre-Monsoon Drainage Desilting',
      letterType: 'Municipal Circular',
      department: 'PMC Drainage Dept',
      description: 'Official circular from Municipal Drainage Division regarding desilting schedule for Prabhag 12.',
      area: 'Prabhag 12 Ward Office',
      fileType: 'application/pdf',
      status: 'Received',
      isIncoming: true,
      receivedDate: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    LetterModel(
      id: 'INC-LTR-202',
      title: 'MSEDCL Substation Maintenance & Feeder Shutdown Notice',
      letterType: 'Power Board Notice',
      department: 'MSEDCL Division',
      description: 'Intimation of scheduled maintenance shutdown of 11KV overhead feeder line on Station Road.',
      area: 'Station Road',
      fileType: 'image/jpeg',
      letterUrl: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=800',
      status: 'Received',
      isIncoming: true,
      receivedDate: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    LetterModel(
      id: 'INC-LTR-203',
      title: 'Citizen Delegation Memorandum: Children Community Garden Swings',
      letterType: 'Citizen Petition',
      department: 'Garden Dept',
      description: 'Joint memorandum signed by 45 residents of Shanti Nagar requesting swings, benches & solar lights.',
      area: 'Shanti Nagar',
      fileType: 'image/jpeg',
      letterUrl: 'https://images.unsplash.com/photo-1568667256549-094345857637?w=800',
      status: 'Received',
      isIncoming: true,
      receivedDate: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _outgoingLetters = List.from(_defaultOutgoingLetters);
    _incomingLetters = List.from(_defaultIncomingLetters);
    _fetchLetters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLetters() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(lettersRepoProvider);
      final outRes = await repo.getLetters(isIncoming: false);
      final inRes = await repo.getLetters(isIncoming: true);

      if (mounted) {
        setState(() {
          if (outRes.isNotEmpty) _outgoingLetters = outRes;
          if (inRes.isNotEmpty) _incomingLetters = inRes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LetterModel> get _currentList {
    return _isOutgoing ? _outgoingLetters : _incomingLetters;
  }

  List<LetterModel> get _filteredLetters {
    return _currentList.where((l) {
      if (_isOutgoing && _selectedStatus != 'All') {
        if (l.status.toLowerCase() != _selectedStatus.toLowerCase()) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = l.id.toLowerCase().contains(q) ||
            l.title.toLowerCase().contains(q) ||
            l.citizenName.toLowerCase().contains(q) ||
            (l.area != null && l.area!.toLowerCase().contains(q)) ||
            (l.letterType != null && l.letterType!.toLowerCase().contains(q)) ||
            (l.description != null && l.description!.toLowerCase().contains(q));
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _openDetailScreen(LetterModel letter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LetterDetailScreen(letter: letter),
      ),
    ).then((_) => _fetchLetters());
  }

  void _shareOnWhatsApp(LetterModel letter) async {
    final text = Uri.encodeComponent(
      'Official Correspondence: ${letter.title}\n'
      'Type: ${letter.letterType ?? 'Official Letter'}\n'
      'Status: ${letter.status}\n'
      'Citizen: ${letter.citizenName}\n'
      'Nagarsevak Office, Prabhag 12',
    );
    final cleanMobile = letter.mobile.replaceAll(RegExp(r'\D'), '');
    final uri = cleanMobile.isNotEmpty
        ? Uri.parse('https://wa.me/91$cleanMobile?text=$text')
        : Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Open Create Outgoing Letter Modal
  void _openCreateLetterModal() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    String selectedType = 'Recommendation Letter';

    final types = [
      'Recommendation Letter',
      'Residence Proof Certificate',
      'Electricity NOC Endorsement',
      'Character Certificate',
      'Sanitation Clearance Letter',
      'Water Supply Endorsement',
      'General Official Letter',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create Outgoing Letter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text('Letter Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedType,
                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Citizen Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Ramesh Patil',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. 9822012345',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Subject / Purpose *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: subjectCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Higher Education Scholarship Endorsement',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Citizen Address / Area', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Ward 12, Sector 3, Near Ganpati Mandir',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final subj = subjectCtrl.text.trim();
                        if (name.isEmpty || subj.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill citizen name and subject.')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        final newLetter = LetterModel(
                          id: 'REQ-LTR-${DateTime.now().millisecondsSinceEpoch % 10000}',
                          title: subj,
                          letterType: selectedType,
                          recipient: name,
                          sender: 'Nagarsevak Office',
                          userId: name,
                          area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                          details: {
                            'name': name,
                            'subject': subj,
                            'address': addressCtrl.text.trim(),
                            'purpose': subj,
                            'mobile': mobileCtrl.text.trim(),
                          },
                          status: 'Pending',
                          isIncoming: false,
                          createdAt: DateTime.now(),
                        );

                        setState(() {
                          _outgoingLetters.insert(0, newLetter);
                        });

                        try {
                          await ref.read(lettersRepoProvider).createLetterRequest(
                                type: selectedType,
                                name: name,
                                subject: subj,
                                address: addressCtrl.text.trim(),
                                purpose: subj,
                                area: areaCtrl.text.trim(),
                                mobile: mobileCtrl.text.trim(),
                              );
                        } catch (_) {}
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save & Issue', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Open Scan / Upload Incoming Letter Modal
  void _openUploadIncomingModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    String? localPhotoPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scan Incoming Letter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text('Letter / Circular Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. PMC Pre-Monsoon Drainage Circular',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Sender / Department / Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Letter from PMC Drainage division regarding...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Attach Scanned File / Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(source: ImageSource.camera);
                          if (file != null) setSheetState(() => localPhotoPath = file.path);
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('Camera', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(source: ImageSource.gallery);
                          if (file != null) setSheetState(() => localPhotoPath = file.path);
                        },
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Gallery', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),

                if (localPhotoPath != null) ...[
                  const SizedBox(height: 8),
                  Text('Attached: ${localPhotoPath!.split(RegExp(r'[/\\]')).last}', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                ],

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter letter title.')));
                            return;
                          }
                          Navigator.pop(ctx);
                          final newIncoming = LetterModel(
                            id: 'INC-LTR-${DateTime.now().millisecondsSinceEpoch % 10000}',
                            title: title,
                            letterType: 'Incoming Letter',
                            description: descCtrl.text.trim(),
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12 Office',
                            fileType: 'image/jpeg',
                            letterUrl: localPhotoPath,
                            status: 'Received',
                            isIncoming: true,
                            receivedDate: DateTime.now(),
                            createdAt: DateTime.now(),
                          );

                          setState(() => _incomingLetters.insert(0, newIncoming));

                          try {
                            await ref.read(lettersRepoProvider).uploadIncomingLetter(
                                  title: title,
                                  description: descCtrl.text.trim(),
                                  area: areaCtrl.text.trim(),
                                  receivedDate: DateTime.now(),
                                  fileUrl: localPhotoPath ?? '',
                                  fileType: 'image/jpeg',
                                );
                          } catch (_) {}
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Save & Archive', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isMr = ref.watch(isMarathiProvider);
    final filtered = _filteredLetters;

    final outCount = _outgoingLetters.length;
    final inCount = _incomingLetters.length;

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
        drawer: NagarsevakAppDrawer(
          currentTabIndex: 2,
          onTabChange: widget.onTabChange,
        ),
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
                'Letters & Outward Inward',
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
                'Ward correspondence & inward outward',
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
            // Top Inward / Outward Navigation Tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Outgoing Tab Button
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isOutgoing = true),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _isOutgoing ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _isOutgoing
                                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_made_rounded,
                                size: 16,
                                color: _isOutgoing ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${isMr ? AppStrings.outgoingLettersMr : AppStrings.outgoingLetters} ($outCount)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _isOutgoing ? FontWeight.w800 : FontWeight.w600,
                                  color: _isOutgoing ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Incoming Tab Button
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isOutgoing = false),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: !_isOutgoing ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !_isOutgoing
                                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_received_rounded,
                                size: 16,
                                color: !_isOutgoing ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${isMr ? AppStrings.incomingLettersMr : AppStrings.incomingLetters} ($inCount)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: !_isOutgoing ? FontWeight.w800 : FontWeight.w600,
                                  color: !_isOutgoing ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar & Filters
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: isMr ? 'पत्र, नागरिक किंवा विषय शोधा...' : 'Search letters, citizen, subject...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 19),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  // Status filter for Outgoing letters
                  if (_isOutgoing) ...[
                    const SizedBox(width: 8),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Status', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'Approved', child: Text('Approved', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'Rejected', child: Text('Rejected', style: TextStyle(fontSize: 12.5))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Letters List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mail_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isMr ? AppStrings.noDataFoundMr : AppStrings.noDataFound,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchLetters,
                          color: const Color(0xFF0284C7),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final item = filtered[idx];
                              return _LetterCard(
                                letter: item,
                                isMr: isMr,
                                onTap: () => _openDetailScreen(item),
                                onWhatsApp: () => _shareOnWhatsApp(item),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),

        // Floating Action Button (+ New Outgoing or + Scan Incoming)
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isOutgoing ? _openCreateLetterModal : _openUploadIncomingModal,
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: Icon(_isOutgoing ? Icons.add_rounded : Icons.document_scanner_outlined, size: 20),
          label: Text(
            _isOutgoing
                ? (isMr ? AppStrings.newLetterMr : AppStrings.newLetter)
                : (isMr ? AppStrings.scanLetterMr : AppStrings.scanLetter),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LETTER CARD WIDGET
// -----------------------------------------------------------------------------
class _LetterCard extends StatelessWidget {
  final LetterModel letter;
  final bool isMr;
  final VoidCallback onTap;
  final VoidCallback onWhatsApp;

  const _LetterCard({
    required this.letter,
    required this.isMr,
    required this.onTap,
    required this.onWhatsApp,
  });

  Color get _leftBorderColor {
    if (letter.isIncoming) return const Color(0xFF0284C7);
    final s = letter.status.toLowerCase();
    if (s == 'approved') return const Color(0xFF16A34A);
    if (s == 'rejected') return const Color(0xFFDC2626);
    if (s == 'pending') return const Color(0xFFEAB308);
    return const Color(0xFFCBD5E1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Color Bar matching status
              Container(width: 4.5, color: _leftBorderColor),

              // Card Body
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Type Pill & Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: letter.isIncoming ? const Color(0xFFE0F2FE) : const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                letter.letterType ?? 'Official',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: letter.isIncoming ? const Color(0xFF0369A1) : const Color(0xFF7E22CE),
                                ),
                              ),
                            ),
                            _buildStatusBadge(letter.status, isMr),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Title / Subject
                        Text(
                          letter.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Citizen Name / Department
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                letter.citizenName,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 8),

                        // Footer Row: Area, Date, WhatsApp, Details Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (letter.area != null && letter.area!.isNotEmpty) ...[
                                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 2),
                                    Text(
                                      letter.area!,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('MMM d').format(letter.receivedDate ?? letter.createdAt),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: onWhatsApp,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF6EE7B7)),
                                    ),
                                    child: const Icon(Icons.chat_rounded, size: 14, color: Color(0xFF059669)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Details',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF0284C7)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isMr) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF166534);
        label = isMr ? 'मंजूर' : 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFB91C1C);
        label = isMr ? 'नाकारले' : 'Rejected';
        break;
      case 'received':
        bg = const Color(0xFFDBEAFE);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF1E40AF);
        label = isMr ? 'प्राप्त' : 'Received';
        break;
      default:
        bg = const Color(0xFFFEFCE8);
        border = const Color(0xFFFDE047);
        text = const Color(0xFF854D0E);
        label = isMr ? 'प्रलंबित' : 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}
