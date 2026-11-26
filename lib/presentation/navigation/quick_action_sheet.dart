import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/complaints/new_complaint_bottom_sheet.dart';
import '../screens/letters/new_letter_bottom_sheet.dart';

class QuickActionSheet extends ConsumerWidget {
  const QuickActionSheet({super.key});

  static void show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const QuickActionSheet(),
            ),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final isMr = lang == 'mr';
    final isHi = lang == 'hi';
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    String t(String en, String mr, String hi) => isMr ? mr : (isHi ? hi : en);

    final actions = [
      _QuickActionItem(
        icon: Icons.add_task_rounded,
        title: t('New Citizen Request', 'नवीन तक्रार / विनंती', 'नई नागरिक शिकायत / अनुरोध'),
        subtitle: t(
          'Log civic issue, road, water or street light grievance',
          'नागरी समस्या व तक्रार नोंदवा',
          'नागरिक समस्याएं व शिकायत दर्ज करें',
        ),
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        onTap: () {
          Navigator.pop(context);
          NewComplaintBottomSheet.show(context);
        },
      ),
      _QuickActionItem(
        icon: Icons.mail_outline_rounded,
        title: t('Draft Official Letter', 'नवीन पत्र व्यवहार', 'नया पत्र व्यवहार'),
        subtitle: t(
          'Ward correspondence, administrative letters & proposals',
          'प्रभागातील पत्र व आवक-जावक',
          'वार्ड पत्राचार व आवक-जावक',
        ),
        gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
        onTap: () {
          Navigator.pop(context);
          NewLetterBottomSheet.show(context);
        },
      ),
      _QuickActionItem(
        icon: Icons.person_search_rounded,
        title: t('Voter Directory & Search', 'मतदार शोध व यादी', 'मतदाता खोज व सूची'),
        subtitle: t(
          'Lookup booth, family details & print voter slip',
          'बूथ, कुटुंब व मतदार स्लिप',
          'बूथ, परिवार विवरण व मतदाता पर्ची',
        ),
        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        onTap: () {
          Navigator.pop(context);
          ref.read(activeScreenProvider.notifier).setScreen('voters');
        },
      ),
      _QuickActionItem(
        icon: Icons.event_note_rounded,
        title: t('Diary Meeting / Visit', 'दौरा / दैनंदिनी नोंद', 'दौरा / दैनंदिनी प्रविष्टि'),
        subtitle: t(
          'Schedule field visit, event or personal meeting',
          'दौरे, बैठका व नियोजित कार्यक्रम',
          'दौरे, बैठकें व तय कार्यक्रम',
        ),
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        onTap: () {
          Navigator.pop(context);
          ref.read(activeScreenProvider.notifier).setScreen('diary');
        },
      ),
      _QuickActionItem(
        icon: Icons.badge_outlined,
        title: t('Record Visitor', 'कार्यालय भेट नोंद', 'कार्यालय आगंतुक प्रविष्टि'),
        subtitle: t(
          'Log citizen delegation, visitor info & purpose',
          'कार्यालयात आलेले नागरिक व शिष्टमंडळ',
          'कार्यालय में आए नागरिक व शिष्टमंडल',
        ),
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        onTap: () {
          Navigator.pop(context);
          ref.read(activeScreenProvider.notifier).setScreen('visitors');
        },
      ),
      _QuickActionItem(
        icon: Icons.auto_awesome_rounded,
        title: t('AI Content Studio', 'एआय भाषण व मजकूर', 'एआई भाषण व सामग्री'),
        subtitle: t(
          'Generate political speech, greeting or social post',
          'भाषण, शुभेच्छा पत्र व सोशल पोस्ट',
          'भाषण, शुभकामना संदेश व सोशल पोस्ट',
        ),
        gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
        onTap: () {
          Navigator.pop(context);
          ref.read(activeScreenProvider.notifier).setScreen('ai_content');
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        isDesktop ? 18 : 12,
        20,
        isDesktop ? 20 : MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle (Mobile only)
          if (!isDesktop) ...[
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
          ],

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
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
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
                      t('Quick Actions', 'जलद कृती मेनू', 'त्वरित कार्रवाई मेनू'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t('Shortcuts for daily ward operations & logging', 'दैनंदिन कामांसाठी जलद शॉर्टकट', 'दैनिक कार्यों के लिए त्वरित शॉर्टकट'),
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
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = actions[i];
                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: const Color(0xFF0284C7).withValues(alpha: 0.08),
                    highlightColor: const Color(0xFF0284C7).withValues(alpha: 0.04),
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
                                  color: item.gradient.first.withValues(alpha: 0.25),
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

