import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_translations.dart';

const String _kLanguagePrefKey = 'ns_app_language';

/// Global ValueNotifier kept in sync with [appLanguageProvider] so even
/// non-Consumer widgets or tests without a ProviderScope stay safe and reactive.
final ValueNotifier<String> appLanguageValueNotifier = ValueNotifier<String>('en');

class AppLanguageNotifier extends Notifier<String> {
  @override
  String build() {
    appLanguageValueNotifier.value = 'en';
    _loadPersistedLanguage();
    return 'en';
  }

  Future<void> _loadPersistedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLanguagePrefKey);
      if (saved != null && (saved == 'en' || saved == 'mr' || saved == 'hi')) {
        state = saved;
        appLanguageValueNotifier.value = saved;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    if (lang != 'en' && lang != 'mr' && lang != 'hi') return;
    state = lang;
    appLanguageValueNotifier.value = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguagePrefKey, lang);
    } catch (_) {}
  }

  void cycleLanguage() {
    if (state == 'en') {
      setLanguage('mr');
    } else if (state == 'mr') {
      setLanguage('hi');
    } else {
      setLanguage('en');
    }
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, String>(AppLanguageNotifier.new);

final isHindiProvider = Provider<bool>((ref) => ref.watch(appLanguageProvider) == 'hi');

/// Language state notifier for desktop UI
class DesktopLanguageNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(appLanguageProvider);
  }

  void setLanguage(String lang) {
    ref.read(appLanguageProvider.notifier).setLanguage(lang);
    state = lang;
  }
}

final desktopLanguageProvider =
    NotifierProvider<DesktopLanguageNotifier, String>(DesktopLanguageNotifier.new);

/// Helpful language extensions
extension LanguageProviderX on WidgetRef {
  String get lang => watch(appLanguageProvider);
  bool get isMarathi => lang == 'mr';
  bool get isHindi => lang == 'hi';
  bool get isEnglish => lang == 'en';

  String tr3(String en, String mr, String hi) =>
      AppTranslations.pick(lang, en: en, mr: mr, hi: hi);

  String tKey(String key, {Map<String, dynamic>? params}) =>
      AppTranslations.t(key, lang: lang, params: params);

  String fmtNum(dynamic value) => AppTranslations.formatDigits(value, lang);

  String fmtDate(DateTime dt, {String pattern = 'dd MMM yyyy'}) =>
      AppTranslations.formatDate(dt, lang, pattern: pattern);
}

/// Language Selector Segmented Widget for Desktop & Mobile
class AppLanguageSegmentedSelector extends ConsumerWidget {
  final bool isCompact;
  const AppLanguageSegmentedSelector({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(ref, 'en', 'EN', 'English', currentLang == 'en'),
          _buildItem(ref, 'mr', 'मराठी', 'मराठी (Marathi)', currentLang == 'mr'),
          _buildItem(ref, 'hi', 'हिंदी', 'हिंदी (Hindi)', currentLang == 'hi'),
        ],
      ),
    );
  }

  Widget _buildItem(
    WidgetRef ref,
    String code,
    String label,
    String fullLabel,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(code),
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: fullLabel,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 14,
            vertical: isCompact ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11.5 : 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
