import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import 'package:nagarsevak_mobile/presentation/widgets/krishnaniti_logo.dart';
import 'package:nagarsevak_mobile/presentation/providers/auth_provider.dart';
import 'package:nagarsevak_mobile/presentation/providers/language_provider.dart';
import 'package:nagarsevak_mobile/presentation/navigation/adaptive_scaffold.dart';

/// Desktop Login Screen matching Nagarsevak-Managment/src/pages/Login.tsx exactly 1:1
class DesktopLoginScreen extends ConsumerStatefulWidget {
  const DesktopLoginScreen({super.key});

  @override
  ConsumerState<DesktopLoginScreen> createState() => _DesktopLoginScreenState();
}

class _DesktopLoginScreenState extends ConsumerState<DesktopLoginScreen> {
  // Step 1: activeTab = null (Role Selection)
  // Step 2: activeTab = 'nagarsevak' | 'amdar' | 'khasdar' | 'minister'
  String? _activeTab;
  String _subRole = 'nagarsevak'; // 'nagarsevak' or 'staff'

  final TextEditingController _emailController = TextEditingController(text: 'demo_nagarsevak@demo.com');
  final TextEditingController _passwordController = TextEditingController(text: 'Password@123');
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final lang = ref.read(appLanguageProvider);

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter both email and password.',
              mr: 'कृपया ईमेल आणि पासवर्ड दोन्ही प्रविष्ट करा.',
              hi: 'कृपया ईमेल और पासवर्ड दोनों दर्ज करें।',
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).signIn(
        email,
        password,
        role: _activeTab ?? 'nagarsevak',
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
        setState(() => _loading = false);
        final rawMsg = e.toString().replaceFirst('Exception: ', '');
        final prefix = AppTranslations.pick(
          lang,
          en: 'Sign in failed: ',
          mr: 'लॉगिन अयशस्वी: ',
          hi: 'साइन इन विफल: ',
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

  Future<void> _signInDemo(String role) async {
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).signIn(
        'demo_nagarsevak@demo.com',
        'Password@123',
        role: role,
        isStaff: false,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdaptiveScaffold()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // #f8fafc matching Login.tsx
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 1000, // max-w-[1000px]
            height: 600, // md:h-[600px]
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // rounded-3xl
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12), // shadow-2xl
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // 1. Left Side - Visual / Brand Hero (hidden md:flex w-1/2 matching Login.tsx)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: Color(0xFFF1F5F9), width: 1), // border-slate-100
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/login_hero.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/login_hero.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ),

                // 2. Right Side - Login Form (w-full md:w-1/2 p-8 md:p-12 matching Login.tsx)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Color(0xFFF0F9FF), // brand-50/30
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                    child: Stack(
                      children: [
                        // 3-Language Switcher (top-right)
                        const Align(
                          alignment: Alignment.topRight,
                          child: AppLanguageSegmentedSelector(isCompact: true),
                        ),

                        // Form Content (max-w-sm mx-auto w-full mt-14 matching Login.tsx)
                        Center(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Logo + Title Header
                                  const KrishnanitiLogo(size: 60),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppTranslations.pick(lang, en: 'Krishnaniti', mr: 'कृष्णनीती', hi: 'कृष्णनीति'),
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A), // slate-900
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Sign in to access your administrative portal',
                                      mr: 'तुमच्या प्रशासकीय पोर्टलवर प्रवेश करण्यासाठी साइन इन करा',
                                      hi: 'अपने प्रशासनिक पोर्टल तक पहुँचने के लिए साइन इन करें',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B), // slate-500
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 28),

                                  // STEP 1: Role Selection (matching Login.tsx lines 180-230)
                                  if (_activeTab == null) ...[
                                    GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.45,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: [
                                        _buildRoleButton('nagarsevak', AppTranslations.getRoleName('nagarsevak', lang)),
                                        _buildRoleButton('amdar', AppTranslations.getRoleName('amdar', lang)),
                                        _buildRoleButton('khasdar', AppTranslations.getRoleName('khasdar', lang)),
                                        _buildRoleButton('minister', AppTranslations.getRoleName('minister', lang)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: _loading ? null : () => _signInDemo('nagarsevak'),
                                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                                        label: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Instant Demo Login (demo_nagarsevak@demo.com)',
                                            mr: 'त्वरित डेमो लॉगिन (demo_nagarsevak@demo.com)',
                                            hi: 'तुरंत डेमो लॉगिन (demo_nagarsevak@demo.com)',
                                          ),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0284C7),
                                          foregroundColor: Colors.white,
                                          elevation: 1,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // STEP 2: Login Form (matching Login.tsx lines 240-340)
                                    _buildLoginForm(lang),
                                  ],

                                  const SizedBox(height: 24),

                                  // Footer Security Note (matching Login.tsx lines 345-350)
                                  Container(
                                    padding: const EdgeInsets.only(top: 16),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Color(0xFFF1F5F9)), // border-slate-100
                                      ),
                                    ),
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Protected by enterprise-grade security.\nUnauthorized access is strictly prohibited.',
                                        mr: 'उच्च-स्तरीय सुरक्षिततेने संरक्षित.\nअनधिकृत प्रवेश सक्त निषिद्ध आहे.',
                                        hi: 'एंटरप्राइज़-स्तरीय सुरक्षा द्वारा सुरक्षित।\nअनधिकृत पहुँच सख्ती से वर्जित है।',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8), // slate-400
                                        height: 1.35,
                                      ),
                                      textAlign: TextAlign.center,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String roleKey, String title) {
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = roleKey;
          if (_emailController.text.trim().isEmpty) {
            _emailController.text = 'demo_nagarsevak@demo.com';
            _passwordController.text = 'Password@123';
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      hoverColor: const Color(0xFFF0F9FF), // brand-50
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)), // border-slate-200
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const KrishnanitiLogo(size: 30),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155), // slate-700
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back to Role Selection button (matching Login.tsx lines 240-250)
        InkWell(
          onTap: () => setState(() => _activeTab = null),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Back to Role Selection',
                    mr: 'भूमिका निवडीकडे परत जा',
                    hi: 'भूमिका चयन पर वापस जाएँ',
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Sub-role toggle for Nagarsevak (Nagarsevak | Staff) (matching Login.tsx lines 252-276)
        if (_activeTab == 'nagarsevak') ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // bg-slate-100
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _subRole = 'nagarsevak'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _subRole == 'nagarsevak' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _subRole == 'nagarsevak'
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          AppTranslations.getRoleName('nagarsevak', lang),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _subRole == 'nagarsevak' ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _subRole = 'staff'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _subRole == 'staff' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _subRole == 'staff'
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          AppTranslations.pick(lang, en: 'Staff', mr: 'कर्मचारी', hi: 'स्टाफ'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _subRole == 'staff' ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Email Label & Input (matching Login.tsx lines 285-305)
        Text(
          AppTranslations.pick(lang, en: 'Email / Username', mr: 'ईमेल / युझरनेम', hi: 'ईमेल / उपयोगकर्ता नाम'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // bg-slate-50
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
              ),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Enter email or username',
                      mr: 'ईमेल किंवा युझरनेम प्रविष्ट करा',
                      hi: 'ईमेल या उपयोगकर्ता नाम दर्ज करें',
                    ),
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Password Label & Input (matching Login.tsx lines 310-335)
        Text(
          AppTranslations.pick(lang, en: 'Password', mr: 'पासवर्ड', hi: 'पासवर्ड'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // bg-slate-50
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
              ),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Enter password',
                      mr: 'पासवर्ड प्रविष्ट करा',
                      hi: 'पासवर्ड दर्ज करें',
                    ),
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Submit Button (matching Login.tsx lines 340-355: bg-brand-600 hover:bg-brand-700)
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7), // bg-brand-600
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppTranslations.pick(lang, en: 'Sign In', mr: 'लॉगिन करा', hi: 'साइन इन करें'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: TextButton.icon(
            onPressed: _loading ? null : () => _signInDemo(_activeTab ?? 'nagarsevak'),
            icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF0284C7)),
            label: Text(
              AppTranslations.pick(
                lang,
                en: 'One-Click Demo Access (Skip Server)',
                mr: 'एक-क्लिक डेमो प्रवेश (सर्व्हर वगळून)',
                hi: 'एक-क्लिक डेमो एक्सेस (सर्वर छोड़कर)',
              ),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
            ),
          ),
        ),
      ],
    );
  }
}
