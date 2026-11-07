import 'package:flutter/material.dart';

enum SocialPlatform {
  facebook,
  instagram,
  twitter,
  youtube,
}

class SocialPostModel {
  final String id;
  final String platform; // 'Facebook' | 'Instagram' | 'Twitter' | 'YouTube'
  final String content;
  final String contentMarathi;
  final String? contentKey;
  final int likes;
  final int comments;
  final int shares;
  final int reach;
  final String date;
  final String? imageUrl;
  final String? postUrl;
  final List<String> tags;
  final String author;

  const SocialPostModel({
    required this.id,
    required this.platform,
    required this.content,
    required this.contentMarathi,
    this.contentKey,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.reach,
    required this.date,
    this.imageUrl,
    this.postUrl,
    this.tags = const [],
    this.author = 'नगरसेवक कार्यालय • प्रभाग १२',
  });

  double get engagementRate {
    if (reach <= 0) return 0.0;
    return ((likes + comments + shares) / reach) * 100;
  }

  Color get platformColor {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'twitter':
      case 'x':
        return const Color(0xFF0F1419);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFF0284C7);
    }
  }

  IconData get platformIcon {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'twitter':
      case 'x':
        return Icons.alternate_email_rounded;
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.share_rounded;
    }
  }

  SocialPostModel copyWith({
    String? id,
    String? platform,
    String? content,
    String? contentMarathi,
    String? contentKey,
    int? likes,
    int? comments,
    int? shares,
    int? reach,
    String? date,
    String? imageUrl,
    String? postUrl,
    List<String>? tags,
    String? author,
  }) {
    return SocialPostModel(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      content: content ?? this.content,
      contentMarathi: contentMarathi ?? this.contentMarathi,
      contentKey: contentKey ?? this.contentKey,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      reach: reach ?? this.reach,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      postUrl: postUrl ?? this.postUrl,
      tags: tags ?? this.tags,
      author: author ?? this.author,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'content': content,
      'contentMarathi': contentMarathi,
      'contentKey': contentKey,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'reach': reach,
      'date': date,
      'imageUrl': imageUrl,
      'postUrl': postUrl,
      'tags': tags,
      'author': author,
    };
  }

  factory SocialPostModel.fromJson(Map<String, dynamic> json) {
    return SocialPostModel(
      id: json['id']?.toString() ?? '',
      platform: json['platform'] ?? 'Facebook',
      content: json['content'] ?? '',
      contentMarathi: json['contentMarathi'] ?? '',
      contentKey: json['contentKey'],
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      reach: (json['reach'] as num?)?.toInt() ?? 0,
      date: json['date'] ?? '',
      imageUrl: json['imageUrl'],
      postUrl: json['postUrl'],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      author: json['author'] ?? 'नगरसेवक कार्यालय • प्रभाग १२',
    );
  }
}

class VoterBirthdayModel {
  final String id;
  final String name;
  final String nameMarathi;
  final String mobile;
  final String area;
  final String boothNumber;
  final int age;

  const VoterBirthdayModel({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.mobile,
    required this.area,
    required this.boothNumber,
    required this.age,
  });

  String get displayName => name.isNotEmpty ? name : nameMarathi;
}

extension IntFormatting on int {
  String toLocaleString() {
    final str = toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(RegExp(r'\B(?=(\d{2})+(?!\d))'), (match) => ',');
    return '$formattedRest,$lastThree';
  }
}


