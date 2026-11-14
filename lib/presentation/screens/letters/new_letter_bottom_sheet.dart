import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/letters_repository.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../providers/auth_provider.dart';
import 'letter_form_constants.dart';

/// Modal Bottom Sheet that slides up from the bottom with downward-dismiss capability,
/// matching the EXACT form fields, labels, placeholders, and structure of Nagarsevak-Managment
/// (LetterForm.tsx & IncomingLetterUpload.tsx).
class NewLetterBottomSheet extends ConsumerStatefulWidget {
  final String initialTab; // 'outgoing' | 'incoming'
  final String? prefillVoterId;
  final String? prefillVoterName;

  const NewLetterBottomSheet({
    super.key,
    this.initialTab = 'outgoing',
    this.prefillVoterId,
    this.prefillVoterName,
  });

  static Future<bool?> show(
    BuildContext context, {
    String initialTab = 'outgoing',
    String? prefillVoterId,
    String? prefillVoterName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => NewLetterBottomSheet(
        initialTab: initialTab,
        prefillVoterId: prefillVoterId,
        prefillVoterName: prefillVoterName,
      ),
    );
  }

  @override
  ConsumerState<NewLetterBottomSheet> createState() =>
      _NewLetterBottomSheetState();
}

class _NewLetterBottomSheetState extends ConsumerState<NewLetterBottomSheet> {
  late String _activeTab; // 'outgoing' | 'incoming'

  // Linked Voter
  String? _selectedVoterId;
  String? _linkedVoterDisplay;

  // Outgoing Form Controllers (matching LetterForm.tsx)
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController(text: '+91 ');
  String _selectedGender = 'Male';
  String _selectedLetterType = 'Residential Certificate';
  final _areaCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();

  // Dynamic Additional Details Controllers & Keys (matching LetterForm.tsx lines 600-628)
  final Map<String, TextEditingController> _dynamicControllers = {};
  List<String> _activeDynamicFieldKeys = [];

  // Incoming Form Controllers (matching IncomingLetterUpload.tsx)
  final _incomingTitleCtrl = TextEditingController();
  final _incomingDescCtrl = TextEditingController();
  final _incomingAreaCtrl = TextEditingController();
  final _bearerFirstNameCtrl = TextEditingController();
  final _bearerMiddleNameCtrl = TextEditingController();
  final _bearerLastNameCtrl = TextEditingController();
  final _bearerMobileCtrl = TextEditingController(text: '+91 ');
  DateTime _receivedDate = DateTime.now();

  // Staff Dropdown (ALWAYS visible with presets)
  static final List<StaffModel> _fallbackStaffList = [
    StaffModel(id: 'staff-1', name: 'Sunil Shinde', role: 'Electrical JE', mobile: '9822012345'),
    StaffModel(id: 'staff-2', name: 'Santosh Gaikwad', role: 'Sanitation Sup.', mobile: '9822023456'),
    StaffModel(id: 'staff-3', name: 'Pradeep Joshi', role: 'Water Works Dept', mobile: '9822034567'),
    StaffModel(id: 'staff-4', name: 'Anand Jadhav', role: 'Road Engineering', mobile: '9822045678'),
    StaffModel(id: 'staff-5', name: 'Mahesh Patil', role: 'Ward Officer', mobile: '9822056789'),
  ];
  List<StaffModel> _staffList = [];
  String? _selectedStaffId;

  // Attachments
  final List<XFile> _pickedFiles = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;

  bool get _hasAnyDraft {
    if (_activeTab == 'outgoing') {
      return _firstNameCtrl.text.isNotEmpty ||
          _lastNameCtrl.text.isNotEmpty ||
          (_mobileCtrl.text.isNotEmpty && _mobileCtrl.text != '+91 ') ||
          _subjectCtrl.text.isNotEmpty ||
          _addressCtrl.text.isNotEmpty ||
          _purposeCtrl.text.isNotEmpty ||
          _areaCtrl.text.isNotEmpty ||
          _pickedFiles.isNotEmpty ||
          _dynamicControllers.values.any((c) => c.text.isNotEmpty);
    } else {
      return _incomingTitleCtrl.text.isNotEmpty ||
          _incomingDescCtrl.text.isNotEmpty ||
          _bearerFirstNameCtrl.text.isNotEmpty ||
          (_bearerMobileCtrl.text.isNotEmpty && _bearerMobileCtrl.text != '+91 ') ||
          _pickedFiles.isNotEmpty;
    }
  }

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab == 'incoming' ? 'incoming' : 'outgoing';
    _staffList = List.from(_fallbackStaffList);
    _syncDynamicFields(_selectedLetterType);

    if (widget.prefillVoterId != null) {
      _selectedVoterId = widget.prefillVoterId;
      _linkedVoterDisplay = widget.prefillVoterName;
      if (widget.prefillVoterName != null) {
        _splitAndFillName(widget.prefillVoterName!);
      }
    }

    _loadStaff();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _mobileCtrl.dispose();
    _areaCtrl.dispose();
    _subjectCtrl.dispose();
    _addressCtrl.dispose();
    _purposeCtrl.dispose();
    for (final c in _dynamicControllers.values) {
      c.dispose();
    }
    _incomingTitleCtrl.dispose();
    _incomingDescCtrl.dispose();
    _incomingAreaCtrl.dispose();
    _bearerFirstNameCtrl.dispose();
    _bearerMiddleNameCtrl.dispose();
    _bearerLastNameCtrl.dispose();
    _bearerMobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final list = await ref.read(complaintsRepoProvider).getStaffList();
      if (mounted && list.isNotEmpty) {
        setState(() => _staffList = list);
      }
    } catch (_) {}
  }

  void _splitAndFillName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (_activeTab == 'outgoing') {
      if (parts.isNotEmpty) _firstNameCtrl.text = parts[0];
      if (parts.length == 2) {
        _lastNameCtrl.text = parts[1];
      } else if (parts.length >= 3) {
        _middleNameCtrl.text = parts[1];
        _lastNameCtrl.text = parts.sublist(2).join(' ');
      }
    } else {
      if (parts.isNotEmpty) _bearerFirstNameCtrl.text = parts[0];
      if (parts.length == 2) {
        _bearerLastNameCtrl.text = parts[1];
      } else if (parts.length >= 3) {
        _bearerMiddleNameCtrl.text = parts[1];
        _bearerLastNameCtrl.text = parts.sublist(2).join(' ');
      }
    }
  }

  void _handleVoterSelected(VoterModel voter) {
    final name = voter.nameEnglish.isNotEmpty ? voter.nameEnglish : voter.nameMarathi;
    setState(() {
      _selectedVoterId = voter.id;
      _linkedVoterDisplay = name;
      _splitAndFillName(name);

      final mob = voter.mobile;
      if (_activeTab == 'outgoing') {
        if (mob != null && mob.isNotEmpty) {
          _mobileCtrl.text = mob.startsWith('+91') ? mob : '+91 $mob';
        }
        if (voter.address.isNotEmpty) {
          _addressCtrl.text = voter.address;
          _areaCtrl.text = voter.address;
        }
        if (voter.gender.toUpperCase() == 'M') {
          _selectedGender = 'Male';
        } else if (voter.gender.toUpperCase() == 'F') {
          _selectedGender = 'Female';
        }
      } else {
        if (mob != null && mob.isNotEmpty) {
          _bearerMobileCtrl.text = mob.startsWith('+91') ? mob : '+91 $mob';
        }
        if (voter.address.isNotEmpty) {
          _incomingAreaCtrl.text = voter.address;
        }
      }
    });
    HapticFeedback.lightImpact();
  }

  void _clearLinkedVoter() {
    setState(() {
      _selectedVoterId = null;
      _linkedVoterDisplay = null;
      if (_activeTab == 'outgoing') {
        _firstNameCtrl.clear();
        _middleNameCtrl.clear();
        _lastNameCtrl.clear();
        _mobileCtrl.text = '+91 ';
        _addressCtrl.clear();
        _areaCtrl.clear();
      } else {
        _bearerFirstNameCtrl.clear();
        _bearerMiddleNameCtrl.clear();
        _bearerLastNameCtrl.clear();
        _bearerMobileCtrl.text = '+91 ';
        _incomingAreaCtrl.clear();
      }
    });
  }

  void _handleClearAllDrafts() {
    setState(() {
      _selectedVoterId = null;
      _linkedVoterDisplay = null;
      _firstNameCtrl.clear();
      _middleNameCtrl.clear();
      _lastNameCtrl.clear();
      _mobileCtrl.text = '+91 ';
      _areaCtrl.clear();
      _subjectCtrl.clear();
      _addressCtrl.clear();
      _purposeCtrl.clear();
      for (final c in _dynamicControllers.values) {
        c.clear();
      }
      _incomingTitleCtrl.clear();
      _incomingDescCtrl.clear();
      _incomingAreaCtrl.clear();
      _bearerFirstNameCtrl.clear();
      _bearerMiddleNameCtrl.clear();
      _bearerLastNameCtrl.clear();
      _bearerMobileCtrl.text = '+91 ';
      _pickedFiles.clear();
      _selectedStaffId = null;
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Draft cleared'),
        backgroundColor: const Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickFile(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 75);
      if (file != null) {
        setState(() => _pickedFiles.add(file));
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (_activeTab == 'outgoing') {
      final fName = _firstNameCtrl.text.trim();
      final lName = _lastNameCtrl.text.trim();
      final fullName = [fName, _middleNameCtrl.text.trim(), lName].where((s) => s.isNotEmpty).join(' ');
      final rawMobile = _mobileCtrl.text.trim();
      final mobile = (rawMobile == '+91' || rawMobile == '+91 ') ? '' : rawMobile;

      if (fName.isEmpty) {
        _showToast('Please enter First Name (पहिले नाव आवश्यक आहे)', isError: true);
        return;
      }
      if (lName.isEmpty) {
        _showToast('Please enter Last Name (आडनाव आवश्यक आहे)', isError: true);
        return;
      }
      if (mobile.isEmpty) {
        _showToast('Please enter Mobile Number (मोबाईल नंबर आवश्यक आहे)', isError: true);
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        final repo = ref.read(lettersRepoProvider);
        final attachments = _pickedFiles.map((f) => f.path).toList();

        final Map<String, dynamic> additionalDetails = {};
        for (final key in _activeDynamicFieldKeys) {
          final ctrl = _dynamicControllers[key];
          if (ctrl != null && ctrl.text.trim().isNotEmpty) {
            additionalDetails[key] = ctrl.text.trim();
          }
        }

        await repo.createLetterRequest(
          type: _selectedLetterType,
          name: fullName,
          subject: _subjectCtrl.text.trim().isNotEmpty ? _subjectCtrl.text.trim() : '$_selectedLetterType - $fullName',
          address: _addressCtrl.text.trim(),
          purpose: _purposeCtrl.text.trim().isNotEmpty ? _purposeCtrl.text.trim() : _selectedLetterType,
          area: _areaCtrl.text.trim().isNotEmpty ? _areaCtrl.text.trim() : null,
          mobile: mobile,
          gender: _selectedGender,
          voterId: _selectedVoterId,
          addedByStaffId: _selectedStaffId,
          attachments: attachments,
          additionalDetails: additionalDetails,
        );

        if (mounted) {
          _showToast('Letter Request created successfully! (पत्र विनंती तयार झाली)');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) _showToast('Failed to save request: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      // Incoming Letter
      final title = _incomingTitleCtrl.text.trim();
      if (title.isEmpty) {
        _showToast('Please enter Letter Title (पत्राचे शीर्षक आवश्यक आहे)', isError: true);
        return;
      }

      final bearerName = [
        _bearerFirstNameCtrl.text.trim(),
        _bearerMiddleNameCtrl.text.trim(),
        _bearerLastNameCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).join(' ');

      final rawMobile = _bearerMobileCtrl.text.trim();
      final bearerMobile = (rawMobile == '+91' || rawMobile == '+91 ') ? '' : rawMobile;

      setState(() => _isSubmitting = true);
      try {
        final repo = ref.read(lettersRepoProvider);
        final fileUrl = _pickedFiles.isNotEmpty ? _pickedFiles.first.path : '';

        await repo.uploadIncomingLetter(
          title: title,
          description: _incomingDescCtrl.text.trim(),
          area: _incomingAreaCtrl.text.trim().isNotEmpty ? _incomingAreaCtrl.text.trim() : null,
          receivedDate: _receivedDate,
          fileUrl: fileUrl,
          fileType: fileUrl.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
          bearerName: bearerName.isNotEmpty ? bearerName : null,
          bearerMobile: bearerMobile.isNotEmpty ? bearerMobile : null,
          addedByStaffId: _selectedStaffId,
          voterId: _selectedVoterId,
        );

        if (mounted) {
          _showToast('Incoming letter uploaded successfully! (आवक पत्र जतन झाले)');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) _showToast('Failed to upload letter: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _syncDynamicFields(String letterType) {
    final defaultKeys = kDefaultLetterTypeFields[letterType] ?? ['ward_no', 'reason_for_certificate'];
    setState(() {
      _activeDynamicFieldKeys = List.from(defaultKeys);
      for (final key in _activeDynamicFieldKeys) {
        if (!_dynamicControllers.containsKey(key)) {
          _dynamicControllers[key] = TextEditingController();
        }
      }
    });
  }

  bool _isDefaultFieldForSelectedType(String key) {
    final defaults = kDefaultLetterTypeFields[_selectedLetterType] ?? [];
    return defaults.contains(key);
  }

  void _openAddFieldDialog(bool isMr) {
    final available = kDynamicFieldDefinitions.keys
        .where((k) => !_activeDynamicFieldKeys.contains(k))
        .toList();
    final customFieldCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'अतिरिक्त माहितीचे फील्ड जोडा' : 'Add Additional Field',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Custom field input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customFieldCtrl,
                          decoration: InputDecoration(
                            hintText: isMr ? 'किंवा नवीन फील्डचे नाव टाका...' : 'Or enter custom field name...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final customName = customFieldCtrl.text.trim();
                          if (customName.isNotEmpty) {
                            final key = customName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                            if (!_activeDynamicFieldKeys.contains(key)) {
                              Navigator.pop(ctx);
                              setState(() {
                                _activeDynamicFieldKeys.add(key);
                                _dynamicControllers.putIfAbsent(key, () => TextEditingController());
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(isMr ? 'जोडा' : 'Add'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Text(
                    isMr ? 'किंवा यादीतून निवडा:' : 'Or choose from standard fields:',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (_, idx) {
                        final key = available[idx];
                        final meta = kDynamicFieldDefinitions[key]!;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7), size: 20),
                          title: Text(
                            isMr ? meta.mrLabel : meta.enLabel,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          subtitle: Text(
                            isMr ? meta.enLabel : meta.mrLabel,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _activeDynamicFieldKeys.add(key);
                              _dynamicControllers.putIfAbsent(key, () => TextEditingController());
                            });
                          },
                        );
                      },
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

  void _openVoterSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoterSearchModalSheet(
        onSelect: (voter) {
          _handleVoterSelected(voter);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _pickReceivedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0284C7),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _receivedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Downward Drag Handle
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

            // Top Header matching LetterForm.tsx & IncomingLetterUpload.tsx
            _buildTopCardHeader(isMr),

            // Tab Selector: Outgoing vs Incoming
            _buildTabSelector(isMr),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_activeTab == 'outgoing')
                      _buildOutgoingForm(isMr)
                    else
                      _buildIncomingForm(isMr),

                    const SizedBox(height: 24),

                    // Submit Action Button
                    _buildSubmitButton(isMr),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP CARD HEADER
  // ---------------------------------------------------------------------------
  Widget _buildTopCardHeader(bool isMr) {
    final titleText = _activeTab == 'outgoing'
        ? (isMr ? 'नवीन पत्र विनंती' : 'New Letter Request')
        : (isMr ? 'आवक पत्र अपलोड करा' : 'Upload Incoming Letter');

    final subtitleText = isMr
        ? 'अधिकृत पत्र विनंत्यांचा मागोवा घ्या आणि व्यवस्थापित करा'
        : 'Track and manage official letter requests';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F9FF),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                if (_linkedVoterDisplay != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${isMr ? "मतदाराशी जोडले:" : "Linking to Voter:"} ',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                      ),
                      Text(
                        _linkedVoterDisplay!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (_hasAnyDraft) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isMr ? 'मसुदा सेव्ह केला' : 'Draft autosaved',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleClearAllDrafts,
              child: Text(
                isMr ? 'काढून टाका' : 'Clear draft',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFDC2626),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: Color(0xFF64748B)),
            tooltip: 'Dismiss downwards',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB SELECTOR: OUTGOING vs INCOMING
  // ---------------------------------------------------------------------------
  Widget _buildTabSelector(bool isMr) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
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
              label: isMr ? 'जावक पत्र (Outgoing)' : 'Outgoing Letters',
              icon: Icons.send_rounded,
              isActive: _activeTab == 'outgoing',
              onTap: () {
                setState(() => _activeTab = 'outgoing');
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabPill(
              label: isMr ? 'आवक पत्र (Incoming)' : 'Incoming Letters',
              icon: Icons.move_to_inbox_rounded,
              isActive: _activeTab == 'incoming',
              onTap: () {
                setState(() => _activeTab = 'incoming');
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. OUTGOING LETTER FORM (matching LetterForm.tsx lines 430-639)
  // ---------------------------------------------------------------------------
  Widget _buildOutgoingForm(bool isMr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1: Applicant Name & Voter Details
        _CardSection(
          title: isMr ? 'नाव (अर्जदार)' : 'Applicant Name',
          icon: Icons.person_outline_rounded,
          action: OutlinedButton.icon(
            onPressed: _openVoterSearchSheet,
            icon: const Icon(Icons.search_rounded, size: 15),
            label: Text(isMr ? 'मतदार यादीतून शोधा' : 'Search from Voter List'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0284C7),
              backgroundColor: const Color(0xFFF0F9FF),
              side: const BorderSide(color: Color(0xFFBAE6FD)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_linkedVoterDisplay != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${isMr ? "जोडलेले मतदार:" : "Linked Voter:"} $_linkedVoterDisplay',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF065F46)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _clearLinkedVoter,
                      ),
                    ],
                  ),
                ),
              ],
              // 3-Column Name
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameCtrl,
                      label: isMr ? 'पहिले नाव' : 'First Name',
                      placeholder: isMr ? 'पहिले नाव' : 'First Name',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _middleNameCtrl,
                      label: isMr ? 'मधले नाव' : 'Middle Name',
                      placeholder: isMr ? 'मधले नाव' : 'Middle Name',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameCtrl,
                      label: isMr ? 'आडनाव' : 'Last Name',
                      placeholder: isMr ? 'आडनाव' : 'Last Name',
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mobile Number
              _buildTextField(
                controller: _mobileCtrl,
                label: isMr ? 'मोबाईल नंबर' : 'Mobile Number',
                placeholder: '+91 98765 43210',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                required: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 2: Letter Details (Type, Gender, Area, Subject, Address, Purpose)
        _CardSection(
          title: isMr ? 'पत्राचा तपशील' : 'Letter Details',
          icon: Icons.description_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Gender & Letter Type
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildDropdown(
                      label: isMr ? 'लिंग' : 'Gender',
                      value: _selectedGender,
                      items: kGenderOptions.map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(
                            g == 'Male' ? (isMr ? 'पुरुष' : 'Male') : (g == 'Female' ? (isMr ? 'महिला' : 'Female') : (isMr ? 'इतर' : 'Other')),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGender = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _buildDropdown(
                      label: isMr ? 'पत्राचा प्रकार' : 'Letter Type',
                      value: _selectedLetterType,
                      items: kLetterTypeOptions.map((t) {
                        return DropdownMenuItem(
                          value: t.key,
                          child: Text(isMr ? t.mr : t.en, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLetterType = val);
                          _syncDynamicFields(val);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Area
              _buildTextField(
                controller: _areaCtrl,
                label: isMr ? 'क्षेत्र / परिसर' : 'Area',
                placeholder: isMr ? 'उदा. गणेश नगर, लेन ३' : 'e.g. Ganesh Nagar, Lane 3',
              ),

              const SizedBox(height: 14),

              // Subject
              _buildTextField(
                controller: _subjectCtrl,
                label: isMr ? 'पत्राचा विषय' : 'Subject',
                placeholder: isMr ? 'पत्राचा विषय...' : 'Subject of the letter...',
              ),

              const SizedBox(height: 14),

              // Address / Details (3 rows, matching LetterForm.tsx line 576)
              _buildTextField(
                controller: _addressCtrl,
                label: isMr ? 'पत्ता / तपशील' : 'Address / Details',
                placeholder: isMr
                    ? 'सध्याचा रहिवासी पत्ता किंवा विशिष्ट तपशील...'
                    : 'Current resident address or specific details...',
                maxLines: 3,
              ),

              const SizedBox(height: 14),

              // Purpose (matching LetterForm.tsx line 590)
              _buildTextField(
                controller: _purposeCtrl,
                label: isMr ? 'उद्देश / कारण' : 'Purpose',
                placeholder: isMr ? 'पत्राचे कारण / उद्देश...' : 'Purpose of the letter...',
              ),

              const SizedBox(height: 14),

              // Added By (Staff) - ALWAYS VISIBLE matching pattern
              _buildDropdown(
                label: isMr ? 'कर्मचारी (नोंदणीकर्ता) - ऐच्छिक' : 'Added By (Staff)',
                value: _selectedStaffId ?? '',
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(isMr ? 'कर्मचारी निवडा (ऐच्छिक)' : 'Select Staff (Optional)'),
                  ),
                  ..._staffList.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.role})', overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedStaffId = (val == null || val.isEmpty) ? null : val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 3: Additional Details (अतिरिक्त माहिती - matching LetterForm.tsx lines 600-628)
        _buildAdditionalDetailsSection(isMr),

        const SizedBox(height: 16),

        // Section 4: Attachments
        _buildAttachmentsSection(isMr),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. INCOMING LETTER FORM (matching IncomingLetterUpload.tsx lines 347-518)
  // ---------------------------------------------------------------------------
  Widget _buildIncomingForm(bool isMr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1: File Upload Box (matching IncomingLetterUpload.tsx lines 349-408)
        _CardSection(
          title: isMr ? 'स्कॅन / फोटो दस्तऐवज' : 'Scan / Photo Document',
          icon: Icons.upload_file_rounded,
          action: Text(
            isMr ? 'कमाल १० MB' : 'Max 10MB',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF0284C7)),
                    const SizedBox(height: 8),
                    Text(
                      isMr ? 'आवक पत्राचा फोटो किंवा स्कॅन कॉपी जोडा' : 'Add photo or scanned copy of incoming letter',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, JPG, PNG (Max 10MB)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickFile(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: Text(isMr ? 'कॅमेरा' : 'Camera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFFBAE6FD)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => _pickFile(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded, size: 16),
                          label: Text(isMr ? 'गॅलरी / फाईल्स' : 'Gallery / File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFFBAE6FD)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_pickedFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pickedFiles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final file = entry.value;
                    return Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.description_rounded, size: 18, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  file.name,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _pickedFiles.removeAt(idx)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 10, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 2: Incoming Letter Details (Title, Description, Area, Received Date)
        _CardSection(
          title: isMr ? 'पत्राचा तपशील' : 'Letter Details',
          icon: Icons.mark_email_read_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _incomingTitleCtrl,
                label: isMr ? 'पत्राचे शीर्षक' : 'Letter Title',
                placeholder: isMr ? 'पत्राचे शीर्षक...' : 'Letter Title...',
                required: true,
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _incomingDescCtrl,
                label: isMr ? 'वर्णन' : 'Description',
                placeholder: isMr
                    ? 'पत्राबद्दल तपशील किंवा इतर माहिती...'
                    : 'Add any notes or details about this letter...',
                maxLines: 3,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _incomingAreaCtrl,
                      label: isMr ? 'क्षेत्र / परिसर' : 'Area',
                      placeholder: isMr ? 'क्षेत्र शोधा...' : 'Search Area...',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMr ? 'प्राप्त झाल्याची तारीख' : 'Received Date',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickReceivedDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_receivedDate),
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Added By (Staff) - ALWAYS VISIBLE
              _buildDropdown(
                label: isMr ? 'कर्मचारी (नोंदणीकर्ता) - ऐच्छिक' : 'Added By (Staff)',
                value: _selectedStaffId ?? '',
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(isMr ? 'कर्मचारी निवडा (ऐच्छिक)' : 'Select Staff (Optional)'),
                  ),
                  ..._staffList.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.role})', overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedStaffId = (val == null || val.isEmpty) ? null : val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 3: Bearer Details (matching IncomingLetterUpload.tsx lines 469-516)
        _CardSection(
          title: isMr ? 'पत्र घेऊन येणाऱ्याची माहिती' : 'Bearer Details',
          icon: Icons.person_pin_circle_outlined,
          action: OutlinedButton.icon(
            onPressed: _openVoterSearchSheet,
            icon: const Icon(Icons.search_rounded, size: 15),
            label: Text(isMr ? 'मतदार यादीतून शोधा' : 'Search from Voter List'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0284C7),
              backgroundColor: const Color(0xFFF0F9FF),
              side: const BorderSide(color: Color(0xFFBAE6FD)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _bearerFirstNameCtrl,
                      label: isMr ? 'पहिले नाव' : 'First Name',
                      placeholder: isMr ? 'पहिले नाव' : 'First Name',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _bearerMiddleNameCtrl,
                      label: isMr ? 'मधले नाव' : 'Middle Name',
                      placeholder: isMr ? 'मधले नाव' : 'Middle Name',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _bearerLastNameCtrl,
                      label: isMr ? 'आडनाव' : 'Last Name',
                      placeholder: isMr ? 'आडनाव' : 'Last Name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _bearerMobileCtrl,
                label: isMr ? 'मोबाईल नंबर' : 'Mobile Number',
                placeholder: '+91 98765 43210',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: ADDITIONAL DETAILS (अतिरिक्त माहिती - matching LetterForm.tsx lines 600-628)
  // ---------------------------------------------------------------------------
  Widget _buildAdditionalDetailsSection(bool isMr) {
    return _CardSection(
      title: isMr ? 'अतिरिक्त माहिती' : 'Additional Details',
      icon: Icons.playlist_add_check_rounded,
      action: InkWell(
        onTap: () => _openAddFieldDialog(isMr),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 15, color: Color(0xFF0284C7)),
              const SizedBox(width: 4),
              Text(
                isMr ? 'फील्ड जोडा' : 'Add Field',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isMr
                        ? 'निवडलेल्या दाखल्यानुसार खालील तपशील भरा किंवा नवीन फील्ड जोडा'
                        : 'Fill in the specific details below or add custom fields',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_activeDynamicFieldKeys.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  isMr ? 'कोणतेही अतिरिक्त फील्ड नाही' : 'No additional fields added',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ..._activeDynamicFieldKeys.map((fieldKey) {
              final meta = kDynamicFieldDefinitions[fieldKey];
              final label = meta != null
                  ? (isMr ? meta.mrLabel : meta.enLabel)
                  : fieldKey.replaceAll('_', ' ').toUpperCase();
              final placeholder = meta != null
                  ? (isMr ? meta.placeholderMr : meta.placeholderEn)
                  : (isMr ? '$label प्रविष्ट करा' : 'Enter $label');
              final keyboardType = meta?.keyboardType ?? TextInputType.text;

              final ctrl = _dynamicControllers.putIfAbsent(fieldKey, () => TextEditingController());
              final isDefault = _isDefaultFieldForSelectedType(fieldKey);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: ctrl,
                        label: label,
                        placeholder: placeholder,
                        keyboardType: keyboardType,
                      ),
                    ),
                    if (!isDefault) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _activeDynamicFieldKeys.remove(fieldKey);
                              _dynamicControllers[fieldKey]?.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: ATTACHMENTS
  // ---------------------------------------------------------------------------
  Widget _buildAttachmentsSection(bool isMr) {
    return _CardSection(
      title: isMr ? 'संलग्न फाईल्स' : 'Attachments (Photos & Documents)',
      icon: Icons.attach_file_rounded,
      action: Text(
        isMr ? 'कमाल १०० MB' : 'Max 100MB',
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickFile(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(isMr ? 'कॅमेरा' : 'Camera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickFile(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: Text(isMr ? 'गॅलरी' : 'Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          if (_pickedFiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pickedFiles.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        color: const Color(0xFFF8FAFC),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0284C7), size: 26),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              file.name,
                              style: const TextStyle(fontSize: 8, color: Color(0xFF334155)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _pickedFiles.removeAt(idx)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMIT BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildSubmitButton(bool isMr) {
    final buttonText = _activeTab == 'outgoing'
        ? (isMr ? 'विनंती तयार करा' : 'Create Request')
        : (isMr ? 'आवक पत्र जतन करा' : 'Upload Letter');

    return ElevatedButton(
      onPressed: _isSubmitting ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : Text(
              buttonText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER FORM WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            if (required) ...[
              const SizedBox(width: 2),
              const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
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
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: items.any((i) => i.value == value) ? value : null,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
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
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SUB-COMPONENT: TAB PILL
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// SUB-COMPONENT: CARD SECTION
// -----------------------------------------------------------------------------
class _CardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? action;
  final Widget child;

  const _CardSection({
    required this.title,
    required this.icon,
    this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUB-COMPONENT: VOTER SEARCH MODAL SHEET (Exact 5 Filters)
// -----------------------------------------------------------------------------
class _VoterSearchModalSheet extends ConsumerStatefulWidget {
  final ValueChanged<VoterModel> onSelect;

  const _VoterSearchModalSheet({required this.onSelect});

  @override
  ConsumerState<_VoterSearchModalSheet> createState() =>
      _VoterSearchModalSheetState();
}

class _VoterSearchModalSheetState extends ConsumerState<_VoterSearchModalSheet> {
  final _nameFilterCtrl = TextEditingController();
  final _houseNoFilterCtrl = TextEditingController();
  final _ageFilterCtrl = TextEditingController();
  final _addressFilterCtrl = TextEditingController();
  String _selectedGender = '';

  List<VoterModel> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _executeSearch();
  }

  @override
  void dispose() {
    _nameFilterCtrl.dispose();
    _houseNoFilterCtrl.dispose();
    _ageFilterCtrl.dispose();
    _addressFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeSearch() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(votersRepoProvider);
      final query = _nameFilterCtrl.text.trim();
      final ageText = _ageFilterCtrl.text.trim();

      final list = await repo.searchVoters(
        query: query.isNotEmpty ? query : null,
        genderFilter: _selectedGender.isNotEmpty ? _selectedGender : null,
        ageRangeFilter: ageText.isNotEmpty ? ageText : null,
        pageSize: 40,
      );

      final house = _houseNoFilterCtrl.text.trim().toLowerCase();
      final addr = _addressFilterCtrl.text.trim().toLowerCase();

      final filtered = list.where((v) {
        final vHouse = (v.houseNo ?? '').toLowerCase();
        if (house.isNotEmpty && !vHouse.contains(house)) return false;
        if (addr.isNotEmpty && !v.address.toLowerCase().contains(addr)) return false;
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _results = filtered;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMr ? 'मतदार यादीतून शोधा' : 'Search from Voter List',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Filters panel
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Row 1: Search by Name & Search House No
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameFilterCtrl,
                        onChanged: (_) => _executeSearch(),
                        decoration: InputDecoration(
                          hintText: isMr ? 'नावाने शोधा' : 'Search by Name',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _houseNoFilterCtrl,
                        onChanged: (_) => _executeSearch(),
                        decoration: InputDecoration(
                          hintText: isMr ? 'घर क्र. शोधा' : 'Search House No',
                          hintStyle: const TextStyle(fontSize: 12),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Age Range & Gender
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageFilterCtrl,
                        onChanged: (_) => _executeSearch(),
                        decoration: InputDecoration(
                          hintText: isMr ? 'वय / मर्यादा (उदा. १८-२४)' : 'Age / Range (e.g. 18-24)',
                          hintStyle: const TextStyle(fontSize: 12),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        items: [
                          DropdownMenuItem(value: '', child: Text(isMr ? 'सर्व लिंग' : 'All Genders', style: const TextStyle(fontSize: 12))),
                          const DropdownMenuItem(value: 'M', child: Text('Male', style: TextStyle(fontSize: 12))),
                          const DropdownMenuItem(value: 'F', child: Text('Female', style: TextStyle(fontSize: 12))),
                          const DropdownMenuItem(value: 'O', child: Text('Other', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedGender = val ?? '');
                          _executeSearch();
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 3: Search Address
                TextField(
                  controller: _addressFilterCtrl,
                  onChanged: (_) => _executeSearch(),
                  decoration: InputDecoration(
                    hintText: isMr ? 'पत्त्यानुसार शोधा' : 'Search Address',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(isMr ? 'कोणतेही मतदार सापडले नाहीत' : 'No voters found', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, idx) {
                          final v = _results[idx];
                          final displayName = isMr ? v.nameMarathi : v.nameEnglish;

                          return ListTile(
                            onTap: () => widget.onSelect(v),
                            title: Text(
                              displayName,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${v.age} Y • ${v.gender}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'EPIC: ${v.epicNo}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    if (v.mobile != null && v.mobile!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '| 📱 ${v.mobile}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  v.address,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0F9FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF0284C7)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
