import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../core/services/supabase_service.dart';

Widget createComplaintVideoPlayer({
  required String url,
  String type = 'video/mp4',
  double height = 110,
}) {
  return _ComplaintVideoPlayerWeb(
    url: url,
    type: type,
    height: height,
  );
}

class _ComplaintVideoPlayerWeb extends StatefulWidget {
  final String url;
  final String type;
  final double height;

  const _ComplaintVideoPlayerWeb({
    required this.url,
    required this.type,
    required this.height,
  });

  @override
  State<_ComplaintVideoPlayerWeb> createState() => _ComplaintVideoPlayerWebState();
}

class _ComplaintVideoPlayerWebState extends State<_ComplaintVideoPlayerWeb> {
  String? _resolvedUrl;
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    _initVideo();
  }

  Future<void> _initVideo() async {
    String finalUrl = widget.url.trim();
    if (!finalUrl.startsWith('data:') && !finalUrl.startsWith('blob:')) {
      finalUrl = await SupabaseService.instance.getSignedStorageUrl(finalUrl, bucket: 'documents');
    }
    if (mounted) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int id) {
          final video = web.HTMLVideoElement()
            ..src = finalUrl
            ..controls = true
            ..autoplay = false
            ..preload = 'metadata'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'contain'
            ..style.backgroundColor = '#000000'
            ..style.borderRadius = '10px';
          return video;
        },
      );
      setState(() {
        _resolvedUrl = finalUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedUrl == null) {
      return Container(
        height: widget.height,
        color: Colors.black,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
