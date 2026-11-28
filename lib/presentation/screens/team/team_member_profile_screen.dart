import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pagination_bar.dart';

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
  int _taskPage = 1;
  static const int _taskPageSize = 5;

  int get _totalTaskPages {
    final count = _tasks.length;
    return (count / _taskPageSize).ceil() < 1 ? 1 : (count / _taskPageSize).ceil();
  }

  List<TeamTaskModel> get _pagedTasks {
    final startIndex = (_taskPage - 1) * _taskPageSize;
    if (startIndex >= _tasks.length) return [];
    final endIndex = min(startIndex + _taskPageSize, _tasks.length);
    return _tasks.sublist(startIndex, endIndex);
  }

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
        _taskPage = 1;
      });
    }
  }

  Future<void> _callMember() async {
    final clean = AppTranslations.normalizeAsciiDigits(_member.mobile).replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:+91$clean');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  Future<void> _messageOnWhatsApp(String lang) async {
    final tName = await DynamicTranslationService.translateOrRaw(
      _member.displayNameFor(lang),
      lang,
      isName: true,
    );
    final body = AppTranslations.pick(
      lang,
      en: 'Greetings $tName,\nContacting you from Ward 12 Corporator Office.',
      mr: 'नमस्कार $tName,\nप्रभाग १२ नगरसेवक कार्यालयातून संपर्क साधत आहोत.',
      hi: 'नमस्ते $tName,\nवार्ड १२ नगरसेवक कार्यालय से संपर्क कर रहे हैं।',
    );
    final clean = AppTranslations.normalizeAsciiDigits(_member.mobile).replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse('https://wa.me/91$clean?text=${Uri.encodeComponent(body)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _toggleTaskStatus(TeamTaskModel task, String lang) async {
    final newStatus = (task.status == 'Completed' || task.status == 'Resolved') ? 'In Progress' : 'Completed';
    final repo = ref.read(teamRepoProvider);
    await repo.updateTaskStatus(_member.id, task.id, newStatus);
    _loadTasks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Completed'
                ? AppTranslations.pick(
                    lang,
                    en: 'Task marked as completed!',
                    mr: 'काम पूर्ण म्हणून नोंदवले!',
                    hi: 'कार्य पूर्ण के रूप में चिह्नित!',
                  )
                : AppTranslations.pick(
                    lang,
                    en: 'Task status updated',
                    mr: 'कामाची स्थिती अद्यतनित केली',
                    hi: 'कार्य स्थिति अपडेट की गई',
                  ),
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    }
  }

  void _showAssignTaskModal() {
    final lang = ref.read(appLanguageProvider);
    final tMemberName = DynamicTranslationService.getCachedTranslation(
          _member.displayNameFor(lang),
          lang,
          isName: true,
        ) ??
        _member.displayNameFor(lang);
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
          return Container(
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
                  icon: Icons.assignment_add,
                  title: AppTranslations.pick(
                    lang,
                    en: 'Assign New Task',
                    mr: 'नवीन काम सोपवा',
                    hi: 'नया कार्य सौंपें',
                  ),
                  subtitle: '$tMemberName (${_member.roleLabel(lang)})',
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
                      // Task Title & Location side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Task Title',
                                    mr: 'कामाचे नाव / शीर्षक',
                                    hi: 'कार्य का शीर्षक',
                                  ),
                                  isRequired: true,
                                ),
                                TextField(
                                  controller: titleCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Drainage inspection',
                                      mr: 'उदा. ड्रेनेज लाईन पाहणी',
                                      hi: 'उदा. ड्रेनेज लाइन निरीक्षण',
                                    ),
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Location / Area',
                                    mr: 'स्थान / परिसर',
                                    hi: 'स्थान / क्षेत्र',
                                  ),
                                ),
                                TextField(
                                  controller: locCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Shaniwar Peth',
                                      mr: 'उदा. शनिवार पेठ, लेन २',
                                      hi: 'उदा. शनिवार पेठ, गली २',
                                    ),
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
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(lang, en: 'Priority', mr: 'प्राधान्य', hi: 'प्राथमिकता'),
                                  value: priority,
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Low',
                                      child: Text(AppTranslations.pick(lang, en: 'Low', mr: 'सामान्य', hi: 'सामान्य')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Medium',
                                      child: Text(AppTranslations.pick(lang, en: 'Medium', mr: 'मध्यम', hi: 'मध्यम')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'High',
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'High', mr: 'तातडीचे', hi: 'तत्काल'),
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Due Date',
                                    mr: 'पूर्ण करण्याची तारीख',
                                    hi: 'नियत तिथि',
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showThemedDatePicker(
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
                                          AppTranslations.formatDate(dueDate, lang, pattern: 'dd MMM yyyy'),
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
                      AppFieldLabel(
                        label: AppTranslations.pick(
                          lang,
                          en: 'Description & Instructions',
                          mr: 'कामाचा तपशील / सूचना',
                          hi: 'विवरण और निर्देश',
                        ),
                      ),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: appInputDecoration(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'Work details, citizen grievance or instructions...',
                            mr: 'कामाचा सविस्तर तपशील, नागरिकांची तक्रार किंवा विशेष सूचना...',
                            hi: 'कार्य विवरण, नागरिक शिकायत या विशेष निर्देश...',
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
                            AppTranslations.pick(lang, en: 'Assign Task', mr: 'काम सोपवा', hi: 'कार्य सौंपें'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () async {
                            if (titleCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Please enter task title.',
                                      mr: 'कृपया कामाचे नाव प्रविष्ट करा.',
                                      hi: 'कृपया कार्य का शीर्षक दर्ज करें।',
                                    ),
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
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Task assigned successfully!',
                                      mr: 'काम यशस्वीरित्या सोपवले गेले!',
                                      hi: 'कार्य सफलतापूर्वक सौंपा गया!',
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
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
          tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'पीछे'),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTranslatedText(
              _member.displayNameFor(lang),
              targetLanguage: lang,
              isName: true,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            AppTranslatedText(
              '${_member.categoryLabel(lang)} • ${_member.roleLabel(lang)}',
              targetLanguage: lang,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 10.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            tooltip: AppTranslations.pick(lang, en: 'Call', mr: 'कॉल', hi: 'कॉल'),
            onPressed: _callMember,
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(lang, en: 'WhatsApp Message', mr: 'व्हॉट्सअॅप संदेश', hi: 'व्हाट्सऐप संदेश'),
            onPressed: () => _messageOnWhatsApp(lang),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Profile Header Card
          _buildProfileHeaderCard(catColor, catBg, lang),
          const SizedBox(height: 14),

          // Quick Action Bar: Call, WhatsApp, Assign Task
          _buildQuickActionBar(lang),
          const SizedBox(height: 14),

          // Auto-Assign Keywords Card
          _buildKeywordsCard(lang),
          const SizedBox(height: 14),

          // Assigned Tasks Section
          _buildAssignedTasksSection(completedTasks, pendingTasks, lang),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: Text(
          AppTranslations.pick(lang, en: 'Assign Task', mr: 'काम सोपवा', hi: 'कार्य सौंपें'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _showAssignTaskModal,
      ),
    );
  }

  Widget _buildProfileHeaderCard(Color catColor, Color catBg, String lang) {
    final displayName = _member.displayNameFor(lang);
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
                    displayName.isNotEmpty ? displayName.substring(0, 1) : 'S',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTranslatedText(
                      displayName,
                      targetLanguage: lang,
                      isName: true,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: catBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: catColor.withOpacity(0.3)),
                          ),
                          child: AppTranslatedText(
                            _member.categoryLabel(lang),
                            targetLanguage: lang,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: catColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppTranslatedText(
                            _member.roleLabel(lang),
                            targetLanguage: lang,
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
            _buildInfoRow(
              Icons.flag_rounded,
              AppTranslations.pick(lang, en: 'Party Wing / Organization', mr: 'पक्ष विभाग / संघटना', hi: 'पार्टी प्रकोष्ठ / संगठन'),
              '${_member.partyWing!} ${_member.pad != null ? "(${_member.pad})" : ""}',
              lang: lang,
              translateValue: true,
            ),
          if (_member.societyName != null && _member.societyName!.isNotEmpty)
            _buildInfoRow(
              Icons.apartment_rounded,
              AppTranslations.pick(lang, en: 'Organization / Department', mr: 'संस्था / विभाग', hi: 'संगठन / विभाग'),
              _member.societyName!,
              lang: lang,
              translateValue: true,
            ),
          _buildInfoRow(
            Icons.location_on_outlined,
            AppTranslations.pick(lang, en: 'Work Area', mr: 'कार्यक्षेत्र', hi: 'कार्य क्षेत्र'),
            _member.area != null && _member.area!.isNotEmpty
                ? AppTranslations.getAreaName(_member.area!, lang)
                : AppTranslations.pick(lang, en: 'Ward 12 Entire Area', mr: 'संपूर्ण प्रभाग १२', hi: 'पूरा वार्ड १२ क्षेत्र'),
            lang: lang,
            translateValue: _member.area != null && _member.area!.isNotEmpty,
          ),
          _buildInfoRow(
            Icons.phone_iphone_rounded,
            AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
            AppTranslations.formatDigits('+91 ${_member.mobile}', lang),
            lang: lang,
          ),
          if (_member.email != null && _member.email!.isNotEmpty)
            _buildInfoRow(
              Icons.email_outlined,
              AppTranslations.pick(lang, en: 'Email', mr: 'ईमेल', hi: 'ईमेल'),
              _member.email!,
              lang: lang,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    required String lang,
    bool translateValue = false,
  }) {
    const valStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF0284C7)),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: translateValue
                ? AppTranslatedText(value, targetLanguage: lang, style: valStyle)
                : Text(value, style: valStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar(String lang) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.phone, size: 16, color: Colors.white),
            label: Text(
              AppTranslations.pick(lang, en: 'Call', mr: 'कॉल करा', hi: 'कॉल करें'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
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
            label: Text(
              AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सअॅप', hi: 'व्हाट्सऐप'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _messageOnWhatsApp(lang),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordsCard(String lang) {
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
            children: [
              const Icon(Icons.auto_fix_high_rounded, size: 17, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Auto-Assign Rules',
                  mr: 'स्वयंचलित काम वाटप नियम',
                  hi: 'स्वचालित कार्य आवंटन नियम',
                ),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.pick(
              lang,
              en: 'When citizen complaints contain these keywords, tasks are routed here automatically:',
              mr: 'नागरिकांच्या तक्रारींमध्ये हे शब्द आल्यास कामे स्वयंचलितपणे येथे पाठवली जातात:',
              hi: 'नागरिकों की शिकायतों में ये मुख्य शब्द आने पर कार्य स्वतः यहाँ भेजे जाते हैं:',
            ),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          if (_member.keywords.isEmpty)
            Text(
              AppTranslations.pick(
                lang,
                en: 'No specific keywords assigned (General tasks).',
                mr: 'कोणतेही विशिष्ट मुख्य शब्द नेमलेले नाहीत (सामान्य कामे).',
                hi: 'कोई विशेष मुख्य शब्द निर्धारित नहीं (सामान्य कार्य).',
              ),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
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
                  child: AppTranslatedText(
                    k,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignedTasksSection(int completed, int pending, String lang) {
    final compStr = AppTranslations.formatDigits(completed, lang);
    final pendStr = AppTranslations.formatDigits(pending, lang);

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.task_alt_rounded, size: 18, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.pick(lang, en: 'Assigned Tasks', mr: 'सोपवलेली कामे', hi: 'सौंपे गए कार्य'),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      AppTranslations.pick(lang, en: '$compStr Completed', mr: '$compStr पूर्ण', hi: '$compStr पूर्ण'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      AppTranslations.pick(lang, en: '$pendStr In Progress', mr: '$pendStr प्रगतीपथावर', hi: '$pendStr प्रगति पर'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
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
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'No tasks assigned yet.',
                        mr: 'अद्याप कोणतेही काम सोपवलेले नाही.',
                        hi: 'अभी तक कोई कार्य नहीं सौंपा गया है।',
                      ),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pagedTasks.length,
              separatorBuilder: (context, index) => const Divider(height: 14),
              itemBuilder: (ctx, idx) {
                final t = _pagedTasks[idx];
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
                      onChanged: (_) => _toggleTaskStatus(t, lang),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTranslatedText(
                            t.title,
                            targetLanguage: lang,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey : const Color(0xFF0F172A),
                            ),
                          ),
                          if (t.description != null && t.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            AppTranslatedText(
                              t.description!,
                              targetLanguage: lang,
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
                                  t.priorityLabel(lang),
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: prioColor),
                                ),
                              ),
                              if (t.dueDate != null) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                                const SizedBox(width: 3),
                                Text(
                                  AppTranslations.formatDate(t.dueDate!, lang, pattern: 'dd MMM'),
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                ),
                              ],
                              if (t.location != null) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.location_on_outlined, size: 11, color: Colors.grey.shade500),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: AppTranslatedText(
                                    t.location!,
                                    targetLanguage: lang,
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
            AppInlinePagination(
              currentPage: _taskPage,
              totalPages: _totalTaskPages,
              totalItems: _tasks.length,
              pageSize: _taskPageSize,
              label: AppTranslations.pick(lang, en: 'tasks', mr: 'कामे', hi: 'कार्य'),
              onPageChanged: (page) => setState(() => _taskPage = page),
            ),
          ],
        ],
      ),
    );
  }
}
