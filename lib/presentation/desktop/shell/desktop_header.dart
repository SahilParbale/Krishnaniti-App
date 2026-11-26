import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/navigation_provider.dart';

class DesktopHeader extends ConsumerWidget {
  final VoidCallback onOpenCommandPalette;
  final VoidCallback onNewComplaint;

  const DesktopHeader({
    super.key,
    required this.onOpenCommandPalette,
    required this.onNewComplaint,
  });

  static final Map<String, String> _screenTitles = {
    'dashboard': 'Dashboard Overview',
    'complaints': 'Citizen Complaints & Grievances',
    'letters': 'Letters & Inward/Outward Records',
    'diary': 'Daily Tasks & Diary Log',
    'visitors': 'Office Visitor Log',
    'schemes': 'Government Schemes & Subsidies',
    'ward_problems': 'Ward Problems & Citizen Requests',
    'ward_map': 'Ward GIS Map & Geographic Locations',
    'work_history': 'Ward Development Work History',
    'improvements': 'Possible Ward Improvements',
    'provisions': 'Ward Financial Provisions',
    'gb_register': 'GB Register & General Body Motions',
    'ward_budget': 'Ward Budget Allocation & Expenses',
    'gov_office': 'Government Offices & Directory',
    'social_analytics': 'Social Media Analytics & Reach',
    'newspaper': 'Newspaper Clippings & Media Coverage',
    'media_tracking': 'Media Tracking & Sentiment',
    'ai_content': 'AI Content Studio & Post Creator',
    'events': 'Events, Programs & Invitations',
    'gallery': 'Photo Gallery & Visual Archives',
    'result_analysis': 'Election Results & Booth Analysis',
    'sadasya': 'Party Members & Cadre Management',
    'surveys': 'Sample Field Surveys & Feedbacks',
    'voters': 'Voters Directory & Search',
    'team': 'My Administrative Team & Staff',
    'opposition': 'Opposition Activity & Tracker',
    'ngo_mandals': 'NGO, Mandals & Social Organizations',
    'housing_societies': 'Housing Societies & Chairpersons',
    'duplicate_voters': 'Duplicate Voters Cross-Check',
    'voter_forms': 'Voter Registration Applications',
    'karyakarta_work': 'Karyakarta Work Assignment & Tracker',
    'sms': 'Bulk SMS Communication Campaigns',
    'whatsapp_message': 'WhatsApp Broadcast & Messages',
    'voice_call': 'Automated Voice Call Campaigns',
    'ai_voice_call': 'AI Smart Voice Calls & Inquiries',
    'conference_room': 'Virtual Video Conference Room',
    'whatsapp_call': 'Direct WhatsApp Calling Service',
    'analysis_strategy': 'Ward Analytics & Political Strategy',
    'profile_settings': 'Ward & Profile Configuration',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeKey = ref.watch(activeScreenProvider);
    final activeTitle = _screenTitles[activeKey] ?? 'Overview';
    final nowFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.slate200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Active Screen Title & Breadcrumb
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.brand100),
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: AppColors.brand600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Text(
                            'Nagarsevak Portal',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate400,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('•', style: TextStyle(color: AppColors.slate300, fontSize: 11)),
                          ),
                          Expanded(
                            child: Text(
                              nowFormatted,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Central Search / Command Palette Bar
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: onOpenCommandPalette,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.slate400, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Search anything across modules...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.slate400,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.slate300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Ctrl+K',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Action Button: + New Grievance
          ElevatedButton.icon(
            onPressed: onNewComplaint,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ New Grievance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),


        ],
      ),
    );
  }
}
