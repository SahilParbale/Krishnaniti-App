import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/sadasya_model.dart';

class SadasyaProfileScreen extends StatelessWidget {
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

  Future<void> _openWhatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$clean?text=नमस्कार ${member.displayName} जी,');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd MMMM yyyy').format(member.registeredAt);

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
          'सदस्य तपशील (Member Profile)',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'माहिती संपादित करा',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            tooltip: 'सदस्य काढा',
            onPressed: () => _confirmDelete(context),
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
                            Text(
                              member.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (member.nameEnglish != null && member.nameEnglish != member.displayName)
                              Text(
                                member.nameEnglish!,
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
                                    member.isVoter ? 'नोंदणीकृत मतदार' : 'पक्ष सदस्य',
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
                                    child: Text(
                                      member.role!,
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
                          label: const Text(
                            'कॉल करा',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                          onPressed: () => _openWhatsApp(member.mobile),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'व्हॉट्सॲप',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                  const Text(
                    'वैयक्तिक व संपर्क माहिती',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _buildInfoRow(Icons.phone_iphone_rounded, 'मोबाईल क्रमांक', member.mobile),
                  _buildInfoRow(Icons.cake_outlined, 'वय व लिंग', '${member.age > 0 ? "${member.age} वर्षे" : "-"} • ${member.displayGender}'),
                  if (member.voterId != null && member.voterId!.isNotEmpty)
                    _buildInfoRow(Icons.badge_outlined, 'मतदार ओळखपत्र (EPIC No)', member.voterId!),
                  _buildInfoRow(Icons.location_on_outlined, 'प्रभाग व परिसर', '${member.ward ?? "प्रभाग १२"} • ${member.area ?? "शनिवार पेठ"}'),
                  _buildInfoRow(Icons.home_outlined, 'निवासस्थान पत्ता', member.displayAddress),
                  _buildInfoRow(Icons.calendar_today_outlined, 'नोंदणी दिनांक', dateFormatted),
                  _buildInfoRow(Icons.verified_outlined, 'स्थिती', member.status == 'Active' ? 'सक्रिय (Active)' : 'निष्क्रिय (Inactive)'),
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
                      const Text(
                        'सोपवलेली प्रभागातील कामे व जबाबदाऱ्या',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Text(
                          '२ कामे सक्रिय',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildTaskTile(
                    title: 'मतदार यादी पडताळणी मोहीम - शनिवार पेठ',
                    date: '१० फेब्रुवारी २०२५',
                    status: 'पूर्ण झाले',
                    statusColor: const Color(0xFF16A34A),
                    statusBg: const Color(0xFFDCFCE7),
                  ),
                  const SizedBox(height: 8),
                  _buildTaskTile(
                    title: 'आरोग्य तपासणी शिबिर स्वयंसेवक नियोजन',
                    date: '१८ फेब्रुवारी २०२५',
                    status: 'प्रगतीपथावर',
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('सदस्य काढण्याची खात्री करा', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('आपण खरोखरच "${member.displayName}" यांना सदस्य यादीतून काढू इच्छिता?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('काढून टाका', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

