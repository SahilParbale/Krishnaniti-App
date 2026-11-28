import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/letters_repository.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_date_picker.dart';
import 'letter_form_constants.dart';
import '../../../data/models/letter_type_model.dart';
import '../../widgets/app_dropdown.dart';

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
            child: NewLetterBottomSheet(
              initialTab: initialTab,
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
  List<LetterTypeModel> _dbLetterTypes = [];

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

  // Staff Dropdown (loaded from Supabase staff table)
  List<StaffModel> _staffList = [];
  String? _selectedStaffId;

  // Attachments
  final List<XFile> _pickedFiles = [];

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
    _syncDynamicFields(_selectedLetterType);

    if (widget.prefillVoterId != null) {
      _selectedVoterId = widget.prefillVoterId;
      _linkedVoterDisplay = widget.prefillVoterName;
      if (widget.prefillVoterName != null) {
        _splitAndFillName(widget.prefillVoterName!);
      }
    }

    _loadStaff();
    _loadLetterTypes();
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


  Future<void> _loadLetterTypes() async {
    try {
      final repo = ref.read(lettersRepoProvider);
      final types = await repo.getLetterTypes();
      if (mounted && types.isNotEmpty) {
        setState(() {
          _dbLetterTypes = types;
        });
      }
    } catch (_) {}
  }

  List<DropdownMenuItem<String>> _buildLetterTypeDropdownItems(String lang) {
    final Map<String, ({LetterTypeOption option, bool isFromDb})> optionsMap = {
      for (final opt in kLetterTypeOptions) opt.key: (option: opt, isFromDb: false),
    };

    for (final dbType in _dbLetterTypes) {
      final isCustom = !optionsMap.containsKey(dbType.name);
      final existing = optionsMap[dbType.name]?.option;
      optionsMap[dbType.name] = (
        option: LetterTypeOption(
          key: dbType.name,
          en: existing?.en ?? dbType.name,
          mr: dbType.nameMarathi?.isNotEmpty == true
              ? dbType.nameMarathi!
              : (existing?.mr ?? dbType.name),
          hi: existing?.hi ?? dbType.name,
        ),
        isFromDb: isCustom,
      );
    }

    return optionsMap.values.map((entry) {
      final t = entry.option;
      final label = t.getLabel(lang);
      return DropdownMenuItem<String>(
        value: t.key,
        child: entry.isFromDb
            ? AppTranslatedText(
                label,
                targetLanguage: lang,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(label, overflow: TextOverflow.ellipsis),
      );
    }).toList();
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
    final lang = ref.read(appLanguageProvider);
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
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Draft cleared',
            mr: 'मसुदा साफ केला',
            hi: 'ड्राफ्ट साफ़ किया गया',
          ),
        ),
        backgroundColor: const Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final lang = ref.read(appLanguageProvider);
    if (_activeTab == 'outgoing') {
      final fName = _firstNameCtrl.text.trim();
      final lName = _lastNameCtrl.text.trim();
      final fullName = [fName, _middleNameCtrl.text.trim(), lName].where((s) => s.isNotEmpty).join(' ');
      final rawMobile = _mobileCtrl.text.trim();
      final mobile = (rawMobile == '+91' || rawMobile == '+91 ') ? '' : rawMobile;

      if (fName.isEmpty) {
        _showToast(
          AppTranslations.pick(
            lang,
            en: 'Please enter First Name',
            mr: 'कृपया पहिले नाव प्रविष्ट करा',
            hi: 'कृपया पहला नाम दर्ज करें',
          ),
          isError: true,
        );
        return;
      }
      if (lName.isEmpty) {
        _showToast(
          AppTranslations.pick(
            lang,
            en: 'Please enter Last Name',
            mr: 'कृपया आडनाव प्रविष्ट करा',
            hi: 'कृपया उपनाम दर्ज करें',
          ),
          isError: true,
        );
        return;
      }
      if (mobile.isEmpty) {
        _showToast(
          AppTranslations.pick(
            lang,
            en: 'Please enter Mobile Number',
            mr: 'कृपया मोबाईल नंबर प्रविष्ट करा',
            hi: 'कृपया मोबाइल नंबर दर्ज करें',
          ),
          isError: true,
        );
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
          _showToast(
            AppTranslations.pick(
              lang,
              en: 'Letter request created successfully!',
              mr: 'पत्र विनंती यशस्वीरित्या तयार झाली!',
              hi: 'पत्र अनुरोध सफलतापूर्वक बनाया गया!',
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          _showToast(
            '${AppTranslations.pick(lang, en: 'Failed to save request', mr: 'विनंती जतन करण्यात अयशस्वी', hi: 'अनुरोध सहेजने में विफल')}: $e',
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      // Incoming Letter
      final title = _incomingTitleCtrl.text.trim();
      if (title.isEmpty) {
        _showToast(
          AppTranslations.pick(
            lang,
            en: 'Please enter Letter Title',
            mr: 'कृपया पत्राचे शीर्षक प्रविष्ट करा',
            hi: 'कृपया पत्र का शीर्षक दर्ज करें',
          ),
          isError: true,
        );
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
          _showToast(
            AppTranslations.pick(
              lang,
              en: 'Incoming letter uploaded successfully!',
              mr: 'आवक पत्र यशस्वीरित्या जतन झाले!',
              hi: 'आवक पत्र सफलतापूर्वक अपलोड किया गया!',
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          _showToast(
            '${AppTranslations.pick(lang, en: 'Failed to upload letter', mr: 'पत्र अपलोड करण्यात अयशस्वी', hi: 'पत्र अपलोड करने में विफल')}: $e',
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

  void _openAddFieldDialog(String lang) {
    final available = kDynamicFieldDefinitions.keys
        .where((k) => !_activeDynamicFieldKeys.contains(k))
        .toList();
    final customFieldCtrl = TextEditingController();
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    Widget buildSheetContent(BuildContext ctx, StateSetter setModalState) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return Container(
        constraints: BoxConstraints(
          maxHeight: isDesktop ? 600 : MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isDesktop
              ? BorderRadius.circular(20)
              : const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: isDesktop
              ? null
              : const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. FIXED STANDARDIZED HEADER
            AppModalHeader(
              icon: Icons.add_circle_outline_rounded,
              title: AppTranslations.pick(
                lang,
                en: 'Add Additional Field',
                mr: 'अतिरिक्त माहितीचे फील्ड जोडा',
                hi: 'अतिरिक्त जानकारी फ़ील्ड जोड़ें',
              ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Select field for certificate or letter',
                mr: 'पत्रासाठी आवश्यक फील्ड निवडा',
                hi: 'प्रमाणपत्र या पत्र के लिए फ़ील्ड चुनें',
              ),
              onClose: () => Navigator.pop(ctx),
            ),

            // 2. SCROLLABLE BODY
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
                children: [
                  // Custom field input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customFieldCtrl,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Or enter custom field name...',
                              mr: 'किंवा नवीन फील्डचे नाव टाका...',
                              hi: 'या कस्टम फ़ील्ड नाम दर्ज करें...',
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          AppTranslations.pick(lang, en: 'Add', mr: 'जोडा', hi: 'जोड़ें'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Or choose from standard fields:',
                      mr: 'किंवा यादीतून निवडा:',
                      hi: 'या मानक फ़ील्ड में से चुनें:',
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),

                  ...available.map((key) {
                    final meta = kDynamicFieldDefinitions[key]!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7), size: 20),
                        title: Text(
                          meta.getLabel(lang),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                        subtitle: Text(
                          lang == 'en' ? meta.mrLabel : meta.enLabel,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _activeDynamicFieldKeys.add(key);
                            _dynamicControllers.putIfAbsent(key, () => TextEditingController());
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: StatefulBuilder(
                builder: (context, setModalState) => buildSheetContent(context, setModalState),
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) => buildSheetContent(context, setModalState),
        ),
      );
    }
  }

  void _openVoterSearchSheet() {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 740),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _VoterSearchModalSheet(
                onSelect: (voter) {
                  _handleVoterSelected(voter);
                  Navigator.pop(context);
                },
              ),
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

  Future<void> _pickReceivedDate() async {
    final picked = await showThemedDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _receivedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final titleText = _activeTab == 'outgoing'
        ? AppTranslations.pick(lang, en: 'New Letter Request', mr: 'नवीन पत्र विनंती', hi: 'नया पत्र अनुरोध')
        : AppTranslations.pick(lang, en: 'Upload Incoming Letter', mr: 'आवक पत्र अपलोड करा', hi: 'आवक पत्र अपलोड करें');

    final subtitleText = AppTranslations.pick(
      lang,
      en: 'Track and manage official correspondence',
      mr: 'अधिकृत पत्र विनंत्यांचा मागोवा घ्या आणि व्यवस्थापित करा',
      hi: 'आधिकारिक पत्राचार को ट्रैक और प्रबंधित करें',
    );

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
              icon: _activeTab == 'outgoing' ? Icons.mail_outline_rounded : Icons.move_to_inbox_rounded,
              title: titleText,
              subtitle: subtitleText,
              onClose: () => Navigator.pop(context),
            ),

            // Tab Selector: Outgoing vs Incoming
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
                        AppTranslations.pick(lang, en: 'Linked:', mr: 'जोडलेले मतदार:', hi: 'जुड़ा मतदाता:'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: AppTranslatedText(
                          _linkedVoterDisplay!,
                          isName: true,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                        AppTranslations.pick(lang, en: 'Draft autosaved', mr: 'मसुदा सेव्ह केला', hi: 'ड्राफ्ट स्वतः सहेजा गया'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleClearAllDrafts,
                        child: Text(
                          AppTranslations.pick(lang, en: 'Clear draft', mr: 'काढून टाका', hi: 'ड्राफ्ट हटाएँ'),
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
                  if (_activeTab == 'outgoing')
                    _buildOutgoingForm(lang)
                  else
                    _buildIncomingForm(lang),

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
  // TAB SELECTOR: OUTGOING vs INCOMING
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
              label: AppTranslations.pick(lang, en: 'Outgoing Letters', mr: 'जावक पत्र (Outgoing)', hi: 'जावक पत्र (Outgoing)'),
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
              label: AppTranslations.pick(lang, en: 'Incoming Letters', mr: 'आवक पत्र (Incoming)', hi: 'आवक पत्र (Incoming)'),
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
  Widget _buildOutgoingForm(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1: Applicant Name & Voter Details
        _CardSection(
          title: AppTranslations.pick(lang, en: 'Applicant Name', mr: 'नाव (अर्जदार)', hi: 'आवेदक का नाम'),
          icon: Icons.person_outline_rounded,
          action: OutlinedButton.icon(
            onPressed: _openVoterSearchSheet,
            icon: const Icon(Icons.search_rounded, size: 15),
            label: Text(AppTranslations.pick(lang, en: 'Search from Voter List', mr: 'मतदार यादीतून शोधा', hi: 'मतदाता सूची से खोजें')),
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
                      Text(
                        AppTranslations.pick(lang, en: 'Linked Voter:', mr: 'जोडलेले मतदार:', hi: 'जुड़ा मतदाता:'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppTranslatedText(
                          _linkedVoterDisplay!,
                          isName: true,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      label: AppTranslations.pick(lang, en: 'First Name', mr: 'पहिले नाव', hi: 'पहला नाम'),
                      placeholder: AppTranslations.pick(lang, en: 'First Name', mr: 'पहिले नाव', hi: 'पहला नाम'),
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _middleNameCtrl,
                      label: AppTranslations.pick(lang, en: 'Middle Name', mr: 'मधले नाव', hi: 'मध्य नाम'),
                      placeholder: AppTranslations.pick(lang, en: 'Middle Name', mr: 'मधले नाव', hi: 'मध्य नाम'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameCtrl,
                      label: AppTranslations.pick(lang, en: 'Last Name', mr: 'आडनाव', hi: 'उपनाम'),
                      placeholder: AppTranslations.pick(lang, en: 'Last Name', mr: 'आडनाव', hi: 'उपनाम'),
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mobile Number
              _buildTextField(
                controller: _mobileCtrl,
                label: AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                placeholder: AppTranslations.formatDigits('+91 98765 43210', lang),
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
          title: AppTranslations.pick(lang, en: 'Letter Details', mr: 'पत्राचा तपशील', hi: 'पत्र विवरण'),
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
                      label: AppTranslations.pick(lang, en: 'Gender', mr: 'लिंग', hi: 'लिंग'),
                      value: _selectedGender,
                      items: kGenderOptions.map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(
                            g == 'Male'
                                ? AppTranslations.pick(lang, en: 'Male', mr: 'पुरुष', hi: 'पुरुष')
                                : (g == 'Female'
                                    ? AppTranslations.pick(lang, en: 'Female', mr: 'महिला', hi: 'महिला')
                                    : AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य')),
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
                      label: AppTranslations.pick(lang, en: 'Letter Type', mr: 'पत्राचा प्रकार', hi: 'पत्र का प्रकार'),
                      value: _selectedLetterType,
                      items: _buildLetterTypeDropdownItems(lang),
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
                label: AppTranslations.pick(lang, en: 'Area', mr: 'क्षेत्र / परिसर', hi: 'क्षेत्र / परिसर'),
                placeholder: AppTranslations.formatDigits(
                  AppTranslations.pick(lang, en: 'e.g. Ganesh Nagar, Lane 3', mr: 'उदा. गणेश नगर, लेन ३', hi: 'उदा. गणेश नगर, गली 3'),
                  lang,
                ),
              ),

              const SizedBox(height: 14),

              // Subject
              _buildTextField(
                controller: _subjectCtrl,
                label: AppTranslations.pick(lang, en: 'Subject', mr: 'पत्राचा विषय', hi: 'पत्र का विषय'),
                placeholder: AppTranslations.pick(lang, en: 'Subject of the letter...', mr: 'पत्राचा विषय...', hi: 'पत्र का विषय...'),
              ),

              const SizedBox(height: 14),

              // Address / Details (3 rows, matching LetterForm.tsx line 576)
              _buildTextField(
                controller: _addressCtrl,
                label: AppTranslations.pick(lang, en: 'Address / Details', mr: 'पत्ता / तपशील', hi: 'पता / विवरण'),
                placeholder: AppTranslations.pick(
                  lang,
                  en: 'Current resident address or specific details...',
                  mr: 'सध्याचा रहिवासी पत्ता किंवा विशिष्ट तपशील...',
                  hi: 'वर्तमान निवास पता या विशिष्ट विवरण...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 14),

              // Purpose (matching LetterForm.tsx line 590)
              _buildTextField(
                controller: _purposeCtrl,
                label: AppTranslations.pick(lang, en: 'Purpose', mr: 'उद्देश / कारण', hi: 'उद्देश्य / कारण'),
                placeholder: AppTranslations.pick(lang, en: 'Purpose of the letter...', mr: 'पत्राचे कारण / उद्देश...', hi: 'पत्र का उद्देश्य...'),
              ),

              const SizedBox(height: 14),

              // Added By (Staff) - ALWAYS VISIBLE matching pattern
              _buildDropdown(
                label: AppTranslations.pick(lang, en: 'Added By (Staff)', mr: 'कर्मचारी (नोंदणीकर्ता) - ऐच्छिक', hi: 'कर्मचारी (दर्जकर्ता) - वैकल्पिक'),
                value: _selectedStaffId ?? '',
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(AppTranslations.pick(lang, en: 'Select Staff (Optional)', mr: 'कर्मचारी निवडा (ऐच्छिक)', hi: 'कर्मचारी चुनें (वैकल्पिक)')),
                  ),
                  ..._staffList.map((s) {
                    final roleLabel = AppTranslations.getRoleName(s.role ?? 'Staff', lang);
                    return DropdownMenuItem(
                      value: s.id,
                      child: Row(
                        children: [
                          Flexible(
                            child: AppTranslatedText(
                              s.name,
                              isName: true,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(' ($roleLabel)', overflow: TextOverflow.ellipsis),
                        ],
                      ),
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
        _buildAdditionalDetailsSection(lang),

        const SizedBox(height: 16),

        // Section 4: Attachments
        _buildAttachmentsSection(lang),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. INCOMING LETTER FORM (matching IncomingLetterUpload.tsx lines 347-518)
  // ---------------------------------------------------------------------------
  Widget _buildIncomingForm(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1: File Upload Box (matching IncomingLetterUpload.tsx lines 349-408)
        _CardSection(
          title: AppTranslations.pick(lang, en: 'Scan / Photo Document', mr: 'स्कॅन / फोटो दस्तऐवज', hi: 'स्कैन / फोटो दस्तावेज़'),
          icon: Icons.upload_file_rounded,
          action: Text(
            AppTranslations.formatDigits(
              AppTranslations.pick(lang, en: 'Max 10MB', mr: 'कमाल 10 MB', hi: 'अधिकतम 10 MB'),
              lang,
            ),
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImagePickerField(
                label: AppTranslations.pick(
                  lang,
                  en: 'Add photo or scanned copy of incoming letter',
                  mr: 'आवक पत्राचा फोटो किंवा स्कॅन कॉपी जोडा',
                  hi: 'आवक पत्र की फोटो या स्कैन कॉपी जोड़ें',
                ),
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
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 2: Incoming Letter Details (Title, Description, Area, Received Date)
        _CardSection(
          title: AppTranslations.pick(lang, en: 'Letter Details', mr: 'पत्राचा तपशील', hi: 'पत्र विवरण'),
          icon: Icons.mark_email_read_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _incomingTitleCtrl,
                label: AppTranslations.pick(lang, en: 'Letter Title', mr: 'पत्राचे शीर्षक', hi: 'पत्र का शीर्षक'),
                placeholder: AppTranslations.pick(lang, en: 'Letter Title...', mr: 'पत्राचे शीर्षक...', hi: 'पत्र का शीर्षक...'),
                required: true,
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _incomingDescCtrl,
                label: AppTranslations.pick(lang, en: 'Description', mr: 'वर्णन', hi: 'विवरण'),
                placeholder: AppTranslations.pick(
                  lang,
                  en: 'Add any notes or details about this letter...',
                  mr: 'पत्राबद्दल तपशील किंवा इतर माहिती...',
                  hi: 'इस पत्र के बारे में विवरण या टिप्पणी जोड़ें...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _incomingAreaCtrl,
                      label: AppTranslations.pick(lang, en: 'Area', mr: 'क्षेत्र / परिसर', hi: 'क्षेत्र / परिसर'),
                      placeholder: AppTranslations.pick(lang, en: 'Search Area...', mr: 'क्षेत्र शोधा...', hi: 'क्षेत्र खोजें...'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.pick(lang, en: 'Received Date', mr: 'प्राप्त झाल्याची तारीख', hi: 'प्राप्ति तिथि'),
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
                                    AppTranslations.formatDate(_receivedDate, lang, pattern: 'dd/MM/yyyy'),
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
                label: AppTranslations.pick(lang, en: 'Added By (Staff)', mr: 'कर्मचारी (नोंदणीकर्ता) - ऐच्छिक', hi: 'कर्मचारी (दर्जकर्ता) - वैकल्पिक'),
                value: _selectedStaffId ?? '',
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(AppTranslations.pick(lang, en: 'Select Staff (Optional)', mr: 'कर्मचारी निवडा (ऐच्छिक)', hi: 'कर्मचारी चुनें (वैकल्पिक)')),
                  ),
                  ..._staffList.map((s) {
                    final roleLabel = AppTranslations.getRoleName(s.role ?? 'Staff', lang);
                    return DropdownMenuItem(
                      value: s.id,
                      child: Row(
                        children: [
                          Flexible(
                            child: AppTranslatedText(
                              s.name,
                              isName: true,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(' ($roleLabel)', overflow: TextOverflow.ellipsis),
                        ],
                      ),
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
          title: AppTranslations.pick(lang, en: 'Bearer Details', mr: 'पत्र घेऊन येणाऱ्याची माहिती', hi: 'पत्र वाहक का विवरण'),
          icon: Icons.person_pin_circle_outlined,
          action: OutlinedButton.icon(
            onPressed: _openVoterSearchSheet,
            icon: const Icon(Icons.search_rounded, size: 15),
            label: Text(AppTranslations.pick(lang, en: 'Search from Voter List', mr: 'मतदार यादीतून शोधा', hi: 'मतदाता सूची से खोजें')),
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
                      label: AppTranslations.pick(lang, en: 'First Name', mr: 'पहिले नाव', hi: 'पहला नाम'),
                      placeholder: AppTranslations.pick(lang, en: 'First Name', mr: 'पहिले नाव', hi: 'पहला नाम'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _bearerMiddleNameCtrl,
                      label: AppTranslations.pick(lang, en: 'Middle Name', mr: 'मधले नाव', hi: 'मध्य नाम'),
                      placeholder: AppTranslations.pick(lang, en: 'Middle Name', mr: 'मधले नाव', hi: 'मध्य नाम'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _bearerLastNameCtrl,
                      label: AppTranslations.pick(lang, en: 'Last Name', mr: 'आडनाव', hi: 'उपनाम'),
                      placeholder: AppTranslations.pick(lang, en: 'Last Name', mr: 'आडनाव', hi: 'उपनाम'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _bearerMobileCtrl,
                label: AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                placeholder: AppTranslations.formatDigits('+91 98765 43210', lang),
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
  Widget _buildAdditionalDetailsSection(String lang) {
    return _CardSection(
      title: AppTranslations.pick(lang, en: 'Additional Details', mr: 'अतिरिक्त माहिती', hi: 'अतिरिक्त विवरण'),
      icon: Icons.playlist_add_check_rounded,
      action: InkWell(
        onTap: () => _openAddFieldDialog(lang),
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
                AppTranslations.pick(lang, en: 'Add Field', mr: 'फील्ड जोडा', hi: 'फ़ील्ड जोड़ें'),
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
                    AppTranslations.pick(
                      lang,
                      en: 'Fill in the specific details below or add custom fields',
                      mr: 'निवडलेल्या दाखल्यानुसार खालील तपशील भरा किंवा नवीन फील्ड जोडा',
                      hi: 'नीचे विशिष्ट विवरण भरें या कस्टम फ़ील्ड जोड़ें',
                    ),
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
                  AppTranslations.pick(
                    lang,
                    en: 'No additional fields added',
                    mr: 'कोणतेही अतिरिक्त फील्ड नाही',
                    hi: 'कोई अतिरिक्त फ़ील्ड नहीं जोड़ा गया',
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ..._activeDynamicFieldKeys.map((fieldKey) {
              final meta = kDynamicFieldDefinitions[fieldKey];
              final label = meta != null
                  ? meta.getLabel(lang)
                  : fieldKey.replaceAll('_', ' ').toUpperCase();
              final placeholder = meta != null
                  ? meta.getPlaceholder(lang)
                  : AppTranslations.pick(lang, en: 'Enter $label', mr: '$label प्रविष्ट करा', hi: '$label दर्ज करें');
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
  Widget _buildAttachmentsSection(String lang) {
    return _CardSection(
      title: AppTranslations.pick(
        lang,
        en: 'Attachments (Photos & Documents)',
        mr: 'संलग्न फाईल्स',
        hi: 'संलग्न फ़ाइलें (फ़ोटो व दस्तावेज़)',
      ),
      icon: Icons.attach_file_rounded,
      action: Text(
        AppTranslations.formatDigits(
          AppTranslations.pick(lang, en: 'Max 100MB', mr: 'कमाल 100 MB', hi: 'अधिकतम 100 MB'),
          lang,
        ),
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
  // SUBMIT BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildSubmitButton(String lang) {
    final buttonText = _activeTab == 'outgoing'
        ? AppTranslations.pick(lang, en: 'Create Request', mr: 'विनंती तयार करा', hi: 'अनुरोध बनाएँ')
        : AppTranslations.pick(lang, en: 'Upload Letter', mr: 'आवक पत्र जतन करा', hi: 'पत्र अपलोड करें');

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
      final ageText = AppTranslations.normalizeAsciiDigits(_ageFilterCtrl.text.trim());

      final list = await repo.searchVoters(
        query: query.isNotEmpty ? query : null,
        genderFilter: _selectedGender.isNotEmpty ? _selectedGender : null,
        ageRangeFilter: ageText.isNotEmpty ? ageText : null,
        pageSize: 40,
      );

      final house = AppTranslations.normalizeAsciiDigits(_houseNoFilterCtrl.text.trim()).toLowerCase();
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
            title: AppTranslations.pick(lang, en: 'Search from Voter List', mr: 'मतदार यादीतून शोधा', hi: 'मतदाता सूची से खोजें'),
            subtitle: AppTranslations.pick(lang, en: 'Filter voters from electoral roll', mr: 'नाव, घर क्र. किंवा पत्त्यानुसार शोधा', hi: 'नाम, मकान नं. या पते से खोजें'),
            onClose: () => Navigator.pop(context),
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
                          hintText: AppTranslations.pick(lang, en: 'Search by Name', mr: 'नावाने शोधा', hi: 'नाम से खोजें'),
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
                          hintText: AppTranslations.pick(lang, en: 'Search House No', mr: 'घर क्र. शोधा', hi: 'मकान नं. खोजें'),
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
                          hintText: AppTranslations.formatDigits(
                            AppTranslations.pick(lang, en: 'Age / Range (e.g. 18-24)', mr: 'वय / मर्यादा (उदा. 18-24)', hi: 'आयु / सीमा (उदा. 18-24)'),
                            lang,
                          ),
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
                          DropdownMenuItem(value: '', child: Text(AppTranslations.pick(lang, en: 'All Genders', mr: 'सर्व लिंग', hi: 'सभी लिंग'), style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'M', child: Text(AppTranslations.pick(lang, en: 'Male', mr: 'पुरुष', hi: 'पुरुष'), style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'F', child: Text(AppTranslations.pick(lang, en: 'Female', mr: 'महिला', hi: 'महिला'), style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'O', child: Text(AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य'), style: const TextStyle(fontSize: 12))),
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
                    hintText: AppTranslations.pick(lang, en: 'Search Address', mr: 'पत्त्यानुसार शोधा', hi: 'पते से खोजें'),
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
                            Text(
                              AppTranslations.pick(lang, en: 'No voters found', mr: 'कोणतेही मतदार सापडले नाहीत', hi: 'कोई मतदाता नहीं मिला'),
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
                          final displayName = lang == 'en'
                              ? (v.nameEnglish.isNotEmpty ? v.nameEnglish : v.nameMarathi)
                              : (v.nameMarathi.isNotEmpty ? v.nameMarathi : v.nameEnglish);
                          final genderShort = v.gender.toUpperCase() == 'M'
                              ? AppTranslations.pick(lang, en: 'M', mr: 'पु.', hi: 'पु.')
                              : (v.gender.toUpperCase() == 'F'
                                  ? AppTranslations.pick(lang, en: 'F', mr: 'म.', hi: 'म.')
                                  : AppTranslations.pick(lang, en: 'O', mr: 'इ.', hi: 'अ.'));
                          final yrLabel = AppTranslations.pick(lang, en: 'Y', mr: 'वर्षे', hi: 'वर्ष');

                          return ListTile(
                            onTap: () => widget.onSelect(v),
                            title: AppTranslatedText(
                              displayName,
                              isName: true,
                              targetLanguage: lang,
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
                                        AppTranslations.formatDigits('${v.age} $yrLabel • $genderShort', lang),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppTranslations.formatDigits('EPIC: ${v.epicNo}', lang),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    if (v.mobile != null && v.mobile!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        AppTranslations.formatDigits('| ${v.mobile}', lang),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                AppTranslatedText(
                                  v.address,
                                  targetLanguage: lang,
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
