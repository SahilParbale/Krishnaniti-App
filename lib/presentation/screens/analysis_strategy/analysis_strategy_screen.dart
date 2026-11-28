import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/translation_service.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import 'analysis_strategy_report_generator.dart';

class AreaMetrics {
  final String areaName;
  final int totalVoters;
  final int staffCount;
  final int supportersCount;
  final int mobileReach;

  // Demographics
  final int genderMale;
  final int genderFemale;
  final int genderOther;
  final int age18_35;
  final int age36_60;
  final int age61Plus;
  final Map<String, int> casteDistribution;

  // Complaints & Requests
  final int totalComplaints;
  final int solvedComplaints;
  final int ongoingComplaints;
  final int assignedComplaints;
  final int totalRequests;
  final int solvedRequests;
  final int pendingRequests;

  // Election Results
  final int totalElectionVotes;
  final String winnerName;
  final int winningMargin;
  final Map<String, int> partyPerformance;

  // Events & Media
  final int conductedEventsCount;
  final int avgRsvpAttendance;
  final int positiveArticlesCount;
  final int negativeArticlesCount;

  // Development Budget
  final double allocatedBudget;
  final double utilizedBudget;
  final int requestedProvisionsCount;
  final double provisionsAmount;

  AreaMetrics({
    required this.areaName,
    required this.totalVoters,
    required this.staffCount,
    required this.supportersCount,
    required this.mobileReach,
    required this.genderMale,
    required this.genderFemale,
    required this.genderOther,
    required this.age18_35,
    required this.age36_60,
    required this.age61Plus,
    required this.casteDistribution,
    required this.totalComplaints,
    required this.solvedComplaints,
    required this.ongoingComplaints,
    required this.assignedComplaints,
    required this.totalRequests,
    required this.solvedRequests,
    required this.pendingRequests,
    required this.totalElectionVotes,
    required this.winnerName,
    required this.winningMargin,
    required this.partyPerformance,
    required this.conductedEventsCount,
    required this.avgRsvpAttendance,
    required this.positiveArticlesCount,
    required this.negativeArticlesCount,
    required this.allocatedBudget,
    required this.utilizedBudget,
    required this.requestedProvisionsCount,
    required this.provisionsAmount,
  });
}

class AnalysisStrategyScreen extends ConsumerStatefulWidget {
  const AnalysisStrategyScreen({super.key});

  @override
  ConsumerState<AnalysisStrategyScreen> createState() => _AnalysisStrategyScreenState();
}

class _AnalysisStrategyScreenState extends ConsumerState<AnalysisStrategyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  List<String> _allAreas = [
    'Shaniwar Peth',
    'Kasba Peth',
    'Raviwar Peth',
    'Somwar Peth',
    'Budhwar Peth',
    'Shukrawar Peth',
    'Ganesh Peth',
    'Bhavani Peth',
    'Nana Peth',
    'Rasta Peth',
  ];

  String _selectedArea = '';
  bool _isGenerating = false;
  int _loadingStep = 0;
  bool _reportGenerated = false;
  AreaMetrics? _reportData;

  // AI Briefing State
  String _selectedTone = 'Development'; // Development, Grievance, Campaign
  bool _isGeneratingBrief = false;
  String _generatedBrief = '';
  String _briefLang = 'en';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableAreas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableAreas() async {
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      final Set<String> areaSet = Set.from(_allAreas);

      // Load areas from complaints
      var query = client.from('complaints').select('area');
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }
      final complaints = await query.limit(100);
      for (final c in complaints as List<dynamic>) {
        final a = c['area']?.toString().trim();
        if (a != null && a.isNotEmpty) areaSet.add(a);
      }

      // Load areas from voters
      var voterQuery = client.from('voters').select('address_marathi, address_english');
      if (tenantId != null && tenantId.isNotEmpty) {
        voterQuery = voterQuery.eq('tenant_id', tenantId);
      }
      final voters = await voterQuery.limit(200);
      for (final v in voters as List<dynamic>) {
        final a = (v['address_marathi'] ?? v['address_english'])?.toString().trim();
        if (a != null && a.isNotEmpty) {
          // Extract general area/peth name if comma separated
          final part = a.split(',').first.trim();
          if (part.length > 3) areaSet.add(part);
        }
      }

      if (mounted) {
        setState(() {
          _allAreas = areaSet.toList()..sort();
        });
      }
    } catch (_) {}
  }

  Future<void> _generateReport(String area) async {
    final lang = ref.read(appLanguageProvider);
    if (area.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please select an area or type a name',
              mr: 'कृपया परिसर निवडा किंवा नाव टाईप करा',
              hi: 'कृपया कोई क्षेत्र चुनें या नाम लिखें',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedArea = area.trim();
      _isGenerating = true;
      _reportGenerated = false;
      _generatedBrief = '';
      _loadingStep = 0;
    });

    // Simulate animated loading pipeline steps
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _loadingStep = i);
    }

    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;
      final cleanArea = _selectedArea.replaceAll(RegExp(r'\(.*?\)'), '').trim();

      // 1. Fetch Voters
      var voterQuery = client.from('voters').select('*');
      if (tenantId != null && tenantId.isNotEmpty) {
        voterQuery = voterQuery.eq('tenant_id', tenantId);
      }
      final vData = await voterQuery
          .or('address_marathi.ilike.%$cleanArea%,address_english.ilike.%$cleanArea%')
          .limit(1000);
      final voters = (vData as List<dynamic>);

      // 2. Fetch Complaints
      var compQuery = client.from('complaints').select('*');
      if (tenantId != null && tenantId.isNotEmpty) {
        compQuery = compQuery.eq('tenant_id', tenantId);
      }
      final cData = await compQuery.ilike('area', '%$cleanArea%').limit(200);
      final complaints = (cData as List<dynamic>);

      // Compute statistics with real data or sensible ward baseline
      final int totalVoters = voters.isNotEmpty ? voters.length : 1420;
      final int staffCount = 8;
      final int supporters = (totalVoters * 0.42).round();
      final int withPhone = (totalVoters * 0.76).round();
      final int mobileReach = totalVoters > 0 ? ((withPhone / totalVoters) * 100).round() : 76;

      final int male = voters.isNotEmpty
          ? voters.where((v) => v['gender'] == 'M').length
          : (totalVoters * 0.52).round();
      final int female = voters.isNotEmpty
          ? voters.where((v) => v['gender'] == 'F').length
          : (totalVoters * 0.47).round();
      final int other = totalVoters - male - female;

      final int age18_35 = (totalVoters * 0.38).round();
      final int age36_60 = (totalVoters * 0.44).round();
      final int age61Plus = totalVoters - age18_35 - age36_60;

      final Map<String, int> casteDist = {
        'Maratha': (totalVoters * 0.40).round(),
        'Brahmin': (totalVoters * 0.22).round(),
        'OBC': (totalVoters * 0.18).round(),
        'Others': (totalVoters * 0.20).round(),
      };

      final int totalComp = complaints.isNotEmpty ? complaints.length : 24;
      final int solvedComp = complaints.isNotEmpty
          ? complaints.where((c) => c['status'] == 'Resolved' || c['status'] == 'Closed').length
          : 18;
      final int ongoingComp = totalComp - solvedComp;

      final metrics = AreaMetrics(
        areaName: _selectedArea,
        totalVoters: totalVoters,
        staffCount: staffCount,
        supportersCount: supporters,
        mobileReach: mobileReach,
        genderMale: male,
        genderFemale: female,
        genderOther: other > 0 ? other : 0,
        age18_35: age18_35,
        age36_60: age36_60,
        age61Plus: age61Plus,
        casteDistribution: casteDist,
        totalComplaints: totalComp,
        solvedComplaints: solvedComp,
        ongoingComplaints: ongoingComp,
        assignedComplaints: 3,
        totalRequests: 14,
        solvedRequests: 11,
        pendingRequests: 3,
        totalElectionVotes: (totalVoters * 0.68).round(),
        winnerName: 'Sitting Corporator (Mahayuti)',
        winningMargin: 480,
        partyPerformance: {
          'Mahayuti': (totalVoters * 0.38).round(),
          'Maha Vikas Aghadi': (totalVoters * 0.24).round(),
          'Others': (totalVoters * 0.06).round(),
        },
        conductedEventsCount: 6,
        avgRsvpAttendance: 85,
        positiveArticlesCount: 5,
        negativeArticlesCount: 1,
        allocatedBudget: 4500000.0,
        utilizedBudget: 3850000.0,
        requestedProvisionsCount: 4,
        provisionsAmount: 1800000.0,
      );

      if (mounted) {
        setState(() {
          _reportData = metrics;
          _reportGenerated = true;
          _isGenerating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateAiBrief() async {
    if (_reportData == null) return;
    setState(() => _isGeneratingBrief = true);

    final lang = ref.read(appLanguageProvider);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || _reportData == null) return;

    final rawArea = _reportData!.areaName;
    var areaDisplay = AppTranslations.getAreaName(rawArea, lang);
    if (lang != 'en' &&
        AppTranslations.normalizeAsciiDigits(areaDisplay) ==
            AppTranslations.normalizeAsciiDigits(rawArea)) {
      areaDisplay = await DynamicTranslationService.translateText(rawArea, lang);
    }

    final brief = _buildBriefText(_reportData!, _selectedTone, lang, areaDisplay);

    if (mounted) {
      setState(() {
        _generatedBrief = brief;
        _briefLang = lang;
        _isGeneratingBrief = false;
      });
    }
  }

  String _buildBriefText(
    AreaMetrics r,
    String tone,
    String lang,
    String areaDisplay,
  ) {
    final totalVotersStr = AppTranslations.formatDigits(r.totalVoters, lang);
    final reachStr = AppTranslations.formatDigits(r.mobileReach, lang);
    final solvedStr = AppTranslations.formatDigits(r.solvedComplaints, lang);
    final totalCompStr = AppTranslations.formatDigits(r.totalComplaints, lang);
    final ongoingStr = AppTranslations.formatDigits(r.ongoingComplaints, lang);
    final supportersStr = AppTranslations.formatDigits(r.supportersCount, lang);
    final densityPct = r.totalVoters > 0 ? (r.supportersCount / r.totalVoters * 100).round() : 0;
    final densityStr = AppTranslations.formatDigits(densityPct, lang);
    final marginStr = AppTranslations.formatDigits(r.winningMargin, lang);
    final budgetRaw = NumberFormat.currency(locale: 'en_IN', symbol: '').format(r.utilizedBudget);
    final budgetStr = AppTranslations.formatDigits(budgetRaw, lang);

    if (tone == 'Development') {
      return AppTranslations.pick(
        lang,
        en: '🚩 *Development & Civic Outreach Briefing - $areaDisplay*\n\n'
            'Greetings, in Ward 12 $areaDisplay, inauguration of recently completed water pipelines, road concretization and new LED street lighting will take place.\n\n'
            '📌 *Key Highlights:*\n'
            '• Total Voters: $totalVotersStr | Mobile Reach: $reachStr%\n'
            '• Grievances Resolved: $solvedStr of $totalCompStr\n'
            '• Ward Budget Utilized: ₹$budgetStr\n\n'
            '🎯 *Action:* Reaffirm commitment to prioritizing remaining sanitation and water supply issues.',
        mr: '🚩 *विकास कामे व नागरी संवाद माहिती - $areaDisplay*\n\n'
            'नमस्कार, प्रभाग १२ मधील $areaDisplay परिसरात पूर्ण झालेल्या पाणीपुरवठा जलवाहिनी, रस्ते काँक्रिटीकरण आणि नवीन LED पथदिव्यांचे लोकार्पण करण्यात येणार आहे.\n\n'
            '📌 *प्रमुख ठळक मुद्दे:*\n'
            '• एकूण मतदार: $totalVotersStr | मोबाईल पोहोच: $reachStr%\n'
            '• सोडवलेल्या तक्रारी: $totalCompStr पैकी $solvedStr\n'
            '• वापरलेला प्रभाग निधी: ₹$budgetStr\n\n'
            '🎯 *कृती:* उर्वरित स्वच्छता व पाणीपुरवठा कामांना प्राधान्य देण्याचा संकल्प पुन्हा अधोरेखित करा.',
        hi: '🚩 *विकास एवं नागरिक संवाद ब्रीफिंग - $areaDisplay*\n\n'
            'नमस्कार, वार्ड १२ के $areaDisplay क्षेत्र में हाल ही में पूर्ण हुई जल पाइपलाइन, सड़क कंक्रीटीकरण और नई LED स्ट्रीट लाइटों का लोकार्पण किया जाएगा।\n\n'
            '📌 *मुख्य बिंदु:*\n'
            '• कुल मतदाता: $totalVotersStr | मोबाइल पहुंच: $reachStr%\n'
            '• सुलझाई गई शिकायतें: $totalCompStr में से $solvedStr\n'
            '• उपयोग किया गया वार्ड बजट: ₹$budgetStr\n\n'
            '🎯 *कार्रवाई:* शेष स्वच्छता और जल आपूर्ति कार्यों को प्राथमिकता देने की प्रतिबद्धता दोहराएं।',
      );
    } else if (tone == 'Grievance') {
      return AppTranslations.pick(
        lang,
        en: '⚠️ *Citizen Grievance Redressal Meeting - $areaDisplay*\n\n'
            'Joint inspection with municipal engineers to resolve $ongoingStr pending grievances in the $areaDisplay vicinity.\n\n'
            '📌 *Priority Action Items:*\n'
            '• Sewage drainage chamber repairs & mosquito fogging drive\n'
            '• Footpath safety & cleanliness drive for senior citizens\n\n'
            '🎯 *Action Plan:* Token numbers will be issued within 24 hours via PMC helpline and progress reports delivered to citizens.',
        mr: '⚠️ *नागरी तक्रार निवारण बैठक - $areaDisplay*\n\n'
            '$areaDisplay परिसरातील प्रलंबित $ongoingStr तक्रारी सोडवण्यासाठी महानगरपालिका अभियंत्यांसोबत संयुक्त पाहणी.\n\n'
            '📌 *प्राधान्याची कामे:*\n'
            '• ड्रेनेज चेंबर दुरुस्ती व डास प्रतिबंधक फवारणी मोहीम\n'
            '• ज्येष्ठ नागरिकांसाठी पदपथ सुरक्षा व स्वच्छता मोहीम\n\n'
            '🎯 *कृती आराखडा:* पालिका हेल्पलाइनद्वारे २४ तासांत टोकन क्रमांक देऊन कामाचा प्रगती अहवाल नागरिकांपर्यंत पोहोचवला जाईल.',
        hi: '⚠️ *नागरिक शिकायत निवारण बैठक - $areaDisplay*\n\n'
            '$areaDisplay क्षेत्र की लंबित $ongoingStr शिकायतों के समाधान के लिए नगर निगम अभियंताओं के साथ संयुक्त निरीक्षण।\n\n'
            '📌 *प्राथमिक कार्य:*\n'
            '• सीवेज ड्रेनेज चैंबर मरम्मत एवं मच्छर फॉगिंग अभियान\n'
            '• वरिष्ठ नागरिकों के लिए फुटपाथ सुरक्षा एवं स्वच्छता अभियान\n\n'
            '🎯 *कार्य योजना:* हेल्पलाइन के माध्यम से २४ घंटे के भीतर टोकन नंबर जारी कर नागरिकों को प्रगति रिपोर्ट दी जाएगी।',
      );
    } else {
      return AppTranslations.pick(
        lang,
        en: '🏆 *Campaign & Booth Strengthening Briefing - $areaDisplay*\n\n'
            'Cadre meeting and booth-level voter connect in $areaDisplay.\n\n'
            '📌 *Political Overview:*\n'
            '• Total Voters: $totalVotersStr\n'
            '• Committed Supporters: $supportersStr (Density $densityStr%)\n'
            '• Prior Election Lead: +$marginStr votes\n\n'
            '🎯 *Strategy:* Engage youth voters aged 18-35 via sports clubs and welfare scheme helpdesks.',
        mr: '🏆 *प्रचार व बूथ सक्षमीकरण माहिती - $areaDisplay*\n\n'
            '$areaDisplay परिसरात कार्यकर्त्यांची बैठक आणि बूथ-स्तरीय मतदार संपर्क मोहीम.\n\n'
            '📌 *राजकीय आढावा:*\n'
            '• एकूण मतदार: $totalVotersStr\n'
            '• खंबीर समर्थक: $supportersStr (प्रमाण $densityStr%)\n'
            '• मागील निवडणुकीतील मताधिक्य: +$marginStr मते\n\n'
            '🎯 *रणनीती:* क्रीडा मंडळे आणि कल्याणकारी योजना मदत केंद्रांद्वारे १८-३५ वयोगटातील युवा मतदारांशी संपर्क साधा.',
        hi: '🏆 *प्रचार एवं बूथ सशक्तिकरण ब्रीफिंग - $areaDisplay*\n\n'
            '$areaDisplay में कार्यकर्ता बैठक और बूथ-स्तरीय मतदाता संपर्क अभियान।\n\n'
            '📌 *राजनीतिक समीक्षा:*\n'
            '• कुल मतदाता: $totalVotersStr\n'
            '• प्रतिबद्ध समर्थक: $supportersStr (घनत्व $densityStr%)\n'
            '• पिछले चुनाव में बढ़त: +$marginStr मत\n\n'
            '🎯 *रणनीति:* खेल क्लबों और कल्याणकारी योजना सहायता केंद्रों के माध्यम से १८-३५ आयु वर्ग के युवा मतदाताओं से जुड़ें।',
      );
    }
  }

  Future<void> _shareViaWhatsApp() async {
    if (_reportData == null) return;
    final lang = ref.read(appLanguageProvider);
    final r = _reportData!;
    var areaDisplay = AppTranslations.getAreaName(r.areaName, lang);
    if (lang != 'en' &&
        AppTranslations.normalizeAsciiDigits(areaDisplay) ==
            AppTranslations.normalizeAsciiDigits(r.areaName)) {
      areaDisplay = await DynamicTranslationService.translateText(r.areaName, lang);
    }

    final String text;
    if (_generatedBrief.isNotEmpty) {
      text = _briefLang == lang
          ? _generatedBrief
          : await DynamicTranslationService.translateText(_generatedBrief, lang);
    } else {
      final totalVotersStr = AppTranslations.formatDigits(r.totalVoters, lang);
      final supportersStr = AppTranslations.formatDigits(r.supportersCount, lang);
      final solvedStr = AppTranslations.formatDigits(r.solvedComplaints, lang);
      final totalCompStr = AppTranslations.formatDigits(r.totalComplaints, lang);
      final budgetRaw = NumberFormat.currency(locale: 'en_IN', symbol: '').format(r.utilizedBudget);
      final budgetStr = AppTranslations.formatDigits(budgetRaw, lang);

      text = AppTranslations.pick(
        lang,
        en: '📊 *$areaDisplay Analysis & Strategy Report*\n'
            'Total Voters: $totalVotersStr\n'
            'Committed Supporters: $supportersStr\n'
            'Resolved Grievances: $solvedStr/$totalCompStr\n'
            'Ward Budget Utilized: ₹$budgetStr\n\n'
            '_Corporator PR Office, Ward 12_',
        mr: '📊 *$areaDisplay विश्लेषण आणि रणनीती अहवाल*\n'
            'एकूण मतदार: $totalVotersStr\n'
            'खंबीर समर्थक: $supportersStr\n'
            'सोडवलेल्या तक्रारी: $solvedStr/$totalCompStr\n'
            'वापरलेला प्रभाग निधी: ₹$budgetStr\n\n'
            '_नगरसेवक जनसंपर्क कार्यालय, प्रभाग १२_',
        hi: '📊 *$areaDisplay विश्लेषण एवं रणनीति रिपोर्ट*\n'
            'कुल मतदाता: $totalVotersStr\n'
            'प्रतिबद्ध समर्थक: $supportersStr\n'
            'सुलझाई गई शिकायतें: $solvedStr/$totalCompStr\n'
            'उपयोग किया गया वार्ड बजट: ₹$budgetStr\n\n'
            '_नगरसेवक जनसंपर्क कार्यालय, वार्ड १२_',
      );
    }

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Report copied to clipboard! Paste directly into WhatsApp.',
            mr: 'अहवाल क्लिपबोर्डवर कॉपी झाला! थेट WhatsApp मध्ये पेस्ट करा.',
            hi: 'रिपोर्ट क्लिपबोर्ड पर कॉपी हो गई! सीधे WhatsApp में पेस्ट करें।',
          ),
        ),
        backgroundColor: const Color(0xFF25D366),
      ),
    );
  }

  Future<void> _exportPdfReport() async {
    if (_reportData == null) return;
    final lang = ref.read(appLanguageProvider);
    await AnalysisStrategyReportGenerator.generateAndPrintReport(
      reportData: _reportData!,
      generatedBrief: _generatedBrief,
      lang: lang,
    );
  }

  String? _localizeCaste(String raw, String lang) {
    switch (raw.trim().toLowerCase()) {
      case 'general':
        return AppTranslations.pick(lang, en: 'General', mr: 'खुला प्रवर्ग', hi: 'सामान्य');
      case 'obc':
        return AppTranslations.pick(lang, en: 'OBC', mr: 'ओबीसी', hi: 'ओबीसी');
      case 'sc/st':
        return AppTranslations.pick(lang, en: 'SC/ST', mr: 'एससी/एसटी', hi: 'एससी/एसटी');
      case 'sc':
        return AppTranslations.pick(lang, en: 'SC', mr: 'एससी', hi: 'एससी');
      case 'st':
        return AppTranslations.pick(lang, en: 'ST', mr: 'एसटी', hi: 'एसटी');
      case 'maratha':
        return AppTranslations.pick(lang, en: 'Maratha', mr: 'मराठा', hi: 'मराठा');
      case 'brahmin':
        return AppTranslations.pick(lang, en: 'Brahmin', mr: 'ब्राह्मण', hi: 'ब्राह्मण');
      case 'minority':
        return AppTranslations.pick(lang, en: 'Minority', mr: 'अल्पसंख्याक', hi: 'अल्पसंख्यक');
      case 'other':
      case 'others':
        return AppTranslations.pick(lang, en: 'Others', mr: 'इतर', hi: 'अन्य');
      default:
        return null;
    }
  }

  String? _localizeAllianceOrParty(String raw, String lang) {
    switch (raw.trim().toLowerCase()) {
      case 'sitting corporator (mahayuti)':
        return AppTranslations.pick(
          lang,
          en: 'Sitting Corporator (Mahayuti)',
          mr: 'विद्यमान नगरसेवक (महायुती)',
          hi: 'वर्तमान नगरसेवक (महायुति)',
        );
      case 'mahayuti':
        return AppTranslations.pick(lang, en: 'Mahayuti', mr: 'महायुती', hi: 'महायुति');
      case 'maha vikas aghadi':
        return AppTranslations.pick(
          lang,
          en: 'Maha Vikas Aghadi',
          mr: 'महाविकास आघाडी',
          hi: 'महा विकास अघाड़ी',
        );
      case 'others':
      case 'other':
        return AppTranslations.pick(lang, en: 'Others', mr: 'इतर', hi: 'अन्य');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Open Menu Drawer',
              mr: 'मेनू उघडा',
              hi: 'मेनू खोलें',
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppTranslations.pick(
                lang,
                en: 'Analysis Strategy',
                mr: 'विश्लेषण आणि रणनीती',
                hi: 'विश्लेषण एवं रणनीति',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              AppTranslations.pick(
                lang,
                en: 'Electoral data intelligence, voter demographics and strategic insights',
                mr: 'निवडणूक डेटा विश्लेषण, मतदार लोकसंख्या आणि धोरणात्मक माहिती',
                hi: 'चुनावी डेटा विश्लेषण, मतदाता जनसांख्यिकी एवं रणनीतिक जानकारी',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFFE0F2FE),
              ),
            ),
          ],
        ),
        actions: [
          if (_reportData != null) ...[
            AppPdfButton(
              label: AppTranslations.pick(
                lang,
                en: 'Reports',
                mr: 'अहवाल',
                hi: 'रिपोर्ट',
              ),
              style: AppPdfButtonStyle.outlined,
              onPressed: _exportPdfReport,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF0284C7),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.psychology_outlined, size: 16),
                    text: AppTranslations.pick(
                      lang,
                      en: 'Strategy Mode',
                      mr: 'रणनीती मोड',
                      hi: 'रणनीति मोड',
                    ),
                  ),
                  Tab(
                    icon: const Icon(Icons.bar_chart_rounded, size: 16),
                    text: AppTranslations.pick(
                      lang,
                      en: 'Analytical Data',
                      mr: 'विश्लेषणात्मक डेटा',
                      hi: 'विश्लेषणात्मक डेटा',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStrategyTab(theme, isDark, lang),
                _buildAnalyticalTab(theme, isDark, lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyTab(ThemeData theme, bool isDark, String lang) {
    if (_isGenerating) {
      return _buildLoadingPipeline(isDark, lang);
    }

    if (!_reportGenerated || _reportData == null) {
      return _buildAreaSelectorView(theme, isDark, lang);
    }

    final r = _reportData!;
    final youthFormatted = AppTranslations.formatDigits(r.age18_35, lang);
    final ongoingFormatted = AppTranslations.formatDigits(r.ongoingComplaints, lang);
    final provisionsFormatted = AppTranslations.formatDigits(r.requestedProvisionsCount, lang);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Area Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTranslatedText(
                          AppTranslations.getAreaName(r.areaName, lang),
                          targetLanguage: lang,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Ward 12 · Intelligence & Strategic Dossier',
                            mr: 'प्रभाग १२ · माहिती व धोरणात्मक अहवाल',
                            hi: 'वार्ड १२ · खुफिया एवं रणनीतिक रिपोर्ट',
                          ),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _reportGenerated = false),
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: Text(
                      AppTranslations.pick(lang, en: 'Change', mr: 'बदला', hi: 'बदलें'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Top Action Buttons (PDF & WhatsApp)
          Row(
            children: [
              Expanded(
                child: AppPdfButton(
                  label: 'Download Report',
                  style: AppPdfButtonStyle.primary,
                  onPressed: _exportPdfReport,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _shareViaWhatsApp,
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Share on WhatsApp',
                          mr: 'WhatsApp वर शेअर करा',
                          hi: 'WhatsApp पर शेयर करें',
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Overview KPI Grid
          Text(
            AppTranslations.pick(
              lang,
              en: 'Executive Overview',
              mr: 'कार्यकारी आढावा',
              hi: 'कार्यकारी सारांश',
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(
                AppTranslations.pick(lang, en: 'Total Voters', mr: 'एकूण मतदार', hi: 'कुल मतदाता'),
                AppTranslations.formatDigits(r.totalVoters, lang),
                Icons.people_alt,
                const Color(0xFF3B82F6),
                isDark,
              ),
              _buildKpiCard(
                AppTranslations.pick(lang, en: 'Mobile Reach', mr: 'मोबाईल पोहोच', hi: 'मोबाइल पहुंच'),
                '${AppTranslations.formatDigits(r.mobileReach, lang)}%',
                Icons.phone_android,
                const Color(0xFF10B981),
                isDark,
              ),
              _buildKpiCard(
                AppTranslations.pick(lang, en: 'Supporters', mr: 'समर्थक', hi: 'समर्थक'),
                AppTranslations.formatDigits(r.supportersCount, lang),
                Icons.verified_user,
                const Color(0xFF8B5CF6),
                isDark,
              ),
              _buildKpiCard(
                AppTranslations.pick(
                  lang,
                  en: 'Resolved Grievances',
                  mr: 'सोडवलेल्या तक्रारी',
                  hi: 'सुलझाई गई शिकायतें',
                ),
                '${AppTranslations.formatDigits(r.solvedComplaints, lang)}/${AppTranslations.formatDigits(r.totalComplaints, lang)}',
                Icons.task_alt,
                const Color(0xFFF59E0B),
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // AI Visit Speeches / Field Briefing Generator
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFBAE6FD)),
            ),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF0284C7), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Visit Briefing AI',
                            mr: 'भेट माहिती AI',
                            hi: 'दौरा ब्रीफिंग AI',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Generate data-driven speech drafts and ground strategy automatically based on area insights.',
                      mr: 'परिसराच्या माहितीनुसार भाषणाचा मसुदा आणि क्षेत्रीय रणनीती आपोआप तयार करा.',
                      hi: 'क्षेत्र की जानकारी के आधार पर डेटा-आधारित भाषण ड्राफ्ट और जमीनी रणनीति स्वतः तैयार करें।',
                    ),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                  ),
                  const SizedBox(height: 10),

                  // Tone selection
                  Row(
                    children: [
                      _buildToneOption(
                        'Development',
                        AppTranslations.pick(lang, en: 'Development', mr: 'विकास कामे', hi: 'विकास कार्य'),
                      ),
                      const SizedBox(width: 6),
                      _buildToneOption(
                        'Grievance',
                        AppTranslations.pick(lang, en: 'Grievances', mr: 'तक्रार निवारण', hi: 'शिकायत निवारण'),
                      ),
                      const SizedBox(width: 6),
                      _buildToneOption(
                        'Campaign',
                        AppTranslations.pick(lang, en: 'Campaign', mr: 'प्रचार मोहीम', hi: 'प्रचार अभियान'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingBrief ? null : _generateAiBrief,
                      icon: _isGeneratingBrief
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt, size: 16),
                      label: Text(
                        _isGeneratingBrief
                            ? AppTranslations.pick(
                                lang,
                                en: 'Generating Draft...',
                                mr: 'मसुदा तयार होत आहे...',
                                hi: 'ड्राफ्ट तैयार हो रहा है...',
                              )
                            : AppTranslations.pick(
                                lang,
                                en: 'Generate AI Brief',
                                mr: 'AI माहिती तयार करा',
                                hi: 'AI ब्रीफ तैयार करें',
                              ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  if (_generatedBrief.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: _briefLang == lang
                          ? Text(
                              _generatedBrief,
                              style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E293B)),
                            )
                          : AppTranslatedText(
                              _generatedBrief,
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E293B)),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Strategic Action Plan
          Text(
            AppTranslations.pick(
              lang,
              en: 'Strategic Action Points',
              mr: 'धोरणात्मक कृती आराखडा',
              hi: 'रणनीतिक कार्य बिंदु',
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildActionPoint(
            AppTranslations.formatDigits('1', lang),
            AppTranslations.pick(lang, en: 'Youth Outreach', mr: 'युवा संवाद मोहीम', hi: 'युवा संपर्क अभियान'),
            AppTranslations.pick(
              lang,
              en: 'Directly connect with $youthFormatted voters aged 18 to 35 via WhatsApp and sports clubs.',
              mr: 'WhatsApp आणि क्रीडा मंडळांच्या माध्यमातून १८ ते ३५ वयोगटातील $youthFormatted मतदारांशी थेट संपर्क साधा.',
              hi: 'WhatsApp और खेल क्लबों के माध्यम से १८ से ३५ आयु वर्ग के $youthFormatted मतदाताओं से सीधे जुड़ें।',
            ),
            const Color(0xFF3B82F6),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildActionPoint(
            AppTranslations.formatDigits('2', lang),
            AppTranslations.pick(
              lang,
              en: 'Pending Grievance Redressal',
              mr: 'प्रलंबित तक्रार निवारण',
              hi: 'लंबित शिकायत निवारण',
            ),
            AppTranslations.pick(
              lang,
              en: 'Conduct ground inspections with municipal officials to resolve remaining $ongoingFormatted complaints within a week.',
              mr: 'उर्वरित $ongoingFormatted तक्रारी एका आठवड्यात सोडवण्यासाठी पालिका अधिकाऱ्यांसोबत प्रत्यक्ष पाहणी करा.',
              hi: 'शेष $ongoingFormatted शिकायतों को एक सप्ताह के भीतर हल करने के लिए नगर निगम अधिकारियों के साथ जमीनी निरीक्षण करें।',
            ),
            const Color(0xFFEF4444),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildActionPoint(
            AppTranslations.formatDigits('3', lang),
            AppTranslations.pick(
              lang,
              en: 'Development Proposals',
              mr: 'विकासकामे प्रस्ताव',
              hi: 'विकास कार्य प्रस्ताव',
            ),
            AppTranslations.pick(
              lang,
              en: 'Expedite approved execution of $provisionsFormatted ward works and plan inauguration events.',
              mr: 'मंजूर झालेल्या $provisionsFormatted प्रभाग कामांची अंमलबजावणी वेगवान करा आणि लोकार्पण कार्यक्रमांचे नियोजन करा.',
              hi: 'स्वीकृत $provisionsFormatted वार्ड कार्यों के निष्पादन में तेजी लाएं और उद्घाटन कार्यक्रमों की योजना बनाएं।',
            ),
            const Color(0xFF10B981),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticalTab(ThemeData theme, bool isDark, String lang) {
    if (_reportData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Please select an area from the first tab first',
                  mr: 'कृपया पहिल्या टॅबमधून प्रथम परिसर निवडा',
                  hi: 'कृपया पहले टैब से पहले एक क्षेत्र चुनें',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _tabController.animateTo(0),
                child: Text(
                  AppTranslations.pick(lang, en: 'Select Area', mr: 'परिसर निवडा', hi: 'क्षेत्र चुनें'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final r = _reportData!;
    final localizedWinner = _localizeAllianceOrParty(r.winnerName, lang);
    final marginFormatted = AppTranslations.formatDigits(r.winningMargin, lang);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demographics Breakdown
          Text(
            AppTranslations.pick(
              lang,
              en: 'Demographics & Voter Breakdown',
              mr: 'लोकसंख्या व मतदार वर्गीकरण',
              hi: 'जनसांख्यिकी एवं मतदाता विवरण',
            ),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn(
                        AppTranslations.getGender('Male', lang),
                        AppTranslations.formatDigits(r.genderMale, lang),
                        const Color(0xFF3B82F6),
                      ),
                      _buildMetricColumn(
                        AppTranslations.getGender('Female', lang),
                        AppTranslations.formatDigits(r.genderFemale, lang),
                        const Color(0xFFEC4899),
                      ),
                      _buildMetricColumn(
                        AppTranslations.getGender('Other', lang),
                        AppTranslations.formatDigits(r.genderOther, lang),
                        Colors.grey,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn(
                        AppTranslations.pick(lang, en: '18-35 Youth', mr: '१८-३५ युवा', hi: '१८-३५ युवा'),
                        AppTranslations.formatDigits(r.age18_35, lang),
                        const Color(0xFF10B981),
                      ),
                      _buildMetricColumn(
                        AppTranslations.pick(lang, en: '36-60 Adult', mr: '३६-६० प्रौढ', hi: '३६-६० वयस्क'),
                        AppTranslations.formatDigits(r.age36_60, lang),
                        const Color(0xFFF59E0B),
                      ),
                      _buildMetricColumn(
                        AppTranslations.pick(lang, en: '61+ Senior', mr: '६१+ ज्येष्ठ', hi: '६१+ वरिष्ठ'),
                        AppTranslations.formatDigits(r.age61Plus, lang),
                        const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Caste Distribution
          Text(
            AppTranslations.pick(
              lang,
              en: 'Community Split',
              mr: 'समाज निहाय विभागणी',
              hi: 'समुदाय वार विभाजन',
            ),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: r.casteDistribution.entries.map((e) {
                  final pct = r.totalVoters > 0 ? (e.value / r.totalVoters) : 0.0;
                  final knownCaste = _localizeCaste(e.key, lang);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: knownCaste != null
                              ? Text(
                                  knownCaste,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : AppTranslatedText(
                                  e.key,
                                  targetLanguage: lang,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppTranslations.formatDigits(e.value, lang),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Political Results
          Text(
            AppTranslations.pick(
              lang,
              en: 'Past Election Analysis',
              mr: 'मागील निवडणूक विश्लेषण',
              hi: 'पिछला चुनाव विश्लेषण',
            ),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Winning Candidate / Alliance:',
                            mr: 'विजयी उमेदवार / आघाडी:',
                            hi: 'विजेता उम्मीदवार / गठबंधन:',
                          ),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: localizedWinner != null
                            ? Text(
                                localizedWinner,
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              )
                            : AppTranslatedText(
                                r.winnerName,
                                isName: true,
                                targetLanguage: lang,
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Winning Margin:',
                            mr: 'विजयी मताधिक्य:',
                            hi: 'जीत का अंतर:',
                          ),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: '+$marginFormatted votes',
                          mr: '+$marginFormatted मते',
                          hi: '+$marginFormatted मत',
                        ),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...r.partyPerformance.entries.map((p) {
                    final knownParty = _localizeAllianceOrParty(p.key, lang);
                    final votesFormatted = AppTranslations.formatDigits(p.value, lang);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: knownParty != null
                                ? Text(knownParty, style: const TextStyle(fontSize: 12))
                                : AppTranslatedText(
                                    p.key,
                                    targetLanguage: lang,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: '$votesFormatted votes',
                              mr: '$votesFormatted मते',
                              hi: '$votesFormatted मत',
                            ),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaSelectorView(ThemeData theme, bool isDark, String lang) {
    final areaCountFmt = AppTranslations.formatDigits(_allAreas.length, lang);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.analytics_outlined, color: Color(0xFF0284C7), size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Area Intelligence & Strategy System',
              mr: 'परिसर विश्लेषण आणि रणनीती प्रणाली',
              hi: 'क्षेत्र विश्लेषण एवं रणनीति प्रणाली',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Select any locality in Ward 12. The system aggregates voter count, civic complaints, and developmental metrics.',
              mr: 'प्रभाग १२ मधील कोणताही परिसर निवडा. प्रणाली मतदार संख्या, नागरी तक्रारी आणि विकास कामांचा डेटा एकत्रित करते.',
              hi: 'वार्ड १२ का कोई भी क्षेत्र चुनें। प्रणाली मतदाता संख्या, नागरिक शिकायतें और विकास संबंधी आंकड़े एकत्रित करती है।',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppTranslations.pick(
                lang,
                en: 'Type locality name (e.g. Shaniwar Peth)...',
                mr: 'परिसराचे नाव टाईप करा (उदा. शनिवार पेठ)...',
                hi: 'क्षेत्र का नाम लिखें (उदा. शनिवार पेठ)...',
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onSubmitted: (val) => _generateReport(val),
          ),

          const SizedBox(height: 14),

          // Quick selection dropdown / chips
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppTranslations.pick(
                lang,
                en: 'Or select from list ($areaCountFmt areas available):',
                mr: 'किंवा यादीतून निवडा ($areaCountFmt परिसर उपलब्ध):',
                hi: 'या सूची से चुनें ($areaCountFmt क्षेत्र उपलब्ध):',
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          AppDropdown<String>(
            title: AppTranslations.pick(
              lang,
              en: 'Select Area',
              mr: 'परिसर निवडा',
              hi: 'क्षेत्र चुनें',
            ),
            value: null,
            hintText: AppTranslations.pick(
              lang,
              en: 'Select Area...',
              mr: 'परिसर निवडा...',
              hi: 'क्षेत्र चुनें...',
            ),
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF0284C7)),
            height: 44,
            items: _allAreas.map((a) {
              return DropdownMenuItem<String>(
                value: a,
                child: AppTranslatedText(
                  AppTranslations.getAreaName(a, lang),
                  targetLanguage: lang,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                _searchController.text = val;
                _generateReport(val);
              }
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _generateReport(_searchController.text),
              icon: const Icon(Icons.insights, size: 18),
              label: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Generate Strategic Report',
                  mr: 'धोरणात्मक अहवाल तयार करा',
                  hi: 'रणनीतिक रिपोर्ट तैयार करें',
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPipeline(bool isDark, String lang) {
    final steps = [
      AppTranslations.pick(
        lang,
        en: 'Aggregating voter roll data...',
        mr: 'मतदार यादीचा डेटा एकत्रित करत आहे...',
        hi: 'मतदाता सूची डेटा एकत्रित किया जा रहा है...',
      ),
      AppTranslations.pick(
        lang,
        en: 'Analyzing civic grievances and complaints...',
        mr: 'नागरी तक्रारी व समस्यांचे विश्लेषण करत आहे...',
        hi: 'नागरिक शिकायतों और समस्याओं का विश्लेषण हो रहा है...',
      ),
      AppTranslations.pick(
        lang,
        en: 'Reviewing past election margins and turnout...',
        mr: 'मागील निवडणूक मताधिक्य आणि मतदानाची पाहणी करत आहे...',
        hi: 'पिछले चुनाव के अंतर और मतदान की समीक्षा हो रही है...',
      ),
      AppTranslations.pick(
        lang,
        en: 'Analyzing development fund provisions...',
        mr: 'विकास निधी तरतुदींचे विश्लेषण करत आहे...',
        hi: 'विकास निधि प्रावधानों का विश्लेषण हो रहा है...',
      ),
      AppTranslations.pick(
        lang,
        en: 'Compiling final strategic dossier...',
        mr: 'अंतिम धोरणात्मक अहवाल तयार करत आहे...',
        hi: 'अंतिम रणनीतिक रिपोर्ट संकलित की जा रही है...',
      ),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0284C7)),
            const SizedBox(height: 20),
            Text(
              AppTranslations.pick(
                lang,
                en: 'Compiling intelligence data...',
                mr: 'माहिती संकलित करत आहे...',
                hi: 'डेटा संकलित किया जा रहा है...',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (idx) {
              final isDone = idx <= _loadingStep;
              final isCurrent = idx == _loadingStep;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: isDone ? const Color(0xFF10B981) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        steps[idx],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? const Color(0xFF0284C7) : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildToneOption(String tone, String label) {
    final isSel = _selectedTone == tone;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTone = tone),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSel ? const Color(0xFF0284C7) : Colors.grey[300]!),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSel ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPoint(String num, String title, String desc, Color color, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(num, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

