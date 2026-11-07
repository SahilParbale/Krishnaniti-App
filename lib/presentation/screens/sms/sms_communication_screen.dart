import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sms_campaign_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/sms_repository.dart';
import '../../navigation/app_drawer.dart';
import 'sms_history_report_generator.dart';

class SmsCommunicationScreen extends ConsumerStatefulWidget {
  const SmsCommunicationScreen({super.key});

  @override
  ConsumerState<SmsCommunicationScreen> createState() => _SmsCommunicationScreenState();
}

class _SmsCommunicationScreenState extends ConsumerState<SmsCommunicationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _casteController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _ageFilter = 'All';
  String _genderFilter = 'All';
  String _boothFilter = 'All';

  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];
  final Set<String> _selectedVoterIds = {};
  bool _isAllVisibleSelected = false;

  // History state
  bool _isLoadingHistory = false;
  List<SmsCampaignModel> _campaignHistory = [];

  // Compose state
  bool _isSending = false;
  SmsTemplateModel? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _campaignHistory.isEmpty) {
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
    _houseNoController.dispose();
    _casteController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoadingVoters = true);
    final repo = ref.read(smsRepoProvider);

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
    final repo = ref.read(smsRepoProvider);

    try {
      final logs = await repo.getCampaigns();
      if (mounted) {
        setState(() {
          _campaignHistory = logs;
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

  void _applyTemplate(SmsTemplateModel template) {
    setState(() {
      _selectedTemplate = template;
      _messageController.text = template.text;
    });
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
            Icon(Icons.sms_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text('Confirm SMS Campaign', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'I confirm that I have reviewed the recipients and message and wish to send this official SMS.',
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Route / Channel:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const Text('DLT Government Header (SMS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                    ],
                  ),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  const Text('Message Preview:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      _messageController.text.trim(),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
                      maxLines: 4,
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
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeSendSms();
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Confirm & Send', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSendSms() async {
    setState(() => _isSending = true);
    final repo = ref.read(smsRepoProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final selectedVotersList = _voters.where((v) => _selectedVoterIds.contains(v.id)).toList();
      final campaignName = _selectedTemplate != null
          ? _selectedTemplate!.title
          : 'SMS Campaign ${DateFormat('dd MMM HH:mm').format(DateTime.now())}';

      final campaign = await repo.sendSmsCampaign(
        campaignName: campaignName,
        message: _messageController.text.trim(),
        recipients: selectedVotersList,
        dltTemplateId: _selectedTemplate?.dltTeId,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          _selectedVoterIds.clear();
          _isAllVisibleSelected = false;
          _messageController.clear();
          _selectedTemplate = null;
          _campaignHistory.insert(0, campaign);
        });

        messenger.showSnackBar(
          SnackBar(
            content: Text('SMS broadcast queued for ${campaign.totalRecipients} voters!'),
            backgroundColor: const Color(0xFF047857),
            duration: const Duration(seconds: 3),
          ),
        );

        // Switch to history tab to view campaign progress
        _tabController.animateTo(1);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Error sending SMS. Please try again.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _generatePdfReport() async {
    if (_campaignHistory.isEmpty) await _loadHistory();
    await SmsHistoryReportGenerator.generateAndPrintReport(campaigns: _campaignHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF0284C7),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            tooltip: 'Open Menu Drawer',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Send SMS',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Send important notifications & updates to ward voters',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFFE0F2FE),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: Colors.white.withOpacity(0.18),
              ),
              onPressed: _generatePdfReport,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.white),
              label: const Text(
                'Download Report',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
        ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Send SMS'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('History & Reports'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendSmsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _tabController.index == 0 && _selectedVoterIds.isNotEmpty
          ? _buildStickySendBar()
          : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: Send SMS Tab
  // ─────────────────────────────────────────────────────────────
  Widget _buildSendSmsTab() {
    final templates = ref.read(smsRepoProvider).getSmsTemplates();

    return RefreshIndicator(
      onRefresh: _loadVoters,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DLT Registered Templates Strip
            Row(
              children: const [
                Icon(Icons.star_outline_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Registered DLT Templates (Quick Templates)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final t = templates[i];
                  final isSelected = _selectedTemplate?.id == t.id;
                  return InkWell(
                    onTap: () => _applyTemplate(t),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        t.title,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // 2. Compose Message Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Compose Message *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (_selectedTemplate != null)
                        Text(
                          'DLT ID: ${_selectedTemplate!.dltTeId}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Type your message here... (English)',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.info_outline, size: 12, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text(
                            'Note: SMS will be delivered only to voters with registered mobile numbers.',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Text(
                        '${_messageController.text.length} chars · ${(_messageController.text.length / 160).ceil().clamp(1, 10)} SMS',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Filters Section
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
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
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
                        child: const Text('Reset', style: TextStyle(fontSize: 11, color: Colors.white)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 2: Age, Gender, Booth
                  Row(
                    children: [
                      // Age Filter
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _ageFilter,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 11.5, color: Colors.white),
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
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Gender Filter
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _genderFilter,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 11.5, color: Colors.white),
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
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Booth Filter
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _boothFilter,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 11.5, color: Colors.white),
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
                        color: _isAllVisibleSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Select All (${_voters.length} voters)',
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
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedVoterIds.length} Selected',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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

            // 5. Voter Cards List
            if (_isLoadingVoters)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
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
                        color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        voter.displayName,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone, size: 10, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            voter.mobile ?? '-',
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
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
  // UI Builder: History Tab
  // ─────────────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : _campaignHistory.isEmpty
              ? _buildEmptyHistoryState()
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: _campaignHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final campaign = _campaignHistory[idx];
                    return _buildCampaignHistoryCard(campaign);
                  },
                ),
    );
  }

  Widget _buildCampaignHistoryCard(SmsCampaignModel campaign) {
    Color statusBg = const Color(0xFFECFDF5);
    Color statusColor = const Color(0xFF047857);
    if (campaign.isFailed) {
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
    } else if (campaign.isSending) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      campaign.formattedDate,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  campaign.status,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              campaign.message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
            ),
          ),

          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              _buildMiniHistoryStat('Recipients', '${campaign.totalRecipients}', const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildMiniHistoryStat('Delivered', '${campaign.stats.delivered}', const Color(0xFF047857)),
              const SizedBox(width: 8),
              _buildMiniHistoryStat('Failed', '${campaign.stats.failed}', campaign.stats.failed > 0 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8)),
              const Spacer(),
              if (campaign.dltTemplateId != null)
                Text(
                  campaign.dltTemplateId!,
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniHistoryStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStickySendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, -2))],
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text('Dispatched via official DLT registered SMS gateway', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: _isSending ? null : _showConfirmationDialog,
              icon: _isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSending ? 'Sending...' : 'Send SMS',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
            'Modify search query or click Reset.',
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
          Icon(Icons.sms_failed_outlined, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text(
            'No SMS campaigns sent yet.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

