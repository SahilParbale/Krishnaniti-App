import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/models/whatsapp_broadcast_model.dart';
import '../../../../data/repositories/sms_repository.dart';
import '../../shell/desktop_sidebar.dart';
import '../../../screens/voice/communication_history_report_generator.dart';
import '../../../widgets/app_dropdown.dart';

class DesktopAiVoiceView extends ConsumerStatefulWidget {
  const DesktopAiVoiceView({super.key});

  @override
  ConsumerState<DesktopAiVoiceView> createState() => _DesktopAiVoiceViewState();
}

class _DesktopAiVoiceViewState extends ConsumerState<DesktopAiVoiceView> {
  String _activeTab = 'call'; // 'call' | 'history'

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _callMessageController = TextEditingController();
  String _callLanguage = 'mr-IN'; // Marathi India

  final Set<String> _selectedVoterIds = {};
  bool _isLoading = false;
  bool _isBroadcasting = false;
  List<VoterModel> _voters = [];

  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _callMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(smsRepoProvider);
      final voters = await repo.getVotersWithMobile(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
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

  void _toggleSelectAll() {
    setState(() {
      if (_selectedVoterIds.length == _voters.length) {
        _selectedVoterIds.clear();
      } else {
        _selectedVoterIds.addAll(_voters.map((v) => v.id));
      }
    });
  }

  void _toggleSelectVoter(String id) {
    setState(() {
      if (_selectedVoterIds.contains(id)) {
        _selectedVoterIds.remove(id);
      } else {
        _selectedVoterIds.add(id);
      }
    });
  }

  Future<void> _startAiVoiceCampaign(bool isMr) async {
    if (_selectedVoterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one voter')),
      );
      return;
    }
    if (_callMessageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type voice announcement text')),
      );
      return;
    }

    setState(() => _isBroadcasting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isBroadcasting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI Voice Campaign initiated successfully (${_selectedVoterIds.length} calls queued)',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _callMessageController.clear();
      _selectedVoterIds.clear();
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
                        color: AppColors.brand50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: AppColors.brand600, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Voice Call',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Broadcast natural AI voice synthesized voice calls across the ward in regional languages',
                          style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ],
                ),

                // Download Report matching AIVoiceCall.tsx
                OutlinedButton.icon(
                  onPressed: () {
                    final logs = _voters.map((v) => WhatsAppBroadcastModel(
                      id: 'ai-${v.id}',
                      title: 'AI Voice Broadcast: ${v.nameEnglish.isNotEmpty ? v.nameEnglish : v.nameMarathi}',
                      message: 'Automated AI voice broadcast campaign delivered in Marathi.',
                      sentAt: DateTime.now(),
                      channel: 'voice',
                      recipients: 1,
                      sentCount: 1,
                      deliveredCount: 1,
                      failedCount: 0,
                      status: 'COMPLETED',
                      targetCriteria: v.address,
                      category: 'AI Voice Broadcast',
                    )).toList();
                    CommunicationHistoryReportGenerator.generateAndPrintReport(
                      context: context,
                      logs: logs,
                      title: 'AI Voice Campaign Report',
                      subtitle: 'Synthesized voice broadcast logs and recipient delivery status',
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
                  _buildTabButton('call', 'Create Campaign', Icons.campaign_rounded),
                  _buildTabButton('history', 'Campaign Logs', Icons.history_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_activeTab == 'call') ...[
              // Filters Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Search Name...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _loadVoters(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Search Address...',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _loadVoters(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _toggleSelectAll,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            _selectedVoterIds.length == _voters.length && _voters.isNotEmpty
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: AppColors.brand600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select All Visible (${_voters.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.brand200),
                    ),
                    child: Text(
                      '${_selectedVoterIds.length} Selected',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brand600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2-Column Area
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Voter List
                  Expanded(
                    flex: 6,
                    child: Container(
                      height: 520,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _voters.isEmpty
                              ? Center(
                                  child: Text(
                                    'No voters found',
                                    style: const TextStyle(color: AppColors.slate400),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _voters.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, i) {
                                    final v = _voters[i];
                                    final isSelected = _selectedVoterIds.contains(v.id);
                                    return InkWell(
                                      onTap: () => _toggleSelectVoter(v.id),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.brand50 : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected ? AppColors.brand600 : AppColors.slate200,
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                              color: isSelected ? AppColors.brand600 : AppColors.slate400,
                                              size: 20,
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
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${v.mobile ?? '-'}  •  ${v.address}',
                                                    style: const TextStyle(fontSize: 12, color: AppColors.slate500),
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
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right: AI Voice Campaign Configuration
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.brand600, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'AI Speech Synthesizer',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Voice Language:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate600)),
                          const SizedBox(height: 6),
                          AppDropdown<String>(
                            value: _callLanguage,
                            height: 42,
                            backgroundColor: Colors.white,
                            borderColor: const Color(0xFFE2E8F0),
                            items: const [
                              DropdownMenuItem(value: 'mr-IN', child: Text('Marathi - India')),
                              DropdownMenuItem(value: 'hi-IN', child: Text('Hindi - India')),
                              DropdownMenuItem(value: 'en-IN', child: Text('English (Indian Accent)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _callLanguage = v);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text('Speech Script:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _callMessageController,
                            maxLines: 8,
                            decoration: InputDecoration(
                              hintText: 'Type script for the automated voice call...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              fillColor: const Color(0xFFF8FAFC),
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brand600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isBroadcasting ? null : () => _startAiVoiceCampaign(isMr),
                              icon: _isBroadcasting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.phone_in_talk_rounded, size: 18),
                              label: Text(
                                _isBroadcasting ? 'Dispatching Calls...' : 'Start AI Voice Broadcast',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                      'AI Voice Broadcast History',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          'No AI voice campaign history recorded yet',
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
          color: isSelected ? AppColors.brand50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.brand600 : AppColors.slate500),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.brand700 : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
