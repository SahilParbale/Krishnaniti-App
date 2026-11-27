import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/models/whatsapp_broadcast_model.dart';
import '../../../../data/repositories/whatsapp_repository.dart';
import '../../../providers/navigation_provider.dart';
import '../../shell/desktop_sidebar.dart';
import '../../../screens/whatsapp/whatsapp_history_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopWhatsappView extends ConsumerStatefulWidget {
  const DesktopWhatsappView({super.key});

  @override
  ConsumerState<DesktopWhatsappView> createState() => _DesktopWhatsappViewState();
}

class _DesktopWhatsappViewState extends ConsumerState<DesktopWhatsappView> {
  String _activeTab = 'send'; // 'send' | 'history'

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseNoController = TextEditingController();
  String _selectedGender = '';
  final _casteController = TextEditingController();

  final Set<String> _selectedVoterIds = {};
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isSending = false;
  final bool _isBotConnected = true;

  List<VoterModel> _voters = [];
  int _displayedLimit = 20;
  List<VoterModel> get _visibleVoters =>
      _voters.take(_displayedLimit).toList();

  List<WhatsAppBroadcastModel> _broadcastHistory = [];
  int _historyLimit = 20;
  List<WhatsAppBroadcastModel> get _visibleHistory =>
      _broadcastHistory.take(_historyLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadVoters();
    _loadHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _casteController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() {
      _displayedLimit = 20;
      _isLoading = true;
    });
    try {
      final repo = ref.read(whatsAppRepoProvider);
      final voters = await repo.getVotersWithMobile(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        houseNo: _houseNoController.text.trim().isEmpty ? null : _houseNoController.text.trim(),
        gender: _selectedGender.isEmpty ? null : _selectedGender,
        caste: _casteController.text.trim().isEmpty ? null : _casteController.text.trim(),
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

  Future<void> _loadHistory() async {
    setState(() => _historyLimit = 20);
    try {
      final repo = ref.read(whatsAppRepoProvider);
      final history = await repo.getBroadcastHistory();
      if (mounted) {
        setState(() => _broadcastHistory = history);
      }
    } catch (_) {}
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

  void _confirmAndSend(bool isMr) {
    if (_selectedVoterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one voter')),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter message content')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => DesktopModalDialog(
        title: 'Confirm WhatsApp Broadcast',
        subtitle: 'Review and confirm broadcast details before dispatching',
        icon: Icons.chat_rounded,
        width: 520,
        onClose: () => Navigator.pop(ctx),
        actions: [
          DesktopModalDialog.cancelButton(ctx),
          const SizedBox(width: 12),
          DesktopModalDialog.primaryButton(
            text: 'Send Broadcast',
            icon: Icons.send_rounded,
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSending = true);
              try {
                final repo = ref.read(whatsAppRepoProvider);
                final selectedVoters = _voters.where((v) => _selectedVoterIds.contains(v.id)).toList();
                await repo.sendBulkWhatsApp(
                  title: 'WhatsApp Broadcast ${DateFormat('dd MMM hh:mm a').format(DateTime.now())}',
                  recipients: selectedVoters,
                  message: _messageController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('WhatsApp broadcast sent successfully!'), backgroundColor: AppColors.brand600),
                  );
                  _messageController.clear();
                  _selectedVoterIds.clear();
                  _loadHistory();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSending = false);
              }
            },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to broadcast this WhatsApp message to ${_selectedVoterIds.length} recipients?',
              style: const TextStyle(fontSize: 14, color: AppColors.slate700),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brand200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Message Preview:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.brand700)),
                  const SizedBox(height: 6),
                  Text(_messageController.text, style: const TextStyle(fontSize: 13, color: AppColors.slate800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                      child: const Icon(Icons.chat_bubble_rounded, color: AppColors.brand600, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Communication',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send targeted official WhatsApp updates and monitor delivery history',
                          style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Tooltip(
                      message: 'Click to manage WhatsApp Bot connection & QR code',
                      child: InkWell(
                        onTap: () {
                          ref.read(desktopSettingsTabProvider.notifier).setTab('bot');
                          ref.read(activeScreenProvider.notifier).setScreen('profile_settings');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isBotConnected ? AppColors.brand50 : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isBotConnected ? AppColors.brand200 : const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isBotConnected ? AppColors.brand600 : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isBotConnected
                                    ? ('Bot Active')
                                    : ('Bot Inactive'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isBotConnected ? AppColors.brand600 : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Download Report matching WhatsAppCommunication.tsx
                    OutlinedButton.icon(
                      onPressed: () {
                        WhatsAppHistoryReportGenerator.generateAndPrintReport(
                          context: context,
                          broadcasts: _broadcastHistory,
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: Text(
                        AppTranslations.getDownloadReport(ref.watch(desktopLanguageProvider)),
                        style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F9FF),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
                  _buildTabButton('send', 'Send Message', Icons.send_rounded),
                  _buildTabButton('history', 'Broadcast History', Icons.history_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_activeTab == 'send') ...[
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
                    const SizedBox(width: 12),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _houseNoController,
                        decoration: InputDecoration(
                          hintText: 'House No.',
                          prefixIcon: const Icon(Icons.home_outlined, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _loadVoters(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: AppDropdown<String>(
                        value: _selectedGender,
                        height: 40,
                        prefixIcon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF94A3B8)),
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFFE2E8F0),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All Genders')),
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedGender = v ?? '');
                          _loadVoters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _casteController,
                        decoration: InputDecoration(
                          hintText: 'Caste...',
                          prefixIcon: const Icon(Icons.group_outlined, size: 18),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brand700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2 Column Area
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left List
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
                                    'No voters found with mobile number',
                                    style: const TextStyle(color: AppColors.slate400),
                                  ),
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: ListView.separated(
                                        padding: const EdgeInsets.all(12),
                                        itemCount: _visibleVoters.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (ctx, i) {
                                          final v = _visibleVoters[i];
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
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.slate100,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${v.gender} / ${v.age}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    AppLoadMoreFooter(
                                      currentCount: _visibleVoters.length,
                                      totalCount: _voters.length,
                                      pageSize: 20,
                                      onLoadMore: () {
                                        setState(() => _displayedLimit += 20);
                                      },
                                      label: 'मतदार',
                                      isMarathi: isMr,
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right Compose
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
                              const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brand600, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Compose WhatsApp',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _messageController,
                            maxLines: 10,
                            decoration: InputDecoration(
                              hintText: 'Type WhatsApp message...\nUse *text* for bold, _text_ for italics',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              fillColor: const Color(0xFFF8FAFC),
                              filled: true,
                            ),
                            onChanged: (_) => setState(() {}),
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
                              onPressed: _isSending ? null : () => _confirmAndSend(isMr),
                              icon: _isSending
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                _isSending ? ('Sending...') : ('Broadcast via WhatsApp'),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'WhatsApp Broadcast History',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_broadcastHistory.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No WhatsApp broadcast history found',
                            style: const TextStyle(color: AppColors.slate400),
                          ),
                        ),
                      )
                    else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _visibleHistory.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.slate100),
                        itemBuilder: (ctx, i) {
                          final item = _visibleHistory[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.brand50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.mark_chat_read_rounded, color: AppColors.brand600, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800)),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(item.sentAt),
                                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.brand50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.status.toUpperCase(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brand600),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${item.recipients} recipients',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate700),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      AppLoadMoreFooter(
                        currentCount: _visibleHistory.length,
                        totalCount: _broadcastHistory.length,
                        pageSize: 20,
                        onLoadMore: () {
                          setState(() => _historyLimit += 20);
                        },
                        label: 'मोहिमा',
                        isMarathi: isMr,
                      ),
                    ],
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
                color: isSelected ? AppColors.brand600 : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
