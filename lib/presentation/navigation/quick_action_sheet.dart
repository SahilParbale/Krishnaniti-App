import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/complaints/new_complaint_screen.dart';

class QuickActionSheet extends ConsumerWidget {
  const QuickActionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMr = ref.watch(isMarathiProvider);

    final actions = [
      _QuickActionItem(
        icon: Icons.add_task_rounded,
        title: isMr ? 'नवीन तक्रार / विनंती' : 'New Citizen Request',
        subtitle: isMr ? 'नागरी समस्या व तक्रार नोंदवा' : 'Log civic issue, road, water or street light grievance',
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewComplaintScreen()),
          );
        },
      ),
      _QuickActionItem(
        icon: Icons.mail_outline_rounded,
        title: isMr ? 'नवीन पत्र व्यवहार' : 'Draft Official Letter',
        subtitle: isMr ? 'प्रभागातील पत्र व आवक-जावक' : 'Ward correspondence, administrative letters & proposals',
        gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
        onTap: () {
          Navigator.pop(context);
          ref.read(mainTabIndexProvider.notifier).setTab(2);
          ref.read(activeScreenProvider.notifier).setScreen('letters');
        },
      ),
      _QuickActionItem(
        icon: Icons.person_search_rounded,
        title: isMr ? 'मतदार शोध व यादी' : 'Voter Directory & Search',
        subtitle: isMr ? 'बूथ, कुटुंब व मतदार स्लिप' : 'Lookup booth, family details & print voter slip',
        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        onTap: () {
          Navigator.pop(context);
          ref.read(activeScreenProvider.notifier).setScreen('voters');
        },
      ),
      _QuickActionItem(
        icon: Icons.event_note_rounded,
        title: isMr ? 'दौरा / दैनंदिनी नोंद' : 'Diary Meeting / Visit',
        subtitle: isMr ? 'दौरे, बैठका व नियोजित कार्यक्रम' : 'Schedule field visit, event or personal meeting',
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        onTap: () {
          Navigator.pop(context);
          ref.read(activeScreenProvider.notifier).setScreen('diary');
        },
      ),
      _QuickActionItem(
        icon: Icons.badge_outlined,
        title: isMr ? 'कार्यालय भेट नोंद' : 'Record Visitor',
        subtitle: isMr ? 'कार्यालयात आलेले नागरिक व शिष्टमंडळ' : 'Log citizen delegation, visitor info & purpose',
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        onTap: () {
          Navigator.pop(context);
          ref.read(activeScreenProvider.notifier).setScreen('visitors');
        },
      ),
      _QuickActionItem(
        icon: Icons.auto_awesome_rounded,
        title: isMr ? 'एआय भाषण व मजकूर' : 'AI Content Studio',
        subtitle: isMr ? 'भाषण, शुभेच्छा पत्र व सोशल पोस्ट' : 'Generate political speech, greeting or social post',
        gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
        onTap: () {
          Navigator.pop(context);
          ref.read(activeScreenProvider.notifier).setScreen('ai_content');
        },
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMr ? 'जलद कृती मेनू' : 'Quick Actions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMr ? 'दैनंदिन कामांसाठी जलद शॉर्टकट' : 'Shortcuts for daily ward operations & logging',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 22),
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Action Items Grid / List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = actions[i];
                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: const Color(0xFF0284C7).withOpacity(0.08),
                    highlightColor: const Color(0xFF0284C7).withOpacity(0.04),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: item.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: item.gradient.first.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(item.icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

