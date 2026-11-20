import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';

Widget createComplaintVideoPlayer({
  required String url,
  String type = 'video/mp4',
  double height = 110,
}) {
  return _ComplaintVideoPlayerStub(
    url: url,
    type: type,
    height: height,
  );
}

class _ComplaintVideoPlayerStub extends StatelessWidget {
  final String url;
  final String type;
  final double height;

  const _ComplaintVideoPlayerStub({
    required this.url,
    required this.type,
    required this.height,
  });

  Future<void> _playVideo(BuildContext context) async {
    String finalUrl = url.trim();
    if (!finalUrl.startsWith('http://') &&
        !finalUrl.startsWith('https://') &&
        !finalUrl.startsWith('blob:') &&
        !finalUrl.startsWith('data:')) {
      finalUrl = await SupabaseService.instance.getSignedStorageUrl(finalUrl, bucket: 'documents');
    }

    final uri = Uri.tryParse(finalUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open video player')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _playVideo(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Play Icon Button
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),

            // Bottom Player Control Bar matching HTML5 video player in screenshot
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      '0:00',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.volume_up_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
