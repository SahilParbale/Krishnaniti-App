import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../providers/language_provider.dart';

class DesktopMediaTrackingView extends ConsumerWidget {
  const DesktopMediaTrackingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(desktopLanguageProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
      child: Center(
        child: Container(
          width: 680,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Pulse Globe Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: const Icon(
                  Icons.public,
                  size: 64,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Media Tracking',
                  mr: 'माध्यम मागोवा',
                  hi: 'मीडिया ट्रैकिंग',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Live media sentiment and news monitoring dashboard operating in secure local workstation mode.',
                  mr: 'सुरक्षित स्थानिक वर्कस्टेशन मोडमध्ये कार्यरत थेट मीडिया भावना आणि बातम्या देखरेख डॅशबोर्ड.',
                  hi: 'सुरक्षित स्थानीय वर्कस्टेशन मोड में कार्यरत लाइव मीडिया भावना और समाचार निगरानी डैशबोर्ड।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Amber Security Notice Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 20, color: Color(0xFFD97706)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'SECURITY NOTICE',
                              mr: 'सुरक्षा सूचना',
                              hi: 'सुरक्षा सूचना',
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'In accordance with security policies, media analytics operate on authorized administrative workstations. Contact system admin for external API connectors.',
                              mr: 'सुरक्षा धोरणांनुसार, मीडिया विश्लेषण अधिकृत प्रशासकीय वर्कस्टेशन्सवर कार्य करते. बाह्य API कनेक्टर्ससाठी सिस्टम प्रशासकाशी संपर्क साधा.',
                              hi: 'सुरक्षा नीतियों के अनुसार, मीडिया विश्लेषण अधिकृत प्रशासनिक वर्कस्टेशन पर संचालित होता है। बाहरी API कनेक्टर के लिए सिस्टम एडमिन से संपर्क करें।',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB45309),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
