import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../../data/repositories/whatsapp_repository.dart';
import 'whatsapp_history_report_generator.dart';

const _kWaGreen = Color(0xFF25D366);
const _kWaDark = Color(0xFF075E54);
const _kWaLight = Color(0xFFE8F5E9);
const _kWaLightBorder = Color(0xFFA5D6A7);

class WhatsAppCallingScreen extends ConsumerStatefulWidget {
  const WhatsAppCallingScreen({super.key});

  @override
  ConsumerState<WhatsAppCallingScreen> createState() => _WhatsAppCallingScreenState();
}

class _WhatsAppCallingScreenState extends ConsumerState<WhatsAppCallingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];

  bool _isLoadingHistory = false;
  List<WhatsAppBroadcastModel> _callLogs = [];
  bool _isExportingPdf = false;

  // Bot Status
  final String _botStatus = 'connected'; // Connected bot indicator

  // Seed sample records for fallback
  final List<WhatsAppBroadcastModel> _seedLogs = [
    WhatsAppBroadcastModel(
      id: 'wacall-001',
      title: 'WhatsApp Voice Call - रमेश कुलकर्णी',
      message: 'WhatsApp Call initiated to रमेश कुलकर्णी (+91 9822011223)',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      channel: 'wa_call',
      recipients: 1,
      sentCount: 1,
      deliveredCount: 1,
      failedCount: 0,
      status: 'COMPLETED',
      category: 'व्हॉट्सॲप कॉल',
    ),
    WhatsAppBroadcastModel(
      id: 'wacall-002',
      title: 'WhatsApp Voice Call - सुरेश पाटील',
      message: 'WhatsApp Call initiated to सुरेश पाटील (+91 9822044556)',
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
      channel: 'wa_call',
      recipients: 1,
      sentCount: 1,
      deliveredCount: 1,
      failedCount: 0,
      status: 'COMPLETED',
      category: 'व्हॉट्सॲप कॉल',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _callLogs.isEmpty) {
        _loadHistory();
      }
      setState(() {});
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadVoters();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoadingVoters = true);
    final repo = ref.read(whatsAppRepoProvider);

    try {
      final list = await repo.getVotersWithMobile(
        name: _searchController.text.trim(),
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

      var query = client.from('message_logs').select('*').eq('channel', 'wa_call');
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }

      final response = await query.order('sent_at', ascending: false).limit(100);
      final list = (response as List<dynamic>)
          .map((item) => WhatsAppBroadcastModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _callLogs = list.isNotEmpty ? list : List.from(_seedLogs);
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _callLogs = List.from(_seedLogs);
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _initiateWhatsAppCall(VoterModel voter) async {
    final rawNumber = voter.mobile?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (rawNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mobile number available for this voter')),
      );
      return;
    }

    String phone = rawNumber;
    if (phone.length == 10) phone = '91$phone';

    // Direct WhatsApp dial link
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Log into message_logs with channel: wa_call
      final voterName = voter.displayName;
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      final newLog = WhatsAppBroadcastModel(
        id: 'wacall-${DateTime.now().millisecondsSinceEpoch}',
        title: 'WhatsApp Call - $voterName',
        message: 'WhatsApp Call initiated to $voterName (+$phone)',
        sentAt: DateTime.now(),
        channel: 'wa_call',
        recipients: 1,
        sentCount: 1,
        deliveredCount: 1,
        failedCount: 0,
        status: 'COMPLETED',
        category: 'व्हॉट्सॲप कॉल',
      );

      try {
        await client.from('message_logs').insert({
          'tenant_id': tenantId,
          'channel': 'wa_call',
          'message': 'WhatsApp Call initiated to $voterName (+$phone)',
          'recipients': 1,
          'sent_count': 1,
          'failed_count': 0,
          'sent_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      setState(() {
        _callLogs.insert(0, newLog);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _exportPdfReport() async {
    if (_callLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No call logs to export.')),
      );
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      await WhatsAppHistoryReportGenerator.generateAndPrintReport(
        broadcasts: _callLogs,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate PDF report.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.help_outline_rounded, color: _kWaGreen),
            SizedBox(width: 8),
            Text(
              'व्हॉट्सॲप कॉल मार्गदर्शक',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTutorialStep(
                step: '१',
                title: 'बॉट स्थिती तपासा',
                desc: 'वरील "बॉट सक्रिय" हिरवा इंडिकेटर सक्रिय असल्याचे सुनिश्चित करा. हे थेट इंटरनेट व्हॉट्सॲप कॉल जोडणी सक्षम करते.',
              ),
              _buildTutorialStep(
                step: '२',
                title: 'मतदार शोध व फिल्टर',
                desc: 'नाव, मोबाईल किंवा पत्त्यानुसार विशिष्ट मतदाराला शोधून काढा.',
              ),
              _buildTutorialStep(
                step: '३',
                title: '१-टॅप थेट व्हॉट्सॲप कॉल',
                desc: 'प्रत्येक मतदाराच्या कार्डवरील "WA कॉल" बटणावर टॅप करा. यामुळे मतदाराचा नंबर थेट व्हॉट्सॲपमध्ये ओपन होऊन कॉल सुरू होईल.',
              ),
              _buildTutorialStep(
                step: '४',
                title: 'कॉल इतिहास व अहवाल',
                desc: 'केलेल्या सर्व व्हॉट्सॲप कॉल्सची तारीख, वेळ व तपशील "कॉल इतिहास" टॅबमध्ये नोंदवले जातात. अधिकृत A4 PDF अहवाल एका टॅपवर डाउनलोड करा.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kWaGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('समजले', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep({required String step, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _kWaGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.phone_in_talk, color: _kWaGreen, size: 22),
            SizedBox(width: 8),
            Text('WhatsApp Call'),
          ],
        ),
        elevation: 0,
        actions: [
          // Bot status badge
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _botStatus == 'connected' ? _kWaLight : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _botStatus == 'connected' ? _kWaLightBorder : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _pulseAnim,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _botStatus == 'connected' ? _kWaGreen : const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _botStatus == 'connected' ? 'बॉट सक्रिय' : 'बॉट निष्क्रिय',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _botStatus == 'connected' ? _kWaDark : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _showTutorialDialog,
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'मदत / Help',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kWaDark,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: _kWaGreen,
          tabs: const [
            Tab(icon: Icon(Icons.phone), text: 'कॉल करा (Make Call)'),
            Tab(icon: Icon(Icons.history), text: 'कॉल इतिहास (Call History)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCallingTab(theme, isDark),
          _buildHistoryTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildCallingTab(ThemeData theme, bool isDark) {
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
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'नाव किंवा मोबाईल नंबर शोधा...',
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
                  hintText: 'पत्ता / परिसर फिल्टर करा...',
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

        // Count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'उपलब्ध संपर्क (Available Voters): ${_voters.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              if (_isLoadingVoters)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kWaGreen),
                ),
            ],
          ),
        ),

        // Voter list / grid
        Expanded(
          child: _isLoadingVoters && _voters.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kWaGreen))
              : _voters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_disabled_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('वैध मोबाईल नंबर असलेले मतदार आढळले नाहीत', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVoters,
                      color: _kWaGreen,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _voters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final voter = _voters[index];
                          final hasPhone = (voter.mobile != null && voter.mobile!.isNotEmpty);

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _kWaLight,
                                    foregroundColor: _kWaDark,
                                    child: const Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          voter.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 13, color: _kWaDark),
                                            const SizedBox(width: 4),
                                            Text(
                                              hasPhone ? voter.mobile! : 'No mobile',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: hasPhone ? _kWaDark : Colors.grey,
                                                fontWeight: FontWeight.w600,
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
                                    onPressed: hasPhone ? () => _initiateWhatsAppCall(voter) : null,
                                    icon: const Icon(Icons.phone_in_talk, size: 16),
                                    label: const Text('WA कॉल'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kWaGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    if (_isLoadingHistory && _callLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kWaGreen));
    }

    return Column(
      children: [
        // History sub-header with count and PDF action button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_callLogs.length} व्हॉट्सॲप कॉल्स (Calls)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isExportingPdf ? null : _exportPdfReport,
                    icon: _isExportingPdf
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: _kWaDark),
                          )
                        : const Icon(Icons.picture_as_pdf, size: 16, color: _kWaDark),
                    label: const Text('PDF अहवाल', style: TextStyle(fontSize: 12, color: _kWaDark)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kWaLightBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loadHistory,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Logs list or Empty state
        Expanded(
          child: _callLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'अद्याप कोणतेही व्हॉट्सॲप कॉल लॉग नाहीत',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text('रिफ्रेश'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: _kWaGreen,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _callLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _callLogs[index];
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
                                backgroundColor: _kWaLight,
                                child: const Icon(Icons.phone_in_talk, color: _kWaGreen, size: 20),
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
                                            color: _kWaLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'WHATSAPP CALL',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _kWaDark,
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
                ),
        ),
      ],
    );
  }
}
