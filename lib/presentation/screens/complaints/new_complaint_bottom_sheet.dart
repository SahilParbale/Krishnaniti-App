import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../providers/language_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_modal_sheet.dart';
import 'complaint_form_constants.dart';
import '../../widgets/app_dropdown.dart';

/// Modal Bottom Sheet that slides up from the bottom with downward-dismiss capability,
/// matching the EXACT form fields, labels, placeholders, and structure of Nagarsevak-Managment
/// (ComplaintForm.tsx & PersonalRequestForm.tsx).
class NewComplaintBottomSheet extends ConsumerStatefulWidget {
  final String initialTab; // 'Complaints' or 'Personal Help'
  final bool hidePersonalHelp;
  final String? prefillVoterId;
  final String? prefillVoterName;

  const NewComplaintBottomSheet({
    super.key,
    this.initialTab = 'Complaints',
    this.hidePersonalHelp = false,
    this.prefillVoterId,
    this.prefillVoterName,
  });

  static Future<bool?> show(
    BuildContext context, {
    String initialTab = 'Complaints',
    bool hidePersonalHelp = false,
    String? prefillVoterId,
    String? prefillVoterName,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            width: 720,
            constraints: const BoxConstraints(maxHeight: 820),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: NewComplaintBottomSheet(
              initialTab: initialTab,
              hidePersonalHelp: hidePersonalHelp,
              prefillVoterId: prefillVoterId,
              prefillVoterName: prefillVoterName,
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => NewComplaintBottomSheet(
        initialTab: initialTab,
        hidePersonalHelp: hidePersonalHelp,
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

  bool _isSubmitting = false;
  bool _isAiAnalyzing = false;
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
    _activeTab = widget.hidePersonalHelp
        ? 'Complaints'
        : (widget.initialTab == 'Personal Help' ? 'Personal Help' : 'Complaints');
    _selectedCategory = 'Other';
    _selectedPersonalType = 'Personal Help';

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

      final lang = ref.read(appLanguageProvider);
      if (title.isEmpty) {
        _showToast(
          lang == 'mr'
              ? 'तक्रारीचे शीर्षक आवश्यक आहे'
              : (lang == 'hi' ? 'शिकायत का शीर्षक आवश्यक है' : 'Please enter Issue Title'),
          isError: true,
        );
        return;
      }
      if (description.isEmpty) {
        _showToast(
          lang == 'mr'
              ? 'तपशीलवार वर्णन आवश्यक आहे'
              : (lang == 'hi' ? 'विस्तृत विवरण आवश्यक है' : 'Please enter Description'),
          isError: true,
        );
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
          _showToast(
            lang == 'mr'
                ? 'तक्रार यशस्वीरित्या दाखल केली गेली!'
                : (lang == 'hi' ? 'शिकायत सफलतापूर्वक दर्ज की गई!' : 'Complaint submitted successfully!'),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          _showToast(
            lang == 'mr'
                ? 'तक्रार दाखल करणे अयशस्वी झाले: $e'
                : (lang == 'hi' ? 'शिकायत दर्ज करने में विफल: $e' : 'Failed to submit complaint: $e'),
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      // Personal Help
      final lang = ref.read(appLanguageProvider);
      final fName = _firstNameController.text.trim();
      final lName = _lastNameController.text.trim();
      final description = _descriptionController.text.trim();

      if (fName.isEmpty) {
        _showToast(
          lang == 'mr'
              ? 'पहिले नाव आवश्यक आहे'
              : (lang == 'hi' ? 'पहला नाम आवश्यक है' : 'Please enter First Name'),
          isError: true,
        );
        return;
      }
      if (lName.isEmpty) {
        _showToast(
          lang == 'mr'
              ? 'आडनाव आवश्यक आहे'
              : (lang == 'hi' ? 'अंतिम नाम आवश्यक है' : 'Please enter Last Name'),
          isError: true,
        );
        return;
      }
      if (mobile.isEmpty) {
        _showToast(
          lang == 'mr'
              ? 'मोबाईल नंबर आवश्यक आहे'
              : (lang == 'hi' ? 'मोबाइल नंबर आवश्यक है' : 'Please enter Mobile Number'),
          isError: true,
        );
        return;
      }
      if (description.isEmpty) {
        _showToast(
          lang == 'mr'
              ? 'वर्णन आवश्यक आहे'
              : (lang == 'hi' ? 'विवरण आवश्यक है' : 'Please enter Description'),
          isError: true,
        );
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
          _showToast(
            lang == 'mr'
                ? 'वैयक्तिक मदत विनंती यशस्वीरित्या जतन झाली!'
                : (lang == 'hi' ? 'व्यक्तिगत सहायता अनुरोध सफलतापूर्वक दर्ज किया गया!' : 'Personal Help Request submitted successfully!'),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          _showToast(
            lang == 'mr'
                ? 'विनंती जतन करणे अयशस्वी झाले: $e'
                : (lang == 'hi' ? 'अनुरोध सहेजने में विफल: $e' : 'Failed to save request: $e'),
            isError: true,
          );
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
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            width: 650,
            constraints: const BoxConstraints(maxHeight: 740),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: _VoterSearchModalSheet(
              onSelect: (voter) {
                _handleVoterSelected(voter);
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      );
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final societies = kSocietiesByWard[_selectedWard] ?? [];

    final titleText = widget.hidePersonalHelp
        ? (lang == 'mr' ? 'नवीन प्रभागातील समस्या' : (lang == 'hi' ? 'नई वार्ड समस्या' : 'Report Ward Problem'))
        : (_activeTab == 'Complaints'
            ? (lang == 'mr' ? 'नवीन तक्रार / विनंती' : (lang == 'hi' ? 'नई शिकायत / अनुरोध' : 'New Request / Complaint'))
            : (lang == 'mr' ? 'वैयक्तिक मदत विनंती' : (lang == 'hi' ? 'व्यक्तिगत सहायता अनुरोध' : 'Personal Help Request')));

    final subtitleText = widget.hidePersonalHelp
        ? (lang == 'mr' ? 'प्रभागातील नागरी समस्यांची नोंद घ्या' : (lang == 'hi' ? 'वार्ड स्तर की नागरिक समस्याओं को दर्ज करें' : 'Record civic and ward-level issues'))
        : (lang == 'mr'
            ? 'अधिकृत तक्रारी आणि वैयक्तिक मदत विनंत्या व्यवस्थापित करा'
            : (lang == 'hi' ? 'नागरिक शिकायतों और व्यक्तिगत सहायता अनुरोधों का प्रबंधन करें' : 'Track and manage citizen grievances and petitions'));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isDesktop
              ? BorderRadius.circular(20)
              : const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: isDesktop
              ? null
              : const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. FIXED STANDARDIZED HEADER
            AppModalHeader(
              icon: widget.hidePersonalHelp
                  ? Icons.report_problem_outlined
                  : (_activeTab == 'Complaints' ? Icons.add_task_rounded : Icons.person_outline_rounded),
              title: titleText,
              subtitle: subtitleText,
              onClose: () => Navigator.pop(context),
            ),

            // Tab Selector (Area Complaint vs Personal Help - hidden when opened from Ward Problems)
            if (!widget.hidePersonalHelp)
              _buildTabSelector(lang),

            // Linked voter / Draft autosave status bar
            if (_linkedVoterDisplay != null || _hasAnyDraft)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    if (_linkedVoterDisplay != null) ...[
                      const Icon(Icons.link_rounded, size: 16, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Text(
                        '${lang == "mr" ? "जोडलेले मतदार:" : (lang == "hi" ? "जुड़े मतदाता:" : "Linked:")} $_linkedVoterDisplay',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearLinkedVoter,
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
                      ),
                    ],
                    const Spacer(),
                    if (_hasAnyDraft) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        lang == 'mr' ? 'मसुदा सेव्ह केला' : (lang == 'hi' ? 'मसौदा सहेजा गया' : 'Draft autosaved'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleClearAllDrafts,
                        child: Text(
                          lang == 'mr' ? 'काढून टाका' : (lang == 'hi' ? 'हटाएं' : 'Clear draft'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // 2. SCROLLABLE FORM BODY & SUBMIT BUTTON
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  // Section 1: Voter Details
                  _buildVoterDetailsSection(lang),
                  const SizedBox(height: 18),

                  // Section 2: Complaint Details OR Personal Request Details
                  if (_activeTab == 'Complaints')
                    _buildComplaintDetailsSection(lang, societies)
                  else
                    _buildPersonalRequestDetailsSection(lang),
                  const SizedBox(height: 18),

                  // Section 3: Attachments
                  _buildAttachmentsSection(lang),
                  const SizedBox(height: 20),

                  // Submit Action Button (Scrolls together with form)
                  _buildSubmitButton(lang),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB SELECTOR (Area Complaints vs Personal Help)
  // ---------------------------------------------------------------------------
  Widget _buildTabSelector(String lang) {
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
              label: AppTranslations.t('complaints.tabs.area', lang: lang),
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
              label: AppTranslations.t('complaints.tabs.personal', lang: lang),
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
  Widget _buildVoterDetailsSection(String lang) {
    return _CardSection(
      title: lang == 'mr' ? 'मतदार तपशील' : (lang == 'hi' ? 'मतदाता विवरण' : 'Voter Details'),
      icon: Icons.person_outline_rounded,
      action: OutlinedButton.icon(
        onPressed: _openVoterSearchSheet,
        icon: const Icon(Icons.search_rounded, size: 15),
        label: Text(lang == 'mr' ? 'मतदार यादीतून शोधा' : (lang == 'hi' ? 'मतदाता सूची से खोजें' : 'Search from Voter List')),
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
                      '${lang == "mr" ? "जोडलेले मतदार:" : (lang == "hi" ? "जुड़े मतदाता:" : "Linked Voter:")} $_linkedVoterDisplay',
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
                  label: lang == 'mr' ? 'पहिले नाव' : (lang == 'hi' ? 'पहला नाम' : 'First Name'),
                  placeholder: lang == 'mr' ? 'पहिले नाव' : (lang == 'hi' ? 'पहला नाम' : 'First Name'),
                  required: _activeTab == 'Personal Help',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _middleNameController,
                  label: lang == 'mr' ? 'मधले नाव' : (lang == 'hi' ? 'मध्यम नाम' : 'Middle Name'),
                  placeholder: lang == 'mr' ? 'मधले नाव' : (lang == 'hi' ? 'मध्यम नाम' : 'Middle Name'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: lang == 'mr' ? 'आडनाव' : (lang == 'hi' ? 'अंतिम नाम' : 'Last Name'),
                  placeholder: lang == 'mr' ? 'आडनाव' : (lang == 'hi' ? 'अंतिम नाम' : 'Last Name'),
                  required: _activeTab == 'Personal Help',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mobile Number Field
          _buildTextField(
            controller: _mobileController,
            label: lang == 'mr' ? 'मोबाईल नंबर' : (lang == 'hi' ? 'मोबाइल नंबर' : 'Mobile Number'),
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
  Widget _buildComplaintDetailsSection(String lang, List<String> societies) {
    return _CardSection(
      title: lang == 'mr' ? 'तक्रार तपशील' : (lang == 'hi' ? 'शिकायत विवरण' : 'Complaint Details'),
      icon: Icons.warning_amber_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issue Title
          _buildTextField(
            controller: _titleController,
            label: lang == 'mr' ? 'तक्रारीचे शीर्षक' : (lang == 'hi' ? 'शिकायत का शीर्षक' : 'Issue Title'),
            placeholder: lang == 'mr' ? 'उदा. कचरा उचलला नाही' : (lang == 'hi' ? 'उदा. कचरा नहीं उठाया गया' : 'e.g. Garbage not collected'),
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
                  lang == 'mr' ? 'AI समस्येचे वर्गीकरण करत आहे...' : (lang == 'hi' ? 'AI समस्या का विश्लेषण कर रहा है...' : 'AI is analyzing issue details...'),
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
                  lang == 'mr' ? 'AI द्वारे उच्च तातडी आढळली' : (lang == 'hi' ? 'AI द्वारा उच्च प्राथमिकता पहचानी गई' : 'High Urgency Detected by AI'),
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
                  label: lang == 'mr' ? 'प्रकार' : (lang == 'hi' ? 'प्रकार' : 'Type'),
                  value: _selectedCategory,
                  items: kComplaintCategories.map((c) {
                    return DropdownMenuItem(
                      value: c.key,
                      child: Text(c.getLabel(lang), overflow: TextOverflow.ellipsis),
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
                  label: lang == 'mr' ? 'वार्ड / प्रभाग' : (lang == 'hi' ? 'वार्ड / प्रभाग' : 'Ward'),
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
            _buildSocietyPicker(lang, societies),
            const SizedBox(height: 14),
          ],

          // Area / Colony (Optional) & Number of People Affected
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _areaController,
                  label: lang == 'mr' ? 'परिसर / गल्ली (ऐच्छिक)' : (lang == 'hi' ? 'क्षेत्र / कॉलोनी (वैकल्पिक)' : 'Area / Colony (Optional)'),
                  placeholder: lang == 'mr' ? 'उदा. गणेश नगर, लेन ३' : (lang == 'hi' ? 'उदा. गणेश नगर, लेन ३' : 'e.g. Ganesh Nagar, Lane 3'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _peopleAffectedController,
                  label: lang == 'mr' ? 'प्रभावित लोकांची संख्या' : (lang == 'hi' ? 'प्रभावित लोगों की संख्या' : 'Number of People Affected'),
                  placeholder: lang == 'mr' ? 'उदा. १००' : (lang == 'hi' ? 'उदा. १००' : 'e.g. 100'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description (4 rows, matching ComplaintForm.tsx)
          _buildTextField(
            controller: _descriptionController,
            label: lang == 'mr' ? 'वर्णन' : (lang == 'hi' ? 'विवरण' : 'Description'),
            placeholder: lang == 'mr' ? 'समस्येचे सविस्तर वर्णन करा...' : (lang == 'hi' ? 'समस्या का विस्तृत विवरण दर्ज करें...' : 'Describe the issue in detail...'),
            maxLines: 4,
            required: true,
          ),
          const SizedBox(height: 14),

          // Added By (Staff) - Always visible matching ComplaintForm.tsx line 857
          _buildDropdown(
            label: lang == 'mr' ? 'कर्मचारी (नोंदणीकर्ता) - ऐच्छिक' : (lang == 'hi' ? 'कर्मचारी (दर्जकर्ता) - वैकल्पिक' : 'Added By (Staff)'),
            value: _selectedStaffId ?? '',
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(lang == 'mr' ? 'कर्मचारी निवडा (ऐच्छिक)' : (lang == 'hi' ? 'कर्मचारी चुनें (वैकल्पिक)' : 'Select Staff (Optional)')),
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
  Widget _buildPersonalRequestDetailsSection(String lang) {
    return _CardSection(
      title: lang == 'mr' ? 'तक्रार तपशील' : (lang == 'hi' ? 'अनुरोध विवरण' : 'Complaint Details'),
      icon: Icons.help_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type (matching PersonalRequestForm.tsx)
          _buildDropdown(
            label: lang == 'mr' ? 'प्रकार' : (lang == 'hi' ? 'प्रकार' : 'Type'),
            value: _selectedPersonalType,
            items: kPersonalRequestCategories.map((c) {
              return DropdownMenuItem(
                value: c.key,
                child: Text(c.getLabel(lang), overflow: TextOverflow.ellipsis),
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
            label: lang == 'mr' ? 'वर्णन' : (lang == 'hi' ? 'विवरण' : 'Description'),
            placeholder: lang == 'mr' ? 'समस्येचे सविस्तर वर्णन करा...' : (lang == 'hi' ? 'समस्या का विस्तृत विवरण दर्ज करें...' : 'Describe the issue in detail...'),
            maxLines: 6,
            required: true,
          ),
          const SizedBox(height: 14),

          // Added By (Staff)
          _buildDropdown(
            label: lang == 'mr' ? 'कर्मचारी (नोंदणीकर्ता) - ऐच्छिक' : (lang == 'hi' ? 'कर्मचारी (दर्जकर्ता) - वैकल्पिक' : 'Added By (Staff)'),
            value: _selectedStaffId ?? '',
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(lang == 'mr' ? 'कर्मचारी निवडा (ऐच्छिक)' : (lang == 'hi' ? 'कर्मचारी चुनें (वैकल्पिक)' : 'Select Staff (Optional)')),
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
  Widget _buildAttachmentsSection(String lang) {
    return _CardSection(
      title: lang == 'mr' ? 'संलग्न फाईल्स' : (lang == 'hi' ? 'संलग्न फाइलें' : 'Attachments (Photos, Videos, Audio, Documents)'),
      icon: Icons.attach_file_rounded,
      action: Text(
        lang == 'mr' ? 'कमाल १०० MB' : (lang == 'hi' ? 'अधिकतम १०० MB' : 'Max 100MB'),
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      child: AppImagePickerField(
        isRequired: false,
        isMarathi: lang == 'mr',
        allowMultiple: true,
        initialFiles: _pickedFiles,
        onFilesChanged: (files) {
          setState(() {
            _pickedFiles.clear();
            _pickedFiles.addAll(files);
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMIT BUTTON (matching ns-btn-primary)
  // ---------------------------------------------------------------------------
  Widget _buildSubmitButton(String lang) {
    final buttonText = _activeTab == 'Complaints'
        ? (lang == 'mr' ? 'तक्रार दाखल करा' : (lang == 'hi' ? 'शिकायत दर्ज करें' : 'Submit Complaint'))
        : (lang == 'mr' ? 'जतन करा' : (lang == 'hi' ? 'सहेजें' : 'Save'));

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
  Widget _buildSocietyPicker(String lang, List<String> societies) {
    return AppDropdownFormField<String>(
      label: lang == 'mr' ? 'सोसायटीचे नाव' : (lang == 'hi' ? 'सोसायटी का नाम' : 'Society Name'),
      isRequired: false,
      hintText: lang == 'mr' ? 'सोसायटी निवडा' : (lang == 'hi' ? 'सोसायटी चुनें' : 'Select Society'),
      prefixIcon: const Icon(Icons.apartment_rounded, size: 18, color: Color(0xFF64748B)),
      value: _selectedSociety.isNotEmpty ? _selectedSociety : null,
      items: societies.asMap().entries.map((e) {
        final formattedName = '${e.key + 1} - ${e.value}';
        return DropdownMenuItem<String>(
          value: formattedName,
          child: Text(formattedName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedSociety = val ?? '');
      },
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
        AppFieldLabel(
          label: label,
          isRequired: required,
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: appInputDecoration(
            hint: placeholder,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
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
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdownFormField<String>(
          label: label,
          isRequired: required,
          value: items.any((i) => i.value == value) ? value : null,
          items: items,
          onChanged: onChanged,
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
    final lang = ref.watch(appLanguageProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      constraints: BoxConstraints(
        maxHeight: isDesktop ? 700 : MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. FIXED STANDARDIZED HEADER
          AppModalHeader(
            icon: Icons.person_search_rounded,
            title: lang == 'mr'
                ? 'मतदार यादीतून शोधा'
                : (lang == 'hi' ? 'मतदाता सूची से खोजें' : 'Search from Voter List'),
            subtitle: lang == 'mr'
                ? 'नाव, घर क्र. किंवा पत्त्यानुसार शोधा'
                : (lang == 'hi' ? 'नाम, मकान नं. या पते के अनुसार खोजें' : 'Filter voters from electoral roll'),
            onClose: () => Navigator.pop(context),
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
                          hintText: lang == 'mr'
                              ? 'नावाने शोधा'
                              : (lang == 'hi' ? 'नाम से खोजें' : 'Search by Name'),
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
                          hintText: lang == 'mr'
                              ? 'घर क्र. शोधा'
                              : (lang == 'hi' ? 'मकान नं. खोजें' : 'Search House No'),
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
                          hintText: lang == 'mr'
                              ? 'वय / मर्यादा (उदा. १८-२४)'
                              : (lang == 'hi' ? 'आयु / सीमा (उदा. १८-२४)' : 'Age / Range (e.g. 18-24)'),
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
                      child: AppDropdown<String>(
                        value: _selectedGender,
                        height: 44,
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(
                              lang == 'mr' ? 'सर्व लिंग' : (lang == 'hi' ? 'सभी लिंग' : 'All Genders'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'M',
                            child: Text(
                              lang == 'mr' ? 'पुरुष' : (lang == 'hi' ? 'पुरुष' : 'Male'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'F',
                            child: Text(
                              lang == 'mr' ? 'स्त्री' : (lang == 'hi' ? 'महिला' : 'Female'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'O',
                            child: Text(
                              lang == 'mr' ? 'इतर' : (lang == 'hi' ? 'अन्य' : 'Other'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedGender = val ?? '');
                          _executeSearch();
                        },
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
                    hintText: lang == 'mr'
                        ? 'पत्त्यानुसार शोधा'
                        : (lang == 'hi' ? 'पते के अनुसार खोजें' : 'Search Address'),
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
                            Text(
                              lang == 'mr'
                                  ? 'कोणतेही मतदार सापडले नाहीत'
                                  : (lang == 'hi' ? 'कोई मतदाता नहीं मिला' : 'No voters found'),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, idx) {
                          final v = _results[idx];
                          final displayName = (lang == 'mr' || lang == 'hi') && v.nameMarathi.isNotEmpty
                              ? v.nameMarathi
                              : v.nameEnglish;

                          final genderLabel = lang == 'mr'
                              ? (v.gender == 'M' ? 'पुरुष' : (v.gender == 'F' ? 'स्त्री' : 'इतर'))
                              : (lang == 'hi'
                                  ? (v.gender == 'M' ? 'पुरुष' : (v.gender == 'F' ? 'महिला' : 'अन्य'))
                                  : v.gender);

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
                                        '${AppTranslations.formatDigits(v.age.toString(), lang)} ${lang == "mr" ? "वर्षे" : (lang == "hi" ? "वर्ष" : "Y")} • $genderLabel',
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
                                        '| 📱 ${AppTranslations.formatDigits(v.mobile!, lang)}',
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


