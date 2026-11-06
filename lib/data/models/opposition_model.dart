/// Represents a public activity, protest, or campaign event logged for an opposition member
class OppositionActivityModel {
  final String id;
  final String date;
  final String title;
  final String description;
  final String location;

  const OppositionActivityModel({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    this.location = '',
  });

  factory OppositionActivityModel.fromJson(Map<String, dynamic> json) {
    return OppositionActivityModel(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'description': description,
      'location': location,
    };
  }

  OppositionActivityModel copyWith({
    String? id,
    String? date,
    String? title,
    String? description,
    String? location,
  }) {
    return OppositionActivityModel(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
    );
  }
}

/// Represents a controversy, negative story, corruption allegation, or political dispute
class OppositionNegativeStoryModel {
  final String id;
  final String date;
  final String title;
  /// 'High' | 'Medium' | 'Low'
  final String severity;
  final String source;
  final String description;

  const OppositionNegativeStoryModel({
    required this.id,
    required this.date,
    required this.title,
    this.severity = 'Medium',
    this.source = '',
    required this.description,
  });

  factory OppositionNegativeStoryModel.fromJson(Map<String, dynamic> json) {
    return OppositionNegativeStoryModel(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'Medium',
      source: json['source']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'severity': severity,
      'source': source,
      'description': description,
    };
  }

  OppositionNegativeStoryModel copyWith({
    String? id,
    String? date,
    String? title,
    String? severity,
    String? source,
    String? description,
  }) {
    return OppositionNegativeStoryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      description: description ?? this.description,
    );
  }

  String get severityLabelMarathi {
    switch (severity) {
      case 'High':
        return 'तीव्र प्रभाव (High)';
      case 'Medium':
        return 'मध्यम प्रभाव (Medium)';
      case 'Low':
        return 'सौम्य प्रभाव (Low)';
      default:
        return severity;
    }
  }
}

/// Represents an opposition party worker or candidate in the Prabhag
class OppositionMemberModel {
  final String id;
  final String name;
  final String? mobile;
  final String party;
  final String? role;
  final String? area;
  final List<String> strongholds;
  final String? notes;
  final bool isCandidate;
  final String? constituency;
  final String? opposingCandidate;
  /// 'Declared' | 'Contesting' | 'Withdrawn' | 'Won' | 'Lost'
  final String? candidacyStatus;
  /// If this member is a worker, links to an opposition candidate
  final String? candidateId;
  final List<OppositionActivityModel> activities;
  final List<OppositionNegativeStoryModel> negativeStories;
  final DateTime createdAt;

  const OppositionMemberModel({
    required this.id,
    required this.name,
    this.mobile,
    required this.party,
    this.role,
    this.area,
    this.strongholds = const [],
    this.notes,
    this.isCandidate = false,
    this.constituency,
    this.opposingCandidate,
    this.candidacyStatus = 'Declared',
    this.candidateId,
    this.activities = const [],
    this.negativeStories = const [],
    required this.createdAt,
  });

  factory OppositionMemberModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStrongholds(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (raw is String) {
        return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    List<OppositionActivityModel> parseActivities(dynamic raw) {
      if (raw == null || raw is! List) return [];
      return raw.map((e) => OppositionActivityModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    List<OppositionNegativeStoryModel> parseNegativeStories(dynamic raw) {
      if (raw == null || raw is! List) return [];
      return raw.map((e) => OppositionNegativeStoryModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return OppositionMemberModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString(),
      party: json['party']?.toString() ?? 'Independent',
      role: json['role']?.toString(),
      area: json['area']?.toString(),
      strongholds: parseStrongholds(json['strongholds']),
      notes: json['notes']?.toString(),
      isCandidate: json['is_candidate'] == true || json['isCandidate'] == true,
      constituency: json['constituency']?.toString(),
      opposingCandidate: json['opposing_candidate']?.toString() ?? json['opposingCandidate']?.toString(),
      candidacyStatus: json['candidacy_status']?.toString() ?? json['candidacyStatus']?.toString() ?? 'Declared',
      candidateId: json['candidate_id']?.toString() ?? json['candidateId']?.toString(),
      activities: parseActivities(json['activities']),
      negativeStories: parseNegativeStories(json['negative_stories'] ?? json['negativeStories']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'party': party,
      'role': role,
      'area': area,
      'strongholds': strongholds,
      'notes': notes,
      'is_candidate': isCandidate,
      'constituency': isCandidate ? constituency : null,
      'opposing_candidate': isCandidate ? opposingCandidate : null,
      'candidacy_status': isCandidate ? candidacyStatus : null,
      'candidate_id': !isCandidate ? candidateId : null,
      'activities': activities.map((a) => a.toJson()).toList(),
      'negative_stories': negativeStories.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  OppositionMemberModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? party,
    String? role,
    String? area,
    List<String>? strongholds,
    String? notes,
    bool? isCandidate,
    String? constituency,
    String? opposingCandidate,
    String? candidacyStatus,
    String? candidateId,
    List<OppositionActivityModel>? activities,
    List<OppositionNegativeStoryModel>? negativeStories,
    DateTime? createdAt,
  }) {
    return OppositionMemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      party: party ?? this.party,
      role: role ?? this.role,
      area: area ?? this.area,
      strongholds: strongholds ?? this.strongholds,
      notes: notes ?? this.notes,
      isCandidate: isCandidate ?? this.isCandidate,
      constituency: constituency ?? this.constituency,
      opposingCandidate: opposingCandidate ?? this.opposingCandidate,
      candidacyStatus: candidacyStatus ?? this.candidacyStatus,
      candidateId: candidateId ?? this.candidateId,
      activities: activities ?? this.activities,
      negativeStories: negativeStories ?? this.negativeStories,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get candidacyStatusLabelMarathi {
    if (!isCandidate || candidacyStatus == null) return '';
    switch (candidacyStatus) {
      case 'Declared':
        return 'घोषित';
      case 'Contesting':
        return 'लढत असलेले';
      case 'Withdrawn':
        return 'मागे घेतलेले';
      case 'Won':
        return 'विजयी';
      case 'Lost':
        return 'पराजित';
      default:
        return candidacyStatus!;
    }
  }

  String get typeLabelMarathi => isCandidate ? 'विरोधी उमेदवार' : 'विरोधी कार्यकर्ता';

  String get partyFullLabel {
    switch (party.toUpperCase()) {
      case 'INC':
        return 'काँग्रेस (INC)';
      case 'NCP':
        return 'राष्ट्रवादी (NCP)';
      case 'UBT':
        return 'शिवसेना (UBT)';
      case 'MNS':
        return 'मनसे (MNS)';
      case 'BJP':
        return 'भाजप (BJP)';
      case 'AAP':
        return 'आप (AAP)';
      case 'INDEPENDENT':
        return 'अपक्ष (Independent)';
      default:
        return party;
    }
  }
}

