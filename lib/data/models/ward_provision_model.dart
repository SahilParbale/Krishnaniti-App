import 'package:flutter/material.dart';

class WardProvisionModel {
  final String id;
  final String title;
  final String description;
  final double requestedAmount;
  final double? sanctionedAmount;
  final String requestedDate;
  final String? sanctionedDate;
  final String status; // 'Pending' | 'Approved' | 'Partially Approved' | 'Rejected'
  final String financialYear; // e.g. '2024-2025'
  final String category;
  final String area;
  final String letterReference;

  const WardProvisionModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.requestedAmount,
    this.sanctionedAmount,
    required this.requestedDate,
    this.sanctionedDate,
    this.status = 'Pending',
    this.financialYear = '2024-2025',
    required this.category,
    required this.area,
    required this.letterReference,
  });

  factory WardProvisionModel.fromJson(Map<String, dynamic> json) {
    return WardProvisionModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requestedAmount: (json['requested_amount'] as num?)?.toDouble() ??
          (json['requestedAmount'] as num?)?.toDouble() ??
          0.0,
      sanctionedAmount: (json['sanctioned_amount'] as num?)?.toDouble() ??
          (json['sanctionedAmount'] as num?)?.toDouble(),
      requestedDate: json['requested_date'] ?? json['requestedDate'] ?? '',
      sanctionedDate: json['sanctioned_date'] ?? json['sanctionedDate'],
      status: json['status'] ?? 'Pending',
      financialYear: json['financial_year'] ?? json['financialYear'] ?? '2024-2025',
      category: json['category'] ?? 'General',
      area: json['area'] ?? 'Ward 12',
      letterReference: json['letter_reference'] ?? json['letterReference'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requested_amount': requestedAmount,
      'sanctioned_amount': sanctionedAmount,
      'requested_date': requestedDate,
      'sanctioned_date': sanctionedDate,
      'status': status,
      'financial_year': financialYear,
      'category': category,
      'area': area,
      'letter_reference': letterReference,
    };
  }

  WardProvisionModel copyWith({
    String? id,
    String? title,
    String? description,
    double? requestedAmount,
    double? sanctionedAmount,
    String? requestedDate,
    String? sanctionedDate,
    String? status,
    String? financialYear,
    String? category,
    String? area,
    String? letterReference,
  }) {
    return WardProvisionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      sanctionedAmount: sanctionedAmount ?? this.sanctionedAmount,
      requestedDate: requestedDate ?? this.requestedDate,
      sanctionedDate: sanctionedDate ?? this.sanctionedDate,
      status: status ?? this.status,
      financialYear: financialYear ?? this.financialYear,
      category: category ?? this.category,
      area: area ?? this.area,
      letterReference: letterReference ?? this.letterReference,
    );
  }

  // Helpers
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'partially approved':
      case 'partially_approved':
      case 'partial':
        return const Color(0xFF0284C7);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'pending':
      default:
        return const Color(0xFFCA8A04);
    }
  }

  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFF0FDF4);
      case 'partially approved':
      case 'partially_approved':
      case 'partial':
        return const Color(0xFFEFF6FF);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      case 'pending':
      default:
        return const Color(0xFFFEFCE8);
    }
  }

  Color get statusBorderColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFBBF7D0);
      case 'partially approved':
      case 'partially_approved':
      case 'partial':
        return const Color(0xFFBFDBFE);
      case 'rejected':
        return const Color(0xFFFECACA);
      case 'pending':
      default:
        return const Color(0xFFFEF08A);
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'partially approved':
      case 'partially_approved':
      case 'partial':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'pending':
      default:
        return Icons.access_time_rounded;
    }
  }

  String get statusDisplayEn {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'partially approved':
      case 'partially_approved':
      case 'partial':
        return 'Partially Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String get statusDisplayMr {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'मंजूर';
      case 'partially approved':
      case 'partially_approved':
      case 'partial':
        return 'अंशतः मंजूर';
      case 'rejected':
        return 'नाकारले';
      case 'pending':
      default:
        return 'प्रलंबित';
    }
  }

  double get effectiveAmount => sanctionedAmount ?? requestedAmount;

  double get sanctionPercentage {
    if (requestedAmount <= 0) return 0;
    final sanc = sanctionedAmount ?? 0;
    return (sanc / requestedAmount) * 100;
  }
}

