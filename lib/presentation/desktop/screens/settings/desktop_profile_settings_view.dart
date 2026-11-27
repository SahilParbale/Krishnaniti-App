import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/navigation_provider.dart';
import 'desktop_bot_dashboard_view.dart';

class DesktopProfileSettingsView extends ConsumerStatefulWidget {
  final String? initialTab;
  const DesktopProfileSettingsView({super.key, this.initialTab});

  @override
  ConsumerState<DesktopProfileSettingsView> createState() => _DesktopProfileSettingsViewState();
}

class _DesktopProfileSettingsViewState extends ConsumerState<DesktopProfileSettingsView> {
  String _activeTab = 'profile'; // 'profile' | 'bot' | 'sms' | 'security' | 'support'

  // Profile Form Controllers
  final _nameEnCtrl = TextEditingController(text: 'Ramesh Patil');
  final _nameMrCtrl = TextEditingController(text: 'Ramesh Patil');
  final _wardNameCtrl = TextEditingController(text: 'Kasba - Vishrambaug');
  final _wardNoCtrl = TextEditingController(text: '12');
  final _partyCtrl = TextEditingController(text: 'Nationalist Congress Party');
  final _addressCtrl = TextEditingController(text: 'Shaniwar Peth, Bajirao Road, Pune - 411030');
  final _hoursCtrl = TextEditingController(text: 'Morning 9:00 AM - 1:00 PM, Evening 5:00 PM - 8:00 PM');
  final _phoneCtrl = TextEditingController(text: '+91 98220 12345');
  final _emailCtrl = TextEditingController(text: 'ramesh.patil.corporator@gmail.com');
  bool _isSavingProfile = false;

  // SMS Gateway state
  bool _isSmsConnected = true;
  final _apiKeyCtrl = TextEditingController(text: 'sec_sms_gateway_live_prod_8829');

  // Support ticket form
  final _ticketTitleCtrl = TextEditingController();
  final _ticketDescCtrl = TextEditingController();
  String _ticketPriority = 'Medium';

  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TKT-101',
      'title': 'Voter roll import EPIC number mismatch error',
      'priority': 'High',
      'status': 'Resolved',
      'date': DateTime.now().subtract(const Duration(days: 4)),
    },
    {
      'id': 'TKT-102',
      'title': 'WhatsApp automated bot QR code reconnection request',
      'priority': 'Medium',
      'status': 'In Progress',
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _activeTab = widget.initialTab!;
    } else {
      _activeTab = ref.read(desktopSettingsTabProvider);
    }
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameMrCtrl.dispose();
    _wardNameCtrl.dispose();
    _wardNoCtrl.dispose();
    _partyCtrl.dispose();
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _apiKeyCtrl.dispose();
    _ticketTitleCtrl.dispose();
    _ticketDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _submitSupportTicket() {
    if (_ticketTitleCtrl.text.trim().isEmpty || _ticketDescCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and description')),
      );
      return;
    }
    setState(() {
      _tickets.insert(0, {
        'id': 'TKT-${DateTime.now().millisecondsSinceEpoch % 1000}',
        'title': _ticketTitleCtrl.text.trim(),
        'priority': _ticketPriority,
        'status': 'Pending',
        'date': DateTime.now(),
      });
      _ticketTitleCtrl.clear();
      _ticketDescCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support ticket submitted successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    ref.listen<String>(desktopSettingsTabProvider, (prev, next) {
      if (next != _activeTab && mounted) {
        setState(() => _activeTab = next);
      }
    });

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
                      child: const Icon(Icons.settings_rounded, color: AppColors.brandPrimary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.getNavTitle('profile_settings', lang),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang == 'mr'
                              ? 'नगरसेवक प्रोफाईल माहिती, एसएमएस गेटवे, सुरक्षा सत्रे आणि सपोर्ट व्यवस्थापन'
                              : (lang == 'hi'
                                  ? 'नगरसेवक प्रोफाइल जानकारी, एसएमएस गेटवे, सुरक्षा सत्र और सहायता प्रबंधन'
                                  : 'Manage corporator profile info, SMS connection gateway, security sessions, and support'),
                          style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                        ),
                      ],
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
                  _buildTabButton('profile', lang == 'mr' ? 'प्रोफाईल तपशील' : (lang == 'hi' ? 'प्रोफाइल विवरण' : 'Profile Details'), Icons.person_outline_rounded),
                  _buildTabButton('bot', lang == 'mr' ? 'व्हॉट्सॲप बॉट' : (lang == 'hi' ? 'व्हाट्सएप बॉट' : 'WhatsApp Bot'), Icons.smart_toy_outlined),
                  _buildTabButton('sms', lang == 'mr' ? 'एसएमएस गेटवे' : (lang == 'hi' ? 'एसएमएस गेटवे' : 'SMS Gateway'), Icons.phone_android_rounded),
                  _buildTabButton('security', lang == 'mr' ? 'सुरक्षा लॉग' : (lang == 'hi' ? 'सुरक्षा लॉग' : 'Security Logs'), Icons.shield_outlined),
                  _buildTabButton('support', lang == 'mr' ? 'सपोर्ट तिकिटे' : (lang == 'hi' ? 'सहायता टिकट' : 'Support Tickets'), Icons.support_agent_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_activeTab == 'profile') ...[
              // Profile Form Container
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
                      lang == 'mr' ? 'प्रतिनिधी माहिती' : (lang == 'hi' ? 'प्रतिनिधि जानकारी' : 'Representative Information'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(lang == 'mr' ? 'नाव (इंग्रजी):' : (lang == 'hi' ? 'नाम (अंग्रेजी):' : 'Name (English):'), _nameEnCtrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(lang == 'mr' ? 'नाव (मराठी/हिंदी):' : (lang == 'hi' ? 'नाम (क्षेत्रीय):' : 'Name (Regional):'), _nameMrCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(lang == 'mr' ? 'प्रभाग नाव:' : (lang == 'hi' ? 'वार्ड नाम:' : 'Ward Name:'), _wardNameCtrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(lang == 'mr' ? 'प्रभाग क्रमांक:' : (lang == 'hi' ? 'वार्ड नंबर:' : 'Ward Number:'), _wardNoCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(lang == 'mr' ? 'पक्ष:' : (lang == 'hi' ? 'दल / पार्टी:' : 'Political Party:'), _partyCtrl),
                    const SizedBox(height: 16),
                    _buildFormField(lang == 'mr' ? 'कार्यालय पत्ता:' : (lang == 'hi' ? 'कार्यालय का पता:' : 'Official Office Address:'), _addressCtrl),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(lang == 'mr' ? 'मोबाईल नंबर:' : (lang == 'hi' ? 'मोबाइल नंबर:' : 'Contact Phone:'), _phoneCtrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(lang == 'mr' ? 'ईमेल आयडी:' : (lang == 'hi' ? 'ईमेल आईडी:' : 'Official Email:'), _emailCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(lang == 'mr' ? 'कार्यालयीन वेळ:' : (lang == 'hi' ? 'कार्यालय का समय:' : 'Office Visiting Hours:'), _hoursCtrl),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSavingProfile ? null : () => _saveProfile(),
                        icon: _isSavingProfile
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(lang == 'mr' ? 'बदल जतन करा' : (lang == 'hi' ? 'परिवर्तन सहेजें' : 'Save Profile Details')),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_activeTab == 'bot') ...[
              const DesktopBotDashboardView(),
            ] else if (_activeTab == 'sms') ...[
              // SMS Gateway Connection
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SMS Gateway Connection Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isSmsConnected ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isSmsConnected ? Colors.green : Colors.red),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isSmsConnected ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                                color: _isSmsConnected ? Colors.green : Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isSmsConnected ? 'CONNECTED' : 'DISCONNECTED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isSmsConnected ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.smartphone_rounded, color: AppColors.brandPrimary, size: 36),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Samsung Galaxy M34 (Dedicated Ward SIM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                SizedBox(height: 2),
                                Text(
                                  'Last active: 2 mins ago  •  Battery: 92%',
                                  style: TextStyle(fontSize: 12, color: AppColors.slate500),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSmsConnected ? Colors.red.shade50 : AppColors.brandPrimary,
                              foregroundColor: _isSmsConnected ? Colors.red : Colors.white,
                              elevation: 0,
                              side: BorderSide(color: _isSmsConnected ? Colors.red.shade200 : AppColors.brandPrimary),
                            ),
                            onPressed: () {
                              setState(() => _isSmsConnected = !_isSmsConnected);
                            },
                            child: Text(
                              _isSmsConnected ? 'Disconnect' : 'Connect Gateway',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_activeTab == 'security') ...[
              // Security Logs
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Security & Device Sessions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Signed out other device sessions')),
                                );
                              },
                              icon: const Icon(Icons.logout_rounded, size: 16),
                              label: const Text('Sign Out Others'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSessionItem('Windows 11 PC (Current Session)', 'Chrome 122  •  IP: 49.36.120.45', 'Active Now', true),
                    const Divider(color: AppColors.slate100),
                    _buildSessionItem('iPhone 15 Pro', 'Safari Mobile  •  IP: 152.58.21.90', 'Yesterday, 08:30 PM', false),
                    const Divider(color: AppColors.slate100),
                    _buildSessionItem('MacBook Pro', 'Chrome Desktop  •  IP: 114.143.78.12', '3 days ago', false),
                  ],
                ),
              ),
            ] else ...[
              // Support Tickets
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Create ticket form
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Raise New Support Ticket',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                          ),
                          const SizedBox(height: 16),
                          _buildFormField('Subject / Issue Title:', _ticketTitleCtrl),
                          const SizedBox(height: 14),
                          const Text('Priority:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _ticketPriority,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Low', child: Text('Low')),
                              DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'High', child: Text('High')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _ticketPriority = v);
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _ticketDescCtrl,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Describe the technical problem in detail...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _submitSupportTicket(),
                              child: const Text('Submit Ticket'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Tickets List
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Previous Support Tickets',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tickets.length,
                            separatorBuilder: (_, __) => const Divider(color: AppColors.slate100),
                            itemBuilder: (ctx, i) {
                              final t = _tickets[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(t['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate500)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: t['status'] == 'Resolved' ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            t['status'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: t['status'] == 'Resolved' ? Colors.green : Colors.amber.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate800)),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(t['date']),
                                      style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionItem(String device, String meta, String status, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.brandPrimary.withValues(alpha: 0.1) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCurrent ? Icons.computer_rounded : Icons.phone_iphone_rounded,
                  color: isCurrent ? AppColors.brandPrimary : AppColors.slate600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800)),
                  const SizedBox(height: 2),
                  Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.green.withValues(alpha: 0.1) : AppColors.slate100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.green : AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return InkWell(
      onTap: () {
        setState(() => _activeTab = key);
        ref.read(desktopSettingsTabProvider.notifier).setTab(key);
      },
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
