import 'package:flutter/material.dart';
import 'complaint_video_player_stub.dart'
    if (dart.library.html) 'complaint_video_player_web.dart';

Widget buildComplaintVideoPlayer({
  required String url,
  String type = 'video/mp4',
  double height = 160,
}) {
  return createComplaintVideoPlayer(
    url: url,
    type: type,
    height: height,
  );
}
