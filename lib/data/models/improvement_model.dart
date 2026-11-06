import 'package:flutter/material.dart';

class ImprovementModel {
  final String id;
  final String title;
  final String description;
  final int votes;
  final String location;
  final String area;
  final String status; // 'Pending' | 'Planned' | 'In Progress' | 'Complete'
  final String? completionDate;
  final int? peopleBenefited;
  final double? estimatedBudget;
  final String createdAt;
  final String? proposedBy;

  const ImprovementModel({
    required this.id,
    required this.title,
    required this.description,
    this.votes = 0,
    required this.location,
    this.area = 'Ward 12',
    this.status = 'Pending',
    this.completionDate,
    this.peopleBenefited,
    this.estimatedBudget,
    required this.createdAt,
    this.proposedBy,
  });

  factory ImprovementModel.fromJson(Map<String, dynamic> json) {
    return ImprovementModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      location: json['location'] ?? '',
      area: json['area'] ?? 'Ward 12',
      status: json['status'] ?? 'Pending',
      completionDate: json['completion_date'] ?? json['completionDate'],
      peopleBenefited: (json['metadata']?['people_benefited'] as num?)?.toInt() ??
          (json['people_benefited'] as num?)?.toInt() ??
          (json['peopleBenefited'] as num?)?.toInt(),
      estimatedBudget: (json['estimated_budget'] as num?)?.toDouble() ??
          (json['budget'] as num?)?.toDouble(),
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      proposedBy: json['proposed_by'] ?? json['proposedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'votes': votes,
      'location': location,
      'area': area,
      'status': status,
      'completion_date': completionDate,
      'people_benefited': peopleBenefited,
      'estimated_budget': estimatedBudget,
      'created_at': createdAt,
      'proposed_by': proposedBy,
    };
  }

  ImprovementModel copyWith({
    String? id,
    String? title,
    String? description,
    int? votes,
    String? location,
    String? area,
    String? status,
    String? completionDate,
    int? peopleBenefited,
    double? estimatedBudget,
    String? createdAt,
    String? proposedBy,
  }) {
    return ImprovementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      votes: votes ?? this.votes,
      location: location ?? this.location,
      area: area ?? this.area,
      status: status ?? this.status,
      completionDate: completionDate ?? this.completionDate,
      peopleBenefited: peopleBenefited ?? this.peopleBenefited,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      createdAt: createdAt ?? this.createdAt,
      proposedBy: proposedBy ?? this.proposedBy,
    );
  }

  // Helpers
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'complete':
        return const Color(0xFF16A34A);
      case 'in progress':
      case 'inprogress':
        return const Color(0xFF0284C7);
      case 'planned':
        return const Color(0xFF7E22CE);
      case 'pending':
      default:
        return const Color(0xFFEA580C);
    }
  }

  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'complete':
        return const Color(0xFFF0FDF4);
      case 'in progress':
      case 'inprogress':
        return const Color(0xFFEFF6FF);
      case 'planned':
        return const Color(0xFFFAF5FF);
      case 'pending':
      default:
        return const Color(0xFFFFF7ED);
    }
  }

  Color get statusBorderColor {
    switch (status.toLowerCase()) {
      case 'complete':
        return const Color(0xFFBBF7D0);
      case 'in progress':
      case 'inprogress':
        return const Color(0xFFBFDBFE);
      case 'planned':
        return const Color(0xFFE9D5FF);
      case 'pending':
      default:
        return const Color(0xFFFED7AA);
    }
  }

  String get statusDisplayEn {
    switch (status.toLowerCase()) {
      case 'complete':
        return 'Complete';
      case 'in progress':
      case 'inprogress':
        return 'In Progress';
      case 'planned':
        return 'Planned';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String get statusDisplayMr {
    switch (status.toLowerCase()) {
      case 'complete':
        return 'पूर्ण झाले';
      case 'in progress':
      case 'inprogress':
        return 'प्रगतीपथावर';
      case 'planned':
        return 'नियोजित';
      case 'pending':
      default:
        return 'प्रलंबित';
    }
  }
}

