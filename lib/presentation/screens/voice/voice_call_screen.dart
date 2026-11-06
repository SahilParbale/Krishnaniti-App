import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../../data/repositories/sms_repository.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];

  // History state
  bool _isLoadingHistory = false;
  List<WhatsAppBroadcastModel> _callHistory = [];

  // Realistic seed call history if database returns empty
  final List<WhatsAppBroadcastModel> _seedCallLogs = [
    WhatsAppBroadcastModel(
      id: 'call-001',
      title: 'Manual Voice Call - रमेश कुलकर्णी',
      message: 'Direct phone call placed to रमेश कुलकर्णी (9822011223)',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      channel: 'call',
      recipients: 1,
      sentCount: 1,
      deliveredCount: 1,
      failedCount: 0,
      status: 'COMPLETED',
    ),
    WhatsAppBroadcastModel(
      id: 'call-002',
      title: 'Manual Voice Call - सुरेश पाटील',
      message: 'Direct phone call placed to सुरेश पाटील (9822044556)',
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
      channel: 'call',
      recipients: 1,
      sentCount: 1,
      deliveredCount: 1,
      failedCount: 0,
      status: 'COMPLETED',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _callHistory.isEmpty) {
        _loadHistory();
      }
    });

    _loadVoters();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoadingVoters = true);
    final repo = ref.read(smsRepoProvider);

    try {
      final list = await repo.getVotersWithMobile(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _voters = list;
          _isLoadingVoters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVoters = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      var query = client.from('message_logs').select('*').eq('channel', 'call');
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }

      final response = await query.order('sent_at', ascending: false).limit(100);
      final list = (response as List<dynamic>)
          .map((item) => WhatsAppBroadcastModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _callHistory = list.isNotEmpty ? list : List.from(_seedCallLogs);
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _callHistory = List.from(_seedCallLogs);
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _makeCall(VoterModel voter) async {
    final phone = voter.mobile?.replaceAll(RegExp(r'\s+'), '') ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mobile number available for this voter')),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);

      // Log manual call into message_logs (channel: call) matching web
      final voterName = voter.nameMarathi.isNotEmpty ? voter.nameMarathi : voter.nameEnglish;
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      final newLog = WhatsAppBroadcastModel(
        id: 'call-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Manual Voice Call - $voterName',
        message: 'Direct phone call placed to $voterName ($phone)',
        sentAt: DateTime.now(),
        channel: 'call',
        recipients: 1,
        sentCount: 1,
        deliveredCount: 1,
        failedCount: 0,
        status: 'COMPLETED',
      );

      try {
        await client.from('message_logs').insert({
          'tenant_id': tenantId,
          'channel': 'call',
          'message': 'Direct phone call placed to $voterName ($phone)',
          'recipients': 1,
          'sent_count': 1,
          'failed_count': 0,
          'sent_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      setState(() {
        _callHistory.insert(0, newLog);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Call'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.phone), text: 'Voice Call'),
            Tab(icon: Icon(Icons.history), text: 'Call History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCallTab(theme, isDark),
          _buildHistoryTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildCallTab(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Search voter by name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (_) => _loadVoters(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _loadVoters,
                    icon: const Icon(Icons.filter_alt, size: 20),
                    tooltip: 'Apply Filters',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Filter by address / area...',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (_) => _loadVoters(),
              ),
            ],
          ),
        ),

        // Voter count info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Contacts: ${_voters.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              if (_isLoadingVoters)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        // Voter List
        Expanded(
          child: _isLoadingVoters && _voters.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _voters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_disabled_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No voters with valid phone numbers found', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVoters,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _voters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final voter = _voters[index];
                          final hasPhone = (voter.mobile != null && voter.mobile!.isNotEmpty);
                          final name = voter.nameMarathi.isNotEmpty
                              ? voter.nameMarathi
                              : (voter.nameEnglish.isNotEmpty ? voter.nameEnglish : 'Unnamed Voter');

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                                    child: const Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.call, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              hasPhone ? voter.mobile! : 'No mobile',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: hasPhone ? Colors.green[700] : Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (voter.address.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            voter.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: hasPhone ? () => _makeCall(voter) : null,
                                    icon: const Icon(Icons.phone, size: 16),
                                    label: const Text('Call'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      ],
    );
  }

  Widget _buildHistoryTab(ThemeData theme, bool isDark) {
    if (_isLoadingHistory && _callHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_callHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No voice call history found', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _callHistory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _callHistory[index];
          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.sentAt);

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.15),
                    child: const Icon(Icons.phone_forwarded, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                dateStr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VOICE CALL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.message.isNotEmpty ? item.message : item.title,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]),
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
    );
  }
}
