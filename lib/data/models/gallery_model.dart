import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_translations.dart';

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

  String get titleHi {
    switch (this) {
      case GalleryCategory.event:
        return 'कार्यक्रम';
      case GalleryCategory.work:
        return 'विकास कार्य';
      case GalleryCategory.award:
        return 'पुरस्कार';
      case GalleryCategory.campaign:
        return 'अभियान / जनसंपर्क';
    }
  }

  String title(String lang) =>
      lang == 'mr' ? titleMr : (lang == 'hi' ? titleHi : titleEn);

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

  String formattedDateFor(String lang) =>
      AppTranslations.formatDate(date, lang, pattern: 'dd/MM/yyyy');

  String formattedDateFullFor(String lang) =>
      AppTranslations.formatDate(date, lang, pattern: 'd MMMM yyyy');

  String get relativeTime {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'आज';
    if (diff.inDays == 1) return 'काल';
    if (diff.inDays < 7) return '${diff.inDays} दिवसांपूर्वी';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} आठवड्यांपूर्वी';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()} महिन्यांपूर्वी';
    return '${date.year}';
  }

  String relativeTimeFor(String lang) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      return AppTranslations.pick(lang, en: 'Today', mr: 'आज', hi: 'आज');
    }
    if (diff.inDays == 1) {
      return AppTranslations.pick(lang, en: 'Yesterday', mr: 'काल', hi: 'कल');
    }
    if (diff.inDays < 7) {
      final d = AppTranslations.formatDigits(diff.inDays, lang);
      return AppTranslations.pick(
        lang,
        en: '$d days ago',
        mr: '$d दिवसांपूर्वी',
        hi: '$d दिन पहले',
      );
    }
    if (diff.inDays < 30) {
      final w = AppTranslations.formatDigits((diff.inDays / 7).round(), lang);
      return AppTranslations.pick(
        lang,
        en: '$w weeks ago',
        mr: '$w आठवड्यांपूर्वी',
        hi: '$w सप्ताह पहले',
      );
    }
    if (diff.inDays < 365) {
      final m = AppTranslations.formatDigits((diff.inDays / 30).round(), lang);
      return AppTranslations.pick(
        lang,
        en: '$m months ago',
        mr: '$m महिन्यांपूर्वी',
        hi: '$m महीने पहले',
      );
    }
    return AppTranslations.formatDigits(date.year, lang);
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

  factory GalleryItemModel.fromJson(Map<String, dynamic> json) {
    GalleryCategory cat = GalleryCategory.event;
    final catStr = json['category']?.toString().toLowerCase();
    if (catStr == 'work') {
      cat = GalleryCategory.work;
    } else if (catStr == 'award') {
      cat = GalleryCategory.award;
    } else if (catStr == 'campaign') {
      cat = GalleryCategory.campaign;
    }

    return GalleryItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      titleMr: json['title_mr'] ?? json['title'] ?? '',
      category: cat,
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      descriptionMr: json['description_mr'] ?? json['description'] ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      location: json['location'] ?? 'Ward 12',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? (json['viewsCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) {
    return {
      'title': title,
      'category': category.id,
      'image_url': imageUrl,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      if (tenantId != null) 'tenant_id': tenantId,
    };
  }
}

