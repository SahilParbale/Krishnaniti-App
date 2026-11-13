import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/opposition_model.dart';
import '../../../data/repositories/opposition_repository.dart';
import '../../providers/auth_provider.dart';

class OppositionDetailScreen extends ConsumerStatefulWidget {
  final OppositionMemberModel member;

  const OppositionDetailScreen({super.key, required this.member});

  @override
  ConsumerState<OppositionDetailScreen> createState() => _OppositionDetailScreenState();
}

class _OppositionDetailScreenState extends ConsumerState<OppositionDetailScreen> {
  late OppositionMemberModel _member;

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
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
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

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
          children: isRequired
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  InputDecoration _inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
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

  // ===========================================================================
  // LOG CAMPAIGN ACTIVITY MODAL
  // ===========================================================================
  void _showAddActivityModal() {
    final isMr = ref.read(isMarathiProvider);
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
          height: MediaQuery.of(context).size.height * 0.85,
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
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_note_rounded,
                            color: Color(0xFF0284C7),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isMr ? 'प्रचार उपक्रमाची नोंद करा' : 'Record Campaign Activity',
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
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
                              _fieldLabel(isMr ? 'तारीख' : 'Activity Date', isRequired: true),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
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
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(selectedDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
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
                              _fieldLabel(isMr ? 'उपक्रमाचे नाव / शीर्षक' : 'Activity Title', isRequired: true),
                              TextField(
                                controller: titleCtrl,
                                decoration: _inputDec(
                                  hintText: isMr ? 'उदा. जनआक्रोश मोर्चा, शिबीर' : 'e.g. Citizen Rights March',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Location / Vicinity
                    _fieldLabel(isMr ? 'स्थान / परिसर' : 'Location / Vicinity'),
                    TextField(
                      controller: locCtrl,
                      decoration: _inputDec(
                        hintText: isMr ? 'उदा. सेक्टर ३ चौक, मुख्य रस्ता' : 'e.g. Sector 3 Chowk',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description & Notes
                    _fieldLabel(isMr ? 'तपशील व निरीक्षणे' : 'Activity Description & Notes'),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: _inputDec(
                        hintText: isMr ? 'उपक्रमाचे स्वरूप, प्रमुख मागण्या व प्रभाव...' : 'Nature of activity, key demands, and political impact...',
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
                          isMr ? 'उपक्रम जतन करा' : 'Save Activity',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isMr
                                      ? 'कृपया उपक्रमाचे नाव प्रविष्ट करा.'
                                      : 'Please enter activity title.',
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
                                  isMr
                                      ? 'उपक्रम यशस्वीरित्या नोंदवला गेला!'
                                      : 'Activity recorded successfully!',
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
  // ADD / EDIT CONTROVERSY / NEGATIVE STORY MODAL
  // ===========================================================================
  void _showNegativeStoryModal({OppositionNegativeStoryModel? storyToEdit}) {
    final isMr = ref.read(isMarathiProvider);
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
          height: MediaQuery.of(context).size.height * 0.90,
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
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          storyToEdit == null
                              ? (isMr ? 'वादग्रस्त घटना / प्रकरण नोंदवा' : 'Record Controversy / Incident')
                              : (isMr ? 'वादग्रस्त प्रकरण संपादित करा' : 'Edit Controversy / Incident'),
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
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
                              _fieldLabel(isMr ? 'घटनेची तारीख' : 'Incident Date', isRequired: true),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
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
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(selectedDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
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
                              _fieldLabel(isMr ? 'स्रोत / पुरावा संदर्भ' : 'Source / Reference'),
                              TextField(
                                controller: sourceCtrl,
                                decoration: _inputDec(
                                  hintText: isMr ? 'उदा. बातमी, व्हिडिओ लिंक' : 'e.g. News clipping, video link',
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
                              _fieldLabel(isMr ? 'प्रकरणाचे शीर्षक' : 'Controversy Title', isRequired: true),
                              TextField(
                                controller: titleCtrl,
                                decoration: _inputDec(
                                  hintText: isMr ? 'उदा. बेकायदेशीर बांधकाम...' : 'e.g. Tender irregularities...',
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
                              _fieldLabel(isMr ? 'तीव्रता / प्रभाव' : 'Severity / Impact', isRequired: true),
                              Row(
                                children: [
                                  _buildSeverityOption(
                                    isMr ? 'उच्च' : 'High',
                                    'High',
                                    const Color(0xFFDC2626),
                                    severity,
                                    (val) => setModalState(() => severity = val),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildSeverityOption(
                                    isMr ? 'मध्यम' : 'Med',
                                    'Medium',
                                    const Color(0xFFD97706),
                                    severity,
                                    (val) => setModalState(() => severity = val),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildSeverityOption(
                                    isMr ? 'कमी' : 'Low',
                                    'Low',
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
                    _fieldLabel(isMr ? 'प्रकरणाचा तपशील' : 'Controversy Details', isRequired: true),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: _inputDec(
                        hintText: isMr ? 'आरोप, स्थानिक मतदारांची प्रतिक्रिया व राजकीय रणनीती...' : 'Details, allegations, voter reaction, and strategy notes...',
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
                              ? (isMr ? 'प्रकरण नोंदवा' : 'Record Incident')
                              : (isMr ? 'बदल जतन करा' : 'Save Changes'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isMr
                                      ? 'कृपया शीर्षक आणि तपशील प्रविष्ट करा.'
                                      : 'Please enter title and details.',
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
                                      ? (isMr ? 'प्रकरण यशस्वीरित्या नोंदवले गेले!' : 'Controversy recorded successfully!')
                                      : (isMr ? 'तपशील अद्यतनित केले!' : 'Controversy updated!'),
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
  void _showAddTeamMemberModal() {
    final isMr = ref.read(isMarathiProvider);
    final repo = ref.read(oppositionRepoProvider);
    final unassigned = repo.getUnassignedWorkers();
    int activeTab = 0; // 0 = Link Existing, 1 = Quick Create
    String? selectedWorkerId = unassigned.isNotEmpty ? unassigned.first.id : null;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Booth Cadre');
    final areaCtrl = TextEditingController(text: _member.area ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.group_add_rounded,
                            color: Color(0xFF0284C7),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isMr ? 'कार्यकर्ता जोडा (${_member.name})' : 'Add Cadre for ${_member.name}',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
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
                                  isMr ? 'विद्यमान जोडा' : 'Link Existing',
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
                                  isMr ? 'नवीन तयार करा' : 'Create New',
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
                              isMr
                                  ? 'कोणताही असंबद्ध कार्यकर्ता उपलब्ध नाही.\nकृपया "नवीन तयार करा" टॅब वापरा.'
                                  : 'No unlinked cadre available.\nPlease use "Create New" tab.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else ...[
                        _fieldLabel(isMr ? 'विरोधी कार्यकर्ता निवडा' : 'Select Opposition Cadre', isRequired: true),
                        DropdownButtonFormField<String>(
                          value: selectedWorkerId,
                          decoration: _inputDec(),
                          isExpanded: true,
                          items: unassigned.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.id,
                              child: Text(
                                '${w.name} (${w.party} - ${w.role ?? w.area ?? "Cadre"})',
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
                              isMr ? 'कार्यकर्ता जोडा' : 'Link Cadre',
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
                                            isMr
                                                ? 'कार्यकर्ता यशस्वीरित्या जोडला गेला!'
                                                : 'Cadre linked to team successfully!',
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
                                _fieldLabel(isMr ? 'पूर्ण नाव' : 'Cadre Full Name', isRequired: true),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: _inputDec(
                                    hintText: isMr ? 'उदा. सचिन पवार' : 'e.g. Sachin Pawar',
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
                                _fieldLabel(isMr ? 'मोबाईल नंबर' : 'Mobile Number'),
                                TextField(
                                  controller: phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDec(
                                    hintText: '98220xxxxx',
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
                                _fieldLabel(isMr ? 'पद / हुद्दा' : 'Role / Designation'),
                                TextField(
                                  controller: roleCtrl,
                                  decoration: _inputDec(
                                    hintText: isMr ? 'उदा. बूथ कार्यकर्ता' : 'e.g. Booth Cadre',
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
                                _fieldLabel(isMr ? 'कार्यक्षेत्र' : 'Work Area'),
                                TextField(
                                  controller: areaCtrl,
                                  decoration: _inputDec(
                                    hintText: isMr ? 'उदा. प्रभाग १२' : 'e.g. Ward 12',
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
                            isMr ? 'कार्यकर्ता तयार करा' : 'Create Cadre',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMr
                                        ? 'कृपया कार्यकर्त्याचे नाव प्रविष्ट करा.'
                                        : 'Please enter cadre name.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final newWorker = OppositionMemberModel(
                              id: 'opp-wrk-${DateTime.now().millisecondsSinceEpoch}',
                              name: nameCtrl.text.trim(),
                              mobile: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
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
                                    isMr
                                        ? 'नवीन कार्यकर्ता तयार करून यशस्वीरित्या जोडला!'
                                        : 'New cadre created and linked successfully!',
                                  ),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
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

  @override
  Widget build(BuildContext context) {
    final partyColor = _getPartyColor(_member.party);
    final repo = ref.read(oppositionRepoProvider);
    final candidateTeam = _member.isCandidate ? repo.getCandidateTeam(_member.id) : <OppositionMemberModel>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _member.name,
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
              tooltip: 'Call',
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
              onPressed: () => _openWhatsApp(_member.mobile),
              tooltip: 'WhatsApp',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
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
                                  child: Text(
                                    _member.name,
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
                            Text(
                              _member.role ?? (_member.isCandidate ? 'Candidate' : 'Cadre'),
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
                                  child: Text(
                                    _member.partyFullLabel,
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
                                    _member.typeLabelMarathi,
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
                                  _member.mobile!,
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
                                child: Text(
                                  _member.area!,
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
                          const Text('Candidate Team: ', style: TextStyle(fontSize: 11.5, color: Color(0xFF166534))),
                          Text(
                            repo.getCandidateName(_member.candidateId!),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Strongholds
                  if (_member.strongholds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Strongholds & Active Areas:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
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
                          child: Text(
                            s,
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
                    const Row(
                      children: [
                        Icon(Icons.how_to_vote_rounded, size: 18, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Election Candidacy Details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
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
                              const Text('Constituency / Ward', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                              Text(
                                _member.constituency ?? 'Ward 12 (Pune PMC)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Opposing Candidate', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                              Text(
                                _member.opposingCandidate ?? 'Sitting Corporator',
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
                        const Text('Candidacy Status: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCandidacyStatusColor(_member.candidacyStatus).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _member.candidacyStatusLabelMarathi,
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
                        Row(
                          children: [
                            const Icon(Icons.groups_outlined, size: 18, color: Color(0xFF0284C7)),
                            const SizedBox(width: 6),
                            Text(
                              'Candidate Team / Cadre (${candidateTeam.length})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _showAddTeamMemberModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, size: 14, color: Color(0xFF0284C7)),
                                SizedBox(width: 4),
                                Text(
                                  'Add Cadre',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
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
                        child: const Text(
                          'No cadre linked to this candidate yet.\nUse "+ Add Cadre" button to link members.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: candidateTeam.length,
                        separatorBuilder: (context, index) => const Divider(height: 12),
                        itemBuilder: (ctx, idx) {
                          final worker = candidateTeam[idx];
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
                                    Text(
                                      worker.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      '${worker.role ?? "Cadre"} • ${worker.area ?? ""}',
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
                                tooltip: 'Remove from Team',
                              ),
                            ],
                          );
                        },
                      ),
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
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Text(
                          'Notes & Internal Strategy',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _member.notes!,
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
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFDC2626)),
                          const SizedBox(width: 6),
                          Text(
                            'Controversies & Issues (${_member.negativeStories.length})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showNegativeStoryModal(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, size: 14, color: Color(0xFFDC2626)),
                              SizedBox(width: 4),
                              Text(
                                'Record Incident',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
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
                      child: const Text(
                        'No controversies or negative incidents recorded for this member yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _member.negativeStories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final story = _member.negativeStories[idx];
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
                                          story.date,
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
                                          story.severityLabelMarathi,
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
                                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                        onPressed: () => _showNegativeStoryModal(storyToEdit: story),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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
                              Text(
                                story.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                story.description,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                              ),
                              if (story.source.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.link_rounded, size: 13, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Source: ${story.source}',
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
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
                      Row(
                        children: [
                          const Icon(Icons.timeline_rounded, size: 20, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Text(
                            'Campaign Activities (${_member.activities.length})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _showAddActivityModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, size: 14, color: Color(0xFF0284C7)),
                              SizedBox(width: 4),
                              Text(
                                'Record Activity',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
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
                      child: const Text(
                        'No recent public campaign activities recorded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _member.activities.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (ctx, idx) {
                        final act = _member.activities[idx];
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
                                        act.date,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                                        onPressed: () async {
                                          await repo.deleteActivity(_member.id, act.id);
                                          _refreshMember();
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    act.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  if (act.location.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(act.location, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ],
                                  if (act.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      act.description,
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
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

