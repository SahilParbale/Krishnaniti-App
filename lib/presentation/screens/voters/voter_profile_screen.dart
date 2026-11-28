import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pagination_bar.dart';
import 'voter_slip_generator.dart';

class VoterProfileScreen extends ConsumerStatefulWidget {
  final VoterModel voter;

  const VoterProfileScreen({super.key, required this.voter});

  @override
  ConsumerState<VoterProfileScreen> createState() => _VoterProfileScreenState();
}

class _VoterProfileScreenState extends ConsumerState<VoterProfileScreen> {
  late VoterModel _voter;
  List<VoterModel> _familyMembers = [];
  bool _isLoadingFamily = true;
  int _familyPage = 1;
  static const int _familyPageSize = 5;

  int get _totalFamilyPages {
    final count = _familyMembers.length;
    return (count / _familyPageSize).ceil() < 1 ? 1 : (count / _familyPageSize).ceil();
  }

  List<VoterModel> get _pagedFamily {
    final startIndex = (_familyPage - 1) * _familyPageSize;
    if (startIndex >= _familyMembers.length) return [];
    final endIndex = min(startIndex + _familyPageSize, _familyMembers.length);
    return _familyMembers.sublist(startIndex, endIndex);
  }

  @override
  void initState() {
    super.initState();
    _voter = widget.voter;
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    if (_voter.houseNo == null || _voter.houseNo!.isEmpty) {
      if (mounted) setState(() => _isLoadingFamily = false);
      return;
    }

    final repo = ref.read(votersRepoProvider);
    final family = await repo.getFamilyMembers(_voter.houseNo!, _voter.booth);

    if (mounted) {
      setState(() {
        _familyMembers = family.where((m) => m.id != _voter.id).toList();
        _isLoadingFamily = false;
        _familyPage = 1;
      });
    }
  }

  Future<void> _updateFavour(String newFavour, String lang) async {
    final repo = ref.read(votersRepoProvider);
    await repo.updateFavour(_voter.id, newFavour);
    setState(() {
      _voter = _voter.copyWith(favour: newFavour);
    });

    if (mounted) {
      final stanceText = _voter.favourLabel(lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Political stance recorded as "$stanceText"',
              mr: 'राजकीय भूमिका "$stanceText" अशी नोंदवली गेली',
              hi: 'राजनीतिक रुझान "$stanceText" के रूप में दर्ज किया गया',
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    }
  }

  Future<void> _toggleFriendRelative(String lang) async {
    final repo = ref.read(votersRepoProvider);
    await repo.toggleFriendRelative(_voter.id, _voter.isFriendRelative);
    setState(() {
      _voter = _voter.copyWith(isFriendRelative: !_voter.isFriendRelative);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _voter.isFriendRelative
                ? AppTranslations.pick(
                    lang,
                    en: 'Added to Friends & Relatives list!',
                    mr: 'मित्र आणि नातेवाईक यादीत जोडले!',
                    hi: 'मित्र और रिश्तेदार सूची में जोड़ा गया!',
                  )
                : AppTranslations.pick(
                    lang,
                    en: 'Removed from Friends & Relatives list',
                    mr: 'मित्र आणि नातेवाईक यादीतून काढले',
                    hi: 'मित्र और रिश्तेदार सूची से हटाया गया',
                  ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _callVoter(String lang) async {
    if (_voter.mobile == null || _voter.mobile!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Mobile number not available for this voter',
              mr: 'या मतदाराचा मोबाईल नंबर उपलब्ध नाही',
              hi: 'इस मतदाता का मोबाइल नंबर उपलब्ध नहीं है',
            ),
          ),
        ),
      );
      return;
    }
    final clean = AppTranslations.normalizeAsciiDigits(_voter.mobile!).replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:+91$clean');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  Future<void> _shareSlipOnWhatsApp(String lang) async {
    final mobile = _voter.mobile != null
        ? AppTranslations.normalizeAsciiDigits(_voter.mobile!).replaceAll(RegExp(r'\D'), '')
        : '';
    final tName = await DynamicTranslationService.translateOrRaw(
      _voter.displayNameFor(lang),
      lang,
      isName: true,
    );
    final tStation = await DynamicTranslationService.translateOrRaw(
      _voter.displayPollingStationFor(lang),
      lang,
    );
    final tAddress = await DynamicTranslationService.translateOrRaw(
      _voter.address,
      lang,
    );
    final tBooth = await DynamicTranslationService.translateOrRaw(
      _voter.booth,
      lang,
    );
    final epicStr = AppTranslations.formatDigits(_voter.epicNo, lang);
    final serialStr = AppTranslations.formatDigits(_voter.serialNo?.toString() ?? '-', lang);
    final body = AppTranslations.pick(
      lang,
      en: 'Greetings $tName,\n\n'
          'Your official Ward 12 voter slip details:\n\n'
          '*Voter Name:* $tName\n'
          '*EPIC No:* $epicStr\n'
          '*Booth / Part No:* $tBooth\n'
          '*Serial No in Roll:* #$serialStr\n'
          '*Polling Station:* $tStation\n'
          '*Address:* $tAddress\n\n'
          'Please carry an identity card (EPIC or Aadhaar Card) on voting day.\n\n'
          '- Office of Corporator, Ward 12',
      mr: 'नमस्कार $tName,\n\n'
          'आपली प्रभाग १२ मधील अधिकृत मतदान पावती माहिती:\n\n'
          '*मतदाराचे नाव:* $tName\n'
          '*मतदार ओळखपत्र क्र. (EPIC):* $epicStr\n'
          '*बूथ / भाग क्र.:* $tBooth\n'
          '*यादीतील अनुक्रमांक:* #$serialStr\n'
          '*मतदान केंद्र:* $tStation\n'
          '*पत्ता:* $tAddress\n\n'
          'कृपया मतदानाच्या दिवशी ओळखपत्र (मतदार कार्ड किंवा आधार कार्ड) सोबत आणावे.\n\n'
          '- नगरसेवक कार्यालय, प्रभाग १२',
      hi: 'नमस्ते $tName,\n\n'
          'वार्ड १२ में आपकी आधिकारिक मतदाता पर्ची विवरण:\n\n'
          '*मतदाता का नाम:* $tName\n'
          '*पहचान पत्र क्र. (EPIC):* $epicStr\n'
          '*बूथ / भाग सं.:* $tBooth\n'
          '*सूची में क्रमांक:* #$serialStr\n'
          '*मतदान केंद्र:* $tStation\n'
          '*पता:* $tAddress\n\n'
          'कृपया मतदान के दिन एक पहचान पत्र (EPIC या आधार कार्ड) साथ लाएं।\n\n'
          '- नगरसेवक कार्यालय, वार्ड १२',
    );
    final msg = Uri.encodeComponent(body);

    Uri url;
    if (mobile.isNotEmpty) {
      url = Uri.parse('https://wa.me/91$mobile?text=$msg');
    } else {
      url = Uri.parse('https://wa.me/?text=$msg');
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    Color favourColor = const Color(0xFF64748B);
    Color favourBg = const Color(0xFFF1F5F9);

    switch (_voter.favour?.toLowerCase()) {
      case 'favourable':
        favourColor = const Color(0xFF16A34A);
        favourBg = const Color(0xFFDCFCE7);
        break;
      case 'against':
        favourColor = const Color(0xFFDC2626);
        favourBg = const Color(0xFFFEE2E2);
        break;
      case 'neutral':
        favourColor = const Color(0xFF0284C7);
        favourBg = const Color(0xFFE0F2FE);
        break;
      case 'swing':
        favourColor = const Color(0xFFD97706);
        favourBg = const Color(0xFFFEF3C7);
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'पीछे'),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTranslatedText(
              _voter.displayNameFor(lang),
              targetLanguage: lang,
              isName: true,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              AppTranslations.pick(
                lang,
                en: 'Voter details & official slip',
                mr: 'मतदार तपशील आणि अधिकृत पावती',
                hi: 'मतदाता विवरण और आधिकारिक पर्ची',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 10.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _voter.isFriendRelative ? Icons.star_rounded : Icons.star_border_rounded,
              color: _voter.isFriendRelative ? Colors.amberAccent : Colors.white,
            ),
            tooltip: _voter.isFriendRelative
                ? AppTranslations.pick(
                    lang,
                    en: 'Remove from Friends & Relatives',
                    mr: 'मित्र आणि नातेवाईक यादीतून काढा',
                    hi: 'मित्र और रिश्तेदार सूची से हटाएं',
                  )
                : AppTranslations.pick(
                    lang,
                    en: 'Mark as Friend / Relative',
                    mr: 'मित्र / नातेवाईक म्हणून चिन्हांकित करा',
                    hi: 'मित्र / रिश्तेदार के रूप में चिह्नित करें',
                  ),
            onPressed: () => _toggleFriendRelative(lang),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Print Voter Slip',
              mr: 'मतदान पावती प्रिंट करा',
              hi: 'मतदाता पर्ची प्रिंट करें',
            ),
            onPressed: () => VoterSlipGenerator.printVoterSlip(_voter, lang: lang),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Send Slip on WhatsApp',
              mr: 'व्हॉट्सअॅपवर पावती पाठवा',
              hi: 'व्हाट्सऐप पर पर्ची भेजें',
            ),
            onPressed: () => _shareSlipOnWhatsApp(lang),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Top Identity Header Card
          _buildIdentityHeaderCard(favourColor, favourBg, lang),
          const SizedBox(height: 14),

          // Official Voter Slip Card
          _buildOfficialVoterSlipCard(lang),
          const SizedBox(height: 14),

          // Political Favour / Stance Card
          _buildPoliticalStanceCard(lang),
          const SizedBox(height: 14),

          // Family Members in Same House Card
          _buildFamilyMembersCard(lang),
          const SizedBox(height: 14),

          // Polling Station Location Card
          _buildPollingStationCard(lang),
          const SizedBox(height: 40),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_voter.mobile != null && _voter.mobile!.isNotEmpty) ...[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone, size: 16, color: Color(0xFF0284C7)),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppTranslations.pick(lang, en: 'Direct Call', mr: 'थेट कॉल करा', hi: 'सीधा कॉल'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _callVoter(lang),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppTranslations.pick(lang, en: 'WhatsApp Slip', mr: 'व्हॉट्सअॅप पावती', hi: 'व्हाट्सऐप पर्ची'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _shareSlipOnWhatsApp(lang),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityHeaderCard(Color favourColor, Color favourBg, String lang) {
    final displayName = _voter.displayNameFor(lang);
    final ageStr = AppTranslations.formatDigits(_voter.age, lang);
    final serialStr = AppTranslations.formatDigits(_voter.serialNo?.toString() ?? '-', lang);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName.substring(0, 1) : 'V',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTranslatedText(
                      displayName,
                      targetLanguage: lang,
                      isName: true,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Age: $ageStr Yrs • ${_voter.genderLabel(lang)}',
                              mr: 'वय: $ageStr वर्षे • ${_voter.genderLabel(lang)}',
                              hi: 'उम्र: $ageStr वर्ष • ${_voter.genderLabel(lang)}',
                            ),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        if (_voter.caste != null && _voter.caste!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: AppTranslatedText(
                              _voter.caste!,
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Serial No Badge
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.format_list_numbered, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Roll Serial No: #$serialStr',
                          mr: 'यादी अनुक्र.: #$serialStr',
                          hi: 'सूची क्रमांक: #$serialStr',
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stance Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: favourBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: favourColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: favourColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _voter.favourLabel(lang),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: favourColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialVoterSlipCard(String lang) {
    final epicDisplay = AppTranslations.formatDigits(_voter.epicNo, lang);
    final houseDisplay = _voter.houseNo != null
        ? '#${AppTranslations.formatDigits(_voter.houseNo, lang)}'
        : AppTranslations.pick(lang, en: 'Not Available', mr: 'उपलब्ध नाही', hi: 'उपलब्ध नहीं');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slip Top Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFF0284C7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Official Voter Slip',
                        mr: 'अधिकृत मतदान पावती',
                        hi: 'आधिकारिक मतदाता पर्ची',
                      ),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => VoterSlipGenerator.printVoterSlip(_voter, lang: lang),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.print, size: 12, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.pick(lang, en: 'Print Slip', mr: 'प्रिंट करा', hi: 'प्रिंट करें'),
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildSlipRow(
                  icon: Icons.credit_card_rounded,
                  label: AppTranslations.pick(lang, en: 'EPIC ID No.', mr: 'ओळखपत्र क्र. (EPIC)', hi: 'पहचान पत्र क्र. (EPIC)'),
                  value: epicDisplay,
                  rawCopyValue: _voter.epicNo,
                  lang: lang,
                  isCopyable: true,
                ),
                const Divider(height: 14),
                _buildSlipRow(
                  icon: Icons.how_to_vote_outlined,
                  label: AppTranslations.pick(lang, en: 'Part / Booth No.', mr: 'भाग / बूथ क्र.', hi: 'भाग / बूथ क्र.'),
                  value: _voter.booth,
                  lang: lang,
                  translateValue: true,
                ),
                const Divider(height: 14),
                _buildSlipRow(
                  icon: Icons.home_outlined,
                  label: AppTranslations.pick(lang, en: 'House No.', mr: 'घर क्र.', hi: 'मकान नं.'),
                  value: houseDisplay,
                  lang: lang,
                ),
                const Divider(height: 14),
                _buildSlipRow(
                  icon: Icons.location_on_outlined,
                  label: AppTranslations.pick(lang, en: 'Residential Address', mr: 'निवासी पत्ता', hi: 'निवासी पता'),
                  value: _voter.address,
                  lang: lang,
                  translateValue: true,
                ),
                if (_voter.mobile != null && _voter.mobile!.isNotEmpty) ...[
                  const Divider(height: 14),
                  _buildSlipRow(
                    icon: Icons.phone_iphone_rounded,
                    label: AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                    value: AppTranslations.formatDigits('+91 ${_voter.mobile}', lang),
                    lang: lang,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlipRow({
    required IconData icon,
    required String label,
    required String value,
    required String lang,
    String? rawCopyValue,
    bool isCopyable = false,
    bool translateValue = false,
  }) {
    const valStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: translateValue
                    ? AppTranslatedText(value, targetLanguage: lang, style: valStyle)
                    : Text(value, style: valStyle),
              ),
              if (isCopyable)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.grey),
                  tooltip: AppTranslations.pick(lang, en: 'Copy', mr: 'कॉपी करा', hi: 'कॉपी करें'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: rawCopyValue ?? value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppTranslations.pick(
                            lang,
                            en: '$value copied!',
                            mr: '$value कॉपी केले!',
                            hi: '$value कॉपी किया गया!',
                          ),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoliticalStanceCard(String lang) {
    final stances = [
      {
        'key': 'Favourable',
        'label': AppTranslations.pick(lang, en: 'Favourable', mr: 'अनुकूल', hi: 'अनुकूल'),
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFDCFCE7),
      },
      {
        'key': 'Neutral',
        'label': AppTranslations.pick(lang, en: 'Neutral', mr: 'तटस्थ', hi: 'तटस्थ'),
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFE0F2FE),
      },
      {
        'key': 'Against',
        'label': AppTranslations.pick(lang, en: 'Against', mr: 'प्रतिकूल', hi: 'प्रतिकूल'),
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEE2E2),
      },
      {
        'key': 'Swing',
        'label': AppTranslations.pick(lang, en: 'Undecided', mr: 'अनिश्चित', hi: 'अनिश्चित'),
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFEF3C7),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_reg_rounded, size: 18, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Political Stance & Alignment',
                    mr: 'राजकीय भूमिका व कल',
                    hi: 'राजनीतिक रुझान और संरेखण',
                  ),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Tag voter political stance towards the party:',
              mr: 'पक्षाप्रती मतदाराची राजकीय भूमिका नोंदवा:',
              hi: 'पार्टी के प्रति मतदाता का राजनीतिक रुझान चिह्नित करें:',
            ),
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: stances.map((st) {
              final isSel = _voter.favour?.toLowerCase() == st['key']!.toString().toLowerCase();
              final c = st['color'] as Color;
              final bg = st['bg'] as Color;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => _updateFavour(st['key']!.toString(), lang),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? bg : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? c : Colors.grey.shade300,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              st['label']!.toString(),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? c : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersCard(String lang) {
    final houseSuffix = _voter.houseNo != null
        ? ' (${AppTranslations.pick(lang, en: "House", mr: "घर", hi: "मकान")} #${AppTranslations.formatDigits(_voter.houseNo, lang)})'
        : '';
    final famCountStr = AppTranslations.formatDigits(_familyMembers.length + 1, lang);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                    const Icon(Icons.family_restroom_rounded, size: 18, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${AppTranslations.pick(lang, en: "Family Members in Same Household", mr: "एकाच घरातील कुटुंबीय", hi: "एक ही परिवार के मतदाता")}$houseSuffix',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: '$famCountStr Voters',
                    mr: '$famCountStr मतदार',
                    hi: '$famCountStr मतदाता',
                  ),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isLoadingFamily
              ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
              : _familyMembers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No other voters registered at this house number.',
                          mr: 'या घर क्रमांकावर इतर मतदार नोंदणीकृत नाहीत.',
                          hi: 'इस मकान नंबर पर कोई अन्य मतदाता पंजीकृत नहीं है।',
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pagedFamily.length,
                          separatorBuilder: (_, _) => const Divider(height: 12),
                          itemBuilder: (ctx, idx) {
                            final m = _pagedFamily[idx];
                            String inferredRel = AppTranslations.pick(
                              lang,
                              en: 'Family Member',
                              mr: 'कुटुंब सदस्य',
                              hi: 'परिवार सदस्य',
                            );
                            if (m.relationType != null && m.relationType!.isNotEmpty) {
                              if (m.relationType == 'Spouse') {
                                inferredRel = AppTranslations.pick(lang, en: 'Spouse', mr: 'जोडीदार', hi: 'जीवनसाथी');
                              } else if (m.relationType == 'Son') {
                                inferredRel = AppTranslations.pick(lang, en: 'Son', mr: 'मुलगा', hi: 'पुत्र');
                              } else if (m.relationType == 'Daughter') {
                                inferredRel = AppTranslations.pick(lang, en: 'Daughter', mr: 'मुलगी', hi: 'पुत्री');
                              } else if (m.relationType == 'Head') {
                                inferredRel = AppTranslations.pick(lang, en: 'Head of Family', mr: 'कुटुंब प्रमुख', hi: 'परिवार प्रमुख');
                              }
                            } else {
                              if (m.age > _voter.age + 18) {
                                inferredRel = AppTranslations.pick(lang, en: 'Father / Mother', mr: 'वडील / आई', hi: 'पिता / माता');
                              } else if (m.age < _voter.age - 18) {
                                inferredRel = AppTranslations.pick(lang, en: 'Son / Daughter', mr: 'मुलगा / मुलगी', hi: 'पुत्र / पुत्री');
                              } else if ((m.age - _voter.age).abs() < 8 && m.gender != _voter.gender) {
                                inferredRel = AppTranslations.pick(lang, en: 'Spouse', mr: 'जोडीदार', hi: 'जीवनसाथी');
                              }
                            }

                            final mDisplayName = m.displayNameFor(lang);
                            final mAgeStr = AppTranslations.formatDigits(m.age, lang);

                            return InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => VoterProfileScreen(voter: m)),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      child: Text(
                                        mDisplayName.isNotEmpty ? mDisplayName.substring(0, 1) : 'V',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AppTranslatedText(
                                            mDisplayName,
                                            targetLanguage: lang,
                                            isName: true,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          Wrap(
                                            spacing: 4,
                                            children: [
                                              Text(
                                                AppTranslations.pick(
                                                  lang,
                                                  en: '$inferredRel • Age: $mAgeStr Yrs • ${m.genderLabel(lang)}',
                                                  mr: '$inferredRel • वय: $mAgeStr वर्षे • ${m.genderLabel(lang)}',
                                                  hi: '$inferredRel • उम्र: $mAgeStr वर्ष • ${m.genderLabel(lang)}',
                                                ),
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                              ),
                                              if (m.serialNo != null)
                                                Text(
                                                  '• #${AppTranslations.formatDigits(m.serialNo, lang)}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (m.favour != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: m.favour == 'Favourable'
                                              ? const Color(0xFFDCFCE7)
                                              : (m.favour == 'Against' ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          m.favourLabel(lang),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: m.favour == 'Favourable'
                                                ? const Color(0xFF16A34A)
                                                : (m.favour == 'Against' ? const Color(0xFFDC2626) : const Color(0xFF0284C7)),
                                          ),
                                        ),
                                      ),
                                    const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        AppInlinePagination(
                          currentPage: _familyPage,
                          totalPages: _totalFamilyPages,
                          totalItems: _familyMembers.length,
                          pageSize: _familyPageSize,
                          label: AppTranslations.pick(lang, en: 'voters', mr: 'मतदार', hi: 'मतदाता'),
                          onPageChanged: (page) => setState(() => _familyPage = page),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildPollingStationCard(String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city_rounded, size: 18, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Polling Station Details',
                  mr: 'मतदान केंद्र तपशील',
                  hi: 'मतदान केंद्र विवरण',
                ),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppTranslatedText(
            _voter.displayPollingStationFor(lang),
            targetLanguage: lang,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
          ),
          const SizedBox(height: 4),
          AppTranslatedText(
            AppTranslations.pick(
              lang,
              en: 'Assembly: 214 - Kasba Peth • Ward: 12 • Part: ${_voter.booth}',
              mr: 'विधानसभा: २१४ - कसबा पेठ • प्रभाग: १२ • भाग: ${_voter.booth}',
              hi: 'विधानसभा: २१४ - कसबा पेठ • वार्ड: १२ • भाग: ${_voter.booth}',
            ),
            targetLanguage: lang,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Voting Hours: 7:00 AM to 6:00 PM',
                      mr: 'मतदानाची वेळ: सकाळी ७:०० ते सायंकाळी ६:००',
                      hi: 'मतदान समय: सुबह ७:०० से शाम ६:००',
                    ),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
