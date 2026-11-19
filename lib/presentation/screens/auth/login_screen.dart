import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/krishnaniti_logo.dart';
import '../../navigation/main_scaffold.dart';

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
  final TextEditingController _passwordController = TextEditingController(text: 'Password@123');
  bool _obscurePassword = true;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      _activeRole = widget.initialRole!;
    }
    _updateDefaultCredentials();
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
      _updateDefaultCredentials();
    });
  }

  void _updateDefaultCredentials() {
    _passwordController.text = 'Password@123';
    if (_activeRole == 'nagarsevak') {
      _emailController.text = _subRole == 'nagarsevak'
          ? 'demo_nagarsevak@demo.com'
          : 'staff_prabhag12@demo.com';
    } else if (_activeRole == 'amdar') {
      _emailController.text = 'amdar_demo@krishnaniti.in';
    } else if (_activeRole == 'khasdar') {
      _emailController.text = 'khasdar_demo@krishnaniti.in';
    } else if (_activeRole == 'minister') {
      _emailController.text = 'minister_demo@krishnaniti.in';
    }
  }

  Future<void> _handleLogin() async {
    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isMr = ref.read(isMarathiProvider);

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMr ? 'कृपया ईमेल आणि पासवर्ड दोन्ही प्रविष्ट करा' : 'Please enter both Email and Password',
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
          MaterialPageRoute(builder: (_) => const MainScaffold()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMr ? 'लॉगिन अयशस्वी: $errorMsg' : 'Sign in failed: $errorMsg',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showForgotPasswordSheet(BuildContext context, bool isMr) {
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
                      isMr ? 'पासवर्ड विसरलात?' : 'Forgot Password?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isMr
                      ? 'सुरक्षिततेच्या कारणास्तव पासवर्ड रीसेट करण्यासाठी आपल्या प्रभाग प्रशासक किंवा कृष्णनीती सपोर्टशी संपर्क साधा.'
                      : 'For administrative security, password resets are handled via your ward system administrator or Krishnaniti IT desk.',
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
                    children: const [
                      Icon(Icons.headset_mic_rounded, color: Color(0xFF0284C7), size: 22),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Helpline: +91 98220 12345', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('support@krishnaniti.in', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
                    child: Text(isMr ? 'समजले' : 'Got it'),
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
    final isMr = ref.watch(isMarathiProvider);
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
            tooltip: 'Back',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            // Language Toggle Pill
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(isMarathiProvider.notifier).toggle();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 15, color: Color(0xFF0284C7)),
                      const SizedBox(width: 5),
                      Text(
                        isMr ? 'English' : 'मराठी',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
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
                        const Text(
                          'Krishnaniti',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isMr ? 'प्रशासकीय पोर्टल' : 'Administrative Portal',
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
                  isMr ? 'आपल्या खात्यात प्रवेश करा' : 'Sign in to your account',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMr
                      ? 'आपल्या भूमिकेनुसार पोर्टल निवडून लॉगिन करा.'
                      : 'Select your representative role to proceed.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 20),

                // 1. Role Selector Tabs (Nagarsevak, Amdar, Khasdar, Minister)
                Text(
                  isMr ? 'भूमिका निवडा' : 'Select Role',
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
                        label: isMr ? 'नगरसेवक' : 'Nagarsevak',
                        roleKey: 'nagarsevak',
                        icon: Icons.account_balance_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildRolePill(
                        label: isMr ? 'आमदार' : 'Amdar',
                        roleKey: 'amdar',
                        icon: Icons.gavel_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildRolePill(
                        label: isMr ? 'खासदार' : 'Khasdar',
                        roleKey: 'khasdar',
                        icon: Icons.assured_workload_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildRolePill(
                        label: isMr ? 'मंत्री' : 'Minister',
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
                                _updateDefaultCredentials();
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
                                    isMr ? 'नगरसेवक' : 'Nagarsevak',
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
                                _updateDefaultCredentials();
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
                                    isMr ? 'कार्यालय कर्मचारी' : 'Office Staff',
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
                  isMr ? 'ईमेल किंवा युझरनेम' : 'Email Address / Username',
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
                      hintText: isMr ? 'उदा. demo_nagarsevak@demo.com' : 'e.g. demo_nagarsevak@demo.com',
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
                      isMr ? 'पासवर्ड' : 'Password',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showForgotPasswordSheet(context, isMr),
                      child: Text(
                        isMr ? 'पासवर्ड विसरलात?' : 'Forgot Password?',
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

                const SizedBox(height: 18),

                // Demo Credentials Highlight Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 17),
                          const SizedBox(width: 7),
                          Text(
                            isMr ? 'डेमो लॉगिन माहिती (Demo Credentials)' : 'Demo Credentials (१-क्लिक लॉगिन)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('ID: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                          Expanded(
                            child: Text(
                              _emailController.text,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Text('Password: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                          Text('Password@123', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0284C7))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () {
                                  _updateDefaultCredentials();
                                  _handleLogin();
                                },
                          icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF16A34A)),
                          label: Text(
                            isMr ? 'डेमोद्वारे थेट प्रवेश करा' : '1-Tap Demo Sign In',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF86EFAC)),
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

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
                                isMr ? 'लॉगिन करा' : 'Sign In',
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
                          isMr ? '२५६-बिट सुरक्षित नागरिक प्रशासन' : '256-Bit Secure Civic Authentication',
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
