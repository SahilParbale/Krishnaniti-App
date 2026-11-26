import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/ai_content_model.dart';
import '../../../../data/repositories/ai_content_repository.dart';
import '../../../screens/content_studio/ai_content_report_generator.dart';

class DesktopAiContentView extends ConsumerStatefulWidget {
  const DesktopAiContentView({super.key});

  @override
  ConsumerState<DesktopAiContentView> createState() => _DesktopAiContentViewState();
}

class _DesktopAiContentViewState extends ConsumerState<DesktopAiContentView> {
  final _topicController = TextEditingController();
  final _historySearchController = TextEditingController();

  String _contentType = 'Speech';
  String _tone = 'Enthusiastic';
  String _language = 'Marathi';

  String _generatedContent = '';
  bool _isGenerating = false;
  bool _copied = false;

  final List<Map<String, dynamic>> _history = [
    {
      'title': 'Ward Community Center Inauguration',
      'type': 'Speech',
      'tone': 'Enthusiastic',
      'language': 'Marathi',
      'content': 'Dear citizens, today is an eventful day for Ward 12. Committed to social and civic progress, we are inaugurating the new Community Center featuring a modern library, senior citizen hub, and self-help group facilities. Thank you all for your continuous trust and cooperation!',
      'date': '2026-01-20',
    },
    {
      'title': 'Ward Road Concretization Launch',
      'type': 'Social Media Caption',
      'tone': 'Professional',
      'language': 'Marathi',
      'content': '🚧 #InfrastructureDevelopment | Commenced cement concretization work on the primary arterial road in Ward 12 today. High quality roads and uninterrupted civic mobility remain our top priority! #Ward12 #CivicDevelopment',
      'date': '2026-01-18',
    },
    {
      'title': 'Water Supply Maintenance Notice',
      'type': 'Letter/Notice',
      'tone': 'Formal',
      'language': 'Marathi',
      'content': 'Notice to Ward 12 residents: Due to primary pipeline maintenance, water supply will remain suspended on Thursday. Low pressure supply will resume Friday morning. Please store required water in advance. For emergency tanker assistance, contact the ward office.',
      'date': '2026-01-15',
    },
  ];

  void _generateContent() async {
    if (_topicController.text.trim().isEmpty) return;
    setState(() => _isGenerating = true);

    await Future.delayed(const Duration(milliseconds: 700));

    final topic = _topicController.text.trim();
    String result;

    if (_contentType == 'Speech') {
      result = 'Dear Citizens and Respected Friends,\n\n'
          'It gives me immense pleasure to address all of you today on "$topic". This milestone represents our shared vision for the overall development of our ward.\n\n'
          'Our office is committed to ensuring high-quality amenities and infrastructure for every resident. Your continuous support is our greatest strength.\n\n'
          'Thank you all!';
    } else if (_contentType == 'Social Media Caption') {
      result = '📢 #DevelopmentUpdate | $topic\n\n'
          'Another positive step towards the welfare and progress of Ward 12! Our dedicated efforts for civic excellence continue unabated.\n\n'
          '#Ward12 #CivicExcellence #Development';
    } else if (_contentType == 'Press Release') {
      result = 'PRESS NOTE\n\n'
          'Subject: $topic\n'
          'Venue: Ward Office, Ward 12\n\n'
          'Details were shared by the Ward Office regarding "$topic" today. This project directly addresses community requirements and contractors have been directed to ensure timely execution.\n\n'
          'For further information, please contact the Public Relations desk.';
    } else {
      result = 'OFFICIAL NOTICE / PUBLIC CIRCULAR\n\n'
          'To: All Respected Citizens of Ward 12\n\n'
          'Subject: Regarding $topic\n\n'
          'Please be informed that relevant administrative work under $topic has been initiated. Your cooperation is appreciated.\n\n'
          'Office of the Nagar Sevak • Ward 12';
    }

    setState(() {
      _generatedContent = result;
      _isGenerating = false;
      _copied = false;
      _history.insert(0, {
        'title': topic,
        'type': _contentType,
        'tone': _tone,
        'language': _language,
        'content': result,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedContent));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _loadFromHistory(Map<String, dynamic> item) {
    setState(() {
      _topicController.text = item['title'];
      _contentType = item['type'];
      _tone = item['tone'];
      _language = item['language'];
      _generatedContent = item['content'];
      _copied = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Main Dual-Pane Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Editor Section (65%)
              Expanded(
                flex: 65,
                child: Column(
                  children: [
                    _buildInputCard(),
                    if (_generatedContent.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildOutputCard(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right History Section (35%)
              Expanded(
                flex: 35,
                child: _buildHistoryCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Icon(Icons.auto_awesome, size: 24, color: Color(0xFF0284C7)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'AI Content Studio',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                SizedBox(height: 2),
                Text(
                  'Draft speeches, social media posts, press releases and public notices with AI',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),

        // Download Report matching SalesProposalGenerator / Content Studio
        OutlinedButton.icon(
          onPressed: () {
            final items = _history.map<AiContentHistoryItem>((h) => AiContentHistoryItem(
              id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
              title: h['title'] ?? 'Civic Content',
              contentType: AiContentType.speech,
              tone: AiToneType.formal,
              language: AiLanguageType.marathi,
              generatedContent: h['content'] ?? '',
              createdAt: DateTime.tryParse(h['date'] ?? '') ?? DateTime.now(),
            )).toList();
            AiContentReportGenerator.generateDossier(
              context: context,
              items: items,
              categoryFilter: _contentType,
            );
          },
          icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
          label: const Text('Download Report', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14)),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFF0F9FF),
            side: const BorderSide(color: Color(0xFFBAE6FD)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.edit_note, size: 20, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Generate Content',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Topic Textarea
          const Text('Topic / Event Prompt *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: _topicController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. Inauguration of Community Center & Library in Ward 12, Main Road concretization...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 18),

          // Type & Tone Dropdowns
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Content Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _contentType,
                      items: const [
                        DropdownMenuItem(value: 'Speech', child: Text('Speech')),
                        DropdownMenuItem(value: 'Social Media Caption', child: Text('Social Media Caption')),
                        DropdownMenuItem(value: 'Press Release', child: Text('Press Release')),
                        DropdownMenuItem(value: 'Letter/Notice', child: Text('Letter / Public Notice')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _contentType = val);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tone / Voice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _tone,
                      items: const [
                        DropdownMenuItem(value: 'Enthusiastic', child: Text('Enthusiastic')),
                        DropdownMenuItem(value: 'Formal', child: Text('Formal')),
                        DropdownMenuItem(value: 'Professional', child: Text('Professional')),
                        DropdownMenuItem(value: 'Empathetic', child: Text('Empathetic')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _tone = val);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _language,
                      items: const [
                        DropdownMenuItem(value: 'Marathi', child: Text('Marathi')),
                        DropdownMenuItem(value: 'English', child: Text('English')),
                        DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _language = val);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateContent,
              icon: _isGenerating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate with AI',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: const [BoxShadow(color: Color(0x060284C7), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  const Text('Generated Content', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: Icon(_copied ? Icons.check : Icons.copy, size: 14, color: _copied ? Colors.white : const Color(0xFF0284C7)),
                label: Text(
                  _copied ? 'Copied!' : 'Copy to Clipboard',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _copied ? Colors.white : const Color(0xFF0284C7)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _copied ? const Color(0xFF16A34A) : const Color(0xFFF0F9FF),
                  elevation: 0,
                  side: BorderSide(color: _copied ? const Color(0xFF16A34A) : const Color(0xFFBAE6FD)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Output Text Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SelectableText(
              _generatedContent,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    final search = _historySearchController.text.trim().toLowerCase();
    final items = _history.where((h) => search.isEmpty || h['title'].toString().toLowerCase().contains(search)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.history, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  const Text('Recent Generations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(100)),
                child: Text('${items.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // History Search
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              controller: _historySearchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search history...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List of items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final h = items[index];

              return InkWell(
                onTap: () => _loadFromHistory(h),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(4)),
                            child: Text(h['type'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                          ),
                          Text(h['date'], style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        h['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h['content'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
