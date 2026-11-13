import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/auth_provider.dart';

class TeamMemberProfileScreen extends ConsumerStatefulWidget {
  final TeamMemberModel member;

  const TeamMemberProfileScreen({super.key, required this.member});

  @override
  ConsumerState<TeamMemberProfileScreen> createState() => _TeamMemberProfileScreenState();
}

class _TeamMemberProfileScreenState extends ConsumerState<TeamMemberProfileScreen> {
  late TeamMemberModel _member;
  List<TeamTaskModel> _tasks = [];
  bool _isLoadingTasks = true;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoadingTasks = true);
    final repo = ref.read(teamRepoProvider);
    final tasks = await repo.getMemberTasks(_member.id);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });
    }
  }

  Future<void> _callMember() async {
    final url = Uri.parse('tel:+91${_member.mobile}');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  Future<void> _messageOnWhatsApp() async {
    final msg = Uri.encodeComponent(
      'Greetings ${_member.displayName},\n'
      'Contacting you from Ward 12 Corporator Office.',
    );
    final url = Uri.parse('https://wa.me/91${_member.mobile}?text=$msg');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _toggleTaskStatus(TeamTaskModel task) async {
    final newStatus = (task.status == 'Completed' || task.status == 'Resolved') ? 'In Progress' : 'Completed';
    final repo = ref.read(teamRepoProvider);
    await repo.updateTaskStatus(_member.id, task.id, newStatus);
    _loadTasks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'Completed' ? 'Task marked as completed!' : 'Task status updated'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    }
  }

  void _showAssignTaskModal() {
    final isMr = ref.read(isMarathiProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    String priority = 'Medium';
    DateTime dueDate = DateTime.now().add(const Duration(days: 2));

    Widget fieldLabel(String text, {bool isRequired = false}) {
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
        builder: (context, setModalState) {
          return Container(
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
                            child: const Icon(Icons.assignment_add, color: Color(0xFF0284C7), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMr ? 'नवीन काम सोपवा' : 'Assign New Task',
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${_member.displayName} (${_member.role})',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
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
                      // Task Title & Location side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'कामाचे नाव / शीर्षक' : 'Task Title', isRequired: true),
                                TextField(
                                  controller: titleCtrl,
                                  decoration: inputDec(
                                    hintText: isMr ? 'उदा. ड्रेनेज लाईन पाहणी' : 'e.g. Drainage inspection',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'स्थान / परिसर' : 'Location / Area'),
                                TextField(
                                  controller: locCtrl,
                                  decoration: inputDec(
                                    hintText: isMr ? 'उदा. शनिवार पेठ, लेन २' : 'e.g. Shaniwar Peth',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Priority & Due Date side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'प्राधान्य' : 'Priority'),
                                DropdownButtonFormField<String>(
                                  value: priority,
                                  decoration: inputDec(),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(value: 'Low', child: Text(isMr ? 'कमी (Low)' : 'Low')),
                                    DropdownMenuItem(value: 'Medium', child: Text(isMr ? 'मध्यम (Medium)' : 'Medium')),
                                    DropdownMenuItem(
                                      value: 'High',
                                      child: Text(
                                        isMr ? 'तातडीचे (High)' : 'High',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => priority = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'पूर्ण करण्याची तारीख' : 'Due Date'),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: dueDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 90)),
                                    );
                                    if (picked != null) setModalState(() => dueDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('dd MMM yyyy').format(dueDate),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

                      // Description
                      fieldLabel(isMr ? 'कामाचा तपशील / सूचना' : 'Description & Instructions'),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: inputDec(
                          hintText: isMr
                              ? 'कामाचा सविस्तर तपशील, नागरिकांची तक्रार किंवा विशेष सूचना...'
                              : 'Work details, citizen grievance or instructions...',
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
                            isMr ? 'काम सोपवा' : 'Assign Task',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () async {
                            if (titleCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMr
                                        ? 'कृपया कामाचे नाव प्रविष्ट करा.'
                                        : 'Please enter task title.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final newTask = TeamTaskModel(
                              id: 'tsk-${DateTime.now().millisecondsSinceEpoch}',
                              staffId: _member.id,
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                              priority: priority,
                              status: 'Pending',
                              dueDate: dueDate,
                              location: locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : _member.area,
                              createdAt: DateTime.now(),
                            );

                            final repo = ref.read(teamRepoProvider);
                            await repo.assignTask(_member.id, newTask);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            _loadTasks();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMr
                                        ? 'काम यशस्वीरित्या सोपवले गेले!'
                                        : 'Task assigned successfully!',
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color catColor = const Color(0xFF0284C7);
    Color catBg = const Color(0xFFE0F2FE);

    if (_member.category == 'Party') {
      catColor = const Color(0xFFD97706);
      catBg = const Color(0xFFFEF3C7);
    } else if (_member.category == 'Cooperative') {
      catColor = const Color(0xFF7C3AED);
      catBg = const Color(0xFFEDE9FE);
    }

    final completedTasks = _tasks.where((t) => t.status == 'Completed' || t.status == 'Resolved').length;
    final pendingTasks = _tasks.where((t) => t.status != 'Completed' && t.status != 'Resolved').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _member.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_member.categoryLabelMarathi} • ${_member.roleLabelMarathi}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 10.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            tooltip: 'Call',
            onPressed: _callMember,
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            tooltip: 'WhatsApp Message',
            onPressed: _messageOnWhatsApp,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Profile Header Card
          _buildProfileHeaderCard(catColor, catBg),
          const SizedBox(height: 14),

          // Quick Action Bar: Call, WhatsApp, Assign Task
          _buildQuickActionBar(),
          const SizedBox(height: 14),

          // Auto-Assign Keywords Card
          _buildKeywordsCard(),
          const SizedBox(height: 14),

          // Assigned Tasks Section
          _buildAssignedTasksSection(completedTasks, pendingTasks),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Assign Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAssignTaskModal,
      ),
    );
  }

  Widget _buildProfileHeaderCard(Color catColor, Color catBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catColor, catColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _member.displayName.isNotEmpty ? _member.displayName.substring(0, 1) : 'S',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _member.displayName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    if (_member.name != _member.displayName)
                      Text(_member.name, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: catBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: catColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            _member.categoryLabelMarathi,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: catColor),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _member.roleLabelMarathi,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
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

          // Detail Points Grid
          if (_member.partyWing != null && _member.partyWing!.isNotEmpty)
            _buildInfoRow(Icons.flag_rounded, 'Party Wing / Organization', '${_member.partyWing!} ${_member.pad != null ? "(${_member.pad})" : ""}'),
          if (_member.societyName != null && _member.societyName!.isNotEmpty)
            _buildInfoRow(Icons.apartment_rounded, 'Organization / Department', _member.societyName!),
          _buildInfoRow(Icons.location_on_outlined, 'Work Area', _member.area ?? 'Ward 12 Entire Area'),
          _buildInfoRow(Icons.phone_iphone_rounded, 'Mobile Number', '+91 ${_member.mobile}'),
          if (_member.email != null && _member.email!.isNotEmpty)
            _buildInfoRow(Icons.email_outlined, 'Email', _member.email!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF0284C7)),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.phone, size: 16, color: Colors.white),
            label: const Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _callMember,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
            label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _messageOnWhatsApp,
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_fix_high_rounded, size: 17, color: Color(0xFF0284C7)),
              SizedBox(width: 6),
              Text(
                'Auto-Assign Rules',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'When citizen complaints contain these keywords, tasks are routed here automatically:',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          if (_member.keywords.isEmpty)
            Text('No specific keywords assigned (General tasks).', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _member.keywords.map((k) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    k,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignedTasksSection(int completed, int pending) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.task_alt_rounded, size: 18, color: Color(0xFF0284C7)),
                  SizedBox(width: 6),
                  Text(
                    'Assigned Tasks',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: Text('$completed Completed', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                    child: Text('$pending In Progress', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_isLoadingTasks)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 36, color: Colors.grey.shade300),
                    const SizedBox(height: 6),
                    Text('No tasks assigned yet.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              separatorBuilder: (context, index) => const Divider(height: 14),
              itemBuilder: (ctx, idx) {
                final t = _tasks[idx];
                final isDone = t.status == 'Completed' || t.status == 'Resolved';

                Color prioColor = Colors.grey;
                if (t.priority == 'High') {
                  prioColor = Colors.redAccent;
                } else if (t.priority == 'Medium') {
                  prioColor = Colors.orange;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox toggle
                    Checkbox(
                      value: isDone,
                      activeColor: const Color(0xFF16A34A),
                      onChanged: (_) => _toggleTaskStatus(t),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey : const Color(0xFF0F172A),
                            ),
                          ),
                          if (t.description != null && t.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              t.description!,
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: prioColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.priorityLabelMarathi,
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: prioColor),
                                ),
                              ),
                              if (t.dueDate != null) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                                const SizedBox(width: 3),
                                Text(
                                  DateFormat('dd MMM').format(t.dueDate!),
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                ),
                              ],
                              if (t.location != null) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.location_on_outlined, size: 11, color: Colors.grey.shade500),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    t.location!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
