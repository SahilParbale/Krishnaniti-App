import 'package:flutter/material.dart';

class SchemeModel {
  final int id;
  final String name;
  final String description;
  final String eligibility;
  final String benefits;
  final String documents;
  final String category;
  final DateTime? createdAt;
  final String? tenantId;

  const SchemeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.eligibility,
    required this.benefits,
    required this.documents,
    this.category = 'All',
    this.createdAt,
    this.tenantId,
  });

  // Extract English or Marathi based on 'English / Marathi' format used in Nagarsevak-Managment
  static String extractLocalized(String text, bool isMarathi) {
    if (text.isEmpty) return text;

    // Strict separator check ' / '
    final parts = text.split(' / ');
    if (parts.length == 2) {
      return isMarathi ? parts[1].trim() : parts[0].trim();
    }

    // Devanagari detection fallback
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    if (hasDevanagari) {
      if (isMarathi) {
        final match = RegExp(r'[\u0900-\u097F].*', dotAll: true).firstMatch(text);
        return match != null ? match.group(0)!.trim() : text;
      } else {
        final split = text.split(RegExp(r'[\u0900-\u097F]'));
        return split[0].trim().replaceAll(RegExp(r'[./]+$'), '');
      }
    }

    return text;
  }

  String localizedName(bool isMarathi) => extractLocalized(name, isMarathi);
  String localizedDescription(bool isMarathi) => extractLocalized(description, isMarathi);
  String localizedEligibility(bool isMarathi) => extractLocalized(eligibility, isMarathi);
  String localizedBenefits(bool isMarathi) => extractLocalized(benefits, isMarathi);
  String localizedDocuments(bool isMarathi) => extractLocalized(documents, isMarathi);

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'women':
        return Icons.female_rounded;
      case 'student':
        return Icons.school_rounded;
      case 'senior citizen':
        return Icons.elderly_rounded;
      case 'farmer':
        return Icons.agriculture_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'youth':
        return Icons.work_outline_rounded;
      case 'housing':
        return Icons.home_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  Color get color {
    switch (category.toLowerCase()) {
      case 'women':
        return const Color(0xFFDB2777); // Pink
      case 'student':
        return const Color(0xFF2563EB); // Blue
      case 'senior citizen':
        return const Color(0xFF7C3AED); // Purple
      case 'farmer':
        return const Color(0xFF16A34A); // Green
      case 'health':
        return const Color(0xFFDC2626); // Red
      case 'youth':
        return const Color(0xFFD97706); // Amber
      case 'housing':
        return const Color(0xFF0284C7); // Sky
      default:
        return const Color(0xFF475569); // Slate
    }
  }

  Color get bgColor => color.withValues(alpha: 0.12);

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      eligibility: json['eligibility']?.toString() ?? '',
      benefits: json['benefits']?.toString() ?? '',
      documents: json['documents']?.toString() ?? '',
      category: json['category']?.toString() ?? 'All',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'eligibility': eligibility,
      'benefits': benefits,
      'documents': documents,
      'category': category,
      if (tenantId != null) 'tenant_id': tenantId,
    };
  }

  SchemeModel copyWith({
    int? id,
    String? name,
    String? description,
    String? eligibility,
    String? benefits,
    String? documents,
    String? category,
    DateTime? createdAt,
    String? tenantId,
  }) {
    return SchemeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      eligibility: eligibility ?? this.eligibility,
      benefits: benefits ?? this.benefits,
      documents: documents ?? this.documents,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}

class SchemeApplicationModel {
  final int id;
  final int schemeId;
  final String? schemeName;
  final int? voterId;
  final String applicantName;
  final String mobile;
  final String address;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String? notes;
  final String? benefit;
  final String? rejectionReason;
  final DateTime createdAt;
  final String? tenantId;

  const SchemeApplicationModel({
    required this.id,
    required this.schemeId,
    this.schemeName,
    this.voterId,
    required this.applicantName,
    required this.mobile,
    required this.address,
    this.status = 'Pending',
    this.notes,
    this.benefit,
    this.rejectionReason,
    required this.createdAt,
    this.tenantId,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPending => status.toLowerCase() == 'pending';

  Color get statusColor {
    if (isApproved) return const Color(0xFF16A34A);
    if (isRejected) return const Color(0xFFDC2626);
    return const Color(0xFFD97706);
  }

  Color get statusBgColor {
    if (isApproved) return const Color(0xFFDCFCE7);
    if (isRejected) return const Color(0xFFFEE2E2);
    return const Color(0xFFFEF3C7);
  }

  factory SchemeApplicationModel.fromJson(Map<String, dynamic> json) {
    String? schemeTitle;
    if (json['schemes'] is Map<String, dynamic>) {
      schemeTitle = json['schemes']['name']?.toString();
    } else if (json['scheme_name'] != null) {
      schemeTitle = json['scheme_name']?.toString();
    }

    return SchemeApplicationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      schemeId: json['scheme_id'] is int ? json['scheme_id'] : int.tryParse(json['scheme_id']?.toString() ?? '0') ?? 0,
      schemeName: schemeTitle,
      voterId: json['voter_id'] is int ? json['voter_id'] : int.tryParse(json['voter_id']?.toString() ?? ''),
      applicantName: json['applicant_name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      notes: json['notes']?.toString(),
      benefit: json['benefit']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheme_id': schemeId,
      if (voterId != null) 'voter_id': voterId,
      'applicant_name': applicantName,
      'mobile': mobile,
      'address': address,
      'status': status,
      if (notes != null) 'notes': notes,
      if (benefit != null) 'benefit': benefit,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (tenantId != null) 'tenant_id': tenantId,
    };
  }

  SchemeApplicationModel copyWith({
    int? id,
    int? schemeId,
    String? schemeName,
    int? voterId,
    String? applicantName,
    String? mobile,
    String? address,
    String? status,
    String? notes,
    String? benefit,
    String? rejectionReason,
    DateTime? createdAt,
    String? tenantId,
  }) {
    return SchemeApplicationModel(
      id: id ?? this.id,
      schemeId: schemeId ?? this.schemeId,
      schemeName: schemeName ?? this.schemeName,
      voterId: voterId ?? this.voterId,
      applicantName: applicantName ?? this.applicantName,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      benefit: benefit ?? this.benefit,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}

