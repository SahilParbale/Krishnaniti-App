import 'package:intl/intl.dart';

class DiaryEntryModel {
  final String id;
  final DateTime meetingDate;
  final String meetingType; // 'GB', 'Standing Committee', 'Ward Committee', 'Special GB', 'Other'
  final String subject;
  final String? description;
  final String? department;
  final String? area;
  final String status; // 'Raised', 'In Discussion', 'Resolved', 'Action Taken'
  final String? beneficiaries;
  final String? response;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? tenantId;

  DiaryEntryModel({
    required this.id,
    required this.meetingDate,
    required this.meetingType,
    required this.subject,
    this.description,
    this.department,
    this.area,
    required this.status,
    this.beneficiaries,
    this.response,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.tenantId,
  });

  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(meetingDate);
  }

  String get formattedTime {
    return DateFormat('hh:mm a').format(meetingDate);
  }

  bool get isRaised => status.toLowerCase() == 'raised';
  bool get isInDiscussion => status.toLowerCase() == 'in discussion';
  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isActionTaken => status.toLowerCase() == 'action taken';

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    List<String> parseTags(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return DiaryEntryModel(
      id: json['id']?.toString() ?? '',
      meetingDate: parseDate(json['meeting_date'] ?? json['meetingDate']),
      meetingType: json['meeting_type']?.toString() ?? json['meetingType']?.toString() ?? 'GB',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString(),
      department: json['department']?.toString(),
      area: json['area']?.toString(),
      status: json['status']?.toString() ?? 'Raised',
      beneficiaries: json['beneficiaries']?.toString(),
      response: json['response']?.toString(),
      tags: parseTags(json['tags']),
      createdAt: json['created_at'] != null ? parseDate(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? parseDate(json['updated_at']) : null,
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) {
    return {
      'meeting_date': meetingDate.toIso8601String().split('T')[0],
      'meeting_type': meetingType,
      'subject': subject,
      'description': description,
      'department': department,
      'area': area,
      'status': status,
      'beneficiaries': beneficiaries,
      'response': response,
      'tags': tags,
      if (tenantId != null) 'tenant_id': tenantId,
    };
  }

  DiaryEntryModel copyWith({
    String? id,
    DateTime? meetingDate,
    String? meetingType,
    String? subject,
    String? description,
    String? department,
    String? area,
    String? status,
    String? beneficiaries,
    String? response,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tenantId,
  }) {
    return DiaryEntryModel(
      id: id ?? this.id,
      meetingDate: meetingDate ?? this.meetingDate,
      meetingType: meetingType ?? this.meetingType,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      department: department ?? this.department,
      area: area ?? this.area,
      status: status ?? this.status,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      response: response ?? this.response,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}

