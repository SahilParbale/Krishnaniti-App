import 'dart:convert';
import 'package:flutter/material.dart';

class WorkFeedbackModel {
  final String id;
  final String citizenName;
  final int rating; // 1 to 5
  final String comment;
  final String createdAt;

  const WorkFeedbackModel({
    required this.id,
    required this.citizenName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory WorkFeedbackModel.fromJson(Map<String, dynamic> json) {
    return WorkFeedbackModel(
      id: json['id']?.toString() ?? '',
      citizenName: json['citizen_name'] ?? json['citizenName'] ?? 'Citizen',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizen_name': citizenName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
    };
  }
}

class WorkHistoryModel {
  final String id;
  final String source; // 'Manual' | 'Complaint' | 'Help'
  final String title;
  final String description;
  final String location;
  final String area;
  final String status; // 'Completed' | 'InProgress' | 'Planned'
  final String date;
  final String? citizenName;
  final double? amount;
  final int? peopleBenefited;
  final double feedbackRating;
  final int feedbackCount;
  final List<WorkFeedbackModel> feedbacks;

  const WorkHistoryModel({
    required this.id,
    this.source = 'Manual',
    required this.title,
    required this.description,
    required this.location,
    this.area = 'Ward 12',
    this.status = 'Completed',
    required this.date,
    this.citizenName,
    this.amount,
    this.peopleBenefited,
    this.feedbackRating = 4.8,
    this.feedbackCount = 0,
    this.feedbacks = const [],
  });

  factory WorkHistoryModel.fromJson(Map<String, dynamic> json) {
    var rawFeedbacks = json['feedbacks'] as List<dynamic>? ?? [];
    List<WorkFeedbackModel> parsedFeedbacks = rawFeedbacks
        .map((f) => WorkFeedbackModel.fromJson(f as Map<String, dynamic>))
        .toList();

    Map<String, dynamic>? meta;
    if (json['metadata'] != null) {
      if (json['metadata'] is Map) {
        meta = Map<String, dynamic>.from(json['metadata'] as Map);
      } else if (json['metadata'] is String && (json['metadata'] as String).trim().isNotEmpty) {
        try {
          meta = Map<String, dynamic>.from(jsonDecode(json['metadata'] as String) as Map);
        } catch (_) {}
      }
    }

    final peopleBenefited = meta?['people_benefited'] is num
        ? (meta!['people_benefited'] as num).toInt()
        : int.tryParse(meta?['people_benefited']?.toString() ?? '') ??
            (json['people_benefited'] is num ? (json['people_benefited'] as num).toInt() : int.tryParse(json['people_benefited']?.toString() ?? '')) ??
            (json['peopleBenefited'] is num ? (json['peopleBenefited'] as num).toInt() : int.tryParse(json['peopleBenefited']?.toString() ?? ''));

    final amount = (json['amount'] is num ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '')) ??
        (json['budget'] is num ? (json['budget'] as num).toDouble() : double.tryParse(json['budget']?.toString() ?? ''));

    return WorkHistoryModel(
      id: json['id']?.toString() ?? '',
      source: json['source'] ?? 'Manual',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Planned',
      date: json['completion_date']?.toString() ?? json['date']?.toString() ?? json['created_at']?.toString() ?? '',
      citizenName: json['citizen_name']?.toString() ?? json['citizenName']?.toString(),
      amount: amount,
      peopleBenefited: peopleBenefited,
      feedbackRating: (json['feedback_rating'] as num?)?.toDouble() ?? 4.8,
      feedbackCount: (json['feedback_count'] as num?)?.toInt() ?? parsedFeedbacks.length,
      feedbacks: parsedFeedbacks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'title': title,
      'description': description,
      'location': location,
      'area': area,
      'status': status,
      'date': date,
      'citizen_name': citizenName,
      'amount': amount,
      'people_benefited': peopleBenefited,
      'feedback_rating': feedbackRating,
      'feedback_count': feedbackCount,
      'feedbacks': feedbacks.map((f) => f.toJson()).toList(),
    };
  }

  WorkHistoryModel copyWith({
    String? id,
    String? source,
    String? title,
    String? description,
    String? location,
    String? area,
    String? status,
    String? date,
    String? citizenName,
    double? amount,
    int? peopleBenefited,
    double? feedbackRating,
    int? feedbackCount,
    List<WorkFeedbackModel>? feedbacks,
  }) {
    return WorkHistoryModel(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      area: area ?? this.area,
      status: status ?? this.status,
      date: date ?? this.date,
      citizenName: citizenName ?? this.citizenName,
      amount: amount ?? this.amount,
      peopleBenefited: peopleBenefited ?? this.peopleBenefited,
      feedbackRating: feedbackRating ?? this.feedbackRating,
      feedbackCount: feedbackCount ?? this.feedbackCount,
      feedbacks: feedbacks ?? this.feedbacks,
    );
  }

  // Helpers
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'inprogress':
      case 'in_progress':
        return const Color(0xFF0284C7);
      case 'planned':
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'inprogress':
      case 'in_progress':
        return const Color(0xFFE0F2FE);
      case 'planned':
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String get statusDisplayEn {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'inprogress':
      case 'in_progress':
        return 'In Progress';
      case 'planned':
      default:
        return 'Planned';
    }
  }

  String get statusDisplayMr {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'पूर्ण झाले';
      case 'inprogress':
      case 'in_progress':
        return 'प्रगतीपथावर';
      case 'planned':
      default:
        return 'नियोजित';
    }
  }

  String get sourceDisplayEn {
    switch (source.toLowerCase()) {
      case 'complaint':
        return 'From Grievance';
      case 'help':
        return 'Direct Help';
      case 'manual':
      default:
        return 'Civil Project';
    }
  }

  String get sourceDisplayMr {
    switch (source.toLowerCase()) {
      case 'complaint':
        return 'तक्रार निवारण';
      case 'help':
        return 'नागरिक मदत';
      case 'manual':
      default:
        return 'विकास काम';
    }
  }

  IconData get sourceIcon {
    switch (source.toLowerCase()) {
      case 'complaint':
        return Icons.assignment_turned_in_outlined;
      case 'help':
        return Icons.volunteer_activism_outlined;
      case 'manual':
      default:
        return Icons.construction_rounded;
    }
  }
}

