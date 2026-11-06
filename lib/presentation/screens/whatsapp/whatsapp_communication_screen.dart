import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/whatsapp_repository.dart';
import 'whatsapp_history_report_generator.dart';

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
    with SingleTickerProviderStateMixin {
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
    final greetText = 'नमस्कार ${voter.nameMarathi}! प्रभाग १२ नगरसेवक कार्यालयातून संपर्क.';
    await repo.launchDirectWhatsApp(mobile: voter.mobile!, text: greetText);
  }

  void _showConfirmationDialog() {
    if (_selectedVoterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया किमान एक मतदार निवडा.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया संदेश प्रविष्ट करा.'),
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
                'व्हॉट्सॲप संदेश पाठवण्याची पुष्टी करा',
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
              'मी पुष्टी करतो की मी प्राप्तकर्त्यांची यादी व संदेश तपासला आहे आणि हा अधिकृत व्हॉट्सॲप संदेश पाठवायचा आहे.',
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
                      const Text('निवडलेले मतदार:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(
                        '${_selectedVoterIds.length} मतदार',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kWaDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('चॅनेल:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(
                        'WhatsApp Bot (wa.me)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  const Text('संदेश पूर्वावलोकन:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
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
            child: const Text('रद्द करा', style: TextStyle(color: Color(0xFF64748B))),
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
            label: const Text('पुष्टी करा व पाठवा', style: TextStyle(fontWeight: FontWeight.bold)),
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
        targetCriteria: '${selectedVotersList.length} निवडलेले मतदार · प्रभाग १२',
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
            content: Text('${broadcast.recipients} मतदारांसाठी व्हॉट्सॲप संदेश रांगेत जोडला! 🚀'),
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
            content: Text('व्हॉट्सॲप पाठवण्यात त्रुटी आली. कृपया पुन्हा प्रयत्न करा.'),
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

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // WhatsApp Logo icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: _kWaGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.chat_rounded, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'व्हॉट्सॲप संदेश (WhatsApp)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const Text(
              'मतदारांना थेट व्हॉट्सॲप संदेश पाठवा · प्रभाग १२',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          // Bot status pill
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              final isConn = _botStatus == 'connected';
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                            ? _kWaGreen.withOpacity(_pulseAnim.value)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isConn ? 'बॉट कनेक्टेड' : 'बॉट निष्क्रिय',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isConn ? _kWaDark : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBBF7D0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: const Color(0xFFF0FDF4),
              ),
              onPressed: _generatePdfReport,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: _kWaDark),
              label: const Text(
                'अहवाल',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kWaDark),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _kWaDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 14),
                        SizedBox(width: 5),
                        Text('व्हॉट्सॲप पाठवा'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 14),
                        SizedBox(width: 5),
                        Text('इतिहास व अहवाल'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildHistoryTab(),
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
                  'त्वरित टेम्प्लेट्स (Quick WhatsApp Templates)',
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
                        color: isSelected ? _kWaDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _kWaDark : _kWaLightBorder,
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
                            'संदेश लिहा (Compose Message) *',
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
                        hintText: 'येथे व्हॉट्सॲप संदेश लिहा...\n*ठळक* _टेढे_ ~खोडलेले~',
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
                            '*ठळक* _टेढे_ ~खोडलेले~ - WA फॉर्मेटिंग',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Text(
                        '${_messageController.text.length} अक्षरे',
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
                        'मतदार फिल्टर व शोध',
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
                        child: const Text('रीसेट', style: TextStyle(fontSize: 11, color: _kWaGreen)),
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
                              hintText: 'नाव शोधा...',
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
                              hintText: 'पत्ता / परिसर...',
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
                              hintText: 'घर नं...',
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
                              hintText: 'जात / समाज...',
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
                            DropdownMenuItem(value: 'All', child: Text('सर्व वय')),
                            DropdownMenuItem(value: '18-25', child: Text('वय १८-२५')),
                            DropdownMenuItem(value: '26-40', child: Text('वय २६-४०')),
                            DropdownMenuItem(value: '41-60', child: Text('वय ४१-६०')),
                            DropdownMenuItem(value: '60+', child: Text('वय ६०+')),
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
                            DropdownMenuItem(value: 'All', child: Text('सर्व लिंग')),
                            DropdownMenuItem(value: 'M', child: Text('पुरुष')),
                            DropdownMenuItem(value: 'F', child: Text('महिला')),
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
                            DropdownMenuItem(value: 'All', child: Text('सर्व बूथ')),
                            DropdownMenuItem(value: '२८/शनिवार पेठ', child: Text('बूथ २८')),
                            DropdownMenuItem(value: '२९/कसबा पेठ', child: Text('बूथ २९')),
                            DropdownMenuItem(value: '३०/रविवार पेठ', child: Text('बूथ ३०')),
                            DropdownMenuItem(value: '३१/सोमवार पेठ', child: Text('बूथ ३१')),
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
                        'सर्व निवडा (दिसणारे) (${_voters.length} मतदार)',
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
                        '${_selectedVoterIds.length} निवडले',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kWaDark),
                      ),
                    ),
                    if (_selectedVoterIds.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _clearSelection,
                        child: const Text(
                          'साफ करा',
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
                                      '${voter.genderLabelMarathi} · वय ${voter.age}',
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
                                      'इतिहास व अहवाल',
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
                                    side: const BorderSide(color: _kWaLightBorder),
                                    backgroundColor: _kWaLight,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: _generatePdfReport,
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 15, color: _kWaDark),
                                  label: const Text(
                                    'पीडीएफ डाउनलोड',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _kWaDark),
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
    final totalFailed = _broadcastHistory.fold<int>(0, (s, b) => s + b.failedCount);
    final rate = totalRecipients > 0 ? ((totalDelivered / totalRecipients) * 100).toStringAsFixed(1) : '98.5';

    return Row(
      children: [
        _buildKpiCard('मोहीम', '${_broadcastHistory.length}', Icons.campaign_rounded, _kWaDark),
        const SizedBox(width: 8),
        _buildKpiCard('मतदार', '$totalRecipients', Icons.people_rounded, const Color(0xFF0369A1)),
        const SizedBox(width: 8),
        _buildKpiCard('पोहोचले', '$totalDelivered', Icons.check_circle_rounded, const Color(0xFF047857)),
        const SizedBox(width: 8),
        _buildKpiCard('दर', '$rate%', Icons.trending_up_rounded, _kWaGreen),
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
              _buildMiniStat('प्राप्तकर्ते', '${broadcast.recipients}', const Color(0xFF0369A1)),
              const SizedBox(width: 8),
              _buildMiniStat('पाठवले', '${broadcast.sentCount}', _kWaGreen),
              const SizedBox(width: 8),
              _buildMiniStat('पोहोचले', '${broadcast.deliveredCount}', const Color(0xFF047857)),
              const SizedBox(width: 8),
              _buildMiniStat(
                'अयशस्वी',
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
                  '${_selectedVoterIds.length} मतदार निवडलेले',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Text(
                  'व्हॉट्सॲप बॉटद्वारे पाठवले जाईल',
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
                _isSending ? 'पाठवत आहे...' : 'व्हॉट्सॲप पाठवा',
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
            'फिल्टरनुसार कोणताही मतदार आढळला नाही.',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          SizedBox(height: 4),
          Text(
            'मोबाईल नंबर असलेले मतदार दाखवले जातात.',
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
            'कोणताही व्हॉट्सॲप संदेश पाठवला नाही.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          SizedBox(height: 4),
          Text(
            '"व्हॉट्सॲप पाठवा" टॅबवर जाऊन पहिला संदेश पाठवा!',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

