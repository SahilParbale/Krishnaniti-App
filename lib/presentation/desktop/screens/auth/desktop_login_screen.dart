import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/core/theme/app_colors.dart';
import 'package:nagarsevak_mobile/presentation/widgets/krishnaniti_logo.dart';
import 'package:nagarsevak_mobile/presentation/providers/auth_provider.dart';
import 'package:nagarsevak_mobile/presentation/navigation/adaptive_scaffold.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';

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

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password.'),
          backgroundColor: Color(0xFFDC2626),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $rawMsg'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        // Language Switch Button (top-6 right-6 matching Login.tsx)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.language_rounded, size: 18, color: Color(0xFF64748B)),
                                SizedBox(width: 6),
                                Text(
                                  'English',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                  const Text(
                                    'Krishnaniti',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A), // slate-900
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sign in to access your administrative portal',
                                    style: TextStyle(
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
                                        _buildRoleButton('nagarsevak', 'Nagarsevak'),
                                        _buildRoleButton('amdar', 'Amdar'),
                                        _buildRoleButton('khasdar', 'Khasdar'),
                                        _buildRoleButton('minister', 'Minister'),
                                      ],
                                    ),
                                  ] else ...[
                                    // STEP 2: Login Form (matching Login.tsx lines 240-340)
                                    _buildLoginForm(),
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
                                    child: const Text(
                                      'Protected by enterprise-grade security.\nUnauthorized access is strictly prohibited.',
                                      style: TextStyle(
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

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back to Role Selection button (matching Login.tsx lines 240-250)
        InkWell(
          onTap: () => setState(() => _activeTab = null),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF94A3B8)),
                SizedBox(width: 6),
                Text(
                  'Back to Role Selection',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
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
                          'Nagarsevak',
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
                          'Staff',
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
        const Text(
          'Email / Username',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Enter email or username',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Password Label & Input (matching Login.tsx lines 310-335)
        const Text(
          'Password',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Enter password',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
