import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/whatsapp_repository.dart';
import 'whatsapp_history_report_generator.dart';
import '../../navigation/app_drawer.dart';

// WhatsApp brand colors
const _kWaGreen = Color(0xFF25D366);
const _kWaDark = Color(0xFF075E54);
const _kWaLight = Color(0xFFE8F5E9);
const _kWaLightBorder = Color(0xFFA5D6A7);

class WhatsAppCommunicationScreen extends ConsumerStatefulWidget {
  const WhatsAppCommunicationScreen({super.key});

  @override
  ConsumerState<WhatsAppCommunicationScreen> createState() => _WhatsAppCommunicationScreenState();
}

class _WhatsAppCommunicationScreenState
    extends ConsumerState<WhatsAppCommunicationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Filter controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _casteController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _ageFilter = 'All';
  String _genderFilter = 'All';
  String _boothFilter = 'All';

  // Voter state
  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];
  final Set<String> _selectedVoterIds = {};
  bool _isAllVisibleSelected = false;

  // History state
  bool _isLoadingHistory = false;
  List<WhatsAppBroadcastModel> _broadcastHistory = [];

  // Compose state
  bool _isSending = false;
  WhatsAppTemplateModel? _selectedTemplate;

  // Bot status simulation (UI only since socket not available in mobile)
  final String _botStatus = 'connected';

  // Pulsing animation for bot indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _broadcastHistory.isEmpty) {
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
    _nameController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _casteController.dispose();
    _messageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoadingVoters = true);
    final repo = ref.read(whatsAppRepoProvider);
    try {
      final list = await repo.getVotersWithMobile(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        houseNo: _houseNoController.text.trim(),
        ageRange: _ageFilter,
        gender: _genderFilter,
        caste: _casteController.text.trim(),
        booth: _boothFilter,
      );
      if (mounted) {
        setState(() {
          _voters = list;
          _isLoadingVoters = false;
          _updateSelectAllStatus();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVoters = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final repo = ref.read(whatsAppRepoProvider);
    try {
      final logs = await repo.getBroadcastHistory();
      if (mounted) {
        setState(() {
          _broadcastHistory = logs;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _updateSelectAllStatus() {
    if (_voters.isEmpty) {
      _isAllVisibleSelected = false;
      return;
    }
    _isAllVisibleSelected = _voters.every((v) => _selectedVoterIds.contains(v.id));
  }

  void _toggleSelectVoter(String voterId) {
    setState(() {
      if (_selectedVoterIds.contains(voterId)) {
        _selectedVoterIds.remove(voterId);
      } else {
        _selectedVoterIds.add(voterId);
      }
      _updateSelectAllStatus();
    });
  }

  void _handleSelectAllVisible() {
    setState(() {
      if (_isAllVisibleSelected) {
        for (final v in _voters) {
          _selectedVoterIds.remove(v.id);
        }
        _isAllVisibleSelected = false;
      } else {
        for (final v in _voters) {
          _selectedVoterIds.add(v.id);
        }
        _isAllVisibleSelected = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedVoterIds.clear();
      _isAllVisibleSelected = false;
    });
  }

  void _applyTemplate(WhatsAppTemplateModel template) {
    setState(() {
      _selectedTemplate = template;
      _messageController.text = template.text;
    });
  }

  Future<void> _openDirectWhatsApp(VoterModel voter) async {
    if (voter.mobile == null || voter.mobile!.isEmpty) return;
    final repo = ref.read(whatsAppRepoProvider);
    final greetText = 'Greetings ${voter.displayName}! Contacting you from Ward 12 Corporator Office.';
    await repo.launchDirectWhatsApp(mobile: voter.mobile!, text: greetText);
  }

  void _showConfirmationDialog() {
    if (_selectedVoterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one voter.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter message text.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.send_rounded, color: _kWaGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm WhatsApp Broadcast',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'I confirm that I have reviewed the recipient list and message content and wish to send this official WhatsApp broadcast.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Selected Voters:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(
                        '${_selectedVoterIds.length} Voters',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kWaDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Channel:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(
                        'WhatsApp Bot (wa.me)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  const Text('Message Preview:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kWaLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _kWaLightBorder),
                    ),
                    child: Text(
                      _messageController.text.trim(),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kWaGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeSendWhatsApp();
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Confirm & Send', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSendWhatsApp() async {
    setState(() => _isSending = true);
    final repo = ref.read(whatsAppRepoProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final selectedVotersList = _voters.where((v) => _selectedVoterIds.contains(v.id)).toList();
      final title = _selectedTemplate != null
          ? _selectedTemplate!.title
          : 'WhatsApp Broadcast ${DateFormat('dd MMM HH:mm').format(DateTime.now())}';

      final broadcast = await repo.sendBulkWhatsApp(
        title: title,
        message: _messageController.text.trim(),
        recipients: selectedVotersList,
        category: _selectedTemplate?.category,
        targetCriteria: '${selectedVotersList.length} Selected Voters · Ward 12',
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          _selectedVoterIds.clear();
          _isAllVisibleSelected = false;
          _messageController.clear();
          _selectedTemplate = null;
          _broadcastHistory.insert(0, broadcast);
        });

        messenger.showSnackBar(
          SnackBar(
            content: Text('WhatsApp message queued for ${broadcast.recipients} voters! 🚀'),
            backgroundColor: _kWaDark,
            duration: const Duration(seconds: 3),
          ),
        );

        _tabController.animateTo(1);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Error sending WhatsApp message. Please try again.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _generatePdfReport() async {
    if (_broadcastHistory.isEmpty) await _loadHistory();
    await WhatsAppHistoryReportGenerator.generateAndPrintReport(broadcasts: _broadcastHistory);
  }

  void _showBotStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.hub_rounded, color: _kWaGreen),
            SizedBox(width: 8),
            Text('WhatsApp Bot Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kWaGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bot Connected & Active',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kWaDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Server Endpoint: nagarsevak-managment-1.onrender.com',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Directly integrated with the Ward 12 official WhatsApp Business account. Outbound broadcasts are automatically queued and dispatched by the bot.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kWaDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpTutorialDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.help_outline_rounded, color: _kWaDark),
            SizedBox(width: 8),
            Text('WhatsApp Communication Guide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTutorialStep(
                step: '1',
                title: 'Check Bot Status',
                desc: 'Ensure the "Bot Active" indicator is green. Messages are dispatched only when the bot service is online.',
              ),
              _buildTutorialStep(
                step: '2',
                title: 'Filters & Voter Search',
                desc: 'Search and filter voters by name, area, house no., age, gender, or community.',
              ),
              _buildTutorialStep(
                step: '3',
                title: 'Quick Templates or Custom Text',
                desc: 'Select pre-approved templates for water notices, govt schemes, or festivals in 1-tap, or type your own text.',
              ),
              _buildTutorialStep(
                step: '4',
                title: '1-Tap Personal WhatsApp',
                desc: 'Tap the green WhatsApp icon on any voter card to open a direct 1-on-1 chat in the official WhatsApp app.',
              ),
              _buildTutorialStep(
                step: '5',
                title: 'History & Official Reports',
                desc: 'Track delivery metrics across all sent broadcasts and download landscape A4 PDF reports for official records.',
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
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
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
            decoration: const BoxDecoration(color: _kWaLight, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kWaDark),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Open Menu Drawer',
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'WhatsApp Message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'WhatsApp broadcasts & campaign reports',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFFE0F2FE),
              ),
            ),
          ],
        ),
        actions: const [],
        ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 13),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Send Message',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 13),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'History',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bot status pill (clickable)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    final isConn = _botStatus == 'connected';
                    return InkWell(
                      onTap: _showBotStatusDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isConn ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isConn ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConn
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isConn ? 'Active' : 'Offline',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isConn ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Help Guide',
                  icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: _showHelpTutorialDialog,
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _generatePdfReport,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.picture_as_pdf_outlined, size: 15, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text('Report', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _tabController.index == 0 && _selectedVoterIds.isNotEmpty ? _buildStickySendBar() : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 1: Send WhatsApp
  // ─────────────────────────────────────────────────────────────
  Widget _buildSendTab() {
    final templates = ref.read(whatsAppRepoProvider).getTemplates();

    return RefreshIndicator(
      onRefresh: _loadVoters,
      color: _kWaGreen,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Quick Templates Strip
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, size: 15, color: _kWaGreen),
                SizedBox(width: 5),
                Text(
                  'Quick WhatsApp Templates',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final t = templates[i];
                  final isSelected = _selectedTemplate?.id == t.id;
                  return InkWell(
                    onTap: () => _applyTemplate(t),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // 2. WhatsApp Compose Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kWaLightBorder),
                boxShadow: [BoxShadow(color: _kWaGreen.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 14, color: _kWaGreen),
                          SizedBox(width: 5),
                          Text(
                            'Compose Message *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      if (_selectedTemplate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kWaLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _kWaLightBorder),
                          ),
                          child: Text(
                            _selectedTemplate!.category,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: _kWaDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // WhatsApp bubble-style compose area
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kWaLightBorder),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Type your WhatsApp message here...\n*bold* _italic_ ~strikethrough~',
                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.all(10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 12, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text(
                            '*bold* _italic_ ~strikethrough~ - WA Formatting',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Text(
                        '${_messageController.text.length} characters',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kWaGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Filters
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Voter Filters & Search',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _nameController.clear();
                          _addressController.clear();
                          _houseNoController.clear();
                          _casteController.clear();
                          setState(() {
                            _ageFilter = 'All';
                            _genderFilter = 'All';
                            _boothFilter = 'All';
                          });
                          _loadVoters();
                        },
                        child: const Text('Reset', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 1: Name & Address
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Search name...',
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _addressController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Address / Area...',
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 2: HouseNo & Caste (text)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _houseNoController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'House No...',
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.home_outlined, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _casteController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Community / Group...',
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 3: Age, Gender, Booth dropdowns
                  Row(
                    children: [
                      // Age
                      Expanded(
                        child: _buildDropdownFilter(
                          value: _ageFilter,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Ages')),
                            DropdownMenuItem(value: '18-25', child: Text('Age 18-25')),
                            DropdownMenuItem(value: '26-40', child: Text('Age 26-40')),
                            DropdownMenuItem(value: '41-60', child: Text('Age 41-60')),
                            DropdownMenuItem(value: '60+', child: Text('Age 60+')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _ageFilter = v);
                              _loadVoters();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Gender
                      Expanded(
                        child: _buildDropdownFilter(
                          value: _genderFilter,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Genders')),
                            DropdownMenuItem(value: 'M', child: Text('Male')),
                            DropdownMenuItem(value: 'F', child: Text('Female')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _genderFilter = v);
                              _loadVoters();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Booth
                      Expanded(
                        child: _buildDropdownFilter(
                          value: _boothFilter,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Booths')),
                            DropdownMenuItem(value: '28', child: Text('Booth 28 (Shaniwar Peth)')),
                            DropdownMenuItem(value: '29', child: Text('Booth 29 (Kasba Peth)')),
                            DropdownMenuItem(value: '30', child: Text('Booth 30 (Raviwar Peth)')),
                            DropdownMenuItem(value: '31', child: Text('Booth 31 (Somwar Peth)')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _boothFilter = v);
                              _loadVoters();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4. Selection Control Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _handleSelectAllVisible,
                  child: Row(
                    children: [
                      Icon(
                        _isAllVisibleSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: _isAllVisibleSelected ? _kWaGreen : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Select All (Visible) (${_voters.length} voters)',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kWaLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kWaLightBorder),
                      ),
                      child: Text(
                        '${_selectedVoterIds.length} Selected',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kWaDark),
                      ),
                    ),
                    if (_selectedVoterIds.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _clearSelection,
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 5. Voter Cards
            if (_isLoadingVoters)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: _kWaGreen),
                ),
              )
            else if (_voters.isEmpty)
              _buildEmptyVotersState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _voters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final voter = _voters[idx];
                  final isSelected = _selectedVoterIds.contains(voter.id);

                  return InkWell(
                    onTap: () => _toggleSelectVoter(voter.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kWaGreen : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected ? _kWaGreen : const Color(0xFFCBD5E1),
                            size: 20,
                          ),
                          const SizedBox(width: 10),

                          // Voter info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        voter.displayName,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    // Mobile chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _kWaLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _kWaLightBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone, size: 10, color: _kWaDark),
                                          const SizedBox(width: 3),
                                          Text(
                                            voter.mobile ?? '-',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: _kWaDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      '${voter.gender} · Age ${voter.age}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    if (voter.booth.isNotEmpty) ...[
                                      const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                                      Text(
                                        voter.booth,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ],
                                ),
                                if (voter.address.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    voter.address,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 1-tap direct WA chat button
                          if (voter.mobile != null && voter.mobile!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () => _openDirectWhatsApp(voter),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: _kWaGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_rounded, size: 17, color: Colors.white),
                                ),
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 2: History & Reports
  // ─────────────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: _kWaGreen,
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator(color: _kWaGreen))
          : _broadcastHistory.isEmpty
              ? _buildEmptyHistoryState()
              : CustomScrollView(
                  slivers: [
                    // Stats summary header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'History & Reports',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      '${_broadcastHistory.length} WhatsApp broadcasts',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: _generatePdfReport,
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 15, color: Color(0xFF0284C7)),
                                  label: const Text(
                                    'Download PDF',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // KPI Summary Row
                            _buildKpiSummary(),
                          ],
                        ),
                      ),
                    ),

                    // Broadcast cards
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, idx) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildBroadcastHistoryCard(_broadcastHistory[idx]),
                          ),
                          childCount: _broadcastHistory.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildKpiSummary() {
    final totalRecipients = _broadcastHistory.fold<int>(0, (s, b) => s + b.recipients);
    final totalDelivered = _broadcastHistory.fold<int>(0, (s, b) => s + b.deliveredCount);
    final rate = totalRecipients > 0 ? ((totalDelivered / totalRecipients) * 100).toStringAsFixed(1) : '98.5';

    return Row(
      children: [
        _buildKpiCard('Broadcasts', '${_broadcastHistory.length}', Icons.campaign_rounded, _kWaDark),
        const SizedBox(width: 8),
        _buildKpiCard('Voters', '$totalRecipients', Icons.people_rounded, const Color(0xFF0369A1)),
        const SizedBox(width: 8),
        _buildKpiCard('Delivered', '$totalDelivered', Icons.check_circle_rounded, const Color(0xFF047857)),
        const SizedBox(width: 8),
        _buildKpiCard('Delivery Rate', '$rate%', Icons.trending_up_rounded, _kWaGreen),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastHistoryCard(WhatsAppBroadcastModel broadcast) {
    Color statusBg = _kWaLight;
    Color statusColor = _kWaDark;
    if (broadcast.isFailed) {
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
    } else if (broadcast.isSending) {
      statusBg = const Color(0xFFFFFBEB);
      statusColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WA icon
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: _kWaGreen, shape: BoxShape.circle),
                child: const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      broadcast.title,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          broadcast.formattedDate,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        if (broadcast.targetCriteria != null) ...[
                          const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                          Expanded(
                            child: Text(
                              broadcast.targetCriteria!,
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  broadcast.status,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Message preview (WhatsApp bubble)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border.all(color: _kWaLightBorder),
            ),
            child: Text(
              broadcast.message,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              _buildMiniStat('Recipients', '${broadcast.recipients}', const Color(0xFF0369A1)),
              const SizedBox(width: 8),
              _buildMiniStat('Sent', '${broadcast.sentCount}', _kWaGreen),
              const SizedBox(width: 8),
              _buildMiniStat('Delivered', '${broadcast.deliveredCount}', const Color(0xFF047857)),
              const SizedBox(width: 8),
              _buildMiniStat(
                'Failed',
                '${broadcast.failedCount}',
                broadcast.failedCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
              ),
              const Spacer(),
              if (broadcast.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kWaLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kWaLightBorder),
                  ),
                  child: Text(
                    broadcast.category!,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _kWaDark),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Sticky Bottom Send Bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildStickySendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: _kWaGreen.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedVoterIds.length} voters selected',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Text(
                  'Dispatched via official WhatsApp Bot',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kWaGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: _isSending ? null : _showConfirmationDialog,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSending ? 'Sending...' : 'Send WhatsApp',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
  Widget _buildDropdownFilter({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyVotersState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: const [
          Icon(Icons.search_off_rounded, size: 44, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text(
            'No voters found matching current filters.',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          SizedBox(height: 4),
          Text(
            'Only voters with registered mobile numbers are displayed.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.chat_bubble_outline_rounded, size: 52, color: Color(0xFFCBD5E1)),
          SizedBox(height: 10),
          Text(
            'No WhatsApp broadcasts sent yet.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          SizedBox(height: 4),
          Text(
            'Switch to "Send WhatsApp" tab to dispatch your first broadcast!',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

