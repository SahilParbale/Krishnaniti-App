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
    final isMr = ref.read(isMarathiProvider);
    final subjectCtrl = TextEditingController(text: _currentEntry.subject);
    final descCtrl = TextEditingController(text: _currentEntry.description);
    final deptCtrl = TextEditingController(text: _currentEntry.department);
    final areaCtrl = TextEditingController(text: _currentEntry.area);
    final dateCtrl = TextEditingController(text: _currentEntry.meetingDate);
    final benCtrl = TextEditingController(text: _currentEntry.beneficiaries ?? '');
    final respCtrl = TextEditingController(text: _currentEntry.response ?? '');

    String selectedMeetingType = _currentEntry.meetingType;
    String selectedStatus = _currentEntry.status;

    final meetingTypes = ['GB', 'Standing Committee', 'Ward Committee', 'Special GB', 'Other'];
    final statusList = ['Raised', 'In Discussion', 'Resolved', 'Action Taken'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            Future<void> pickDate() async {
              DateTime initial;
              try {
                initial = DateTime.parse(dateCtrl.text.trim());
              } catch (_) {
                initial = DateTime.now();
              }
              final picked = await showDatePicker(
                context: sheetCtx,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF0284C7),
                        onPrimary: Colors.white,
                        onSurface: Color(0xFF0F172A),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setModalState(() {
                  dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            }

            InputDecoration inputDec({required String hintText, IconData? prefixIcon}) {
              return InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

            Widget fieldLabel(String label, {bool isRequired = false}) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 2),
                      const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  // Downward Dismiss Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header with Title and Close Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMr ? 'GB नोंद संपादित करा' : 'Edit GB Register Entry',
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: 14,
                        left: 18,
                        right: 18,
                        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Meeting Date & Meeting Type (Side-by-Side)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(isMr ? 'बैठक तारीख' : 'Meeting Date', isRequired: true),
                                    TextField(
                                      controller: dateCtrl,
                                      readOnly: true,
                                      onTap: pickDate,
                                      decoration: inputDec(
                                        hintText: 'YYYY-MM-DD',
                                        prefixIcon: Icons.calendar_today_outlined,
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
                                    fieldLabel(isMr ? 'बैठक प्रकार' : 'Meeting Type', isRequired: true),
                                    DropdownButtonFormField<String>(
                                      initialValue: meetingTypes.contains(selectedMeetingType) ? selectedMeetingType : 'GB',
                                      isExpanded: true,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                      decoration: inputDec(hintText: 'Select Type'),
                                      items: meetingTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedMeetingType = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 2. Subject / Issue (Full Width)
                          fieldLabel(isMr ? 'विषय / मुद्दा' : 'Subject / Issue', isRequired: true),
                          TextField(
                            controller: subjectCtrl,
                            decoration: inputDec(
                              hintText: isMr ? 'उदा. प्रभाग १२ मध्ये पाण्याची टंचाई' : 'e.g. Water shortage in Ward 12',
                              prefixIcon: Icons.title_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Description (Full Width)
                          fieldLabel(isMr ? 'वर्णन' : 'Description'),
                          TextField(
                            controller: descCtrl,
                            maxLines: 3,
                            decoration: inputDec(
                              hintText: isMr ? 'मंडलेल्या मुद्द्याचे सविस्तर वर्णन...' : 'Detailed description of the issue raised...',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 4. Area & Beneficiaries (Side-by-Side)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(isMr ? 'क्षेत्र / भाग' : 'Area'),
                                    TextField(
                                      controller: areaCtrl,
                                      decoration: inputDec(
                                        hintText: isMr ? 'उदा. प्रभाग १२' : 'e.g. Ward 12',
                                        prefixIcon: Icons.map_outlined,
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
                                    fieldLabel(isMr ? 'लाभार्थी' : 'People Benefited'),
                                    TextField(
                                      controller: benCtrl,
                                      decoration: inputDec(
                                        hintText: isMr ? 'उदा. ५००+ नागरिक' : 'e.g. 500+ residents',
                                        prefixIcon: Icons.people_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 5. Department & Outcome / Status (Side-by-Side)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(isMr ? 'विभाग' : 'Department'),
                                    TextField(
                                      controller: deptCtrl,
                                      decoration: inputDec(
                                        hintText: isMr ? 'उदा. पाणी पुरवठा' : 'e.g. Water Supply',
                                        prefixIcon: Icons.business_outlined,
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
                                    fieldLabel(isMr ? 'निकाल / स्थिती' : 'Outcome / Status', isRequired: true),
                                    DropdownButtonFormField<String>(
                                      initialValue: statusList.contains(selectedStatus) ? selectedStatus : 'Raised',
                                      isExpanded: true,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                      decoration: inputDec(hintText: 'Select Status'),
                                      items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedStatus = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 6. Administrative Response (Full Width)
                          fieldLabel(isMr ? 'प्रशासकीय उत्तर' : 'Administrative Response'),
                          TextField(
                            controller: respCtrl,
                            maxLines: 2,
                            decoration: inputDec(
                              hintText: isMr ? 'प्रशासनाकडून मिळालेले उत्तर...' : 'Response received from administration...',
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button (Existing button - wired directly)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                              onPressed: () async {
                                if (subjectCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isMr ? 'कृपया विषय प्रविष्ट करा' : 'Subject is required')),
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
                                  response: respCtrl.text.trim().isNotEmpty ? respCtrl.text.trim() : null,
                                );

                                final repo = ref.read(gbRegisterRepoProvider);
                                await repo.updateEntry(updated);
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (mounted) {
                                  setState(() => _currentEntry = updated);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isMr ? 'नोंद यशस्वीरित्या अद्यतनित केली!' : 'GB Register entry updated successfully'),
                                      backgroundColor: const Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              label: Text(
                                isMr ? 'बदल जतन करा' : 'Save Changes',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                '${entry.meetingType} • ${entry.area}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
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
