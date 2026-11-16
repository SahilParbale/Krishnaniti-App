import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
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
  final ScrollController _scrollController = ScrollController();
  final Set<int> _expandedFaqIndices = {0}; // First FAQ open by default

  @override
  void dispose() {
    _scrollController.dispose();
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
          builder: (_) => LoginScreen(initialRole: role, showBackToWebsite: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final user = ref.watch(currentUserProvider);

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
              // 1. Fixed Top Navigation Bar (Matching LandingPage.tsx)
              _buildTopNavbar(isMr, user != null),

              // 2. Scrollable Landing Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section
                      _buildHeroSection(isMr, user != null),

                      // Features Section
                      _buildFeaturesSection(isMr),

                      // Testimonials Section
                      _buildTestimonialsSection(isMr),

                      // Stats / Social Proof Banner (Navy Blue)
                      _buildStatsSection(isMr),

                      // FAQ Accordion Section
                      _buildFaqSection(isMr),

                      // Footer
                      _buildFooterSection(isMr),
                    ],
                  ),
                ),
              ),

              // Bottom Quick Action Bar for Instant Access
              _buildBottomActionBar(isMr, user != null),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP NAVBAR
  // ---------------------------------------------------------------------------
  Widget _buildTopNavbar(bool isMr, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          Row(
            children: [
              const KrishnanitiLogo(size: 34),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Krishnaniti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    isMr ? 'नगरसेवक व्यवस्थापन' : 'Nagarsevak Management',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions: Language Toggle & Login Button
          Row(
            children: [
              // Language Switch Button
              IconButton(
                onPressed: () {
                  ref.read(isMarathiProvider.notifier).toggle();
                },
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, size: 18, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Text(
                      isMr ? 'EN' : 'मराठी',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                constraints: const BoxConstraints(),
                tooltip: isMr ? 'Switch to English' : 'मराठीत बदला',
              ),

              const SizedBox(width: 8),

              // Login / Dashboard CTA
              ElevatedButton.icon(
                onPressed: () => _navigateToLogin(),
                icon: const Icon(Icons.login_rounded, size: 15),
                label: Text(
                  isLoggedIn
                      ? (isMr ? 'डॅशबोर्ड' : 'Dashboard')
                      : (isMr ? 'लॉगिन' : 'Login'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. HERO SECTION
  // ---------------------------------------------------------------------------
  Widget _buildHeroSection(bool isMr, bool isLoggedIn) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE0F2FE),
            Color(0xFFF0F9FF),
            Colors.white,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
      child: Column(
        children: [
          // Platform Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isMr ? AppStrings.smartGovernanceBadgeMr : AppStrings.smartGovernanceBadge,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0369A1),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Main Title
          Text(
            isMr ? AppStrings.landingHeroTitleMr : AppStrings.landingHeroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 14),

          // Subtitle
          Text(
            isMr ? AppStrings.landingHeroSubtitleMr : AppStrings.landingHeroSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 24),

          // CTA Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _navigateToLogin(),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  isLoggedIn
                      ? (isMr ? 'डॅशबोर्ड उघडा' : 'Go to Dashboard')
                      : (isMr ? AppStrings.getStartedMr : AppStrings.getStarted),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _navigateToLogin(role: 'nagarsevak'),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 17),
                label: Text(
                  isMr ? AppStrings.viewDemoMr : AppStrings.viewDemo,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Trusted By Leaders text
          Text(
            isMr ? AppStrings.trustedByLeadersMr : AppStrings.trustedByLeaders,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. FEATURES SECTION
  // ---------------------------------------------------------------------------
  Widget _buildFeaturesSection(bool isMr) {
    final features = [
      _FeatureItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: isMr ? 'तक्रार निवारण' : 'Grievance Redressal',
        description: isMr
            ? 'रिअल-टाइममध्ये नागरिकांच्या तक्रारींचे निवारण करा आणि प्रगती अपडेट करा.'
            : 'Track, manage, and resolve citizen complaints in real-time with automated updates.',
        color: const Color(0xFF0284C7),
        bgColor: const Color(0xFFE0F2FE),
      ),
      _FeatureItem(
        icon: Icons.people_outline_rounded,
        title: isMr ? 'नागरिक व मतदार नोंद' : 'Citizen Directory & CRM',
        description: isMr
            ? 'मतदार यादी, कुटुंब रचना आणि संपर्क तपशीलांचे संपूर्ण डिजिटल व्यवस्थापन.'
            : 'Maintain detailed voter and citizen records, manage contacts, and track family structures.',
        color: const Color(0xFF6366F1),
        bgColor: const Color(0xFFEEF2FF),
      ),
      _FeatureItem(
        icon: Icons.apartment_rounded,
        title: isMr ? 'विकासकामे व निधी' : 'Development Works',
        description: isMr
            ? 'प्रभागातील सुरू असलेली कामे, खर्च आणि प्रगतीचा मागोवा घ्या.'
            : 'Monitor ongoing infrastructure projects, track budgets, and share progress with residents.',
        color: const Color(0xFF0891B2),
        bgColor: const Color(0xFFECFEFF),
      ),
      _FeatureItem(
        icon: Icons.bar_chart_rounded,
        title: isMr ? 'निकाल व प्रभाग विश्लेषण' : 'Result Analytics',
        description: isMr
            ? 'मतदारसंख्या, मतदान कल आणि कामगिरीचे सखोल विश्लेषण करा.'
            : 'Analyze ward demographics, election trends, and performance metrics.',
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
      ),
      _FeatureItem(
        icon: Icons.dashboard_outlined,
        title: isMr ? 'शासकीय योजना व लाभ' : 'Welfare Schemes',
        description: isMr
            ? 'नागरिकांना शासकीय योजनांशी जोडा आणि लाभाचे वितरण सुलभ करा.'
            : 'Connect citizens with government schemes, track applications, and disburse benefits.',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _FeatureItem(
        icon: Icons.mail_outline_rounded,
        title: isMr ? 'पत्रव्यवहार व संवाद' : 'Official Letters & Notice',
        description: isMr
            ? 'अधिकृत पत्रे, ना हरकत प्रमाणपत्रे आणि आवक-जावक पत्रव्यवहार व्यवस्थापन.'
            : 'Generate official letters, NOCs, certificates, and municipal correspondence.',
        color: const Color(0xFFE11D48),
        bgColor: const Color(0xFFFFF1F2),
      ),
    ];

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          // Section Title
          Text(
            isMr ? 'सर्वसमावेशक प्रभाग व्यवस्थापन' : 'Comprehensive Ward Management',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMr
                ? 'आपला प्रभाग प्रभावीपणे आणि पारदर्शकपणे चालवण्यासाठी आवश्यक सर्वकाही.'
                : 'Everything you need to manage your ward effectively and transparently.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 24),

          // Responsive Feature Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: isWide ? 2.1 : 2.5,
                ),
                itemBuilder: (ctx, idx) {
                  final item = features[idx];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: item.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. TESTIMONIALS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildTestimonialsSection(bool isMr) {
    final testimonials = [
      _TestimonialData(
        quote: isMr
            ? 'या प्लॅटफॉर्मने तक्रार निवारणाची माझी पद्धत पूर्णपणे बदलली आहे. माझा प्रतिसाद वेळ ५०% ने सुधारला आहे!'
            : 'This platform has completely revolutionized how I track complaints. My response time has improved by 50%!',
        author: isMr ? 'राजेश पाटील' : 'Rajesh Patil',
        role: isMr ? 'नगरसेवक, प्रभाग १२' : 'Corporator, Ward 12',
      ),
      _TestimonialData(
        quote: isMr
            ? 'डिजिटल प्रभाग व्यवस्थापनाने आमचे कार्यालय १००% पेपरलेस आणि कार्यक्षम बनवले आहे.'
            : 'Digital ward management has made our office completely paperless and efficient.',
        author: isMr ? 'सुनिता मोरे' : 'Sunita More',
        role: isMr ? 'नगरसेविका, प्रभाग ८' : 'Nagarsevika, Prabhag 8',
      ),
      _TestimonialData(
        quote: isMr
            ? 'थेट नागरिक संपर्कामुळे स्थानिक नागरिकांमध्ये प्रचंड विश्वास निर्माण झाला आहे.'
            : 'Direct citizen engagement has created tremendous trust among ward residents.',
        author: isMr ? 'अमित शिंदे' : 'Amit Shinde',
        role: isMr ? 'नगरसेवक, प्रभाग १५' : 'Corporator, Ward 15',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          Text(
            isMr ? 'लोकप्रतिनिधींचा विश्वास' : 'Trusted by Community Leaders',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isMr
                ? 'पहा नगरसेवक प्रणालीने प्रभाग व्यवस्थापनात कसा बदल घडवला आहे.'
                : 'See how our platform is transforming ward management.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          // Testimonial Cards
          Column(
            children: testimonials.map((t) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 5 Stars
                    Row(
                      children: List.generate(
                        5,
                        (_) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"${t.quote}"',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF0284C7),
                          child: Text(
                            t.author[0],
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.author,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              t.role,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. STATS / SOCIAL PROOF SECTION (Navy Blue)
  // ---------------------------------------------------------------------------
  Widget _buildStatsSection(bool isMr) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF082F49),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  number: '50+',
                  label: isMr ? 'प्रभाग व्यवस्थापित' : 'Wards Managed',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  number: '10k+',
                  label: isMr ? 'तक्रारी निवारण' : 'Grievances Solved',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  number: '5L+',
                  label: isMr ? 'नागरिक जोडले' : 'Citizens Connected',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  number: '100+',
                  label: isMr ? 'विकासकामे पूर्ण' : 'Projects Completed',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String number, required String label}) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFBAE6FD),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. FAQ ACCORDION SECTION
  // ---------------------------------------------------------------------------
  Widget _buildFaqSection(bool isMr) {
    final faqs = [
      _FaqItemData(
        question: isMr ? 'माझा डेटा सुरक्षित आहे का?' : 'Is my data secure?',
        answer: isMr
            ? 'होय, सर्व नागरिक आणि प्रशासकीय डेटा १००% सुरक्षित ठेवण्यासाठी आम्ही प्रगत एनक्रिप्शन वापरतो.'
            : 'Yes, we use enterprise-grade encryption to ensure all citizen and administrative data is 100% secure.',
      ),
      _FaqItemData(
        question: isMr ? 'मी एकाधिक प्रभाग व्यवस्थापित करू शकतो का?' : 'Can I manage multiple wards?',
        answer: isMr
            ? 'होय, ही प्रणाली बहु-प्रभाग आणि मतदारसंघ स्तरावरील सर्वसमावेशक व्यवस्थापनास पूर्णपणे समर्थन देते.'
            : 'Yes, the platform fully supports multi-ward and constituency-level governance.',
      ),
      _FaqItemData(
        question: isMr ? 'प्रणाली मराठी आणि इंग्रजी दोन्ही भाषांना समर्थन देते का?' : 'Does it support Marathi and English?',
        answer: isMr
            ? 'होय, संपूर्ण अ‍ॅप मराठी आणि इंग्रजी दोन्ही भाषांमध्ये एका क्लिकवर बदलता येतो.'
            : 'Yes, full bilingual support allows switching between English and Marathi seamlessly.',
      ),
      _FaqItemData(
        question: isMr ? 'नागरिक तक्रारी कशा नोंदवू शकतात?' : 'How do citizens submit complaints?',
        answer: isMr
            ? 'नागरिक व्हॉट्सअ‍ॅप, नागरिक पोर्टल किंवा आपल्या कार्यालयातील मदत कक्षाद्वारे तक्रार नोंदवू शकतात.'
            : 'Citizens can submit complaints through WhatsApp integration, citizen web portals, or through ward office staff.',
      ),
    ];

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          Text(
            isMr ? 'सतत विचारले जाणारे प्रश्न' : 'Frequently Asked Questions',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isMr ? 'प्लॅटफॉर्मबद्दलचे सामान्य प्रश्न' : 'Common questions about the platform',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // FAQ Accordion Items
          Column(
            children: List.generate(faqs.length, (idx) {
              final faq = faqs[idx];
              final isOpen = _expandedFaqIndices.contains(idx);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isOpen) {
                            _expandedFaqIndices.remove(idx);
                          } else {
                            _expandedFaqIndices.add(idx);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                faq.question,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Icon(
                              isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isOpen)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Text(
                          faq.answer,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. FOOTER SECTION
  // ---------------------------------------------------------------------------
  Widget _buildFooterSection(bool isMr) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              KrishnanitiLogo(size: 32),
              SizedBox(width: 8),
              Text(
                'Krishnaniti',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isMr
                ? 'स्मार्ट डिजिटल प्रशासनासह लोकप्रतिनिधींना सक्षम करणारी अत्याधुनिक प्रणाली.'
                : 'Empowering municipal representatives with smart digital governance.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFF1E293B)),
          const SizedBox(height: 16),
          Text(
            '© 2026 Krishnaniti Management System. ${isMr ? 'सर्व हक्क राखीव.' : 'All rights reserved.'}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            isMr ? 'चांगल्या शासनासाठी ❤️ ने बनवले' : 'Made with ❤️ for Better Governance',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. BOTTOM ACTION BAR (Login Shortcut)
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(bool isMr, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: () => _navigateToLogin(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLoggedIn
                    ? (isMr ? 'डॅशबोर्डवर जा' : 'Go to Dashboard')
                    : (isMr ? 'पोर्टलवर लॉगिन करा' : 'Sign in to Portal'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color bgColor;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.bgColor,
  });
}

class _TestimonialData {
  final String quote;
  final String author;
  final String role;

  _TestimonialData({
    required this.quote,
    required this.author,
    required this.role,
  });
}

class _FaqItemData {
  final String question;
  final String answer;

  _FaqItemData({
    required this.question,
    required this.answer,
  });
}
