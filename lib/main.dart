import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_translations.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/navigation/adaptive_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Backend
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: NagarsevakApp(),
    ),
  );
}

class NagarsevakApp extends ConsumerWidget {
  const NagarsevakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final lang = ref.watch(appLanguageProvider);

    return MaterialApp(
      title: AppTranslations.pick(
        lang,
        en: 'Nagarsevak Management',
        mr: 'नगरसेवक व्यवस्थापन',
        hi: 'नगरसेवक प्रबंधन',
      ),
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      supportedLocales: const [
        Locale('en'),
        Locale('mr'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const AdaptiveScaffold();
          }
          return const AdaptiveLandingScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, st) => const AdaptiveLandingScreen(),
      ),
    );
  }
}
