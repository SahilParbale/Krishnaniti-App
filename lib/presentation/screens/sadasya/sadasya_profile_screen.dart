import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/sadasya_model.dart';
import '../../providers/language_provider.dart';

class SadasyaProfileScreen extends ConsumerWidget {
  final SadasyaModel member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SadasyaProfileScreen({
    super.key,
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _makeCall(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String number, String lang) async {
    final clean = number.replaceAll(RegExp(r'[^\d]'), '');
    final name = await DynamicTranslationService.translateOrRaw(
      member.displayNameFor(lang),
      lang,
      isName: true,
    );
    final greeting = Uri.encodeComponent(
      AppTranslations.pick(
        lang,
        en: 'Hello $name,',
        mr: 'नमस्कार $name,',
        hi: 'नमस्ते $name,',
      ),
    );
    final uri = Uri.parse('https://wa.me/$clean?text=$greeting');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final dateFormatted = AppTranslations.formatDate(
      member.registeredAt,
      lang,
      pattern: 'dd MMMM yyyy',
    );
    final primaryName = member.displayNameFor(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'वापस'),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTranslations.pick(
            lang,
            en: 'Member Profile',
            mr: 'सदस्य प्रोफाइल',
            hi: 'सदस्य प्रोफ़ाइल',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: AppTranslations.pick(lang, en: 'Edit Details', mr: 'माहिती संपादित करा', hi: 'विवरण संपादित करें'),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(lang, en: 'Remove Member', mr: 'सदस्य हटवा', hi: 'सदस्य हटाएं'),
            onPressed: () => _confirmDelete(context, lang),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFFE0F2FE),
                        child: Text(
                          member.initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              primaryName,
                              targetLanguage: lang,
                              isName: true,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (member.nameEnglish != null && member.nameEnglish != primaryName)
                              AppTranslatedText(
                                member.nameEnglish!,
                                targetLanguage: lang,
                                isName: true,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: member.isVoter ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: member.isVoter ? const Color(0xFF86EFAC) : const Color(0xFFBAE6FD),
                                    ),
                                  ),
                                  child: Text(
                                    member.isVoter
                                        ? AppTranslations.pick(lang, en: 'Registered Voter', mr: 'नोंदणीकृत मतदार', hi: 'पंजीकृत मतदाता')
                                        : AppTranslations.pick(lang, en: 'Party Member', mr: 'पक्ष सदस्य', hi: 'पार्टी सदस्य'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: member.isVoter ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                if (member.role != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: AppTranslatedText(
                                      member.role!,
                                      targetLanguage: lang,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
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

                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // Quick Action Buttons (Call, WhatsApp, Share)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makeCall(member.mobile),
                          icon: const Icon(Icons.call_rounded, size: 18, color: Colors.white),
                          label: Text(
                            AppTranslations.pick(lang, en: 'Call', mr: 'कॉल करा', hi: 'कॉल करें'),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openWhatsApp(member.mobile, lang),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
                          label: Text(
                            AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सअॅप', hi: 'व्हाट्सएप'),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Detailed Information Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Personal & Contact Information',
                      mr: 'वैयक्तिक व संपर्क माहिती',
                      hi: 'व्यक्तिगत व संपर्क जानकारी',
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    Icons.phone_iphone_rounded,
                    AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                    AppTranslations.formatDigits(member.mobile, lang),
                  ),
                  _buildInfoRow(
                    Icons.cake_outlined,
                    AppTranslations.pick(lang, en: 'Age & Gender', mr: 'वय व लिंग', hi: 'आयु व लिंग'),
                    '${member.age > 0 ? "${AppTranslations.formatDigits('${member.age}', lang)} ${AppTranslations.pick(lang, en: 'Yrs', mr: 'वर्षे', hi: 'वर्ष')}" : "-"} • ${member.displayGenderFor(lang)}',
                  ),
                  if (member.voterId != null && member.voterId!.isNotEmpty)
                    _buildInfoRow(
                      Icons.badge_outlined,
                      AppTranslations.pick(lang, en: 'EPIC / Voter ID', mr: 'मतदार ओळखपत्र क्र.', hi: 'मतदाता पहचान पत्र सं.'),
                      AppTranslations.formatDigits(member.voterId!, lang),
                    ),
                  _buildTranslatedInfoRow(
                    Icons.location_on_outlined,
                    AppTranslations.pick(lang, en: 'Ward & Area', mr: 'प्रभाग व परिसर', hi: 'वार्ड व क्षेत्र'),
                    '${member.ward ?? AppTranslations.pick(lang, en: 'Ward 12', mr: 'प्रभाग १२', hi: 'वार्ड १२')} • ${AppTranslations.getAreaName(member.area ?? 'Shaniwar Peth', lang)}',
                    lang,
                  ),
                  _buildTranslatedInfoRow(
                    Icons.home_outlined,
                    AppTranslations.pick(lang, en: 'Residential Address', mr: 'निवासी पत्ता', hi: 'निवासी पता'),
                    member.displayAddressFor(lang),
                    lang,
                  ),
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    AppTranslations.pick(lang, en: 'Registration Date', mr: 'नोंदणी दिनांक', hi: 'पंजीकरण तिथि'),
                    dateFormatted,
                  ),
                  _buildInfoRow(
                    Icons.verified_outlined,
                    AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                    AppTranslations.getStatus(member.status, lang),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Civic Task & Activity Section (matching Nagarsevak-Managment work assignment)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Assigned Ward Tasks & Responsibilities',
                            mr: 'नेमलेली प्रभाग कामे व जबाबदाऱ्या',
                            hi: 'सौंपे गए वार्ड कार्य व जिम्मेदारियां',
                          ),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          '${AppTranslations.formatDigits('2', lang)} ${AppTranslations.pick(lang, en: 'Active Tasks', mr: 'सक्रिय कामे', hi: 'सक्रिय कार्य')}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildTaskTile(
                    title: AppTranslations.pick(
                      lang,
                      en: 'Voter List Verification Campaign - Shaniwar Peth',
                      mr: 'मतदार यादी पडताळणी मोहीम - शनिवार पेठ',
                      hi: 'मतदाता सूची सत्यापन अभियान - शनिवार पेठ',
                    ),
                    date: AppTranslations.formatDate(DateTime(2025, 2, 10), lang, pattern: 'dd MMM yyyy'),
                    status: AppTranslations.getStatus('Completed', lang),
                    statusColor: const Color(0xFF16A34A),
                    statusBg: const Color(0xFFDCFCE7),
                  ),
                  const SizedBox(height: 8),
                  _buildTaskTile(
                    title: AppTranslations.pick(
                      lang,
                      en: 'Health Camp Volunteer Planning',
                      mr: 'आरोग्य शिबिर स्वयंसेवक नियोजन',
                      hi: 'स्वास्थ्य शिविर स्वयंसेवक योजना',
                    ),
                    date: AppTranslations.formatDate(DateTime(2025, 2, 18), lang, pattern: 'dd MMM yyyy'),
                    status: AppTranslations.getStatus('In Progress', lang),
                    statusColor: const Color(0xFFD97706),
                    statusBg: const Color(0xFFFEF3C7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslatedInfoRow(
      IconData icon, String label, String value, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                AppTranslatedText(
                  value,
                  targetLanguage: lang,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile({
    required String title,
    required String date,
    required String status,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppTranslations.pick(lang, en: 'Confirm Remove Member', mr: 'सदस्य हटविण्याची पुष्टी करा', hi: 'सदस्य हटाने की पुष्टि करें'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: FutureBuilder<String>(
          future: DynamicTranslationService.translateOrRaw(member.displayNameFor(lang), lang, isName: true),
          builder: (context, snapshot) {
            final name = snapshot.data ?? member.displayNameFor(lang);
            return Text(
              AppTranslations.pick(
                lang,
                en: 'Are you sure you want to remove "$name" from the members list?',
                mr: 'तुम्हाला खरोखर "$name" यांना सदस्य यादीतून हटवायचे आहे का?',
                hi: 'क्या आप वाकई "$name" को सदस्य सूची से हटाना चाहते हैं?',
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: Text(
              AppTranslations.pick(lang, en: 'Remove', mr: 'हटवा', hi: 'हटाएं'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

