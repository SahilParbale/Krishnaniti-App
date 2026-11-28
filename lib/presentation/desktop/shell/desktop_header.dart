import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/language_provider.dart';
import '../common/desktop_responsive.dart';

class DesktopHeader extends ConsumerWidget {
  final VoidCallback onOpenCommandPalette;
  final VoidCallback onNewComplaint;

  const DesktopHeader({
    super.key,
    required this.onOpenCommandPalette,
    required this.onNewComplaint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeKey = ref.watch(activeScreenProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final activeTitle = AppTranslations.getNavTitle(activeKey, currentLang);
    final now = DateTime.now();
    final String nowFormatted;
    if (currentLang == 'mr') {
      const weekdays = {1: 'सोमवार', 2: 'मंगळवार', 3: 'बुधवार', 4: 'गुरुवार', 5: 'शुक्रवार', 6: 'शनिवार', 7: 'रविवार'};
      const months = {1: 'जानेवारी', 2: 'फेब्रुवारी', 3: 'मार्च', 4: 'एप्रिल', 5: 'मे', 6: 'जून', 7: 'जुलै', 8: 'ऑगस्ट', 9: 'सप्टेंबर', 10: 'ऑक्टोबर', 11: 'नोव्हेंबर', 12: 'डिसेंबर'};
      nowFormatted = '${weekdays[now.weekday]}, ${AppTranslations.formatDigits(now.day, currentLang)} ${months[now.month]} ${AppTranslations.formatDigits(now.year, currentLang)}';
    } else if (currentLang == 'hi') {
      const weekdays = {1: 'सोमवार', 2: 'मंगलवार', 3: 'बुधवार', 4: 'गुरुवार', 5: 'शुक्रवार', 6: 'शनिवार', 7: 'रविवार'};
      const months = {1: 'जनवरी', 2: 'फ़रवरी', 3: 'मार्च', 4: 'अप्रैल', 5: 'मई', 6: 'जून', 7: 'जुलाई', 8: 'अगस्त', 9: 'सितंबर', 10: 'अक्टूबर', 11: 'नवंबर', 12: 'दिसंबर'};
      nowFormatted = '${weekdays[now.weekday]}, ${AppTranslations.formatDigits(now.day, currentLang)} ${months[now.month]} ${AppTranslations.formatDigits(now.year, currentLang)}';
    } else {
      nowFormatted = DateFormat('EEEE, d MMMM yyyy').format(now);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final r = DesktopResponsive.of(context);
        final isVeryCompact = r.width < 1024;
        return Container(
          height: r.headerHeight,
          padding: EdgeInsets.symmetric(horizontal: r.headerPadding),
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
                flex: r.isCompact ? 3 : 4,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeTitle,
                            style: TextStyle(
                              fontSize: r.isCompact ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!r.isCompact)
                            Row(
                              children: [
                                Text(
                                  currentLang == 'mr'
                                      ? 'नगरसेवक पोर्टल'
                                      : (currentLang == 'hi' ? 'नगरसेवक पोर्टल' : 'Nagarsevak Portal'),
                                  style: const TextStyle(
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
                flex: r.isCompact ? 3 : 5,
                child: InkWell(
                  onTap: onOpenCommandPalette,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.slate400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentLang == 'mr'
                                ? 'सर्व मॉड्युल्समध्ये काहीही शोधा...'
                                : (currentLang == 'hi'
                                    ? 'सभी मॉड्यूल में कुछ भी खोजें...'
                                    : 'Search anything across modules...'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate400,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!r.isCompact)
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

              SizedBox(width: r.isCompact ? 10 : 20),

              // 3-Language Selector (EN | MR | HI)
              const AppLanguageSegmentedSelector(isCompact: true),

              SizedBox(width: r.isCompact ? 8 : 14),

              // Action Button: + New Grievance
              if (isVeryCompact)
                Tooltip(
                  message: currentLang == 'mr'
                      ? 'नवीन तक्रार'
                      : (currentLang == 'hi' ? 'नई शिकायत' : 'New Grievance'),
                  child: IconButton(
                    onPressed: onNewComplaint,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brand600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: onNewComplaint,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    currentLang == 'mr'
                        ? '+ नवीन तक्रार'
                        : (currentLang == 'hi' ? '+ नई शिकायत' : '+ New Grievance'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: r.isCompact ? 12 : 16,
                      vertical: 12,
                    ),
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
      },
    );
  }
}
