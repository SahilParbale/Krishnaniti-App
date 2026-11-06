import 'package:flutter/material.dart';

class MediaTrackingArticleModel {
  final String id;
  final String title;
  final String titleMarathi;
  final String source; // 'ABP Majha Online', 'TV9 Marathi Web', 'Lokmat News18', etc.
  final String sourceType; // 'portal' | 'tv_web' | 'social_web' | 'e_paper'
  final String date;
  final String time;
  final String sentiment; // 'positive' | 'negative' | 'neutral'
  final String personTracked; // 'Amit Chougale (नगरसेवक)', 'Prabhag 12 Development', etc.
  final String url;
  final String summary;
  final String summaryMarathi;
  final int reachEstimate;
  final bool isSavedToClipping;
  final List<String> keywords;

  const MediaTrackingArticleModel({
    required this.id,
    required this.title,
    required this.titleMarathi,
    required this.source,
    required this.sourceType,
    required this.date,
    required this.time,
    required this.sentiment,
    required this.personTracked,
    required this.url,
    required this.summary,
    required this.summaryMarathi,
    required this.reachEstimate,
    this.isSavedToClipping = false,
    this.keywords = const [],
  });

  bool get isPositive => sentiment.toLowerCase() == 'positive';
  bool get isNegative => sentiment.toLowerCase() == 'negative';

  Color get sentimentColor {
    if (isPositive) return const Color(0xFF16A34A);
    if (isNegative) return const Color(0xFFDC2626);
    return const Color(0xFF0284C7);
  }

  Color get sentimentBgColor {
    if (isPositive) return const Color(0xFFDCFCE7);
    if (isNegative) return const Color(0xFFFEE2E2);
    return const Color(0xFFE0F2FE);
  }

  String get sentimentLabelMarathi {
    if (isPositive) return 'सकारात्मक कव्हरेज';
    if (isNegative) return 'दखलपात्र समस्या';
    return 'तटस्थ बातमी';
  }

  String get sentimentLabelEnglish {
    if (isPositive) return 'Positive Coverage';
    if (isNegative) return 'Critical Issue';
    return 'Neutral Report';
  }

  Color get sourceBrandColor {
    final lower = source.toLowerCase();
    if (lower.contains('abp')) return const Color(0xFFE11D48);
    if (lower.contains('tv9')) return const Color(0xFF0284C7);
    if (lower.contains('lokmat')) return const Color(0xFFDC2626);
    if (lower.contains('sakal')) return const Color(0xFF0369A1);
    if (lower.contains('maharashtra times') || lower.contains('mt')) return const Color(0xFFEA580C);
    if (lower.contains('zee')) return const Color(0xFF9333EA);
    if (lower.contains('twitter') || lower.contains('x')) return const Color(0xFF0F172A);
    return const Color(0xFF475569);
  }

  IconData get sourceIcon {
    switch (sourceType.toLowerCase()) {
      case 'tv_web':
        return Icons.live_tv_rounded;
      case 'social_web':
        return Icons.share_rounded;
      case 'e_paper':
        return Icons.newspaper_rounded;
      case 'portal':
      default:
        return Icons.language_rounded;
    }
  }

  MediaTrackingArticleModel copyWith({
    String? id,
    String? title,
    String? titleMarathi,
    String? source,
    String? sourceType,
    String? date,
    String? time,
    String? sentiment,
    String? personTracked,
    String? url,
    String? summary,
    String? summaryMarathi,
    int? reachEstimate,
    bool? isSavedToClipping,
    List<String>? keywords,
  }) {
    return MediaTrackingArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleMarathi: titleMarathi ?? this.titleMarathi,
      source: source ?? this.source,
      sourceType: sourceType ?? this.sourceType,
      date: date ?? this.date,
      time: time ?? this.time,
      sentiment: sentiment ?? this.sentiment,
      personTracked: personTracked ?? this.personTracked,
      url: url ?? this.url,
      summary: summary ?? this.summary,
      summaryMarathi: summaryMarathi ?? this.summaryMarathi,
      reachEstimate: reachEstimate ?? this.reachEstimate,
      isSavedToClipping: isSavedToClipping ?? this.isSavedToClipping,
      keywords: keywords ?? this.keywords,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleMarathi': titleMarathi,
      'source': source,
      'sourceType': sourceType,
      'date': date,
      'time': time,
      'sentiment': sentiment,
      'personTracked': personTracked,
      'url': url,
      'summary': summary,
      'summaryMarathi': summaryMarathi,
      'reachEstimate': reachEstimate,
      'isSavedToClipping': isSavedToClipping,
      'keywords': keywords,
    };
  }

  factory MediaTrackingArticleModel.fromJson(Map<String, dynamic> json) {
    return MediaTrackingArticleModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      titleMarathi: json['titleMarathi'] ?? '',
      source: json['source'] ?? 'Online Portal',
      sourceType: json['sourceType'] ?? 'portal',
      date: json['date'] ?? '',
      time: json['time'] ?? '12:00 PM',
      sentiment: json['sentiment'] ?? 'positive',
      personTracked: json['personTracked'] ?? 'Amit Chougale',
      url: json['url'] ?? 'https://news.google.com',
      summary: json['summary'] ?? '',
      summaryMarathi: json['summaryMarathi'] ?? '',
      reachEstimate: (json['reachEstimate'] as num?)?.toInt() ?? 10000,
      isSavedToClipping: json['isSavedToClipping'] ?? false,
      keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class TrackingProfileModel {
  final String id;
  final String name;
  final String nameMarathi;
  final String category;
  final String query;
  final int mentionsCount;

  const TrackingProfileModel({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.category,
    required this.query,
    required this.mentionsCount,
  });
}

class TelemetryLogEntry {
  final String timestamp;
  final String portal;
  final String message;
  final String status; // 'scanning' | 'found' | 'completed'

  const TelemetryLogEntry({
    required this.timestamp,
    required this.portal,
    required this.message,
    required this.status,
  });
}

