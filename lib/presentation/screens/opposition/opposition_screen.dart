import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/opposition_model.dart';
import '../../../data/repositories/opposition_repository.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import 'opposition_detail_screen.dart';
import 'opposition_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class OppositionScreen extends ConsumerStatefulWidget {
  const OppositionScreen({super.key});

  @override
  ConsumerState<OppositionScreen> createState() => _OppositionScreenState();
}

class _OppositionScreenState extends ConsumerState<OppositionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'all'; // 'all', 'candidate', 'worker'
  String _selectedParty = 'all'; // 'all', 'INC', 'NCP', 'UBT', 'MNS', 'BJP', 'Independent'
  String _selectedArea = '';
  int _viewMode = 0; // 0 = Cards, 1 = Table

  bool _isLoading = true;
  List<OppositionMemberModel> _members = [];
  Map<String, int> _stats = {
    'total': 0,
    'candidates': 0,
    'workers': 0,
    'controversies': 0,
    'activities': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadOppositionData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOppositionData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(oppositionRepoProvider);

    final members = await repo.getMembers(
      party: _selectedParty == 'all' ? null : _selectedParty,
      type: _selectedType == 'all' ? null : _selectedType,
      area: _selectedArea.isEmpty ? null : _selectedArea,
      query: _searchController.text.trim(),
    );

    final stats = await repo.getOppositionStats();

    if (mounted) {
      setState(() {
        _members = members;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Color _getPartyColor(String party) {
    switch (party.toUpperCase()) {
      case 'INC':
        return const Color(0xFF0284C7);
      case 'NCP':
        return const Color(0xFF10B981);
      case 'UBT':
        return const Color(0xFFF97316);
      case 'MNS':
        return const Color(0xFF8B5CF6);
      case 'BJP':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getCandidacyStatusColor(String? status) {
    switch (status) {
      case 'Won':
        return const Color(0xFF16A34A);
      case 'Lost':
        return const Color(0xFF64748B);
      case 'Withdrawn':
        return const Color(0xFFDC2626);
      case 'Contesting':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFFD97706);
    }
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = AppTranslations.normalizeAsciiDigits(phone).replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = AppTranslations.normalizeAsciiDigits(phone).replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ===========================================================================
  // ADD / EDIT OPPOSITION MEMBER MODAL
  // ===========================================================================
  void _showMemberForm({OppositionMemberModel? memberToEdit}) {
    final lang = ref.read(appLanguageProvider);
    final nameCtrl = TextEditingController(text: memberToEdit?.name ?? '');
    final phoneCtrl = TextEditingController(text: memberToEdit?.mobile ?? '');
    final roleCtrl = TextEditingController(text: memberToEdit?.role ?? '');
    final areaCtrl = TextEditingController(text: memberToEdit?.area ?? '');
    final strongholdsCtrl = TextEditingController(text: memberToEdit != null ? memberToEdit.strongholds.join(', ') : '');
    final notesCtrl = TextEditingController(text: memberToEdit?.notes ?? '');

    bool isCandidate = memberToEdit?.isCandidate ?? false;
    String party = memberToEdit?.party ?? 'INC';
    String candidacyStatus = memberToEdit?.candidacyStatus ?? 'Declared';
    final constCtrl = TextEditingController(
      text: memberToEdit?.constituency ??
          AppTranslations.pick(
            lang,
            en: 'Ward 12 (Pune PMC)',
            mr: 'प्रभाग १२ (पुणे मनपा)',
            hi: 'वार्ड १२ (पुणे मनपा)',
          ),
    );
    final oppCtrl = TextEditingController(
      text: memberToEdit?.opposingCandidate ??
          AppTranslations.pick(
            lang,
            en: 'Sitting Corporator',
            mr: 'विद्यमान नगरसेवक',
            hi: 'वर्तमान पार्षद',
          ),
    );
    String? selectedCandidateId = memberToEdit?.candidateId;

    final repo = ref.read(oppositionRepoProvider);
    final candidatesList = _members.where((m) => m.isCandidate && m.id != memberToEdit?.id).toList();

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return AppFieldLabel(label: text, isRequired: isRequired);
    }

    InputDecoration inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
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
              // 1. FIXED HEADER
              AppModalHeader(
                icon: Icons.group_add_rounded,
                title: memberToEdit == null
                    ? AppTranslations.pick(lang, en: 'Add Opposition Member', mr: 'नवीन विरोधी सदस्य', hi: 'नया विपक्षी सदस्य जोड़ें')
                    : AppTranslations.pick(lang, en: 'Edit Opposition Member', mr: 'विरोधी सदस्य संपादित करा', hi: 'विपक्षी सदस्य संपादित करें'),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Track opposition candidates, workers and political presence',
                  mr: 'प्रभागातील विरोधी पक्षांचे उमेदवार व कार्यकर्ते नोंदवा',
                  hi: 'वार्ड के विपक्षी उम्मीदवारों व कार्यकर्ताओं का विवरण दर्ज करें',
                ),
                onClose: () => Navigator.pop(ctx),
              ),

              // 2. SCROLLABLE FORM BODY & BUTTONS
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  children: [
                    // Record Type Switch: Worker vs Candidate
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => isCandidate = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !isCandidate ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !isCandidate ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
                                ),
                                child: Text(
                                  AppTranslations.pick(lang, en: 'Opposition Cadre', mr: 'विरोधी कार्यकर्ता', hi: 'विपक्षी कार्यकर्ता'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => isCandidate = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCandidate ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isCandidate ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
                                ),
                                child: Text(
                                  AppTranslations.pick(lang, en: 'Opposition Candidate', mr: 'विरोधी उमेदवार', hi: 'विपक्षी उम्मीदवार'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Full Name & Party side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(
                                AppTranslations.pick(lang, en: 'Full Name', mr: 'पूर्ण नाव', hi: 'पूरा नाम'),
                                isRequired: true,
                              ),
                              TextField(
                                controller: nameCtrl,
                                decoration: inputDec(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Adv. Ramesh Shinde',
                                    mr: 'उदा. ॲड. रमेश शिंदे',
                                    hi: 'उदा. एड. रमेश शिंदे',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppDropdownFormField<String>(
                                label: AppTranslations.pick(lang, en: 'Party', mr: 'पक्ष', hi: 'पार्टी'),
                                isRequired: true,
                                value: party,
                                items: [
                                  DropdownMenuItem(value: 'INC', child: Text(AppTranslations.pick(lang, en: 'Congress (INC)', mr: 'काँग्रेस (INC)', hi: 'कांग्रेस (INC)'))),
                                  DropdownMenuItem(value: 'NCP', child: Text(AppTranslations.pick(lang, en: 'NCP', mr: 'राष्ट्रवादी (NCP)', hi: 'राकांपा (NCP)'))),
                                  DropdownMenuItem(value: 'UBT', child: Text(AppTranslations.pick(lang, en: 'Shiv Sena (UBT)', mr: 'शिवसेना (UBT)', hi: 'शिवसेना (UBT)'))),
                                  DropdownMenuItem(value: 'MNS', child: Text(AppTranslations.pick(lang, en: 'MNS', mr: 'मनसे (MNS)', hi: 'मनसे (MNS)'))),
                                  DropdownMenuItem(value: 'BJP', child: Text(AppTranslations.pick(lang, en: 'BJP', mr: 'भाजप (BJP)', hi: 'भाजपा (BJP)'))),
                                  DropdownMenuItem(value: 'Independent', child: Text(AppTranslations.pick(lang, en: 'Independent (Ind)', mr: 'अपक्ष (Independent)', hi: 'निर्दलीय (Ind)'))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => party = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Mobile Number & Role side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर')),
                              TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: inputDec(
                                  hintText: AppTranslations.formatDigits('98220xxxxx', lang),
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
                              fieldLabel(AppTranslations.pick(lang, en: 'Role / Designation', mr: 'पद / हुद्दा', hi: 'पद / भूमिका')),
                              TextField(
                                controller: roleCtrl,
                                decoration: inputDec(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Ex-Corporator, Ward President',
                                    mr: 'उदा. माजी नगरसेवक, प्रभाग अध्यक्ष',
                                    hi: 'उदा. पूर्व पार्षद, वार्ड अध्यक्ष',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Base Area & Strongholds side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(AppTranslations.pick(lang, en: 'Primary Work Area', mr: 'कार्यक्षेत्र / परिसर', hi: 'मुख्य कार्यक्षेत्र / क्षेत्र')),
                              TextField(
                                controller: areaCtrl,
                                decoration: inputDec(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Tilak Chowk, Sector 3',
                                    mr: 'उदा. टिळक चौक, सेक्टर ३',
                                    hi: 'उदा. तिलक चौक, सेक्टर ३',
                                  ),
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
                              fieldLabel(AppTranslations.pick(lang, en: 'Strongholds / Booths', mr: 'प्रभाव क्षेत्रे', hi: 'प्रभाव क्षेत्र / बूथ')),
                              TextField(
                                controller: strongholdsCtrl,
                                decoration: inputDec(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Booth 4-6, Shanti Nagar',
                                    mr: 'उदा. बूथ ४-६, शांति नगर',
                                    hi: 'उदा. बूथ ४-६, शांति नगर',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // If Candidate: Show Constituency & Opposing Candidate side-by-side
                    if (isCandidate) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(AppTranslations.pick(lang, en: 'Constituency / Ward', mr: 'मतदारसंघ / प्रभाग', hi: 'निर्वाचन क्षेत्र / वार्ड')),
                                TextField(
                                  controller: constCtrl,
                                  decoration: inputDec(
                                    hintText: AppTranslations.pick(
                                      lang,
                                      en: 'Ward 12 (Pune PMC)',
                                      mr: 'प्रभाग १२ (पुणे मनपा)',
                                      hi: 'वार्ड १२ (पुणे मनपा)',
                                    ),
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
                                fieldLabel(AppTranslations.pick(lang, en: 'Opposing Candidate', mr: 'विरोधी उमेदवार', hi: 'प्रतिद्वंद्वी उम्मीदवार')),
                                TextField(
                                  controller: oppCtrl,
                                  decoration: inputDec(
                                    hintText: AppTranslations.pick(
                                      lang,
                                      en: 'Sitting Corporator',
                                      mr: 'विद्यमान नगरसेवक',
                                      hi: 'वर्तमान पार्षद',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppDropdownFormField<String>(
                        label: AppTranslations.pick(lang, en: 'Candidacy Status', mr: 'उमेदवारी स्थिती', hi: 'उम्मीदवारी स्थिति'),
                        value: candidacyStatus,
                        items: [
                          DropdownMenuItem(value: 'Declared', child: Text(AppTranslations.pick(lang, en: 'Declared', mr: 'घोषित', hi: 'घोषित'))),
                          DropdownMenuItem(value: 'Contesting', child: Text(AppTranslations.pick(lang, en: 'Contesting', mr: 'लढत असलेले', hi: 'चुनाव लड़ रहे'))),
                          DropdownMenuItem(value: 'Withdrawn', child: Text(AppTranslations.pick(lang, en: 'Withdrawn', mr: 'मागे घेतलेले', hi: 'नाम वापस'))),
                          DropdownMenuItem(value: 'Won', child: Text(AppTranslations.pick(lang, en: 'Won', mr: 'विजयी', hi: 'विजयी'))),
                          DropdownMenuItem(value: 'Lost', child: Text(AppTranslations.pick(lang, en: 'Lost', mr: 'पराजित', hi: 'पराजित'))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => candidacyStatus = val);
                        },
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      // If Worker: Option to link to candidate
                      if (candidatesList.isNotEmpty) ...[
                        AppDropdownFormField<String>(
                          label: AppTranslations.pick(lang, en: 'Link to Candidate (Optional)', mr: 'उमेदवाराशी जोडा (पर्यायी)', hi: 'उम्मीदवार से जोड़ें (वैकल्पिक)'),
                          value: selectedCandidateId,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(AppTranslations.pick(lang, en: 'Not linked to any candidate', mr: 'कोणाशीही जोडलेले नाही', hi: 'किसी भी उम्मीदवार से नहीं जुड़ा')),
                            ),
                            ...candidatesList.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: AppTranslatedText(
                                  '${c.name} (${c.party})',
                                  targetLanguage: lang,
                                  isName: true,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => setModalState(() => selectedCandidateId = val),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],

                    // Notes / Strategy
                    fieldLabel(AppTranslations.pick(lang, en: 'Notes & Strategy', mr: 'नोंदी व रणनीती', hi: 'टिप्पणियाँ और रणनीति')),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: inputDec(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Local influence, outreach, and political observations...',
                          mr: 'स्थानिक प्रभाव, राजकीय निरीक्षणे...',
                          hi: 'स्थानीय प्रभाव, जनसंपर्क और राजनीतिक टिप्पणियाँ...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          memberToEdit == null
                              ? AppTranslations.pick(lang, en: 'Add Member', mr: 'सदस्य जतन करा', hi: 'सदस्य जोड़ें')
                              : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'बदलाव सहेजें'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Please enter opposition member name.',
                                    mr: 'कृपया विरोधी सदस्याचे नाव प्रविष्ट करा.',
                                    hi: 'कृपया विपक्षी सदस्य का नाम दर्ज करें।',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          final strongholdsList = strongholdsCtrl.text
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();

                          final cleanMobile = AppTranslations.normalizeAsciiDigits(phoneCtrl.text.trim());
                          final newMember = OppositionMemberModel(
                            id: memberToEdit?.id ?? 'opp-${isCandidate ? "cand" : "wrk"}-${DateTime.now().millisecondsSinceEpoch}',
                            name: nameCtrl.text.trim(),
                            mobile: cleanMobile.isNotEmpty ? cleanMobile : null,
                            party: party,
                            role: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : null,
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : null,
                            strongholds: strongholdsList,
                            notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            isCandidate: isCandidate,
                            constituency: isCandidate ? constCtrl.text.trim() : null,
                            opposingCandidate: isCandidate ? oppCtrl.text.trim() : null,
                            candidacyStatus: isCandidate ? candidacyStatus : null,
                            candidateId: !isCandidate ? selectedCandidateId : null,
                            activities: memberToEdit?.activities ?? [],
                            negativeStories: memberToEdit?.negativeStories ?? [],
                            createdAt: memberToEdit?.createdAt ?? DateTime.now(),
                          );

                          if (memberToEdit == null) {
                            await repo.addMember(newMember);
                          } else {
                            await repo.updateMember(newMember);
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          _loadOppositionData();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  memberToEdit == null
                                      ? AppTranslations.pick(lang, en: 'Opposition member added successfully!', mr: 'विरोधी सदस्य यशस्वीरित्या जोडला!', hi: 'विपक्षी सदस्य सफलतापूर्वक जोड़ा गया!')
                                      : AppTranslations.pick(lang, en: 'Details updated!', mr: 'तपशील अद्यतनित केले!', hi: 'विवरण अपडेट किए गए!'),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DELETE CONFIRMATION DIALOG
  // ===========================================================================
  void _confirmDeleteMember(OppositionMemberModel member) {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTranslations.pick(lang, en: 'Delete Opposition Record?', mr: 'विरोधी नोंद हटवायची का?', hi: 'विपक्षी रिकॉर्ड हटाएँ?')),
        content: AppTranslatedText(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete record for "${member.name}"? This action cannot be undone.',
            mr: '"${member.name}" यांची नोंद हटवायची आहे का? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई "${member.name}" का रिकॉर्ड हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
          ),
          targetLanguage: lang,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(oppositionRepoProvider);
              await repo.deleteMember(member.id);
              _loadOppositionData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppTranslations.pick(lang, en: 'Record deleted successfully!', mr: 'नोंद यशस्वीरित्या हटवली!', hi: 'रिकॉर्ड सफलतापूर्वक हटाया गया!')),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(oppositionRepoProvider);
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            tooltip: AppTranslations.pick(lang, en: 'Open Menu Drawer', mr: 'मेनू उघडा', hi: 'मेनू खोलें'),
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
              AppTranslations.pick(lang, en: 'Opposition Information', mr: 'विरोधी पक्ष माहिती', hi: 'विपक्ष की जानकारी'),
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
              AppTranslations.pick(
                lang,
                en: 'Opposition candidate profiles, past records and public claims',
                mr: 'विरोधी उमेदवारांची माहिती, मागील नोंदी व दावे',
                hi: 'विपक्षी उम्मीदवारों की प्रोफ़ाइल, पिछले रिकॉर्ड और दावे',
              ),
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: AppLanguageSegmentedSelector(isCompact: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOppositionData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 2. SEARCH & VIEW TOGGLE
              // ==========================================
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _loadOppositionData(),
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'Search name, role, strongholds or keywords...',
                            mr: 'नाव, पद, प्रभाव क्षेत्र किंवा कीवर्ड शोधा...',
                            hi: 'नाम, पद, प्रभाव क्षेत्र या कीवर्ड खोजें...',
                          ),
                          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadOppositionData();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // View & Export Controls
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.grid_view_rounded, size: 20, color: _viewMode == 0 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _viewMode = 0),
                          tooltip: AppTranslations.pick(lang, en: 'Card View', mr: 'कार्ड दृश्य', hi: 'कार्ड दृश्य'),
                        ),
                        IconButton(
                          icon: Icon(Icons.table_rows_rounded, size: 20, color: _viewMode == 1 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _viewMode = 1),
                          tooltip: AppTranslations.pick(lang, en: 'Table View', mr: 'तक्ता दृश्य', hi: 'तालिका दृश्य'),
                        ),
                        Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
                        const SizedBox(width: 4),
                        AppPdfButton.icon(
                          tooltip: AppTranslations.pick(lang, en: 'Download Report', mr: 'अहवाल डाउनलोड करा', hi: 'रिपोर्ट डाउनलोड करें'),
                          onPressed: () {
                            OppositionReportGenerator.generateAndPrintReport(
                              context: context,
                              members: _members,
                              getCandidateName: repo.getCandidateName,
                              lang: lang,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 3. FILTER TABS: RECORD TYPE & PARTY
              // ==========================================
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      '${AppTranslations.pick(lang, en: 'All', mr: 'सर्व', hi: 'सभी')} (${AppTranslations.formatDigits('${_stats['total'] ?? 0}', lang)})',
                      'all',
                      _selectedType,
                      (val) {
                        setState(() => _selectedType = val);
                        _loadOppositionData();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      '${AppTranslations.pick(lang, en: 'Candidates', mr: 'उमेदवार', hi: 'उम्मीदवार')} (${AppTranslations.formatDigits('${_stats['candidates'] ?? 0}', lang)})',
                      'candidate',
                      _selectedType,
                      (val) {
                        setState(() => _selectedType = val);
                        _loadOppositionData();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      '${AppTranslations.pick(lang, en: 'Cadre', mr: 'कार्यकर्ते', hi: 'कार्यकर्ता')} (${AppTranslations.formatDigits('${_stats['workers'] ?? 0}', lang)})',
                      'worker',
                      _selectedType,
                      (val) {
                        setState(() => _selectedType = val);
                        _loadOppositionData();
                      },
                    ),
                    const SizedBox(width: 14),

                    // Party Filters
                    Container(height: 18, width: 1, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 14),
                    _buildPartyFilterChip(AppTranslations.pick(lang, en: 'All Parties', mr: 'सर्व पक्ष', hi: 'सभी दल'), 'all'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip(AppTranslations.pick(lang, en: 'Congress', mr: 'काँग्रेस', hi: 'कांग्रेस'), 'INC'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip(AppTranslations.pick(lang, en: 'NCP', mr: 'राष्ट्रवादी', hi: 'राकांपा'), 'NCP'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip(AppTranslations.pick(lang, en: 'Shiv Sena (UBT)', mr: 'शिवसेना (UBT)', hi: 'शिवसेना (UBT)'), 'UBT'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip(AppTranslations.pick(lang, en: 'MNS', mr: 'मनसे', hi: 'मनसे'), 'MNS'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip(AppTranslations.pick(lang, en: 'BJP', mr: 'भाजप', hi: 'भाजपा'), 'BJP'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip(AppTranslations.pick(lang, en: 'Independent', mr: 'अपक्ष', hi: 'निर्दलीय'), 'Independent'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================
              // 4. MAIN CONTENT (CARDS OR TABLE)
              // ==========================================
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_members.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_off_outlined, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No opposition members found.',
                          mr: 'कोणतेही विरोधी सदस्य आढळले नाहीत.',
                          hi: 'कोई विपक्षी सदस्य नहीं मिला।',
                        ),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Use the "+ Add Member" button below to create a record.',
                          mr: 'नोंद तयार करण्यासाठी खालील "+ सदस्य जोडा" बटण वापरा.',
                          hi: 'रिकॉर्ड बनाने के लिए नीचे "+ सदस्य जोड़ें" बटन का उपयोग करें।',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showMemberForm(),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppTranslations.pick(lang, en: 'Add Opposition Member', mr: 'विरोधी सदस्य जोडा', hi: 'विपक्षी सदस्य जोड़ें')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_viewMode == 0)
                // CARDS VIEW
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final member = _members[idx];
                    return _buildMemberCard(member, repo, lang);
                  },
                )
              else
                // SPREADSHEET TABLE VIEW
                _buildSpreadsheetTable(repo, lang),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMemberForm(),
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          AppTranslations.pick(lang, en: 'Add Member', mr: 'सदस्य जोडा', hi: 'सदस्य जोड़ें'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET HELPERS
  // ===========================================================================
  Widget _buildFilterChip(String label, String value, String current, ValueChanged<String> onSelect) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPartyFilterChip(String label, String partyCode) {
    final isSelected = _selectedParty == partyCode;
    return InkWell(
      onTap: () {
        setState(() => _selectedParty = partyCode);
        _loadOppositionData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(OppositionMemberModel member, OppositionRepository repo, String lang) {
    final partyColor = _getPartyColor(member.party);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OppositionDetailScreen(member: member)),
        );
        _loadOppositionData();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: member.isCandidate ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
            width: member.isCandidate ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Edit/Delete Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: partyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: partyColor.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Icon(
                      member.isCandidate ? Icons.campaign_rounded : Icons.person_outline_rounded,
                      color: partyColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTranslatedText(
                              member.name,
                              targetLanguage: lang,
                              isName: true,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                          if (member.isCandidate)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (member.role != null && member.role!.trim().isNotEmpty)
                        AppTranslatedText(
                          member.role!,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        )
                      else
                        Text(
                          member.isCandidate
                              ? AppTranslations.pick(lang, en: 'Candidate', mr: 'उमेदवार', hi: 'उम्मीदवार')
                              : AppTranslations.pick(lang, en: 'Cadre', mr: 'कार्यकर्ता', hi: 'कार्यकर्ता'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(height: 6),

                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: partyColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: partyColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              member.partyFullLabelFor(lang),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: partyColor),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: member.isCandidate ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              member.typeLabel(lang),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: member.isCandidate ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          if (member.isCandidate && member.candidacyStatus != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getCandidacyStatusColor(member.candidacyStatus).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                member.candidacyStatusLabel(lang),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getCandidacyStatusColor(member.candidacyStatus),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Edit/Delete Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showMemberForm(memberToEdit: member);
                    } else if (val == 'delete') {
                      _confirmDeleteMember(member);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Text(AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Text(
                            AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ'),
                            style: const TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Middle Row: Contact & Base Area
            Row(
              children: [
                if (member.mobile != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.formatDigits(member.mobile!, lang),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _makePhoneCall(member.mobile),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.phone, size: 13, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _openWhatsApp(member.mobile),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (member.area != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppTranslatedText(
                            member.area!,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Strongholds chips
            if (member.strongholds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: member.strongholds.take(3).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AppTranslatedText(
                      s,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),

            // Bottom Action Bar: Activities count, Controversies badge & View details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      if (member.negativeStories.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                              const SizedBox(width: 4),
                              Text(
                                '${AppTranslations.formatDigits('${member.negativeStories.length}', lang)} ${AppTranslations.pick(lang, en: 'Controversies', mr: 'वादग्रस्त प्रकरणे', hi: 'विवाद')}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (member.activities.isNotEmpty)
                        Flexible(
                          child: Text(
                            '${AppTranslations.formatDigits('${member.activities.length}', lang)} ${AppTranslations.pick(lang, en: 'Activities', mr: 'उपक्रम', hi: 'गतिविधियाँ')}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppTranslations.pick(lang, en: 'Detailed Profile', mr: 'सविस्तर माहिती', hi: 'विस्तृत प्रोफ़ाइल'),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0284C7)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SPREADSHEET TABLE VIEW
  // ===========================================================================
  Widget _buildSpreadsheetTable(OppositionRepository repo, String lang) {
    return Container(
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
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: [
              DataColumn(label: Text(AppTranslations.pick(lang, en: '#', mr: 'क्र.', hi: 'क्र.'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Name', mr: 'नाव', hi: 'नाम'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Party', mr: 'पक्ष', hi: 'पार्टी'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Type', mr: 'प्रकार', hi: 'प्रकार'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Role / Designation', mr: 'पद / हुद्दा', hi: 'पद / भूमिका'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Work Area', mr: 'कार्यक्षेत्र', hi: 'कार्यक्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Strongholds', mr: 'प्रभाव क्षेत्रे', hi: 'प्रभाव क्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status / Candidate', mr: 'स्थिती / उमेदवार', hi: 'स्थिति / उम्मीदवार'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Issues', mr: 'प्रकरणे', hi: 'विवाद'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Action', mr: 'कृती', hi: 'कार्रवाई'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: List.generate(_members.length, (index) {
              final m = _members[index];
              final partyColor = _getPartyColor(m.party);

              final bool isCandStatus = m.isCandidate;
              final bool hasLinkedCand = !m.isCandidate && m.candidateId != null && m.candidateId!.isNotEmpty;
              final String linkedCandName = hasLinkedCand ? repo.getCandidateName(m.candidateId!) : '';

              return DataRow(
                cells: [
                  DataCell(Text(AppTranslations.formatDigits('${index + 1}', lang), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    AppTranslatedText(
                      m.name,
                      targetLanguage: lang,
                      isName: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: partyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(m.partyFullLabelFor(lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: partyColor)),
                    ),
                  ),
                  DataCell(
                    Text(
                      m.typeLabel(lang),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: m.isCandidate ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  DataCell(
                    m.role != null && m.role!.trim().isNotEmpty
                        ? AppTranslatedText(m.role!, targetLanguage: lang, style: const TextStyle(fontSize: 11))
                        : const Text('-', style: TextStyle(fontSize: 11)),
                  ),
                  DataCell(
                    m.area != null && m.area!.trim().isNotEmpty
                        ? AppTranslatedText(m.area!, targetLanguage: lang, style: const TextStyle(fontSize: 11))
                        : const Text('-', style: TextStyle(fontSize: 11)),
                  ),
                  DataCell(
                    m.strongholds.isNotEmpty
                        ? AppTranslatedText(m.strongholds.take(2).join(', '), targetLanguage: lang, style: const TextStyle(fontSize: 11))
                        : const Text('-', style: TextStyle(fontSize: 11)),
                  ),
                  DataCell(
                    isCandStatus
                        ? Text(m.candidacyStatusLabel(lang), style: const TextStyle(fontSize: 11))
                        : (linkedCandName.isNotEmpty
                            ? AppTranslatedText(linkedCandName, targetLanguage: lang, isName: true, style: const TextStyle(fontSize: 11))
                            : const Text('-', style: TextStyle(fontSize: 11))),
                  ),
                  DataCell(
                    Text(
                      AppTranslations.formatDigits('${m.negativeStories.length}', lang),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: m.negativeStories.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                      tooltip: AppTranslations.pick(lang, en: 'View Profile', mr: 'प्रोफाईल पहा', hi: 'प्रोफ़ाइल देखें'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OppositionDetailScreen(member: m)),
                        );
                        _loadOppositionData();
                      },
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
