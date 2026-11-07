import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/survey_model.dart';
import '../../../data/repositories/surveys_repository.dart';

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

  Future<void> _shareOnWhatsApp() async {
    final text = 'Hello, important citizen opinion survey for Ward 12:\n"${widget.survey.title}"\nPlease register your opinion and help us develop the ward.';
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
    final totalResponses = _responses.length;
    final target = widget.survey.targetSampleSize > 0 ? widget.survey.targetSampleSize : 100;
    final completionRate = ((totalResponses / target) * 100).clamp(0, 100).toInt();
    final dateFormatted = DateFormat('dd MMMM yyyy').format(widget.survey.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Survey Analysis & Results',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share on WhatsApp',
            onPressed: _shareOnWhatsApp,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _loadResponses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Meta Card
                  _buildSurveyHeaderCard(dateFormatted),

                  const SizedBox(height: 16),

                  // KPI Response Progress Cards
                  _buildProgressKpiCards(totalResponses, target, completionRate),

                  const SizedBox(height: 20),

                  // Analytics Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Question-wise Citizen Response Analysis',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${widget.survey.questions.length} Questions',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Question Breakdown Cards
                  ...widget.survey.questions.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final q = entry.value;
                    return _buildQuestionAnalyticsCard(idx, q);
                  }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordResponseModal,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
        label: const Text(
          'Record Citizen Response',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSurveyHeaderCard(String dateFormatted) {
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
                      widget.survey.isActive ? 'Active Survey' : 'Closed',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.survey.area!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.survey.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            widget.survey.description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started: $dateFormatted',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              Text(
                'Ward 12 (Kasba-Vishrambaug)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressKpiCards(int totalResponses, int target, int completionRate) {
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recorded Responses', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                    Icon(Icons.how_to_reg_rounded, size: 18, color: Color(0xFF2563EB)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalResponses',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sample Target: out of $target',
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sample Completion', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                    Icon(Icons.pie_chart_rounded, size: 18, color: Color(0xFF16A34A)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$completionRate%',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF14532D)),
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

  Widget _buildQuestionAnalyticsCard(int index, SurveyQuestionModel q) {
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
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Q.$index',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.text,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Type: ${q.type.name.toUpperCase()}',
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
            _buildYesNoBreakdown(q.id)
          else if (q.type == SurveyQuestionType.mcq)
            _buildMcqBreakdown(q)
          else if (q.type == SurveyQuestionType.rating)
            _buildRatingBreakdown(q.id),
        ],
      ),
    );
  }

  Widget _buildYesNoBreakdown(String qId) {
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

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_rounded, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text('Yes: $yesCount votes ($yesPerc%)', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.thumb_down_alt_rounded, size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Text('No: $noCount votes ($noPerc%)', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
              ],
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

  Widget _buildMcqBreakdown(SurveyQuestionModel q) {
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(opt, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  Text('$count votes ($perc%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
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

  Widget _buildRatingBreakdown(String qId) {
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
                  Text(avg, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 22, color: Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 2),
              Text('$total votes', style: const TextStyle(fontSize: 10, color: Color(0xFF92400E))),
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
                    Text('$stars ★', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
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
                    Text('$count', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
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
    final Map<String, dynamic> localAnswers = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Record Citizen Response Directly',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text('Record citizen responses on ground and add to survey', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.survey.questions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (c, i) {
                    final q = widget.survey.questions[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q.${i + 1}. ${q.text}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (q.type == SurveyQuestionType.yesNo)
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Yes'),
                                selected: localAnswers[q.id] == 'Yes',
                                onSelected: (sel) {
                                  if (sel) setModalState(() => localAnswers[q.id] = 'Yes');
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('No'),
                                selected: localAnswers[q.id] == 'No',
                                onSelected: (sel) {
                                  if (sel) setModalState(() => localAnswers[q.id] = 'No');
                                },
                              ),
                            ],
                          )
                        else if (q.type == SurveyQuestionType.mcq)
                          Wrap(
                            spacing: 8,
                            children: q.options.map((opt) {
                              return ChoiceChip(
                                label: Text(opt),
                                selected: localAnswers[q.id] == opt,
                                onSelected: (sel) {
                                  if (sel) setModalState(() => localAnswers[q.id] = opt);
                                },
                              );
                            }).toList(),
                          )
                        else if (q.type == SurveyQuestionType.rating)
                          Row(
                            children: [1, 2, 3, 4, 5].map((stars) {
                              final isSel = localAnswers[q.id] == stars;
                              return IconButton(
                                icon: Icon(isSel ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: isSel ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1), size: 28),
                                onPressed: () {
                                  setModalState(() => localAnswers[q.id] = stars);
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
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
                      const SnackBar(content: Text('Citizen response recorded successfully!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Response', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

