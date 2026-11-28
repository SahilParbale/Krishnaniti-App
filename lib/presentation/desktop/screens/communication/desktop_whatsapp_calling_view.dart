import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/desktop_responsive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/models/whatsapp_broadcast_model.dart';
import '../../../../data/repositories/whatsapp_repository.dart';
import '../../shell/desktop_sidebar.dart';
import '../../../screens/whatsapp/whatsapp_history_report_generator.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopWhatsappCallingView extends ConsumerStatefulWidget {
  const DesktopWhatsappCallingView({super.key});

  @override
  ConsumerState<DesktopWhatsappCallingView> createState() => _DesktopWhatsappCallingViewState();
}

class _DesktopWhatsappCallingViewState extends ConsumerState<DesktopWhatsappCallingView> {
  String _activeTab = 'call'; // 'call' | 'history'
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<VoterModel> _voters = [];
  int _displayedLimit = 20;
  List<VoterModel> get _visibleVoters =>
      _voters.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() {
      _displayedLimit = 20;
      _isLoading = true;
    });
    try {
      final repo = ref.read(whatsAppRepoProvider);
      final normalizedSearch = AppTranslations.normalizeAsciiDigits(_searchController.text.trim());
      final voters = await repo.getVotersWithMobile(
        name: normalizedSearch.isEmpty ? null : normalizedSearch,
      );
      if (mounted) {
        setState(() {
          _voters = voters;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWaCall(String? mobile) async {
    if (mobile == null || mobile.trim().isEmpty) return;
    final clean = AppTranslations.normalizeAsciiDigits(mobile).replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

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
                          color: AppColors.brand50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.brand600, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'WhatsApp Call', mr: 'WhatsApp कॉल', hi: 'WhatsApp कॉल'),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Initiate direct WhatsApp voice calling with key ward constituents',
                                mr: 'प्रभागातील प्रमुख नागरिकांशी थेट WhatsApp व्हॉइस कॉलिंग सुरू करा',
                                hi: 'वार्ड के प्रमुख नागरिकों के साथ सीधे WhatsApp वॉइस कॉल शुरू करें',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.brand200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brand600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Calling Gateway Ready',
                              mr: 'कॉलिंग गेटवे सज्ज',
                              hi: 'कॉलिंग गेटवे तैयार',
                            ),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Download Report matching WhatsAppCalling.tsx
                    OutlinedButton.icon(
                      onPressed: () {
                        final logs = _voters.map((v) => WhatsAppBroadcastModel(
                          id: 'wacall-${v.id}',
                          title: 'WhatsApp Call - ${v.displayNameFor(lang)}',
                          message: 'WhatsApp voice call outreach record for Ward 12 constituency.',
                          sentAt: DateTime.now(),
                          channel: 'whatsapp',
                          recipients: 1,
                          sentCount: 1,
                          deliveredCount: 1,
                          failedCount: 0,
                          status: 'COMPLETED',
                          targetCriteria: v.address,
                          category: 'WhatsApp Voice Call',
                        )).toList();
                        WhatsAppHistoryReportGenerator.generateAndPrintReport(
                          context: context,
                          broadcasts: logs,
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
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    'call',
                    AppTranslations.pick(lang, en: 'Make Call', mr: 'कॉल करा', hi: 'कॉल करें'),
                    Icons.phone_forwarded_rounded,
                  ),
                  _buildTabButton(
                    'history',
                    AppTranslations.pick(lang, en: 'Call History', mr: 'कॉल इतिहास', hi: 'कॉल इतिहास'),
                    Icons.history_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_activeTab == 'call') ...[
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Search voter by name or mobile...',
                      mr: 'नाव किंवा मोबाईलद्वारे मतदार शोधा...',
                      hi: 'नाम या मोबाइल से मतदाता खोजें...',
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (_) => _loadVoters(),
                ),
              ),
              const SizedBox(height: 20),

              // 3-Column Grid of Voters
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (_voters.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      AppTranslations.pick(lang, en: 'No voters found', mr: 'कोणतेही मतदार आढळले नाहीत', hi: 'कोई मतदाता नहीं मिला'),
                      style: const TextStyle(color: AppColors.slate400),
                    ),
                  ),
                )
              else ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: DesktopResponsive.of(context).gridColumns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 170,
                  ),
                  itemCount: _visibleVoters.length,
                  itemBuilder: (ctx, i) {
                    final v = _visibleVoters[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.brand50,
                                child: const Icon(Icons.person, color: AppColors.brand600, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTranslatedText(
                                      v.displayNameFor(lang),
                                      isName: true,
                                      targetLanguage: lang,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppTranslations.formatDigits(v.mobile ?? '-', lang),
                                      style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          AppTranslatedText(
                            v.address,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brand50,
                                foregroundColor: AppColors.brand700,
                                elevation: 0,
                                side: const BorderSide(color: AppColors.brand200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _launchWaCall(v.mobile),
                              icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                              label: Text(
                                AppTranslations.pick(lang, en: 'WhatsApp Call', mr: 'WhatsApp कॉल', hi: 'WhatsApp कॉल'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                AppLoadMoreFooter(
                  currentCount: _visibleVoters.length,
                  totalCount: _voters.length,
                  pageSize: 20,
                  onLoadMore: () {
                    setState(() => _displayedLimit += 20);
                  },
                  label: 'voters',
                  isMarathi: lang == 'mr',
                ),
              ],
            ] else ...[
              // History Tab
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.pick(lang, en: 'WhatsApp Call History', mr: 'WhatsApp कॉल इतिहास', hi: 'WhatsApp कॉल इतिहास'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'No call logs recorded yet',
                            mr: 'अद्याप कोणत्याही कॉल नोंदी नाहीत',
                            hi: 'अभी तक कोई कॉल लॉग दर्ज नहीं है',
                          ),
                          style: const TextStyle(color: AppColors.slate400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return InkWell(
      onTap: () => setState(() => _activeTab = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.brand600 : AppColors.slate500),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.brand600 : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
