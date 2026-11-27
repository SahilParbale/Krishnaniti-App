import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/housing_society_model.dart';
import '../../../../data/repositories/housing_society_repository.dart';
import '../../../screens/housing_societies/housing_society_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopHousingSocietiesView extends ConsumerStatefulWidget {
  const DesktopHousingSocietiesView({super.key});

  @override
  ConsumerState<DesktopHousingSocietiesView> createState() => _DesktopHousingSocietiesViewState();
}

class _DesktopHousingSocietiesViewState extends ConsumerState<DesktopHousingSocietiesView> {
  bool _loading = true;
  List<HousingSocietyModel> _societies = [];
  String _searchTerm = '';
  String _selectedArea = 'All';
  String _statusFilter = 'all';
  List<String> _availableAreas = ['All'];
  int _displayedLimit = 20;

  List<HousingSocietyModel> get _visibleSocieties =>
      _filteredSocieties.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  Future<void> _fetchSocieties() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(housingSocietyRepoProvider);
      final list = await repo.getSocieties();
      final areas = await repo.getUniqueAreas();

      if (mounted) {
        setState(() {
          _societies = list;
          _availableAreas = areas;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _societies = [];
          _loading = false;
        });
      }
    }
  }

  List<HousingSocietyModel> get _filteredSocieties {
    return _societies.where((s) {
      final matchesSearch = _searchTerm.isEmpty ||
          s.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (s.nameMarathi?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          s.chairmanName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          s.secretaryName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          s.chairmanMobile.contains(_searchTerm) ||
          s.area.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesArea = _selectedArea == 'All' || s.area.toLowerCase() == _selectedArea.toLowerCase();
      final matchesStatus = _statusFilter == 'all' || s.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesArea && matchesStatus;
    }).toList();
  }

  void _showAddEditModal({HousingSocietyModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    final chairmanController = TextEditingController(text: item?.chairmanName ?? '');
    final chairMobileController = TextEditingController(text: item?.chairmanMobile ?? '');
    final secretaryController = TextEditingController(text: item?.secretaryName ?? '');
    final secMobileController = TextEditingController(text: item?.secretaryMobile ?? '');
    final voterCountController = TextEditingController(text: (item?.voterCount ?? 100).toString());
    final favVoterController = TextEditingController(text: (item?.favourableVoterCount ?? 60).toString());
    final notesController = TextEditingController(text: item?.notes ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: item == null ? 'Register New Society' : 'Edit Society Details',
            subtitle: 'Register and track housing societies, office bearers, and voter count',
            icon: Icons.domain_rounded,
            width: 600,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: item == null ? 'Register Society' : 'Save Changes',
                onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            final newSoc = HousingSocietyModel(
                              id: item?.id ?? 'soc-${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text.trim(),
                              nameMarathi: nameController.text.trim(),
                              area: areaController.text.trim(),
                              chairmanName: chairmanController.text.trim(),
                              chairmanMobile: chairMobileController.text.trim(),
                              secretaryName: secretaryController.text.trim(),
                              secretaryMobile: secMobileController.text.trim(),
                              voterCount: int.tryParse(voterCountController.text.trim()) ?? 0,
                              favourableVoterCount: int.tryParse(favVoterController.text.trim()) ?? 0,
                              notes: notesController.text.trim(),
                            );

                            final repo = ref.read(housingSocietyRepoProvider);
                            if (item == null) {
                              await repo.addSociety(newSoc);
                            } else {
                              await repo.updateSociety(newSoc);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchSocieties();
                          },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Society Name
                    const Text('Society Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Gokuldham Co-op Housing Society...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Area & Voters
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Area / Location *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Main Street',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
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
                              const Text('Total Voters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: voterCountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
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
                              const Text('Favourable Voters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: favVoterController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chairman Name & Mobile
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chairman Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: chairmanController,
                                decoration: InputDecoration(
                                  hintText: 'Name of Chairman...',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
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
                              const Text('Chairman Mobile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: chairMobileController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '98XXXXXXXX',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Secretary Name & Mobile
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Secretary Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: secretaryController,
                                decoration: InputDecoration(
                                  hintText: 'Name of Secretary...',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
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
                              const Text('Secretary Mobile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: secMobileController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '98XXXXXXXX',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const Text('Local Issues & Demands', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Water supply, internal roads, streetlight or waste disposal issues...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                                      ],
            ),
          );
        },
      ),
    );  }

  void _showDeleteConfirm(HousingSocietyModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Society'),
        content: Text('Are you sure you want to delete "${item.displayName()}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(housingSocietyRepoProvider);
              await repo.deleteSociety(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchSocieties();
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
    final filtered = _filteredSocieties;
    final visible = _visibleSocieties;
    final totalVoters = filtered.fold<int>(0, (sum, s) => sum + s.voterCount);
    final favVoters = filtered.fold<int>(0, (sum, s) => sum + s.favourableVoterCount);
    final avgSupport = totalVoters > 0 ? ((favVoters / totalVoters) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length),
          const SizedBox(height: 20),

          // 4 Stats Cards
          _buildStatsRow(filtered.length, totalVoters, favVoters, avgSupport),
          const SizedBox(height: 24),

          // Filter bar
          _buildFilterBar(),
          const SizedBox(height: 24),

          // Content Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildCardGrid(visible),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: 'सोसायटी',
              isMarathi: true,
            ),
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
                  'Housing Societies',
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
              'Co-operative housing societies, chairpersons, secretaries and voter outreach',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions Row matching HousingSocieties.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                HousingSocietyReportGenerator.generateAndPrintReport(
                  context: context,
                  societies: _filteredSocieties,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(ref.watch(desktopLanguageProvider)),
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),

            // Add Button
            ElevatedButton(
              onPressed: () => _showAddEditModal(),
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
                    'Register Society',
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

  Widget _buildStatsRow(int totalSoc, int totalVoters, int favVoters, int avgSupport) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Total Societies', totalSoc.toString(), Icons.apartment_rounded, const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Total Voters', totalVoters.toString(), Icons.people_alt_outlined, const Color(0xFF0284C7), const Color(0xFFF0F9FF)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Favourable Voters', favVoters.toString(), Icons.how_to_reg_rounded, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Support Rate', '$avgSupport%', Icons.pie_chart_outline_rounded, const Color(0xFF9333EA), const Color(0xFFFAF5FF)),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: const InputDecoration(
                hintText: 'Search society by name, chairman or secretary...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Area Filter
        AppDropdown<String>(
          value: _selectedArea,
          height: 40,
          width: 160,
          prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          items: _availableAreas.map((a) {
            return DropdownMenuItem(value: a, child: Text(a == 'All' ? 'All Areas' : a));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedArea = val;
                _displayedLimit = 20;
              });
            }
          },
        ),
        const SizedBox(width: 12),

        // Status Filter
        AppDropdown<String>(
          value: _statusFilter,
          height: 40,
          width: 140,
          prefixIcon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF94A3B8)),
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'Active', child: Text('Active')),
            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _statusFilter = val;
                _displayedLimit = 20;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<HousingSocietyModel> items) {
    if (items.isEmpty) {
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
            Icon(Icons.home_work_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No housing societies found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 280,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(4)),
                        child: Text(item.area.isNotEmpty ? item.area : 'Ward 12', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)),
                        child: Text('${item.supportPercentage}% Favourable', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    item.displayName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  // Chairman
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text('Chairman: ${item.chairmanName.isNotEmpty ? item.chairmanName : "Not recorded"}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      if (item.chairmanMobile.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text('(${item.chairmanMobile})', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Secretary
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text('Secretary: ${item.secretaryName.isNotEmpty ? item.secretaryName : "Not recorded"}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      if (item.secretaryMobile.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text('(${item.secretaryMobile})', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Voter progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Voters: ${item.favourableVoterCount} / ${item.voterCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      Text('Other: ${item.otherVotersCount}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: item.voterCount > 0 ? (item.favourableVoterCount / item.voterCount).clamp(0.0, 1.0) : 0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      minHeight: 6,
                    ),
                  ),

                  const Spacer(),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.status == 'Active' ? 'Active Society' : 'Inactive', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showAddEditModal(item: item)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)), onPressed: () => _showDeleteConfirm(item)),
                          ],
                        ),
                      ],
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

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 260,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
