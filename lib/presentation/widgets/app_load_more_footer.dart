import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../providers/language_provider.dart';

class AppLoadMoreFooter extends StatelessWidget {
  final int currentCount;
  final int totalCount;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final int pageSize;
  final String label;
  final bool isMarathi;

  const AppLoadMoreFooter({
    super.key,
    required this.currentCount,
    required this.totalCount,
    required this.onLoadMore,
    this.isLoading = false,
    this.pageSize = 20,
    this.label = 'records',
    this.isMarathi = false,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, activeLang, _) {
        final lang = (activeLang == 'en' && isMarathi) ? 'mr' : activeLang;
        final hasMore = currentCount < totalCount;
        final remaining = max(0, totalCount - currentCount);
        final nextBatch = min(pageSize, remaining);

        final locTotal = AppTranslations.formatDigits(totalCount, lang);
        final locCurrent = AppTranslations.formatDigits(currentCount, lang);
        final locRemaining = AppTranslations.formatDigits(remaining, lang);
        final locNext = AppTranslations.formatDigits(nextBatch, lang);
        final locLabel = _translateRecordLabel(label, lang);

        if (!hasMore) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 28, height: 1, color: const Color(0xFFCBD5E1)),
                const SizedBox(width: 10),
                const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'All $locTotal $locLabel loaded',
                      mr: 'सर्व $locTotal $locLabel दाखवले आहेत',
                      hi: 'सभी $locTotal $locLabel दिखाए गए हैं',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 28, height: 1, color: const Color(0xFFCBD5E1)),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Showing $locCurrent of $locTotal $locLabel',
                        mr: '$locTotal पैकी $locCurrent $locLabel दाखवत आहे',
                        hi: '$locTotal में से $locCurrent $locLabel दिखाए जा रहे हैं',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: '$locRemaining remaining',
                        mr: '$locRemaining शिल्लक',
                        hi: '$locRemaining शेष',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onLoadMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: Text(
                    isLoading
                        ? AppTranslations.pick(lang, en: 'Loading...', mr: 'लोड होत आहे...', hi: 'लोड हो रहा है...')
                        : AppTranslations.pick(
                            lang,
                            en: 'Load Next $locNext $locLabel',
                            mr: 'पुढील $locNext $locLabel दाखवा',
                            hi: 'अगले $locNext $locLabel दिखाएं',
                          ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _translateRecordLabel(String raw, String lang) {
    final lower = raw.trim().toLowerCase();
    const map = {
      'records': ('records', 'नोंदी', 'रिकॉर्ड'),
      'नोंदी': ('records', 'नोंदी', 'रिकॉर्ड'),
      'complaints': ('complaints', 'तक्रारी', 'शिकायतें'),
      'तक्रारी': ('complaints', 'तक्रारी', 'शिकायतें'),
      'letters': ('letters', 'पत्रे', 'पत्र'),
      'पत्रे': ('letters', 'पत्रे', 'पत्र'),
      'events': ('events', 'कार्यक्रम', 'कार्यक्रम'),
      'कार्यक्रम': ('events', 'कार्यक्रम', 'कार्यक्रम'),
      'photos': ('photos', 'छायाचित्रे', 'तस्वीरें'),
      'छायाचित्रे': ('photos', 'छायाचित्रे', 'तस्वीरें'),
      'offices': ('offices', 'कार्यालये', 'कार्यालय'),
      'कार्यालये': ('offices', 'कार्यालये', 'कार्यालय'),
      'workers': ('workers', 'कर्मचारी', 'कर्मचारी'),
      'कर्मचारी': ('workers', 'कर्मचारी', 'कर्मचारी'),
      'voters': ('voters', 'मतदार', 'मतदाता'),
      'मतदार': ('voters', 'मतदार', 'मतदाता'),
      'entries': ('entries', 'नोंदी', 'प्रविष्टियाँ'),
      'tasks': ('tasks', 'कामे', 'कार्य'),
      'visitors': ('visitors', 'भेटी', 'आगंतुक'),
      'schemes': ('schemes', 'योजना', 'योजनाएं'),
      'members': ('members', 'सदस्य', 'सदस्य'),
      'surveys': ('surveys', 'सर्वेक्षणे', 'सर्वेक्षण'),
      'proposals': ('proposals', 'प्रस्ताव', 'प्रस्ताव'),
      'problems': ('problems', 'समस्या', 'समस्याएं'),
      'items': ('items', 'घटक', 'आइटम'),
      'works': ('works', 'कामे', 'कार्य'),
    };
    if (map.containsKey(lower)) {
      final entry = map[lower]!;
      return AppTranslations.pick(lang, en: entry.$1, mr: entry.$2, hi: entry.$3);
    }
    return AppTranslations.translateDirect(raw, lang: lang);
  }
}
