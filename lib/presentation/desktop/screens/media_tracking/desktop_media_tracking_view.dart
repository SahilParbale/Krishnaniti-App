import 'package:flutter/material.dart';

class DesktopMediaTrackingView extends StatelessWidget {
  const DesktopMediaTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
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
              const Text(
                'Media Tracking',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              const Text(
                'Live media sentiment and news monitoring dashboard operating in secure local workstation mode.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                  children: const [
                    Icon(Icons.shield_outlined, size: 20, color: Color(0xFFD97706)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SECURITY NOTICE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'In accordance with security policies, media analytics operate on authorized administrative workstations. Contact system admin for external API connectors.',
                            style: TextStyle(
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
