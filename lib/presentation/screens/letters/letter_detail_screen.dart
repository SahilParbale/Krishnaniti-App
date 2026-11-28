import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../../data/models/letter_model.dart';
import '../dashboard/dashboard_screen.dart';
import 'letter_form_constants.dart';
import 'letter_report_generator.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_pdf_report_theme.dart';

class LetterDetailScreen extends ConsumerStatefulWidget {
  final LetterModel letter;

  const LetterDetailScreen({
    super.key,
    required this.letter,
  });

  @override
  ConsumerState<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends ConsumerState<LetterDetailScreen> {
  late LetterModel _letter;
  String _previewLang = 'mr'; // 'mr', 'hi', or 'en'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _letter = widget.letter;
    _previewLang = ref.read(appLanguageProvider);
  }

  Future<void> _refreshFromBackend() async {
    try {
      final repo = ref.read(lettersRepoProvider);
      final fresh = await repo.getLetterById(_letter.id, isIncoming: _letter.isIncoming);
      if (fresh != null && mounted) {
        setState(() => _letter = fresh);
      }
    } catch (_) {}
  }

  // Update Status (Approve / Reject)
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    final previousStatus = _letter.status;

    setState(() {
      _letter = _letter.copyWith(status: newStatus);
    });

    try {
      await ref.read(lettersRepoProvider).updateLetterStatus(_letter.id, newStatus);
    } catch (_) {
      // Revert if error
      if (mounted) setState(() => _letter = _letter.copyWith(status: previousStatus));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (mounted) {
      final lang = ref.read(appLanguageProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Approved'
                ? (lang == 'mr'
                    ? 'पत्र यशस्वीरित्या मंजूर केले!'
                    : (lang == 'hi' ? 'पत्र सफलतापूर्वक स्वीकृत किया गया!' : 'Letter approved successfully!'))
                : (lang == 'mr'
                    ? 'पत्र नाकारले!'
                    : (lang == 'hi' ? 'पत्र अस्वीकृत कर दिया गया!' : 'Letter request rejected!')),
          ),
          backgroundColor: newStatus == 'Approved' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Delete Letter
  void _openDeleteDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Delete Letter?',
                  mr: 'पत्र हटवायचे का?',
                  hi: 'पत्र हटाएँ?',
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'This action cannot be undone. This letter record will be permanently removed.',
            mr: 'ही कृती पूर्ववत करता येणार नाही. या पत्राची नोंद कायमची हटवली जाईल.',
            hi: 'यह कार्रवाई पूर्ववत नहीं की जा सकती। यह पत्र रिकॉर्ड स्थायी रूप से हटा दिया जाएगा।',
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(lettersRepoProvider).deleteLetter(_letter.id, isIncoming: _letter.isIncoming);
              } catch (_) {}
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ')),
          ),
        ],
      ),
    );
  }

  // WhatsApp Share
  void _shareOnWhatsApp() async {
    final lang = ref.read(appLanguageProvider);
    final rawType = _letter.letterType ??
        AppTranslations.pick(lang, en: 'Official Letter', mr: 'अधिकृत पत्र', hi: 'आधिकारिक पत्र');
    final translatedList = await Future.wait([
      DynamicTranslationService.translateOrRaw(_letter.title, lang),
      DynamicTranslationService.translateOrRaw(rawType, lang),
      DynamicTranslationService.translateOrRaw(_letter.citizenName, lang, isName: true),
    ]);
    final header = AppTranslations.pick(
      lang,
      en: 'Official Correspondence',
      mr: 'अधिकृत पत्रव्यवहार',
      hi: 'आधिकारिक पत्राचार',
    );
    final typeLabel = AppTranslations.pick(lang, en: 'Type', mr: 'प्रकार', hi: 'प्रकार');
    final statusLabel = AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति');
    final citizenLabel = AppTranslations.pick(lang, en: 'Citizen', mr: 'नागरिक', hi: 'नागरिक');
    final officeLabel = AppTranslations.formatDigits(
      AppTranslations.pick(
        lang,
        en: 'Nagarsevak Office, Ward 12',
        mr: 'नगरसेवक कार्यालय, प्रभाग 12',
        hi: 'नगरसेवक कार्यालय, वार्ड 12',
      ),
      lang,
    );
    final text = Uri.encodeComponent(
      '$header: ${translatedList[0]}\n'
      '$typeLabel: ${translatedList[1]}\n'
      '$statusLabel: ${AppTranslations.getStatus(_letter.status, lang)}\n'
      '$citizenLabel: ${translatedList[2]}\n'
      '$officeLabel',
    );
    final cleanMobile = _letter.mobile.replaceAll(RegExp(r'\D'), '');
    final uri = cleanMobile.isNotEmpty
        ? Uri.parse('https://wa.me/91$cleanMobile?text=$text')
        : Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Fullscreen Lightbox for scanned images
  Future<void> _openLightbox(String rawUrl, String title) async {
    final url = await SupabaseService.instance.getSignedStorageUrl(rawUrl, bucket: 'documents');
    if (!mounted) return;
    final lang = ref.read(appLanguageProvider);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: const CircleBorder(),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppTranslatedText(
                  title,
                  targetLanguage: lang,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate and Print / Download Official Letter PDF
  Future<void> _generateAndPrintPDF([String? lang]) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final doc = await WebReportTheme.createDocument(lang: activeLang);

    final rawPurpose = _letter.purpose.isNotEmpty ? _letter.purpose : _letter.subject;
    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        if (_letter.address.isNotEmpty) _letter.address,
        rawPurpose,
        _letter.letterType,
        _letter.subject,
      ], activeLang),
      PdfTranslationHelper.batchNames([_letter.citizenName], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final name = PdfTranslationHelper.resolveName(
      nameCache,
      _letter.citizenName,
      activeLang,
      fallback: AppTranslations.pick(activeLang, en: 'Citizen', mr: 'नागरिक', hi: 'नागरिक'),
    );
    final String address;
    if (_letter.address.trim().isNotEmpty) {
      final cleanAddr = _letter.address.trim();
      final domainAddr = AppTranslations.getAreaName(cleanAddr, activeLang);
      final plainDigits = AppTranslations.formatDigits(cleanAddr, activeLang);
      address = (domainAddr != cleanAddr && domainAddr != plainDigits)
          ? domainAddr
          : PdfTranslationHelper.resolve(textCache, cleanAddr, activeLang);
    } else {
      address = AppTranslations.pick(
        activeLang,
        en: 'Ward 12, Pune',
        mr: 'प्रभाग १२, पुणे',
        hi: 'वार्ड १२, पुणे',
      );
    }
    final purpose = PdfTranslationHelper.resolve(textCache, rawPurpose, activeLang, fallback: '-');
    final letterHeading = (_letter.letterType != null && _letter.letterType!.trim().isNotEmpty)
        ? PdfTranslationHelper.resolve(textCache, _letter.letterType, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'OFFICIAL RECOMMENDATION LETTER',
            mr: 'अधिकृत शिफारस पत्र',
            hi: 'आधिकारिक अनुशंसा पत्र',
          );

    final dateStr = PdfTranslationHelper.formatDate(
      _letter.createdAt,
      activeLang,
      pattern: 'dd/MM/yyyy',
    );
    final rawRefNo = 'OUT/${_letter.createdAt.year}/${_letter.id.replaceAll(RegExp(r'\D'), '').padLeft(4, '0')}';
    final refNo = PdfTranslationHelper.formatNumber(rawRefNo, activeLang);

    final officeHeading = AppTranslations.pick(
      activeLang,
      en: 'OFFICE OF NAGARSEVAK',
      mr: 'नगरसेवक कार्यालय - प्रभाग १२',
      hi: 'नगरसेवक कार्यालय - वार्ड १२',
    );
    final officeSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Ward 12 • Municipal Corporation Office, Pune',
      mr: 'पुणे महानगरपालिका • प्रभाग क्र. १२ (शिवाजीनगर - मॉडेल कॉलनी)',
      hi: 'पुणे नगर निगम • वार्ड क्र. १२ (शिवाजीनगर - मॉडल कॉलोनी)',
    );
    final phoneText = AppTranslations.pick(
      activeLang,
      en: 'Phone: +91 98220 12345',
      mr: 'दूरध्वनी: +९१ ९८२२० १२३४५',
      hi: 'फ़ोन: +९१ ९८२२० १२३४५',
    );
    final emailLabel = AppTranslations.pick(
      activeLang,
      en: 'Email:',
      mr: 'ईमेल:',
      hi: 'ईमेल:',
    );
    final refLabel = AppTranslations.pick(
      activeLang,
      en: 'Ref No:',
      mr: 'संदर्भ क्र.:',
      hi: 'संदर्भ सं.:',
    );
    final dateLabel = AppTranslations.pick(
      activeLang,
      en: 'Date:',
      mr: 'दिनांक:',
      hi: 'दिनांक:',
    );
    final salutation = AppTranslations.pick(
      activeLang,
      en: 'TO WHOMSOEVER IT MAY CONCERN,',
      mr: 'ज्यास हे सादर केले जाईल त्यास,',
      hi: 'संबंधित अधिकारी महोदय / सर्वसंबंधित को,',
    );
    final bodyParagraph = AppTranslations.pick(
      activeLang,
      en: 'This is to certify that Mr./Ms. $name, residing at $address, is a bonafide resident of Ward 12, Pune.\n\n'
          'This official letter is issued upon their formal request for the purpose of $purpose. '
          'Their identity and residence credentials have been verified by our ward administrative desk.\n\n'
          'I wish them all success in their future endeavors.',
      mr: 'प्रमाणित करण्यात येते की, श्री/श्रीमती $name, रा. $address, हे प्रभाग क्र. १२ मधील रहिवासी आहेत.\n\n'
          'सदर पत्र त्यांच्या विनंतीनुसार $purpose या कारणास्तव शिफारस पत्र म्हणून देण्यात येत आहे. '
          'नागरिकांची माहिती पडताळणी करण्यात आली असून ते पात्र आहेत.\n\n'
          'त्यांच्या भावी वाटचालीस मनःपूर्वक शुभेच्छा.',
      hi: 'प्रमाणित किया जाता है कि श्री/श्रीमती $name, निवासी $address, वार्ड क्र. १२, पुणे के वास्तविक निवासी हैं।\n\n'
          'यह आधिकारिक पत्र उनके औपचारिक अनुरोध पर $purpose के उद्देश्य से अनुशंसा पत्र के रूप में जारी किया जा रहा है। '
          'उनकी पहचान और निवास विवरण की पुष्टि हमारे वार्ड प्रशासनिक कार्यालय द्वारा की जा चुकी है।\n\n'
          'हम उनके उज्ज्वल भविष्य की शुभकामनाएँ देते हैं।',
    );
    final sealLabel = AppTranslations.pick(
      activeLang,
      en: '[OFFICIAL\nSEAL]',
      mr: '[अधिकृत\nशिक्का]',
      hi: '[आधिकारिक\nमुहर]',
    );
    final stampLabel = AppTranslations.pick(
      activeLang,
      en: 'Prabhag 12 Office Stamp',
      mr: 'प्रभाग १२ कार्यालय शिक्का',
      hi: 'प्रभाग १२ कार्यालय मुहर',
    );
    final signatoryTitle = AppTranslations.pick(
      activeLang,
      en: 'Nagarsevak',
      mr: 'नगरसेवक / नगरसेविका',
      hi: 'नगरसेवक / नगरसेविका',
    );
    final signatoryOrg = AppTranslations.pick(
      activeLang,
      en: 'Ward 12, Pune Municipal Corp.',
      mr: 'प्रभाग १२, पुणे महानगरपालिका',
      hi: 'वार्ड १२, पुणे नगर निगम',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Letterhead Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 14),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.blue900, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            officeHeading,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            officeSubtitle,
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          phoneText,
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          '$emailLabel nagarsevak.ward12@pune.gov.in',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Ref No & Date Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$refLabel $refNo', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('$dateLabel $dateStr', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),

              pw.SizedBox(height: 24),

              // Subject / Title
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    letterHeading,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 24),

              // Salutation
              pw.Text(
                salutation,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),

              pw.SizedBox(height: 14),

              // Body Paragraph
              pw.Text(
                bodyParagraph,
                style: const pw.TextStyle(
                  fontSize: 11,
                  lineSpacing: 2,
                  color: PdfColors.grey900,
                ),
              ),

              pw.Spacer(),

              // Signoff
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(35),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            sealLabel,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(stampLabel, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.grey800),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        signatoryTitle,
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        signatoryOrg,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Letter_${_letter.id}_$activeLang.pdf',
    );
  }

  // Color generator for Letter Overview Card matching web version clsx
  Color get _cardBgColor {
    if (_letter.isIncoming) return const Color(0xFFF0F9FF); // bg-blue-50
    final s = _letter.status.toLowerCase();
    if (s == 'approved') return const Color(0xFFF0FDF4); // bg-green-50
    if (s == 'rejected') return const Color(0xFFFEF2F2); // bg-red-50
    if (s == 'pending') return const Color(0xFFFEFCE8); // bg-yellow-50
    return Colors.white;
  }

  Color get _cardBorderColor {
    if (_letter.isIncoming) return const Color(0xFFBAE6FD); // border-blue-200
    final s = _letter.status.toLowerCase();
    if (s == 'approved') return const Color(0xFF86EFAC); // border-green-300
    if (s == 'rejected') return const Color(0xFFFCA5A5); // border-red-300
    if (s == 'pending') return const Color(0xFFFDE047); // border-yellow-300
    return const Color(0xFFE2E8F0);
  }

  // Formatted Letter Content for On-Screen Preview
  String _buildLetterPreviewText({
    required String targetLang,
    String? nameOverride,
    String? addressOverride,
    String? purposeOverride,
  }) {
    final name = nameOverride ?? _letter.citizenName;
    final defaultAddr = AppTranslations.formatDigits(
      AppTranslations.pick(targetLang, en: 'Ward 12, Pune', mr: 'प्रभाग 12, पुणे', hi: 'वार्ड 12, पुणे'),
      targetLang,
    );
    final address = (addressOverride ?? _letter.address).isNotEmpty
        ? (addressOverride ?? _letter.address)
        : defaultAddr;
    final purpose = (purposeOverride ?? _letter.purpose).isNotEmpty
        ? (purposeOverride ?? _letter.purpose)
        : _letter.subject;

    if (targetLang == 'mr') {
      return 'ज्यास हे सादर केले जाईल त्यास,\n\n'
          'प्रमाणित करण्यात येते की, श्री/श्रीमती $name,\n'
          'रा. $address, हे प्रभाग क्र. १२ मधील रहिवासी आहेत.\n\n'
          'सदर पत्र त्यांच्या विनंतीनुसार $purpose या कारणास्तव शिफारस पत्र म्हणून देण्यात येत आहे.\n'
          'त्यांच्या भावी वाटचालीस मनःपूर्वक शुभेच्छा.\n\n'
          'आपला नम्र,\n'
          'नगरसेवक कार्यालय (प्रभाग १२)';
    }
    if (targetLang == 'hi') {
      return 'संबंधित अधिकारी महोदय,\n\n'
          'प्रमाणित किया जाता है कि श्री/श्रीमती $name,\n'
          'निवासी $address, मेरी जानकारी के अनुसार वार्ड क्र. १२ के निवासी हैं।\n\n'
          'यह पत्र उनके अनुरोध पर "$purpose" के उद्देश्य से सिफारिश पत्र के रूप में जारी किया जा रहा है।\n'
          'उनके उज्ज्वल भविष्य के लिए हार्दिक शुभकामनाएँ।\n\n'
          'भवदीय,\n'
          'नगरसेवक कार्यालय (वार्ड १२)';
    }
    return 'To Whom It May Concern,\n\n'
        'This is to certify that Mr./Ms. $name,\n'
        'residing at $address, is a resident of Ward 12 to the best of my knowledge.\n\n'
        'This letter is issued upon their request for the purpose of $purpose.\n'
        'I wish them all the best for their future endeavors.\n\n'
        'Sincerely,\n'
        'Office of Nagarsevak (Ward 12)';
  }

  Future<List<String>> _resolvePreviewFields(String targetLang) {
    final defaultAddr = AppTranslations.formatDigits(
      AppTranslations.pick(targetLang, en: 'Ward 12, Pune', mr: 'प्रभाग 12, पुणे', hi: 'वार्ड 12, पुणे'),
      targetLang,
    );
    final rawAddr = _letter.address.isNotEmpty ? _letter.address : defaultAddr;
    final rawPurpose = _letter.purpose.isNotEmpty ? _letter.purpose : _letter.subject;
    return Future.wait([
      DynamicTranslationService.translateOrRaw(_letter.citizenName, targetLang, isName: true),
      DynamicTranslationService.translateOrRaw(rawAddr, targetLang),
      DynamicTranslationService.translateOrRaw(rawPurpose, targetLang),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF8FAFC),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Enhanced Top Header Bar with Back & Delete (matching LetterDashboard.tsx)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button with circular icon
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF475569)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Back to Letters',
                                mr: 'पत्रांकडे परत जा',
                                hi: 'पत्रों पर वापस जाएँ',
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top Actions: PDF Export, WhatsApp & Delete
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppPdfButton.icon(
                          tooltip: AppTranslations.getDownloadReport(lang),
                          onPressed: () async {
                            final resolved = await _resolvePreviewFields(lang);
                            final localizedBody = _buildLetterPreviewText(
                              targetLang: lang,
                              nameOverride: resolved[0],
                              addressOverride: resolved[1],
                              purposeOverride: resolved[2],
                            );
                            await LetterReportGenerator.generateAndPrintSingleLetter(
                              letter: _letter,
                              letterBody: localizedBody,
                              lang: lang,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _shareOnWhatsApp,
                          icon: const Icon(Icons.share_outlined, size: 18, color: Color(0xFF0284C7)),
                          tooltip: AppTranslations.pick(
                            lang,
                            en: 'Share via WhatsApp',
                            mr: 'व्हॉट्सॲपवर शेअर करा',
                            hi: 'व्हाट्सऐप पर साझा करें',
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _openDeleteDialog,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                          tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ'),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF2F2),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshFromBackend,
                  color: const Color(0xFF0284C7),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top Letter Overview Card (Dynamic status styling matching LetterDashboard.tsx)
                      _buildLetterOverviewCard(lang),

                      const SizedBox(height: 16),

                      // 2. Main Content Area: Outgoing Preview vs Incoming Document Viewer
                      if (!_letter.isIncoming) ...[
                        _buildOutgoingLetterPreviewCard(lang),
                        const SizedBox(height: 16),
                        _buildRequestDetailsCard(lang),
                        const SizedBox(height: 16),
                        _buildApprovalActionBar(lang),
                      ] else ...[
                        _buildIncomingDocumentViewerCard(lang),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Letter Overview Card
  Widget _buildLetterOverviewCard(String lang) {
    final rawType = _letter.letterType ??
        AppTranslations.pick(
          lang,
          en: _letter.isIncoming ? 'Incoming Circular' : 'Official Letter',
          mr: _letter.isIncoming ? 'आवक परिपत्रक' : 'अधिकृत पत्र',
          hi: _letter.isIncoming ? 'आवक परिपत्र' : 'आधिकारिक पत्र',
        );
    final rawArea = _letter.area ??
        AppTranslations.formatDigits(
          AppTranslations.pick(lang, en: 'Ward 12 Prabhag', mr: 'प्रभाग 12', hi: 'वार्ड 12 प्रभाग'),
          lang,
        );
    final mappedArea = AppTranslations.getAreaName(rawArea, lang);

    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _letter.isIncoming ? const Color(0xFFE0F2FE) : const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AppTranslatedText(
                        rawType,
                        targetLanguage: lang,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _letter.isIncoming ? const Color(0xFF0369A1) : const Color(0xFF7E22CE),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(_letter.status, lang),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          AppTranslatedText(
            _letter.title,
            targetLanguage: lang,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          // Citizen Name / Requester
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 5),
              Text(
                '${AppTranslations.pick(lang, en: 'Citizen', mr: 'नागरिक', hi: 'नागरिक')}: ',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: AppTranslatedText(
                  _letter.citizenName,
                  isName: true,
                  targetLanguage: lang,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0x1A000000)),
          const SizedBox(height: 12),

          // Footer Row: Area & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AppTranslatedText(
                        mappedArea,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    AppTranslations.formatDate(_letter.receivedDate ?? _letter.createdAt, lang),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Outgoing Letter Preview Card (Document look with Marathi/Hindi/English toggle & PDF download)
  Widget _buildOutgoingLetterPreviewCard(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Language Switcher & PDF Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppTranslations.pick(lang, en: 'Letter Preview', mr: 'पत्राचा नमुना', hi: 'पत्र पूर्वावलोकन'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),

              // 3-Language toggle pills
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final opt in const [
                      ('mr', 'मराठी'),
                      ('hi', 'हिंदी'),
                      ('en', 'English'),
                    ])
                      InkWell(
                        onTap: () => setState(() => _previewLang = opt.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _previewLang == opt.$1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: _previewLang == opt.$1
                                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))]
                                : null,
                          ),
                          child: Text(
                            opt.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _previewLang == opt.$1 ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // PDF Generation Action Bar (Themed Components)
          Row(
            children: [
              Expanded(
                child: AppPdfButton(
                  label: AppTranslations.pick(lang, en: 'Print MR', mr: 'मराठी PDF', hi: 'मराठी PDF'),
                  style: AppPdfButtonStyle.primary,
                  onPressed: () => _generateAndPrintPDF('mr'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppPdfButton(
                  label: AppTranslations.pick(lang, en: 'Print HI', mr: 'हिंदी PDF', hi: 'हिंदी PDF'),
                  style: AppPdfButtonStyle.outlined,
                  onPressed: () => _generateAndPrintPDF('hi'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppPdfButton(
                  label: AppTranslations.pick(lang, en: 'Print EN', mr: 'इंग्रजी PDF', hi: 'अंग्रेज़ी PDF'),
                  style: AppPdfButtonStyle.outlined,
                  onPressed: () => _generateAndPrintPDF('en'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Document Parchment Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Letterhead Header in preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.formatDigits(
                        AppTranslations.pick(
                          _previewLang,
                          en: 'OFFICE OF NAGARSEVAK',
                          mr: 'नगरसेवक कार्यालय • प्रभाग 12',
                          hi: 'नगरसेवक कार्यालय • वार्ड 12',
                        ),
                        _previewLang,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      AppTranslations.formatDate(_letter.createdAt, _previewLang, pattern: 'dd/MM/yyyy'),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const Divider(height: 16, thickness: 1, color: Color(0xFFCBD5E1)),

                // Letter Body Text (cross-lingually translates citizen name, address & purpose)
                FutureBuilder<List<String>>(
                  future: _resolvePreviewFields(_previewLang),
                  builder: (context, snap) {
                    final body = snap.hasData
                        ? _buildLetterPreviewText(
                            targetLang: _previewLang,
                            nameOverride: snap.data![0],
                            addressOverride: snap.data![1],
                            purposeOverride: snap.data![2],
                          )
                        : _buildLetterPreviewText(targetLang: _previewLang);
                    return Text(
                      body,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 13.5,
                        height: 1.6,
                        color: Color(0xFF1E293B),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Request Details Card
  Widget _buildRequestDetailsCard(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.pick(lang, en: 'Request Details', mr: 'विनंती तपशील', hi: 'अनुरोध विवरण'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 12),

          _buildDetailRow(
            label: AppTranslations.pick(lang, en: 'Citizen Name', mr: 'नागरिकाचे नाव', hi: 'नागरिक का नाम'),
            value: _letter.citizenName,
            lang: lang,
            isName: true,
          ),
          if (_letter.subject.isNotEmpty)
            _buildDetailRow(
              label: AppTranslations.pick(lang, en: 'Subject', mr: 'विषय', hi: 'विषय'),
              value: _letter.subject,
              lang: lang,
            ),
          if (_letter.address.isNotEmpty)
            _buildDetailRow(
              label: AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
              value: _letter.address,
              lang: lang,
            ),
          if (_letter.purpose.isNotEmpty)
            _buildDetailRow(
              label: AppTranslations.pick(lang, en: 'Purpose', mr: 'उद्देश / कारण', hi: 'उद्देश्य / कारण'),
              value: _letter.purpose,
              lang: lang,
            ),
          if (_letter.area != null && _letter.area!.isNotEmpty)
            _buildDetailRow(
              label: AppTranslations.pick(lang, en: 'Area', mr: 'क्षेत्र / भाग', hi: 'क्षेत्र / इलाका'),
              value: AppTranslations.getAreaName(_letter.area!, lang),
              lang: lang,
            ),
          if (_letter.mobile.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Text(
                        AppTranslations.formatDigits(_letter.mobile, lang),
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse('tel:${_letter.mobile}');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Dynamic Additional Details (अतिरिक्त माहिती) matching Nagarsevak-Managment
          Builder(
            builder: (context) {
              const standardKeys = {
                'name', 'subject', 'text', 'address', 'purpose', 'mobile',
                'gender', 'voter_id', 'added_by_staff_id', 'attachments', 'title',
                'bearer_name', 'bearer_mobile', 'file_url', 'reason'
              };
              final extraEntries = _letter.details.entries
                  .where((e) => !standardKeys.contains(e.key) && e.value != null && e.value.toString().trim().isNotEmpty)
                  .toList();

              if (extraEntries.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Additional Details',
                      mr: 'अतिरिक्त माहिती',
                      hi: 'अतिरिक्त विवरण',
                    ),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(height: 4),
                  ...extraEntries.map((e) {
                    final meta = kDynamicFieldDefinitions[e.key];
                    final label = meta != null
                        ? meta.getLabel(lang)
                        : AppTranslations.translateDirect(e.key.replaceAll('_', ' '), lang: lang);
                    return _buildDetailRow(
                      label: label,
                      value: e.value.toString(),
                      lang: lang,
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. Approval Action Bar for Outgoing Letters
  Widget _buildApprovalActionBar(String lang) {
    if (_letter.status.toLowerCase() == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _updateStatus('Rejected'),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: Text(
                  AppTranslations.pick(lang, en: 'Reject', mr: 'नाकारा', hi: 'अस्वीकार करें'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _updateStatus('Approved'),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(
                  AppTranslations.pick(lang, en: 'Approve', mr: 'मंजूर करा', hi: 'स्वीकृत करें'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final isApproved = _letter.status.toLowerCase() == 'approved';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isApproved ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isApproved
                  ? AppTranslations.pick(
                      lang,
                      en: 'Letter Request is Approved',
                      mr: 'पत्र मंजूर केले गेले आहे',
                      hi: 'पत्र स्वीकृत किया गया है',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Letter Request is Rejected',
                      mr: 'पत्र नाकारले गेले आहे',
                      hi: 'पत्र अस्वीकृत किया गया है',
                    ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isApproved ? const Color(0xFF166534) : const Color(0xFF991B1B),
              ),
            ),
          ],
        ),
      );
    }
  }

  // 5. Incoming Document Viewer Card
  Widget _buildIncomingDocumentViewerCard(String lang) {
    final hasUrl = _letter.letterUrl != null && _letter.letterUrl!.isNotEmpty;
    final isPdf = _letter.fileType?.contains('pdf') == true ||
        (_letter.letterUrl != null && _letter.letterUrl!.toLowerCase().endsWith('.pdf'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.pick(lang, en: 'Document Preview', mr: 'दस्तऐवज पूर्वावलोकन', hi: 'दस्तावेज़ पूर्वावलोकन'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              if (hasUrl)
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(_letter.letterUrl!);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: Text(
                    AppTranslations.pick(lang, en: 'View Document', mr: 'दस्तऐवज पहा', hi: 'दस्तावेज़ देखें'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),

          if (_letter.description != null && _letter.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: AppTranslatedText(
                _letter.description!,
                targetLanguage: lang,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Document preview container
          if (hasUrl) ...[
            if (isPdf)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, size: 48, color: Color(0xFFDC2626)),
                    const SizedBox(height: 10),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Official PDF Document',
                        mr: 'अधिकृत PDF दस्तऐवज',
                        hi: 'आधिकारिक PDF दस्तावेज़',
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Tap "View Document" above to open or download.',
                        mr: 'उघडण्यासाठी किंवा डाउनलोड करण्यासाठी वरील "दस्तऐवज पहा" वर टॅप करा.',
                        hi: 'खोलने या डाउनलोड करने के लिए ऊपर "दस्तावेज़ देखें" पर टैप करें।',
                      ),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: () => _openLightbox(_letter.letterUrl!, _letter.title),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 340),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FutureBuilder<String>(
                        future: SupabaseService.instance.getSignedStorageUrl(_letter.letterUrl!, bucket: 'documents'),
                        builder: (context, snap) {
                          final resolved = (snap.hasData && snap.data!.isNotEmpty) ? snap.data! : _letter.letterUrl!;
                          return Image.network(
                            resolved,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) => const Padding(
                              padding: EdgeInsets.all(32),
                              child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                AppTranslations.pick(lang, en: 'Zoom', mr: 'झूम', hi: 'ज़ूम'),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'No scanned file attached to this record.',
                    mr: 'या नोंदीसोबत कोणतीही स्कॅन केलेली प्रत जोडलेली नाही.',
                    hi: 'इस रिकॉर्ड के साथ कोई स्कैन की गई फ़ाइल संलग्न नहीं है।',
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required String lang,
    bool isName = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Flexible(
            child: AppTranslatedText(
              value,
              isName: isName,
              targetLanguage: lang,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // Status Badge matching web design colors
  Widget _buildStatusBadge(String status, [String lang = 'en']) {
    Color bg;
    Color border;
    Color text;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF166534);
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFB91C1C);
        break;
      case 'received':
        bg = const Color(0xFFDBEAFE);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF1E40AF);
        break;
      default:
        bg = const Color(0xFFFEFCE8);
        border = const Color(0xFFFDE047);
        text = const Color(0xFF854D0E);
    }

    final label = AppTranslations.getStatus(status, lang);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}
