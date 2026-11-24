import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../shell/desktop_sidebar.dart';

class DesktopAnalysisStrategyView extends ConsumerStatefulWidget {
  const DesktopAnalysisStrategyView({super.key});

  @override
  ConsumerState<DesktopAnalysisStrategyView> createState() => _DesktopAnalysisStrategyViewState();
}

class _DesktopAnalysisStrategyViewState extends ConsumerState<DesktopAnalysisStrategyView> {
  String _activeTab = 'strategy'; // 'strategy' | 'analytical'
  String _selectedArea = 'Shaniwar Peth';
  String _selectedTone = 'Development'; // 'Development' | 'Grievance' | 'Campaign'
  bool _isGenerating = false;
  String _aiBrief = '';

  final List<String> _areas = [
    'Shaniwar Peth',
    'Kasba Peth',
    'Narayan Peth',
    'Sadashiv Peth',
    'Raviwar Peth',
  ];

  @override
  void initState() {
    super.initState();
    _generateDefaultBrief();
  }

  void _generateDefaultBrief() {
    setState(() {
      _aiBrief = '''
📌 **Ward 12 ($_selectedArea) - Strategic Campaign Intelligence Brief**:

1. **Water Supply & Infrastructure Repairs**: Citizen complaints regarding low water pressure constitute 28% of overall volume in this pocket. Prioritizing pipeline overhaul works will yield immediate voter goodwill.
2. **Youth Voter Outreach (Age 18-35)**: Constitutes 42% of local electorate. Organizing career guidance workshops and inter-ward sports tournaments is strongly recommended.
3. **Welfare Scheme Camps**: Over 500+ applications have been processed for central & state welfare benefits; scheduling a dedicated assistance desk in the community hall will consolidate support.
4. **Cooperative Housing Society Meetings**: Direct liaison with management committees across 8 prominent apartment societies is recommended for upcoming weekend town halls.
''';
    });
  }

  Future<void> _triggerAiAnalysis() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _aiBrief = '''
📌 **Ward 12 ($_selectedArea) - Strategic Focus: $_selectedTone**:

• **Core Priority #1**: Accelerate visible development works and local civic infrastructure completion across $_selectedArea.
• **Grievance Resolution Velocity**: Current resolution rate stands at 84%; target an increase to 92% over the next 3 weeks before election announcements.
• **Community Outreach**: Coordinate direct interactive sessions with local senior citizen clubs and commercial merchant associations next week.
• **Digital Amplification**: Broadcast video reels of completed road concreting and LED street lighting upgrades across WhatsApp and Facebook networks.
''';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.query_stats_rounded, color: AppColors.brandPrimary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Strategy',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'AI-assisted strategic ward insights, demographic breakdowns, and ground campaign roadmaps',
                          style: TextStyle(fontSize: 13, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ],
                ),

              ],
            ),
            const SizedBox(height: 24),

            // Tabs Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton('strategy', 'Strategy Planner', Icons.track_changes_rounded),
                  _buildTabButton('analytical', 'Analytical Dashboard', Icons.insights_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top Area Selector & Metrics
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  const Text(
                    'Select Ward Area:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: _selectedArea,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _areas
                          .map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedArea = v);
                          _triggerAiAnalysis();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4 Stat Cards
            Row(
              children: [
                Expanded(child: _buildMetricCard('Total Voters', '14,820', Icons.how_to_reg_rounded, AppColors.brandPrimary)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Resolved Complaints', '88.4%', Icons.check_circle_rounded, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Mobile Reach', '76.2%', Icons.phone_android_rounded, AppColors.brand500)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Winning Margin', '+2,480', Icons.trending_up_rounded, AppColors.brand700)),
              ],
            ),
            const SizedBox(height: 24),

            if (_activeTab == 'strategy') ...[
              // AI Strategy Generation Box
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: AppColors.brandPrimary, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'AI Strategic Intelligence & Campaign Brief',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'Development', label: Text('Dev')),
                                ButtonSegment(value: 'Grievance', label: Text('Grievance')),
                                ButtonSegment(value: 'Campaign', label: Text('Campaign')),
                              ],
                              selected: {_selectedTone},
                              onSelectionChanged: (s) {
                                setState(() => _selectedTone = s.first);
                                _triggerAiAnalysis();
                              },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isGenerating ? null : _triggerAiAnalysis,
                              icon: _isGenerating
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Regenerate'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Text(
                        _aiBrief,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.slate800),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Analytical Dashboard Tab
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Demographic distribution
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Voter Gender Demographics',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                          ),
                          const SizedBox(height: 18),
                          _buildDemographicBar('Male', 52, AppColors.brand600),
                          const SizedBox(height: 14),
                          _buildDemographicBar('Female', 47, const Color(0xFFEC4899)),
                          const SizedBox(height: 14),
                          _buildDemographicBar('Other', 1, AppColors.brand800),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Problem Categories
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Key Ward Grievances Distribution',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                          ),
                          const SizedBox(height: 18),
                          _buildDemographicBar('Water Supply', 34, Colors.cyan),
                          const SizedBox(height: 14),
                          _buildDemographicBar('Roads & Pavements', 28, Colors.amber.shade700),
                          const SizedBox(height: 14),
                          _buildDemographicBar('Sanitation & Garbage', 22, Colors.green),
                          const SizedBox(height: 14),
                          _buildDemographicBar('Streetlights', 16, Colors.deepOrange),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicBar(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate700)),
            Text('$percentage%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.slate100,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTabButton(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return InkWell(
      onTap: () => setState(() => _activeTab = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.brandPrimary : AppColors.slate500),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.brandPrimary : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
