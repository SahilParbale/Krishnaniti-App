import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/work_tracker_model.dart';
import '../../../data/repositories/file_tracker_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_pagination_bar.dart';
import '../../widgets/app_shimmer_card.dart';
import 'gov_office_report_generator.dart';

class FileTrackerTabView extends ConsumerStatefulWidget {
  const FileTrackerTabView({super.key});

  @override
  ConsumerState<FileTrackerTabView> createState() => _FileTrackerTabViewState();
}

class _FileTrackerTabViewState extends ConsumerState<FileTrackerTabView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatus = 'All';
  bool _isLoading = true;
  List<WorkTrackerModel> _trackers = [];

  int _currentPage = 1;
  int _pageSize = 20;

  int get _totalPages {
    final count = _trackers.length;
    return (count / _pageSize).ceil() < 1 ? 1 : (count / _pageSize).ceil();
  }

  List<WorkTrackerModel> get _pagedTrackers {
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= _trackers.length) return [];
    final endIndex = min(startIndex + _pageSize, _trackers.length);
    return _trackers.sublist(startIndex, endIndex);
  }

  final List<String> _statuses = [
    'All',
    'Pending',
    'In Progress',
    'Approved',
    'Rejected',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTrackers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTrackers() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(fileTrackerRepoProvider);
      final list = await repo.getFileTrackers(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _trackers = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'in progress':
      case 'inprogress':
        return const Color(0xFF0284C7);
      case 'approved':
        return const Color(0xFF16A34A);
      case 'completed':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'in progress':
      case 'inprogress':
        return const Color(0xFFE0F2FE);
      case 'approved':
        return const Color(0xFFDCFCE7);
      case 'completed':
        return const Color(0xFFD1FAE5);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  void _showAddEditModal({WorkTrackerModel? existing}) {
    final isMr = ref.read(isMarathiProvider);
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final deptCtrl = TextEditingController(text: existing?.department ?? '');
    final inwardCtrl = TextEditingController(text: existing?.inwardNumber ?? '');
    final outwardCtrl = TextEditingController(text: existing?.outwardNumber ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String status = existing?.currentStatus ?? 'Pending';
    final initialStageCtrl = TextEditingController();
    final initialLocationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF0284C7), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            existing != null
                                ? (isMr ? 'फाईल माहिती संपादित करा' : 'Edit File Tracker')
                                : (isMr ? 'नवीन फाईल नोंदवा' : 'Register New File Tracker'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(bottomCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildInputLabel(isMr ? 'फाईल शीर्षक (Title) *' : 'File Title *'),
                        TextField(
                          controller: titleCtrl,
                          decoration: _inputDecoration('e.g. Ward Road Concreting Proposal'),
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel(isMr ? 'विषय (Subject) *' : 'Subject *'),
                        TextField(
                          controller: subjectCtrl,
                          decoration: _inputDecoration('e.g. Road concretization sanction file'),
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel(isMr ? 'संबंधित विभाग (Department) *' : 'Department *'),
                        TextField(
                          controller: deptCtrl,
                          decoration: _inputDecoration('e.g. PWD / Water Supply / Town Planning'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel(isMr ? 'आवक क्रमांक (Inward No)' : 'Inward Number'),
                                  TextField(
                                    controller: inwardCtrl,
                                    decoration: _inputDecoration('IN-2026-401'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel(isMr ? 'जावक क्रमांक (Outward No)' : 'Outward Number'),
                                  TextField(
                                    controller: outwardCtrl,
                                    decoration: _inputDecoration('OUT-2026-88'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel(isMr ? 'सद्यस्थिती (Current Status)' : 'Current Status'),
                        DropdownButtonFormField<String>(
                          value: status,
                          items: _statuses
                              .where((s) => s != 'All')
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => status = val);
                          },
                          decoration: _inputDecoration('Status'),
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel(isMr ? 'तपशील / शेरा (Description)' : 'Description / Remarks'),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: _inputDecoration('Notes regarding file submission, approvals...'),
                        ),
                        if (existing == null) ...[
                          const SizedBox(height: 12),
                          _buildInputLabel(isMr ? 'सुरुवातीचा टप्पा (Initial Movement Stage)' : 'Initial Movement Stage (Optional)'),
                          TextField(
                            controller: initialStageCtrl,
                            decoration: _inputDecoration('e.g. Submitted to Chief Engineer Office'),
                          ),
                          const SizedBox(height: 12),
                          _buildInputLabel(isMr ? 'सध्याचे ठिकाण / टेबल (Current Location/Table)' : 'Current Location / Table'),
                          TextField(
                            controller: initialLocationCtrl,
                            decoration: _inputDecoration('e.g. Desk 4, PMC Main Building'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        final subject = subjectCtrl.text.trim();
                        final dept = deptCtrl.text.trim();

                        if (title.isEmpty || dept.isEmpty) {
                          ScaffoldMessenger.of(bottomCtx).showSnackBar(
                            SnackBar(content: Text(isMr ? 'शीर्षक व विभाग आवश्यक आहेत' : 'Title and Department are required')),
                          );
                          return;
                        }

                        final repo = ref.read(fileTrackerRepoProvider);
                        final user = ref.read(currentUserProvider);

                        if (existing != null) {
                          await repo.updateFileTracker(
                            id: existing.id,
                            title: title,
                            subject: subject,
                            department: dept,
                            inwardNumber: inwardCtrl.text.trim(),
                            outwardNumber: outwardCtrl.text.trim(),
                            currentStatus: status,
                            description: descCtrl.text.trim(),
                          );
                        } else {
                          await repo.createFileTracker(
                            title: title,
                            subject: subject,
                            department: dept,
                            inwardNumber: inwardCtrl.text.trim(),
                            outwardNumber: outwardCtrl.text.trim(),
                            currentStatus: status,
                            description: descCtrl.text.trim(),
                            initialStageName: initialStageCtrl.text.trim().isNotEmpty ? initialStageCtrl.text.trim() : null,
                            initialLocation: initialLocationCtrl.text.trim().isNotEmpty ? initialLocationCtrl.text.trim() : null,
                            updatedBy: user?.name,
                          );
                        }

                        if (mounted) {
                          Navigator.pop(bottomCtx);
                          _fetchTrackers();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isMr ? 'फाईल नोंद जतन करा' : 'Save File Record', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _showDetailModal(WorkTrackerModel file) async {
    final isMr = ref.read(isMarathiProvider);
    final repo = ref.read(fileTrackerRepoProvider);

    final fullItem = await repo.getFileTrackerById(file.id) ?? file;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullItem.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              fullItem.department,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(fullItem.currentStatus),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(fullItem.currentStatus).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          fullItem.currentStatus,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(fullItem.currentStatus)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // Numbers card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isMr ? 'आवक क्र.' : 'Inward No.', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  Text(fullItem.inwardNumber.isNotEmpty ? fullItem.inwardNumber : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 30, color: const Color(0xFFCBD5E1)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isMr ? 'जावक क्र.' : 'Outward No.', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  Text(fullItem.outwardNumber.isNotEmpty ? fullItem.outwardNumber : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (fullItem.description.isNotEmpty) ...[
                        Text(isMr ? 'तपशील' : 'Description', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(fullItem.description, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                        const SizedBox(height: 16),
                      ],

                      // Movement History Header + Add Stage button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_rounded, size: 18, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Text(
                                isMr ? 'हालचाल इतिहास (Movement History)' : 'Movement Stages History',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _showAddStageDialog(fullItem.id, () async {
                                final updated = await repo.getFileTrackerById(fullItem.id);
                                if (updated != null && mounted) {
                                  Navigator.pop(sheetCtx);
                                  _showDetailModal(updated);
                                }
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(isMr ? 'टप्पा जोडा' : 'Add Stage', style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (fullItem.stages.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            isMr ? 'कोणतेही टप्पे नोंदवलेले नाहीत' : 'No movement stages recorded yet',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: fullItem.stages.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final stage = fullItem.stages[idx];
                            final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(stage.createdAt);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.place_outlined, size: 16, color: Color(0xFF0284C7)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(stage.stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        if (stage.location.isNotEmpty)
                                          Text(stage.location, style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                                        if (stage.statusDescription.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(stage.statusDescription, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(dateStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _showAddEditModal(existing: fullItem);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(isMr ? 'संपादित करा' : 'Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(isMr ? 'हटवायचे का?' : 'Delete File Tracker?'),
                              content: Text(isMr ? 'ही फाईल व इतिहास कायमचा हटवला जाईल.' : 'This file record and its stages will be permanently deleted.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(isMr ? 'रद्द' : 'Cancel')),
                                TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: Text(isMr ? 'हटवा' : 'Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await repo.deleteFileTracker(fullItem.id);
                            if (mounted) {
                              Navigator.pop(sheetCtx);
                              _fetchTrackers();
                            }
                          }
                        },
                      ),
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

  void _showAddStageDialog(String trackerId, VoidCallback onAdded) {
    final isMr = ref.read(isMarathiProvider);
    final stageCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String newStatus = 'In Progress';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isMr ? 'नवीन हालचाल टप्पा जोडा' : 'Add Movement Stage', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel(isMr ? 'टप्प्याचे नाव (Stage Name) *' : 'Stage Name *'),
              TextField(controller: stageCtrl, decoration: _inputDecoration('e.g. Sent for Audit Verification')),
              const SizedBox(height: 10),
              _buildInputLabel(isMr ? 'स्थान / कार्यालय (Location)' : 'Location / Office'),
              TextField(controller: locCtrl, decoration: _inputDecoration('e.g. Accounts Department, 2nd Floor')),
              const SizedBox(height: 10),
              _buildInputLabel(isMr ? 'शेरा / सद्यस्थिती शेरा' : 'Status Description / Remarks'),
              TextField(controller: descCtrl, maxLines: 2, decoration: _inputDecoration('e.g. Verified and signed by superintendent')),
              const SizedBox(height: 10),
              _buildInputLabel(isMr ? 'नवीन स्थिती (Update Status)' : 'Update Status'),
              DropdownButtonFormField<String>(
                value: newStatus,
                items: _statuses
                    .where((s) => s != 'All')
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) newStatus = val;
                },
                decoration: _inputDecoration('Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              final stageName = stageCtrl.text.trim();
              if (stageName.isEmpty) return;

              final repo = ref.read(fileTrackerRepoProvider);
              final user = ref.read(currentUserProvider);

              await repo.addMovementStage(
                workTrackerId: trackerId,
                stageName: stageName,
                location: locCtrl.text.trim(),
                statusDescription: descCtrl.text.trim(),
                updatedBy: user?.name,
                newTrackerStatus: newStatus,
              );

              if (mounted) {
                Navigator.pop(ctx);
                onAdded();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
            child: Text(isMr ? 'जोडा' : 'Add Stage'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
    );
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);

    return Column(
      children: [
        // Filter & Search Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) {
                        setState(() => _currentPage = 1);
                        _fetchTrackers();
                      },
                      decoration: InputDecoration(
                        hintText: isMr ? 'शीर्षक, आवक/जावक क्र. शोधा...' : 'Search title, inward/outward no...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: isMr ? 'अहवाल डाउनलोड करा' : 'Export File Register PDF',
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0284C7)),
                    onPressed: _trackers.isEmpty
                        ? null
                        : () => GovOfficeReportGenerator.generateAndPrintFileTrackerReport(
                              trackers: _trackers,
                              statusFilter: _selectedStatus,
                            ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditModal(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(isMr ? 'नोंदवा' : 'Add File', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status Filter Pills
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final s = _statuses[i];
                    final isSel = _selectedStatus == s;
                    return ChoiceChip(
                      label: Text(s, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF64748B))),
                      selected: isSel,
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: Colors.white,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedStatus = s;
                            _currentPage = 1;
                          });
                          _fetchTrackers();
                        }
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Files List
        Expanded(
          child: _isLoading
              ? const AppShimmerList(count: 6)
              : _trackers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 8),
                          Text(
                            isMr ? 'कोणतीही फाईल सापडली नाही' : 'No file trackers found',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMr ? 'Supabase work_trackers टेबल रिक्त आहे' : 'work_trackers database table is empty',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchTrackers,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _pagedTrackers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _pagedTrackers[index];
                          final dateStr = DateFormat('dd MMM yyyy').format(item.updatedAt);

                          return InkWell(
                            onTap: () => _showDetailModal(item),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.department,
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusBgColor(item.currentStatus),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.currentStatus,
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _getStatusColor(item.currentStatus)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  if (item.subject.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.subject,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (item.inwardNumber.isNotEmpty) ...[
                                            const Icon(Icons.arrow_downward_rounded, size: 12, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 2),
                                            Text('In: ${item.inwardNumber}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            const SizedBox(width: 8),
                                          ],
                                          if (item.outwardNumber.isNotEmpty) ...[
                                            const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF16A34A)),
                                            const SizedBox(width: 2),
                                            Text('Out: ${item.outwardNumber}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ],
                                      ),
                                      Text(dateStr, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
        AppPaginationBar(
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalItems: _trackers.length,
          pageSize: _pageSize,
          onPageChanged: (newPage) {
            setState(() => _currentPage = newPage);
          },
          onPageSizeChanged: (newSize) {
            setState(() {
              _pageSize = newSize;
              _currentPage = 1;
            });
          },
        ),
      ],
    );
  }
}
