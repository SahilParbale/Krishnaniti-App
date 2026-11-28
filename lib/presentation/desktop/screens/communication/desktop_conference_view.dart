import '../../common/desktop_modal_dialog.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../shell/desktop_sidebar.dart';
import '../../../screens/voice/conference_room_screen.dart';
import '../../../screens/voice/conference_meeting_report_generator.dart';
import '../../../widgets/app_load_more_footer.dart';

class MeetingItem {
  final String id;
  final String title;
  final String meetLink;
  final DateTime scheduledAt;
  final String status; // 'scheduled' | 'active' | 'ended'
  final int invitedCount;

  const MeetingItem({
    required this.id,
    required this.title,
    required this.meetLink,
    required this.scheduledAt,
    required this.status,
    required this.invitedCount,
  });
}

class DesktopConferenceView extends ConsumerStatefulWidget {
  const DesktopConferenceView({super.key});

  @override
  ConsumerState<DesktopConferenceView> createState() => _DesktopConferenceViewState();
}

class _DesktopConferenceViewState extends ConsumerState<DesktopConferenceView> {
  int _displayedLimit = 20;
  List<MeetingItem> get _visibleMeetings =>
      _meetings.take(_displayedLimit).toList();

  final List<MeetingItem> _meetings = [
    MeetingItem(
      id: 'm-1',
      title: 'Ward 12 Water Supply & Infrastructure Review Meeting',
      meetLink: 'https://meet.jit.si/nagarsevak-ward12-water-works',
      scheduledAt: DateTime.now().add(const Duration(hours: 3)),
      status: 'scheduled',
      invitedCount: 45,
    ),
    MeetingItem(
      id: 'm-2',
      title: 'Citizen Welfare & Women Empowerment Scheme Review',
      meetLink: 'https://meet.jit.si/nagarsevak-ladki-bahin-review',
      scheduledAt: DateTime.now().subtract(const Duration(minutes: 10)),
      status: 'active',
      invitedCount: 82,
    ),
    MeetingItem(
      id: 'm-3',
      title: 'Festival Committee Presidents & Security Coordination',
      meetLink: 'https://meet.jit.si/nagarsevak-ganesh-festival-sync',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      status: 'scheduled',
      invitedCount: 38,
    ),
    MeetingItem(
      id: 'm-4',
      title: 'Housing Societies Waste Management Action Meeting',
      meetLink: 'https://meet.jit.si/nagarsevak-housing-soc-waste',
      scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      status: 'ended',
      invitedCount: 64,
    ),
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyLink(String link, String lang) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Meeting link copied to clipboard!',
            mr: 'मीटिंगची लिंक क्लिपबोर्डवर कॉपी केली आहे!',
            hi: 'मीटिंग लिंक क्लिपबोर्ड पर कॉपी हो गया है!',
          ),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openCreateMeetingDialog() {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    String? titleError;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final lang = dialogRef.watch(desktopLanguageProvider);
          return StatefulBuilder(
            builder: (ctx, setDlgState) => DesktopModalDialog(
              title: AppTranslations.pick(
                lang,
                en: 'Schedule New Video Meeting',
                mr: 'नवीन व्हिडिओ बैठक नियोजित करा',
                hi: 'नई वीडियो बैठक निर्धारित करें',
              ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Create virtual conference rooms and invite citizens or karyakartas',
                mr: 'व्हर्च्युअल कॉन्फरन्स रूम तयार करा आणि नागरिक किंवा कार्यकर्त्यांना आमंत्रित करा',
                hi: 'वर्चुअल कॉन्फ़्रेंस रूम बनाएं और नागरिकों या कार्यकर्ताओं को आमंत्रित करें',
              ),
              icon: Icons.video_call_rounded,
              width: 520,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(
                  ctx,
                  text: AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                ),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: AppTranslations.pick(
                    lang,
                    en: 'Create Meeting',
                    mr: 'बैठक तयार करा',
                    hi: 'बैठक बनाएं',
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) {
                      setDlgState(() {
                        titleError = AppTranslations.pick(
                          lang,
                          en: 'Please enter a meeting subject',
                          mr: 'कृपया बैठकीचा विषय प्रविष्ट करा',
                          hi: 'कृपया बैठक का विषय दर्ज करें',
                        );
                      });
                      return;
                    }
                    final slug = titleCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
                    final newM = MeetingItem(
                      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      meetLink: 'https://meet.jit.si/nagarsevak-${slug.isEmpty ? DateTime.now().millisecondsSinceEpoch : slug}',
                      scheduledAt: selectedDate,
                      status: 'scheduled',
                      invitedCount: 0,
                    );
                    setState(() => _meetings.insert(0, newM));
                    Navigator.pop(ctx);
                  },
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Meeting Subject / Title:',
                      mr: 'बैठकीचा विषय / शीर्षक:',
                      hi: 'बैठक का विषय / शीर्षक:',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    onChanged: (_) {
                      if (titleError != null) {
                        setDlgState(() => titleError = null);
                      }
                    },
                    decoration: desktopInputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Ward Citizen Interaction',
                        mr: 'उदा. प्रभाग नागरिक संवाद बैठक',
                        hi: 'उदा. वार्ड नागरिक संवाद बैठक',
                      ),
                      errorText: titleError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.pick(lang, en: 'Date & Time:', mr: 'दिनांक व वेळ:', hi: 'दिनांक और समय:'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.formatDateTime(selectedDate, lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (d != null && ctx.mounted) {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: TimeOfDay.fromDateTime(selectedDate),
                              );
                              if (t != null) {
                                setDlgState(() {
                                  selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                          label: Text(AppTranslations.pick(lang, en: 'Change', mr: 'बदला', hi: 'बदलें')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

    final totalMeetings = _meetings.length;
    final activeMeetings = _meetings.where((m) => m.status == 'active' || m.status == 'scheduled').length;
    final totalInvited = _meetings.fold<int>(0, (sum, m) => sum + m.invitedCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.video_call_rounded, color: AppColors.brandPrimary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'Conference Room', mr: 'कॉन्फरन्स रूम', hi: 'कॉन्फ़्रेंस रूम'),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Host secure virtual townhalls and committee conferences with instant WhatsApp invitations',
                                mr: 'त्वरित WhatsApp आमंत्रणांसह सुरक्षित व्हर्च्युअल जनसंवाद आणि समिती बैठका आयोजित करा',
                                hi: 'तुरंत WhatsApp निमंत्रण के साथ सुरक्षित वर्चुअल जनसंवाद और समिति बैठकें आयोजित करें',
                              ),
                              style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Download Report matching ConferenceRoom.tsx
                    OutlinedButton.icon(
                      onPressed: () {
                        final mapped = _meetings.map<ConferenceMeetingModel>((m) => ConferenceMeetingModel(
                          id: m.id,
                          title: m.title,
                          meetLink: m.meetLink,
                          scheduledAt: m.scheduledAt,
                          status: m.status,
                          invitedCount: m.invitedCount,
                          createdAt: DateTime.now(),
                        )).toList();
                        ConferenceMeetingReportGenerator.generateAndPrintMeetingReport(
                          context: context,
                          meetings: mapped,
                          lang: lang,
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: Text(
                        AppTranslations.getDownloadReport(lang),
                        style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F9FF),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _openCreateMeetingDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            AppTranslations.pick(lang, en: 'Schedule Meeting', mr: 'बैठक ठरवा', hi: 'बैठक तय करें'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3 Stat Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    AppTranslations.pick(lang, en: 'Total Meetings', mr: 'एकूण बैठका', hi: 'कुल बैठकें'),
                    AppTranslations.formatDigits(totalMeetings, lang),
                    Icons.event_available_rounded,
                    AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    AppTranslations.pick(lang, en: 'Scheduled / Active', mr: 'नियोजित / सुरू', hi: 'निर्धारित / सक्रिय'),
                    AppTranslations.formatDigits(activeMeetings, lang),
                    Icons.video_camera_front_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    AppTranslations.pick(lang, en: 'Total Invited', mr: 'एकूण आमंत्रित', hi: 'कुल आमंत्रित'),
                    AppTranslations.formatDigits(totalInvited, lang),
                    Icons.people_alt_rounded,
                    Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Meetings Grid (3 Columns)
            Text(
              AppTranslations.pick(lang, en: 'All Video Conferences', mr: 'सर्व व्हिडिओ कॉन्फरन्स', hi: 'सभी वीडियो कॉन्फ़्रेंस'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800),
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: DesktopResponsive.of(context).gridColumns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 220,
              ),
              itemCount: _visibleMeetings.length,
              itemBuilder: (ctx, i) {
                final m = _visibleMeetings[i];
                final isActive = m.status == 'active';
                final isScheduled = m.status == 'scheduled';
                final invitedFormatted = AppTranslations.formatDigits(m.invitedCount, lang);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? Colors.green.shade400 : AppColors.slate200,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : isScheduled
                                      ? AppColors.brandPrimary.withValues(alpha: 0.1)
                                      : AppColors.slate100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                if (isActive) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  isActive
                                      ? AppTranslations.pick(lang, en: 'LIVE NOW', mr: 'थेट सुरू', hi: 'लाइव चालू')
                                      : isScheduled
                                          ? AppTranslations.pick(lang, en: 'SCHEDULED', mr: 'नियोजित', hi: 'निर्धारित')
                                          : AppTranslations.pick(lang, en: 'ENDED', mr: 'संपलेली', hi: 'समाप्त'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.green
                                        : isScheduled
                                            ? AppColors.brandPrimary
                                            : AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: '$invitedFormatted invited',
                              mr: '$invitedFormatted आमंत्रित',
                              hi: '$invitedFormatted आमंत्रित',
                            ),
                            style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      AppTranslatedText(
                        m.title,
                        targetLanguage: lang,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: AppColors.slate400),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslations.formatDateTime(m.scheduledAt, lang),
                            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.slate600),
                            tooltip: AppTranslations.pick(lang, en: 'Copy Link', mr: 'लिंक कॉपी करा', hi: 'लिंक कॉपी करें'),
                            onPressed: () => _copyLink(m.meetLink, lang),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive ? Colors.green : AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _launchUrl(m.meetLink),
                              icon: const Icon(Icons.video_call_rounded, size: 16),
                              label: Text(
                                isActive
                                    ? AppTranslations.pick(lang, en: 'Join Now', mr: 'आता सामील व्हा', hi: 'अभी जुड़ें')
                                    : AppTranslations.pick(lang, en: 'Open Room', mr: 'रूम उघडा', hi: 'रूम खोलें'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_meetings.isNotEmpty)
              AppLoadMoreFooter(
                currentCount: _visibleMeetings.length,
                totalCount: _meetings.length,
                pageSize: 20,
                onLoadMore: () {
                  setState(() => _displayedLimit += 20);
                },
                label: AppTranslations.pick(lang, en: 'meetings', mr: 'बैठका', hi: 'बैठकें'),
                isMarathi: lang == 'mr',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            ],
          ),
        ],
      ),
    );
  }
}
