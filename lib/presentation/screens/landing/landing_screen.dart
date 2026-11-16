import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/krishnaniti_logo.dart';
import '../auth/login_screen.dart';
import '../../navigation/main_scaffold.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.chat_bubble_outline_rounded,
      badge: 'Civic Grievances',
      badgeMr: 'नागरिक तक्रारी',
      title: 'Fast & Transparent\nWard Grievance Redressal',
      titleMr: 'जलद आणि पारदर्शक\nप्रभाग तक्रार निवारण',
      description: 'Register citizen complaints, assign ward staff, and send instant status updates via WhatsApp.',
      descriptionMr: 'नागरिकांच्या तक्रारी नोंदवा, कर्मचाऱ्यांवर जबाबदारी सोपवा आणि व्हॉट्सअ‍ॅपवर प्रगती कळवा.',
      gradientColors: [Color(0xFF0284C7), Color(0xFF0369A1)],
      lightBg: Color(0xFFE0F2FE),
    ),
    _OnboardingSlide(
      icon: Icons.people_outline_rounded,
      badge: 'Voter Directory',
      badgeMr: 'मतदार यादी',
      title: 'Complete Citizen &\nVoter CRM at Your Fingertips',
      titleMr: 'नागरिक व मतदार नोंद\nआपल्या बोटांवर',
      description: 'Search voters by booth, family head, building, or mobile number with intelligent analytics.',
      descriptionMr: 'बूथ, कुटुंब प्रमुख, इमारत किंवा मोबाईल नंबरनुसार मतदारांचा शोध घ्या.',
      gradientColors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
      lightBg: Color(0xFFEEF2FF),
    ),
    _OnboardingSlide(
      icon: Icons.apartment_rounded,
      badge: 'Development Works',
      badgeMr: 'विकासकामे व निधी',
      title: 'Track Infrastructure &\nWard Development Works',
      titleMr: 'पायाभूत सुविधा व\nप्रभाग विकासकामांचा मागोवा',
      description: 'Monitor ongoing civil projects, ward budgets, contractor milestones, and site photos.',
      descriptionMr: 'सुरू असलेली विकासकामे, खर्च, निधी आणि प्रत्यक्ष कामाचे फोटो पहा.',
      gradientColors: [Color(0xFF0891B2), Color(0xFF155E75)],
      lightBg: Color(0xFFECFEFF),
    ),
    _OnboardingSlide(
      icon: Icons.mail_outline_rounded,
      badge: 'Official Correspondence',
      badgeMr: 'पत्रव्यवहार',
      title: 'Inward & Outward\nMunicipal Letters Management',
      titleMr: 'आवक व जावक\nअधिकृत पत्रव्यवहार',
      description: 'Draft recommendation letters, NOCs, certificates, and scan incoming government notices.',
      descriptionMr: 'शिफारस पत्रे, ना हरकत प्रमाणपत्रे तयार करा आणि शासकीय नोटीसा स्कॅन करा.',
      gradientColors: [Color(0xFF059669), Color(0xFF047857)],
      lightBg: Color(0xFFECFDF5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin({String? role}) {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(initialRole: role),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = user != null;

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
        body: SafeArea(
          child: Column(
            children: [
              // 1. App Header: Logo & Language Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo + App Name
                    Row(
                      children: [
                        const KrishnanitiLogo(size: 38),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Krishnaniti',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              isMr ? 'नगरसेवक अ‍ॅप' : 'Nagarsevak App',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Language Switch Pill
                    InkWell(
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
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 2. Interactive Feature Carousel (Native Mobile Feel)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (ctx, idx) {
                    final slide = _slides[idx];
                    return _buildSlideCard(slide, isMr);
                  },
                ),
              ),

              // 3. Carousel Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Quick Role Selector (Nagarsevak, Amdar, Khasdar, Minister)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMr ? 'थेट प्रवेश निवडा' : 'Choose Your Portal',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildQuickRoleChip(
                          title: isMr ? 'नगरसेवक' : 'Nagarsevak',
                          role: 'nagarsevak',
                          icon: Icons.account_balance_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickRoleChip(
                          title: isMr ? 'आमदार' : 'Amdar',
                          role: 'amdar',
                          icon: Icons.gavel_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickRoleChip(
                          title: isMr ? 'खासदार' : 'Khasdar',
                          role: 'khasdar',
                          icon: Icons.assured_workload_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickRoleChip(
                          title: isMr ? 'मंत्री' : 'Minister',
                          role: 'minister',
                          icon: Icons.military_tech_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Bottom Mobile Action Bar (Thumb-friendly buttons)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _navigateToLogin(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLoggedIn
                                  ? (isMr ? 'डॅशबोर्डवर जा' : 'Go to Dashboard')
                                  : (isMr ? 'लॉगिन करा' : 'Sign In to Account'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Quick Demo Login Chip
                    InkWell(
                      onTap: () => _navigateToLogin(role: 'nagarsevak'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Text(
                          isMr ? 'डेमो खात्याद्वारे थेट पहा →' : 'Explore with Demo Account →',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile Slide Card inside Carousel
  Widget _buildSlideCard(_OnboardingSlide slide, bool isMr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: slide.lightBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: slide.gradientColors[0].withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Badge & Icon Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Text(
                    isMr ? slide.badgeMr : slide.badge,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: slide.gradientColors[0],
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: slide.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slide.icon, color: Colors.white, size: 22),
                ),
              ],
            ),

            const Spacer(),

            // Title
            Text(
              isMr ? slide.titleMr : slide.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                height: 1.25,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              isMr ? slide.descriptionMr : slide.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Quick Role Chip
  Widget _buildQuickRoleChip({
    required String title,
    required String role,
    required IconData icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _navigateToLogin(role: role);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0284C7)),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String badge;
  final String badgeMr;
  final String title;
  final String titleMr;
  final String description;
  final String descriptionMr;
  final List<Color> gradientColors;
  final Color lightBg;

  _OnboardingSlide({
    required this.icon,
    required this.badge,
    required this.badgeMr,
    required this.title,
    required this.titleMr,
    required this.description,
    required this.descriptionMr,
    required this.gradientColors,
    required this.lightBg,
  });
}
