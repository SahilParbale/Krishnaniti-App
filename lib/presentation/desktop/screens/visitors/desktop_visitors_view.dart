import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nagarsevak_mobile/data/models/visitor_model.dart';
import 'package:nagarsevak_mobile/data/repositories/visitors_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';

/// Desktop Visitor Log View matching VisitorLog.tsx verbatim:
/// - Sticky Header: Title + Subtitle + Help button
/// - 3-Column Layout:
///   - Left 1/3: Sticky Check-in / Registration Form (Name, Mobile, Area, Purpose, Reference, Remarks)
///   - Right 2/3: Search Toolbar + Grid/Report view toggles + Visitor Cards Grid / Data Table
class DesktopVisitorsView extends ConsumerStatefulWidget {
  const DesktopVisitorsView({super.key});

  @override
  ConsumerState<DesktopVisitorsView> createState() => _DesktopVisitorsViewState();
}

class _DesktopVisitorsViewState extends ConsumerState<DesktopVisitorsView> {
  String _viewMode = 'grid'; // 'grid' | 'report'
  String _searchQuery = '';
  String _selectedArea = 'All';
  String _purposeFilter = 'All';

  // Form State
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String _selectedPurpose = 'Complaint';
  String? _editingId;

  bool _loading = true;
  List<VisitorModel> _visitors = [];

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _areaCtrl.dispose();
    _referenceCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVisitors() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(visitorsRepoProvider);
      final list = await repo.getVisitors();
      if (mounted) {
        setState(() {
          _visitors = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _uniqueAreas {
    final areas = <String>{};
    for (final v in _visitors) {
      if (v.area != null && v.area!.trim().isNotEmpty) {
        areas.add(v.area!.trim());
      }
    }
    final sorted = areas.toList()..sort();
    return ['All', ...sorted];
  }

  List<VisitorModel> get _filteredVisitors {
    return _visitors.where((v) {
      if (_selectedArea != 'All' && v.area != _selectedArea) {
        return false;
      }
      if (_purposeFilter != 'All' && v.purpose.toLowerCase() != _purposeFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchName = v.name.toLowerCase().contains(q);
        final matchPhone = v.mobile.contains(q);
        final matchRemarks = (v.remarks ?? '').toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchRemarks) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _handleSaveVisitor() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final repo = ref.read(visitorsRepoProvider);

    if (_editingId != null) {
      await repo.updateVisitor(_editingId!, {
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'purpose': _selectedPurpose,
        'reference': _referenceCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
      });
      _resetForm();
    } else {
      final newVisitor = VisitorModel(
        id: '',
        name: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        purpose: _selectedPurpose,
        area: _areaCtrl.text.trim(),
        reference: _referenceCtrl.text.trim(),
        remarks: _remarksCtrl.text.trim(),
        visitDate: DateTime.now(),
      );
      await repo.addVisitor(newVisitor);
      _resetForm();
    }
    _loadVisitors();
  }

  void _resetForm() {
    _nameCtrl.clear();
    _mobileCtrl.clear();
    _areaCtrl.clear();
    _referenceCtrl.clear();
    _remarksCtrl.clear();
    setState(() {
      _selectedPurpose = 'Complaint';
      _editingId = null;
    });
  }

  void _startEdit(VisitorModel visitor) {
    setState(() {
      _editingId = visitor.id;
      _nameCtrl.text = visitor.name;
      _mobileCtrl.text = visitor.mobile;
      _areaCtrl.text = visitor.area ?? '';
      _referenceCtrl.text = visitor.reference ?? '';
      _remarksCtrl.text = visitor.remarks ?? '';
      _selectedPurpose = visitor.purpose;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final isMr = lang == 'mr';
    final items = _filteredVisitors;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (matching VisitorLog.tsx lines 380-405)
            _buildHeader(isMr),

            const SizedBox(height: 20),

            // 2. 3-Column Layout: Left 1/3 Form + Right 2/3 List (matching lines 407-1000)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left 1/3: Check-in Form Card
                Expanded(
                  flex: 1,
                  child: _buildCheckInForm(isMr),
                ),

                const SizedBox(width: 24),

                // Right 2/3: Search Bar + View Toggle + Grid / Report
                Expanded(
                  flex: 2,
                  child: _buildLogContainer(items, isMr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(bool isMr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 26, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Text(
                  'Visitor Log',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isMr
                  ? 'Log and manage citizens visiting the ward office'
                  : 'Track office visitors, appointments and follow-ups',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.help_outline_rounded, size: 18, color: Color(0xFF0284C7)),
          label: Text(
            'Help',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFBAE6FD)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  // --- Left 1/3: Check-in Form Card (matching VisitorLog.tsx lines 409-555) ---
  Widget _buildCheckInForm(bool isMr) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                _editingId != null ? 'Edit Visitor' : 'New Visitor / Check-in',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. Full Name
          const Text('Full Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'Citizen full name',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Mobile
          const Text('Mobile Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: _mobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixText: '+91 ',
              hintText: '10 digits mobile',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Area / Venue
          const Text('Area / Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: _areaCtrl,
            decoration: InputDecoration(
              hintText: 'Area or venue',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 12),

          // 4. Purpose Dropdown
          const Text('Purpose', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedPurpose,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: [
              'Complaint',
              'Meeting',
              'Greeting',
              'Donation',
              'Help',
              'Other',
            ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedPurpose = val);
            },
          ),

          const SizedBox(height: 12),

          // 5. Reference
          const Text('Reference (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: _referenceCtrl,
            decoration: InputDecoration(
              hintText: 'Referred by',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 12),

          // 6. Remarks
          const Text('Notes / Remarks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: _remarksCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter visit details or notes...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 18),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _handleSaveVisitor,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(
                _editingId != null ? 'Update Visitor' : 'Log Visit',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 1,
              ),
            ),
          ),

          if (_editingId != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _resetForm,
                child: const Text('Cancel Edit', style: TextStyle(color: Color(0xFF64748B))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Right 2/3: Search Bar + View Toggle + Grid / Report (matching lines 558-750) ---
  Widget _buildLogContainer(List<VisitorModel> items, bool isMr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar of Log: Title + Found count + View Mode Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Visitor Log',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      'Found: ${items.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ),

              // View Toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.grid_view_rounded,
                      label: 'Grid',
                      isActive: _viewMode == 'grid',
                      onTap: () => setState(() => _viewMode = 'grid'),
                    ),
                    _buildViewToggleButton(
                      icon: Icons.table_chart_outlined,
                      label: 'Report',
                      isActive: _viewMode == 'report',
                      onTap: () => setState(() => _viewMode = 'report'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filters: Search & Area dropdown
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search visitors by name, mobile, notes...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  value: _selectedArea,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _uniqueAreas.map((a) {
                    return DropdownMenuItem(
                      value: a,
                      child: Text(a == 'All' ? 'All Areas' : a, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedArea = val);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Content
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (items.isEmpty)
            _buildEmptyState(isMr)
          else if (_viewMode == 'grid')
            _buildVisitorGrid(items, isMr)
          else
            _buildVisitorTable(items, isMr),
        ],
      ),
    );
  }

  // --- Grid View (2 columns on wide area) ---
  Widget _buildVisitorGrid(List<VisitorModel> items, bool isMr) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.6,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final visitor = items[index];
            return _buildVisitorCard(visitor, isMr);
          },
        );
      },
    );
  }

  Widget _buildVisitorCard(VisitorModel visitor, bool isMr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  visitor.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildPurposeBadge(visitor.purpose),
            ],
          ),
          const SizedBox(height: 4),
          if (visitor.mobile.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text('+91 ${visitor.mobile}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (visitor.area != null && visitor.area!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(visitor.area!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (visitor.remarks != null && visitor.remarks!.isNotEmpty) ...[
            Expanded(
              child: Text(
                visitor.remarks!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ] else ...[
            const Spacer(),
          ],
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${visitor.formattedDate} • ${visitor.formattedTime}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _startEdit(visitor),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await ref.read(visitorsRepoProvider).deleteVisitor(visitor.id);
                        _loadVisitors();
                      },
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

  Widget _buildPurposeBadge(String purpose) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    final pLower = purpose.toLowerCase();
    if (pLower == 'complaint') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (pLower == 'meeting') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
    } else if (pLower == 'greeting') {
      bg = const Color(0xFFF3E8FF);
      fg = const Color(0xFF7E22CE);
    } else if (pLower == 'donation' || pLower == 'help') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(purpose, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildVisitorTable(List<VisitorModel> items, bool isMr) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Purpose', style: TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
        rows: items.map((v) {
          return DataRow(
            cells: [
              DataCell(Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('+91 ${v.mobile}')),
              DataCell(_buildPurposeBadge(v.purpose)),
              DataCell(Text(v.area ?? '-')),
              DataCell(Text('${v.formattedDate} • ${v.formattedTime}')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          const Text('No visitors recorded yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
