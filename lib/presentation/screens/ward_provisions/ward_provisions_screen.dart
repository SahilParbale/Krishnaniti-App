import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ward_provision_model.dart';
import '../../../data/repositories/ward_provisions_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'ward_provision_report_generator.dart';

/// WardProvisions Screen matching EXACTLY the web page:
/// Nagarsevak-Managment/src/pages/ward/WardProvisions.tsx
class WardProvisionsScreen extends ConsumerStatefulWidget {
  const WardProvisionsScreen({super.key});

  @override
  ConsumerState<WardProvisionsScreen> createState() => _WardProvisionsScreenState();
}

class _WardProvisionsScreenState extends ConsumerState<WardProvisionsScreen> {
  String _year = '2024-2025';
  bool _loading = true;
  List<WardProvisionModel> _provisions = [];
  int _displayedLimit = 20;

  List<WardProvisionModel> get _visibleProvisions =>
      _provisions.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadProvisions();
  }

  Future<void> _loadProvisions() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(wardProvisionsRepoProvider);
      final data = await repo.getProvisions(year: _year);
      if (mounted) {
        setState(() {
          _provisions = data;
          _loading = false;
          _displayedLimit = 20;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _provisions = [];
          _loading = false;
        });
      }
    }
  }

  String _formatCurrency(double? amount, String lang) {
    return AppTranslations.formatCurrency(amount ?? 0, lang);
  }

  String _formatProvDate(String raw, String lang) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) {
      return AppTranslations.formatDate(parsed, lang, pattern: 'dd MMM yyyy');
    }
    return AppTranslations.formatDigits(raw, lang);
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFFF0FDF4);
      case 'Partially Approved':
        return const Color(0xFFEFF6FF);
      case 'Rejected':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFFEFCE8);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF15803D);
      case 'Partially Approved':
        return const Color(0xFF1D4ED8);
      case 'Rejected':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFA16207);
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFFBBF7D0);
      case 'Partially Approved':
        return const Color(0xFFBFDBFE);
      case 'Rejected':
        return const Color(0xFFFECACA);
      default:
        return const Color(0xFFFEF08A);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
      case 'Partially Approved':
        return Icons.check_circle_outline_rounded;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _getStatusText(String status, String lang) =>
      AppTranslations.getStatus(status, lang);

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
          children: isRequired
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  InputDecoration _inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon, String? prefixText}) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }

  // Add Provision Request Modal matching WardProvisions.tsx lines 347-456
  void _openAddModal() {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final reqAmtCtrl = TextEditingController();
    final catCtrl = TextEditingController(
      text: AppTranslations.pick(lang, en: 'Roads & Civil', mr: 'रस्ते व बांधकाम', hi: 'सड़क व निर्माण'),
    );
    final areaCtrl = TextEditingController(
      text: AppTranslations.pick(lang, en: 'Ward 12', mr: 'प्रभाग १२', hi: 'वार्ड १२'),
    );
    final refCtrl = TextEditingController();
    final now = DateTime.now();
    final dateCtrl = TextEditingController(
      text: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    String finYear = _year;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                    icon: Icons.account_balance_wallet_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Add Provision Request',
                      mr: 'नवीन तरतूद मागणी जोडा',
                      hi: 'नया प्रावधान अनुरोध जोड़ें',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Record civic budget provision and funding requests',
                      mr: 'प्रभागातील प्रस्तावित कामांसाठी तरतूद मागणी नोंदवा',
                      hi: 'वार्ड के प्रस्तावित कार्यों के लिए बजट प्रावधान दर्ज करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Title
                        _fieldLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Provision Proposal Title',
                            mr: 'प्रस्तावित कामाचे नाव / शीर्षक',
                            hi: 'प्रस्तावित कार्य का शीर्षक',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: _inputDec(
                            hintText: AppTranslations.pick(
                              lang,
                              en: 'Enter project name / provision title...',
                              mr: 'प्रकल्प / कामाचे नाव प्रविष्ट करा...',
                              hi: 'परियोजना / कार्य का नाम दर्ज करें...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Requested Amount & Date side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Requested Amount (₹)',
                                      mr: 'मागणी केलेली रक्कम (₹)',
                                      hi: 'अपेक्षित राशि (₹)',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: reqAmtCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDec(
                                      prefixText: '₹ ',
                                      hintText: AppTranslations.pick(lang, en: 'e.g. 2500000', mr: 'उदा. २५०००००', hi: 'उदा. २५०००००'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Requested Date',
                                      mr: 'मागणी तारीख',
                                      hi: 'अपेक्षित तिथि',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: dateCtrl,
                                    decoration: _inputDec(
                                      hintText: 'YYYY-MM-DD',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Category & Area side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(lang, en: 'Category', mr: 'श्रेणी / विभाग', hi: 'श्रेणी / विभाग'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: catCtrl,
                                    decoration: _inputDec(
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. Roads, Water, Health',
                                        mr: 'उदा. रस्ते, पाणी, आरोग्य',
                                        hi: 'उदा. सड़क, पानी, स्वास्थ्य',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(lang, en: 'Area / Locality', mr: 'परिसर / प्रभाग भाग', hi: 'क्षेत्र / वार्ड भाग'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: areaCtrl,
                                    decoration: _inputDec(
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'Enter Area / Ward Sector',
                                        mr: 'उदा. शनिवार पेठ',
                                        hi: 'क्षेत्र / सेक्टर दर्ज करें',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Financial Year & Letter Reference side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<String>(
                                label: AppTranslations.pick(lang, en: 'Financial Year', mr: 'आर्थिक वर्ष', hi: 'वित्तीय वर्ष'),
                                value: finYear,
                                    items: [
                                      DropdownMenuItem(value: '2024-2025', child: Text(AppTranslations.pick(lang, en: 'FY 2024-2025', mr: 'आर्थिक वर्ष २०२४-२०२५', hi: 'वित्तीय वर्ष २०२४-२०२५'), style: const TextStyle(fontSize: 13))),
                                      DropdownMenuItem(value: '2023-2024', child: Text(AppTranslations.pick(lang, en: 'FY 2023-2024', mr: 'आर्थिक वर्ष २०२३-२०२४', hi: 'वित्तीय वर्ष २०२३-२०२४'), style: const TextStyle(fontSize: 13))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => finYear = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(lang, en: 'Letter Ref No', mr: 'पत्र संदर्भ क्र.', hi: 'पत्र संदर्भ क्र.'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: refCtrl,
                                    decoration: _inputDec(
                                      hintText: 'e.g. PMC/RDS/1042',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Description
                        _fieldLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Detailed Scope / Justification',
                            mr: 'सविस्तर स्वरूप / औचित्य',
                            hi: 'विस्तृत दायरा / औचित्य',
                          ),
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: _inputDec(
                            hintText: AppTranslations.pick(
                              lang,
                              en: 'Brief details about the civic requirement...',
                              mr: 'नागरी गरजेचा थोडक्यात तपशील...',
                              hi: 'नागरिक आवश्यकता का संक्षिप्त विवरण...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
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
                                en: 'Save Provision Request',
                                mr: 'तरतूद मागणी जतन करा',
                                hi: 'प्रावधान अनुरोध सहेजें',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: () async {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Please enter proposal title',
                                        mr: 'कृपया कामाचे नाव प्रविष्ट करा.',
                                        hi: 'कृपया प्रस्ताव का शीर्षक दर्ज करें।',
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final normalizedAmt = AppTranslations.normalizeAsciiDigits(reqAmtCtrl.text.trim());
                              final newProv = WardProvisionModel(
                                id: 'prov-${DateTime.now().millisecondsSinceEpoch}',
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                requestedAmount: double.tryParse(normalizedAmt) ?? 0,
                                sanctionedAmount: null,
                                requestedDate: dateCtrl.text.trim(),
                                sanctionedDate: null,
                                status: 'Pending',
                                financialYear: finYear,
                                category: catCtrl.text.trim().isNotEmpty ? catCtrl.text.trim() : 'General',
                                area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                                letterReference: refCtrl.text.trim().isNotEmpty ? refCtrl.text.trim() : 'PMC/GEN/001',
                              );

                              final repo = ref.read(wardProvisionsRepoProvider);
                              await repo.addProvision(newProv);
                              await _loadProvisions();

                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Provision request added successfully!',
                                        mr: 'तरतूद मागणी यशस्वीरित्या जोडली गेली!',
                                        hi: 'प्रावधान अनुरोध सफलतापूर्वक जोड़ा गया!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Update Sanction Modal matching WardProvisions.tsx lines 460-540
  void _openUpdateModal(WardProvisionModel item) {
    final lang = ref.read(appLanguageProvider);
    final sancAmtCtrl = TextEditingController(text: (item.sanctionedAmount ?? item.requestedAmount).toStringAsFixed(0));
    final areaCtrl = TextEditingController(text: item.area);
    final now = DateTime.now();
    final sancDateCtrl = TextEditingController(
      text: item.sanctionedDate ??
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    String status = item.status == 'Pending' ? 'Approved' : item.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
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
                    icon: Icons.verified_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Update Sanction Details',
                      mr: 'मंजुरी तपशील अद्यतनित करा',
                      hi: 'स्वीकृति विवरण अपडेट करें',
                    ),
                    subtitle: DynamicTranslationService.getCachedTranslation(item.title, lang) ?? item.title,
                    onClose: () => Navigator.pop(sheetCtx),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Project overview card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'PROJECT', mr: 'प्रकल्प / काम', hi: 'परियोजना / कार्य'),
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 3),
                              AppTranslatedText(
                                item.title,
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppTranslations.pick(lang, en: "Requested", mr: "मागणी रक्कम", hi: "अपेक्षित राशि")}: ${_formatCurrency(item.requestedAmount, lang)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Sanctioned Amount & Sanctioned Date side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Sanctioned Amount (₹)',
                                      mr: 'मंजूर रक्कम (₹)',
                                      hi: 'स्वीकृत राशि (₹)',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: sancAmtCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                    decoration: _inputDec(
                                      prefixText: '₹ ',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Sanctioned Date',
                                      mr: 'मंजूर तारीख',
                                      hi: 'स्वीकृति तिथि',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: sancDateCtrl,
                                    decoration: _inputDec(
                                      hintText: 'YYYY-MM-DD',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Area
                        _fieldLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Area / Ward Sector',
                            mr: 'परिसर / प्रभाग भाग',
                            hi: 'क्षेत्र / वार्ड सेक्टर',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: areaCtrl,
                          decoration: _inputDec(),
                        ),
                        const SizedBox(height: 14),

                        // Status Choices
                        _fieldLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Approval Status',
                            mr: 'मंजुरी स्थिती',
                            hi: 'स्वीकृति स्थिति',
                          ),
                          isRequired: true,
                        ),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.8,
                          children: ['Approved', 'Partially Approved', 'Pending', 'Rejected'].map((s) {
                            final isSel = status == s;
                            return InkWell(
                              onTap: () => setModalState(() => status = s),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF0284C7) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getStatusText(s, lang),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
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
                                en: 'Update Sanction',
                                mr: 'मंजुरी अद्यतनित करा',
                                hi: 'स्वीकृति अपडेट करें',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: () async {
                              final normalizedSancAmt = AppTranslations.normalizeAsciiDigits(sancAmtCtrl.text.trim());
                              final updated = item.copyWith(
                                sanctionedAmount: double.tryParse(normalizedSancAmt),
                                area: areaCtrl.text.trim(),
                                sanctionedDate: sancDateCtrl.text.trim(),
                                status: status,
                              );

                              final repo = ref.read(wardProvisionsRepoProvider);
                              await repo.updateProvision(updated);
                              await _loadProvisions();

                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Sanction details updated successfully!',
                                        mr: 'मंजुरी तपशील यशस्वीरित्या अद्यतनित केले!',
                                        hi: 'स्वीकृति विवरण सफलतापूर्वक अपडेट किए गए!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Delete target modal matching lines 542-570
  void _confirmDelete(WardProvisionModel item) {
    final lang = ref.read(appLanguageProvider);
    final displayTitle =
        DynamicTranslationService.getCachedTranslation(item.title, lang) ??
            item.title;
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppTranslations.pick(
              lang,
              en: 'Delete Provision?',
              mr: 'तरतूद हटवायची का?',
              hi: 'प्रावधान हटाएं?',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Are you sure you want to delete "$displayTitle"? This action cannot be undone.',
              mr: 'तुम्हाला "$displayTitle" ही तरतूद नक्की हटवायची आहे का? ही कृती पूर्ववत करता येणार नाही.',
              hi: 'क्या आप वाकई "$displayTitle" को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Cancel',
                  mr: 'रद्द करा',
                  hi: 'रद्द करें',
                ),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(dCtx);
                final repo = ref.read(wardProvisionsRepoProvider);
                await repo.deleteProvision(item.id);
                await _loadProvisions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Provision deleted successfully',
                          mr: 'तरतूद यशस्वीरित्या हटवली',
                          hi: 'प्रावधान सफलतापूर्वक हटाया गया',
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Delete',
                  mr: 'हटवा',
                  hi: 'हटाएं',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    final totalRequested = _provisions.fold<double>(0, (sum, p) => sum + p.requestedAmount);
    final totalSanctioned = _provisions.fold<double>(0, (sum, p) => sum + (p.sanctionedAmount ?? 0));
    final successRate = totalRequested > 0 ? ((totalSanctioned / totalRequested) * 100).toStringAsFixed(1) : '0';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const NagarsevakAppDrawer(currentTabIndex: 0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
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
                  en: 'Ward Wise Provision',
                  mr: 'प्रभागनिहाय तरतूद',
                  hi: 'वार्ड-वार प्रावधान',
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
                  en: 'Yearly municipal provisions & capital development allocations',
                  mr: 'वार्षिक बजेट तरतुदी आणि निधी वाटप',
                  hi: 'वार्षिक बजट प्रावधान व पूंजीगत विकास आवंटन',
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
          actions: const [],
        ),
        body: _loading
            ? const AppShimmerList(count: 6)
            : RefreshIndicator(
                onRefresh: _loadProvisions,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // FY Selector & PDF Download Bar
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          // FY Selector
                          AppDropdown<String>(
                            title: AppTranslations.pick(
                              lang,
                              en: 'Select Financial Year',
                              mr: 'आर्थिक वर्ष निवडा',
                              hi: 'वित्तीय वर्ष चुनें',
                            ),
                            value: _year,
                            height: 40,
                            isExpanded: false,
                            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0284C7)),
                            items: [
                              DropdownMenuItem(value: '2024-2025', child: Text(AppTranslations.pick(lang, en: 'FY 2024-2025', mr: 'आर्थिक वर्ष २०२४-२०२५', hi: 'वित्त वर्ष २०२४-२०२५'))),
                              DropdownMenuItem(value: '2023-2024', child: Text(AppTranslations.pick(lang, en: 'FY 2023-2024', mr: 'आर्थिक वर्ष २०२३-२०२४', hi: 'वित्त वर्ष २०२३-२०२४'))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _year = val;
                                  _displayedLimit = 20;
                                });
                                _loadProvisions();
                              }
                            },
                          ),
                          const SizedBox(width: 8),

                          // Download Report
                          Expanded(
                            child: AppPdfButton(
                              label: AppTranslations.getDownloadReport(lang),
                              style: AppPdfButtonStyle.tonal,
                              tooltip: AppTranslations.getDownloadReport(lang),
                              onPressed: () {
                                WardProvisionReportGenerator.generateAndPrintProvisionReport(
                                  provisions: _provisions,
                                  year: _year,
                                  lang: lang,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Overview Cards matching WardProvisions.tsx lines 208-242
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Total Requested Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFF0F9FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Total Requested',
                                          mr: 'एकूण मागणी',
                                          hi: 'कुल मांग',
                                        ),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F9FF),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFBAE6FD)),
                                        ),
                                        child: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(totalRequested, lang),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${AppTranslations.formatDigits('${_provisions.length}', lang)} ${AppTranslations.pick(lang, en: "pending requests", mr: "प्रस्तावित कामे", hi: "प्रस्तावित कार्य")}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Total Sanctioned Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFF0FDF4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Total Sanctioned',
                                          mr: 'एकूण मंजूर',
                                          hi: 'कुल स्वीकृत',
                                        ),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFBBF7D0)),
                                        ),
                                        child: const Icon(Icons.currency_rupee_rounded, size: 16, color: Color(0xFF16A34A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(totalSanctioned, lang),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: totalRequested > 0 ? (totalSanctioned / totalRequested) : 0,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      color: const Color(0xFF0284C7),
                                      minHeight: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppTranslations.formatDigits(successRate, lang)}% ${AppTranslations.pick(lang, en: "success rate", mr: "मंजुरी दर", hi: "सफलता दर")}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Provisions Table matching WardProvisions.tsx lines 245-344
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: _provisions.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  const Icon(Icons.description_outlined, size: 48, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'No provision records found',
                                      mr: 'कोणतेही तरतूद रेकॉर्ड आढळले नाही',
                                      hi: 'कोई प्रावधान रिकॉर्ड नहीं मिला',
                                    ),
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                columnSpacing: 18,
                                columns: [
                                  DataColumn(label: Text(AppTranslations.pick(lang, en: 'Title / Scope', mr: 'प्रकल्प शीर्षक', hi: 'परियोजना शीर्षक'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(AppTranslations.pick(lang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(AppTranslations.pick(lang, en: 'Amount', mr: 'रक्कम', hi: 'राशि'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(AppTranslations.pick(lang, en: 'Date', mr: 'तारीख', hi: 'तारीख'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(AppTranslations.pick(lang, en: 'Actions', mr: 'कृती', hi: 'कार्रवाई'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                                rows: _visibleProvisions.map((item) {
                                  return DataRow(
                                    cells: [
                                      // Title & Category + Reference matching lines 282-291
                                      DataCell(
                                        SizedBox(
                                          width: 180,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              AppTranslatedText(
                                                item.title,
                                                targetLanguage: lang,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: AppTranslatedText(
                                                      item.category,
                                                      targetLanguage: lang,
                                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      '${AppTranslations.pick(lang, en: "Ref", mr: "संदर्भ", hi: "संदर्भ")}: ${AppTranslations.formatDigits(item.letterReference, lang)}',
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Area matching line 293
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: AppTranslatedText(
                                            item.area.isNotEmpty ? item.area : '-',
                                            targetLanguage: lang,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                          ),
                                        ),
                                      ),

                                      // Amount with Strikethrough if partial matching lines 296-300
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatCurrency(item.sanctionedAmount ?? item.requestedAmount, lang),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            ),
                                            if (item.sanctionedAmount != null && item.sanctionedAmount! < item.requestedAmount) ...[
                                              Text(
                                                '${AppTranslations.pick(lang, en: "req", mr: "मागणी", hi: "मांग")}: ${_formatCurrency(item.requestedAmount, lang)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF94A3B8),
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Status Badge matching lines 302-307
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getStatusBg(item.status),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: _getStatusBorderColor(item.status)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_getStatusIcon(item.status), size: 12, color: _getStatusTextColor(item.status)),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getStatusText(item.status, lang),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusTextColor(item.status),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Date matching line 309
                                      DataCell(
                                        Text(
                                          _formatProvDate(item.sanctionedDate ?? item.requestedDate, lang),
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                        ),
                                      ),

                                      // Action Buttons matching lines 312-337
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                                              tooltip: AppTranslations.pick(
                                    lang,
                                    en: 'Update Sanction',
                                    mr: 'मंजुरी अद्यतनित करा',
                                    hi: 'स्वीकृति अपडेट करें',
                                  ),
                                              onPressed: () => _openUpdateModal(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                              tooltip: AppTranslations.pick(
                                    lang,
                                    en: 'Delete',
                                    mr: 'हटवा',
                                    hi: 'हटाएं',
                                  ),
                                              onPressed: () => _confirmDelete(item),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),

                    if (!_loading && _provisions.isNotEmpty)
                      AppLoadMoreFooter(
                        currentCount: _visibleProvisions.length,
                        totalCount: _provisions.length,
                        pageSize: 20,
                        onLoadMore: () => setState(() => _displayedLimit += 20),
                        label: AppTranslations.pick(lang, en: 'provisions', mr: 'तरतुदी', hi: 'प्रावधान'),
                        isMarathi: lang == 'mr',
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _openAddModal,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            AppTranslations.pick(
              lang,
              en: 'New Provision',
              mr: 'नवीन मागणी',
              hi: 'नया प्रावधान',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
