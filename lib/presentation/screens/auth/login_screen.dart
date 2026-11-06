import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'demo_nagarsevak@demo.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  String _selectedRole = 'nagarsevak'; // 'nagarsevak' or 'staff'

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Username and Password'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    ref.read(authStateProvider.notifier).signIn(username, password);
  }

  @override
  Widget build(BuildContext context) {
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

    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Edge-to-Edge Hero Banner with subtle sky gradient and building line-art
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE0F2FE),
                      Color(0xFFF0F9FF),
                      Colors.white,
                    ],
                    stops: [0.0, 0.62, 1.0],
                  ),
                ),
                padding: EdgeInsets.only(
                  top: topPadding > 0 ? topPadding + 14 : 32,
                  bottom: 4,
                ),
                child: Column(
                  children: [
                    // Krishnaniti Logo and Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Building Emblem Logo
                        const _GovernmentEmblemIcon(),
                        const SizedBox(width: 10),
                        // App Brand Titles
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Krishnaniti',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F3663),
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Nagarsevak Management System',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Architectural Municipal Building Line-Art
                    SizedBox(
                      height: 84,
                      width: 290,
                      child: CustomPaint(
                        painter: _MunicipalBuildingLineArtPainter(),
                      ),
                    ),
                  ],
                ),
              ),

              // Sign In Form Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Subtitle
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Access your ward management account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Username TextField
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Username',
                        hintStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password TextField
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password? Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact your ward system administrator to reset password.'),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Select Role Section Header
                    const Text(
                      'Select Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Role Card 1: Administrator / Nagarsevak
                    _RoleSelectionCard(
                      icon: Icons.business_center,
                      title: 'Administrator /\nNagarsevak',
                      isSelected: _selectedRole == 'nagarsevak',
                      onTap: () {
                        setState(() => _selectedRole = 'nagarsevak');
                        _usernameController.text = 'demo_nagarsevak@demo.com';
                      },
                    ),
                    const SizedBox(height: 12),

                    // Role Card 2: Field Staff
                    _RoleSelectionCard(
                      icon: Icons.groups_rounded,
                      title: 'Field Staff',
                      isSelected: _selectedRole == 'staff',
                      onTap: () {
                        setState(() => _selectedRole = 'staff');
                        _usernameController.text = 'staff_prabhag12@demo.com';
                      },
                    ),
                    SizedBox(height: bottomPadding > 0 ? bottomPadding + 16 : 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Role selection card matching the exact UI in the mockup
class _RoleSelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.025),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Solid Brand Blue Icon
            Icon(
              icon,
              size: 28,
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(width: 14),
            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.22,
                ),
              ),
            ),
            // Chevron Right Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF334155),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vector Government / Municipal Building Emblem Logo matching Krishnaniti branding
class _GovernmentEmblemIcon extends StatelessWidget {
  const _GovernmentEmblemIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: CustomPaint(
        painter: _BuildingLogoPainter(),
      ),
    );
  }
}

/// Custom painter for the Krishnaniti building emblem
class _BuildingLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Small spire / finial at peak
    canvas.drawLine(Offset(w * 0.5, h * 0.08), Offset(w * 0.5, h * 0.16), strokePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.08), 1.5, fillPaint);

    // Top pediment / roof triangle
    final roof = Path()
      ..moveTo(w * 0.18, h * 0.28)
      ..lineTo(w * 0.5, h * 0.16)
      ..lineTo(w * 0.82, h * 0.28)
      ..close();
    canvas.drawPath(roof, fillPaint);

    // Horizontal entablature beam under roof
    canvas.drawRect(
      Rect.fromLTWH(w * 0.14, h * 0.28, w * 0.72, h * 0.07),
      fillPaint,
    );

    // 4 Vertical Columns / Pillars
    canvas.drawLine(Offset(w * 0.24, h * 0.35), Offset(w * 0.24, h * 0.75), strokePaint);
    canvas.drawLine(Offset(w * 0.41, h * 0.35), Offset(w * 0.41, h * 0.75), strokePaint);
    canvas.drawLine(Offset(w * 0.59, h * 0.35), Offset(w * 0.59, h * 0.75), strokePaint);
    canvas.drawLine(Offset(w * 0.76, h * 0.35), Offset(w * 0.76, h * 0.75), strokePaint);

    // Outer side wings / pilaster borders
    canvas.drawRect(
      Rect.fromLTWH(w * 0.10, h * 0.35, w * 0.08, h * 0.40),
      strokePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.82, h * 0.35, w * 0.08, h * 0.40),
      strokePaint,
    );

    // Base Steps (Plinths)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.06, h * 0.75, w * 0.88, h * 0.08),
      fillPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.02, h * 0.83, w * 0.96, h * 0.08),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the line-art government / municipal corporation building illustration
class _MunicipalBuildingLineArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF0284C7).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Plinth ground baseline steps
    canvas.drawLine(Offset(w * 0.03, h * 0.94), Offset(w * 0.97, h * 0.94), stroke);
    canvas.drawLine(Offset(w * 0.06, h * 0.88), Offset(w * 0.94, h * 0.88), stroke);

    // --- CENTRAL GRAND DOME ---
    // Spire and finial
    canvas.drawLine(Offset(cx, h * 0.06), Offset(cx, h * 0.18), stroke);
    canvas.drawCircle(Offset(cx, h * 0.06), 2.2, stroke);
    canvas.drawLine(Offset(cx - 3, h * 0.12), Offset(cx + 3, h * 0.12), stroke);

    // Main central dome curve
    final dome = Path()
      ..moveTo(cx - 30, h * 0.44)
      ..cubicTo(cx - 30, h * 0.16, cx + 30, h * 0.16, cx + 30, h * 0.44);
    canvas.drawPath(dome, stroke);

    // Dome internal radial ribs
    canvas.drawLine(Offset(cx, h * 0.18), Offset(cx, h * 0.44), stroke);
    final leftRib = Path()
      ..moveTo(cx - 8, h * 0.20)
      ..quadraticBezierTo(cx - 15, h * 0.32, cx - 18, h * 0.44);
    canvas.drawPath(leftRib, stroke);

    final rightRib = Path()
      ..moveTo(cx + 8, h * 0.20)
      ..quadraticBezierTo(cx + 15, h * 0.32, cx + 18, h * 0.44);
    canvas.drawPath(rightRib, stroke);

    // Dome Drum Cornices
    canvas.drawLine(Offset(cx - 34, h * 0.44), Offset(cx + 34, h * 0.44), stroke);
    canvas.drawLine(Offset(cx - 34, h * 0.48), Offset(cx + 34, h * 0.48), stroke);

    // Drum vertical slits / colonnade
    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(Offset(cx + i * 8.5, h * 0.44), Offset(cx + i * 8.5, h * 0.48), stroke);
    }

    // Central Building Facade
    canvas.drawRect(Rect.fromLTWH(cx - 32, h * 0.48, 64, h * 0.40), stroke);

    // Grand Entrance Arch
    final arch = Path()
      ..moveTo(cx - 13, h * 0.88)
      ..lineTo(cx - 13, h * 0.65)
      ..arcToPoint(Offset(cx + 13, h * 0.65), radius: const Radius.circular(13))
      ..lineTo(cx + 13, h * 0.88);
    canvas.drawPath(arch, stroke);

    // Inner arch accent
    final innerArch = Path()
      ..moveTo(cx - 9, h * 0.88)
      ..lineTo(cx - 9, h * 0.68)
      ..arcToPoint(Offset(cx + 9, h * 0.68), radius: const Radius.circular(9))
      ..lineTo(cx + 9, h * 0.88);
    canvas.drawPath(innerArch, stroke);

    // Flanking entrance pillars
    canvas.drawLine(Offset(cx - 23, h * 0.48), Offset(cx - 23, h * 0.88), stroke);
    canvas.drawLine(Offset(cx + 23, h * 0.48), Offset(cx + 23, h * 0.88), stroke);

    // --- LEFT WING ---
    canvas.drawRect(Rect.fromLTWH(cx - 96, h * 0.56, 64, h * 0.32), stroke);
    canvas.drawLine(Offset(cx - 98, h * 0.56), Offset(cx - 32, h * 0.56), stroke);
    canvas.drawLine(Offset(cx - 98, h * 0.60), Offset(cx - 32, h * 0.60), stroke);

    // Left wing pillars
    canvas.drawLine(Offset(cx - 48, h * 0.60), Offset(cx - 48, h * 0.88), stroke);
    canvas.drawLine(Offset(cx - 64, h * 0.60), Offset(cx - 64, h * 0.88), stroke);
    canvas.drawLine(Offset(cx - 80, h * 0.60), Offset(cx - 80, h * 0.88), stroke);

    // Left Cupola / Side Dome
    final leftDome = Path()
      ..moveTo(cx - 76, h * 0.56)
      ..cubicTo(cx - 76, h * 0.38, cx - 52, h * 0.38, cx - 52, h * 0.56);
    canvas.drawPath(leftDome, stroke);
    canvas.drawLine(Offset(cx - 64, h * 0.30), Offset(cx - 64, h * 0.38), stroke);
    canvas.drawCircle(Offset(cx - 64, h * 0.30), 1.6, stroke);

    // Outer Left Pavilion
    canvas.drawRect(Rect.fromLTWH(w * 0.06, h * 0.64, (cx - 96) - (w * 0.06), h * 0.24), stroke);
    final outerLeftDome = Path()
      ..moveTo(w * 0.08, h * 0.64)
      ..cubicTo(w * 0.08, h * 0.50, cx - 100, h * 0.50, cx - 100, h * 0.64);
    canvas.drawPath(outerLeftDome, stroke);
    final outerLeftCx = (w * 0.08 + cx - 100) / 2;
    canvas.drawLine(Offset(outerLeftCx, h * 0.44), Offset(outerLeftCx, h * 0.50), stroke);
    canvas.drawCircle(Offset(outerLeftCx, h * 0.44), 1.2, stroke);

    // --- RIGHT WING ---
    canvas.drawRect(Rect.fromLTWH(cx + 32, h * 0.56, 64, h * 0.32), stroke);
    canvas.drawLine(Offset(cx + 32, h * 0.56), Offset(cx + 98, h * 0.56), stroke);
    canvas.drawLine(Offset(cx + 32, h * 0.60), Offset(cx + 98, h * 0.60), stroke);

    // Right wing pillars
    canvas.drawLine(Offset(cx + 48, h * 0.60), Offset(cx + 48, h * 0.88), stroke);
    canvas.drawLine(Offset(cx + 64, h * 0.60), Offset(cx + 64, h * 0.88), stroke);
    canvas.drawLine(Offset(cx + 80, h * 0.60), Offset(cx + 80, h * 0.88), stroke);

    // Right Cupola / Side Dome
    final rightDome = Path()
      ..moveTo(cx + 52, h * 0.56)
      ..cubicTo(cx + 52, h * 0.38, cx + 76, h * 0.38, cx + 76, h * 0.56);
    canvas.drawPath(rightDome, stroke);
    canvas.drawLine(Offset(cx + 64, h * 0.30), Offset(cx + 64, h * 0.38), stroke);
    canvas.drawCircle(Offset(cx + 64, h * 0.30), 1.6, stroke);

    // Outer Right Pavilion
    canvas.drawRect(Rect.fromLTWH(cx + 96, h * 0.64, (w * 0.94) - (cx + 96), h * 0.24), stroke);
    final outerRightDome = Path()
      ..moveTo(cx + 100, h * 0.64)
      ..cubicTo(cx + 100, h * 0.50, w * 0.92, h * 0.50, w * 0.92, h * 0.64);
    canvas.drawPath(outerRightDome, stroke);
    final outerRightCx = (cx + 100 + w * 0.92) / 2;
    canvas.drawLine(Offset(outerRightCx, h * 0.44), Offset(outerRightCx, h * 0.50), stroke);
    canvas.drawCircle(Offset(outerRightCx, h * 0.44), 1.2, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
