import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';

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
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    String priority = 'Medium';
    DateTime dueDate = DateTime.now().add(const Duration(days: 2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
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
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_add, color: Color(0xFF0284C7), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assign New Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Assign task to ${_member.displayName}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Task Title
                    const Text('Task Title*', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Shaniwar Peth drainage inspection',
                        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    const Text('Description', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Work details, citizen grievance or instructions...',
                        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Priority & Due Date Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Priority', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: priority,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'Low', child: Text('Low', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Medium', child: Text('Medium', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'High', child: Text('High', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => priority = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due Date', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
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
                    const SizedBox(height: 12),

                    // Location
                    const Text('Location / Area', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: locCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Shaniwar Peth, Lane 2',
                        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) return;
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
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _loadTasks();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task assigned successfully!'), backgroundColor: Color(0xFF16A34A)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Assign Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
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
