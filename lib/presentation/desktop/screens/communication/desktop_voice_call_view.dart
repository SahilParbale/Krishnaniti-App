import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/models/whatsapp_broadcast_model.dart';
import '../../../../data/repositories/sms_repository.dart';
import '../../shell/desktop_sidebar.dart';
import '../../../screens/voice/communication_history_report_generator.dart';

class DesktopVoiceCallView extends ConsumerStatefulWidget {
  const DesktopVoiceCallView({super.key});

  @override
  ConsumerState<DesktopVoiceCallView> createState() => _DesktopVoiceCallViewState();
}

class _DesktopVoiceCallViewState extends ConsumerState<DesktopVoiceCallView> {
  String _activeTab = 'call'; // 'call' | 'history'
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<VoterModel> _voters = [];

  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(smsRepoProvider);
      final voters = await repo.getVotersWithMobile(
        name: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _voters = voters;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makeCall(String? mobile) async {
    if (mobile == null || mobile.trim().isEmpty) return;
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final isMr = lang == 'mr';

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
                      child: const Icon(Icons.phone_rounded, color: AppColors.brandPrimary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Call',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Initiate direct telephone communication with constituents and log conversations',
                          style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ],
                ),

                // Download Report matching VoiceCall.tsx
                OutlinedButton.icon(
                  onPressed: () {
                    final logs = _voters.map((v) => WhatsAppBroadcastModel(
                      id: 'call-${v.id}',
                      title: 'Voice Call: ${v.nameEnglish.isNotEmpty ? v.nameEnglish : v.nameMarathi}',
                      message: 'Direct constituent voice call record for Ward 12 constituency.',
                      sentAt: DateTime.now(),
                      channel: 'voice',
                      recipients: 1,
                      sentCount: 1,
                      deliveredCount: 1,
                      failedCount: 0,
                      status: 'COMPLETED',
                      targetCriteria: v.address,
                      category: 'Voice Communication',
                    )).toList();
                    CommunicationHistoryReportGenerator.generateAndPrintReport(
                      logs: logs,
                      title: 'Voice Call History & Log Report',
                      subtitle: 'Constituent telephone outreach and communication records',
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
                  _buildTabButton('call', 'Make Call', Icons.phone_forwarded_rounded),
                  _buildTabButton('history', 'Call History', Icons.history_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_activeTab == 'call') ...[
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search voter by name or mobile...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (_) => _loadVoters(),
                ),
              ),
              const SizedBox(height: 20),

              // 3-Column Grid
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (_voters.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: const Text('No voters found', style: TextStyle(color: AppColors.slate400)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 170,
                  ),
                  itemCount: _voters.length,
                  itemBuilder: (ctx, i) {
                    final v = _voters[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                                child: const Icon(Icons.person, color: AppColors.brandPrimary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMr && v.nameMarathi.isNotEmpty
                                          ? v.nameMarathi
                                          : v.nameEnglish,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      v.mobile ?? '-',
                                      style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            v.address,
                            style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.brandPrimary,
                                elevation: 0,
                                side: const BorderSide(color: AppColors.brandPrimary),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _makeCall(v.mobile),
                              icon: const Icon(Icons.phone_rounded, size: 16),
                              label: Text(
                                'Call Now',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ] else ...[
              // History Tab
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call History Logs',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          'No call logs recorded yet',
                          style: const TextStyle(color: AppColors.slate400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
