import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../providers/auth_provider.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
  });

  @override
  ConsumerState<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  late ComplaintModel _complaint;
  List<StaffModel> _staffList = [];
  String? _assignedStaffId;

  // Fallback Mock Staff List matching web version
  final List<StaffModel> _defaultStaffList = [
    StaffModel(id: 'staff-1', name: 'Sunil Shinde', role: 'Electrical JE', mobile: '9822012345'),
    StaffModel(id: 'staff-2', name: 'Santosh Gaikwad', role: 'Sanitation Supervisor', mobile: '9822023456'),
    StaffModel(id: 'staff-3', name: 'Pradeep Joshi', role: 'Water Works Dept', mobile: '9822034567'),
    StaffModel(id: 'staff-4', name: 'Anand Jadhav', role: 'Road Engineering', mobile: '9822045678'),
    StaffModel(id: 'staff-5', name: 'Prashant Kadam', role: 'Welfare Desk', mobile: '9822056789'),
  ];

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _assignedStaffId = _complaint.assignedTo;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _staffList = List.from(_defaultStaffList);
    try {
      final repo = ref.read(complaintsRepoProvider);
      final staff = await repo.getStaffList();
      if (staff.isNotEmpty && mounted) {
        setState(() {
          _staffList = staff;
        });
      }

      // Re-fetch complaint by ID from Supabase if connected
      final fresh = await repo.getComplaintById(_complaint.id);
      if (fresh != null && mounted) {
        setState(() {
          _complaint = fresh;
          _assignedStaffId = fresh.assignedTo ?? _assignedStaffId;
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

  // 2. Add / Update Status Modal
  void _openStatusModal({required String mode, bool showStatusSelector = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StatusUpdateBottomSheet(
        initialMode: mode,
        showStatusSelector: showStatusSelector,
        complaintTitle: _complaint.title,
        onSubmit: (note, status, images) async {
          Navigator.pop(ctx);
          await _handleSaveProgressLog(note, status, images);
        },
      ),
    );
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

  // 3. Edit Existing Progress Log
  void _openEditLogModal(int index, ComplaintProgressUpdate update) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditLogBottomSheet(
        logIndex: index,
        initialStatus: update.status,
        initialNote: update.note,
        initialImages: update.images,
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

  // 4. Delete Log Confirmation
  void _openDeleteLogDialog(int index) {
    final isMr = ref.read(isMarathiProvider);
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

  // 5. Edit Ticket Modal
  void _openEditTicketModal() {
    final isMr = ref.read(isMarathiProvider);
    final descController = TextEditingController(text: _complaint.description.isNotEmpty ? _complaint.description : _complaint.title);
    String selectedCategory = _complaint.category;

    final categories = ['Complaint', 'Help', 'Suggestion', 'Other', 'Personal Help', 'StreetLight', 'Cleaning', 'Water', 'Road', 'Drainage'];
    if (!categories.contains(selectedCategory)) {
      categories.insert(0, selectedCategory);
    }

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCategory,
                      items: categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                  ),
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

  // 6. Delete Ticket Confirmation
  void _openDeleteTicketDialog() {
    final isMr = ref.read(isMarathiProvider);
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
                Navigator.pop(context, true); // Pop back to list with refresh signal
              }
            },
            child: Text(isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint),
          ),
        ],
      ),
    );
  }

  // 7. Fullscreen Lightbox Image Viewer
  void _openLightbox(String url, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildNetworkOrFileImage(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: const CircleBorder(),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
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
              // Enhanced Header Bar with Back, Edit, and Delete (matching ComplaintDetail.tsx)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button with circular icon
                    InkWell(
                      onTap: () => Navigator.pop(context),
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
                              isMr ? AppStrings.backToComplaintsMr : AppStrings.backToComplaints,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Edit & Delete Actions
                    if (isAdminOrStaff)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _openEditTicketModal,
                            icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF475569)),
                            label: Text(
                              isMr ? AppStrings.editComplaintMr : AppStrings.editComplaint,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _openDeleteTicketDialog,
                            icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                            label: Text(
                              isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top Ticket Overview Card (Dynamic Colored Card matching ComplaintDetail.tsx)
                      _buildTicketOverviewCard(isMr),

                      const SizedBox(height: 16),

                      // 2. Progress History Section (Timeline matching ComplaintDetail.tsx)
                      _buildProgressHistorySection(isMr, isAdminOrStaff),

                      const SizedBox(height: 16),

                      // 3. Manage Ticket Actions Card (Status toggles & Assign Staff)
                      if (isAdminOrStaff) ...[
                        _buildManageTicketCard(isMr),
                        const SizedBox(height: 16),
                      ],

                      // 4. Ticket Details / Citizen Card (Monochrome box matching ComplaintDetail.tsx)
                      _buildTicketDetailsCard(isMr),

                      const SizedBox(height: 32),
                    ],
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
    final isHelp = categoryText.toLowerCase().contains('help') || categoryText.toLowerCase().contains('personal');

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
      padding: const EdgeInsets.all(18),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHelp ? const Color(0xFFF3E8FF) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        categoryText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isHelp ? const Color(0xFF7E22CE) : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(_complaint.status, isMr),
            ],
          ),

          const SizedBox(height: 10),

          // Title
          Text(
            _complaint.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // Description Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
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
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
                height: 1.45,
              ),
            ),
          ),

          // Attachments Section
          if (_complaint.attachments.isNotEmpty || _complaint.photos.isNotEmpty || _complaint.imageUrl != null) ...[
            const SizedBox(height: 16),
            _buildAttachmentsSection(isMr),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0x1A000000)),
          const SizedBox(height: 12),

          // Location & Date Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _complaint.location ?? _complaint.area ?? _complaint.ward ?? 'Prabhag Area',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy, h:mm a').format(_complaint.createdAt),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Attachments UI (Images, Videos, Docs)
  Widget _buildAttachmentsSection(bool isMr) {
    final allImages = <String>[];
    if (_complaint.attachments.isNotEmpty) {
      for (final att in _complaint.attachments) {
        if (att.isImage && att.url.isNotEmpty) allImages.add(att.url);
      }
    }
    if (allImages.isEmpty) {
      for (final p in _complaint.photos) {
        if (p.isNotEmpty) allImages.add(p);
      }
      if (_complaint.imageUrl != null && _complaint.imageUrl!.isNotEmpty) {
        allImages.add(_complaint.imageUrl!);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, size: 16, color: Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(
              '${isMr ? AppStrings.attachmentsMr : AppStrings.attachments} (${allImages.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final imgUrl = allImages[idx];
              return InkWell(
                onTap: () => _openLightbox(imgUrl, 'Attachment #${idx + 1}'),
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildNetworkOrFileImage(imgUrl, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
          // Section Header: Title & Add Log Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Text(
                    isMr ? AppStrings.progressHistoryMr : AppStrings.progressHistory,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (isAdminOrStaff)
                ElevatedButton.icon(
                  onPressed: () => _openStatusModal(mode: 'InProgress', showStatusSelector: true),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: Text(
                    isMr ? AppStrings.addLogMr : AppStrings.addLog,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
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
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: updates.length,
              itemBuilder: (ctx, idx) {
                final item = updates[idx];
                final isLast = idx == updates.length - 1;
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
          Text(
            isMr ? AppStrings.assignStaffMr : AppStrings.assignStaff,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _staffList.any((s) => s.id == _assignedStaffId) ? _assignedStaffId : null,
                hint: Text(
                  isMr ? AppStrings.selectStaffMr : AppStrings.selectStaff,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
                items: _staffList.map((s) {
                  return DropdownMenuItem<String>(
                    value: s.id,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        if (s.role != null)
                          Text('(${s.role})', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
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
            ),
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

  // Safe image builder for Network vs Local File URLs
  Widget _buildNetworkOrFileImage(String pathOrUrl, {BoxFit fit = BoxFit.cover}) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    } else if (pathOrUrl.startsWith('/')) {
      return Image.file(
        File(pathOrUrl),
        fit: fit,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    } else {
      return _imagePlaceholder();
    }
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 24),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATUS UPDATE BOTTOM SHEET (matching StatusUpdateModal.tsx)
// -----------------------------------------------------------------------------
class _StatusUpdateBottomSheet extends StatefulWidget {
  final String initialMode; // 'InProgress' or 'Resolved'
  final bool showStatusSelector;
  final String complaintTitle;
  final Function(String note, String status, List<ComplaintAttachment> images) onSubmit;

  const _StatusUpdateBottomSheet({
    required this.initialMode,
    required this.showStatusSelector,
    required this.complaintTitle,
    required this.onSubmit,
  });

  @override
  State<_StatusUpdateBottomSheet> createState() => _StatusUpdateBottomSheetState();
}

class _StatusUpdateBottomSheetState extends State<_StatusUpdateBottomSheet> {
  late String _status;
  final TextEditingController _noteController = TextEditingController();
  final List<ComplaintAttachment> _selectedImages = [];
  bool _isSaving = false;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        setState(() {
          _selectedImages.add(
            ComplaintAttachment(
              url: file.path,
              type: 'image/jpeg',
              name: file.name,
            ),
          );
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = _status == 'InProgress';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Center Drag Bar
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
            const SizedBox(height: 14),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isInProgress ? 'Update Work In Progress' : 'Mark Complaint Resolved',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Status Selector Tabs (if showStatusSelector is true)
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

            // Note Text Area
            Text(
              isInProgress ? 'Work Progress Note *' : 'Resolution Details & Completion Remarks *',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: isInProgress
                    ? 'Describe ongoing work, materials used, estimated completion...'
                    : 'Describe how the issue was resolved, inspection done, verified...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 14),

            // Photos / Media Upload Section
            const Text(
              'Attach Site Evidence Photos',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Camera', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Gallery', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            // Previews of selected images
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final img = _selectedImages[idx];
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
                            onTap: () => setState(() => _selectedImages.removeAt(idx)),
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

            const SizedBox(height: 20),

            // Submit Buttons
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
                            widget.onSubmit(note, _status, _selectedImages);
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
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EDIT LOG BOTTOM SHEET (matching EditLogModal.tsx)
// -----------------------------------------------------------------------------
class _EditLogBottomSheet extends StatefulWidget {
  final int logIndex;
  final String initialStatus;
  final String initialNote;
  final List<ComplaintAttachment> initialImages;
  final Function(String note, String status, List<ComplaintAttachment> images) onSubmit;

  const _EditLogBottomSheet({
    required this.logIndex,
    required this.initialStatus,
    required this.initialNote,
    required this.initialImages,
    required this.onSubmit,
  });

  @override
  State<_EditLogBottomSheet> createState() => _EditLogBottomSheetState();
}

class _EditLogBottomSheetState extends State<_EditLogBottomSheet> {
  late String _status;
  late TextEditingController _noteController;
  late List<ComplaintAttachment> _images;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        setState(() {
          _images.add(
            ComplaintAttachment(
              url: file.path,
              type: 'image/jpeg',
              name: file.name,
            ),
          );
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = _status == 'InProgress';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Progress Log', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),

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
            const Text('Log Note *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 14),
            const Text('Manage Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Add Camera Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Add Gallery Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            if (_images.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
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

            const SizedBox(height: 20),

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
                      widget.onSubmit(note, _status, _images);
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
        ),
      ),
    );
  }
}

