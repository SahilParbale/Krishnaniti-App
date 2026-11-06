import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/opposition_model.dart';
import '../../../data/repositories/opposition_repository.dart';

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

  // ===========================================================================
  // LOG CAMPAIGN ACTIVITY MODAL
  // ===========================================================================
  void _showAddActivityModal() {
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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.event_note_rounded, color: Color(0xFF0284C7), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'मोहीम उपक्रम नोंदवा',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Picker Button
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'तारीख: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'उपक्रमाचे नाव / शीर्षक *',
                    hintText: 'उदा. नागरी हक्क मोर्चा, आरोग्य शिबिर',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                TextField(
                  controller: locCtrl,
                  decoration: InputDecoration(
                    labelText: 'ठिकाण / परिसर',
                    hintText: 'उदा. सेक्टर ३ चौक',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'उपक्रमाचा सविस्तर तपशील',
                    hintText: 'उपक्रमाचे स्वरूप, प्रमुख मागण्या आणि राजकीय प्रभाव...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('कृपया उपक्रमाचे नाव प्रविष्ट करा.')),
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
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _refreshMember();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('उपक्रम यशस्वीरित्या नोंदवला गेला!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('उपक्रम जतन करा', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ADD / EDIT CONTROVERSY / NEGATIVE STORY MODAL
  // ===========================================================================
  void _showNegativeStoryModal({OppositionNegativeStoryModel? storyToEdit}) {
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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      storyToEdit == null ? 'नकारात्मक किस्सा / वाद नोंदवा' : 'नकारात्मक किस्सा संपादित करा',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Picker Button
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'घटनेची तारीख: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFDC2626)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'किस्सा / वादाचे शीर्षक *',
                    hintText: 'उदा. अनधिकृत बांधकाम, निविदा गैरव्यवहार आरोप',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Severity Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'तीव्रता / राजकीय प्रभाव',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildSeverityOption('High', 'तीव्र (High)', const Color(0xFFDC2626), severity, (val) => setModalState(() => severity = val)),
                        const SizedBox(width: 8),
                        _buildSeverityOption('Medium', 'मध्यम (Med)', const Color(0xFFD97706), severity, (val) => setModalState(() => severity = val)),
                        const SizedBox(width: 8),
                        _buildSeverityOption('Low', 'सौम्य (Low)', const Color(0xFF0284C7), severity, (val) => setModalState(() => severity = val)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Source
                TextField(
                  controller: sourceCtrl,
                  decoration: InputDecoration(
                    labelText: 'स्रोत / पुरावा संदर्भ',
                    hintText: 'उदा. वृत्तपत्र बातमी, व्हिडिओ लिंक किंवा पोलीस तक्रार',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'वादाचा सविस्तर तपशील *',
                    hintText: 'घटनेचे स्वरूप, आरोप, मतदारांची प्रतिक्रिया व व्यूहात्मक माहिती...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('कृपया शीर्षक आणि तपशील प्रविष्ट करा.')),
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

                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _refreshMember();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(storyToEdit == null ? 'नकारात्मक किस्सा नोंदवला गेला!' : 'किस्सा अद्ययावत केला!'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      storyToEdit == null ? 'किस्सा नोंदवा' : 'बदल जतन करा',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
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
    final repo = ref.read(oppositionRepoProvider);
    final unassigned = repo.getUnassignedWorkers();
    int activeTab = 0; // 0 = Link Existing, 1 = Quick Create
    String? selectedWorkerId = unassigned.isNotEmpty ? unassigned.first.id : null;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'बूथ कार्यकर्ता');
    final areaCtrl = TextEditingController(text: _member.area ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.group_add_rounded, color: Color(0xFF0284C7), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_member.name} साठी कार्यकर्ता जोडा',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

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
                            child: const Text('हयात असलेला जोडा', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                            child: const Text('नवीन तयार करा', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                      child: const Center(
                        child: Text(
                          'सध्या जोडण्यासारखे कोणतेही स्वतंत्र कार्यकर्ते उपलब्ध नाहीत.\nकृपया "नवीन तयार करा" टॅब वापरा.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else ...[
                    const Text('विरोधी कार्यकर्ता निवडा:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedWorkerId,
                          isExpanded: true,
                          items: unassigned.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.id,
                              child: Text(
                                '${w.name} (${w.party} - ${w.role ?? w.area ?? "कार्यकर्ता"})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedWorkerId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedWorkerId == null
                            ? null
                            : () async {
                                await repo.linkWorkerToCandidate(selectedWorkerId!, _member.id);
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                _refreshMember();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('कार्यकर्ता यशस्वीरित्या टीमशी जोडला!'), backgroundColor: Color(0xFF16A34A)),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('कार्यकर्ता जोडा', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ] else ...[
                  // Tab 1: Create New Worker
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'कार्यकर्त्याचे पूर्ण नाव *',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'मोबाईल क्रमांक',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: roleCtrl,
                    decoration: InputDecoration(
                      labelText: 'पद / भूमिका',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: areaCtrl,
                    decoration: InputDecoration(
                      labelText: 'कार्यक्षेत्र',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('कृपया कार्यकर्त्याचे नाव प्रविष्ट करा.')),
                          );
                          return;
                        }

                        final newWorker = OppositionMemberModel(
                          id: 'opp-wrk-${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text.trim(),
                          mobile: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                          party: _member.party,
                          role: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : 'कार्यकर्ता',
                          area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : _member.area,
                          isCandidate: false,
                          candidateId: _member.id,
                          createdAt: DateTime.now(),
                        );

                        await repo.addMember(newWorker);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _refreshMember();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('नवीन कार्यकर्ता यशस्वीरीत्या तयार करून जोडला!'), backgroundColor: Color(0xFF16A34A)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('कार्यकर्ता तयार करा', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
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
              tooltip: 'कॉल करा',
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
              onPressed: () => _openWhatsApp(_member.mobile),
              tooltip: 'व्हॉट्सॲप',
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
                              _member.role ?? (_member.isCandidate ? 'उमेदवार' : 'कार्यकर्ता'),
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
                          const Text('उमेदवाराचे सदस्य: ', style: TextStyle(fontSize: 11.5, color: Color(0xFF166534))),
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
                      'बालेकिल्ले / अत्यंत सक्रिय क्षेत्रे:',
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
                          'निवडणूक उमेदवारी माहिती',
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
                              const Text('मतदारसंघ / प्रभाग', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                              Text(
                                _member.constituency ?? 'प्रभाग क्र. १२ (पुणे मनपा)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('प्रतिस्पर्धी', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                              Text(
                                _member.opposingCandidate ?? 'विद्यमान नगरसेवक',
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
                        const Text('उमेदवारी स्थिती: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                              'उमेदवाराची टीम / सदस्य (${candidateTeam.length})',
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
                                  'कार्यकर्ता जोडा',
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
                          'या उमेदवारासाठी अद्याप कोणतेही सदस्य जोडलेले नाहीत.\n"+ कार्यकर्ता जोडा" बटण वापरून सदस्य जोडा.',
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
                                      '${worker.role ?? "कार्यकर्ता"} • ${worker.area ?? ""}',
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
                                tooltip: 'टीममधून काढा',
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
                          'तपशील आणि अंतर्गत व्यूहरचना (Notes & Strategy)',
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
                            'नकारात्मक किस्से व वाद (${_member.negativeStories.length})',
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
                                'किस्सा नोंदवा',
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
                        'या सदस्यासाठी अद्याप कोणतेही नकारात्मक किस्से किंवा वाद नोंदवलेले नाहीत.',
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
                                        'संदर्भ: ${story.source}',
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
                            'मोहीम उपक्रम नोंद (${_member.activities.length})',
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
                                'उपक्रम नोंदवा',
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
                        'नुकत्याच नोंदवलेल्या कोणत्याही सार्वजनिक उपक्रम नाहीत.',
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

