import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/krishnaniti_logo.dart';
import '../../navigation/adaptive_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? initialRole;

  const LoginScreen({
    super.key,
    this.initialRole,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _activeRole = 'nagarsevak'; // 'nagarsevak', 'amdar', 'khasdar', 'minister'
  String _subRole = 'nagarsevak'; // 'nagarsevak' or 'staff'

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      _activeRole = widget.initialRole!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeRole = role;
    });
  }

  Future<void> _handleLogin() async {
    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final lang = ref.read(appLanguageProvider);

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter both Email and Password',
              mr: 'कृपया ईमेल आणि पासवर्ड दोन्ही प्रविष्ट करा',
              hi: 'कृपया ईमेल और पासवर्ड दोनों दर्ज करें',
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      await ref.read(authStateProvider.notifier).signIn(
        email,
        password,
        role: _activeRole,
        isStaff: _subRole == 'staff',
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdaptiveScaffold()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        final rawMsg = e.toString().replaceFirst('Exception: ', '');
        final isNetwork = rawMsg.toLowerCase().contains('network') ||
            rawMsg.toLowerCase().contains('socket') ||
            rawMsg.toLowerCase().contains('host lookup') ||
            rawMsg.toLowerCase().contains('errno = 7') ||
            rawMsg.toLowerCase().contains('authretryablefetchexception') ||
            rawMsg.toLowerCase().contains('clientexception');
        final prefix = AppTranslations.pick(
          lang,
          en: 'Sign in failed: ',
          mr: 'लॉगिन अयशस्वी: ',
          hi: 'साइन इन विफल: ',
        );
        if (isNetwork) {
          final netMsg = AppTranslations.pick(
            lang,
            en: 'No internet connection. Please check your network connection and try again.',
            mr: 'इंटरनेट कनेक्शन उपलब्ध नाही. कृपया इंटरनेट तपासा आणि पुन्हा प्रयत्न करा.',
            hi: 'इंटरनेट कनेक्शन उपलब्ध नहीं है। कृपया नेटवर्क जाँचें और पुनः प्रयास करें।',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$prefix$netMsg'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppTranslatedText(
                '$prefix$rawMsg',
                targetLanguage: lang,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  Future<void> _signInDemo() async {
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authStateProvider.notifier).signIn(
        'demo_nagarsevak@demo.com',
        'Password@123',
        role: _activeRole,
        isStaff: _subRole == 'staff',
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdaptiveScaffold()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        final lang = ref.read(appLanguageProvider);
        final rawMsg = e.toString().replaceFirst('Exception: ', '');
        final prefix = AppTranslations.pick(
          lang,
          en: 'Demo sign-in failed: ',
          mr: 'डेमो लॉगिन अयशस्वी: ',
          hi: 'डेमो साइन इन विफल: ',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppTranslatedText(
              '$prefix$rawMsg',
              targetLanguage: lang,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showForgotPasswordSheet(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Forgot Password?',
                        mr: 'पासवर्ड विसरलात?',
                        hi: 'पासवर्ड भूल गए?',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'For administrative security, password resets are handled via your ward system administrator or Krishnaniti IT desk.',
                    mr: 'सुरक्षिततेच्या कारणास्तव पासवर्ड रीसेट करण्यासाठी आपल्या प्रभाग प्रशासक किंवा कृष्णनीती सपोर्टशी संपर्क साधा.',
                    hi: 'प्रशासनिक सुरक्षा के लिए, पासवर्ड रीसेट आपके वार्ड सिस्टम व्यवस्थापक या कृष्णनीति आईटी डेस्क के माध्यम से किया जाता है।',
                  ),
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.45),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.headset_mic_rounded, color: Color(0xFF0284C7), size: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.formatDigits(
                              '${AppTranslations.pick(lang, en: 'Helpline', mr: 'हेल्पलाइन', hi: 'हेल्पलाइन')}: +91 98220 12345',
                              lang,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const Text('support@krishnaniti.in', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      AppTranslations.pick(lang, en: 'Got it', mr: 'समजले', hi: 'समझ गया'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final authState = ref.watch(authStateProvider);
    final isLoading = _isSigningIn || authState.isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
            tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'पीछे'),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          actions: const [
            // Language Selector
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: AppLanguageSegmentedSelector(isCompact: true),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Header
                Row(
                  children: [
                    const KrishnanitiLogo(size: 42),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.pick(lang, en: 'Krishnaniti', mr: 'कृष्णनीती', hi: 'कृष्णनीति'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Administrative Portal',
                            mr: 'प्रशासकीय पोर्टल',
                            hi: 'प्रशासनिक पोर्टल',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Welcome Heading
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Sign in to your account',
                    mr: 'आपल्या खात्यात प्रवेश करा',
                    hi: 'अपने खाते में साइन इन करें',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Select your representative role to proceed.',
                    mr: 'आपल्या भूमिकेनुसार पोर्टल निवडून लॉगिन करा.',
                    hi: 'आगे बढ़ने के लिए अपनी प्रतिनिधि भूमिका चुनें।',
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 20),

                // 1. Role Selector Tabs (Nagarsevak, Amdar, Khasdar, Minister)
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Select Role',
                    mr: 'भूमिका निवडा',
                    hi: 'भूमिका चुनें',
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRolePill(
                        label: AppTranslations.getRoleName('nagarsevak', lang),
                        roleKey: 'nagarsevak',
                        icon: Icons.account_balance_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildRolePill(
                        label: AppTranslations.getRoleName('amdar', lang),
                        roleKey: 'amdar',
                        icon: Icons.gavel_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildRolePill(
                        label: AppTranslations.getRoleName('khasdar', lang),
                        roleKey: 'khasdar',
                        icon: Icons.assured_workload_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildRolePill(
                        label: AppTranslations.getRoleName('minister', lang),
                        roleKey: 'minister',
                        icon: Icons.military_tech_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sub-Role Toggle for Nagarsevak (Nagarsevak vs Staff)
                if (_activeRole == 'nagarsevak') ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _subRole = 'nagarsevak';
                              });
                            },
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _subRole == 'nagarsevak' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _subRole == 'nagarsevak'
                                    ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 15,
                                    color: _subRole == 'nagarsevak' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppTranslations.getRoleName('nagarsevak', lang),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: _subRole == 'nagarsevak' ? FontWeight.w800 : FontWeight.w600,
                                      color: _subRole == 'nagarsevak' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _subRole = 'staff';
                              });
                            },
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _subRole == 'staff' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _subRole == 'staff'
                                    ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.badge_rounded,
                                    size: 15,
                                    color: _subRole == 'staff' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Office Staff',
                                      mr: 'कार्यालय कर्मचारी',
                                      hi: 'कार्यालय स्टाफ',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: _subRole == 'staff' ? FontWeight.w800 : FontWeight.w600,
                                      color: _subRole == 'staff' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 2. Email Address Input
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Email Address / Username',
                    mr: 'ईमेल किंवा युझरनेम',
                    hi: 'ईमेल पता / उपयोगकर्ता नाम',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: AppTranslations.formatDigits(
                        AppTranslations.pick(
                          lang,
                          en: 'e.g. name@krishnaniti.in or 10-digit mobile',
                          mr: 'उदा. नाव@krishnaniti.in किंवा 10-अंकी मोबाईल',
                          hi: 'उदा. नाम@krishnaniti.in या 10-अंकीय मोबाइल',
                        ),
                        lang,
                      ),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF64748B), size: 19),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Password Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.pick(lang, en: 'Password', mr: 'पासवर्ड', hi: 'पासवर्ड'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showForgotPasswordSheet(context, lang),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Forgot Password?',
                          mr: 'पासवर्ड विसरलात?',
                          hi: 'पासवर्ड भूल गए?',
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 19),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Primary Mobile Login Button (Height 52, thumb-reachable)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Sign In',
                                  mr: 'लॉगिन करा',
                                  hi: 'साइन इन करें',
                                ),
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Instant Demo Access
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _signInDemo,
                    icon: const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF0284C7)),
                    label: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Instant Demo Login (demo_nagarsevak@demo.com)',
                        mr: 'डेमो लॉगिन (सर्व वैशिष्ट्ये पहा)',
                        hi: 'तुरंत डेमो लॉगिन (सभी सुविधाएँ देखें)',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBAE6FD), width: 1.5),
                      backgroundColor: const Color(0xFFF0F9FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Civic Security Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security_rounded, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text(
                          AppTranslations.formatDigits(
                            AppTranslations.pick(
                              lang,
                              en: '256-Bit Secure Civic Authentication',
                              mr: '256-बिट सुरक्षित नागरिक प्रशासन',
                              hi: '256-बिट सुरक्षित नागरिक प्रमाणीकरण',
                            ),
                            lang,
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Role Pill Widget
  Widget _buildRolePill({
    required String label,
    required String roleKey,
    required IconData icon,
  }) {
    final isSelected = _activeRole == roleKey;

    return InkWell(
      onTap: () => _selectRole(roleKey),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x1A0284C7), blurRadius: 8, offset: Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
