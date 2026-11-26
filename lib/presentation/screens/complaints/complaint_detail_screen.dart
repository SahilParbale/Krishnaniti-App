import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_pagination_bar.dart';
import '../../widgets/complaint_video_player.dart';
import 'complaint_report_generator.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  final ComplaintModel complaint;
  final VoidCallback? onBack;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
    this.onBack,
  });

  @override
  ConsumerState<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  late ComplaintModel _complaint;
  List<StaffModel> _staffList = [];
  bool _isLoadingStaff = true;
  String? _assignedStaffId;
  int _updatePage = 1;
  static const int _updatePageSize = 5;

  int get _totalUpdatePages {
    final count = _complaint.progressUpdates.length;
    return (count / _updatePageSize).ceil() < 1 ? 1 : (count / _updatePageSize).ceil();
  }

  List<ComplaintProgressUpdate> get _pagedUpdates {
    final list = _complaint.progressUpdates;
    final startIndex = (_updatePage - 1) * _updatePageSize;
    if (startIndex >= list.length) return [];
    final endIndex = min(startIndex + _updatePageSize, list.length);
    return list.sublist(startIndex, endIndex);
  }

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _assignedStaffId = _complaint.assignedTo;
    _resolveInitialAttachments();
    _loadInitialData();
  }

  Future<void> _resolveInitialAttachments() async {
    try {
      final resolved = await _resolveComplaintAttachments(_complaint);
      if (mounted) {
        setState(() {
          _complaint = resolved;
        });
      }
    } catch (_) {}
  }

  Future<ComplaintModel> _resolveComplaintAttachments(ComplaintModel complaint) async {
    final service = SupabaseService.instance;
    final resolvedAttachments = <ComplaintAttachment>[];

    for (final att in complaint.attachments) {
      if (att.url.trim().isEmpty) continue;
      String url = att.url.trim();
      if (!url.startsWith('http://') &&
          !url.startsWith('https://') &&
          !url.startsWith('data:') &&
          !url.startsWith('blob:')) {
        url = await service.getSignedStorageUrl(url, bucket: 'documents');
      }
      resolvedAttachments.add(ComplaintAttachment(
        url: url,
        type: att.type,
        name: att.name,
        size: att.size,
      ));
    }

    String? resolvedImageUrl = complaint.imageUrl;
    if (resolvedImageUrl != null &&
        resolvedImageUrl.trim().isNotEmpty &&
        !resolvedImageUrl.startsWith('http://') &&
        !resolvedImageUrl.startsWith('https://')) {
      resolvedImageUrl = await service.getSignedStorageUrl(resolvedImageUrl.trim(), bucket: 'documents');
    }

    final resolvedPhotos = <String>[];
    for (final p in complaint.photos) {
      if (p.trim().isEmpty) continue;
      String url = p.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = await service.getSignedStorageUrl(url, bucket: 'documents');
      }
      resolvedPhotos.add(url);
    }

    return complaint.copyWith(
      attachments: resolvedAttachments,
      imageUrl: resolvedImageUrl,
      photos: resolvedPhotos,
    );
  }

  Future<void> _loadInitialData() async {
    // 1. Fetch Staff list first & independently (matching Staff screen / TeamRepository)
    try {
      final repo = ref.read(complaintsRepoProvider);
      var staff = await repo.getStaffList(forceRefresh: true);

      if (staff.isEmpty) {
        // Fallback to TeamRepository (powers the My Team / Staff screen)
        final teamMembers = await ref.read(teamRepoProvider).getTeamMembers();
        if (teamMembers.isNotEmpty) {
          staff = teamMembers
              .map((m) => StaffModel(
                    id: m.id,
                    name: m.displayName,
                    role: m.role,
                    mobile: m.mobile,
                    email: m.email,
                    tenantId: m.tenantId,
                  ))
              .toList();
        }
      }

      if (mounted) {
        setState(() {
          _staffList = staff;
          _isLoadingStaff = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStaff = false);
      }
    }

    // 2. Fetch fresh complaint details & attachments
    try {
      final repo = ref.read(complaintsRepoProvider);
      final fresh = await repo.getComplaintById(_complaint.id);
      if (mounted) {
        final complaintToUse = fresh ?? _complaint;
        final resolvedComplaint = await _resolveComplaintAttachments(complaintToUse);

        setState(() {
          _complaint = resolvedComplaint;
          _assignedStaffId = resolvedComplaint.assignedTo ?? _assignedStaffId;
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshComplaint() async {
    try {
      final repo = ref.read(complaintsRepoProvider);
      final freshFuture = repo.getComplaintById(_complaint.id);
      final staffFuture = repo.getStaffList(forceRefresh: true);

      final results = await Future.wait([freshFuture, staffFuture]);
      final fresh = results[0] as ComplaintModel?;
      final staff = results[1] as List<StaffModel>;

      if (mounted) {
        final resolvedComplaint = fresh != null ? await _resolveComplaintAttachments(fresh) : _complaint;
        setState(() {
          if (staff.isNotEmpty) _staffList = staff;
          _complaint = resolvedComplaint;
          _assignedStaffId = resolvedComplaint.assignedTo ?? _assignedStaffId;
        });
      }
    } catch (_) {}
  }

  // Helper to resolve staff name
  String get _currentAssignedStaffName {
    if (_complaint.assignedStaffName != null && _complaint.assignedStaffName!.isNotEmpty) {
      return _complaint.assignedStaffName!;
    }
    if (_assignedStaffId != null) {
      final found = _staffList.where((s) => s.id == _assignedStaffId);
      if (found.isNotEmpty) return found.first.name;
    }
    return '';
  }

  String get _currentAssignedStaffMobile {
    if (_complaint.assignedStaffMobile != null && _complaint.assignedStaffMobile!.isNotEmpty) {
      return _complaint.assignedStaffMobile!;
    }
    if (_assignedStaffId != null) {
      final found = _staffList.where((s) => s.id == _assignedStaffId);
      if (found.isNotEmpty && found.first.mobile != null) return found.first.mobile!;
    }
    return '';
  }

  // 1. Assign Staff Action
  Future<void> _assignStaff(StaffModel staff) async {
    setState(() {
      _assignedStaffId = staff.id;
      _complaint = _complaint.copyWith(
        assignedTo: staff.id,
        assignedStaffName: staff.name,
        assignedStaffMobile: staff.mobile,
        status: 'Assigned',
      );
    });

    try {
      await ref.read(complaintsRepoProvider).assignStaff(_complaint.id, staff.id);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff "${staff.name}" assigned successfully'),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 2. Add / Update Status Modal (Responsive: Dialog on Desktop matching StatusUpdateModal.tsx, Sheet on Mobile)
  void _openStatusModal({required String mode, bool showStatusSelector = false}) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 740),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: _StatusUpdateBottomSheet(
              initialMode: mode,
              showStatusSelector: showStatusSelector,
              complaintTitle: _complaint.title,
              isDesktop: true,
              onSubmit: (note, status, images) async {
                Navigator.pop(ctx);
                await _handleSaveProgressLog(note, status, images);
              },
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _StatusUpdateBottomSheet(
          initialMode: mode,
          showStatusSelector: showStatusSelector,
          complaintTitle: _complaint.title,
          isDesktop: false,
          onSubmit: (note, status, images) async {
            Navigator.pop(ctx);
            await _handleSaveProgressLog(note, status, images);
          },
        ),
      );
    }
  }

  Future<void> _handleSaveProgressLog(String note, String status, List<ComplaintAttachment> images) async {
    final user = ref.read(currentUserProvider);
    final updaterName = user?.name ?? user?.email ?? 'Staff Member';
    final timestamp = DateTime.now();

    final newLog = ComplaintProgressUpdate(
      note: note,
      status: status,
      timestamp: timestamp,
      updatedBy: updaterName,
      images: images,
    );

    setState(() {
      final currentUpdates = List<ComplaintProgressUpdate>.from(_complaint.progressUpdates)..add(newLog);
      _complaint = _complaint.copyWith(
        status: status,
        progressUpdates: currentUpdates,
        workInProgress: status == 'InProgress' ? newLog : _complaint.workInProgress,
        resolutionDetails: status == 'Resolved' ? newLog : _complaint.resolutionDetails,
      );
    });

    try {
      await ref.read(complaintsRepoProvider).addProgressLog(
            complaintId: _complaint.id,
            note: note,
            status: status,
            updatedBy: updaterName,
            images: images,
          );
    } catch (_) {}

    if (mounted) {
      final isMr = ref.read(isMarathiProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'InProgress'
                ? (isMr ? 'कामाची प्रगती यशस्वीरित्या नोंदवली!' : 'Work marked in progress with notes & photos!')
                : (isMr ? 'तक्रार यशस्वीरित्या निवारण म्हणून नोंदवली!' : 'Complaint marked as resolved with completion notes & photos!'),
          ),
          backgroundColor: status == 'Resolved' ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 3. Edit Existing Progress Log (Responsive: Dialog on Desktop matching EditLogModal.tsx, Sheet on Mobile)
  void _openEditLogModal(int index, ComplaintProgressUpdate update) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 740),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: _EditLogBottomSheet(
              logIndex: index,
              initialStatus: update.status,
              initialNote: update.note,
              initialImages: update.images,
              isDesktop: true,
              onSubmit: (note, status, images) async {
                Navigator.pop(ctx);
                final user = ref.read(currentUserProvider);
                final updaterName = user?.name ?? user?.email ?? update.updatedBy ?? 'Staff';

                setState(() {
                  final list = List<ComplaintProgressUpdate>.from(_complaint.progressUpdates);
                  if (index >= 0 && index < list.length) {
                    list[index] = ComplaintProgressUpdate(
                      note: note,
                      status: status,
                      timestamp: list[index].timestamp,
                      updatedBy: updaterName,
                      images: images,
                    );
                  }
                  _complaint = _complaint.copyWith(progressUpdates: list);
                });

                try {
                  await ref.read(complaintsRepoProvider).editProgressLog(
                        complaintId: _complaint.id,
                        logIndex: index,
                        note: note,
                        status: status,
                        updatedBy: updaterName,
                        images: images,
                      );
                } catch (_) {}
              },
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _EditLogBottomSheet(
          logIndex: index,
          initialStatus: update.status,
          initialNote: update.note,
          initialImages: update.images,
          isDesktop: false,
          onSubmit: (note, status, images) async {
            Navigator.pop(ctx);
            final user = ref.read(currentUserProvider);
            final updaterName = user?.name ?? user?.email ?? update.updatedBy ?? 'Staff';

            setState(() {
              final list = List<ComplaintProgressUpdate>.from(_complaint.progressUpdates);
              if (index >= 0 && index < list.length) {
                list[index] = ComplaintProgressUpdate(
                  note: note,
                  status: status,
                  timestamp: list[index].timestamp,
                  updatedBy: updaterName,
                  images: images,
                );
              }
              _complaint = _complaint.copyWith(progressUpdates: list);
            });

            try {
              await ref.read(complaintsRepoProvider).editProgressLog(
                    complaintId: _complaint.id,
                    logIndex: index,
                    note: note,
                    status: status,
                    updatedBy: updaterName,
                    images: images,
                  );
            } catch (_) {}
          },
        ),
      );
    }
  }

  // 4. Delete Log Confirmation (Desktop Dialog matching web vs Mobile AlertDialog)
  void _openDeleteLogDialog(int index) {
    final isMr = ref.read(isMarathiProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  isMr ? AppStrings.deleteLogConfirmTitleMr : AppStrings.deleteLogConfirmTitle,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  isMr ? AppStrings.deleteLogConfirmDescMr : AppStrings.deleteLogConfirmDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: Text(isMr ? AppStrings.cancelMr : AppStrings.cancel, style: const TextStyle(color: Color(0xFF475569))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() {
                            final list = List<ComplaintProgressUpdate>.from(_complaint.progressUpdates);
                            if (index >= 0 && index < list.length) {
                              list.removeAt(index);
                            }
                            _complaint = _complaint.copyWith(progressUpdates: list);
                          });
                          try {
                            await ref.read(complaintsRepoProvider).deleteProgressLog(
                                  complaintId: _complaint.id,
                                  logIndex: index,
                                );
                          } catch (_) {}
                        },
                        child: Text(isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Mobile fallback
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              isMr ? AppStrings.deleteLogConfirmTitleMr : AppStrings.deleteLogConfirmTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          isMr ? AppStrings.deleteLogConfirmDescMr : AppStrings.deleteLogConfirmDesc,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? AppStrings.cancelMr : AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                final list = List<ComplaintProgressUpdate>.from(_complaint.progressUpdates);
                if (index >= 0 && index < list.length) {
                  list.removeAt(index);
                }
                _complaint = _complaint.copyWith(progressUpdates: list);
              });
              try {
                await ref.read(complaintsRepoProvider).deleteProgressLog(
                      complaintId: _complaint.id,
                      logIndex: index,
                    );
              } catch (_) {}
            },
            child: Text(isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint),
          ),
        ],
      ),
    );
  }

  // 5. Edit Ticket Modal (Desktop modal dialog matching web vs Mobile AlertDialog)
  void _openEditTicketModal() {
    final isMr = ref.read(isMarathiProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final descController = TextEditingController(text: _complaint.description.isNotEmpty ? _complaint.description : _complaint.title);
    String selectedCategory = _complaint.category;

    final categories = ['Complaint', 'Help', 'Suggestion', 'Other', 'Personal Help', 'StreetLight', 'Cleaning', 'Water', 'Road', 'Drainage'];
    if (!categories.contains(selectedCategory)) {
      categories.insert(0, selectedCategory);
    }

    if (isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (dialogCtx) => StatefulBuilder(
          builder: (ctx, setModalState) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Container(
              width: 540,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isMr ? AppStrings.editModalTitleMr : AppStrings.editModalTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMr ? AppStrings.editDescriptionLabelMr : AppStrings.editDescriptionLabel,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter complaint description...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isMr ? AppStrings.editCategoryLabelMr : AppStrings.editCategoryLabel,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        AppDropdown<String>(
                          title: isMr ? 'वर्गवारी निवडा' : 'Select Category',
                          value: selectedCategory,
                          items: categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          ),
                          child: Text(isMr ? AppStrings.cancelMr : AppStrings.cancel, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final newText = descController.text.trim();
                            Navigator.pop(dialogCtx);
                            if (newText.isNotEmpty) {
                              setState(() {
                                _complaint = _complaint.copyWith(
                                  description: newText,
                                  title: newText.split('\n').first,
                                  category: selectedCategory,
                                );
                              });
                              try {
                                await ref.read(complaintsRepoProvider).updateComplaint(
                                      complaintId: _complaint.id,
                                      problem: newText,
                                      category: selectedCategory,
                                    );
                              } catch (_) {}
                            }
                          },
                          child: Text(isMr ? AppStrings.saveChangesMr : AppStrings.saveChanges, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    // Mobile view AlertDialog
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isMr ? AppStrings.editModalTitleMr : AppStrings.editModalTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMr ? AppStrings.editDescriptionLabelMr : AppStrings.editDescriptionLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter complaint description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isMr ? AppStrings.editCategoryLabelMr : AppStrings.editCategoryLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                AppDropdown<String>(
                  title: isMr ? 'वर्गवारी निवडा' : 'Select Category',
                  value: selectedCategory,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isMr ? AppStrings.cancelMr : AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final newText = descController.text.trim();
                Navigator.pop(ctx);
                if (newText.isNotEmpty) {
                  setState(() {
                    _complaint = _complaint.copyWith(
                      description: newText,
                      title: newText.split('\n').first,
                      category: selectedCategory,
                    );
                  });
                  try {
                    await ref.read(complaintsRepoProvider).updateComplaint(
                          complaintId: _complaint.id,
                          problem: newText,
                          category: selectedCategory,
                        );
                  } catch (_) {}
                }
              },
              child: Text(isMr ? AppStrings.saveChangesMr : AppStrings.saveChanges),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Delete Ticket Confirmation (Desktop Dialog matching web vs Mobile AlertDialog)
  void _openDeleteTicketDialog() {
    final isMr = ref.read(isMarathiProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  isMr ? AppStrings.deleteTicketConfirmTitleMr : AppStrings.deleteTicketConfirmTitle,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  isMr ? AppStrings.deleteTicketConfirmDescMr : AppStrings.deleteTicketConfirmDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: Text(isMr ? AppStrings.cancelMr : AppStrings.cancel, style: const TextStyle(color: Color(0xFF475569))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            await ref.read(complaintsRepoProvider).deleteComplaint(_complaint.id);
                          } catch (_) {}
                          if (mounted) {
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else {
                              Navigator.pop(context, true);
                            }
                          }
                        },
                        child: Text(isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Mobile view AlertDialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMr ? AppStrings.deleteTicketConfirmTitleMr : AppStrings.deleteTicketConfirmTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          isMr ? AppStrings.deleteTicketConfirmDescMr : AppStrings.deleteTicketConfirmDesc,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? AppStrings.cancelMr : AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(complaintsRepoProvider).deleteComplaint(_complaint.id);
              } catch (_) {}
              if (mounted) {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context, true); // Pop back to list with refresh signal
                }
              }
            },
            child: Text(isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint),
          ),
        ],
      ),
    );
  }

  // 7. Fullscreen Lightbox Image Viewer
  Future<void> _openLightbox(String rawUrl, String title) async {
    if (rawUrl.trim().isEmpty) return;
    String resolvedUrl = rawUrl.trim();
    if (!resolvedUrl.startsWith('data:') && !resolvedUrl.startsWith('blob:')) {
      resolvedUrl = await SupabaseService.instance.getSignedStorageUrl(resolvedUrl, bucket: 'documents');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Zoomable / Pannable Image
              SizedBox(
                width: size.width,
                height: size.height * 0.82,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildNetworkOrFileImage(
                        resolvedUrl,
                        fit: BoxFit.contain,
                        isLightbox: true,
                      ),
                    ),
                  ),
                ),
              ),

              // Close Button (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.pop(ctx),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),

              // Caption Badge (bottom)
              Positioned(
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Color theme generator based on Complaint Status (matching ComplaintDetail.tsx clsx logic)
  Color get _cardBgColor {
    final s = _complaint.status.toLowerCase();
    if (s == 'resolved' || s == 'closed') return const Color(0xFFF0FDF4); // bg-green-50
    if (s == 'inprogress' || s == 'assigned') return const Color(0xFFFEFCE8); // bg-yellow-50
    if (s == 'pending') return const Color(0xFFFEF2F2); // bg-red-50
    return Colors.white;
  }

  Color get _cardBorderColor {
    final s = _complaint.status.toLowerCase();
    if (s == 'resolved' || s == 'closed') return const Color(0xFF86EFAC); // border-green-300
    if (s == 'inprogress' || s == 'assigned') return const Color(0xFFFDE047); // border-yellow-300
    if (s == 'pending') return const Color(0xFFFCA5A5); // border-red-300
    return const Color(0xFFE2E8F0);
  }

  String _backButtonText(bool isMr) {
    if (_complaint.id.startsWith('ap-')) {
      return isMr ? 'प्रभाग समस्यांकडे परत' : 'Back to Ward Problems';
    } else if (_complaint.id.startsWith('pr-')) {
      return isMr ? 'वैयक्तिक विनंत्यांकडे परत' : 'Back to Personal Requests';
    } else {
      return isMr ? AppStrings.backToComplaintsMr : AppStrings.backToComplaints;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final user = ref.watch(currentUserProvider);
    final isAdminOrStaff = user?.role == 'admin' || user?.role == 'staff' || true; // Full access for nagarsevak app

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF8FAFC),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Enhanced Header Bar with Back, Edit, and Delete (Responsive, matching web)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, headerConstraints) {
                    final isWide = headerConstraints.maxWidth >= 600;

                    return Row(
                      children: [
                        // Back Button with circular icon
                        InkWell(
                          onTap: () {
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else {
                              Navigator.maybePop(context);
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF475569)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _backButtonText(isMr),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Edit, PDF Docket & Delete Actions
                        if (isAdminOrStaff)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppPdfButton.outlined(
                                label: 'Reports',
                                tooltip: 'Reports',
                                onPressed: () => ComplaintReportGenerator.generateAndPrintSingleComplaintDocket(_complaint),
                              ),
                              const SizedBox(width: 8),
                              if (isWide) ...[
                                OutlinedButton.icon(
                                  onPressed: _openEditTicketModal,
                                  icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF475569)),
                                  label: Text(
                                    isMr ? AppStrings.editComplaintMr : AppStrings.editComplaint,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _openDeleteTicketDialog,
                                  icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFDC2626)),
                                  label: Text(
                                    isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEF2F2),
                                    side: const BorderSide(color: Color(0xFFFECACA)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ] else ...[
                                IconButton(
                                  onPressed: _openEditTicketModal,
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF475569)),
                                  tooltip: isMr ? AppStrings.editComplaintMr : AppStrings.editComplaint,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.all(7),
                                    minimumSize: const Size(32, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: _openDeleteTicketDialog,
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                                  tooltip: isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint,
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEF2F2),
                                    side: const BorderSide(color: Color(0xFFFECACA)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.all(7),
                                    minimumSize: const Size(32, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Main Scrollable Content (Matching ComplaintDetail.tsx responsive 2-column layout)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshComplaint,
                  color: const Color(0xFF0284C7),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth >= 850;

                            if (isDesktop) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column (2/3 width): Ticket Overview + Progress History
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildTicketOverviewCard(isMr),
                                        const SizedBox(height: 20),
                                        _buildProgressHistorySection(isMr, isAdminOrStaff),
                                        const SizedBox(height: 32),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  // Right Column (1/3 width): Manage Ticket Actions + Ticket Details
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (isAdminOrStaff) ...[
                                          _buildManageTicketCard(isMr),
                                          const SizedBox(height: 20),
                                        ],
                                        _buildTicketDetailsCard(isMr),
                                        const SizedBox(height: 32),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Mobile / Compact Layout: Single column stacked
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTicketOverviewCard(isMr),
                                const SizedBox(height: 16),
                                _buildProgressHistorySection(isMr, isAdminOrStaff),
                                const SizedBox(height: 16),
                                if (isAdminOrStaff) ...[
                                  _buildManageTicketCard(isMr),
                                  const SizedBox(height: 16),
                                ],
                                _buildTicketDetailsCard(isMr),
                                const SizedBox(height: 32),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Ticket Overview Card
  Widget _buildTicketOverviewCard(bool isMr) {
    final categoryText = _complaint.category;
    final isPr = _complaint.id.startsWith('pr-');
    final isAp = _complaint.id.startsWith('ap-');
    final isHelp = isPr || categoryText.toLowerCase().contains('help') || categoryText.toLowerCase().contains('personal');

    String typeLabel = categoryText;
    if (isPr || isHelp) {
      typeLabel = isMr ? 'वैयक्तिक मदत' : 'Personal Help';
    } else if (isAp) {
      typeLabel = isMr ? 'प्रभाग समस्या' : 'Ward Problem';
    } else if (categoryText.toLowerCase() == 'complaint') {
      typeLabel = isMr ? 'तक्रार' : 'Complaint';
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Category Pill & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isHelp
                            ? const Color(0xFFF3E8FF)
                            : isAp
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isHelp
                              ? const Color(0xFF7E22CE)
                              : isAp
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(_complaint.status, isMr),
            ],
          ),

          const SizedBox(height: 14),

          // Title
          Text(
            _complaint.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 14),

          // Description Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              _complaint.description.isNotEmpty ? _complaint.description : _complaint.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ),

          // Attachments Section
          if (_complaint.attachments.isNotEmpty ||
              _complaint.photos.isNotEmpty ||
              _complaint.imageUrl != null ||
              _complaint.videoUrl != null) ...[
            const SizedBox(height: 16),
            _buildAttachmentsSection(isMr),
          ],

          const SizedBox(height: 16),

          // Location & Date Footer (matching ComplaintDetail.tsx)
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x18000000), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _complaint.location ?? _complaint.area ?? _complaint.ward ?? 'Prabhag Area',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('MMM d, yyyy h:mm a').format(_complaint.createdAt),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Attachments UI (Horizontal preview strip matching web preview layout)
  Widget _buildAttachmentsSection(bool isMr) {
    final allAttachments = <ComplaintAttachment>[];
    final seenUrls = <String>{};

    void addAttachment(ComplaintAttachment att) {
      final trimmed = att.url.trim();
      if (trimmed.isNotEmpty && !seenUrls.contains(trimmed)) {
        seenUrls.add(trimmed);
        allAttachments.add(att);
      }
    }

    // 1. Complaint attachments list
    for (final att in _complaint.attachments) {
      addAttachment(att);
    }

    // 2. Video URL if specified
    if (_complaint.videoUrl != null && _complaint.videoUrl!.trim().isNotEmpty) {
      addAttachment(ComplaintAttachment(
        url: _complaint.videoUrl!.trim(),
        type: 'video/mp4',
        name: 'Video',
      ));
    }

    // 3. Photos list
    for (final p in _complaint.photos) {
      addAttachment(ComplaintAttachment(
        url: p.trim(),
        type: 'image/jpeg',
        name: 'Photo',
      ));
    }

    // 4. Single imageUrl fallback
    if (_complaint.imageUrl != null && _complaint.imageUrl!.trim().isNotEmpty) {
      addAttachment(ComplaintAttachment(
        url: _complaint.imageUrl!.trim(),
        type: 'image/jpeg',
        name: 'Evidence Photo',
      ));
    }

    if (allAttachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attachments Header (matching ComplaintDetail.tsx)
        Row(
          children: [
            const Icon(Icons.description_outlined, size: 16, color: Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(
              '${isMr ? AppStrings.attachmentsMr : AppStrings.attachments} (${allAttachments.length})',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Preview Strip (compact, side-by-side previews matching web)
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allAttachments.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              return _buildAttachmentPreviewTile(allAttachments[idx], isMr, idx + 1);
            },
          ),
        ),
      ],
    );
  }

  // Individual Attachment Preview Tile (Video, Image, Audio, Document)
  Widget _buildAttachmentPreviewTile(ComplaintAttachment att, bool isMr, int index) {
    // 1. VIDEO ATTACHMENT (Embedded video player with HTML5 controls & thumbnail preview)
    if (att.isVideo) {
      return Container(
        width: 165,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: buildComplaintVideoPlayer(
          url: att.url,
          type: att.type,
          height: 110,
        ),
      );
    }

    // 2. IMAGE ATTACHMENT (Aspect ratio thumbnail with tap to open zoomable lightbox)
    if (att.isImage) {
      final caption = att.name.isNotEmpty ? att.name : 'Photo #$index';
      return InkWell(
        onTap: () => _openLightbox(att.url, caption),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 115,
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildNetworkOrFileImage(att.url, fit: BoxFit.cover),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. AUDIO ATTACHMENT
    if (att.isAudio) {
      return Container(
        width: 150,
        height: 110,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audiotrack_rounded, color: Color(0xFF0284C7), size: 30),
            const SizedBox(height: 6),
            Text(
              att.name.isNotEmpty ? att.name : 'Audio #$index',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // 4. DOCUMENT / PDF / OTHER ATTACHMENT
    return InkWell(
      onTap: () async {
        final signed = await SupabaseService.instance.getSignedStorageUrl(att.url, bucket: 'documents');
        final uri = Uri.tryParse(signed);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 125,
        height: 110,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              att.isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_outlined,
              color: att.isPdf ? const Color(0xFFDC2626) : const Color(0xFF64748B),
              size: 30,
            ),
            const SizedBox(height: 6),
            Text(
              att.name.isNotEmpty ? att.name : 'Document #$index',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 2. Progress History Section (Timeline matching ComplaintDetail.tsx)
  Widget _buildProgressHistorySection(bool isMr, bool isAdminOrStaff) {
    final updates = _complaint.progressUpdates;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Title & Add Log Button (matching ComplaintDetail.tsx lines 1115-1132)
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 19, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Text(
                      isMr ? AppStrings.progressHistoryMr : AppStrings.progressHistory,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                if (isAdminOrStaff)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openStatusModal(mode: 'InProgress', showStatusSelector: true),
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: const Color(0xFF0369A1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.28),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              isMr ? AppStrings.addLogMr : AppStrings.addLog,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (updates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  isMr ? AppStrings.noProgressUpdatesMr : AppStrings.noProgressUpdates,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pagedUpdates.length,
              itemBuilder: (ctx, idx) {
                final item = _pagedUpdates[idx];
                final isLast = idx == _pagedUpdates.length - 1;
                final isResolved = item.status.toLowerCase() == 'resolved';

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Column (Stem Line & Center Node Marker)
                      SizedBox(
                        width: 32,
                        child: Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isResolved ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x10000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isResolved ? Icons.check_rounded : Icons.edit_note_rounded,
                                size: 14,
                                color: isResolved ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Log Card
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Status Chip, Timestamp, Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isResolved ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isResolved ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
                                          ),
                                        ),
                                        child: Text(
                                          isResolved
                                              ? (isMr ? 'निवारण' : 'Resolved')
                                              : (isMr ? 'प्रगतीपथावर' : 'In Progress'),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isResolved ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(item.timestamp),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),

                                  if (isAdminOrStaff)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => _openEditLogModal(idx, item),
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        InkWell(
                                          onTap: () => _openDeleteLogDialog(idx),
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Note Text
                              Text(
                                item.note,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                  height: 1.4,
                                ),
                              ),

                              // Attached Thumbnails
                              if (item.images.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: item.images.map((img) {
                                    return InkWell(
                                      onTap: () => _openLightbox(img.url, img.name),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: _buildNetworkOrFileImage(img.url, fit: BoxFit.cover),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              // Updated By
                              if (item.updatedBy != null && item.updatedBy!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Updated by ${item.updatedBy}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            AppInlinePagination(
              currentPage: _updatePage,
              totalPages: _totalUpdatePages,
              totalItems: updates.length,
              pageSize: _updatePageSize,
              label: isMr ? 'नोंदी' : 'updates',
              onPageChanged: (page) => setState(() => _updatePage = page),
            ),
          ],
        ],
      ),
    );
  }

  // 3. Manage Ticket Card (Update Status & Assign Staff)
  Widget _buildManageTicketCard(bool isMr) {
    final isPr = _complaint.id.startsWith('pr-');
    final isInProgress = _complaint.status.toLowerCase() == 'inprogress';
    final isResolved = _complaint.status.toLowerCase() == 'resolved';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMr ? AppStrings.manageTicketMr : AppStrings.manageTicket,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),

          // UPDATE STATUS section
          Text(
            isMr ? AppStrings.updateStatusMr : AppStrings.updateStatus,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),

          // Mark as In Progress button
          if (!isPr) ...[
            InkWell(
              onTap: () => _openStatusModal(mode: 'InProgress'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isInProgress ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInProgress ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                    width: isInProgress ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: isInProgress ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isInProgress
                            ? (isMr ? AppStrings.updateWipMr : AppStrings.updateWip)
                            : (isMr ? AppStrings.markInProgressMr : AppStrings.markInProgress),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isInProgress ? FontWeight.w700 : FontWeight.w600,
                          color: isInProgress ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Mark as Resolved button
          InkWell(
            onTap: () => _openStatusModal(mode: 'Resolved'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isResolved ? const Color(0xFFECFDF5) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isResolved ? const Color(0xFF6EE7B7) : const Color(0xFFCBD5E1),
                  width: isResolved ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: isResolved ? const Color(0xFF047857) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isResolved
                          ? (isMr ? AppStrings.updateResolutionMr : AppStrings.updateResolution)
                          : (isMr ? AppStrings.markResolvedMr : AppStrings.markResolved),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isResolved ? FontWeight.w700 : FontWeight.w600,
                        color: isResolved ? const Color(0xFF047857) : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          // ASSIGN STAFF section
          // ASSIGN STAFF section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMr ? AppStrings.assignStaffMr : AppStrings.assignStaff,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              if (_isLoadingStaff)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          AppDropdown<String>(
            title: isMr ? AppStrings.selectStaffMr : AppStrings.selectStaff,
            value: _staffList.any((s) => s.id == _assignedStaffId) ? _assignedStaffId : null,
            hint: _isLoadingStaff
                ? (isMr ? 'कर्मचारी यादी लोड होत आहे...' : 'Loading staff...')
                : (_staffList.isEmpty
                    ? (isMr ? 'कोणतेही कर्मचारी उपलब्ध नाहीत' : 'No staff available')
                    : (isMr ? AppStrings.selectStaffMr : AppStrings.selectStaff)),
            items: _staffList.map((s) {
              return DropdownMenuItem<String>(
                value: s.id,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.role != null && s.role!.isNotEmpty)
                      Text(' (${s.role})', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final staff = _staffList.firstWhere((s) => s.id == val);
                _assignStaff(staff);
              }
            },
          ),
        ],
      ),
    );
  }

  // 4. Ticket Details / Citizen Card (Monochrome box matching ComplaintDetail.tsx)
  Widget _buildTicketDetailsCard(bool isMr) {
    final citizenName = _complaint.citizenName ?? (isMr ? AppStrings.anonymousMr : AppStrings.anonymous);
    final assignedName = _currentAssignedStaffName;
    final assignedMobile = _currentAssignedStaffMobile;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMr ? AppStrings.ticketDetailsMr : AppStrings.ticketDetails,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 12),

          // Ticket ID
          _buildDetailRow(
            label: isMr ? AppStrings.ticketIdMr : AppStrings.ticketId,
            valueWidget: Text(
              '#${_complaint.id}',
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
            ),
          ),

          // Citizen
          _buildDetailRow(
            label: isMr ? AppStrings.citizenMr : AppStrings.citizen,
            valueWidget: Text(
              citizenName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black),
            ),
          ),

          // Mobile & Quick actions
          if (_complaint.citizenMobile != null && _complaint.citizenMobile!.isNotEmpty)
            _buildDetailRow(
              label: isMr ? AppStrings.mobileMr : AppStrings.mobile,
              valueWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _complaint.citizenMobile!,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12.5, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('tel:${_complaint.citizenMobile}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () async {
                      final clean = _complaint.citizenMobile!.replaceAll(RegExp(r'\D'), '');
                      final text = Uri.encodeComponent(
                          'Namaskar, regarding your civic request "${_complaint.title}" (#${_complaint.id}), our office has updated the status.');
                      final uri = Uri.parse('https://wa.me/91$clean?text=$text');
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF6EE7B7)),
                      ),
                      child: const Icon(Icons.chat_rounded, size: 12, color: Color(0xFF059669)),
                    ),
                  ),
                ],
              ),
            ),

          // Assigned To
          _buildDetailRow(
            label: isMr ? AppStrings.assignedToMr : AppStrings.assignedTo,
            valueWidget: assignedName.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        assignedName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
                      ),
                      if (assignedMobile.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Text(
                              assignedMobile,
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                    ],
                  )
                : Text(
                    isMr ? AppStrings.unassignedMr : AppStrings.unassigned,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 13),
                  ),
          ),

          // Added By
          if (_complaint.addedByStaffName != null && _complaint.addedByStaffName!.isNotEmpty)
            _buildDetailRow(
              label: isMr ? AppStrings.addedByMr : AppStrings.addedBy,
              valueWidget: Text(
                _complaint.addedByStaffName!,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black),
              ),
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required Widget valueWidget, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          valueWidget,
        ],
      ),
    );
  }

  // Status Badge matching web design colors
  Widget _buildStatusBadge(String status, bool isMr) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        bg = const Color(0xFFDCFCE7); // bg-green-100
        border = const Color(0xFFBBF7D0); // border-green-200
        text = const Color(0xFF166534); // text-green-800
        label = isMr ? 'निवारण' : 'Resolved';
        break;
      case 'inprogress':
        bg = const Color(0xFFDBEAFE); // bg-blue-100
        border = const Color(0xFFBFDBFE); // border-blue-200
        text = const Color(0xFF1E40AF); // text-blue-800
        label = isMr ? 'प्रगतीपथावर' : 'In Progress';
        break;
      case 'assigned':
        bg = const Color(0xFFF3E8FF); // bg-purple-100
        border = const Color(0xFFE9D5FF); // border-purple-200
        text = const Color(0xFF6B21A8); // text-purple-800
        label = isMr ? 'नियुक्त' : 'Assigned';
        break;
      default:
        bg = const Color(0xFFFEF2F2); // bg-red-50
        border = const Color(0xFFFECACA); // border-red-100
        text = const Color(0xFFB91C1C); // text-red-700
        label = isMr ? 'प्रलंबित' : 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }

  // Safe image builder for Network vs Local File vs Base64 URLs
  Widget _buildNetworkOrFileImage(
    String pathOrUrl, {
    BoxFit fit = BoxFit.cover,
    bool isLightbox = false,
  }) {
    final clean = pathOrUrl.trim();
    if (clean.isEmpty) {
      return _imagePlaceholder(isLightbox: isLightbox);
    }

    // 1. Base64 Data URI
    if (clean.startsWith('data:image/') && clean.contains(',')) {
      try {
        final base64Str = clean.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _imagePlaceholder(
            isLightbox: isLightbox,
            message: 'Invalid image data',
          ),
        );
      } catch (_) {
        return _imagePlaceholder(
          isLightbox: isLightbox,
          message: 'Could not render image',
        );
      }
    }

    // 2. Blob URL
    if (clean.startsWith('blob:')) {
      return _rawNetworkImage(clean, fit: fit, isLightbox: isLightbox);
    }

    // 3. Already valid signed URL with token
    if (clean.contains('/object/sign/') && clean.contains('token=')) {
      return _rawNetworkImage(clean, fit: fit, isLightbox: isLightbox);
    }

    // 4. Non-Supabase external URL
    if (clean.startsWith('http') && !clean.contains('.supabase.co/storage/v1/object/')) {
      return _rawNetworkImage(clean, fit: fit, isLightbox: isLightbox);
    }

    // 5. Local file (Mobile/Desktop only)
    if (!kIsWeb && clean.startsWith('/')) {
      return Image.file(
        File(clean),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(isLightbox: isLightbox),
      );
    }

    // 6. Asynchronously resolve signed URL for relative path or Supabase public URL
    return FutureBuilder<String>(
      future: SupabaseService.instance.getSignedStorageUrl(clean, bucket: 'documents'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: isLightbox ? Colors.black26 : const Color(0xFFF1F5F9),
            child: Center(
              child: SizedBox(
                width: isLightbox ? 32 : 18,
                height: isLightbox ? 32 : 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isLightbox ? Colors.white70 : const Color(0xFF0284C7),
                ),
              ),
            ),
          );
        }
        final signed = (snapshot.hasData && snapshot.data!.isNotEmpty) ? snapshot.data! : clean;
        return _rawNetworkImage(signed, fit: fit, isLightbox: isLightbox);
      },
    );
  }

  Widget _rawNetworkImage(String url, {required BoxFit fit, required bool isLightbox}) {
    if (!url.startsWith('http') && !url.startsWith('blob:')) {
      return _imagePlaceholder(isLightbox: isLightbox);
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: isLightbox ? Colors.black26 : const Color(0xFFF1F5F9),
          child: Center(
            child: SizedBox(
              width: isLightbox ? 32 : 18,
              height: isLightbox ? 32 : 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null && loadingProgress.expectedTotalBytes! > 0
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: isLightbox ? Colors.white70 : const Color(0xFF0284C7),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _imagePlaceholder(
        isLightbox: isLightbox,
        message: 'Image unavailable',
      ),
    );
  }

  Widget _imagePlaceholder({bool isLightbox = false, String message = ''}) {
    if (isLightbox) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              message.isNotEmpty ? message : 'Image could not be loaded',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 24),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATUS UPDATE MODAL / BOTTOM SHEET (matching StatusUpdateModal.tsx)
// -----------------------------------------------------------------------------
class _StatusUpdateBottomSheet extends StatefulWidget {
  final String initialMode; // 'InProgress' or 'Resolved'
  final bool showStatusSelector;
  final String complaintTitle;
  final bool isDesktop;
  final Function(String note, String status, List<ComplaintAttachment> images) onSubmit;

  const _StatusUpdateBottomSheet({
    required this.initialMode,
    required this.showStatusSelector,
    required this.complaintTitle,
    this.isDesktop = false,
    required this.onSubmit,
  });

  @override
  State<_StatusUpdateBottomSheet> createState() => _StatusUpdateBottomSheetState();
}

class _StatusUpdateBottomSheetState extends State<_StatusUpdateBottomSheet> {
  late String _status;
  final TextEditingController _noteController = TextEditingController();
  List<XFile> _selectedFiles = [];
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialMode;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = _status == 'InProgress';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDesktop = widget.isDesktop;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: isDesktop ? 0 : bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop ? BorderRadius.circular(16) : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Desktop clean styling vs Mobile drag handle header)
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isInProgress ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isInProgress ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Icon(
                          isInProgress ? Icons.access_time_rounded : Icons.check_circle_outline_rounded,
                          color: isInProgress ? const Color(0xFF1D4ED8) : const Color(0xFF047857),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isInProgress ? 'Add Progress Log' : 'Add Resolution Log',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          if (widget.complaintTitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.complaintTitle,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            )
          else
            AppModalHeader(
              icon: Icons.published_with_changes_rounded,
              title: isInProgress ? 'Update Work In Progress' : 'Mark Complaint Resolved',
              subtitle: widget.complaintTitle,
              onClose: () => Navigator.pop(context),
            ),

          // Scrollable Body
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.showStatusSelector) ...[
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
                            onTap: () => setState(() => _status = 'InProgress'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isInProgress ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isInProgress
                                    ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'In Progress',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isInProgress ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _status = 'Resolved'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isInProgress ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !isInProgress
                                    ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Resolved',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: !isInProgress ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                AppFieldLabel(
                  label: isInProgress ? 'Work Progress Note' : 'Resolution Details & Remarks',
                  isRequired: true,
                ),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isInProgress
                        ? 'Describe ongoing work, actions taken, materials used...'
                        : 'Describe how the issue was completely resolved, inspection done...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
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
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 14),

                AppImagePickerField(
                  label: 'Attach Photos / Videos (Optional)',
                  allowMultiple: true,
                  initialFiles: _selectedFiles,
                  onFilesChanged: (files) {
                    setState(() => _selectedFiles = files);
                  },
                ),

                if (!isDesktop) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  final note = _noteController.text.trim();
                                  if (note.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter progress remarks.')),
                                    );
                                    return;
                                  }
                                  final attachments = _selectedFiles.map((f) => ComplaintAttachment(
                                    url: f.path,
                                    type: 'image/jpeg',
                                    name: f.name,
                                  )).toList();
                                  widget.onSubmit(note, _status, attachments);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInProgress ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isInProgress ? 'Save Progress' : 'Mark Resolved',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Desktop Footer (matching StatusUpdateModal.tsx lines 452-484)
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            final note = _noteController.text.trim();
                            if (note.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter progress remarks.')),
                              );
                              return;
                            }
                            final attachments = _selectedFiles.map((f) => ComplaintAttachment(
                              url: f.path,
                              type: 'image/jpeg',
                              name: f.name,
                            )).toList();
                            widget.onSubmit(note, _status, attachments);
                          },
                    icon: Icon(
                      isInProgress ? Icons.access_time_rounded : Icons.check_circle_outline_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isInProgress ? 'Save Progress' : 'Save Resolution',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInProgress ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EDIT LOG MODAL / BOTTOM SHEET (matching EditLogModal.tsx)
// -----------------------------------------------------------------------------
class _EditLogBottomSheet extends StatefulWidget {
  final int logIndex;
  final String initialStatus;
  final String initialNote;
  final List<ComplaintAttachment> initialImages;
  final bool isDesktop;
  final Function(String note, String status, List<ComplaintAttachment> images) onSubmit;

  const _EditLogBottomSheet({
    required this.logIndex,
    required this.initialStatus,
    required this.initialNote,
    required this.initialImages,
    this.isDesktop = false,
    required this.onSubmit,
  });

  @override
  State<_EditLogBottomSheet> createState() => _EditLogBottomSheetState();
}

class _EditLogBottomSheetState extends State<_EditLogBottomSheet> {
  late String _status;
  late TextEditingController _noteController;
  late List<ComplaintAttachment> _images;
  List<XFile> _newFiles = [];

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _noteController = TextEditingController(text: widget.initialNote);
    _images = List.from(widget.initialImages);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = _status == 'InProgress';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDesktop = widget.isDesktop;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: isDesktop ? 0 : bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop ? BorderRadius.circular(16) : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Color(0xFF1D4ED8), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Progress Log',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isInProgress ? 'Status: In Progress' : 'Status: Resolved',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            )
          else
            AppModalHeader(
              icon: Icons.edit_note_rounded,
              title: 'Edit Progress Log',
              subtitle: isInProgress ? 'Status: In Progress' : 'Status: Resolved',
              onClose: () => Navigator.pop(context),
            ),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                // Status Selector Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _status = 'InProgress'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isInProgress ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isInProgress ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'In Progress',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isInProgress ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _status = 'Resolved'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !isInProgress ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !isInProgress ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Resolved',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: !isInProgress ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const AppFieldLabel(label: 'Log Note', isRequired: true),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter log description...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 14),

                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final img = _images[idx];
                        return Stack(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: img.url.startsWith('/')
                                  ? Image.file(File(img.url), fit: BoxFit.cover)
                                  : Image.network(img.url, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _images.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                AppImagePickerField(
                  label: 'Add More Photos',
                  allowMultiple: true,
                  initialFiles: _newFiles,
                  onFilesChanged: (files) {
                    setState(() => _newFiles = files);
                  },
                ),

                if (!isDesktop) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final note = _noteController.text.trim();
                            if (note.isEmpty) return;
                            final allAttachments = List<ComplaintAttachment>.from(_images);
                            for (final f in _newFiles) {
                              allAttachments.add(ComplaintAttachment(
                                url: f.path,
                                type: 'image/jpeg',
                                name: f.name,
                              ));
                            }
                            widget.onSubmit(note, _status, allAttachments);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      final note = _noteController.text.trim();
                      if (note.isEmpty) return;
                      final allAttachments = List<ComplaintAttachment>.from(_images);
                      for (final f in _newFiles) {
                        allAttachments.add(ComplaintAttachment(
                          url: f.path,
                          type: 'image/jpeg',
                          name: f.name,
                        ));
                      }
                      widget.onSubmit(note, _status, allAttachments);
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

