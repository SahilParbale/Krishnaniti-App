import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

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
    'शनिवार पेठ (Shaniwar Peth)',
    'कसबा पेठ (Kasba Peth)',
    'रविवार पेठ (Raviwar Peth)',
    'सोमवार पेठ (Somwar Peth)',
    'बुधवार पेठ (Budhwar Peth)',
    'शुक्रवार पेठ (Shukrawar Peth)',
    'गणेश पेठ (Ganesh Peth)',
    'भवानी पेठ (Bhavani Peth)',
    'नाना पेठ (Nana Peth)',
    'रास्ता पेठ (Rasta Peth)',
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
    if (area.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया क्षेत्र निवडा किंवा नाव टाईप करा')),
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
        'मराठा': (totalVoters * 0.40).round(),
        'ब्राह्मण': (totalVoters * 0.22).round(),
        'ओबीसी': (totalVoters * 0.18).round(),
        'इतर समाज': (totalVoters * 0.20).round(),
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
        winnerName: 'आपला नगरसेवक (महायुती)',
        winningMargin: 480,
        partyPerformance: {
          'महायुती': (totalVoters * 0.38).round(),
          'महाविकास आघाडी': (totalVoters * 0.24).round(),
          'इतर': (totalVoters * 0.06).round(),
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

  void _generateAiBrief() async {
    if (_reportData == null) return;
    setState(() => _isGeneratingBrief = true);

    await Future.delayed(const Duration(milliseconds: 900));

    final area = _reportData!.areaName;
    String brief = '';

    if (_selectedTone == 'Development') {
      brief = '🚩 *विकास व नागरी सुविधा दौरा आराखडा - $area*\n\n'
          'नमस्कार, प्रभाग १२ मधील $area येथे नुकत्याच पूर्ण झालेल्या जलवाहिनी सिमेंट काँक्रीट व नवीन एलईडी पथदिवे कामांचे उद्घाटन होणार आहे.\n\n'
          '📌 *महत्त्वाचे मुद्दे:*\n'
          '• एकूण मतदार: ${_reportData!.totalVoters} | मोबाईल संपर्क: ${_reportData!.mobileReach}%\n'
          '• सोडवलेल्या तक्रारी: ${_reportData!.solvedComplaints} पैकी ${_reportData!.totalComplaints}\n'
          '• विकास निधी खर्च: ₹${NumberFormat.currency(locale: 'en_IN', symbol: '').format(_reportData!.utilizedBudget)}\n\n'
          '🎯 *आवाहन:* नागरिकांच्या उर्वरित स्वच्छता व पाणीपुरवठा समस्या प्राधान्याने निकाली काढण्याची कटिबद्धता जाहीर करावी.';
    } else if (_selectedTone == 'Grievance') {
      brief = '⚠️ *नागरी समस्या निवारण बैठक - $area*\n\n'
          '$area परिसरातील प्रलंबित ${_reportData!.ongoingComplaints} तक्रारींच्या निवारणासाठी महापालिका अधिकारी व कनिष्ठ अभियंत्यांसमवेत संयुक्त पाहणी दौरा.\n\n'
          '📌 *प्राधान्य विषय:*\n'
          '• सांडपाणी ड्रेनेज चेंबर दुरुस्ती व डास प्रतिबंधक धूर फवारणी\n'
          '• ज्येष्ठ नागरिकांसाठी पदपथ सुरक्षितता व स्वच्छता मोहीम\n\n'
          '🎯 *कृती योजना:* २४ तासांत महापालिका हेल्पलाईनद्वारे टोकन नंबर जारी करून कामाचा अहवाल नागरिकांना सुपूर्द केला जाईल.';
    } else {
      brief = '🏆 *निवडणूक प्रचार व बूथ मजबुतीकरण - $area*\n\n'
          '$area मधील सक्रिय कार्यकर्त्यांची बैठक व बूथनिहाय मतदारांशी थेट संवाद.\n\n'
          '📌 *राजकीय स्थिती:*\n'
          '• एकूण मतदार: ${_reportData!.totalVoters}\n'
          '• हक्काचे समर्थक: ${_reportData!.supportersCount} (घनता ${(_reportData!.supportersCount / _reportData!.totalVoters * 100).round()}%)\n'
          '• गत निवडणुकीतील आघाडी: +${_reportData!.winningMargin} मते\n\n'
          '🎯 *रणनीती:* १८-३५ वयोगटातील तरुण मतदारांना क्रीडा साहित्य व शासकीय योजना केंद्रांमार्फत जोडणे.';
    }

    if (mounted) {
      setState(() {
        _generatedBrief = brief;
        _isGeneratingBrief = false;
      });
    }
  }

  void _shareViaWhatsApp() {
    if (_reportData == null) return;
    final text = _generatedBrief.isNotEmpty
        ? _generatedBrief
        : '📊 *${_reportData!.areaName} विश्लेषण व धोरण अहवाल*\n'
            'एकूण मतदार: ${_reportData!.totalVoters}\n'
            'समर्थक: ${_reportData!.supportersCount}\n'
            'सोडवलेल्या तक्रारी: ${_reportData!.solvedComplaints}/${_reportData!.totalComplaints}\n'
            'विकास निधी: ₹${_reportData!.utilizedBudget}\n\n'
            '_नगरसेवक जनसंपर्क कार्यालय, प्रभाग १२_';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('अहवाल क्लिपबोर्डवर कॉपी केला! WhatsApp वर पेस्ट करा.'),
        backgroundColor: Color(0xFF25D366),
      ),
    );
  }

  Future<void> _exportPdfReport() async {
    if (_reportData == null) return;
    final r = _reportData!;
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - PRABHAG 12',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                      ),
                      pw.Text(
                        'क्षेत्रीय गुप्तचर व सल्लागार अहवाल (Analysis & Strategy Docket)',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                      pw.Text('Area: ${r.areaName} · Confidential Political Document', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 10),

              // KPI Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pwStatCard('Total Voters', '${r.totalVoters}'),
                  _pwStatCard('Supporters', '${r.supportersCount}'),
                  _pwStatCard('Mobile Reach', '${r.mobileReach}%'),
                  _pwStatCard('Complaints Solved', '${r.solvedComplaints} / ${r.totalComplaints}'),
                ],
              ),
              pw.SizedBox(height: 14),

              // Demographics Table
              pw.Text('Demographic Breakdown', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Category', 'Male', 'Female', 'Youth (18-35)', 'Working (36-60)', 'Senior (61+)'],
                data: [
                  ['Count', '${r.genderMale}', '${r.genderFemale}', '${r.age18_35}', '${r.age36_60}', '${r.age61Plus}'],
                ],
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 14),

              // Political & Development
              pw.Text('Political Strength & Development Works', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Parameter', 'Details / Metrics'],
                data: [
                  ['Winning Status', '${r.winnerName} (Margin: +${r.winningMargin})'],
                  ['Total Votes Casted', '${r.totalElectionVotes} votes in area'],
                  ['Utilized Budget', 'Rs. ${r.utilizedBudget}'],
                  ['Requested Provisions', '${r.requestedProvisionsCount} ongoing proposals (Rs. ${r.provisionsAmount})'],
                ],
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
              ),

              if (_generatedBrief.isNotEmpty) ...[
                pw.SizedBox(height: 14),
                pw.Text('AI Field Visit Briefing', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(_generatedBrief, style: const pw.TextStyle(fontSize: 8.5)),
                ),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pwStatCard(String title, String value) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.insights_rounded, color: Color(0xFFD97706), size: 24),
            SizedBox(width: 8),
            Text('Analysis & Strategy'),
          ],
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD97706),
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: const Color(0xFFD97706),
          tabs: const [
            Tab(icon: Icon(Icons.psychology_outlined), text: 'धोरण (Strategy Mode)'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'विश्लेषण (Analytical Data)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStrategyTab(theme, isDark),
          _buildAnalyticalTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildStrategyTab(ThemeData theme, bool isDark) {
    if (_isGenerating) {
      return _buildLoadingPipeline(isDark);
    }

    if (!_reportGenerated || _reportData == null) {
      return _buildAreaSelectorView(theme, isDark);
    }

    final r = _reportData!;

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
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.areaName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text('प्रभाग १२ · गुप्तचर व सल्लागार अहवाल', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _reportGenerated = false),
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text('बदला', style: TextStyle(fontSize: 11)),
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
                child: ElevatedButton.icon(
                  onPressed: _exportPdfReport,
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF अहवाल डाउनलोड'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareViaWhatsApp,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('WhatsApp शेअर'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Overview KPI Grid
          const Text('महत्त्वाचे निर्देशक (Executive Overview)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard('एकूण मतदार', '${r.totalVoters}', Icons.people_alt, const Color(0xFF3B82F6), isDark),
              _buildKpiCard('मोबाईल संपर्क', '${r.mobileReach}%', Icons.phone_android, const Color(0xFF10B981), isDark),
              _buildKpiCard('हक्काचे समर्थक', '${r.supportersCount}', Icons.verified_user, const Color(0xFF8B5CF6), isDark),
              _buildKpiCard('सोडवलेल्या तक्रारी', '${r.solvedComplaints}/${r.totalComplaints}', Icons.task_alt, const Color(0xFFF59E0B), isDark),
            ],
          ),

          const SizedBox(height: 16),

          // AI Visit Speeches / Field Briefing Generator
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFFDE68A)),
            ),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'AI दौरा व भाषण मसुदा (Visit Briefing AI)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'परिसराच्या डेटावर आधारित स्वयंचलित प्रभावी दौरा भाषण व रणनीती तयार करा.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                  ),
                  const SizedBox(height: 10),

                  // Tone selection
                  Row(
                    children: [
                      _buildToneOption('Development', 'विकासकामे'),
                      const SizedBox(width: 6),
                      _buildToneOption('Grievance', 'नागरी अडचणी'),
                      const SizedBox(width: 6),
                      _buildToneOption('Campaign', 'निवडणूक'),
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
                      label: Text(_isGeneratingBrief ? 'मसुदा तयार होत आहे...' : 'AI मसुदा तयार करा'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
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
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        _generatedBrief,
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
          const Text('धोरणात्मक कृती योजना (Strategic Action Points)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildActionPoint('१', 'युवा मतदार संवाद (Youth Outreach)', '१८ ते ३५ वयोगटातील ${r.age18_35} मतदारांशी व्हॉट्सॲप व क्रीडा मंडळांच्या माध्यमातून थेट संवाद साधा.', const Color(0xFF3B82F6), isDark),
          const SizedBox(height: 8),
          _buildActionPoint('२', 'प्रलंबित नागरी तक्रारी निवारण', 'परिसरातील उर्वरित ${r.ongoingComplaints} तक्रारी महापालिका अधिकाऱ्यांशी प्रत्यक्ष पाहणी करून आठवड्यात मार्गी लावा.', const Color(0xFFEF4444), isDark),
          const SizedBox(height: 8),
          _buildActionPoint('३', 'विकास निधी प्रस्ताव', '${r.requestedProvisionsCount} विकासकामांचे मंजूर प्रस्ताव लवकरात लवकर पूर्ण करून उद्घाटनाचे नियोजन करा.', const Color(0xFF10B981), isDark),
        ],
      ),
    );
  }

  Widget _buildAnalyticalTab(ThemeData theme, bool isDark) {
    if (_reportData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('कृपया प्रथम पहिल्या टॅबवरून क्षेत्र निवडा', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('क्षेत्र निवडा'),
            ),
          ],
        ),
      );
    }

    final r = _reportData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demographics Breakdown
          const Text('लोकसंख्या व मतदार वर्गवारी (Demographics)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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
                      _buildMetricColumn('पुरुष', '${r.genderMale}', const Color(0xFF3B82F6)),
                      _buildMetricColumn('महिला', '${r.genderFemale}', const Color(0xFFEC4899)),
                      _buildMetricColumn('इतर', '${r.genderOther}', Colors.grey),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn('१८-३५ युवा', '${r.age18_35}', const Color(0xFF10B981)),
                      _buildMetricColumn('३६-६० प्रौढ', '${r.age36_60}', const Color(0xFFF59E0B)),
                      _buildMetricColumn('६१+ ज्येष्ठ', '${r.age61Plus}', const Color(0xFF6366F1)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Caste Distribution
          const Text('सामाजिक वर्गवारी (Community Split)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 80, child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Political Results
          const Text('मागील निवडणूक निकाल (Past Election Analysis)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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
                      const Text('विजेता उमेदवार / आघाडी:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(r.winnerName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('आघाडी (Winning Margin):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('+${r.winningMargin} मते', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ],
                  ),
                  const Divider(height: 20),
                  ...r.partyPerformance.entries.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.key, style: const TextStyle(fontSize: 12)),
                            Text('${p.value} मते', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaSelectorView(ThemeData theme, bool isDark) {
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
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.analytics_outlined, color: Color(0xFFD97706), size: 36),
          ),
          const SizedBox(height: 14),
          const Text(
            'क्षेत्रीय गुप्तचर व सल्लागार प्रणाली',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'प्रभागातील कोणत्याही परिसराचे नाव निवडा. प्रणाली मतदार संख्या, नागरी समस्या व विकासकामांचे विश्लेषण संकलित करेल.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'परिसराचे नाव टाईप करा (उदा. शनिवार पेठ)...',
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
              'किंवा यादीतून निवडा (${_allAreas.length} क्षेत्रे उपलब्ध):',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('क्षेत्र निवडा...', style: TextStyle(fontSize: 13)),
                items: _allAreas.map((a) {
                  return DropdownMenuItem<String>(
                    value: a,
                    child: Text(a, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _searchController.text = val;
                    _generateReport(val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _generateReport(_searchController.text),
              icon: const Icon(Icons.insights, size: 18),
              label: const Text('अहवाल संकलित करा (Generate Report)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPipeline(bool isDark) {
    final steps = [
      'मतदार यादी व डेटा संकलन...',
      'नागरी तक्रारी व अडचणी विश्लेषण...',
      'मागील निवडणूक कल व मतदान...',
      'विकासकामे व निधी तरतूद...',
      'अंतिम सल्लागार अहवाल तयार होत आहे...',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFD97706)),
            const SizedBox(height: 20),
            const Text(
              'गुप्तचर डेटा संकलन सुरू आहे...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    Text(
                      steps[idx],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? const Color(0xFFD97706) : Colors.grey[700],
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
                Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)),
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFD97706) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSel ? const Color(0xFFD97706) : Colors.grey[300]!),
          ),
          child: Text(
            label,
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
              backgroundColor: color.withOpacity(0.15),
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

