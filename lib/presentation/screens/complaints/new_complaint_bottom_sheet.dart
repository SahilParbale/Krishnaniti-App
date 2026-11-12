import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../providers/auth_provider.dart';
import 'complaint_form_constants.dart';

/// Modal Bottom Sheet that slides up from the bottom with downward-dismiss capability,
/// matching the EXACT form fields, labels, placeholders, and structure of Nagarsevak-Managment
/// (ComplaintForm.tsx & PersonalRequestForm.tsx).
class NewComplaintBottomSheet extends ConsumerStatefulWidget {
  final String initialTab; // 'Complaints' or 'Personal Help'
  final String? prefillVoterId;
  final String? prefillVoterName;

  const NewComplaintBottomSheet({
    super.key,
    this.initialTab = 'Complaints',
    this.prefillVoterId,
    this.prefillVoterName,
  });

  static Future<bool?> show(
    BuildContext context, {
    String initialTab = 'Complaints',
    String? prefillVoterId,
    String? prefillVoterName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => NewComplaintBottomSheet(
        initialTab: initialTab,
        prefillVoterId: prefillVoterId,
        prefillVoterName: prefillVoterName,
      ),
    );
  }

  @override
  ConsumerState<NewComplaintBottomSheet> createState() =>
      _NewComplaintBottomSheetState();
}

class _NewComplaintBottomSheetState
    extends ConsumerState<NewComplaintBottomSheet> {
  late String _activeTab; // 'Complaints' | 'Personal Help'

  // Linked Voter
  String? _selectedVoterId;
  String? _linkedVoterDisplay;

  // Voter / Reporter Details (matching ComplaintForm.tsx)
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController(text: '+91 ');

  // Complaint Details Fields (matching ComplaintForm.tsx)
  final _titleController = TextEditingController();
  final _areaController = TextEditingController();
  final _peopleAffectedController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Other';
  String _selectedWard = 'Sector 5';
  String _selectedSociety = '';
  String _detectedUrgency = 'Medium'; // Auto-detected by AI
  String? _selectedStaffId;

  // Personal Request Type (matching PersonalRequestForm.tsx)
  String _selectedPersonalType = 'Personal Help';

  // Attachments (Photos & Videos)
  final List<XFile> _pickedFiles = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _isAiAnalyzing = false;

  static final List<StaffModel> _fallbackStaffList = [
    StaffModel(id: 'staff-1', name: 'Sunil Shinde', role: 'Electrical JE', mobile: '9822012345'),
    StaffModel(id: 'staff-2', name: 'Santosh Gaikwad', role: 'Sanitation Sup.', mobile: '9822023456'),
    StaffModel(id: 'staff-3', name: 'Pradeep Joshi', role: 'Water Works Dept', mobile: '9822034567'),
    StaffModel(id: 'staff-4', name: 'Anand Jadhav', role: 'Road Engineering', mobile: '9822045678'),
    StaffModel(id: 'staff-5', name: 'Mahesh Patil', role: 'Ward Officer', mobile: '9822056789'),
  ];
  List<StaffModel> _staffList = [];

  bool get _hasAnyDraft =>
      _titleController.text.isNotEmpty ||
      _descriptionController.text.isNotEmpty ||
      _firstNameController.text.isNotEmpty ||
      (_mobileController.text.isNotEmpty && _mobileController.text != '+91 ') ||
      _areaController.text.isNotEmpty ||
      _selectedSociety.isNotEmpty ||
      _pickedFiles.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab == 'Personal Help'
        ? 'Personal Help'
        : 'Complaints';
    _selectedCategory = 'Other';
    _selectedPersonalType = 'Personal Help';
    _staffList = List.from(_fallbackStaffList);

    if (widget.prefillVoterId != null) {
      _selectedVoterId = widget.prefillVoterId;
      _linkedVoterDisplay = widget.prefillVoterName;
      if (widget.prefillVoterName != null) {
        _splitAndFillName(widget.prefillVoterName!);
      }
    }

    _loadStaff();
    _setupAiAnalysisListener();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _titleController.dispose();
    _areaController.dispose();
    _peopleAffectedController.dispose();
    _descriptionController.dispose();
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

  void _setupAiAnalysisListener() {
    _titleController.addListener(() {
      final text = _titleController.text.trim();
      if (text.length > 5 && !_isAiAnalyzing && _activeTab == 'Complaints') {
        setState(() => _isAiAnalyzing = true);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          final lower = text.toLowerCase();
          String inferred = _selectedCategory;
          String urg = 'Medium';

          if (lower.contains('water') || lower.contains('पाणी') || lower.contains('गळती') || lower.contains('leak') || lower.contains('supply')) {
            inferred = 'Water';
          } else if (lower.contains('garbage') || lower.contains('कचरा') || lower.contains('clean') || lower.contains('स्वच्छता') || lower.contains('waste')) {
            inferred = 'Cleaning';
          } else if (lower.contains('light') || lower.contains('दिवा') || lower.contains('वीज') || lower.contains('pole') || lower.contains('lamp')) {
            inferred = 'StreetLight';
          } else if (lower.contains('drain') || lower.contains('गटार') || lower.contains('नाली') || lower.contains('sewer') || lower.contains('gutter')) {
            inferred = 'Drainage';
          } else if (lower.contains('road') || lower.contains('रस्ता') || lower.contains('pothole') || lower.contains('खड्डा') || lower.contains('tar')) {
            inferred = 'Road';
          }

          if (lower.contains('danger') || lower.contains('urgent') || lower.contains('तातडी') || lower.contains('flood') || lower.contains('fire') || lower.contains('short circuit')) {
            urg = 'High';
          }

          setState(() {
            _selectedCategory = inferred;
            _detectedUrgency = urg;
            _isAiAnalyzing = false;
          });
        });
      }
    });
  }

  void _splitAndFillName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isNotEmpty) _firstNameController.text = parts[0];
    if (parts.length == 2) {
      _lastNameController.text = parts[1];
    } else if (parts.length >= 3) {
      _middleNameController.text = parts[1];
      _lastNameController.text = parts.sublist(2).join(' ');
    }
  }

  void _handleVoterSelected(VoterModel voter) {
    final name = voter.nameEnglish.isNotEmpty ? voter.nameEnglish : voter.nameMarathi;
    setState(() {
      _selectedVoterId = voter.id;
      _linkedVoterDisplay = name;
      _splitAndFillName(name);
      final mob = voter.mobile;
      if (mob != null && mob.isNotEmpty) {
        _mobileController.text = mob.startsWith('+91') ? mob : '+91 $mob';
      }
    });
    HapticFeedback.lightImpact();
  }

  void _clearLinkedVoter() {
    setState(() {
      _selectedVoterId = null;
      _linkedVoterDisplay = null;
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _mobileController.text = '+91 ';
    });
  }

  void _handleClearAllDrafts() {
    setState(() {
      _selectedVoterId = null;
      _linkedVoterDisplay = null;
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _mobileController.text = '+91 ';
      _titleController.clear();
      _areaController.clear();
      _peopleAffectedController.clear();
      _descriptionController.clear();
      _selectedCategory = 'Other';
      _selectedSociety = '';
      _pickedFiles.clear();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 75);
      if (file != null) {
        setState(() => _pickedFiles.add(file));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _handleSubmit() async {
    final fullName = [
      _firstNameController.text.trim(),
      _middleNameController.text.trim(),
      _lastNameController.text.trim()
    ].where((s) => s.isNotEmpty).join(' ');

    final rawMobile = _mobileController.text.trim();
    final mobile = rawMobile == '+91' || rawMobile == '+91 ' ? '' : rawMobile;

    if (_activeTab == 'Complaints') {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (title.isEmpty) {
        _showToast('Please enter Issue Title (तक्रारीचे शीर्षक आवश्यक आहे)', isError: true);
        return;
      }
      if (description.isEmpty) {
        _showToast('Please enter Description (तपशीलवार वर्णन आवश्यक आहे)', isError: true);
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        final photos = _pickedFiles.map((f) => f.path).toList();
        final attachments = _pickedFiles.map((f) {
          return ComplaintAttachment(
            url: f.path,
            type: 'image/jpeg',
            name: f.name,
          );
        }).toList();

        await ref.read(complaintsRepoProvider).createComplaint(
          title: title,
          description: description,
          category: _selectedCategory,
          ward: _selectedWard,
          society: _selectedSociety.isNotEmpty ? _selectedSociety : null,
          area: _areaController.text.trim().isNotEmpty ? _areaController.text.trim() : null,
          citizenName: fullName.isNotEmpty ? fullName : null,
          citizenMobile: mobile.isNotEmpty ? mobile : null,
          voterId: _selectedVoterId,
          addedByStaffId: _selectedStaffId,
          priority: _detectedUrgency,
          peopleAffected: _peopleAffectedController.text.trim().isNotEmpty
              ? _peopleAffectedController.text.trim()
              : null,
          photos: photos,
          attachments: attachments,
        );

        if (mounted) {
          _showToast('Complaint submitted successfully! (तक्रार दाखल केली गेली)');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          _showToast('Failed to submit complaint: $e', isError: true);
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      // Personal Help
      final fName = _firstNameController.text.trim();
      final lName = _lastNameController.text.trim();
      final description = _descriptionController.text.trim();

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
      if (description.isEmpty) {
        _showToast('Please enter Description (वर्णन आवश्यक आहे)', isError: true);
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        final photos = _pickedFiles.map((f) => f.path).toList();
        final attachments = _pickedFiles.map((f) {
          return ComplaintAttachment(
            url: f.path,
            type: 'image/jpeg',
            name: f.name,
          );
        }).toList();

        await ref.read(complaintsRepoProvider).createPersonalRequest(
          reporterName: fullName,
          reporterMobile: mobile,
          requestType: _selectedPersonalType,
          description: description,
          voterId: _selectedVoterId,
          addedByStaffId: _selectedStaffId,
          photos: photos,
          attachments: attachments,
        );

        if (mounted) {
          _showToast('Personal Help Request submitted successfully! (वैयक्तिक मदत विनंती जतन झाली)');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          _showToast('Failed to save request: $e', isError: true);
        }
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

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final societies = kSocietiesByWard[_selectedWard] ?? [];

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
            // Downward Dismiss Drag Handle
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

            // Top Header matching ComplaintForm.tsx card header
            _buildTopCardHeader(isMr),

            // Tab Selector (Area Complaint vs Personal Help)
            _buildTabSelector(isMr),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Voter Details
                    _buildVoterDetailsSection(isMr),
                    const SizedBox(height: 18),

                    // Section 2: Complaint Details OR Personal Request Details
                    if (_activeTab == 'Complaints')
                      _buildComplaintDetailsSection(isMr, societies)
                    else
                      _buildPersonalRequestDetailsSection(isMr),
                    const SizedBox(height: 18),

                    // Section 3: Attachments
                    _buildAttachmentsSection(isMr),
                    const SizedBox(height: 24),

                    // Submit Action Button (Submit Complaint / Save)
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
  // TOP CARD HEADER (matching ComplaintForm.tsx)
  // ---------------------------------------------------------------------------
  Widget _buildTopCardHeader(bool isMr) {
    final titleText = _activeTab == 'Complaints'
        ? (isMr ? 'नवीन तक्रार' : 'New Request')
        : (isMr ? 'वैयक्तिक विनंत्या' : 'Personal Requests');

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
                ] else if (_activeTab == 'Personal Help') ...[
                  const SizedBox(height: 2),
                  Text(
                    isMr ? 'नवीन वैयक्तिक मदत विनंती नोंदवा' : 'Create a new manual personal help request',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
  // TAB SELECTOR (Area Complaints vs Personal Help)
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
              label: isMr ? 'तक्रारी (सार्वजनिक)' : 'Area Complaints',
              icon: Icons.location_city_rounded,
              isActive: _activeTab == 'Complaints',
              onTap: () {
                setState(() => _activeTab = 'Complaints');
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabPill(
              label: isMr ? 'वैयक्तिक मदत' : 'Personal Help',
              icon: Icons.person_search_rounded,
              isActive: _activeTab == 'Personal Help',
              onTap: () {
                setState(() => _activeTab = 'Personal Help');
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: VOTER DETAILS (matching t('complaints.form.voter_details'))
  // ---------------------------------------------------------------------------
  Widget _buildVoterDetailsSection(bool isMr) {
    return _CardSection(
      title: isMr ? 'मतदार तपशील' : 'Voter Details',
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
          // Linked Voter Alert Banner (if linked)
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
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

          // 3-Column Grid: First Name, Middle Name, Last Name
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: isMr ? 'पहिले नाव' : 'First Name',
                  placeholder: isMr ? 'पहिले नाव' : 'First Name',
                  required: _activeTab == 'Personal Help',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _middleNameController,
                  label: isMr ? 'मधले नाव' : 'Middle Name',
                  placeholder: isMr ? 'मधले नाव' : 'Middle Name',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: isMr ? 'आडनाव' : 'Last Name',
                  placeholder: isMr ? 'आडनाव' : 'Last Name',
                  required: _activeTab == 'Personal Help',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mobile Number Field
          _buildTextField(
            controller: _mobileController,
            label: isMr ? 'मोबाईल नंबर' : 'Mobile Number',
            placeholder: '+91 9999999999',
            prefixIcon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            required: _activeTab == 'Personal Help',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2A: COMPLAINT DETAILS (matching ComplaintForm.tsx)
  // ---------------------------------------------------------------------------
  Widget _buildComplaintDetailsSection(bool isMr, List<String> societies) {
    return _CardSection(
      title: isMr ? 'तक्रार तपशील' : 'Complaint Details',
      icon: Icons.warning_amber_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issue Title
          _buildTextField(
            controller: _titleController,
            label: isMr ? 'तक्रारीचे शीर्षक' : 'Issue Title',
            placeholder: isMr ? 'उदा. कचरा उचलला नाही' : 'e.g. Garbage not collected',
            required: true,
          ),

          // AI Analyzing Indicator (matching ComplaintForm.tsx)
          if (_isAiAnalyzing) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 6),
                Text(
                  isMr ? 'AI समस्येचे वर्गीकरण करत आहे...' : 'AI is analyzing issue details...',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          // High Urgency Detected Banner (matching ComplaintForm.tsx)
          if (_detectedUrgency == 'High') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 14),
                const SizedBox(width: 5),
                Text(
                  isMr ? 'AI द्वारे उच्च तातडी आढळली' : 'High Urgency Detected by AI',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // 2-Column Grid: Type & Ward
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: isMr ? 'प्रकार' : 'Type',
                  value: _selectedCategory,
                  items: kComplaintCategories.map((c) {
                    return DropdownMenuItem(
                      value: c.key,
                      child: Text(isMr ? c.mr : c.en, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: isMr ? 'वार्ड / प्रभाग' : 'Ward',
                  value: _selectedWard,
                  items: kWardsList.map((w) {
                    return DropdownMenuItem(
                      value: w,
                      child: Text(w, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedWard = val;
                        _selectedSociety = '';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Society Name Combobox (matching ComplaintForm.tsx lines 770-820)
          if (societies.isNotEmpty) ...[
            _buildSocietyPicker(isMr, societies),
            const SizedBox(height: 14),
          ],

          // Area / Colony (Optional) & Number of People Affected
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _areaController,
                  label: isMr ? 'परिसर / गल्ली (ऐच्छिक)' : 'Area / Colony (Optional)',
                  placeholder: isMr ? 'उदा. गणेश नगर, लेन ३' : 'e.g. Ganesh Nagar, Lane 3',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _peopleAffectedController,
                  label: isMr ? 'प्रभावित लोकांची संख्या' : 'Number of People Affected',
                  placeholder: isMr ? 'उदा. १००' : 'e.g. 100',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description (4 rows, matching ComplaintForm.tsx)
          _buildTextField(
            controller: _descriptionController,
            label: isMr ? 'वर्णन' : 'Description',
            placeholder: isMr ? 'समस्येचे सविस्तर वर्णन करा...' : 'Describe the issue in detail...',
            maxLines: 4,
            required: true,
          ),
          const SizedBox(height: 14),

          // Added By (Staff) - Always visible matching ComplaintForm.tsx line 857
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
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2B: PERSONAL REQUEST DETAILS (matching PersonalRequestForm.tsx)
  // ---------------------------------------------------------------------------
  Widget _buildPersonalRequestDetailsSection(bool isMr) {
    return _CardSection(
      title: isMr ? 'तक्रार तपशील' : 'Complaint Details',
      icon: Icons.help_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type (matching PersonalRequestForm.tsx)
          _buildDropdown(
            label: isMr ? 'प्रकार' : 'Type',
            value: _selectedPersonalType,
            items: kPersonalRequestCategories.map((c) {
              return DropdownMenuItem(
                value: c.key,
                child: Text(isMr ? c.mr : c.en, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedPersonalType = val);
            },
          ),
          const SizedBox(height: 14),

          // Description (6 rows, matching PersonalRequestForm.tsx)
          _buildTextField(
            controller: _descriptionController,
            label: isMr ? 'वर्णन' : 'Description',
            placeholder: isMr ? 'समस्येचे सविस्तर वर्णन करा...' : 'Describe the issue in detail...',
            maxLines: 6,
            required: true,
          ),
          const SizedBox(height: 14),

          // Added By (Staff)
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
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: ATTACHMENTS (matching MultiFileUpload)
  // ---------------------------------------------------------------------------
  Widget _buildAttachmentsSection(bool isMr) {
    return _CardSection(
      title: isMr ? 'संलग्न फाईल्स' : 'Attachments (Photos, Videos, Audio, Documents)',
      icon: Icons.attach_file_rounded,
      action: Text(
        isMr ? 'कमाल १०० MB' : 'Max 100MB',
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMr ? 'फोटो, व्हिडिओ आणि कागदपत्रे जोडा' : 'Supports Photos, Videos, Audio & Documents',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
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
                onPressed: () => _pickImage(ImageSource.gallery),
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

          // Display selected images
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
                        onTap: () {
                          setState(() => _pickedFiles.removeAt(idx));
                        },
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
  // SUBMIT BUTTON (matching ns-btn-primary)
  // ---------------------------------------------------------------------------
  Widget _buildSubmitButton(bool isMr) {
    final buttonText = _activeTab == 'Complaints'
        ? (isMr ? 'तक्रार दाखल करा' : 'Submit Complaint')
        : (isMr ? 'जतन करा' : 'Save');

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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildSocietyPicker(bool isMr, List<String> societies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMr ? 'सोसायटीचे नाव' : 'Society Name',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _openSocietySelectionSheet(societies, isMr),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSociety.isNotEmpty
                        ? _selectedSociety
                        : (isMr ? 'सोसायटी निवडा' : 'Select Society'),
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedSociety.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openSocietySelectionSheet(List<String> societies, bool isMr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SocietySearchModal(
        societies: societies,
        current: _selectedSociety,
        onSelect: (selected) {
          setState(() => _selectedSociety = selected);
          Navigator.pop(context);
        },
      ),
    );
  }

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
// SUB-COMPONENT: VOTER SEARCH MODAL SHEET
// (matching ComplaintForm.tsx lines 913-1079)
// -----------------------------------------------------------------------------
class _VoterSearchModalSheet extends ConsumerStatefulWidget {
  final ValueChanged<VoterModel> onSelect;

  const _VoterSearchModalSheet({required this.onSelect});

  @override
  ConsumerState<_VoterSearchModalSheet> createState() =>
      _VoterSearchModalSheetState();
}

class _VoterSearchModalSheetState
    extends ConsumerState<_VoterSearchModalSheet> {
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
          // Header (matching ComplaintForm.tsx lines 916-921)
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

          // Filters panel (matching ComplaintForm.tsx lines 922-1014)
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

          // Search Results List (matching ComplaintForm.tsx lines 1023-1059)
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

// -----------------------------------------------------------------------------
// SUB-COMPONENT: SOCIETY SEARCH MODAL (matching ComplaintForm.tsx)
// -----------------------------------------------------------------------------
class _SocietySearchModal extends StatefulWidget {
  final List<String> societies;
  final String current;
  final ValueChanged<String> onSelect;

  const _SocietySearchModal({
    required this.societies,
    required this.current,
    required this.onSelect,
  });

  @override
  State<_SocietySearchModal> createState() => _SocietySearchModalState();
}

class _SocietySearchModalState extends State<_SocietySearchModal> {
  final _searchCtrl = TextEditingController();
  List<MapEntry<int, String>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.societies.asMap().entries.toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = widget.societies
          .asMap()
          .entries
          .where((e) {
            final formatted = '${e.key + 1} - ${e.value}'.toLowerCase();
            return formatted.contains(query) || e.value.toLowerCase().contains(query);
          })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Housing Society',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search society...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, idx) {
                final entry = _filtered[idx];
                final formattedName = '${entry.key + 1} - ${entry.value}';
                final isSelected = entry.value == widget.current || formattedName == widget.current;
                return ListTile(
                  onTap: () => widget.onSelect(formattedName),
                  title: Text(
                    formattedName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: Color(0xFF0284C7))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
