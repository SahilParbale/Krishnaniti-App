import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nagarsevak_mobile/core/theme/app_colors.dart';
import 'package:nagarsevak_mobile/data/models/complaint_model.dart';
import 'package:nagarsevak_mobile/data/repositories/complaints_repository.dart';
import 'package:nagarsevak_mobile/data/repositories/voters_repository.dart';
import 'package:nagarsevak_mobile/data/repositories/letters_repository.dart';
import 'package:nagarsevak_mobile/presentation/providers/navigation_provider.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/screens/complaints/new_complaint_screen.dart';

/// Desktop Dashboard matching Nagarsevak-Managment/src/pages/dashboard/Dashboard.tsx exactly 1:1
class DesktopDashboardView extends ConsumerStatefulWidget {
  const DesktopDashboardView({super.key});

  @override
  ConsumerState<DesktopDashboardView> createState() => _DesktopDashboardViewState();
}

class _DesktopDashboardViewState extends ConsumerState<DesktopDashboardView> {
  bool _loading = true;
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'inProgress': 0,
    'resolved': 0,
    'voters': 0,
    'totalLetters': 0,
    'totalVisitors': 0,
  };
  List<ComplaintModel> _recentActivity = [];
  String _activityFilter = 'all'; // 'all' or 'pending'

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _loading = true);
    try {
      final compRepo = ComplaintsRepository();
      final voterRepo = VotersRepository();
      final letterRepo = LettersRepository();

      final results = await Future.wait([
        compRepo.getComplaintStats().catchError((_) => {'total': 0, 'pending': 0, 'inProgress': 0, 'resolved': 0}),
        voterRepo.getVotersCount().catchError((_) => 0),
        letterRepo.getLettersCount().catchError((_) => 0),
        compRepo.getComplaints(limit: 12).catchError((_) => <ComplaintModel>[]),
      ]);

      if (mounted) {
        final cStats = results[0] as Map<String, int>;
        final vCount = results[1] as int;
        final lCount = results[2] as int;
        final activities = results[3] as List<ComplaintModel>;

        setState(() {
          _stats = {
            'total': cStats['total'] ?? 0,
            'pending': cStats['pending'] ?? 0,
            'inProgress': cStats['inProgress'] ?? 0,
            'resolved': cStats['resolved'] ?? 0,
            'voters': vCount,
            'totalLetters': lCount,
            'totalVisitors': 0,
          };
          _recentActivity = activities;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openNewRequestModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Container(
          width: 680,
          constraints: const BoxConstraints(maxHeight: 720),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const NewComplaintScreen(),
        ),
      ),
    ).then((_) => _fetchDashboardData());
  }

  void _showHelpDialog(bool isMr) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppColors.brand600),
            const SizedBox(width: 10),
            Text('Dashboard Guide & Overview'),
          ],
        ),
        content: const Text(
          'This is your central administrative command portal. Track civic complaints, registered voters, ward works, and incoming letters in real-time.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand600, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final isMr = lang == 'mr';

    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand600),
            SizedBox(height: 16),
            Text(
              'Loading Dashboard Overview...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate500),
            ),
          ],
        ),
      );
    }

    final total = _stats['total'] ?? 0;
    final pending = _stats['pending'] ?? 0;
    final inProgress = _stats['inProgress'] ?? 0;
    final resolved = _stats['resolved'] ?? 0;
    final voters = _stats['voters'] ?? 0;

    final resolutionRate = total > 0 ? ((resolved / total) * 100).round() : 0;

    final pendingList = _recentActivity.where((a) => a.status.toLowerCase().contains('pending')).toList();
    final displayedActivity = _activityFilter == 'pending' ? pendingList : _recentActivity;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sticky Header Section (matching Dashboard.tsx lines 200-230)
              _buildHeaderSection(isMr),

              const SizedBox(height: 24),

              // 2. Quick Actions Card (matching Dashboard.tsx lines 232-260)
              _buildQuickActionsCard(isMr),

              const SizedBox(height: 24),

              // 3. AI Insight Banner (matching Dashboard.tsx lines 262-280)
              _buildAiInsightBanner(isMr, pending, resolved, voters),

              const SizedBox(height: 24),

              // 4. Stats Grid 4 Cards (matching Dashboard.tsx lines 282-300)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Citizens',
                      value: voters,
                      icon: Icons.people_outline_rounded,
                      accentBorder: const Color(0xFFBAE6FD), // sky-200
                      accentBg: const Color(0xFFF0F9FF), // sky-50
                      iconColor: const Color(0xFF0369A1), // sky-700
                      onTap: () => ref.read(activeScreenProvider.notifier).setScreen('voters'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Pending Issues',
                      value: pending,
                      icon: Icons.error_outline_rounded,
                      accentBorder: const Color(0xFFFECACA), // red-200
                      accentBg: const Color(0xFFFEF2F2), // red-50
                      iconColor: const Color(0xFFB91C1C), // red-700
                      onTap: () => ref.read(activeScreenProvider.notifier).setScreen('complaints'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      title: 'In Progress',
                      value: inProgress,
                      icon: Icons.show_chart_rounded,
                      accentBorder: const Color(0xFFFDE68A), // amber-200
                      accentBg: const Color(0xFFFFFBEB), // amber-50
                      iconColor: const Color(0xFFB45309), // amber-700
                      onTap: () => ref.read(activeScreenProvider.notifier).setScreen('complaints'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Resolved Works',
                      value: resolved,
                      icon: Icons.check_circle_outline_rounded,
                      accentBorder: const Color(0xFFBBF7D0), // green-200
                      accentBg: const Color(0xFFF0FDF4), // green-50
                      iconColor: const Color(0xFF15803D), // green-700
                      onTap: () => ref.read(activeScreenProvider.notifier).setScreen('complaints'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 5. Main Content Grid (3 Columns: 2 cols Status Overview Chart + 1 col Live Activity)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left (2 Columns - 66%): Status Overview Visual Chart
                  Expanded(
                    flex: 2,
                    child: _buildStatusOverviewCard(isMr, total, pending, inProgress, resolved, resolutionRate),
                  ),

                  const SizedBox(width: 24),

                  // Right (1 Column - 33%): Live Activity Feed
                  Expanded(
                    flex: 1,
                    child: _buildLiveActivityFeedCard(isMr, pending, displayedActivity),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isMr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Welcome back to your administration portal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Refresh Button (ns-btn-ghost)
            OutlinedButton.icon(
              onPressed: _fetchDashboardData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.slate700,
                side: const BorderSide(color: AppColors.slate200),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),

            // Help Button (ns-btn-ghost border-brand-200)
            OutlinedButton.icon(
              onPressed: () => _showHelpDialog(isMr),
              icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.brand600),
              label: const Text('Help'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand700,
                side: const BorderSide(color: AppColors.brand200),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),

            // + New Request Button (ns-btn-primary)
            ElevatedButton.icon(
              onPressed: _openNewRequestModal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('+ New Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(bool isMr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Quick actions:',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.slate600,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 10,
            children: [
              _buildGhostActionBtn(
                icon: Icons.search_rounded,
                label: 'Search Voters',
                onTap: () => ref.read(activeScreenProvider.notifier).setScreen('voters'),
              ),
              _buildGhostActionBtn(
                icon: Icons.person_add_alt_1_rounded,
                label: 'My Team / Staff',
                onTap: () => ref.read(activeScreenProvider.notifier).setScreen('team'),
              ),
              _buildGhostActionBtn(
                icon: Icons.campaign_outlined,
                label: 'Citizen Complaints',
                onTap: () => ref.read(activeScreenProvider.notifier).setScreen('complaints'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGhostActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.slate600),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.slate700,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.slate200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAiInsightBanner(bool isMr, int pending, int resolved, int voters) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brand50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brand100),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.brand700,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Analysis & Briefing',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Currently $pending citizen grievances in the ward require attention. $resolved works have been resolved successfully. Total registered ward voters: $voters.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color accentBorder,
    required Color accentBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                      letterSpacing: -0.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentBorder),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverviewCard(
    bool isMr,
    int total,
    int pending,
    int inProgress,
    int resolved,
    int resolutionRate,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Overview',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              InkWell(
                onTap: () => ref.read(activeScreenProvider.notifier).setScreen('complaints'),
                child: Text(
                  'View All',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Custom Horizontal Progress Bars (matching Dashboard.tsx lines 310-340)
          _buildBarChartRow(
            label: 'Pending',
            count: pending,
            total: total,
            barColor: const Color(0xFFEF4444), // red-500
          ),
          const SizedBox(height: 18),
          _buildBarChartRow(
            label: 'In Progress',
            count: inProgress,
            total: total,
            barColor: const Color(0xFFF59E0B), // amber-500
          ),
          const SizedBox(height: 18),
          _buildBarChartRow(
            label: 'Resolved',
            count: resolved,
            total: total,
            barColor: const Color(0xFF16A34A), // green-600
          ),

          const SizedBox(height: 32),
          const Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 20),

          // Bottom Metric Triplets (matching Dashboard.tsx lines 345-360)
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'RESOLUTION RATE',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$resolutionRate%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.slate900),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.slate200),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'AVG. RESPONSE',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '—',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.slate900),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.slate200),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'SATISFACTION',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '—',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.slate900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartRow({
    required String label,
    required int count,
    required int total,
    required Color barColor,
  }) {
    final double fraction = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.slate700),
            ),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.slate900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveActivityFeedCard(
    bool isMr,
    int pendingCount,
    List<ComplaintModel> activities,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Pending Badge & Filter Pills (matching Dashboard.tsx lines 365-400)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Live Activity',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2), // red-100
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFECACA)), // red-200
                        ),
                        child: Text(
                          '$pendingCount Pending',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Filter Buttons
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildActivityFilterBtn('all', 'All', _activityFilter == 'all', isPendingTab: false),
                    _buildActivityFilterBtn('pending', 'Pending', _activityFilter == 'pending', isPendingTab: true),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Activity Items List
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No recent activity records',
                  style: const TextStyle(fontSize: 13, color: AppColors.slate400),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length.clamp(0, 7),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = activities[index];
                final isPending = item.status.toLowerCase().contains('pending');
                final dateFormatted = DateFormat('d MMM, h:mm a').format(item.createdAt);

                return InkWell(
                  onTap: () => ref.read(activeScreenProvider.notifier).setScreen('complaints'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPending ? const Color(0xFFFEF2F2) : AppColors.slate50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPending ? const Color(0xFFFECACA) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPending ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title.isNotEmpty ? item.title : 'Citizen Grievance',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    item.area ?? item.location ?? 'Ward No. 12',
                                    style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Text('•', style: TextStyle(color: AppColors.slate300, fontSize: 10)),
                                  ),
                                  Text(
                                    dateFormatted,
                                    style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityFilterBtn(String key, String label, bool isSelected, {required bool isPendingTab}) {
    return InkWell(
      onTap: () => setState(() => _activityFilter = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? (isPendingTab ? const Color(0xFFEF4444) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? (isPendingTab ? Colors.white : AppColors.slate900) : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}
