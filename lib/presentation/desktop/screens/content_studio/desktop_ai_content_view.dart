import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../data/models/ai_content_model.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/content_studio/ai_content_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

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
  int _historyLimit = 10;

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
      'content': '#InfrastructureDevelopment | Commenced cement concretization work on the primary arterial road in Ward 12 today. High quality roads and uninterrupted civic mobility remain our top priority! #Ward12 #CivicDevelopment',
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

  @override
  void dispose() {
    _topicController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  AiContentType _mapContentType(String raw) {
    switch (raw) {
      case 'Social Media Caption':
        return AiContentType.socialMediaCaption;
      case 'Press Release':
        return AiContentType.pressRelease;
      case 'Letter/Notice':
        return AiContentType.letterNotice;
      case 'Speech':
      default:
        return AiContentType.speech;
    }
  }

  AiToneType _mapTone(String raw) {
    switch (raw) {
      case 'Enthusiastic':
        return AiToneType.enthusiastic;
      case 'Formal':
        return AiToneType.formal;
      case 'Empathetic':
        return AiToneType.emotional;
      case 'Professional':
      default:
        return AiToneType.professional;
    }
  }

  AiLanguageType _mapLanguage(String raw) {
    switch (raw) {
      case 'English':
        return AiLanguageType.english;
      case 'Hindi':
        return AiLanguageType.hindi;
      case 'Marathi':
      default:
        return AiLanguageType.marathi;
    }
  }

  String _localizedType(String raw, String lang) {
    return _mapContentType(raw).title(lang);
  }

  String _formatHistoryDate(String raw, String lang) {
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return AppTranslations.formatDate(dt, lang, pattern: 'dd MMM yyyy');
    }
    return AppTranslations.formatDigits(raw, lang);
  }

  void _generateContent() async {
    if (_topicController.text.trim().isEmpty) return;
    setState(() => _isGenerating = true);

    await Future.delayed(const Duration(milliseconds: 700));

    final topic = _topicController.text.trim();
    final outLangCode = _language == 'Marathi' ? 'mr' : (_language == 'Hindi' ? 'hi' : 'en');
    String result;

    if (_contentType == 'Speech') {
      result = AppTranslations.pick(
        outLangCode,
        en: 'Dear Citizens and Respected Friends,\n\n'
            'It gives me immense pleasure to address all of you today on "$topic". This milestone represents our shared vision for the overall development of our ward.\n\n'
            'Our office is committed to ensuring high-quality amenities and infrastructure for every resident. Your continuous support is our greatest strength.\n\n'
            'Thank you all!',
        mr: 'प्रिय नागरिक बंधू आणि भगिनींनो,\n\n'
            'आज "$topic" या विषयावर आपल्या सर्वांशी संवाद साधताना मला अत्यंत आनंद होत आहे. हा टप्पा आपल्या प्रभागाच्या सर्वांगीण विकासाच्या सामायिक ध्येयाचे प्रतीक आहे.\n\n'
            'प्रत्येक नागरिकाला दर्जेदार सुविधा आणि पायाभूत व्यवस्था उपलब्ध करून देण्यासाठी आमचे कार्यालय कटिबद्ध आहे. तुमचा विश्वास आणि सहकार्य हीच आमची खरी ताकद आहे.\n\n'
            'धन्यवाद!',
        hi: 'प्रिय नागरिक भाइयों और बहनों,\n\n'
            'आज "$topic" विषय पर आप सभी को संबोधित करते हुए मुझे अत्यंत प्रसन्नता हो रही है। यह उपलब्धि हमारे वार्ड के समग्र विकास के साझा संकल्प का प्रतीक है।\n\n'
            'हमारा कार्यालय प्रत्येक निवासी को उच्च गुणवत्ता की सुविधाएं और बुनियादी ढांचा प्रदान करने के लिए प्रतिबद्ध है। आपका निरंतर सहयोग हमारी सबसे बड़ी ताकत है।\n\n'
            'धन्यवाद!',
      );
    } else if (_contentType == 'Social Media Caption') {
      result = AppTranslations.pick(
        outLangCode,
        en: '#DevelopmentUpdate | $topic\n\n'
            'Another positive step towards the welfare and progress of Ward 12. Our dedicated efforts for civic excellence continue unabated.\n\n'
            '#Ward12 #CivicExcellence #Development',
        mr: '#विकासपर्व | $topic\n\n'
            'प्रभाग १२ मधील नागरिकांच्या कल्याणासाठी आणि प्रगतीसाठी आणखी एक सकारात्मक पाऊल. दर्जेदार नागरी सुविधांसाठी आमचे प्रयत्न अखंड सुरू आहेत.\n\n'
            '#प्रभाग१२ #नागरीविकास #लोकसेवा',
        hi: '#विकासअपडेट | $topic\n\n'
            'वार्ड १२ के नागरिकों के कल्याण और प्रगति की दिशा में एक और सकारात्मक कदम. उत्कृष्ट नागरिक सुविधाओं के लिए हमारे प्रयास निरंतर जारी हैं।\n\n'
            '#वार्ड१२ #नागरिकविकास #जनसेवा',
      );
    } else if (_contentType == 'Press Release') {
      result = AppTranslations.pick(
        outLangCode,
        en: 'PRESS NOTE\n\n'
            'Subject: $topic\n'
            'Venue: Ward Office, Ward 12\n\n'
            'Details were shared by the Ward Office regarding "$topic" today. This project directly addresses community requirements and contractors have been directed to ensure timely execution.\n\n'
            'For further information, please contact the Public Relations desk.',
        mr: 'प्रसिद्धीपत्रक\n\n'
            'विषय: $topic\n'
            'ठिकाण: प्रभाग कार्यालय, प्रभाग १२\n\n'
            'आज प्रभाग कार्यालयामार्फत "$topic" बाबत सविस्तर माहिती देण्यात आली. हा उपक्रम नागरिकांच्या गरजा पूर्ण करणारा असून काम वेळेत पूर्ण करण्याचे निर्देश देण्यात आले आहेत.\n\n'
            'अधिक माहितीसाठी कृपया जनसंपर्क कक्षाशी संपर्क साधावा.',
        hi: 'प्रेस विज्ञप्ति\n\n'
            'विषय: $topic\n'
            'स्थान: वार्ड कार्यालय, वार्ड १२\n\n'
            'आज वार्ड कार्यालय द्वारा "$topic" के संबंध में विस्तृत जानकारी साझा की गई। यह पहल नागरिकों की आवश्यकताओं को पूरा करती है और समयबद्ध निष्पादन के निर्देश दिए गए हैं।\n\n'
            'अधिक जानकारी के लिए कृपया जनसंपर्क कक्ष से संपर्क करें।',
      );
    } else {
      result = AppTranslations.pick(
        outLangCode,
        en: 'OFFICIAL NOTICE / PUBLIC CIRCULAR\n\n'
            'To: All Respected Citizens of Ward 12\n\n'
            'Subject: Regarding $topic\n\n'
            'Please be informed that relevant administrative work under $topic has been initiated. Your cooperation is appreciated.\n\n'
            'Office of the Nagar Sevak • Ward 12',
        mr: 'जाहीर सूचना / अधिकृत परिपत्रक\n\n'
            'प्रति: प्रभाग १२ मधील सर्व आदरणीय नागरिक\n\n'
            'विषय: $topic बाबत\n\n'
            'सर्व नागरिकांना कळविण्यात येते की $topic अंतर्गत संबंधित प्रशासकीय कामकाज सुरू करण्यात आले आहे. आपल्या सहकार्याची अपेक्षा आहे.\n\n'
            'नगरसेवक कार्यालय • प्रभाग १२',
        hi: 'सार्वजनिक सूचना / आधिकारिक परिपत्र\n\n'
            'प्रति: वार्ड १२ के सभी सम्मानित नागरिक\n\n'
            'विषय: $topic के संबंध में\n\n'
            'सभी नागरिकों को सूचित किया जाता है कि $topic के अंतर्गत संबंधित प्रशासनिक कार्य प्रारंभ कर दिया गया है। आपका सहयोग प्रार्थनीय है।\n\n'
            'नगरसेवक कार्यालय • वार्ड १२',
      );
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
    final lang = ref.watch(desktopLanguageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
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
                    _buildInputCard(lang),
                    if (_generatedContent.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildOutputCard(lang),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right History Section (35%)
              Expanded(
                flex: 35,
                child: _buildHistoryCard(lang),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 26, color: Color(0xFF0369A1)),
                        const SizedBox(width: 10),
                        Text(
                          AppTranslations.getNavTitle('ai_content', lang),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Draft speeches, social media posts, press releases and public notices with AI',
                        mr: 'AI च्या मदतीने भाषणे, सोशल मीडिया पोस्ट आणि पत्रे तयार करा',
                        hi: 'एआई की मदद से भाषण, सोशल मीडिया पोस्ट और पत्र तैयार करें',
                      ),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Download Report matching SalesProposalGenerator / Content Studio
        OutlinedButton.icon(
          onPressed: () {
            final items = _history.asMap().entries.map<AiContentHistoryItem>((entry) {
              final h = entry.value;
              return AiContentHistoryItem(
                id: 'ai-${entry.key}-${h['date'] ?? ''}',
                title: h['title'] ?? 'Civic Content',
                contentType: _mapContentType(h['type']?.toString() ?? 'Speech'),
                tone: _mapTone(h['tone']?.toString() ?? 'Professional'),
                language: _mapLanguage(h['language']?.toString() ?? 'Marathi'),
                generatedContent: h['content'] ?? '',
                createdAt: DateTime.tryParse(h['date'] ?? '') ?? DateTime.now(),
              );
            }).toList();
            AiContentReportGenerator.generateDossier(
              context: context,
              items: items,
              categoryFilter: _contentType,
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
    );
  }

  Widget _buildInputCard(String lang) {
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
            children: [
              const Icon(Icons.edit_note, size: 20, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(
                AppTranslations.pick(lang, en: 'Generate Content', mr: 'कंटेंट तयार करा', hi: 'कंटेंट बनाएं'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Topic Textarea
          Text(
            AppTranslations.pick(lang, en: 'Topic / Event Prompt *', mr: 'विषय / इव्हेंट प्रॉम्ट *', hi: 'विषय / इवेंट प्रॉम्प्ट *'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _topicController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: AppTranslations.pick(
                lang,
                en: 'e.g. Inauguration of Community Center & Library in Ward 12, Main Road concretization...',
                mr: 'उदा. प्रभाग १२ मध्ये समाज मंदिर आणि ग्रंथालय उद्घाटन...',
                hi: 'उदा. वार्ड १२ में सामुदायिक केंद्र एवं पुस्तकालय उद्घाटन...',
              ),
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
                    Text(
                      AppTranslations.pick(lang, en: 'Content Type', mr: 'कंटेंट प्रकार', hi: 'कंटेंट प्रकार'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _contentType,
                      height: 44,
                      backgroundColor: Colors.white,
                      borderColor: const Color(0xFFE2E8F0),
                      items: [
                        DropdownMenuItem(value: 'Speech', child: Text(AppTranslations.pick(lang, en: 'Speech', mr: 'भाषण', hi: 'भाषण'))),
                        DropdownMenuItem(value: 'Social Media Caption', child: Text(AppTranslations.pick(lang, en: 'Social Media Caption', mr: 'सोशल मीडिया पोस्ट', hi: 'सोशल मीडिया पोस्ट'))),
                        DropdownMenuItem(value: 'Press Release', child: Text(AppTranslations.pick(lang, en: 'Press Release', mr: 'प्रेस नोट', hi: 'प्रेस विज्ञप्ति'))),
                        DropdownMenuItem(value: 'Letter/Notice', child: Text(AppTranslations.pick(lang, en: 'Letter / Public Notice', mr: 'पत्र / जाहीर सूचना', hi: 'पत्र / सार्वजनिक सूचना'))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _contentType = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.pick(lang, en: 'Tone / Voice', mr: 'टोन / शैली', hi: 'टोन / शैली'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _tone,
                      height: 44,
                      backgroundColor: Colors.white,
                      borderColor: const Color(0xFFE2E8F0),
                      items: [
                        DropdownMenuItem(value: 'Enthusiastic', child: Text(AppTranslations.pick(lang, en: 'Enthusiastic', mr: 'उत्साही', hi: 'उत्साही'))),
                        DropdownMenuItem(value: 'Formal', child: Text(AppTranslations.pick(lang, en: 'Formal', mr: 'औपचारिक', hi: 'औपचारिक'))),
                        DropdownMenuItem(value: 'Professional', child: Text(AppTranslations.pick(lang, en: 'Professional', mr: 'व्यावसायिक', hi: 'व्यावसायिक'))),
                        DropdownMenuItem(value: 'Empathetic', child: Text(AppTranslations.pick(lang, en: 'Empathetic', mr: 'सहानुभूतीपूर्वक', hi: 'सहानुभूतिपूर्ण'))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _tone = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.pick(lang, en: 'Language', mr: 'भाषा', hi: 'भाषा'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _language,
                      height: 44,
                      backgroundColor: Colors.white,
                      borderColor: const Color(0xFFE2E8F0),
                      items: [
                        DropdownMenuItem(value: 'Marathi', child: Text(AiLanguageType.marathi.labelFor(lang))),
                        DropdownMenuItem(value: 'English', child: Text(AiLanguageType.english.labelFor(lang))),
                        DropdownMenuItem(value: 'Hindi', child: Text(AiLanguageType.hindi.labelFor(lang))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _language = val);
                      },
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
                _isGenerating
                    ? AppTranslations.pick(lang, en: 'Generating...', mr: 'तयार करत आहे...', hi: 'बना रहा है...')
                    : AppTranslations.pick(lang, en: 'Generate with AI', mr: 'AI सह तयार करा', hi: 'AI से बनाएं'),
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

  Widget _buildOutputCard(String lang) {
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
                  Text(
                    AppTranslations.pick(lang, en: 'Generated Content', mr: 'तयार केलेला मजकूर', hi: 'तैयार किया गया कंटेंट'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: Icon(_copied ? Icons.check : Icons.copy, size: 14, color: _copied ? Colors.white : const Color(0xFF0284C7)),
                label: Text(
                  _copied
                      ? AppTranslations.pick(lang, en: 'Copied!', mr: 'कॉपी केले!', hi: 'कॉपी किया गया!')
                      : AppTranslations.pick(lang, en: 'Copy to Clipboard', mr: 'क्लिपबोर्डवर कॉपी करा', hi: 'क्लिपबोर्ड पर कॉपी करें'),
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

  Widget _buildHistoryCard(String lang) {
    final search = AppTranslations.normalizeAsciiDigits(_historySearchController.text.trim()).toLowerCase();
    final items = _history.where((h) {
      if (search.isEmpty) return true;
      return AppTranslations.normalizeAsciiDigits(h['title']).toLowerCase().contains(search) ||
          AppTranslations.normalizeAsciiDigits(h['content']).toLowerCase().contains(search);
    }).toList();
    final visibleItems = items.take(_historyLimit).toList();

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
                children: [
                  const Icon(Icons.history, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.pick(lang, en: 'Recent Generations', mr: 'मागील इतिहास', hi: 'पिछला इतिहास'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(100)),
                child: Text(
                  AppTranslations.formatDigits(items.length, lang),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // History Search
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              controller: _historySearchController,
              onChanged: (_) => setState(() => _historyLimit = 10),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(lang, en: 'Search history...', mr: 'इतिहास शोधा...', hi: 'इतिहास खोजें...'),
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (visibleItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'No matching drafts found',
                    mr: 'जुळणारा मजकूर आढळला नाही',
                    hi: 'कोई मिलता-जुलता ड्राफ्ट नहीं मिला',
                  ),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            // List of items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final h = visibleItems[index];

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
                              child: Text(
                                _localizedType(h['type']?.toString() ?? 'Speech', lang),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ),
                            Text(
                              _formatHistoryDate(h['date']?.toString() ?? '', lang),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AppTranslatedText(
                          h['title']?.toString() ?? '',
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        AppTranslatedText(
                          h['content']?.toString() ?? '',
                          targetLanguage: lang,
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
          if (items.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visibleItems.length,
              totalCount: items.length,
              pageSize: 10,
              label: AppTranslations.pick(lang, en: 'drafts', mr: 'मसुदे', hi: 'ड्राफ्ट'),
              isMarathi: lang == 'mr',
              onLoadMore: () {
                setState(() => _historyLimit += 10);
              },
            ),
        ],
      ),
    );
  }
}
