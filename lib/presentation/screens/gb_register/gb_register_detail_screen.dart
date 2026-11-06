import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gb_register_entry_model.dart';
import '../../../data/repositories/gb_register_repository.dart';
import '../../providers/auth_provider.dart';

class GbRegisterDetailScreen extends ConsumerStatefulWidget {
  final GbRegisterEntryModel entry;

  const GbRegisterDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<GbRegisterDetailScreen> createState() => _GbRegisterDetailScreenState();
}

class _GbRegisterDetailScreenState extends ConsumerState<GbRegisterDetailScreen> {
  late GbRegisterEntryModel _currentEntry;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  Future<void> _handleQuickStatusChange(String newStatus) async {
    if (_currentEntry.status == newStatus) return;
    final updated = _currentEntry.copyWith(status: newStatus);
    final repo = ref.read(gbRegisterRepoProvider);
    await repo.updateEntry(updated);
    if (mounted) {
      setState(() => _currentEntry = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Motion status updated to $newStatus'),
          backgroundColor: const Color(0xFF0284C7),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Motion Entry'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove this assembly record from the GB Register? This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              final repo = ref.read(gbRegisterRepoProvider);
              await repo.deleteEntry(_currentEntry.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GB Register record deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditModal() {
    final subjectCtrl = TextEditingController(text: _currentEntry.subject);
    final descCtrl = TextEditingController(text: _currentEntry.description);
    final deptCtrl = TextEditingController(text: _currentEntry.department);
    final areaCtrl = TextEditingController(text: _currentEntry.area);
    final dateCtrl = TextEditingController(text: _currentEntry.meetingDate);
    final benCtrl = TextEditingController(text: _currentEntry.beneficiaries ?? '');
    final resCtrl = TextEditingController(text: _currentEntry.resolutionNo ?? '');
    final respCtrl = TextEditingController(text: _currentEntry.response ?? '');

    String selectedMeetingType = _currentEntry.meetingType;
    String selectedStatus = _currentEntry.status;

    final meetingTypes = ['GB', 'Standing Committee', 'Ward Committee', 'Special GB', 'Other'];
    final statusList = ['Raised', 'In Discussion', 'Action Taken', 'Rejected'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit GB Register Entry',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Meeting Type
                    const Text('Meeting Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: meetingTypes.contains(selectedMeetingType) ? selectedMeetingType : 'GB',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: meetingTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMeetingType = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Meeting Date
                    const Text('Meeting Date (YYYY-MM-DD) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: dateCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                        hintText: 'YYYY-MM-DD',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subject
                    const Text('Subject / Question Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subjectCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Enter motion subject...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    const Text('Motion Description & Demands *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Describe issues raised, references, or public demands...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Department & Area
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Department *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: deptCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  hintText: 'e.g. Water Supply',
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
                              const Text('Area / Ward *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  hintText: 'e.g. Shaniwar Peth',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status & Beneficiaries
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: statusList.contains(selectedStatus) ? selectedStatus : 'Raised',
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedStatus = val);
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
                              const Text('Beneficiaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: benCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  hintText: 'e.g. 15,000 Residents',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Resolution No
                    const Text('Resolution Reference No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: resCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'e.g. PMC/GB/RES/2024/412',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Official Response
                    const Text('Administration Reply & Action Taken', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: respCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Enter official response from Municipal Commissioner / Dept Head...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (subjectCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Subject is required')),
                            );
                            return;
                          }

                          final updated = _currentEntry.copyWith(
                            meetingType: selectedMeetingType,
                            meetingDate: dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : _currentEntry.meetingDate,
                            subject: subjectCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : _currentEntry.department,
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : _currentEntry.area,
                            status: selectedStatus,
                            beneficiaries: benCtrl.text.trim().isNotEmpty ? benCtrl.text.trim() : null,
                            resolutionNo: resCtrl.text.trim().isNotEmpty ? resCtrl.text.trim() : null,
                            response: respCtrl.text.trim().isNotEmpty ? respCtrl.text.trim() : null,
                          );

                          final repo = ref.read(gbRegisterRepoProvider);
                          await repo.updateEntry(updated);
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            setState(() => _currentEntry = updated);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('GB Register entry updated successfully'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final entry = _currentEntry;

    final statusTabs = [
      {'key': 'Raised', 'label': isMr ? 'मांडलेला' : 'Raised'},
      {'key': 'In Discussion', 'label': isMr ? 'चर्चेत' : 'In Discussion'},
      {'key': 'Action Taken', 'label': isMr ? 'कार्यवाही झाली' : 'Action Taken'},
      {'key': 'Rejected', 'label': isMr ? 'नाकारले' : 'Rejected'},
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMr ? 'महासभा ठराव तपशील' : 'GB Motion Details',
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${entry.meetingType} • ${entry.area}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit Entry',
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: 'Delete Entry',
              onPressed: _showDeleteConfirmation,
            ),
          ],
        ),
        body: _isDeleting
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Meeting badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: entry.meetingTypeBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: entry.meetingTypeColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  isMr ? entry.meetingTypeDisplayMr : entry.meetingTypeDisplayEn,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: entry.meetingTypeColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: entry.statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: entry.statusBorderColor),
                                ),
                                child: Text(
                                  isMr ? entry.statusDisplayMr : entry.statusDisplayEn,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: entry.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            entry.subject,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.event_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                '${isMr ? "सभेचा दिनांक" : "Meeting Date"}: ${_formatDate(entry.meetingDate)}',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              if (entry.resolutionNo != null) ...[
                                const SizedBox(width: 14),
                                const Icon(Icons.bookmark_border_rounded, size: 16, color: Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  entry.resolutionNo!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick status change selector
                    Text(
                      isMr ? 'सभेची स्थिती बदला' : 'Update Motion Status',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: statusTabs.map((tab) {
                          final isSelected = entry.status.toLowerCase() == tab['key']!.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => _handleQuickStatusChange(tab['key']!),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  tab['label']!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Motion description card
                    Container(
                      width: double.infinity,
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
                            children: [
                              const Icon(Icons.description_outlined, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(
                                isMr ? 'सभेत मांडलेला तपशील' : 'Motion Details & Public Demands',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            entry.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF334155),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Official response card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: entry.response != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: entry.response != null ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                entry.response != null ? Icons.verified_rounded : Icons.pending_actions_rounded,
                                size: 20,
                                color: entry.response != null ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isMr ? 'प्रशासकीय अभिप्राय / कार्यवाही उत्तर' : 'Official Administration Reply',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: entry.response != null ? const Color(0xFF14532D) : const Color(0xFF713F12),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          if (entry.response != null) ...[
                            Text(
                              entry.response!,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF166534),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (entry.resolutionNo != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${isMr ? "ठराव संदर्भ" : "Resolution Ref"}: ${entry.resolutionNo}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                              ),
                            ],
                          ] else ...[
                            Text(
                              isMr
                                  ? 'या प्रश्नावर अजून मनपा प्रशासनाकडून औपचारिक उत्तर आलेले नाही.'
                                  : 'Awaiting formal reply on the assembly floor from Municipal Administration.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Information details grid
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr ? 'विभागीय आणि स्थानिक माहिती' : 'Administrative Context',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Divider(height: 20),
                          _infoRow(
                            icon: Icons.business_rounded,
                            label: isMr ? 'खाते / विभाग' : 'Department',
                            value: entry.department,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.location_on_outlined,
                            label: isMr ? 'परिसर / प्रभाग' : 'Area / Prabhag',
                            value: entry.area,
                          ),
                          if (entry.beneficiaries != null) ...[
                            const SizedBox(height: 12),
                            _infoRow(
                              icon: Icons.people_outline_rounded,
                              label: isMr ? 'प्रभावित लाभार्थी' : 'Beneficiaries Impacted',
                              value: entry.beneficiaries!,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.access_time_rounded,
                            label: isMr ? 'नोंदणी तारीख' : 'Recorded At',
                            value: _formatDate(entry.createdAt.isNotEmpty ? entry.createdAt : entry.meetingDate),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    if (entry.tags.isNotEmpty) ...[
                      Text(
                        isMr ? 'विषय टॅग्ज (Tags)' : 'Tags',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.tags.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '#$t',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
