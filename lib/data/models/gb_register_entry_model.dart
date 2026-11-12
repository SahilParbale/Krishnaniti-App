import 'package:flutter/material.dart';

class GbRegisterEntryModel {
  final String id;
  final String meetingType; // 'GB' | 'Standing Committee' | 'Ward Committee' | 'Special GB' | 'Other'
  final String meetingDate;
  final String subject;
  final String description;
  final String department;
  final String area;
  final String status; // 'Raised' | 'In Discussion' | 'Action Taken' | 'Rejected'
  final String? beneficiaries;
  final String? response;
  final String? resolutionNo;
  final List<String> tags;
  final String createdAt;

  const GbRegisterEntryModel({
    required this.id,
    this.meetingType = 'GB',
    required this.meetingDate,
    required this.subject,
    required this.description,
    required this.department,
    this.area = 'Ward 12',
    this.status = 'Raised',
    this.beneficiaries,
    this.response,
    this.resolutionNo,
    this.tags = const [],
    required this.createdAt,
  });

  factory GbRegisterEntryModel.fromJson(Map<String, dynamic> json) {
    return GbRegisterEntryModel(
      id: json['id']?.toString() ?? '',
      meetingType: json['meeting_type'] ?? json['meetingType'] ?? 'GB',
      meetingDate: json['meeting_date'] ?? json['meetingDate'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      department: json['department'] ?? 'General Administration',
      area: json['area'] ?? 'Ward 12',
      status: json['status'] ?? 'Raised',
      beneficiaries: json['beneficiaries']?.toString(),
      response: json['response'],
      resolutionNo: json['resolution_no'] ?? json['resolutionNo'],
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meeting_type': meetingType,
      'meeting_date': meetingDate,
      'subject': subject,
      'description': description,
      'department': department,
      'area': area,
      'status': status,
      'beneficiaries': beneficiaries,
      'response': response,
      'resolution_no': resolutionNo,
      'tags': tags,
      'created_at': createdAt,
    };
  }

  GbRegisterEntryModel copyWith({
    String? id,
    String? meetingType,
    String? meetingDate,
    String? subject,
    String? description,
    String? department,
    String? area,
    String? status,
    String? beneficiaries,
    String? response,
    String? resolutionNo,
    List<String>? tags,
    String? createdAt,
  }) {
    return GbRegisterEntryModel(
      id: id ?? this.id,
      meetingType: meetingType ?? this.meetingType,
      meetingDate: meetingDate ?? this.meetingDate,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      department: department ?? this.department,
      area: area ?? this.area,
      status: status ?? this.status,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      response: response ?? this.response,
      resolutionNo: resolutionNo ?? this.resolutionNo,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helpers
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'action_taken':
      case 'sanctioned':
        return const Color(0xFF16A34A);
      case 'resolved':
        return const Color(0xFF059669);
      case 'in discussion':
      case 'in_discussion':
        return const Color(0xFF0284C7);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'raised':
      default:
        return const Color(0xFFCA8A04);
    }
  }

  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'action_taken':
      case 'sanctioned':
        return const Color(0xFFF0FDF4);
      case 'resolved':
        return const Color(0xFFECFDF5);
      case 'in discussion':
      case 'in_discussion':
        return const Color(0xFFEFF6FF);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      case 'raised':
      default:
        return const Color(0xFFFEFCE8);
    }
  }

  Color get statusBorderColor {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'action_taken':
      case 'sanctioned':
        return const Color(0xFFBBF7D0);
      case 'resolved':
        return const Color(0xFFA7F3D0);
      case 'in discussion':
      case 'in_discussion':
        return const Color(0xFFBFDBFE);
      case 'rejected':
        return const Color(0xFFFECACA);
      case 'raised':
      default:
        return const Color(0xFFFEF08A);
    }
  }

  String get statusDisplayEn {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'action_taken':
      case 'sanctioned':
        return 'Action Taken';
      case 'resolved':
        return 'Resolved';
      case 'in discussion':
      case 'in_discussion':
        return 'In Discussion';
      case 'rejected':
        return 'Rejected';
      case 'raised':
      default:
        return 'Raised';
    }
  }

  String get statusDisplayMr {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'action_taken':
      case 'sanctioned':
        return 'कार्यवाही झाली';
      case 'resolved':
        return 'सोडवला';
      case 'in discussion':
      case 'in_discussion':
        return 'चर्चेत';
      case 'rejected':
        return 'नाकारले';
      case 'raised':
      default:
        return 'मांडलेला';
    }
  }

  String get meetingTypeDisplayEn {
    switch (meetingType.toLowerCase()) {
      case 'gb':
        return 'General Body (GB)';
      case 'standing committee':
      case 'standing':
        return 'Standing Committee';
      case 'ward committee':
      case 'ward':
        return 'Ward Committee';
      case 'special gb':
        return 'Special GB';
      case 'other':
        return 'Other';
      default:
        return meetingType;
    }
  }

  String get meetingTypeDisplayMr {
    switch (meetingType.toLowerCase()) {
      case 'gb':
        return 'महासभा (GB)';
      case 'standing committee':
      case 'standing':
        return 'स्थायी समिती';
      case 'ward committee':
      case 'ward':
        return 'प्रभाग समिती';
      case 'special gb':
        return 'विशेष महासभा';
      case 'other':
        return 'इतर';
      default:
        return meetingType;
    }
  }

  Color get meetingTypeColor {
    switch (meetingType.toLowerCase()) {
      case 'gb':
        return const Color(0xFF4338CA); // Indigo
      case 'standing committee':
      case 'standing':
        return const Color(0xFF7E22CE); // Purple
      case 'ward committee':
      case 'ward':
        return const Color(0xFF0284C7); // Sky Blue
      case 'special gb':
        return const Color(0xFFC026D3); // Fuchsia
      default:
        return const Color(0xFF475569); // Slate
    }
  }

  Color get meetingTypeBgColor {
    switch (meetingType.toLowerCase()) {
      case 'gb':
        return const Color(0xFFEEF2FF);
      case 'standing committee':
      case 'standing':
        return const Color(0xFFFAF5FF);
      case 'ward committee':
      case 'ward':
        return const Color(0xFFEFF6FF);
      case 'special gb':
        return const Color(0xFFFDF4FF);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}

