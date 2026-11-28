import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/survey_model.dart';
import '../../../data/repositories/surveys_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';

class SurveyDetailScreen extends ConsumerStatefulWidget {
  final SurveyModel survey;

  const SurveyDetailScreen({super.key, required this.survey});

  @override
  ConsumerState<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends ConsumerState<SurveyDetailScreen> {
  bool _isLoading = true;
  List<SurveyResponseModel> _responses = [];

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() => _isLoading = true);
    final repo = ref.read(surveysRepoProvider);
    final resp = await repo.getResponses(widget.survey.id);

    if (mounted) {
      setState(() {
        _responses = resp;
        _isLoading = false;
      });
    }
  }

  Future<void> _shareOnWhatsApp(String lang) async {
    final tTitle = await DynamicTranslationService.translateOrRaw(widget.survey.title, lang);
    final text = AppTranslations.pick(
      lang,
      en: 'Hello, important citizen opinion survey for Ward 12:\n"$tTitle"\nPlease register your opinion and help us develop the ward.',
      mr: 'नमस्कार, प्रभाग १२ साठी महत्त्वाचे नागरिक मत सर्व्हेक्षण:\n"$tTitle"\nकृपया आपले मत नोंदवा आणि प्रभागाच्या विकासात सहभागी व्हा.',
      hi: 'नमस्ते, वार्ड १२ के लिए महत्वपूर्ण नागरिक राय सर्वेक्षण:\n"$tTitle"\nकृपया अपनी राय दर्ज करें और वार्ड के विकास में सहयोग करें।',
    );
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final totalResponses = _responses.length;
    final target = widget.survey.targetSampleSize > 0 ? widget.survey.targetSampleSize : 100;
    final completionRate = ((totalResponses / target) * 100).clamp(0, 100).toInt();
    final dateFormatted = AppTranslations.formatDate(
      widget.survey.createdAt,
      lang,
      pattern: 'dd MMMM yyyy',
    );
    final qCountStr = AppTranslations.formatDigits(widget.survey.questions.length, lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'पीछे'),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTranslations.pick(
            lang,
            en: 'Survey Analysis & Results',
            mr: 'सर्व्हेक्षण विश्लेषण व निकाल',
            hi: 'सर्वेक्षण विश्लेषण और परिणाम',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Share on WhatsApp',
              mr: 'व्हॉट्सअॅपवर शेअर करा',
              hi: 'व्हाट्सऐप पर साझा करें',
            ),
            onPressed: () => _shareOnWhatsApp(lang),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : RefreshIndicator(
              onRefresh: _loadResponses,
              color: const Color(0xFF0284C7),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Meta Card
                    _buildSurveyHeaderCard(dateFormatted, lang),

                    const SizedBox(height: 16),

                    // KPI Response Progress Cards
                    _buildProgressKpiCards(totalResponses, target, completionRate, lang),

                    const SizedBox(height: 20),

                    // Analytics Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Question-wise Citizen Response Analysis',
                              mr: 'प्रश्ननिहाय नागरिक प्रतिसाद विश्लेषण',
                              hi: 'प्रश्न-वार नागरिक प्रतिक्रिया विश्लेषण',
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: '$qCountStr Questions',
                            mr: '$qCountStr प्रश्न',
                            hi: '$qCountStr प्रश्न',
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Question Breakdown Cards
                    ...widget.survey.questions.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final q = entry.value;
                      return _buildQuestionAnalyticsCard(idx, q, lang);
                    }),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordResponseModal,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
        label: Text(
          AppTranslations.pick(
            lang,
            en: 'Record Citizen Response',
            mr: 'नागरिक प्रतिसाद नोंदवा',
            hi: 'नागरिक प्रतिक्रिया दर्ज करें',
          ),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSurveyHeaderCard(String dateFormatted, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.survey.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.survey.isActive ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.survey.isActive ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
                      size: 13,
                      color: widget.survey.isActive ? const Color(0xFF15803D) : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.survey.isActive
                          ? AppTranslations.pick(
                              lang,
                              en: 'Active Survey',
                              mr: 'सक्रिय सर्व्हेक्षण',
                              hi: 'सक्रिय सर्वेक्षण',
                            )
                          : AppTranslations.pick(lang, en: 'Closed', mr: 'बंद', hi: 'बंद'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.survey.isActive ? const Color(0xFF15803D) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.survey.area != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AppTranslatedText(
                      AppTranslations.getAreaName(widget.survey.area!, lang),
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppTranslatedText(
            widget.survey.title,
            targetLanguage: lang,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          AppTranslatedText(
            widget.survey.description,
            targetLanguage: lang,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Started: $dateFormatted',
                  mr: 'सुरुवात: $dateFormatted',
                  hi: 'प्रारंभ: $dateFormatted',
                ),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Ward 12 (Kasba-Vishrambaug)',
                  mr: 'प्रभाग १२ (कसबा-विश्रामबाग)',
                  hi: 'वार्ड १२ (कसबा-विश्रामबाग)',
                ),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressKpiCards(int totalResponses, int target, int completionRate, String lang) {
    final respStr = AppTranslations.formatDigits(totalResponses, lang);
    final targetStr = AppTranslations.formatDigits(target, lang);
    final rateStr = AppTranslations.formatDigits(completionRate, lang);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Recorded Responses',
                          mr: 'नोंदवलेले प्रतिसाद',
                          hi: 'दर्ज प्रतिक्रियाएं',
                        ),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.how_to_reg_rounded, size: 18, color: Color(0xFF2563EB)),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    respStr,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Sample Target: out of $targetStr',
                    mr: 'नमुना उद्दिष्ट: $targetStr पैकी',
                    hi: 'नमूना लक्ष्य: $targetStr में से',
                  ),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF60A5FA), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Sample Completion',
                          mr: 'नमुना पूर्णता',
                          hi: 'नमूना पूर्णता',
                        ),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.pie_chart_rounded, size: 18, color: Color(0xFF16A34A)),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$rateStr%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF14532D)),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (completionRate / 100).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFDCFCE7),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionAnalyticsCard(int index, SurveyQuestionModel q, String lang) {
    final idxStr = AppTranslations.formatDigits(index, lang);
    final typeLabel = switch (q.type) {
      SurveyQuestionType.yesNo => AppTranslations.pick(lang, en: 'YES / NO', mr: 'होय / नाही', hi: 'हाँ / नहीं'),
      SurveyQuestionType.mcq => AppTranslations.pick(lang, en: 'MCQ', mr: 'बहुपर्यायी', hi: 'बहुविकल्पीय'),
      SurveyQuestionType.rating => AppTranslations.pick(lang, en: 'RATING', mr: 'रेटिंग', hi: 'रेटिंग'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppTranslations.pick(lang, en: 'Q.$idxStr', mr: 'प्र.$idxStr', hi: 'प्र.$idxStr'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTranslatedText(
                      q.text,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Type: $typeLabel',
                        mr: 'प्रकार: $typeLabel',
                        hi: 'प्रकार: $typeLabel',
                      ),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Response Visualization based on Type
          if (q.type == SurveyQuestionType.yesNo)
            _buildYesNoBreakdown(q.id, lang)
          else if (q.type == SurveyQuestionType.mcq)
            _buildMcqBreakdown(q, lang)
          else if (q.type == SurveyQuestionType.rating)
            _buildRatingBreakdown(q.id, lang),
        ],
      ),
    );
  }

  Widget _buildYesNoBreakdown(String qId, String lang) {
    int yesCount = 0;
    int noCount = 0;
    for (final r in _responses) {
      final ans = r.answers[qId]?.toString().toLowerCase();
      if (ans == 'yes') yesCount++;
      if (ans == 'no') noCount++;
    }

    final total = yesCount + noCount;
    final yesPerc = total > 0 ? ((yesCount / total) * 100).round() : 0;
    final noPerc = total > 0 ? (100 - yesPerc) : 0;
    final yesCountStr = AppTranslations.formatDigits(yesCount, lang);
    final yesPercStr = AppTranslations.formatDigits(yesPerc, lang);
    final noCountStr = AppTranslations.formatDigits(noCount, lang);
    final noPercStr = AppTranslations.formatDigits(noPerc, lang);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thumb_up_alt_rounded, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Yes: $yesCountStr votes ($yesPercStr%)',
                        mr: 'होय: $yesCountStr मते ($yesPercStr%)',
                        hi: 'हाँ: $yesCountStr वोट ($yesPercStr%)',
                      ),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thumb_down_alt_rounded, size: 14, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'No: $noCountStr votes ($noPercStr%)',
                        mr: 'नाही: $noCountStr मते ($noPercStr%)',
                        hi: 'नहीं: $noCountStr वोट ($noPercStr%)',
                      ),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: yesPerc > 0 ? yesPerc : 1,
                child: Container(height: 8, color: const Color(0xFF16A34A)),
              ),
              Expanded(
                flex: noPerc > 0 ? noPerc : 1,
                child: Container(height: 8, color: const Color(0xFFDC2626)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMcqBreakdown(SurveyQuestionModel q, String lang) {
    final Map<String, int> counts = {};
    for (final opt in q.options) {
      counts[opt] = 0;
    }

    int totalAnswered = 0;
    for (final r in _responses) {
      final ans = r.answers[q.id]?.toString();
      if (ans != null && counts.containsKey(ans)) {
        counts[ans] = (counts[ans] ?? 0) + 1;
        totalAnswered++;
      }
    }

    return Column(
      children: q.options.map((opt) {
        final count = counts[opt] ?? 0;
        final perc = totalAnswered > 0 ? ((count / totalAnswered) * 100).round() : 0;
        final cStr = AppTranslations.formatDigits(count, lang);
        final pStr = AppTranslations.formatDigits(perc, lang);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppTranslatedText(
                      opt,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: '$cStr votes ($pStr%)',
                      mr: '$cStr मते ($pStr%)',
                      hi: '$cStr वोट ($pStr%)',
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (perc / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingBreakdown(String qId, String lang) {
    final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    int sum = 0;
    int total = 0;

    for (final r in _responses) {
      final val = int.tryParse(r.answers[qId]?.toString() ?? '');
      if (val != null && val >= 1 && val <= 5) {
        dist[val] = (dist[val] ?? 0) + 1;
        sum += val;
        total++;
      }
    }

    final avg = total > 0 ? (sum / total).toStringAsFixed(1) : '0.0';
    final avgStr = AppTranslations.formatDigits(avg, lang);
    final totalStr = AppTranslations.formatDigits(total, lang);

    return Row(
      children: [
        // Average Rating Circle
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(avgStr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 22, color: Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                AppTranslations.pick(
                  lang,
                  en: '$totalStr votes',
                  mr: '$totalStr मते',
                  hi: '$totalStr वोट',
                ),
                style: const TextStyle(fontSize: 10, color: Color(0xFF92400E)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Distribution Bars
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((stars) {
              final count = dist[stars] ?? 0;
              final perc = total > 0 ? (count / total) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${AppTranslations.formatDigits(stars, lang)} ★',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: perc.clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.formatDigits(count, lang),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _openRecordResponseModal() {
    final lang = ref.read(appLanguageProvider);
    final Map<String, dynamic> localAnswers = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. FIXED HEADER
              AppModalHeader(
                icon: Icons.rate_review_rounded,
                title: AppTranslations.pick(
                  lang,
                  en: 'Record Citizen Response',
                  mr: 'नागरिक प्रतिसाद नोंदवा',
                  hi: 'नागरिक प्रतिक्रिया दर्ज करें',
                ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Record ground feedback directly',
                  mr: 'स्थानिक नागरिकांचे थेट मत नोंदवा',
                  hi: 'स्थानीय नागरिकों की सीधी प्रतिक्रिया दर्ज करें',
                ),
                onClose: () => Navigator.pop(ctx),
              ),

              // 2. SCROLLABLE FORM & SUBMIT BUTTON
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  children: [
                    ...widget.survey.questions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final q = entry.value;
                      final qNum = AppTranslations.formatDigits(i + 1, lang);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.pick(lang, en: 'Q.$qNum. ', mr: 'प्र.$qNum. ', hi: 'प्र.$qNum. '),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                Expanded(
                                  child: AppTranslatedText(
                                    q.text,
                                    targetLanguage: lang,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (q.type == SurveyQuestionType.yesNo)
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: Text(AppTranslations.pick(lang, en: 'Yes', mr: 'होय', hi: 'हाँ')),
                                    selected: localAnswers[q.id] == 'Yes',
                                    selectedColor: const Color(0xFF0284C7),
                                    labelStyle: TextStyle(
                                      color: localAnswers[q.id] == 'Yes' ? Colors.white : const Color(0xFF334155),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (sel) {
                                      if (sel) setModalState(() => localAnswers[q.id] = 'Yes');
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text(AppTranslations.pick(lang, en: 'No', mr: 'नाही', hi: 'नहीं')),
                                    selected: localAnswers[q.id] == 'No',
                                    selectedColor: const Color(0xFFDC2626),
                                    labelStyle: TextStyle(
                                      color: localAnswers[q.id] == 'No' ? Colors.white : const Color(0xFF334155),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (sel) {
                                      if (sel) setModalState(() => localAnswers[q.id] = 'No');
                                    },
                                  ),
                                ],
                              )
                            else if (q.type == SurveyQuestionType.mcq)
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: q.options.map((opt) {
                                  final isSel = localAnswers[q.id] == opt;
                                  return ChoiceChip(
                                    label: AppTranslatedText(opt, targetLanguage: lang),
                                    selected: isSel,
                                    selectedColor: const Color(0xFF0284C7),
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.white : const Color(0xFF334155),
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (sel) {
                                      if (sel) setModalState(() => localAnswers[q.id] = opt);
                                    },
                                  );
                                }).toList(),
                              )
                            else if (q.type == SurveyQuestionType.rating)
                              Row(
                                children: [1, 2, 3, 4, 5].map((stars) {
                                  final isSel = (localAnswers[q.id] ?? 0) >= stars;
                                  return IconButton(
                                    icon: Icon(
                                      isSel ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: isSel ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      setModalState(() => localAnswers[q.id] = stars);
                                    },
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // Action / Submit button inside scroll view
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final newResponse = SurveyResponseModel(
                            id: 'resp-user-${DateTime.now().millisecondsSinceEpoch}',
                            surveyId: widget.survey.id,
                            answers: localAnswers,
                            submittedAt: DateTime.now(),
                          );

                          final repo = ref.read(surveysRepoProvider);
                          Navigator.pop(ctx);
                          await repo.submitResponse(newResponse);
                          await _loadResponses();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Citizen response recorded successfully!',
                                    mr: 'नागरिक प्रतिसाद यशस्वीरित्या नोंदवला गेला!',
                                    hi: 'नागरिक प्रतिक्रिया सफलतापूर्वक दर्ज की गई!',
                                  ),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Save Response',
                            mr: 'प्रतिसाद जतन करा',
                            hi: 'प्रतिक्रिया सहेजें',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
}

