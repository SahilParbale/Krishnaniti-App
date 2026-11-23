import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/voter_application_model.dart';
import '../../../../data/repositories/voter_applications_repository.dart';

class DesktopVoterFormsView extends ConsumerStatefulWidget {
  const DesktopVoterFormsView({super.key});

  @override
  ConsumerState<DesktopVoterFormsView> createState() => _DesktopVoterFormsViewState();
}

class _DesktopVoterFormsViewState extends ConsumerState<DesktopVoterFormsView> {
  bool _loading = true;
  List<VoterApplicationModel> _applications = [];
  String _searchTerm = '';
  String _selectedStatus = 'All';
  String _selectedFormType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(voterApplicationsRepoProvider);
      final list = await repo.getApplications(
        searchQuery: _searchTerm,
        statusFilter: _selectedStatus,
        formTypeFilter: _selectedFormType,
      );
      if (mounted) {
        setState(() {
          _applications = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _applications = [];
          _loading = false;
        });
      }
    }
  }

  void _showAddModal({VoterApplicationModel? item}) {
    final nameController = TextEditingController(text: item?.applicantName ?? '');
    final mobileController = TextEditingController(text: item?.applicantMobile ?? '');
    final notesController = TextEditingController(text: item?.notes ?? '');
    String formType = item?.formType ?? 'Form 6';
    String status = item?.status ?? 'Submitted';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 540,
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == null ? 'Log New Application' : 'Edit Application',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Applicant Name
                    const Text('Applicant Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Sagar R. Shinde...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mobile & Form Type
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mobile Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mobileController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '98XXXXXXXX',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Form Type *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: formType,
                                items: const [
                                  DropdownMenuItem(value: 'Form 6', child: Text('Form 6 (New Voter)')),
                                  DropdownMenuItem(value: 'Form 7', child: Text('Form 7 (Objection / Deletion)')),
                                  DropdownMenuItem(value: 'Form 8', child: Text('Form 8 (Correction)')),
                                  DropdownMenuItem(value: 'Search', child: Text('Search in Voter List')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => formType = val);
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status
                    const Text('Application Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'Submitted', child: Text('Submitted')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const Text('Reference No. & Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'ECI application reference no. or notes...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            final newApp = VoterApplicationModel(
                              id: item?.id ?? 'app-${DateTime.now().millisecondsSinceEpoch}',
                              applicantName: nameController.text.trim(),
                              applicantMobile: mobileController.text.trim().isNotEmpty ? mobileController.text.trim() : null,
                              formType: formType,
                              status: status,
                              notes: notesController.text.trim(),
                              createdAt: item?.createdAt ?? DateTime.now(),
                            );

                            final repo = ref.read(voterApplicationsRepoProvider);
                            if (item == null) {
                              await repo.addApplication(newApp);
                            } else {
                              await repo.updateApplication(newApp);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchApplications();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          ),
                          child: Text(item == null ? 'Submit Application' : 'Save Changes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
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

  void _showDeleteConfirm(VoterApplicationModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Application'),
        content: Text('Are you sure you want to delete application for "${item.applicantName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(voterApplicationsRepoProvider);
              await repo.deleteApplication(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchApplications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(_applications.length),
          const SizedBox(height: 20),

          // 4 Action Link Cards matching VoterForms.tsx
          _buildActionCards(),
          const SizedBox(height: 24),

          // Filter Row
          _buildFilterRow(),
          const SizedBox(height: 24),

          // Table / Grid of logged applications
          if (_loading)
            _buildLoadingState()
          else
            _buildApplicationsTable(),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Voter Forms',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text('Total: $count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Form 6 (New Voter), Form 7 (Deletion), Form 8 (Correction) and ECI application tracker',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Add Button
        ElevatedButton.icon(
          onPressed: () => _showAddModal(),
          icon: const Icon(Icons.note_add_outlined, size: 18, color: Colors.white),
          label: const Text('+ New Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildFormActionCard(
            title: 'Search in Voter List',
            subtitle: 'Electoral Search (ECI)',
            color: const Color(0xFFEA580C),
            bg: const Color(0xFFFFF7ED),
            icon: Icons.search_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildFormActionCard(
            title: 'Form 6: New Registration',
            subtitle: 'New Voter Registration',
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFF0F9FF),
            icon: Icons.person_add_alt_1_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildFormActionCard(
            title: 'Form 7: Objection / Deletion',
            subtitle: 'Deletion / Objection',
            color: const Color(0xFFDC2626),
            bg: const Color(0xFFFEF2F2),
            icon: Icons.person_remove_alt_1_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildFormActionCard(
            title: 'Form 8: Correction of Entries',
            subtitle: 'Modification / Shifting',
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFF0FDF4),
            icon: Icons.how_to_reg_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildFormActionCard({
    required String title,
    required String subtitle,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) {
                _searchTerm = val;
                _fetchApplications();
              },
              decoration: const InputDecoration(
                hintText: 'Search applicant by name, mobile, reference no...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Status Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedStatus,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Status', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'Submitted', child: Text('Submitted', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'Approved', child: Text('Approved', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'Rejected', child: Text('Rejected', style: TextStyle(fontSize: 12))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatus = val);
                _fetchApplications();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsTable() {
    if (_applications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: const [
            Icon(Icons.description_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No applications found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: const [
            const DataColumn(label: Text('Applicant Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Form Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
          ],
          rows: _applications.map((app) {
            final formattedDate = DateFormat('dd/MM/yyyy').format(app.createdAt);

            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(app.applicantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      if (app.notes != null && app.notes!.isNotEmpty)
                        Text(app.notes!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                DataCell(Text(app.applicantMobile ?? '-', style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(4)),
                    child: Text(app.formTypeMarathi, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: app.statusBgColor, borderRadius: BorderRadius.circular(100), border: Border.all(color: app.statusBorderColor)),
                    child: Text(app.statusMarathi, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: app.statusColor)),
                  ),
                ),
                DataCell(Text(formattedDate, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showAddModal(item: app)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)), onPressed: () => _showDeleteConfirm(app)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(height: 240, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2.5));
  }
}
