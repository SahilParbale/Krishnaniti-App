import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/repositories/voters_repository.dart';
import '../../../screens/voters/voter_slip_generator.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopVotersView extends ConsumerStatefulWidget {
  const DesktopVotersView({super.key});

  @override
  ConsumerState<DesktopVotersView> createState() => _DesktopVotersViewState();
}

class _DesktopVotersViewState extends ConsumerState<DesktopVotersView> {
  bool _loading = true;
  List<VoterModel> _voters = [];
  int _totalCount = 0;
  int _currentPage = 1;
  static const int _pageSize = 24;

  String _searchQuery = '';
  String _selectedBooth = 'All';
  String _selectedFavour = 'All';
  String _selectedGender = 'All';
  String _selectedAgeRange = 'All';
  bool _isFriendOnly = false;
  List<String> _availableBooths = [];
  String _viewMode = 'grid'; // 'grid' | 'table'

  @override
  void initState() {
    super.initState();
    _fetchBooths();
    _fetchVoters();
  }

  Future<void> _fetchBooths() async {
    try {
      final repo = ref.read(votersRepoProvider);
      final booths = await repo.getBoothsList();
      if (mounted) {
        setState(() {
          _availableBooths = ['All', ...booths];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchVoters() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(votersRepoProvider);
      final res = await repo.getPaginatedVoters(
        page: _currentPage,
        pageSize: _pageSize,
        query: _searchQuery,
        boothFilter: _selectedBooth,
        favourFilter: _selectedFavour,
        genderFilter: _selectedGender,
        ageRangeFilter: _selectedAgeRange,
        isFriendOnly: _isFriendOnly,
      );

      if (mounted) {
        setState(() {
          _voters = res.items;
          _totalCount = res.totalCount;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _voters = [];
          _loading = false;
        });
      }
    }
  }

  void _showAddVoterModal() {
    final nameMrController = TextEditingController();
    final nameEnController = TextEditingController();
    final epicController = TextEditingController();
    final boothController = TextEditingController(text: '12');
    final ageController = TextEditingController();
    final mobileController = TextEditingController();
    final addressController = TextEditingController();
    final houseNoController = TextEditingController();
    String gender = 'M';
    String favour = 'Neutral';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: 'Add Voter',
            subtitle: 'Register a new citizen in the ward voter registry',
            icon: Icons.how_to_reg_rounded,
            width: 600,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: 'Save Voter',
                onPressed: () async {
                  if (epicController.text.trim().isEmpty) return;
                  final newVoter = VoterModel(
                    id: 'vot-${DateTime.now().millisecondsSinceEpoch}',
                    nameMarathi: nameMrController.text.trim().isNotEmpty ? nameMrController.text.trim() : nameEnController.text.trim(),
                    nameEnglish: nameEnController.text.trim().isNotEmpty ? nameEnController.text.trim() : nameMrController.text.trim(),
                    epicNo: epicController.text.trim(),
                    booth: boothController.text.trim(),
                    age: int.tryParse(ageController.text.trim()) ?? 0,
                    gender: gender,
                    mobile: mobileController.text.trim().isNotEmpty ? mobileController.text.trim() : null,
                    houseNo: houseNoController.text.trim().isNotEmpty ? houseNoController.text.trim() : null,
                    address: addressController.text.trim(),
                    favour: favour,
                  );

                  final repo = ref.read(votersRepoProvider);
                  await repo.addVoter(newVoter);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchVoters();
                },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Names
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Voter Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameMrController,
                            decoration: desktopInputDecoration(hintText: 'e.g. Ramesh P. Kadam'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Name (English)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameEnController,
                            decoration: desktopInputDecoration(hintText: 'e.g. Ramesh Pandurang Kadam'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // EPIC & Booth
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EPIC No. *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: epicController,
                            decoration: desktopInputDecoration(hintText: 'ABC1234567'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Booth No', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: boothController,
                            decoration: desktopInputDecoration(hintText: 'e.g. 104'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Age, Gender, Mobile
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Age', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: desktopInputDecoration(hintText: '35'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: gender,
                            items: const [
                              DropdownMenuItem(value: 'M', child: Text('Male')),
                              DropdownMenuItem(value: 'F', child: Text('Female')),
                              DropdownMenuItem(value: 'O', child: Text('Other')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => gender = val);
                            },
                            decoration: desktopInputDecoration(hintText: 'Gender'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mobile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: desktopInputDecoration(hintText: '98XXXXXXXX'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // House No & Address
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('House No', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: houseNoController,
                            decoration: desktopInputDecoration(hintText: 'A-102'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: addressController,
                            decoration: desktopInputDecoration(hintText: 'Lane No. 3, Shaniwar Peth, Pune'),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Filters Row
          _buildFiltersRow(),
          const SizedBox(height: 24),

          // Grid or Table View
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildTableView()
          else
            _buildGridView(),

          const SizedBox(height: 24),
          // Pagination Controls
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Voter Search',
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
                  child: Text('Total: $_totalCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Voter directory, polling booths, family trees and voting favor',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Add Voter
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                VoterSlipGenerator.downloadVotersListReport(
                  voters: _voters,
                  totalCount: _totalCount,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: const Text('Download Report', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),

            // Add Voter
            ElevatedButton(
              onPressed: _showAddVoterModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Voter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _viewModeButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              onSubmitted: (val) {
                _searchQuery = val;
                _currentPage = 1;
                _fetchVoters();
              },
              decoration: InputDecoration(
                hintText: 'Search voter by name, EPIC number or mobile...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                  onPressed: _fetchVoters,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Booth Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              value: _selectedBooth,
              underline: const SizedBox(),
              items: _availableBooths.map((b) {
                return DropdownMenuItem(value: b, child: Text(b == 'All' ? 'All Booths' : 'Booth $b', style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedBooth = val);
                  _currentPage = 1;
                  _fetchVoters();
                }
              },
            ),
          ),
          const SizedBox(width: 10),

          // Favour Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              value: _selectedFavour,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Favour', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Favourable', child: Text('Favourable', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Neutral', child: Text('Neutral', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Against', child: Text('Against', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Swing', child: Text('Swing', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedFavour = val);
                  _currentPage = 1;
                  _fetchVoters();
                }
              },
            ),
          ),
          const SizedBox(width: 10),

          // Gender Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              value: _selectedGender,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Genders', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'M', child: Text('Male', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'F', child: Text('Female', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedGender = val);
                  _currentPage = 1;
                  _fetchVoters();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    if (_voters.isEmpty) {
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
            Icon(Icons.how_to_reg_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No voters found matching criteria', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _voters.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 220,
          ),
          itemBuilder: (context, index) {
            final voter = _voters[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Name + Favour Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          voter.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _favourColor(voter.favour).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          voter.favourLabelMarathi,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _favourColor(voter.favour)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // EPIC No & Serial
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text(voter.epicNo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF334155))),
                      ),
                      const SizedBox(width: 8),
                      Text('Sr No: ${voter.serialNo ?? '-'}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const Spacer(),
                      Text('Booth: ${voter.booth}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Age, Gender, Mobile
                  Row(
                    children: [
                      Text('${voter.gender == "M" ? "Male" : "Female"} · ${voter.age} yrs', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                      const Spacer(),
                      if (voter.mobile != null && voter.mobile!.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(voter.mobile!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Expanded(
                    child: Text(
                      voter.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
                    ),
                  ),

                  // Quick favour toggle buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _favourButton('Favourable', 'Favourable', voter.id, voter.favour == 'Favourable'),
                      const SizedBox(width: 6),
                      _favourButton('Neutral', 'Neutral', voter.id, voter.favour == 'Neutral'),
                      const SizedBox(width: 6),
                      _favourButton('Against', 'Against', voter.id, voter.favour == 'Against'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _favourButton(String label, String value, String voterId, bool isSelected) {
    return InkWell(
      onTap: () async {
        final repo = ref.read(votersRepoProvider);
        await repo.updateFavour(voterId, value);
        _fetchVoters();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? _favourColor(value) : Colors.transparent,
          border: Border.all(color: isSelected ? _favourColor(value) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Color _favourColor(String? favour) {
    switch (favour?.toLowerCase()) {
      case 'favourable':
        return const Color(0xFF16A34A);
      case 'against':
        return const Color(0xFFDC2626);
      case 'swing':
        return const Color(0xFFD97706);
      case 'neutral':
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildTableView() {
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
            const DataColumn(label: Text('Voter Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            DataColumn(label: Text('EPIC No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Age / Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Booth No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Favour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
          ],
          rows: _voters.map((v) {
            return DataRow(
              cells: [
                DataCell(Text(v.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)))),
                DataCell(Text(v.epicNo, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF334155)))),
                DataCell(Text('${v.age} / ${v.genderLabelMarathi}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(Text(v.booth, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)))),
                DataCell(Text(v.address, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _favourColor(v.favour).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                    child: Text(v.favourLabelMarathi, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _favourColor(v.favour))),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final maxPages = (_totalCount / _pageSize).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page $_currentPage of $maxPages (Total $_totalCount voters)',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _currentPage > 1
                  ? () {
                      setState(() => _currentPage--);
                      _fetchVoters();
                    }
                  : null,
              child: const Text('Previous'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _currentPage < maxPages
                  ? () {
                      setState(() => _currentPage++);
                      _fetchVoters();
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              child: const Text('Next', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 220,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }
}
