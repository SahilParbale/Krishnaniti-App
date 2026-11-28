import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/opposition_model.dart';
import '../../../data/repositories/opposition_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pagination_bar.dart';

class OppositionDetailScreen extends ConsumerStatefulWidget {
  final OppositionMemberModel member;

  const OppositionDetailScreen({super.key, required this.member});

  @override
  ConsumerState<OppositionDetailScreen> createState() => _OppositionDetailScreenState();
}

class _OppositionDetailScreenState extends ConsumerState<OppositionDetailScreen> {
  late OppositionMemberModel _member;
  int _teamPage = 1;
  static const int _teamPageSize = 5;
  int _storyPage = 1;
  static const int _storyPageSize = 4;
  int _activityPage = 1;
  static const int _activityPageSize = 5;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  Future<void> _refreshMember() async {
    final repo = ref.read(oppositionRepoProvider);
    final members = await repo.getMembers();
    final updated = members.where((m) => m.id == _member.id).firstOrNull;
    if (updated != null && mounted) {
      setState(() => _member = updated);
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

  // ===========================================================================
  // LOG CAMPAIGN ACTIVITY MODAL
  // ===========================================================================
  void _showAddActivityModal() {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController();
    final locCtrl = TextEditingController(text: _member.area ?? '');
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              AppModalHeader(
                icon: Icons.event_note_rounded,
                title: AppTranslations.pick(
                  lang,
                  en: 'Record Campaign Activity',
                  mr: 'प्रचार उपक्रमाची नोंद करा',
                  hi: 'प्रचार गतिविधि दर्ज करें',
                ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Fill campaign activity details',
                  mr: 'उपक्रमाचे तपशील भरा',
                  hi: 'गतिविधि का विवरण भरें',
                ),
                onClose: () => Navigator.pop(ctx),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  children: [
                    // Date & Activity Title side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Activity Date',
                                  mr: 'तारीख',
                                  hi: 'तिथि',
                                ),
                                isRequired: true,
                              ),
                              InkWell(
                                onTap: () async {
                                  final picked = await showThemedDatePicker(
                                    context: ctx,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          AppTranslations.formatDate(selectedDate, lang),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Activity Title',
                                  mr: 'उपक्रमाचे नाव / शीर्षक',
                                  hi: 'गतिविधि का शीर्षक',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: titleCtrl,
                                decoration: appInputDecoration(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Citizen Rights March',
                                    mr: 'उदा. जनआक्रोश मोर्चा, शिबीर',
                                    hi: 'उदा. जन आक्रोश मार्च, शिविर',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Location / Vicinity
                    AppFieldLabel(
                      label: AppTranslations.pick(
                        lang,
                        en: 'Location / Vicinity',
                        mr: 'स्थान / परिसर',
                        hi: 'स्थान / क्षेत्र',
                      ),
                    ),
                    TextField(
                      controller: locCtrl,
                      decoration: appInputDecoration(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'e.g. Sector 3 Chowk',
                          mr: 'उदा. सेक्टर ३ चौक, मुख्य रस्ता',
                          hi: 'उदा. सेक्टर ३ चौक, मुख्य मार्ग',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description & Notes
                    AppFieldLabel(
                      label: AppTranslations.pick(
                        lang,
                        en: 'Activity Description & Notes',
                        mr: 'तपशील व निरीक्षणे',
                        hi: 'गतिविधि विवरण और टिप्पणियाँ',
                      ),
                    ),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: appInputDecoration(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'Nature of activity, key demands, and political impact...',
                          mr: 'उपक्रमाचे स्वरूप, प्रमुख मागण्या व प्रभाव...',
                          hi: 'गतिविधि का स्वरूप, प्रमुख माँगें और प्रभाव...',
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
                          AppTranslations.pick(
                            lang,
                            en: 'Save Activity',
                            mr: 'उपक्रम जतन करा',
                            hi: 'गतिविधि सहेजें',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Please enter activity title.',
                                    mr: 'कृपया उपक्रमाचे नाव प्रविष्ट करा.',
                                    hi: 'कृपया गतिविधि का शीर्षक दर्ज करें।',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          final newAct = OppositionActivityModel(
                            id: 'act-${DateTime.now().millisecondsSinceEpoch}',
                            date: DateFormat('yyyy-MM-dd').format(selectedDate),
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            location: locCtrl.text.trim(),
                          );

                          final repo = ref.read(oppositionRepoProvider);
                          await repo.addActivity(_member.id, newAct);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          _refreshMember();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Activity recorded successfully!',
                                    mr: 'उपक्रम यशस्वीरित्या नोंदवला गेला!',
                                    hi: 'गतिविधि सफलतापूर्वक दर्ज की गई!',
                                  ),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
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
  // ADD / EDIT CONTROVERSY / NEGATIVE STORY MODAL
  // ===========================================================================
  void _showNegativeStoryModal({OppositionNegativeStoryModel? storyToEdit}) {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController(text: storyToEdit?.title ?? '');
    final sourceCtrl = TextEditingController(text: storyToEdit?.source ?? '');
    final descCtrl = TextEditingController(text: storyToEdit?.description ?? '');
    String severity = storyToEdit?.severity ?? 'Medium';
    DateTime selectedDate = storyToEdit != null ? (DateTime.tryParse(storyToEdit.date) ?? DateTime.now()) : DateTime.now();

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
              AppModalHeader(
                icon: Icons.warning_amber_rounded,
                title: storyToEdit == null
                    ? AppTranslations.pick(
                        lang,
                        en: 'Record Controversy / Incident',
                        mr: 'वादग्रस्त घटना / प्रकरण नोंदवा',
                        hi: 'विवादास्पद घटना / प्रकरण दर्ज करें',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Edit Controversy / Incident',
                        mr: 'वादग्रस्त प्रकरण संपादित करा',
                        hi: 'विवादास्पद प्रकरण संपादित करें',
                      ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Incident details & evidence reference',
                  mr: 'प्रकरणाचा तपशील व पुरावा संदर्भ',
                  hi: 'प्रकरण का विवरण व साक्ष्य संदर्भ',
                ),
                onClose: () => Navigator.pop(ctx),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  children: [
                    // Incident Date & Source / Evidence Reference side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Incident Date',
                                  mr: 'घटनेची तारीख',
                                  hi: 'घटना की तिथि',
                                ),
                                isRequired: true,
                              ),
                              InkWell(
                                onTap: () async {
                                  final picked = await showThemedDatePicker(
                                    context: ctx,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          AppTranslations.formatDate(selectedDate, lang),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFDC2626)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Source / Reference',
                                  mr: 'स्रोत / पुरावा संदर्भ',
                                  hi: 'स्रोत / साक्ष्य संदर्भ',
                                ),
                              ),
                              TextField(
                                controller: sourceCtrl,
                                decoration: appInputDecoration(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. News clipping, video link',
                                    mr: 'उदा. बातमी, व्हिडिओ लिंक',
                                    hi: 'उदा. समाचार कतरन, वीडियो लिंक',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Incident Title & Severity side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Controversy Title',
                                  mr: 'प्रकरणाचे शीर्षक',
                                  hi: 'प्रकरण का शीर्षक',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: titleCtrl,
                                decoration: appInputDecoration(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Tender irregularities...',
                                    mr: 'उदा. बेकायदेशीर बांधकाम...',
                                    hi: 'उदा. निविदा अनियमितता...',
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
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Severity / Impact',
                                  mr: 'तीव्रता / प्रभाव',
                                  hi: 'गंभीरता / प्रभाव',
                                ),
                                isRequired: true,
                              ),
                              Row(
                                children: [
                                  _buildSeverityOption(
                                    'High',
                                    AppTranslations.pick(lang, en: 'High', mr: 'उच्च', hi: 'उच्च'),
                                    const Color(0xFFDC2626),
                                    severity,
                                    (val) => setModalState(() => severity = val),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildSeverityOption(
                                    'Medium',
                                    AppTranslations.pick(lang, en: 'Med', mr: 'मध्यम', hi: 'मध्यम'),
                                    const Color(0xFFD97706),
                                    severity,
                                    (val) => setModalState(() => severity = val),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildSeverityOption(
                                    'Low',
                                    AppTranslations.pick(lang, en: 'Low', mr: 'कमी', hi: 'कम'),
                                    const Color(0xFF0284C7),
                                    severity,
                                    (val) => setModalState(() => severity = val),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Description
                    AppFieldLabel(
                      label: AppTranslations.pick(
                        lang,
                        en: 'Controversy Details',
                        mr: 'प्रकरणाचा तपशील',
                        hi: 'प्रकरण का विवरण',
                      ),
                      isRequired: true,
                    ),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: appInputDecoration(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'Details, allegations, voter reaction, and strategy notes...',
                          mr: 'आरोप, स्थानिक मतदारांची प्रतिक्रिया व राजकीय रणनीती...',
                          hi: 'आरोप, स्थानीय मतदाता प्रतिक्रिया और राजनीतिक रणनीति...',
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
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          storyToEdit == null
                              ? AppTranslations.pick(
                                  lang,
                                  en: 'Record Incident',
                                  mr: 'प्रकरण नोंदवा',
                                  hi: 'प्रकरण दर्ज करें',
                                )
                              : AppTranslations.pick(
                                  lang,
                                  en: 'Save Changes',
                                  mr: 'बदल जतन करा',
                                  hi: 'बदलाव सहेजें',
                                ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Please enter title and details.',
                                    mr: 'कृपया शीर्षक आणि तपशील प्रविष्ट करा.',
                                    hi: 'कृपया शीर्षक और विवरण दर्ज करें।',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          final story = OppositionNegativeStoryModel(
                            id: storyToEdit?.id ?? 'story-${DateTime.now().millisecondsSinceEpoch}',
                            date: DateFormat('yyyy-MM-dd').format(selectedDate),
                            title: titleCtrl.text.trim(),
                            severity: severity,
                            source: sourceCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                          );

                          final repo = ref.read(oppositionRepoProvider);
                          if (storyToEdit == null) {
                            await repo.addNegativeStory(_member.id, story);
                          } else {
                            await repo.updateNegativeStory(_member.id, story);
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          _refreshMember();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  storyToEdit == null
                                      ? AppTranslations.pick(
                                          lang,
                                          en: 'Controversy recorded successfully!',
                                          mr: 'प्रकरण यशस्वीरित्या नोंदवले गेले!',
                                          hi: 'प्रकरण सफलतापूर्वक दर्ज किया गया!',
                                        )
                                      : AppTranslations.pick(
                                          lang,
                                          en: 'Controversy updated!',
                                          mr: 'तपशील अद्यतनित केले!',
                                          hi: 'विवरण अपडेट किए गए!',
                                        ),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityOption(String val, String label, Color color, String current, ValueChanged<String> onSelect) {
    final isSelected = current == val;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : const Color(0xFFCBD5E1)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ADD TEAM MEMBER TO CANDIDATE MODAL
  // ===========================================================================
  Future<void> _showAddTeamMemberModal() async {
    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(oppositionRepoProvider);
    final unassigned = repo.getUnassignedWorkers();
    final translatedMemberName = await DynamicTranslationService.translateOrRaw(
      _member.name,
      lang,
      isName: true,
    );
    if (!mounted) return;
    int activeTab = 0; // 0 = Link Existing, 1 = Quick Create
    String? selectedWorkerId = unassigned.isNotEmpty ? unassigned.first.id : null;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController(
      text: AppTranslations.pick(
        lang,
        en: 'Booth Cadre',
        mr: 'बूथ कार्यकर्ता',
        hi: 'बूथ कार्यकर्ता',
      ),
    );
    final areaCtrl = TextEditingController(text: _member.area ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              AppModalHeader(
                icon: Icons.group_add_rounded,
                title: AppTranslations.pick(
                  lang,
                  en: 'Add Cadre for $translatedMemberName',
                  mr: 'कार्यकर्ता जोडा ($translatedMemberName)',
                  hi: 'कार्यकर्ता जोड़ें ($translatedMemberName)',
                ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Link or create opposition cadre',
                  mr: 'विरोधी गटाचा कार्यकर्ता संबद्ध करा',
                  hi: 'विपक्षी गुट का कार्यकर्ता संबद्ध करें',
                ),
                onClose: () => Navigator.pop(ctx),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  children: [
                    // Tabs: Link Existing vs Create New
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
                              onTap: () => setModalState(() => activeTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: activeTab == 0 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: activeTab == 0 ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
                                ),
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Link Existing',
                                    mr: 'विद्यमान जोडा',
                                    hi: 'मौजूदा जोड़ें',
                                  ),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => activeTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: activeTab == 1 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: activeTab == 1 ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
                                ),
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Create New',
                                    mr: 'नवीन तयार करा',
                                    hi: 'नया बनाएँ',
                                  ),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (activeTab == 0) ...[
                      // Tab 0: Link Existing
                      if (unassigned.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'No unlinked cadre available.\nPlease use "Create New" tab.',
                                mr: 'कोणताही असंबद्ध कार्यकर्ता उपलब्ध नाही.\nकृपया "नवीन तयार करा" टॅब वापरा.',
                                hi: 'कोई असंबद्ध कार्यकर्ता उपलब्ध नहीं है।\nकृपया "नया बनाएँ" टैब का उपयोग करें।',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else ...[
                        AppDropdownFormField<String>(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Select Opposition Cadre',
                            mr: 'विरोधी कार्यकर्ता निवडा',
                            hi: 'विपक्षी कार्यकर्ता चुनें',
                          ),
                          isRequired: true,
                          value: selectedWorkerId,
                          isExpanded: true,
                          items: unassigned.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.id,
                              child: AppTranslatedText(
                                '${w.name} (${w.party} - ${w.role ?? w.area ?? "Cadre"})',
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedWorkerId = val);
                          },
                        ),
                        const SizedBox(height: 24),
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
                            icon: const Icon(Icons.link_rounded, size: 20),
                            label: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Link Cadre',
                                mr: 'कार्यकर्ता जोडा',
                                hi: 'कार्यकर्ता जोड़ें',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: selectedWorkerId == null
                                ? null
                                : () async {
                                    await repo.linkWorkerToCandidate(selectedWorkerId!, _member.id);
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                    _refreshMember();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppTranslations.pick(
                                              lang,
                                              en: 'Cadre linked to team successfully!',
                                              mr: 'कार्यकर्ता यशस्वीरित्या जोडला गेला!',
                                              hi: 'कार्यकर्ता सफलतापूर्वक टीम से जोड़ा गया!',
                                            ),
                                          ),
                                          backgroundColor: const Color(0xFF16A34A),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ] else ...[
                      // Tab 1: Create New Worker
                      // Full Name & Mobile Number side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Cadre Full Name',
                                    mr: 'पूर्ण नाव',
                                    hi: 'पूरा नाम',
                                  ),
                                  isRequired: true,
                                ),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Sachin Pawar',
                                      mr: 'उदा. सचिन पवार',
                                      hi: 'उदा. सचिन पवार',
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Mobile Number',
                                    mr: 'मोबाईल नंबर',
                                    hi: 'मोबाइल नंबर',
                                  ),
                                ),
                                TextField(
                                  controller: phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.formatDigits('98220xxxxx', lang),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Role & Work Area side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Role / Designation',
                                    mr: 'पद / हुद्दा',
                                    hi: 'पद / भूमिका',
                                  ),
                                ),
                                TextField(
                                  controller: roleCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Booth Cadre',
                                      mr: 'उदा. बूथ कार्यकर्ता',
                                      hi: 'उदा. बूथ कार्यकर्ता',
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Work Area',
                                    mr: 'कार्यक्षेत्र',
                                    hi: 'कार्यक्षेत्र',
                                  ),
                                ),
                                TextField(
                                  controller: areaCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Ward 12',
                                      mr: 'उदा. प्रभाग १२',
                                      hi: 'उदा. वार्ड १२',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

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
                            AppTranslations.pick(
                              lang,
                              en: 'Create Cadre',
                              mr: 'कार्यकर्ता तयार करा',
                              hi: 'कार्यकर्ता बनाएँ',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Please enter cadre name.',
                                      mr: 'कृपया कार्यकर्त्याचे नाव प्रविष्ट करा.',
                                      hi: 'कृपया कार्यकर्ता का नाम दर्ज करें।',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }

                            final normPhone = AppTranslations.normalizeAsciiDigits(phoneCtrl.text.trim());
                            final newWorker = OppositionMemberModel(
                              id: 'opp-wrk-${DateTime.now().millisecondsSinceEpoch}',
                              name: nameCtrl.text.trim(),
                              mobile: normPhone.isNotEmpty ? normPhone : null,
                              party: _member.party,
                              role: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : 'Cadre',
                              area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : _member.area,
                              isCandidate: false,
                              candidateId: _member.id,
                              createdAt: DateTime.now(),
                            );

                            await repo.addMember(newWorker);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            _refreshMember();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'New cadre created and linked successfully!',
                                      mr: 'नवीन कार्यकर्ता तयार करून यशस्वीरित्या जोडला!',
                                      hi: 'नया कार्यकर्ता बनाकर सफलतापूर्वक जोड़ा गया!',
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final partyColor = _getPartyColor(_member.party);
    final repo = ref.read(oppositionRepoProvider);
    final candidateTeam = _member.isCandidate ? repo.getCandidateTeam(_member.id) : <OppositionMemberModel>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: AppTranslatedText(
          _member.name,
          targetLanguage: lang,
          isName: true,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_member.mobile != null && _member.mobile!.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: Colors.white),
              onPressed: () => _makePhoneCall(_member.mobile),
              tooltip: AppTranslations.pick(lang, en: 'Call', mr: 'कॉल करा', hi: 'कॉल करें'),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
              onPressed: () => _openWhatsApp(_member.mobile),
              tooltip: AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सॲप', hi: 'व्हाट्सएप'),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMember,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. MEMBER PROFILE CARD
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _member.isCandidate ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: partyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: partyColor.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Icon(
                            _member.isCandidate ? Icons.campaign_rounded : Icons.person_outline_rounded,
                            color: partyColor,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name & Party
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppTranslatedText(
                                    _member.name,
                                    targetLanguage: lang,
                                    isName: true,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                if (_member.isCandidate)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0284C7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AppTranslatedText(
                              _member.role ??
                                  AppTranslations.pick(
                                    lang,
                                    en: _member.isCandidate ? 'Candidate' : 'Cadre',
                                    mr: _member.isCandidate ? 'उमेदवार' : 'कार्यकर्ता',
                                    hi: _member.isCandidate ? 'उम्मीदवार' : 'कार्यकर्ता',
                                  ),
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),

                            // Badges: Party & Type
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: partyColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: partyColor.withValues(alpha: 0.3)),
                                  ),
                                  child: AppTranslatedText(
                                    _member.partyFullLabelFor(lang),
                                    targetLanguage: lang,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: partyColor),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _member.isCandidate ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _member.typeLabel(lang),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _member.isCandidate ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Contact & Area Grid
                  Row(
                    children: [
                      if (_member.mobile != null)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  AppTranslations.formatDigits(_member.mobile!, lang),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_member.area != null)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: AppTranslatedText(
                                  AppTranslations.getAreaName(_member.area!, lang),
                                  targetLanguage: lang,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // If Worker and belongs to candidate
                  if (!_member.isCandidate && _member.candidateId != null && _member.candidateId!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded, size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Text(
                            '${AppTranslations.pick(lang, en: 'Candidate Team', mr: 'उमेदवाराची टीम', hi: 'उम्मीदवार की टीम')}: ',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                          ),
                          Expanded(
                            child: AppTranslatedText(
                              repo.getCandidateName(_member.candidateId!),
                              targetLanguage: lang,
                              isName: true,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Strongholds
                  if (_member.strongholds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Strongholds & Active Areas:',
                        mr: 'प्रभाव क्षेत्रे आणि सक्रिय परिसर:',
                        hi: 'गढ़ एवं सक्रिय क्षेत्र:',
                      ),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _member.strongholds.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: AppTranslatedText(
                            s,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // ==========================================
            // 2. IF CANDIDATE: ELECTION DOSSIER & TEAM
            // ==========================================
            if (_member.isCandidate) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.how_to_vote_rounded, size: 18, color: Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Election Candidacy Details',
                            mr: 'निवडणूक उमेदवारी तपशील',
                            hi: 'चुनाव उम्मीदवारी विवरण',
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Constituency / Ward',
                                  mr: 'मतदारसंघ / प्रभाग',
                                  hi: 'निर्वाचन क्षेत्र / वार्ड',
                                ),
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                              AppTranslatedText(
                                _member.constituency ??
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Ward 12 (Pune PMC)',
                                      mr: 'प्रभाग १२ (पुणे मनपा)',
                                      hi: 'वार्ड १२ (पुणे मनपा)',
                                    ),
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Opposing Candidate',
                                  mr: 'विरोधी उमेदवार',
                                  hi: 'प्रतिद्वंदी उम्मीदवार',
                                ),
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                              AppTranslatedText(
                                _member.opposingCandidate ??
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Sitting Corporator',
                                      mr: 'विद्यमान नगरसेवक',
                                      hi: 'वर्तमान पार्षद',
                                    ),
                                targetLanguage: lang,
                                isName: _member.opposingCandidate != null,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${AppTranslations.pick(lang, en: 'Candidacy Status', mr: 'उमेदवारी स्थिती', hi: 'उम्मीदवारी स्थिति')}: ',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCandidacyStatusColor(_member.candidacyStatus).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _member.candidacyStatusLabel(lang),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getCandidacyStatusColor(_member.candidacyStatus),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Candidate's Team
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.groups_outlined, size: 18, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${AppTranslations.pick(lang, en: 'Candidate Team / Cadre', mr: 'उमेदवाराची टीम / कार्यकर्ते', hi: 'उम्मीदवार की टीम / कार्यकर्ता')} (${AppTranslations.formatDigits('${candidateTeam.length}', lang)})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showAddTeamMemberModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 14, color: Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  AppTranslations.pick(lang, en: 'Add Cadre', mr: 'कार्यकर्ता जोडा', hi: 'कार्यकर्ता जोड़ें'),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (candidateTeam.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'No cadre linked to this candidate yet.\nUse "+ Add Cadre" button to link members.',
                            mr: 'या उमेदवाराशी अद्याप कोणताही कार्यकर्ता जोडलेला नाही.\nसदस्य जोडण्यासाठी "+ कार्यकर्ता जोडा" बटण वापरा.',
                            hi: 'इस उम्मीदवार से अभी तक कोई कार्यकर्ता नहीं जुड़ा है।\nसदस्यों को जोड़ने के लिए "+ कार्यकर्ता जोड़ें" बटन का उपयोग करें।',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      )
                    else ...[
                      Builder(
                        builder: (context) {
                          final pagedTeam = candidateTeam
                              .skip((_teamPage - 1) * _teamPageSize)
                              .take(_teamPageSize)
                              .toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pagedTeam.length,
                                separatorBuilder: (context, index) => const Divider(height: 12),
                                itemBuilder: (ctx, idx) {
                                  final worker = pagedTeam[idx];
                                  return Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.person, size: 18, color: Color(0xFF0284C7)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AppTranslatedText(
                                              worker.name,
                                              targetLanguage: lang,
                                              isName: true,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            ),
                                            AppTranslatedText(
                                              '${worker.role ?? "Cadre"} • ${worker.area ?? ""}',
                                              targetLanguage: lang,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                                        onPressed: () async {
                                          await repo.unlinkWorker(worker.id);
                                          _refreshMember();
                                        },
                                        tooltip: AppTranslations.pick(
                                          lang,
                                          en: 'Remove from Team',
                                          mr: 'टीममधून काढा',
                                          hi: 'टीम से हटाएँ',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              AppInlinePagination(
                                currentPage: _teamPage,
                                totalItems: candidateTeam.length,
                                pageSize: _teamPageSize,
                                onPageChanged: (p) => setState(() => _teamPage = p),
                                label: AppTranslations.pick(lang, en: 'members', mr: 'सदस्य', hi: 'सदस्य'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ==========================================
            // 3. INTERNAL STRATEGY & NOTES
            // ==========================================
            if (_member.notes != null && _member.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Notes & Internal Strategy',
                            mr: 'नोंदी आणि अंतर्गत रणनीती',
                            hi: 'टिप्पणियाँ और आंतरिक रणनीति',
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppTranslatedText(
                      _member.notes!,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],

            // ==========================================
            // 4. NEGATIVE STORIES & CONTROVERSIES SECTION
            // ==========================================
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${AppTranslations.pick(lang, en: 'Controversies & Issues', mr: 'वादग्रस्त प्रकरणे आणि मुद्दे', hi: 'विवाद और मुद्दे')} (${AppTranslations.formatDigits('${_member.negativeStories.length}', lang)})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showNegativeStoryModal(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 14, color: Color(0xFFDC2626)),
                              const SizedBox(width: 4),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Record Incident',
                                  mr: 'प्रकरण नोंदवा',
                                  hi: 'प्रकरण दर्ज करें',
                                ),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_member.negativeStories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No controversies or negative incidents recorded for this member yet.',
                          mr: 'या सदस्याबद्दल अद्याप कोणतेही वादग्रस्त प्रकरण नोंदवलेले नाही.',
                          hi: 'इस सदस्य के लिए अभी तक कोई विवाद या नकारात्मक घटना दर्ज नहीं की गई है।',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    )
                  else ...[
                    Builder(
                      builder: (context) {
                        final pagedStories = _member.negativeStories
                            .skip((_storyPage - 1) * _storyPageSize)
                            .take(_storyPageSize)
                            .toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pagedStories.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (ctx, idx) {
                                final story = pagedStories[idx];
                                final parsedStoryDate = DateTime.tryParse(story.date);
                                final storyDateText = parsedStoryDate != null
                                    ? AppTranslations.formatDate(parsedStoryDate, lang)
                                    : AppTranslations.formatDigits(story.date, lang);
                                Color badgeColor = const Color(0xFF64748B);
                                Color cardBg = const Color(0xFFF8FAFC);
                                if (story.severity == 'High') {
                                  badgeColor = const Color(0xFFDC2626);
                                  cardBg = const Color(0xFFFEF2F2);
                                } else if (story.severity == 'Medium') {
                                  badgeColor = const Color(0xFFD97706);
                                  cardBg = const Color(0xFFFFFBEB);
                                } else {
                                  badgeColor = const Color(0xFF0284C7);
                                  cardBg = const Color(0xFFF0F9FF);
                                }

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  storyDateText,
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  story.severityLabel(lang),
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                                onPressed: () => _showNegativeStoryModal(storyToEdit: story),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ'),
                                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                                                onPressed: () async {
                                                  await repo.deleteNegativeStory(_member.id, story.id);
                                                  _refreshMember();
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      AppTranslatedText(
                                        story.title,
                                        targetLanguage: lang,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 4),
                                      AppTranslatedText(
                                        story.description,
                                        targetLanguage: lang,
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                                      ),
                                      if (story.source.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.link_rounded, size: 13, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${AppTranslations.pick(lang, en: 'Source', mr: 'स्रोत', hi: 'स्रोत')}: ',
                                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                                            ),
                                            Expanded(
                                              child: story.source.trim().startsWith('http')
                                                  ? Text(
                                                      story.source,
                                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                                                      overflow: TextOverflow.ellipsis,
                                                    )
                                                  : AppTranslatedText(
                                                      story.source,
                                                      targetLanguage: lang,
                                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                            AppInlinePagination(
                              currentPage: _storyPage,
                              totalItems: _member.negativeStories.length,
                              pageSize: _storyPageSize,
                              onPageChanged: (p) => setState(() => _storyPage = p),
                              label: AppTranslations.pick(lang, en: 'stories', mr: 'प्रकरणे', hi: 'प्रकरण'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // ==========================================
            // 5. CAMPAIGN ACTIVITY LOG
            // ==========================================
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.timeline_rounded, size: 20, color: Color(0xFF0284C7)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${AppTranslations.pick(lang, en: 'Campaign Activities', mr: 'प्रचार उपक्रम', hi: 'प्रचार गतिविधियाँ')} (${AppTranslations.formatDigits('${_member.activities.length}', lang)})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showAddActivityModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 14, color: Color(0xFF0284C7)),
                              const SizedBox(width: 4),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Record Activity',
                                  mr: 'उपक्रम नोंदवा',
                                  hi: 'गतिविधि दर्ज करें',
                                ),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_member.activities.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No recent public campaign activities recorded.',
                          mr: 'अलीकडील कोणताही प्रचार उपक्रम नोंदवलेला नाही.',
                          hi: 'हाल की कोई जन प्रचार गतिविधि दर्ज नहीं की गई है।',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    )
                  else ...[
                    Builder(
                      builder: (context) {
                        final pagedActivities = _member.activities
                            .skip((_activityPage - 1) * _activityPageSize)
                            .take(_activityPageSize)
                            .toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pagedActivities.length,
                              separatorBuilder: (context, index) => const Divider(height: 16),
                              itemBuilder: (ctx, idx) {
                                final act = pagedActivities[idx];
                                final parsedActDate = DateTime.tryParse(act.date);
                                final actDateText = parsedActDate != null
                                    ? AppTranslations.formatDate(parsedActDate, lang)
                                    : AppTranslations.formatDigits(act.date, lang);
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date Bullet
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0284C7),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                actDateText,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                              ),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ'),
                                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                                                onPressed: () async {
                                                  await repo.deleteActivity(_member.id, act.id);
                                                  _refreshMember();
                                                },
                                              ),
                                            ],
                                          ),
                                          AppTranslatedText(
                                            act.title,
                                            targetLanguage: lang,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          ),
                                          if (act.location.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: AppTranslatedText(
                                                    act.location,
                                                    targetLanguage: lang,
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (act.description.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            AppTranslatedText(
                                              act.description,
                                              targetLanguage: lang,
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            AppInlinePagination(
                              currentPage: _activityPage,
                              totalItems: _member.activities.length,
                              pageSize: _activityPageSize,
                              onPageChanged: (p) => setState(() => _activityPage = p),
                              label: AppTranslations.pick(lang, en: 'activities', mr: 'उपक्रम', hi: 'गतिविधियाँ'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }
}

