import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/letter_model.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';

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
  String _previewLang = 'mr'; // 'mr' or 'en'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _letter = widget.letter;
    _refreshFromBackend();
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
      final isMr = ref.read(isMarathiProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Approved'
                ? (isMr ? 'पत्र यशस्वीरित्या मंजूर केले!' : 'Letter approved successfully!')
                : (isMr ? 'पत्र नाकारले!' : 'Letter request rejected!'),
          ),
          backgroundColor: newStatus == 'Approved' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Delete Letter
  void _openDeleteDialog() {
    final isMr = ref.read(isMarathiProvider);
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
                isMr ? AppStrings.deleteLetterConfirmTitleMr : AppStrings.deleteLetterConfirmTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          isMr ? AppStrings.deleteLetterConfirmDescMr : AppStrings.deleteLetterConfirmDesc,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? AppStrings.cancelMr : AppStrings.cancel),
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
            child: Text(isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint),
          ),
        ],
      ),
    );
  }

  // WhatsApp Share
  void _shareOnWhatsApp() async {
    final text = Uri.encodeComponent(
      'Official Correspondence: ${_letter.title}\n'
      'Type: ${_letter.letterType ?? 'Official Letter'}\n'
      'Status: ${_letter.status}\n'
      'Citizen: ${_letter.citizenName}\n'
      'Nagarsevak Office, Prabhag 12',
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
  void _openLightbox(String url, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
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
                  errorBuilder: (_, __, ___) => Container(
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
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
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
  Future<void> _generateAndPrintPDF(String lang) async {
    final doc = pw.Document();
    final isMr = lang == 'mr';

    final name = _letter.citizenName;
    final address = _letter.address.isNotEmpty ? _letter.address : 'Ward 12, Pune';
    final purpose = _letter.purpose.isNotEmpty ? _letter.purpose : (_letter.subject);
    final dateStr = DateFormat('dd/MM/yyyy').format(_letter.createdAt);
    final refNo = 'OUT/${_letter.createdAt.year}/${_letter.id.replaceAll(RegExp(r'\D'), '').padLeft(4, '0')}';

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
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isMr ? 'नगरसेवक कार्यालय - प्रभाग १२' : 'OFFICE OF NAGARSEVAK',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          isMr
                              ? 'पुणे महानगरपालिका • प्रभाग क्र. १२ (शिवाजीनगर - मॉडेल कॉलनी)'
                              : 'Ward 12 • Municipal Corporation Office, Pune',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Phone: +91 98220 12345',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'Email: nagarsevak.ward12@pune.gov.in',
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
                  pw.Text('Ref No: $refNo', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
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
                    _letter.letterType ?? 'OFFICIAL RECOMMENDATION LETTER',
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
                isMr ? 'ज्यास हे सादर केले जाईल त्यास,' : 'TO WHOMSOEVER IT MAY CONCERN,',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),

              pw.SizedBox(height: 14),

              // Body Paragraph
              pw.Text(
                isMr
                    ? 'प्रमाणित करण्यात येते की, श्री/श्रीमती $name, रा. $address, हे प्रभाग क्र. १२ मधील रहिवासी आहेत.\n\n'
                        'सदर पत्र त्यांच्या विनंतीनुसार $purpose या कारणास्तव शिफारस पत्र म्हणून देण्यात येत आहे. '
                        'नागरिकांची माहिती पडताळणी करण्यात आली असून ते पात्र आहेत.\n\n'
                        'त्यांच्या भावी वाटचालीस मनःपूर्वक शुभेच्छा.'
                    : 'This is to certify that Mr./Ms. $name, residing at $address, is a bonafide resident of Ward 12, Pune.\n\n'
                        'This official letter is issued upon their formal request for the purpose of $purpose. '
                        'Their identity and residence credentials have been verified by our ward administrative desk.\n\n'
                        'I wish them all success in their future endeavors.',
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
                            '[OFFICIAL\nSEAL]',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Prabhag 12 Office Stamp', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.grey800),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        isMr ? 'नगरसेवक / नगरसेविका' : 'Nagarsevak',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Ward 12, Pune Municipal Corp.',
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
      name: 'Letter_${_letter.id}_$lang.pdf',
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
  String get _letterPreviewText {
    final name = _letter.citizenName;
    final address = _letter.address.isNotEmpty ? _letter.address : 'Ward 12, Pune';
    final purpose = _letter.purpose.isNotEmpty ? _letter.purpose : _letter.subject;

    if (_previewLang == 'mr') {
      return 'ज्यास हे सादर केले जाईल त्यास,\n\n'
          'प्रमाणित करण्यात येते की, श्री/श्रीमती $name,\n'
          'रा. $address, हे प्रभाग क्र. १२ मधील रहिवासी आहेत.\n\n'
          'सदर पत्र त्यांच्या विनंतीनुसार $purpose या कारणास्तव शिफारस पत्र म्हणून देण्यात येत आहे.\n'
          'त्यांच्या भावी वाटचालीस मनःपूर्वक शुभेच्छा.\n\n'
          'आपला नम्र,\n'
          'नगरसेवक कार्यालय (प्रभाग १२)';
    } else {
      return 'To Whom It May Concern,\n\n'
          'This is to certify that Mr./Ms. $name,\n'
          'residing at $address, is a resident of Ward 12 to the best of my knowledge.\n\n'
          'This letter is issued upon their request for the purpose of $purpose.\n'
          'I wish them all the best for their future endeavors.\n\n'
          'Sincerely,\n'
          'Office of Nagarsevak (Ward 12)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);

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
                              isMr ? AppStrings.backToLettersMr : AppStrings.backToLetters,
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

                    // WhatsApp & Delete Action Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _shareOnWhatsApp,
                          icon: const Icon(Icons.share_outlined, size: 18, color: Color(0xFF0284C7)),
                          tooltip: isMr ? AppStrings.shareWhatsAppMr : AppStrings.shareWhatsApp,
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
                          tooltip: isMr ? AppStrings.deleteComplaintMr : AppStrings.deleteComplaint,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top Letter Overview Card (Dynamic status styling matching LetterDashboard.tsx)
                      _buildLetterOverviewCard(isMr),

                      const SizedBox(height: 16),

                      // 2. Main Content Area: Outgoing Preview vs Incoming Document Viewer
                      if (!_letter.isIncoming) ...[
                        _buildOutgoingLetterPreviewCard(isMr),
                        const SizedBox(height: 16),
                        _buildRequestDetailsCard(isMr),
                        const SizedBox(height: 16),
                        _buildApprovalActionBar(isMr),
                      ] else ...[
                        _buildIncomingDocumentViewerCard(isMr),
                      ],

                      const SizedBox(height: 32),
                    ],
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
  Widget _buildLetterOverviewCard(bool isMr) {
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
                      child: Text(
                        _letter.letterType ?? (_letter.isIncoming ? 'Incoming Circular' : 'Official Letter'),
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
              _buildStatusBadge(_letter.status, isMr),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            _letter.title,
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
                '${isMr ? AppStrings.citizenMr : AppStrings.citizen}: ',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              Text(
                _letter.citizenName,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
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
                      child: Text(
                        _letter.area ?? 'Ward 12 Prabhag',
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
                    DateFormat('MMM d, yyyy').format(_letter.receivedDate ?? _letter.createdAt),
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

  // 2. Outgoing Letter Preview Card (Document look with Marathi/English toggle & PDF download)
  Widget _buildOutgoingLetterPreviewCard(bool isMr) {
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
              Text(
                isMr ? AppStrings.letterPreviewMr : AppStrings.letterPreview,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),

              // Language toggle pills
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _previewLang = 'mr'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _previewLang == 'mr' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _previewLang == 'mr'
                              ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Text(
                          'मराठी',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _previewLang == 'mr' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _previewLang = 'en'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _previewLang == 'en' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _previewLang == 'en'
                              ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Text(
                          'English',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _previewLang == 'en' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
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

          // PDF Generation Action Bar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateAndPrintPDF('mr'),
                  icon: const Icon(Icons.print_outlined, size: 15),
                  label: Text(
                    isMr ? AppStrings.printPdfMrMr : AppStrings.printPdfMr,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateAndPrintPDF('en'),
                  icon: const Icon(Icons.print_outlined, size: 15),
                  label: Text(
                    isMr ? AppStrings.printPdfEnMr : AppStrings.printPdfEn,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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
                      _previewLang == 'mr' ? 'नगरसेवक कार्यालय • प्रभाग १२' : 'OFFICE OF NAGARSEVAK',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_letter.createdAt),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const Divider(height: 16, thickness: 1, color: Color(0xFFCBD5E1)),

                // Letter Body Text
                Text(
                  _letterPreviewText,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 13.5,
                    height: 1.6,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Request Details Card
  Widget _buildRequestDetailsCard(bool isMr) {
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
            isMr ? AppStrings.requestDetailsMr : AppStrings.requestDetails,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 12),

          _buildDetailRow(
            label: isMr ? AppStrings.citizenMr : AppStrings.citizen,
            value: _letter.citizenName,
          ),
          if (_letter.subject.isNotEmpty)
            _buildDetailRow(
              label: isMr ? AppStrings.subjectMr : AppStrings.subject,
              value: _letter.subject,
            ),
          if (_letter.address.isNotEmpty)
            _buildDetailRow(
              label: isMr ? AppStrings.addressMr : AppStrings.address,
              value: _letter.address,
            ),
          if (_letter.purpose.isNotEmpty)
            _buildDetailRow(
              label: isMr ? AppStrings.purposeMr : AppStrings.purpose,
              value: _letter.purpose,
            ),
          if (_letter.area != null && _letter.area!.isNotEmpty)
            _buildDetailRow(
              label: isMr ? AppStrings.areaMr : AppStrings.area,
              value: _letter.area!,
            ),
          if (_letter.mobile.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMr ? AppStrings.mobileMr : AppStrings.mobile,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Text(
                        _letter.mobile,
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
        ],
      ),
    );
  }

  // 4. Approval Action Bar for Outgoing Letters
  Widget _buildApprovalActionBar(bool isMr) {
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
                  isMr ? AppStrings.rejectLetterMr : AppStrings.rejectLetter,
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
                  isMr ? AppStrings.approveLetterMr : AppStrings.approveLetter,
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
                  ? (isMr ? 'पत्र मंजूर केले गेले आहे' : 'Letter Request is Approved')
                  : (isMr ? 'पत्र नाकारले गेले आहे' : 'Letter Request is Rejected'),
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
  Widget _buildIncomingDocumentViewerCard(bool isMr) {
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
                isMr ? AppStrings.documentPreviewMr : AppStrings.documentPreview,
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
                    isMr ? AppStrings.viewDocumentMr : AppStrings.viewDocument,
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
              child: Text(
                _letter.description!,
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
                    const Text(
                      'Official PDF Document',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap "View Document" above to open or download.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                      Image.network(
                        _letter.letterUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                        ),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Zoom', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
              child: const Center(
                child: Text(
                  'No scanned file attached to this record.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // Status Badge matching web design colors
  Widget _buildStatusBadge(String status, bool isMr) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF166534);
        label = isMr ? 'मंजूर' : 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFB91C1C);
        label = isMr ? 'नाकारले' : 'Rejected';
        break;
      case 'received':
        bg = const Color(0xFFDBEAFE);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF1E40AF);
        label = isMr ? 'प्राप्त' : 'Received';
        break;
      default:
        bg = const Color(0xFFFEFCE8);
        border = const Color(0xFFFDE047);
        text = const Color(0xFF854D0E);
        label = isMr ? 'प्रलंबित' : 'Pending';
    }

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
