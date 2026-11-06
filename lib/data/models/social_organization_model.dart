import 'dart:convert';

/// Event or festival conducted by the NGO or Mandal
class SocialOrgEventModel {
  final String id;
  final String title;
  final String? titleMr;
  final int year;
  final String description;
  final String? descriptionMr;

  const SocialOrgEventModel({
    required this.id,
    required this.title,
    this.titleMr,
    required this.year,
    this.description = '',
    this.descriptionMr,
  });

  factory SocialOrgEventModel.fromJson(Map<String, dynamic> json) {
    return SocialOrgEventModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['title_mr']?.toString() ?? '',
      titleMr: json['title_mr']?.toString() ?? json['title']?.toString(),
      year: int.tryParse(json['year']?.toString() ?? '') ?? DateTime.now().year,
      description: json['description']?.toString() ?? json['description_mr']?.toString() ?? '',
      descriptionMr: json['description_mr']?.toString() ?? json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_mr': titleMr,
      'year': year,
      'description': description,
      'description_mr': descriptionMr,
    };
  }

  String get displayTitle => (titleMr != null && titleMr!.isNotEmpty) ? titleMr! : title;
  String get displayDescription => (descriptionMr != null && descriptionMr!.isNotEmpty) ? descriptionMr! : description;
}

/// Represents an NGO, Cricket Club, Ganpati Mandal, or Navratri Mandal in the ward
class SocialOrganizationModel {
  final String id;
  final String name;
  final String? nameMarathi;
  final String? nameEnglish;
  /// 'ngo' | 'sports_cricket' | 'ganpati_mandal' | 'navratri_mandal' | 'other'
  final String type;
  final String presidentName;
  final String presidentMobile;
  final int membersCount;
  final String area;
  final String establishedYear;
  final String supportReceived;
  final List<SocialOrgEventModel> eventsConducted;
  final String description;
  /// 'Active' | 'Inactive'
  final String status;
  final DateTime createdAt;

  const SocialOrganizationModel({
    required this.id,
    required this.name,
    this.nameMarathi,
    this.nameEnglish,
    required this.type,
    required this.presidentName,
    required this.presidentMobile,
    this.membersCount = 0,
    required this.area,
    this.establishedYear = '',
    this.supportReceived = '',
    this.eventsConducted = const [],
    this.description = '',
    this.status = 'Active',
    required this.createdAt,
  });

  factory SocialOrganizationModel.fromJson(Map<String, dynamic> json) {
    List<SocialOrgEventModel> parseEvents(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => SocialOrgEventModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.map((e) => SocialOrgEventModel.fromJson(e as Map<String, dynamic>)).toList();
          }
        } catch (_) {}
      }
      return [];
    }

    final nameVal = json['name']?.toString() ?? json['name_marathi']?.toString() ?? json['name_english']?.toString() ?? '';

    return SocialOrganizationModel(
      id: json['id']?.toString() ?? '',
      name: nameVal,
      nameMarathi: json['name_marathi']?.toString() ?? nameVal,
      nameEnglish: json['name_english']?.toString() ?? nameVal,
      type: json['type']?.toString() ?? 'other',
      presidentName: json['president_name']?.toString() ?? '',
      presidentMobile: json['president_mobile']?.toString() ?? '',
      membersCount: int.tryParse(json['members_count']?.toString() ?? '0') ?? 0,
      area: json['area']?.toString() ?? '',
      establishedYear: json['established_year']?.toString() ?? '',
      supportReceived: json['support_received']?.toString() ?? '',
      eventsConducted: parseEvents(json['events_conducted']),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_marathi': nameMarathi,
      'name_english': nameEnglish,
      'type': type,
      'president_name': presidentName,
      'president_mobile': presidentMobile,
      'members_count': membersCount,
      'area': area,
      'established_year': establishedYear,
      'support_received': supportReceived,
      'events_conducted': eventsConducted.map((e) => e.toJson()).toList(),
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SocialOrganizationModel copyWith({
    String? id,
    String? name,
    String? nameMarathi,
    String? nameEnglish,
    String? type,
    String? presidentName,
    String? presidentMobile,
    int? membersCount,
    String? area,
    String? establishedYear,
    String? supportReceived,
    List<SocialOrgEventModel>? eventsConducted,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return SocialOrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameMarathi: nameMarathi ?? this.nameMarathi,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      type: type ?? this.type,
      presidentName: presidentName ?? this.presidentName,
      presidentMobile: presidentMobile ?? this.presidentMobile,
      membersCount: membersCount ?? this.membersCount,
      area: area ?? this.area,
      establishedYear: establishedYear ?? this.establishedYear,
      supportReceived: supportReceived ?? this.supportReceived,
      eventsConducted: eventsConducted ?? this.eventsConducted,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName => (nameMarathi != null && nameMarathi!.isNotEmpty) ? nameMarathi! : name;

  String get typeLabelMarathi {
    switch (type) {
      case 'ngo':
        return 'एन.जी.ओ / सामाजिक संस्था';
      case 'sports_cricket':
        return 'क्रीडा व क्रिकेट क्लब';
      case 'ganpati_mandal':
        return 'गणपती मंडळ';
      case 'navratri_mandal':
        return 'नवरात्रौत्सव मंडळ';
      default:
        return 'इतर संस्था व मंडळ';
    }
  }

  String get typeLabelEnglish {
    switch (type) {
      case 'ngo':
        return 'NGO / Foundation';
      case 'sports_cricket':
        return 'Cricket & Sports Club';
      case 'ganpati_mandal':
        return 'Ganpati Mandal';
      case 'navratri_mandal':
        return 'Navratri Mandal';
      default:
        return 'Other Organization';
    }
  }
}

