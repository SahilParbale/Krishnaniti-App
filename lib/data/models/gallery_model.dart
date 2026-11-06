import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Supported Gallery Categories matching Nagarsevak-Managment
enum GalleryCategory {
  event,
  work,
  award,
  campaign,
}

extension GalleryCategoryX on GalleryCategory {
  String get id {
    switch (this) {
      case GalleryCategory.event:
        return 'Event';
      case GalleryCategory.work:
        return 'Work';
      case GalleryCategory.award:
        return 'Award';
      case GalleryCategory.campaign:
        return 'Campaign';
    }
  }

  String get titleMr {
    switch (this) {
      case GalleryCategory.event:
        return 'कार्यक्रम';
      case GalleryCategory.work:
        return 'विकासकाम';
      case GalleryCategory.award:
        return 'पुरस्कार';
      case GalleryCategory.campaign:
        return 'मोहीम / जनसंपर्क';
    }
  }

  String get titleEn {
    switch (this) {
      case GalleryCategory.event:
        return 'Events';
      case GalleryCategory.work:
        return 'Works';
      case GalleryCategory.award:
        return 'Awards';
      case GalleryCategory.campaign:
        return 'Campaigns';
    }
  }

  IconData get icon {
    switch (this) {
      case GalleryCategory.event:
        return Icons.celebration_rounded;
      case GalleryCategory.work:
        return Icons.engineering_rounded;
      case GalleryCategory.award:
        return Icons.emoji_events_rounded;
      case GalleryCategory.campaign:
        return Icons.campaign_rounded;
    }
  }

  Color get color {
    switch (this) {
      case GalleryCategory.event:
        return const Color(0xFF8B5CF6); // Purple
      case GalleryCategory.work:
        return const Color(0xFF0284C7); // Sky Blue
      case GalleryCategory.award:
        return const Color(0xFFD97706); // Amber
      case GalleryCategory.campaign:
        return const Color(0xFF059669); // Emerald
    }
  }
}

/// Gallery Item Model
class GalleryItemModel {
  final String id;
  final String title;
  final String titleMr;
  final GalleryCategory category;
  final String imageUrl;
  final String description;
  final String descriptionMr;
  final DateTime date;
  final String location;
  final List<String> tags;
  final bool isFavorite;
  final int viewsCount;
  final DateTime createdAt;

  const GalleryItemModel({
    required this.id,
    required this.title,
    required this.titleMr,
    required this.category,
    required this.imageUrl,
    required this.description,
    required this.descriptionMr,
    required this.date,
    required this.location,
    this.tags = const [],
    this.isFavorite = false,
    this.viewsCount = 0,
    required this.createdAt,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);

  String get formattedDateFull => DateFormat('d MMMM yyyy').format(date);

  String get relativeTime {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'आज';
    if (diff.inDays == 1) return 'काल';
    if (diff.inDays < 7) return '${diff.inDays} दिवसांपूर्वी';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} आठवड्यांपूर्वी';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()} महिन्यांपूर्वी';
    return '${date.year}';
  }

  GalleryItemModel copyWith({
    String? id,
    String? title,
    String? titleMr,
    GalleryCategory? category,
    String? imageUrl,
    String? description,
    String? descriptionMr,
    DateTime? date,
    String? location,
    List<String>? tags,
    bool? isFavorite,
    int? viewsCount,
    DateTime? createdAt,
  }) {
    return GalleryItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleMr: titleMr ?? this.titleMr,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      descriptionMr: descriptionMr ?? this.descriptionMr,
      date: date ?? this.date,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

