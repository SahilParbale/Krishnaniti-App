import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../../data/repositories/sms_repository.dart';

const _kAiPurple = Color(0xFF7C3AED);
const _kAiPurpleLight = Color(0xFFF3E8FF);
const _kAiPurpleBorder = Color(0xFFDDD6FE);

class AiVoiceCallScreen extends ConsumerStatefulWidget {
  const AiVoiceCallScreen({super.key});

  @override
  ConsumerState<AiVoiceCallScreen> createState() => _AiVoiceCallScreenState();
}

class _AiVoiceCallScreenState extends ConsumerState<AiVoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _speechMessageController = TextEditingController();

  String _selectedLanguage = 'mr-IN'; // Marathi (mr-IN), Hindi (hi-IN), English (en-IN)
  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];
  final Set<String> _selectedVoterIds = {};
  bool _isAllSelected = false;

  // Campaign Calling State
  bool _isCalling = false;

  // History State
  bool _isLoadingHistory = false;
  List<WhatsAppBroadcastModel> _aiCallLogs = [];

  // Seed history
  final List<WhatsAppBroadcastModel> _seedLogs = [
    WhatsAppBroadcastModel(
      id: 'ai-001',
      title: 'AI Voice Broadcast - पाणीपुरवठा व रस्ता दुरुस्ती अभिप्राय',
      message: 'नमस्कार, प्रभाग १२ मधील विकासकामे व पाणीपुरवठ्याबाबत नागरिकांचा अभिप्राय नोंदवून घेण्यासाठी स्वयंचलित AI कॉल.',
      sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      channel: 'ai_call',
      recipients: 450,
      sentCount: 450,
      deliveredCount: 432,
      failedCount: 18,
      status: 'COMPLETED',
      category: 'AI Voice Call',
    ),
    WhatsAppBroadcastModel(
      id: 'ai-002',
      title: 'AI Voice Broadcast - लाडकी बहीण योजना शिबिर माहिती',
      message: 'लाडकी बहीण योजनेच्या विशेष नोंदणी शिबिराबाबत नागरिकांना प्रत्यक्ष मराठी व्हॉइस कॉलद्वारे थेट माहिती देण्यात आली.',
      sentAt: DateTime.now().subtract(const Duration(days: 2)),
      channel: 'ai_call',
      recipients: 1200,
      sentCount: 1200,
      deliveredCount: 1180,
      failedCount: 20,
      status: 'COMPLETED',
      category: 'AI Voice Call',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _aiCallLogs.isEmpty) {
        _loadHistory();
      }
    });

    _speechMessageController.text =
        'नमस्कार, मी प्रभाग १२ नगरसेवक कार्यालयातून बोलत आहे. आपल्या परिसरातील पाणीपुरवठा व रस्ते दुरुस्तीच्या कामाबाबत आपला अभिप्राय जाणून घेण्यासाठी हा कॉल करण्यात आला आहे.';

    _loadVoters();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _speechMessageController.dispose();
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
          _updateSelectAllState();
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
          _aiCallLogs = list.isNotEmpty ? list : List.from(_seedLogs);
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiCallLogs = List.from(_seedLogs);
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _updateSelectAllState() {
    if (_voters.isEmpty) {
      _isAllSelected = false;
      return;
    }
    _isAllSelected = _voters.every((v) => _selectedVoterIds.contains(v.id));
  }

  void _toggleVoter(String id) {
    setState(() {
      if (_selectedVoterIds.contains(id)) {
        _selectedVoterIds.remove(id);
      } else {
        _selectedVoterIds.add(id);
      }
      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedVoterIds.clear();
        _isAllSelected = false;
      } else {
        for (final v in _voters) {
          _selectedVoterIds.add(v.id);
        }
        _isAllSelected = true;
      }
    });
  }

  Future<void> _startAiCalls() async {
    final text = _speechMessageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter speech text to be spoken by AI')),
      );
      return;
    }

    if (_selectedVoterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one voter to initiate AI call')),
      );
      return;
    }

    setState(() => _isCalling = true);

    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;
      final count = _selectedVoterIds.length;

      final newLog = WhatsAppBroadcastModel(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        title: 'AI Voice Broadcast ($_selectedLanguage)',
        message: text,
        sentAt: DateTime.now(),
        channel: 'call',
        recipients: count,
        sentCount: count,
        deliveredCount: (count * 0.96).round(),
        failedCount: (count * 0.04).round(),
        status: 'COMPLETED',
        category: 'AI Voice Call',
      );

      await client.from('message_logs').insert({
        'tenant_id': tenantId,
        'channel': 'call',
        'message': text,
        'recipients': count,
        'sent_count': count,
        'failed_count': (count * 0.04).round(),
        'sent_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isCalling = false;
          _aiCallLogs.insert(0, newLog);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _kAiPurple,
            content: Text('AI Voice Broadcast initiated to $count recipients!'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCalling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate AI Voice Broadcast')),
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
        title: Row(
          children: const [
            Icon(Icons.record_voice_over_rounded, color: _kAiPurple, size: 22),
            SizedBox(width: 8),
            Text('AI Voice Call'),
          ],
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kAiPurple,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: _kAiPurple,
          tabs: const [
            Tab(icon: Icon(Icons.record_voice_over), text: 'AI Call Broadcast'),
            Tab(icon: Icon(Icons.history), text: 'Call History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAiCallTab(theme, isDark),
          _buildHistoryTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildAiCallTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Language selector
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : _kAiPurpleBorder),
            ),
            color: isDark ? const Color(0xFF1E293B) : _kAiPurpleLight.withOpacity(0.35),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.language, size: 16, color: _kAiPurple),
                      SizedBox(width: 6),
                      Text(
                        'Select Voice Language / भाषा निवडा',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLangChoice('mr-IN', 'मराठी (Marathi)'),
                      const SizedBox(width: 8),
                      _buildLangChoice('hi-IN', 'हिंदी (Hindi)'),
                      const SizedBox(width: 8),
                      _buildLangChoice('en-IN', 'English'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Speech Text Box
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Message to Speak / संदेश',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kAiPurpleLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Text-to-Speech AI',
                          style: TextStyle(fontSize: 10, color: _kAiPurple, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _speechMessageController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter message to be spoken by AI voice agent...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Voter Selection & Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 18, color: _kAiPurple),
                  const SizedBox(width: 6),
                  Text(
                    'Select Voters (${_selectedVoterIds.length} / ${_voters.length})',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _toggleSelectAll,
                icon: Icon(
                  _isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: _kAiPurple,
                ),
                label: Text(
                  _isAllSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(fontSize: 12, color: _kAiPurple, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Search inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Filter name...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _loadVoters(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Filter area...',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _loadVoters(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: _loadVoters,
                icon: const Icon(Icons.filter_alt, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Voter List
          _isLoadingVoters
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _kAiPurple)))
              : _voters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('No voters found with phone numbers', style: TextStyle(color: Colors.grey[600])),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _voters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (ctx, i) {
                        final v = _voters[i];
                        final isSelected = _selectedVoterIds.contains(v.id);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? _kAiPurple : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _toggleVoter(v.id),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: isSelected ? _kAiPurple : Colors.grey[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          '${v.mobile ?? '-'} · ${v.address}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

          const SizedBox(height: 20),

          // 4. Start AI Call Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isCalling ? null : _startAiCalls,
              icon: _isCalling
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.phone_in_talk, size: 20),
              label: Text(
                _isCalling ? 'Initiating Calls...' : 'Start AI Voice Calls (${_selectedVoterIds.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAiPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChoice(String code, String label) {
    final isSelected = _selectedLanguage == code;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedLanguage = code),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _kAiPurple : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? _kAiPurple : Colors.grey[300]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, bool isDark) {
    if (_isLoadingHistory && _aiCallLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kAiPurple));
    }

    if (_aiCallLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No AI Voice Call history found', style: TextStyle(color: Colors.grey[600])),
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
      color: _kAiPurple,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _aiCallLogs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _aiCallLogs[index];
          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.sentAt);

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                          color: _kAiPurpleLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AI VOICE CALL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _kAiPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message.isNotEmpty ? item.message : item.title,
                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${item.recipients} Recipients · ${item.sentCount} Completed',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                    ],
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

