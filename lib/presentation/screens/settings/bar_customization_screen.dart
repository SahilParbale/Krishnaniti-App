import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_translations.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/custom_navigation_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';

/// Standalone Bar Customization Screen
/// Accessible directly from App Drawer, Radial Quick Menu, or Settings.
/// Ensures team members only see permitted features for customization,
/// and synchronizes selections directly to the Supabase database.
class BarCustomizationScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onTabChange;

  const BarCustomizationScreen({super.key, this.onTabChange});

  @override
  ConsumerState<BarCustomizationScreen> createState() => _BarCustomizationScreenState();
}

class _BarCustomizationScreenState extends ConsumerState<BarCustomizationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final user = ref.watch(currentUserProvider);
    final isStaff = user?.isStaff ?? false;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: NagarsevakAppDrawer(
        currentTabIndex: 3,
        onTabChange: widget.onTabChange,
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          tooltip: AppTranslations.pick(lang, en: 'Toggle Menu', mr: 'मेनू उघडा', hi: 'मेनू खोलें'),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              _scaffoldKey.currentState?.closeDrawer();
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppTranslations.pick(
                lang,
                en: 'Bar Customization',
                mr: 'नेव्हिगेशन सानुकूलन',
                hi: 'नेविगेशन अनुकूलन',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              isStaff
                  ? AppTranslations.pick(
                      lang,
                      en: 'Staff Personal Quick Shortcuts',
                      mr: 'कर्मचारी द्रुत शॉर्टकट',
                      hi: 'स्टाफ व्यक्तिगत त्वरित शॉर्टकट',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Bottom Bar & Radial Quick Access',
                      mr: 'बॉटम बार व द्रुत क्रिया मेनू',
                      hi: 'बॉटम बार और त्वरित क्रिया मेनू',
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFE0F2FE)),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Center(child: AppLanguageSegmentedSelector(isCompact: true)),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 90),
        child: BarCustomizationView(),
      ),
    );
  }
}

/// Reusable Bar Customization Content View
/// Embedded both in [BarCustomizationScreen] and [ProfileSettingsScreen].
class BarCustomizationView extends ConsumerStatefulWidget {
  const BarCustomizationView({super.key});

  @override
  ConsumerState<BarCustomizationView> createState() => _BarCustomizationViewState();
}

class _BarCustomizationViewState extends ConsumerState<BarCustomizationView> {
  String _localizedModuleTitle(NavItemConfig item, String lang) {
    final nav = AppTranslations.getNavTitle(item.key, lang);
    if (nav.trim().isNotEmpty && nav != item.key) return nav;
    return lang == 'mr' ? item.titleMr : item.titleEn;
  }

  void _showModulePicker({
    required BuildContext context,
    required String title,
    required String currentKey,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final lang = ref.watch(appLanguageProvider);
            final permittedList = ref.watch(permittedModulesProvider);
            final filtered = permittedList.where((item) {
              if (query.isEmpty) return true;
              final q = AppTranslations.normalizeAsciiDigits(query).toLowerCase();
              return item.titleEn.toLowerCase().contains(q) ||
                  item.titleMr.toLowerCase().contains(q) ||
                  AppTranslations.getNavTitle(item.key, 'hi').toLowerCase().contains(q) ||
                  item.category.toLowerCase().contains(q) ||
                  AppTranslations.translateDirect(item.category, lang: lang).toLowerCase().contains(q);
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                  // 1. Fixed Header
                  AppModalHeader(
                    icon: Icons.tune_rounded,
                    title: title,
                    subtitle: AppTranslations.formatDigits(
                      AppTranslations.pick(
                        lang,
                        en: 'Select module shortcut (${filtered.length} permitted)',
                        mr: 'प्रणालीमधील विभाग निवडा (${filtered.length} उपलब्ध)',
                        hi: 'मॉड्यूल शॉर्टकट चुनें (${filtered.length} उपलब्ध)',
                      ),
                      lang,
                    ),
                    onClose: () => Navigator.pop(modalCtx),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Search page or module...',
                          mr: 'पर्याय शोधा...',
                          hi: 'पेज या मॉड्यूल खोजें...',
                        ),
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        setModalState(() => query = v);
                      },
                    ),
                  ),

                  const Divider(height: 12),

                  // Module List
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 40, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 10),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'No permitted modules match your search.',
                                      mr: 'कोणतेही अनुमती असलेले पर्याय उपलब्ध नाहीत.',
                                      hi: 'आपकी खोज से मेल खाने वाला कोई मॉड्यूल उपलब्ध नहीं है।',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 50),
                            itemBuilder: (c, idx) {
                              final item = filtered[idx];
                              final isCurrent = item.key == currentKey;
                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                tileColor: isCurrent ? const Color(0xFFE0F2FE) : null,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isCurrent ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: isCurrent ? Colors.white : const Color(0xFF0284C7),
                                    size: 19,
                                  ),
                                ),
                                title: Text(
                                  _localizedModuleTitle(item, lang),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                    color: isCurrent ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  AppTranslations.translateDirect(item.category, lang: lang),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                trailing: isCurrent
                                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 18)
                                    : const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(modalCtx);
                                  onSelected(item.key);
                                },
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final user = ref.watch(currentUserProvider);
    final isStaff = user?.isStaff ?? false;
    final permittedModules = ref.watch(permittedModulesProvider);
    final bottomSlots = ref.watch(customBottomBarProvider);
    final quickSlots = ref.watch(customQuickActionsProvider);
    final modLen = AppTranslations.formatDigits(permittedModules.length, lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─────────────────────────────────────────────────────────────
        // HEADER GRADIENT BANNER
        // ─────────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260284C7),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isStaff
                              ? AppTranslations.pick(
                                  lang,
                                  en: 'Staff Navigation Customization',
                                  mr: 'कर्मचारी नेव्हिगेशन सानुकूलन',
                                  hi: 'स्टाफ नेविगेशन अनुकूलन',
                                )
                              : AppTranslations.pick(
                                  lang,
                                  en: 'Bar & Quick Actions Customization',
                                  mr: 'नेव्हिगेशन आणि द्रुत क्रिया सानुकूलन',
                                  hi: 'बार और त्वरित क्रिया अनुकूलन',
                                ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isStaff
                              ? AppTranslations.formatDigits(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Personalize bottom bar and 5 radial quick gestures from your permitted modules ($modLen accessible).',
                                    mr: 'आपल्या नियुक्त विभागांनुसार ($modLen विभाग उपलब्ध) बॉटम बार आणि 5 द्रुत क्रिया सानुकूल करा.',
                                    hi: 'अपने अनुमत मॉड्यूल ($modLen उपलब्ध) के अनुसार बॉटम बार और 5 त्वरित जेस्चर सेट करें।',
                                  ),
                                  lang,
                                )
                              : AppTranslations.formatDigits(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Personalize your bottom bar tabs and 5 radial quick gestures. Automatically synced to the central database.',
                                    mr: 'आपल्या दैनंदिन कामासाठी बॉटम बार आणि 5 द्रुत क्रिया पर्याय बदला. क्लाउड डेटाबेसमध्ये स्वयंचलित साठवले जाते.',
                                    hi: 'अपने दैनिक कार्य के लिए बॉटम बार टैब और 5 त्वरित क्रियाएँ चुनें। यह स्वचालित रूप से डेटाबेस में सहेजा जाता है।',
                                  ),
                                  lang,
                                ),
                          style: const TextStyle(
                            color: Color(0xFFE0F2FE),
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isStaff) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.white, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Role-Restricted: Only modules permitted for your team account can be chosen.',
                            mr: 'मर्यादित अधिकार मोड: केवळ आपल्याला परवानगी असलेले विभागच पर्यायांमध्ये दिसतील.',
                            hi: 'भूमिका-प्रतिबंधित: केवल आपके टीम खाते के लिए अनुमत मॉड्यूल ही चुने जा सकते हैं।',
                          ),
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─────────────────────────────────────────────────────────────
        // SECTION 1: BOTTOM NAVIGATION BAR (3 CUSTOMIZABLE + 1 FIXED)
        // ─────────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.formatDigits(
                      AppTranslations.pick(
                        lang,
                        en: 'Bottom Navigation Bar (4 Tabs)',
                        mr: 'बॉटम नेव्हिगेशन बार (4 पर्याय)',
                        hi: 'बॉटम नेविगेशन बार (4 टैब)',
                      ),
                      lang,
                    ),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppTranslations.formatDigits(
                      AppTranslations.pick(
                        lang,
                        en: 'First 3 tabs are customizable. Tab 4 (Profile) is fixed.',
                        mr: 'पहिले 3 टॅब बदला. चौथा प्रोफाईल पर्याय कायम निश्चित आहे.',
                        hi: 'पहले 3 टैब बदले जा सकते हैं। टैब 4 (प्रोफ़ाइल) स्थायी है।',
                      ),
                      lang,
                    ),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ref.read(customBottomBarProvider.notifier).resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Bottom bar tabs reset and saved to database.',
                        mr: 'बॉटम बार डीफॉल्टवर रीसेट करून डेटाबेसमध्ये सेव्ह केला.',
                        hi: 'बॉटम बार टैब रीसेट करके डेटाबेस में सहेजे गए।',
                      ),
                    ),
                    backgroundColor: const Color(0xFF0284C7),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.restore_rounded, size: 15, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.pick(lang, en: 'Reset', mr: 'रीसेट', hi: 'रीसेट'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 4 Bottom Bar Slots Preview
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(
              children: [
                for (int slotIdx = 0; slotIdx < 3; slotIdx++) ...[
                  _buildBottomBarSlotTile(
                    slotIndex: slotIdx,
                    moduleKey: bottomSlots[slotIdx],
                    lang: lang,
                  ),
                  if (slotIdx < 2) const Divider(height: 1, indent: 46),
                ],
                const Divider(height: 1, indent: 46),
                // Fixed Slot 4 (Profile)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 20),
                  ),
                  title: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Profile & Account',
                      mr: 'प्रोफाईल व खाती',
                      hi: 'प्रोफ़ाइल और खाता',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  subtitle: Text(
                    AppTranslations.formatDigits(
                      AppTranslations.pick(
                        lang,
                        en: 'Tab 4 (Permanently Fixed)',
                        mr: 'टॅब 4 (कायम निश्चित पर्याय)',
                        hi: 'टैब 4 (स्थायी रूप से निश्चित)',
                      ),
                      lang,
                    ),
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.pick(lang, en: 'Fixed', mr: 'निश्चित', hi: 'निश्चित'),
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        // ─────────────────────────────────────────────────────────────
        // SECTION 2: RADIAL QUICK ACCESS ACTIONS (5 SLOTS)
        // ─────────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.formatDigits(
                      AppTranslations.pick(
                        lang,
                        en: 'Radial Quick Access (5 Slots)',
                        mr: 'द्रुत क्रिया मेनू (5 पर्याय)',
                        hi: 'रेडियल त्वरित पहुँच (5 विकल्प)',
                      ),
                      lang,
                    ),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppTranslations.formatDigits(
                      AppTranslations.pick(
                        lang,
                        en: 'The 5 gesture actions on the semicircular arc track.',
                        mr: 'मध्यवर्ती बटण दाबून धरल्यावर किंवा ओढल्यावर दिसणारे 5 पर्याय.',
                        hi: 'केंद्र बटन दबाकर रखने या स्वाइप करने पर दिखने वाले 5 त्वरित विकल्प।',
                      ),
                      lang,
                    ),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ref.read(customQuickActionsProvider.notifier).resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Quick actions reset and saved to database.',
                        mr: 'द्रुत क्रिया डीफॉल्टवर रीसेट करून डेटाबेसमध्ये सेव्ह केल्या.',
                        hi: 'त्वरित क्रियाएँ रीसेट करके डेटाबेस में सहेजी गईं।',
                      ),
                    ),
                    backgroundColor: const Color(0xFF0284C7),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.restore_rounded, size: 15, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.pick(lang, en: 'Reset', mr: 'रीसेट', hi: 'रीसेट'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 5 Radial Action Slots
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(
              children: [
                for (int slotIdx = 0; slotIdx < 5; slotIdx++) ...[
                  _buildQuickActionSlotTile(
                    slotIndex: slotIdx,
                    moduleKey: quickSlots[slotIdx],
                    lang: lang,
                  ),
                  if (slotIdx < 4) const Divider(height: 1, indent: 46),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Database sync status chip
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_done_rounded, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Saved to Supabase Database (Auto Sync)',
                    mr: 'क्लाउड डेटाबेसशी थेट जोडलेले (Supabase DB)',
                    hi: 'सुपरबेस डेटाबेस में स्वचालित रूप से सहेजा गया',
                  ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBarSlotTile({
    required int slotIndex,
    required String moduleKey,
    required String lang,
  }) {
    final config = getModuleConfig(moduleKey);
    final tabLabel = AppTranslations.formatDigits(
      AppTranslations.pick(
        lang,
        en: 'Tab ${slotIndex + 1}',
        mr: 'टॅब ${slotIndex + 1}',
        hi: 'टैब ${slotIndex + 1}',
      ),
      lang,
    );
    final categoryLabel = AppTranslations.translateDirect(config.category, lang: lang);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(config.icon, color: const Color(0xFF0284C7), size: 20),
      ),
      title: Text(
        _localizedModuleTitle(config, lang),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
      subtitle: Text(
        '$tabLabel • $categoryLabel',
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
      ),
      trailing: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F9FF),
          foregroundColor: const Color(0xFF0284C7),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFBAE6FD)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(60, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          _showModulePicker(
            context: context,
            title: AppTranslations.formatDigits(
              AppTranslations.pick(
                lang,
                en: 'Select Module for Tab ${slotIndex + 1}',
                mr: 'टॅब ${slotIndex + 1} साठी पर्याय निवडा',
                hi: 'टैब ${slotIndex + 1} के लिए मॉड्यूल चुनें',
              ),
              lang,
            ),
            currentKey: moduleKey,
            onSelected: (newKey) {
              ref.read(customBottomBarProvider.notifier).setSlot(slotIndex, newKey);
              final chosenTitle = _localizedModuleTitle(getModuleConfig(newKey), lang);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppTranslations.formatDigits(
                      AppTranslations.pick(
                        lang,
                        en: 'Tab ${slotIndex + 1} updated to "$chosenTitle" and saved to database.',
                        mr: 'टॅब ${slotIndex + 1} "$chosenTitle" वर बदलला व डेटाबेसमध्ये सेव्ह केला.',
                        hi: 'टैब ${slotIndex + 1} "$chosenTitle" पर अपडेट करके डेटाबेस में सहेजा गया।',
                      ),
                      lang,
                    ),
                  ),
                  backgroundColor: const Color(0xFF0284C7),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.edit_rounded, size: 12),
        label: Text(
          AppTranslations.pick(lang, en: 'Change', mr: 'बदला', hi: 'बदलें'),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildQuickActionSlotTile({
    required int slotIndex,
    required String moduleKey,
    required String lang,
  }) {
    final config = getModuleConfig(moduleKey);

    const positionLabelsEn = [
      'Slot 1 • Left Arc (162°)',
      'Slot 2 • Left Upper Arc (126°)',
      'Slot 3 • Top Center Arc (90°)',
      'Slot 4 • Right Upper Arc (54°)',
      'Slot 5 • Right Arc (18°)',
    ];

    const positionLabelsMr = [
      'पर्याय 1 • डावा चाप (162°)',
      'पर्याय 2 • डावा वरील चाप (126°)',
      'पर्याय 3 • मध्य शिखर चाप (90°)',
      'पर्याय 4 • उजवा वरील चाप (54°)',
      'पर्याय 5 • उजवा चाप (18°)',
    ];

    const positionLabelsHi = [
      'स्लॉट 1 • बायाँ चाप (162°)',
      'स्लॉट 2 • बायाँ ऊपरी चाप (126°)',
      'स्लॉट 3 • शीर्ष मध्य चाप (90°)',
      'स्लॉट 4 • दायाँ ऊपरी चाप (54°)',
      'स्लॉट 5 • दायाँ चाप (18°)',
    ];

    final posLabel = AppTranslations.formatDigits(
      AppTranslations.pick(
        lang,
        en: positionLabelsEn[slotIndex],
        mr: positionLabelsMr[slotIndex],
        hi: positionLabelsHi[slotIndex],
      ),
      lang,
    );

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(config.icon, color: const Color(0xFF0284C7), size: 20),
      ),
      title: Text(
        _localizedModuleTitle(config, lang),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
      subtitle: Text(
        posLabel,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
      ),
      trailing: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F9FF),
          foregroundColor: const Color(0xFF0284C7),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFBAE6FD)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(60, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          _showModulePicker(
            context: context,
            title: AppTranslations.formatDigits(
              AppTranslations.pick(
                lang,
                en: 'Select Action for Slot ${slotIndex + 1}',
                mr: 'द्रुत क्रिया ${slotIndex + 1} साठी पर्याय निवडा',
                hi: 'स्लॉट ${slotIndex + 1} के लिए क्रिया चुनें',
              ),
              lang,
            ),
            currentKey: moduleKey,
            onSelected: (newKey) {
              ref.read(customQuickActionsProvider.notifier).setSlot(slotIndex, newKey);
              final chosenTitle = _localizedModuleTitle(getModuleConfig(newKey), lang);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppTranslations.formatDigits(
                      AppTranslations.pick(
                        lang,
                        en: 'Slot ${slotIndex + 1} updated to "$chosenTitle" and saved to database.',
                        mr: 'पर्याय ${slotIndex + 1} "$chosenTitle" वर बदलला व डेटाबेसमध्ये सेव्ह केला.',
                        hi: 'स्लॉट ${slotIndex + 1} "$chosenTitle" पर अपडेट करके डेटाबेस में सहेजा गया।',
                      ),
                      lang,
                    ),
                  ),
                  backgroundColor: const Color(0xFF0284C7),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.edit_rounded, size: 12),
        label: Text(
          AppTranslations.pick(lang, en: 'Change', mr: 'बदला', hi: 'बदलें'),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
