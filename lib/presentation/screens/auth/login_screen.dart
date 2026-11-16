import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/krishnaniti_logo.dart';
import '../landing/landing_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  final bool showBackToWebsite;

  const LoginScreen({
    super.key,
    this.initialRole,
    this.showBackToWebsite = true,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _activeRole; // 'nagarsevak', 'amdar', 'khasdar', 'minister'
  String _subRole = 'nagarsevak'; // 'nagarsevak' or 'staff'

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      _selectRole(widget.initialRole!);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() {
      _activeRole = role;
      _updateDefaultCredentials();
    });
  }

  void _updateDefaultCredentials() {
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

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Email and Password'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    ref.read(authStateProvider.notifier).signIn(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${next.error}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;

              return Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 24 : 16,
                    vertical: isWide ? 32 : 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 1000 : 480,
                      minHeight: isWide ? 580 : 0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C0F172A),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Visual Side (Matching Nagarsevak-Managment)
                                Expanded(
                                  flex: 1,
                                  child: _buildLeftHeroVisual(isMr),
                                ),

                                // Right Form Side
                                Expanded(
                                  flex: 1,
                                  child: _buildFormContent(isMr, isLoading),
                                ),
                              ],
                            )
                          : _buildFormContent(isMr, isLoading),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Left Side - Visual Banner for Tablets and Desktop
  Widget _buildLeftHeroVisual(bool isMr) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_hero.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, _, _) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const KrishnanitiLogo(size: 80),
                      const SizedBox(height: 16),
                      Text(
                        isMr ? 'कृष्णनीती' : 'Krishnaniti',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isMr ? 'नगरसेवक व्यवस्थापन प्रणाली' : 'Smart Ward Governance',
                        style: const TextStyle(
                          color: Color(0xFFE0F2FE),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 28,
            right: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KrishnanitiLogo(size: 44),
                const SizedBox(height: 12),
                Text(
                  isMr
                      ? 'स्थानिक नेतृत्वाला सक्षम करणे'
                      : 'Empowering Local Leaders,\nServing Citizens Better.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isMr
                      ? 'डिजिटल प्रभाग व्यवस्थापन व जनसंपर्क'
                      : 'Digital ward management & citizen engagement',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Right Side - Interactive Form Content
  Widget _buildFormContent(bool isMr, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Navigation Row: Back to Website & Language Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.showBackToWebsite)
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LandingScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          isMr ? AppStrings.backToWebsiteMr : AppStrings.backToWebsite,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Language Toggle Pill (Globe icon + Language name)
              InkWell(
                onTap: () {
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
            ],
          ),

          const SizedBox(height: 18),

          // Logo & Branding Header
          Center(
            child: Column(
              children: [
                const KrishnanitiLogo(size: 58),
                const SizedBox(height: 12),
                const Text(
                  'Krishnaniti',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMr ? 'आपल्या पोर्टलवर साइन इन करा' : 'Sign in to access your portal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Flow Step 1: Role Selection OR Flow Step 2: Login Form
          if (_activeRole == null)
            _buildRoleSelectionStep(isMr)
          else
            _buildLoginFormStep(isMr, isLoading),

          const SizedBox(height: 24),

          // Enterprise Security Footer Notice
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Text(
            isMr ? AppStrings.enterpriseSecurityNoteMr : AppStrings.enterpriseSecurityNote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Role Selection Grid (Nagarsevak, Amdar, Khasdar, Minister)
  Widget _buildRoleSelectionStep(bool isMr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMr ? 'आपली भूमिका निवडा' : 'Select Your Role',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _buildRoleCard(
              title: isMr ? AppStrings.roleNagarsevakMr : AppStrings.roleNagarsevak,
              roleKey: 'nagarsevak',
              icon: Icons.account_balance_rounded,
            ),
            _buildRoleCard(
              title: isMr ? AppStrings.roleAmdarMr : AppStrings.roleAmdar,
              roleKey: 'amdar',
              icon: Icons.gavel_rounded,
            ),
            _buildRoleCard(
              title: isMr ? AppStrings.roleKhasdarMr : AppStrings.roleKhasdar,
              roleKey: 'khasdar',
              icon: Icons.assured_workload_rounded,
            ),
            _buildRoleCard(
              title: isMr ? AppStrings.roleMinisterMr : AppStrings.roleMinister,
              roleKey: 'minister',
              icon: Icons.military_tech_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String roleKey,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _selectRole(roleKey),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const KrishnanitiLogo(size: 28, showShadow: false),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Role Login Form
  Widget _buildLoginFormStep(bool isMr, bool isLoading) {
    final roleDisplay = _getRoleDisplayName(isMr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back to Role Selection Button
        InkWell(
          onTap: () => setState(() => _activeRole = null),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  isMr ? AppStrings.backToRolesMr : AppStrings.backToRoles,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Sub-Role Toggle (Nagarsevak vs Staff)
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
                      setState(() {
                        _subRole = 'nagarsevak';
                        _updateDefaultCredentials();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _subRole == 'nagarsevak' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _subRole == 'nagarsevak'
                            ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isMr ? AppStrings.roleNagarsevakMr : AppStrings.roleNagarsevak,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _subRole == 'nagarsevak' ? FontWeight.w800 : FontWeight.w600,
                          color: _subRole == 'nagarsevak' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _subRole = 'staff';
                        _updateDefaultCredentials();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _subRole == 'staff' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _subRole == 'staff'
                            ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isMr ? AppStrings.roleStaffMr : AppStrings.roleStaff,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _subRole == 'staff' ? FontWeight.w800 : FontWeight.w600,
                          color: _subRole == 'staff' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
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

        // Active Role Title
        Row(
          children: [
            Text(
              '$roleDisplay ${isMr ? 'लॉगिन' : 'Login'}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            if (_activeRole == 'nagarsevak') ...[
              const SizedBox(width: 6),
              Text(
                '(${_subRole == 'nagarsevak' ? (isMr ? AppStrings.roleNagarsevakMr : AppStrings.roleNagarsevak) : (isMr ? AppStrings.roleStaffMr : AppStrings.roleStaff)})',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // Email / Username Input
        Text(
          isMr ? AppStrings.emailLabelMr : AppStrings.emailLabel,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: isMr ? 'आपला ईमेल किंवा युझरनेम टाका' : 'name@krishnaniti.in',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Password Input
        Text(
          isMr ? AppStrings.passwordLabelMr : AppStrings.passwordLabel,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Submit Login Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isMr ? AppStrings.loginButtonMr : AppStrings.loginButton,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(bool isMr) {
    switch (_activeRole) {
      case 'nagarsevak':
        return isMr ? AppStrings.roleNagarsevakMr : AppStrings.roleNagarsevak;
      case 'amdar':
        return isMr ? AppStrings.roleAmdarMr : AppStrings.roleAmdar;
      case 'khasdar':
        return isMr ? AppStrings.roleKhasdarMr : AppStrings.roleKhasdar;
      case 'minister':
        return isMr ? AppStrings.roleMinisterMr : AppStrings.roleMinister;
      default:
        return 'User';
    }
  }
}
