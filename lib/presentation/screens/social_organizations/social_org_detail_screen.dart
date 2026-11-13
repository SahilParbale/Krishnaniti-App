import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/social_organization_model.dart';
import '../../../data/repositories/social_organization_repository.dart';
import '../../providers/auth_provider.dart';

class SocialOrgDetailScreen extends ConsumerStatefulWidget {
  final SocialOrganizationModel organization;

  const SocialOrgDetailScreen({super.key, required this.organization});

  @override
  ConsumerState<SocialOrgDetailScreen> createState() => _SocialOrgDetailScreenState();
}

class _SocialOrgDetailScreenState extends ConsumerState<SocialOrgDetailScreen> {
  late SocialOrganizationModel _org;

  @override
  void initState() {
    super.initState();
    _org = widget.organization;
  }

  Future<void> _refreshOrg() async {
    final repo = ref.read(socialOrgRepoProvider);
    final orgs = await repo.getOrganizations();
    final updated = orgs.where((o) => o.id == _org.id).firstOrNull;
    if (updated != null && mounted) {
      setState(() => _org = updated);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mobile number copied!'), duration: Duration(seconds: 2)),
    );
  }

  Map<String, dynamic> _getTheme(String type) {
    switch (type) {
      case 'ngo':
        return {
          'color': const Color(0xFF0284C7),
          'bg': const Color(0xFFF0F9FF),
          'border': const Color(0xFFBAE6FD),
          'icon': Icons.apartment_rounded,
        };
      case 'sports_cricket':
        return {
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFECFDF5),
          'border': const Color(0xFFA7F3D0),
          'icon': Icons.sports_cricket_rounded,
        };
      case 'ganpati_mandal':
        return {
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFFFBEB),
          'border': const Color(0xFFFDE68A),
          'icon': Icons.auto_awesome_rounded,
        };
      case 'navratri_mandal':
        return {
          'color': const Color(0xFFE11D48),
          'bg': const Color(0xFFFFF1F2),
          'border': const Color(0xFFFECDD3),
          'icon': Icons.festival_rounded,
        };
      default:
        return {
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF8FAFC),
          'border': const Color(0xFFE2E8F0),
          'icon': Icons.groups_rounded,
        };
    }
  }

  // ===========================================================================
  // ADD EVENT BOTTOM SHEET
  // ===========================================================================
  void _showAddEventModal() {
    final isMr = ref.read(isMarathiProvider);
    final titleCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: DateTime.now().year.toString());
    final descCtrl = TextEditingController();

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.70,
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
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 6, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_available_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isMr ? 'नवीन कार्यक्रम / उपक्रम जोडा' : 'Add New Event / Activity',
                    style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title & Year side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(isMr ? 'कार्यक्रमाचे नाव' : 'Event Name', isRequired: true),
                              TextField(
                                controller: titleCtrl,
                                decoration: inputDec(hint: isMr ? 'उदा. मोफत आरोग्य शिबीर, शिवजयंती' : 'e.g. Free Health Camp, Dahi Handi'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(isMr ? 'वर्ष' : 'Year', isRequired: true),
                              TextField(
                                controller: yearCtrl,
                                keyboardType: TextInputType.number,
                                decoration: inputDec(hint: '2026'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    fieldLabel(isMr ? 'तपशीलवार माहिती व योगदान' : 'Detailed Event Notes'),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: inputDec(hint: isMr ? 'सहभागी, प्रमुख पाहुणे, पुरस्कार व सामाजिक प्रभाव...' : 'Participants, chief guests, awards, and social impact...'),
                    ),
                    const SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isMr ? 'कृपया कार्यक्रमाचे नाव टाका.' : 'Please enter event name.')),
                            );
                            return;
                          }

                          final newEvent = SocialOrgEventModel(
                            id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            titleMr: titleCtrl.text.trim(),
                            year: int.tryParse(yearCtrl.text.trim()) ?? DateTime.now().year,
                            description: descCtrl.text.trim(),
                            descriptionMr: descCtrl.text.trim(),
                          );

                          final repo = ref.read(socialOrgRepoProvider);
                          await repo.addEvent(_org.id, newEvent);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (!mounted) return;
                          _refreshOrg();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isMr ? 'कार्यक्रम यशस्वीरित्या जोडला!' : 'Event added successfully!'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          isMr ? 'कार्यक्रम जतन करा' : 'Save Event',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // EDIT ORGANIZATION MODAL
  // ===========================================================================
  void _showEditOrgModal() {
    final isMr = ref.read(isMarathiProvider);
    final nameMrCtrl = TextEditingController(text: _org.nameMarathi ?? _org.name);
    final nameEnCtrl = TextEditingController(text: _org.nameEnglish ?? _org.name);
    String type = _org.type;
    final presNameCtrl = TextEditingController(text: _org.presidentName);
    final presPhoneCtrl = TextEditingController(text: _org.presidentMobile);
    final membersCtrl = TextEditingController(text: _org.membersCount > 0 ? _org.membersCount.toString() : '');
    final areaCtrl = TextEditingController(text: _org.area);
    final estCtrl = TextEditingController(text: _org.establishedYear);
    final supportCtrl = TextEditingController(text: _org.supportReceived);
    final descCtrl = TextEditingController(text: _org.description);
    String status = _org.status;

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.90,
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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 6, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isMr ? 'संस्थेची माहिती सुधारा' : 'Edit Organization Details',
                      style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Marathi & Name English side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'संस्थेचे नाव (मराठी)' : 'Organization Name (Marathi)', isRequired: true),
                                TextField(
                                  controller: nameMrCtrl,
                                  decoration: inputDec(hint: isMr ? 'उदा. बाळ गणेश मंडळ' : 'e.g. Bal Ganesh Mandal'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'संस्थेचे नाव (इंग्रजी)' : 'Organization Name (English)'),
                                TextField(
                                  controller: nameEnCtrl,
                                  decoration: inputDec(hint: isMr ? 'उदा. Bal Ganesh Mandal' : 'e.g. Bal Ganesh Mandal'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Organization Type & Status side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'संस्थेचा प्रकार' : 'Organization Type', isRequired: true),
                                DropdownButtonFormField<String>(
                                  initialValue: type,
                                  decoration: inputDec(),
                                  items: [
                                    DropdownMenuItem(value: 'ganpati_mandal', child: Text(isMr ? 'गणेश मंडळ' : 'Ganesh Mandal')),
                                    DropdownMenuItem(value: 'navratri_mandal', child: Text(isMr ? 'नवरात्र मंडळ' : 'Navratri Mandal')),
                                    DropdownMenuItem(value: 'sports_cricket', child: Text(isMr ? 'क्रीडा क्लब' : 'Cricket / Sports')),
                                    DropdownMenuItem(value: 'ngo', child: Text(isMr ? 'एन.जी.ओ / ट्रस्ट' : 'NGO / Trust')),
                                    DropdownMenuItem(value: 'other', child: Text(isMr ? 'इतर मंडळ' : 'Other Mandals')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => type = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'स्थिती' : 'Status'),
                                DropdownButtonFormField<String>(
                                  initialValue: status,
                                  decoration: inputDec(),
                                  items: const [
                                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => status = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // President Name & Mobile (+91) side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'प्रमुख व्यक्ती / अध्यक्ष नाव' : 'President Name', isRequired: true),
                                TextField(
                                  controller: presNameCtrl,
                                  decoration: inputDec(hint: isMr ? 'उदा. गणेश जाधव' : 'e.g. Ganesh Jadhav'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'मोबाईल नंबर' : 'Mobile (+91)', isRequired: true),
                                TextField(
                                  controller: presPhoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                  decoration: inputDec(prefixText: '+91 ', hint: '98221xxxxx'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total Members & Established Year side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'सदस्य संख्या (अंदाजे)' : 'Total Members (Approx)'),
                                TextField(
                                  controller: membersCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: inputDec(hint: '50'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'स्थापना वर्ष' : 'Established Year'),
                                TextField(
                                  controller: estCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: inputDec(hint: '2015'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Area / Location
                      fieldLabel(isMr ? 'परिसर / प्रभाग क्षेत्र' : 'Area / Vicinity', isRequired: true),
                      TextField(
                        controller: areaCtrl,
                        decoration: inputDec(hint: isMr ? 'उदा. सेक्टर ३, मुख्य चौक' : 'e.g. Sector 3, Main Chowk'),
                      ),
                      const SizedBox(height: 12),

                      // Nagarsevak Support Received Notes
                      fieldLabel(isMr ? 'आपल्या वतीने मिळालेली मदत / प्रायोजकत्व' : 'Corporator Support & Sponsorship History'),
                      TextField(
                        controller: supportCtrl,
                        maxLines: 2,
                        decoration: inputDec(
                          hint: isMr
                              ? 'उदा. स्टेज उभारणी, साऊंड परवानगी, चषक प्रायोजकत्व...'
                              : 'e.g. Stage setup, sound permissions, trophy sponsorship...',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      fieldLabel(isMr ? 'संस्थेबद्दल माहिती व उद्दिष्टे' : 'About Organization & Objectives'),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: inputDec(
                          hint: isMr
                              ? 'सामाजिक उपक्रम, समाजकार्य व योगदान...'
                              : 'Social initiatives, community outreach & contributions...',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : nameEnCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isMr ? 'कृपया संस्थेचे नाव टाका.' : 'Please enter organization name.')),
                              );
                              return;
                            }

                            final updated = _org.copyWith(
                              name: name,
                              nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : name,
                              nameEnglish: nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : name,
                              type: type,
                              presidentName: presNameCtrl.text.trim(),
                              presidentMobile: presPhoneCtrl.text.trim(),
                              membersCount: int.tryParse(membersCtrl.text.trim()) ?? 0,
                              area: areaCtrl.text.trim(),
                              establishedYear: estCtrl.text.trim(),
                              supportReceived: supportCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              status: status,
                            );

                            final repo = ref.read(socialOrgRepoProvider);
                            await repo.updateOrganization(updated);

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (!mounted) return;
                            _refreshOrg();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isMr ? 'माहिती अद्यतनित केली!' : 'Details updated!'),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            isMr ? 'बदल जतन करा' : 'Save Changes',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final theme = _getTheme(_org.type);
    final repo = ref.read(socialOrgRepoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _org.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: _showEditOrgModal,
            tooltip: isMr ? 'संपादित करा' : 'Edit',
          ),
          if (_org.presidentMobile.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: Colors.white),
              onPressed: () => _makePhoneCall(_org.presidentMobile),
              tooltip: 'Call',
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
              onPressed: () => _openWhatsApp(_org.presidentMobile),
              tooltip: 'WhatsApp',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. ORGANIZATION HERO CARD
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme['border'] as Color),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: (theme['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: (theme['color'] as Color).withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Icon(
                            theme['icon'] as IconData,
                            color: theme['color'] as Color,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _org.displayName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (theme['color'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: (theme['color'] as Color).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    _org.typeLabelMarathi,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme['color'] as Color),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _org.status == 'Active' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _org.status == 'Active' ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Text(
                                    _org.status == 'Active' ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _org.status == 'Active' ? const Color(0xFF047857) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (_org.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"${_org.description}"',
                      style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Key Details 2x2 Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('President', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(_org.presidentName.isNotEmpty ? _org.presidentName : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Mobile Number', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  if (_org.presidentMobile.isNotEmpty)
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _makePhoneCall(_org.presidentMobile),
                                          child: Text(
                                            _org.presidentMobile,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _copyToClipboard(_org.presidentMobile),
                                          child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    )
                                  else
                                    const Text('-', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Members', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_org.membersCount} Members',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Established Year', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _org.establishedYear.isNotEmpty ? _org.establishedYear : '-',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Area Row
                  if (_org.area.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Area: ${_org.area}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ==========================================
            // 2. NAGARSEVAK SUPPORT & SPONSORSHIP HISTORY
            // ==========================================
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 20, color: Color(0xFF7C3AED)),
                      SizedBox(width: 8),
                      Text(
                        'Corporator Support & Sponsorship History',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _org.supportReceived.isNotEmpty
                        ? _org.supportReceived
                        : 'No official support recorded for this organization yet.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _org.supportReceived.isNotEmpty ? const Color(0xFF4C1D95) : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // 3. KEY EVENTS & FESTIVALS SECTION
            // ==========================================
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Text(
                            'Key Events & Activities (${_org.eventsConducted.length})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _showAddEventModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, size: 14, color: Color(0xFF0284C7)),
                              SizedBox(width: 4),
                              Text(
                                'Add Event',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_org.eventsConducted.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'No events recorded for this organization yet.\nClick "+ Add Event" to add festivals or sports tournaments.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _org.eventsConducted.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (ctx, idx) {
                        final evt = _org.eventsConducted[idx];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0284C7),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          evt.displayTitle,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          evt.year.toString(),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                                        onPressed: () async {
                                          await repo.deleteEvent(_org.id, evt.id);
                                          _refreshOrg();
                                        },
                                      ),
                                    ],
                                  ),
                                  if (evt.displayDescription.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      evt.displayDescription,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
