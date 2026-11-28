import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/analysis_strategy/analysis_strategy_report_generator.dart';
import '../../../screens/analysis_strategy/analysis_strategy_screen.dart';
import '../../../widgets/app_dropdown.dart';

class DesktopAnalysisStrategyView extends ConsumerStatefulWidget {
  const DesktopAnalysisStrategyView({super.key});

  @override
  ConsumerState<DesktopAnalysisStrategyView> createState() => _DesktopAnalysisStrategyViewState();
}

class _DesktopAnalysisStrategyViewState extends ConsumerState<DesktopAnalysisStrategyView> {
  String _activeTab = 'strategy'; // 'strategy' | 'analytical'
  String _selectedArea = 'Shaniwar Peth';
  String _selectedTone = 'Development'; // 'Development' | 'Grievance' | 'Campaign'
  bool _isGenerating = false;
  bool _hasCustomBrief = false;

  final List<String> _areas = [
    'Shaniwar Peth',
    'Kasba Peth',
    'Narayan Peth',
    'Sadashiv Peth',
    'Raviwar Peth',
  ];

  String _localizedArea(String area, String lang) {
    if (area == 'Raviwar Peth') {
      return AppTranslations.pick(
        lang,
        en: 'Raviwar Peth',
        mr: 'रविवार पेठ',
        hi: 'रविवार पेठ',
      );
    }
    return AppTranslations.getAreaName(area, lang);
  }

  String _localizedToneLabel(String tone, String lang) {
    switch (tone) {
      case 'Grievance':
        return AppTranslations.pick(
          lang,
          en: 'Grievance',
          mr: 'तक्रार निवारण',
          hi: 'शिकायत निवारण',
        );
      case 'Campaign':
        return AppTranslations.pick(
          lang,
          en: 'Campaign',
          mr: 'निवडणूक प्रचार',
          hi: 'चुनाव अभियान',
        );
      case 'Development':
      default:
        return AppTranslations.pick(
          lang,
          en: 'Development',
          mr: 'विकास कामे',
          hi: 'विकास कार्य',
        );
    }
  }

  String _buildBriefText(String lang) {
    final areaName = _localizedArea(_selectedArea, lang);
    final toneLabel = _localizedToneLabel(_selectedTone, lang);

    if (!_hasCustomBrief) {
      return AppTranslations.formatDigits(
        AppTranslations.pick(
          lang,
          en: '''📌 **Ward 12 ($areaName) - Strategic Campaign Intelligence Brief**:

1. **Water Supply & Infrastructure Repairs**: Citizen complaints regarding low water pressure constitute 28% of overall volume in this pocket. Prioritizing pipeline overhaul works will yield immediate voter goodwill.
2. **Youth Voter Outreach (Age 18-35)**: Constitutes 42% of local electorate. Organizing career guidance workshops and inter-ward sports tournaments is strongly recommended.
3. **Welfare Scheme Camps**: Over 500+ applications have been processed for central & state welfare benefits; scheduling a dedicated assistance desk in the community hall will consolidate support.
4. **Cooperative Housing Society Meetings**: Direct liaison with management committees across 8 prominent apartment societies is recommended for upcoming weekend town halls.''',
          mr: '''📌 **प्रभाग 12 ($areaName) - रणनीतिक मोहीम विश्लेषण सारांश**:

1. **पाणी पुरवठा व पायाभूत सुविधा दुरुस्ती**: या परिसरातील एकूण तक्रारींपैकी 28% तक्रारी कमी दाबाच्या पाणी पुरवठ्याशी संबंधित आहेत. जलवाहिनी दुरुस्तीस प्राधान्य दिल्यास मतदारांचा तात्काळ विश्वास वाढेल.
2. **युवा मतदार संपर्क (वय 18-35)**: स्थानिक मतदारांपैकी 42% मतदार युवा वर्गातील आहेत. करिअर मार्गदर्शन शिबिरे व प्रभागस्तरीय क्रीडा स्पर्धा आयोजित करण्याची शिफारस आहे.
3. **कल्याणकारी योजना शिबिरे**: केंद्र व राज्य शासनाच्या विविध योजनांसाठी 500+ हून अधिक अर्जांवर कार्यवाही झाली आहे; समाज मंदिरात विशेष मदत केंद्र सुरू केल्यास पाठिंबा अधिक दृढ होईल.
4. **सहकारी गृहनिर्माण संस्था बैठका**: आगामी आठवड्याच्या शेवटी 8 प्रमुख अपार्टमेंट सोसायट्यांच्या कार्यकारी समित्यांशी थेट संवाद बैठकांचे आयोजन करण्याची शिफारस आहे.''',
          hi: '''📌 **वार्ड 12 ($areaName) - रणनीतिक अभियान विश्लेषण सारांश**:

1. **जल आपूर्ति एवं बुनियादी ढांचा सुधार**: इस क्षेत्र में कुल शिकायतों का 28% कम पानी के दबाव से संबंधित है। पाइपलाइन सुधार कार्यों को प्राथमिकता देने से तत्काल मतदाता सद्भावना प्राप्त होगी।
2. **युवा मतदाता संपर्क (आयु 18-35)**: स्थानीय मतदाताओं में 42% युवा वर्ग से हैं। करियर मार्गदर्शन कार्यशालाओं और अंतर-वार्ड खेल प्रतियोगिताओं का आयोजन अत्यंत अनुशंसित है।
3. **कल्याणकारी योजना शिविर**: केंद्र और राज्य सरकार की योजनाओं के तहत 500+ से अधिक आवेदनों का निपटारा किया जा चुका है; सामुदायिक भवन में समर्पित सहायता केंद्र लगाने से जनसमर्थन मजबूत होगा।
4. **सहकारी हाउसिंग सोसायटी बैठकें**: आगामी सप्ताहांत टाउन हॉल बैठकों के लिए 8 प्रमुख अपार्टमेंट सोसायटियों की प्रबंधन समितियों के साथ सीधा संवाद अनुशंसित है।''',
        ),
        lang,
      );
    }

    return AppTranslations.formatDigits(
      AppTranslations.pick(
        lang,
        en: '''📌 **Ward 12 ($areaName) - Strategic Focus: $toneLabel**:

• **Core Priority #1**: Accelerate visible development works and local civic infrastructure completion across $areaName.
• **Grievance Resolution Velocity**: Current resolution rate stands at 84%; target an increase to 92% over the next 3 weeks before election announcements.
• **Community Outreach**: Coordinate direct interactive sessions with local senior citizen clubs and commercial merchant associations next week.
• **Digital Amplification**: Broadcast video reels of completed road concreting and LED street lighting upgrades across WhatsApp and Facebook networks.''',
        mr: '''📌 **प्रभाग 12 ($areaName) - मुख्य रणनीतिक दिशा: $toneLabel**:

• **मुख्य प्राधान्य #1**: $areaName परिसरात दृश्यमान विकास कामे व स्थानिक नागरी पायाभूत सुविधांची पूर्तता वेगाने पूर्ण करा.
• **तक्रार निवारण वेग**: सध्याचे तक्रार निवारण प्रमाण 84% आहे; निवडणूक घोषणेपूर्वी पुढील 3 आठवड्यांत ते 92% पर्यंत नेण्याचे उद्दिष्ट ठेवा.
• **लोकसंपर्क मोहीम**: पुढील आठवड्यात स्थानिक ज्येष्ठ नागरिक संघटना व व्यापारी महासंघांसोबत थेट संवादात्मक बैठकांचे आयोजन करा.
• **डिजिटल प्रसार**: पूर्ण झालेल्या काँक्रीट रस्ते आणि LED पथदिव्यांच्या कामांचे व्हिडिओ रील्स व्हॉट्सॲप व फेसबुक नेटवर्कद्वारे प्रसारित करा.''',
        hi: '''📌 **वार्ड 12 ($areaName) - रणनीतिक फोकस: $toneLabel**:

• **मुख्य प्राथमिकता #1**: $areaName क्षेत्र में दृश्यमान विकास कार्यों और स्थानीय नागरिक बुनियादी ढांचे को तेजी से पूरा करें।
• **शिकायत समाधान गति**: वर्तमान समाधान दर 84% है; चुनाव घोषणाओं से पहले अगले 3 सप्ताह में इसे 92% तक बढ़ाने का लक्ष्य रखें।
• **सामुदायिक संपर्क**: अगले सप्ताह स्थानीय वरिष्ठ नागरिक क्लबों और व्यापारिक संघों के साथ सीधे संवादात्मक सत्र आयोजित करें।
• **डिजिटल प्रचार**: पूर्ण हुए सड़क कंक्रीटीकरण और LED स्ट्रीट लाइट उन्नयन कार्यों के वीडियो रील व्हाट्सएप और फेसबुक नेटवर्क पर प्रसारित करें।''',
      ),
      lang,
    );
  }

  Future<void> _triggerAiAnalysis() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _hasCustomBrief = true;
      });
    }
  }

  AreaMetrics _getMetricsForArea(String area) {
    return AreaMetrics(
      areaName: area,
      totalVoters: 2480,
      staffCount: 8,
      supportersCount: 1120,
      mobileReach: 82,
      genderMale: 1280,
      genderFemale: 1180,
      genderOther: 20,
      age18_35: 980,
      age36_60: 1040,
      age61Plus: 460,
      casteDistribution: const {'General': 820, 'OBC': 740, 'SC/ST': 420, 'Maratha': 500},
      totalComplaints: 64,
      solvedComplaints: 52,
      ongoingComplaints: 8,
      assignedComplaints: 4,
      totalRequests: 38,
      solvedRequests: 30,
      pendingRequests: 8,
      totalElectionVotes: 1980,
      winnerName: 'BJP (Sitting)',
      winningMargin: 340,
      partyPerformance: const {'BJP': 980, 'NCP': 640, 'INC': 260, 'SS': 100},
      conductedEventsCount: 12,
      avgRsvpAttendance: 85,
      positiveArticlesCount: 8,
      negativeArticlesCount: 2,
      allocatedBudget: 5000000,
      utilizedBudget: 3800000,
      requestedProvisionsCount: 6,
      provisionsAmount: 2200000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final briefText = _buildBriefText(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.query_stats_rounded, color: AppColors.brandPrimary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Analysis Strategy',
                                mr: 'विश्लेषण व रणनीती',
                                hi: 'विश्लेषण और रणनीति',
                              ),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'AI-assisted strategic ward insights, demographic breakdowns, and ground campaign roadmaps',
                                mr: 'AI-आधारित प्रभाग रणनीती माहिती, लोकसंख्याशास्त्र विश्लेषण आणि प्रत्यक्ष मोहीम आराखडा',
                                hi: 'एआई-सहायता प्राप्त रणनीतिक वार्ड अंतर्दृष्टि, जनसांख्यिकीय विश्लेषण और जमीनी अभियान रोडमैप',
                              ),
                              style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Download Report matching AnalysisStrategy.tsx
                OutlinedButton.icon(
                  onPressed: () {
                    AnalysisStrategyReportGenerator.generateAndPrintReport(
                      context: context,
                      reportData: _getMetricsForArea(_selectedArea),
                      generatedBrief: briefText,
                      lang: lang,
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                  label: Text(
                    AppTranslations.getDownloadReport(lang),
                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F9FF),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    'strategy',
                    AppTranslations.pick(
                      lang,
                      en: 'Strategy Planner',
                      mr: 'रणनीती नियोजक',
                      hi: 'रणनीति योजनाकार',
                    ),
                    Icons.track_changes_rounded,
                  ),
                  _buildTabButton(
                    'analytical',
                    AppTranslations.pick(
                      lang,
                      en: 'Analytical Dashboard',
                      mr: 'विश्लेषणात्मक डॅशबोर्ड',
                      hi: 'विश्लेषणात्मक डैशबोर्ड',
                    ),
                    Icons.insights_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top Area Selector & Metrics
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Select Ward Area:',
                      mr: 'प्रभाग परिसर निवडा:',
                      hi: 'वार्ड क्षेत्र चुनें:',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700),
                  ),
                  const SizedBox(width: 14),
                  AppDropdown<String>(
                    value: _selectedArea,
                    height: 40,
                    width: 220,
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFFE2E8F0),
                    items: _areas
                        .map((a) => DropdownMenuItem(value: a, child: Text(_localizedArea(a, lang))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedArea = v);
                        _triggerAiAnalysis();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4 Stat Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    AppTranslations.pick(lang, en: 'Total Voters', mr: 'एकूण मतदार', hi: 'कुल मतदाता'),
                    AppTranslations.formatDigits('14,820', lang),
                    Icons.how_to_reg_rounded,
                    AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    AppTranslations.pick(lang, en: 'Resolved Complaints', mr: 'सोडवलेल्या तक्रारी', hi: 'सुलझाई गई शिकायतें'),
                    AppTranslations.formatDigits('88.4%', lang),
                    Icons.check_circle_rounded,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    AppTranslations.pick(lang, en: 'Mobile Reach', mr: 'मोबाईल संपर्क', hi: 'मोबाइल पहुंच'),
                    AppTranslations.formatDigits('76.2%', lang),
                    Icons.phone_android_rounded,
                    AppColors.brand500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    AppTranslations.pick(lang, en: 'Winning Margin', mr: 'विजयी मताधिक्य', hi: 'जीत का अंतर'),
                    AppTranslations.formatDigits('+2,480', lang),
                    Icons.trending_up_rounded,
                    AppColors.brand700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_activeTab == 'strategy') ...[
              // AI Strategy Generation Box
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: AppColors.brandPrimary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'AI Strategic Intelligence & Campaign Brief',
                                    mr: 'AI रणनीतिक विश्लेषण व मोहीम सारांश',
                                    hi: 'एआई रणनीतिक बुद्धिमत्ता एवं अभियान सारांश',
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'Development',
                                  label: Text(AppTranslations.pick(lang, en: 'Dev', mr: 'विकास', hi: 'विकास')),
                                ),
                                ButtonSegment(
                                  value: 'Grievance',
                                  label: Text(AppTranslations.pick(lang, en: 'Grievance', mr: 'तक्रार', hi: 'शिकायत')),
                                ),
                                ButtonSegment(
                                  value: 'Campaign',
                                  label: Text(AppTranslations.pick(lang, en: 'Campaign', mr: 'प्रचार', hi: 'अभियान')),
                                ),
                              ],
                              selected: {_selectedTone},
                              onSelectionChanged: (s) {
                                setState(() => _selectedTone = s.first);
                                _triggerAiAnalysis();
                              },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isGenerating ? null : _triggerAiAnalysis,
                              icon: _isGenerating
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(
                                _isGenerating
                                    ? AppTranslations.pick(lang, en: 'Generating...', mr: 'तयार होत आहे...', hi: 'तैयार हो रहा है...')
                                    : AppTranslations.pick(lang, en: 'Regenerate', mr: 'पुन्हा तयार करा', hi: 'पुनः तैयार करें'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Text(
                        briefText,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.slate800),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Analytical Dashboard Tab
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Demographic distribution
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Voter Gender Demographics',
                              mr: 'मतदार लिंगनिहाय वर्गवारी',
                              hi: 'मतदाता लिंग जनसांख्यिकी',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                          ),
                          const SizedBox(height: 18),
                          _buildDemographicBar(AppTranslations.getGender('Male', lang), 52, AppColors.brand600, lang),
                          const SizedBox(height: 14),
                          _buildDemographicBar(AppTranslations.getGender('Female', lang), 47, const Color(0xFFEC4899), lang),
                          const SizedBox(height: 14),
                          _buildDemographicBar(AppTranslations.getGender('Other', lang), 1, AppColors.brand800, lang),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Problem Categories
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Key Ward Grievances Distribution',
                              mr: 'प्रभागातील प्रमुख तक्रारींचे वर्गीकरण',
                              hi: 'प्रमुख वार्ड शिकायतों का वितरण',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                          ),
                          const SizedBox(height: 18),
                          _buildDemographicBar(
                            AppTranslations.pick(lang, en: 'Water Supply', mr: 'पाणी पुरवठा', hi: 'जल आपूर्ति'),
                            34,
                            Colors.cyan,
                            lang,
                          ),
                          const SizedBox(height: 14),
                          _buildDemographicBar(
                            AppTranslations.pick(lang, en: 'Roads & Pavements', mr: 'रस्ते व पदपथ', hi: 'सड़कें और फुटपाथ'),
                            28,
                            Colors.amber.shade700,
                            lang,
                          ),
                          const SizedBox(height: 14),
                          _buildDemographicBar(
                            AppTranslations.pick(lang, en: 'Sanitation & Garbage', mr: 'स्वच्छता व कचरा', hi: 'स्वच्छता और कचरा'),
                            22,
                            Colors.green,
                            lang,
                          ),
                          const SizedBox(height: 14),
                          _buildDemographicBar(
                            AppTranslations.pick(lang, en: 'Streetlights', mr: 'पथदिवे', hi: 'स्ट्रीट लाइट'),
                            16,
                            Colors.deepOrange,
                            lang,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicBar(String label, int percentage, Color color, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate700)),
            Text(
              AppTranslations.formatDigits('$percentage%', lang),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.slate100,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTabButton(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return InkWell(
      onTap: () => setState(() => _activeTab = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.brandPrimary : AppColors.slate500),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.brandPrimary : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
