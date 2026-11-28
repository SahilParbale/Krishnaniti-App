import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/tenant_provider.dart';

const String _kBotSocketUrl = 'https://nagarsevak-managment-1.onrender.com';

class DesktopBotDashboardView extends ConsumerStatefulWidget {
  const DesktopBotDashboardView({super.key});

  @override
  ConsumerState<DesktopBotDashboardView> createState() => _DesktopBotDashboardViewState();
}

class _DesktopBotDashboardViewState extends ConsumerState<DesktopBotDashboardView>
    with SingleTickerProviderStateMixin {
  io_client.Socket? _socket;
  String _status = 'disconnected';
  String _qrCode = '';
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initSocket();
  }

  void _initSocket() {
    final tenantState = ref.read(tenantProvider);
    final tenantId = tenantState.tenant?.id ?? 'ward-12';

    try {
      _socket = io_client.io(
        _kBotSocketUrl,
        io_client.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        debugPrint('[Desktop WhatsApp Bot] Connected to Socket.IO server');
        _socket?.emit('join_tenant', {'tenantId': tenantId});
        _socket?.emit('start_session', {'tenantId': tenantId});
      });

      _socket?.onDisconnect((_) {
        debugPrint('[Desktop WhatsApp Bot] Disconnected from Socket.IO server');
        if (mounted) {
          setState(() {
            _status = 'disconnected';
          });
        }
      });

      _socket?.on('status', (newStatus) {
        debugPrint('[Desktop WhatsApp Bot] Status: $newStatus');
        if (mounted) {
          final s = newStatus?.toString() ?? 'disconnected';
          setState(() {
            _status = s;
          });

          // Auto-start session if backend reports disconnected
          if (s == 'disconnected') {
            _socket?.emit('start_session', {'tenantId': tenantId});
          }
        }
      });

      _socket?.on('qr', (qr) {
        debugPrint('[Desktop WhatsApp Bot] QR received');
        if (mounted) {
          setState(() {
            _qrCode = qr?.toString() ?? '';
            _status = 'scanning';
          });
        }
      });

      _socket?.on('logged_out', (_) {
        debugPrint('[Desktop WhatsApp Bot] Bot logged out explicitly');
        if (mounted) {
          setState(() {
            _status = 'disconnected';
            _qrCode = '';
          });
          _socket?.emit('start_session', {'tenantId': tenantId});
        }
      });
    } catch (e) {
      debugPrint('[Desktop WhatsApp Bot] Socket initialization failed: $e');
      if (mounted) {
        setState(() {
          _status = 'failed';
        });
      }
    }
  }

  void _handleLogout() {
    final tenantState = ref.read(tenantProvider);
    final tenantId = tenantState.tenant?.id ?? 'ward-12';
    final lang = ref.read(desktopLanguageProvider);
    if (_socket != null) {
      _socket?.emit('logout_session', {'tenantId': tenantId});
      setState(() {
        _status = 'disconnected';
        _qrCode = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'WhatsApp bot session reset requested.',
              mr: 'WhatsApp बॉट सत्र रीसेट करण्याची विनंती केली आहे.',
              hi: 'WhatsApp बॉट सत्र रीसेट का अनुरोध किया गया है।',
            ),
          ),
          backgroundColor: AppColors.brandPrimary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Color _getStatusTextColor() {
    switch (_status) {
      case 'connected':
        return const Color(0xFF16A34A);
      case 'scanning':
        return const Color(0xFFEA580C);
      case 'authenticated':
        return const Color(0xFF2563EB);
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF475569);
    }
  }

  Color _getStatusBgColor() {
    switch (_status) {
      case 'connected':
        return const Color(0xFFF0FDF4);
      case 'scanning':
        return const Color(0xFFFFF7ED);
      case 'authenticated':
        return const Color(0xFFEFF6FF);
      case 'failed':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  Color _getStatusBorderColor() {
    switch (_status) {
      case 'connected':
        return const Color(0xFFBBF7D0);
      case 'scanning':
        return const Color(0xFFFED7AA);
      case 'authenticated':
        return const Color(0xFFBFDBFE);
      case 'failed':
        return const Color(0xFFFECACA);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  String _getStatusText(String lang) {
    switch (_status) {
      case 'connected':
        return AppTranslations.pick(
          lang,
          en: 'Bot is Online & Ready',
          mr: 'बॉट ऑनलाइन आणि सक्रिय आहे',
          hi: 'बॉट ऑनलाइन और सक्रिय है',
        );
      case 'scanning':
        return AppTranslations.pick(
          lang,
          en: 'Scan QR Code',
          mr: 'QR कोड स्कॅन करा',
          hi: 'QR कोड स्कैन करें',
        );
      case 'authenticated':
        return AppTranslations.pick(
          lang,
          en: 'Authenticated, Starting...',
          mr: 'प्रमाणीकृत, सुरू होत आहे...',
          hi: 'प्रमाणित, शुरू हो रहा है...',
        );
      case 'disconnected':
        return AppTranslations.pick(
          lang,
          en: 'Bot Disconnected / Offline',
          mr: 'बॉट डिस्कनेक्ट / ऑफलाइन आहे',
          hi: 'बॉट डिस्कनेक्ट / ऑफ़लाइन है',
        );
      case 'connected_to_server':
        return AppTranslations.pick(
          lang,
          en: 'Waiting for Bot...',
          mr: 'बॉटची प्रतीक्षा करत आहे...',
          hi: 'बॉट की प्रतीक्षा हो रही है...',
        );
      case 'failed':
        return AppTranslations.pick(
          lang,
          en: 'Connection Failed - Retry Needed',
          mr: 'कनेक्शन अयशस्वी - पुन्हा प्रयत्न करा',
          hi: 'कनेक्शन विफल - पुनः प्रयास आवश्यक',
        );
      default:
        return _status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'WhatsApp Bot Manager (Baileys)',
                        mr: 'WhatsApp बॉट मॅनेजर (Baileys)',
                        hi: 'WhatsApp बॉट मैनेजर (Baileys)',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Connect official WhatsApp session from desktop to automate broadcasts and citizen replies',
                        mr: 'डेस्कटॉपवरून अधिकृत WhatsApp सत्र लिंक करा आणि स्वयंचलित प्रतिसाद व्यवस्थापित करा',
                        hi: 'ब्रॉडकास्ट और नागरिकों के उत्तर स्वचालित करने के लिए डेस्कटॉप से आधिकारिक WhatsApp सत्र कनेक्ट करें',
                      ),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2-Card Layout (Left: Status & Instructions, Right: QR / Active Session)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 780;
              final leftCard = _buildStatusCard(lang);
              final rightCard = _buildQrCard(lang);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftCard),
                    const SizedBox(width: 20),
                    Expanded(child: rightCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    leftCard,
                    const SizedBox(height: 20),
                    rightCard,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.pick(
              lang,
              en: 'Connection status',
              mr: 'कनेक्शन स्थिती',
              hi: 'कनेक्शन स्थिति',
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 14),

          // Status Badge Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusBgColor(),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _getStatusBorderColor()),
            ),
            child: Row(
              children: [
                if (_status == 'connected')
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22)
                else if (_status == 'scanning')
                  RotationTransition(
                    turns: _spinController,
                    child: const Icon(Icons.sync_rounded, color: Color(0xFFEA580C), size: 22),
                  )
                else
                  const Icon(Icons.power_settings_new_rounded, color: Color(0xFF64748B), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getStatusText(lang),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _getStatusTextColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 15),
                  label: Text(
                    _status == 'connected'
                        ? AppTranslations.pick(lang, en: 'Logout', mr: 'लॉगआउट', hi: 'लॉगआउट')
                        : AppTranslations.pick(lang, en: 'Reset Bot', mr: 'रीसेट करा', hi: 'बॉट रीसेट करें'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Instructions Section
          Text(
            AppTranslations.pick(
              lang,
              en: 'Instructions:',
              mr: 'सूचना (कसे कनेक्ट करावे):',
              hi: 'निर्देश (कैसे कनेक्ट करें):',
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.slate700,
            ),
          ),
          const SizedBox(height: 10),
          _buildInstructionStep(
            number: AppTranslations.formatDigits('1', lang),
            text: AppTranslations.pick(
              lang,
              en: 'Open WhatsApp on your mobile phone.',
              mr: 'तुमच्या मोबाईल फोनवर WhatsApp उघडा.',
              hi: 'अपने मोबाइल फ़ोन पर WhatsApp खोलें।',
            ),
          ),
          _buildInstructionStep(
            number: AppTranslations.formatDigits('2', lang),
            text: AppTranslations.pick(
              lang,
              en: 'Go to Settings > Linked Devices.',
              mr: 'Settings > Linked Devices (लिंक केलेली उपकरणे) वर जा.',
              hi: 'Settings > Linked Devices (लिंक किए गए डिवाइस) पर जाएं।',
            ),
          ),
          _buildInstructionStep(
            number: AppTranslations.formatDigits('3', lang),
            text: AppTranslations.pick(
              lang,
              en: 'Tap on Link a Device.',
              mr: 'Link a Device (डिव्हाइस लिंक करा) वर टॅप करा.',
              hi: 'Link a Device (डिवाइस लिंक करें) पर टैप करें।',
            ),
          ),
          _buildInstructionStep(
            number: AppTranslations.formatDigits('4', lang),
            text: AppTranslations.pick(
              lang,
              en: 'Point your camera at the QR code on this screen.',
              mr: 'तुमचा कॅमेरा स्क्रीनवरील QR कोडवर दाखवून स्कॅन करा.',
              hi: 'अपना कैमरा इस स्क्रीन पर दिख रहे QR कोड की ओर करके स्कैन करें।',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.slate300),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.slate700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(String lang) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      alignment: Alignment.center,
      child: _buildQrContent(lang),
    );
  }

  Widget _buildQrContent(String lang) {
    if (_status == 'connected') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Connected',
              mr: 'कनेक्ट झाले',
              hi: 'कनेक्ट हो गया',
            ),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'The bot is active and responding to messages.',
              mr: 'बॉट सक्रिय आहे आणि नागरिकांच्या संदेशांना प्रतिसाद देत आहे.',
              hi: 'बॉट सक्रिय है और नागरिकों के संदेशों का उत्तर दे रहा है।',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.slate500),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.power_settings_new_rounded, size: 16),
            label: Text(
              AppTranslations.pick(
                lang,
                en: 'Disconnect Bot',
                mr: 'बॉट डिस्कनेक्ट करा',
                hi: 'बॉट डिस्कनेक्ट करें',
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    if (_status == 'scanning' && _qrCode.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: QrImageView(
              data: _qrCode,
              version: QrVersions.auto,
              size: 210.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Scan this QR code with WhatsApp',
              mr: 'हा QR कोड तुमच्या WhatsApp ने स्कॅन करा',
              hi: 'इस QR कोड को अपने WhatsApp से स्कैन करें',
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.slate600, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    // Default: Waiting / connecting
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          turns: _spinController,
          child: const Icon(
            Icons.refresh_rounded,
            color: AppColors.slate400,
            size: 42,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppTranslations.pick(
            lang,
            en: 'Waiting for QR Code...',
            mr: 'QR कोडची प्रतीक्षा करत आहे...',
            hi: 'QR कोड की प्रतीक्षा हो रही है...',
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppTranslations.pick(
            lang,
            en: '(Make sure the bot backend is running)',
            mr: '(बॉट सर्व्हर चालू असल्याची खात्री करा)',
            hi: '(सुनिश्चित करें कि बॉट सर्वर चल रहा है)',
          ),
          style: const TextStyle(fontSize: 11.5, color: AppColors.slate400),
        ),
      ],
    );
  }
}
