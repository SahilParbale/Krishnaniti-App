/// Question types matching Nagarsevak-Managment
enum SurveyQuestionType {
  yesNo,
  mcq,
  rating,
}

extension SurveyQuestionTypeX on SurveyQuestionType {
  String get value {
    switch (this) {
      case SurveyQuestionType.yesNo:
        return 'YesNo';
      case SurveyQuestionType.mcq:
        return 'MCQ';
      case SurveyQuestionType.rating:
        return 'Rating';
    }
  }

  String get labelMr {
    switch (this) {
      case SurveyQuestionType.yesNo:
        return 'होय / नाही (Yes/No)';
      case SurveyQuestionType.mcq:
        return 'बहुपर्यायी (MCQ)';
      case SurveyQuestionType.rating:
        return 'स्टार रेटिंग (१ ते ५)';
    }
  }

  static SurveyQuestionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'yesno':
      case 'yes_no':
        return SurveyQuestionType.yesNo;
      case 'mcq':
        return SurveyQuestionType.mcq;
      case 'rating':
        return SurveyQuestionType.rating;
      default:
        return SurveyQuestionType.yesNo;
    }
  }
}

/// Question Model
class SurveyQuestionModel {
  final String id;
  final String text;
  final SurveyQuestionType type;
  final List<String> options;

  const SurveyQuestionModel({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
  });

  factory SurveyQuestionModel.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? json['question']?.toString() ?? '',
      type: SurveyQuestionTypeX.fromString(json['type']?.toString() ?? 'YesNo'),
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.value,
      'options': options,
    };
  }
}

/// Survey Model matching Nagarsevak-Managment
class SurveyModel {
  final String id;
  final String title;
  final String description;
  final String? area;
  final List<SurveyQuestionModel> questions;
  final int targetSampleSize;
  final String status; // 'Active', 'Draft', 'Closed'
  final DateTime createdAt;
  final String? tenantId;

  const SurveyModel({
    required this.id,
    required this.title,
    required this.description,
    this.area,
    required this.questions,
    this.targetSampleSize = 100,
    this.status = 'Active',
    required this.createdAt,
    this.tenantId,
  });

  bool get isActive => status == 'Active';
  bool get isDraft => status == 'Draft';
  bool get isClosed => status == 'Closed';

  SurveyModel copyWith({
    String? id,
    String? title,
    String? description,
    String? area,
    List<SurveyQuestionModel>? questions,
    int? targetSampleSize,
    String? status,
    DateTime? createdAt,
    String? tenantId,
  }) {
    return SurveyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      area: area ?? this.area,
      questions: questions ?? this.questions,
      targetSampleSize: targetSampleSize ?? this.targetSampleSize,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    List<SurveyQuestionModel> qList = [];
    if (json['questions'] != null && json['questions'] is List) {
      qList = (json['questions'] as List)
          .map((e) => SurveyQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SurveyModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      area: json['area']?.toString(),
      questions: qList,
      targetSampleSize: (json['target_sample_size'] ?? json['targetSampleSize'] ?? 100) as int,
      status: json['status']?.toString() ?? 'Active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'area': area,
      'questions': questions.map((q) => q.toJson()).toList(),
      'target_sample_size': targetSampleSize,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'tenant_id': tenantId,
    };
  }
}

/// Survey Response Model matching survey_responses table
class SurveyResponseModel {
  final String id;
  final String surveyId;
  final String? voterId;
  final String? voterName;
  final String? voterMobile;
  final Map<String, dynamic> answers; // questionId -> answer
  final DateTime submittedAt;

  const SurveyResponseModel({
    required this.id,
    required this.surveyId,
    this.voterId,
    this.voterName,
    this.voterMobile,
    required this.answers,
    required this.submittedAt,
  });

  factory SurveyResponseModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> ansMap = {};
    if (json['answers'] != null && json['answers'] is Map) {
      ansMap = Map<String, dynamic>.from(json['answers'] as Map);
    }

    String? vName;
    String? vMobile;
    if (json['voters'] != null && json['voters'] is Map) {
      vName = json['voters']['name_marathi'] ?? json['voters']['name'];
      vMobile = json['voters']['mobile'];
    }

    return SurveyResponseModel(
      id: json['id']?.toString() ?? '',
      surveyId: json['survey_id']?.toString() ?? json['surveyId']?.toString() ?? '',
      voterId: json['voter_id']?.toString(),
      voterName: vName,
      voterMobile: vMobile,
      answers: ansMap,
      submittedAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['submittedAt'] != null
              ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'survey_id': surveyId,
      'voter_id': voterId,
      'answers': answers,
      'created_at': submittedAt.toIso8601String(),
    };
  }
}

