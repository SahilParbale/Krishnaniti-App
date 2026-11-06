import 'package:flutter/material.dart';

/// Supported content types in the AI Content Studio
enum AiContentType {
  speech,
  socialMediaCaption,
  pressRelease,
  letterNotice,
  email,
  workReport,
}

extension AiContentTypeX on AiContentType {
  String get id {
    switch (this) {
      case AiContentType.speech:
        return 'Speech';
      case AiContentType.socialMediaCaption:
        return 'Social Media Caption';
      case AiContentType.pressRelease:
        return 'Press Release';
      case AiContentType.letterNotice:
        return 'Letter/Notice';
      case AiContentType.email:
        return 'Email';
      case AiContentType.workReport:
        return 'Work Report';
    }
  }

  String get titleEn {
    switch (this) {
      case AiContentType.speech:
        return 'Speech';
      case AiContentType.socialMediaCaption:
        return 'Social Media Caption';
      case AiContentType.pressRelease:
        return 'Press Release';
      case AiContentType.letterNotice:
        return 'Letter / Notice';
      case AiContentType.email:
        return 'Email';
      case AiContentType.workReport:
        return 'Work Report';
    }
  }

  String get titleMr {
    switch (this) {
      case AiContentType.speech:
        return 'भाषण';
      case AiContentType.socialMediaCaption:
        return 'सोशल मीडिया कॅप्शन';
      case AiContentType.pressRelease:
        return 'प्रेस रिलीज';
      case AiContentType.letterNotice:
        return 'पत्र / सूचना';
      case AiContentType.email:
        return 'ईमेल';
      case AiContentType.workReport:
        return 'कामाचा अहवाल';
    }
  }

  IconData get icon {
    switch (this) {
      case AiContentType.speech:
        return Icons.record_voice_over_rounded;
      case AiContentType.socialMediaCaption:
        return Icons.tag_rounded;
      case AiContentType.pressRelease:
        return Icons.newspaper_rounded;
      case AiContentType.letterNotice:
        return Icons.description_rounded;
      case AiContentType.email:
        return Icons.alternate_email_rounded;
      case AiContentType.workReport:
        return Icons.engineering_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AiContentType.speech:
        return const Color(0xFF8B5CF6); // Purple
      case AiContentType.socialMediaCaption:
        return const Color(0xFF0284C7); // Sky Blue
      case AiContentType.pressRelease:
        return const Color(0xFF059669); // Emerald Green
      case AiContentType.letterNotice:
        return const Color(0xFFD97706); // Amber
      case AiContentType.email:
        return const Color(0xFF2563EB); // Royal Blue
      case AiContentType.workReport:
        return const Color(0xFFDC2626); // Crimson
    }
  }
}

/// Supported tones
enum AiToneType {
  enthusiastic,
  formal,
  professional,
  emotional,
  urgent,
}

extension AiToneTypeX on AiToneType {
  String get id {
    switch (this) {
      case AiToneType.enthusiastic:
        return 'Enthusiastic';
      case AiToneType.formal:
        return 'Formal';
      case AiToneType.professional:
        return 'Professional';
      case AiToneType.emotional:
        return 'Emotional';
      case AiToneType.urgent:
        return 'Urgent';
    }
  }

  String get titleEn {
    switch (this) {
      case AiToneType.enthusiastic:
        return 'Enthusiastic';
      case AiToneType.formal:
        return 'Formal';
      case AiToneType.professional:
        return 'Professional';
      case AiToneType.emotional:
        return 'Emotional';
      case AiToneType.urgent:
        return 'Urgent';
    }
  }

  String get titleMr {
    switch (this) {
      case AiToneType.enthusiastic:
        return 'उत्साही';
      case AiToneType.formal:
        return 'औपचारिक';
      case AiToneType.professional:
        return 'व्यावसायिक';
      case AiToneType.emotional:
        return 'भावनिक';
      case AiToneType.urgent:
        return 'तात्काळ';
    }
  }

  IconData get icon {
    switch (this) {
      case AiToneType.enthusiastic:
        return Icons.celebration_rounded;
      case AiToneType.formal:
        return Icons.business_center_rounded;
      case AiToneType.professional:
        return Icons.verified_rounded;
      case AiToneType.emotional:
        return Icons.favorite_rounded;
      case AiToneType.urgent:
        return Icons.warning_rounded;
    }
  }
}

/// Supported languages
enum AiLanguageType {
  marathi,
  english,
  hindi,
}

extension AiLanguageTypeX on AiLanguageType {
  String get id {
    switch (this) {
      case AiLanguageType.marathi:
        return 'Marathi';
      case AiLanguageType.english:
        return 'English';
      case AiLanguageType.hindi:
        return 'Hindi';
    }
  }

  String get label {
    switch (this) {
      case AiLanguageType.marathi:
        return 'मराठी (Marathi)';
      case AiLanguageType.english:
        return 'English';
      case AiLanguageType.hindi:
        return 'हिंदी (Hindi)';
    }
  }

  String get shortCode => id.substring(0, 2).toUpperCase();
}

/// Item in the AI Content Generation History
class AiContentHistoryItem {
  final String id;
  final String title;
  final AiContentType contentType;
  final AiToneType tone;
  final AiLanguageType language;
  final String generatedContent;
  final DateTime createdAt;
  final bool isFavorite;
  final String? wardNumber;

  const AiContentHistoryItem({
    required this.id,
    required this.title,
    required this.contentType,
    required this.tone,
    required this.language,
    required this.generatedContent,
    required this.createdAt,
    this.isFavorite = false,
    this.wardNumber = 'प्रभाग क्र. १२',
  });

  int get wordCount {
    if (generatedContent.trim().isEmpty) return 0;
    return generatedContent.trim().split(RegExp(r'\s+')).length;
  }

  /// Approximate reading/speaking time in minutes (avg 130 words/min)
  double get readingTimeMinutes {
    final count = wordCount;
    if (count == 0) return 0;
    return (count / 130.0);
  }

  String get readingTimeFormatted {
    final mins = readingTimeMinutes;
    if (mins < 1) {
      final secs = (mins * 60).round();
      return '$secs सेकंद';
    }
    return '${mins.toStringAsFixed(1)} मिनिटे';
  }

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'आत्ताच';
    if (diff.inMinutes < 60) return '${diff.inMinutes} मिनिटांपूर्वी';
    if (diff.inHours < 24) return '${diff.inHours} तासांपूर्वी';
    if (diff.inDays < 7) return '${diff.inDays} दिवसांपूर्वी';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  AiContentHistoryItem copyWith({
    String? id,
    String? title,
    AiContentType? contentType,
    AiToneType? tone,
    AiLanguageType? language,
    String? generatedContent,
    DateTime? createdAt,
    bool? isFavorite,
    String? wardNumber,
  }) {
    return AiContentHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      tone: tone ?? this.tone,
      language: language ?? this.language,
      generatedContent: generatedContent ?? this.generatedContent,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      wardNumber: wardNumber ?? this.wardNumber,
    );
  }
}

/// Political quick prompt template for Nagar Sevak
class AiPromptTemplate {
  final String id;
  final String title;
  final String titleMr;
  final String subtitle;
  final String prompt;
  final AiContentType defaultType;
  final AiToneType defaultTone;
  final IconData icon;

  const AiPromptTemplate({
    required this.id,
    required this.title,
    required this.titleMr,
    required this.subtitle,
    required this.prompt,
    required this.defaultType,
    required this.defaultTone,
    required this.icon,
  });
}

