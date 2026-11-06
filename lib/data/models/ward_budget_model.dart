import 'package:flutter/material.dart';

class WardBudgetModel {
  final String id;
  final String financialYear; // '2024-2025', '2023-2024', etc.
  final String category; // 'Road Maintenance', 'Water Supply', etc.
  final double totalAllocation;
  final double utilizedAmount;
  final String area;
  final String status; // 'Active' | 'Closed'
  final String createdAt;
  final String updatedAt;

  const WardBudgetModel({
    required this.id,
    this.financialYear = '2024-2025',
    required this.category,
    required this.totalAllocation,
    this.utilizedAmount = 0.0,
    this.area = 'Ward 12',
    this.status = 'Active',
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => (totalAllocation - utilizedAmount).clamp(0.0, double.infinity);

  double get utilizationPercentage {
    if (totalAllocation <= 0) return 0.0;
    return (utilizedAmount / totalAllocation) * 100.0;
  }

  Color get progressColor {
    final pct = utilizationPercentage;
    if (pct >= 80.0) return const Color(0xFF16A34A); // Green
    if (pct >= 50.0) return const Color(0xFFCA8A04); // Yellow / Amber
    return const Color(0xFFDC2626); // Red / Low utilization
  }

  Color get progressBgColor {
    final pct = utilizationPercentage;
    if (pct >= 80.0) return const Color(0xFFF0FDF4);
    if (pct >= 50.0) return const Color(0xFFFEFCE8);
    return const Color(0xFFFEF2F2);
  }

  Color get progressBorderColor {
    final pct = utilizationPercentage;
    if (pct >= 80.0) return const Color(0xFFBBF7D0);
    if (pct >= 50.0) return const Color(0xFFFEF08A);
    return const Color(0xFFFECACA);
  }

  Color get statusColor => status == 'Active' ? const Color(0xFF16A34A) : const Color(0xFF64748B);
  Color get statusBgColor => status == 'Active' ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9);

  factory WardBudgetModel.fromJson(Map<String, dynamic> json) {
    return WardBudgetModel(
      id: json['id']?.toString() ?? '',
      financialYear: json['financial_year'] ?? json['financialYear'] ?? '2024-2025',
      category: json['category'] ?? json['title'] ?? 'General Development',
      totalAllocation: (json['total_allocation'] ?? json['sanctioned_amount'] ?? json['totalAllocation'] ?? 0.0).toDouble(),
      utilizedAmount: (json['utilized_amount'] ?? json['requested_amount'] ?? json['utilizedAmount'] ?? 0.0).toDouble(),
      area: json['area'] ?? 'Ward 12',
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      updatedAt: json['updated_at'] ?? json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'financial_year': financialYear,
      'category': category,
      'total_allocation': totalAllocation,
      'utilized_amount': utilizedAmount,
      'area': area,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  WardBudgetModel copyWith({
    String? id,
    String? financialYear,
    String? category,
    double? totalAllocation,
    double? utilizedAmount,
    String? area,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return WardBudgetModel(
      id: id ?? this.id,
      financialYear: financialYear ?? this.financialYear,
      category: category ?? this.category,
      totalAllocation: totalAllocation ?? this.totalAllocation,
      utilizedAmount: utilizedAmount ?? this.utilizedAmount,
      area: area ?? this.area,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

