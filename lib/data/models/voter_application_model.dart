import 'package:flutter/material.dart';

/// Represents a constituent's voter form application (Form 6, Form 7, Form 8, Search)
class VoterApplicationModel {
  final String id;
  final String? tenantId;
  final String? voterId;
  final String applicantName;
  final String? applicantMobile;
  /// 'Form 6' | 'Form 7' | 'Form 8' | 'Search'
  final String formType;
  /// 'Submitted' | 'Pending' | 'Approved' | 'Rejected'
  final String status;
  final String? notes;
  final DateTime createdAt;

  const VoterApplicationModel({
    required this.id,
    this.tenantId,
    this.voterId,
    required this.applicantName,
    this.applicantMobile,
    required this.formType,
    this.status = 'Submitted',
    this.notes,
    required this.createdAt,
  });

  /// Marathi Form Type Label
  String get formTypeMarathi => formTypeLabel('mr');

  /// Localized Form Type Label
  String formTypeLabel(String lang) {
    switch (formType.toLowerCase().replaceAll(' ', '')) {
      case 'form6':
        return lang == 'mr'
            ? 'फॉर्म ६ (नवीन नोंदणी)'
            : (lang == 'hi' ? 'फॉर्म ६ (नया पंजीकरण)' : 'Form 6 (New Reg)');
      case 'form7':
        return lang == 'mr'
            ? 'फॉर्म ७ (नाव वगळणे)'
            : (lang == 'hi' ? 'फॉर्म ७ (नाम विलोपन)' : 'Form 7 (Deletion)');
      case 'form8':
        return lang == 'mr'
            ? 'फॉर्म ८ (तपशील दुरुस्ती)'
            : (lang == 'hi' ? 'फॉर्म ८ (विवरण सुधार)' : 'Form 8 (Correction)');
      case 'search':
        return lang == 'mr'
            ? 'मतदार यादीत शोध'
            : (lang == 'hi' ? 'मतदाता सूची खोज' : 'Roll Search');
      default:
        return formType;
    }
  }

  /// Marathi Status Label
  String get statusMarathi => statusLabel('mr');

  /// Localized Status Label
  String statusLabel(String lang) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return lang == 'mr'
            ? 'दाखल केला'
            : (lang == 'hi' ? 'जमा किया गया' : 'Submitted');
      case 'pending':
        return lang == 'mr'
            ? 'प्रलंबित'
            : (lang == 'hi' ? 'लंबित' : 'Pending');
      case 'approved':
        return lang == 'mr'
            ? 'मंजूर'
            : (lang == 'hi' ? 'स्वीकृत' : 'Approved');
      case 'rejected':
        return lang == 'mr'
            ? 'नाकारला'
            : (lang == 'hi' ? 'अस्वीकृत' : 'Rejected');
      default:
        return status;
    }
  }

  /// Status Text Color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF047857);
      case 'rejected':
        return const Color(0xFFB91C1C);
      case 'pending':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF0369A1);
    }
  }

  /// Status Background Color
  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFECFDF5);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      case 'pending':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFF0F9FF);
    }
  }

  /// Status Border Color
  Color get statusBorderColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFA7F3D0);
      case 'rejected':
        return const Color(0xFFFECACA);
      case 'pending':
        return const Color(0xFFFDE68A);
      default:
        return const Color(0xFFBAE6FD);
    }
  }

  factory VoterApplicationModel.fromJson(Map<String, dynamic> json) {
    return VoterApplicationModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      voterId: json['voter_id']?.toString(),
      applicantName: json['applicant_name']?.toString() ?? '',
      applicantMobile: json['applicant_mobile']?.toString(),
      formType: json['form_type']?.toString() ?? 'Form 6',
      status: json['status']?.toString() ?? 'Submitted',
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (voterId != null) 'voter_id': voterId,
      'applicant_name': applicantName,
      'applicant_mobile': applicantMobile,
      'form_type': formType,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VoterApplicationModel copyWith({
    String? id,
    String? tenantId,
    String? voterId,
    String? applicantName,
    String? applicantMobile,
    String? formType,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return VoterApplicationModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      voterId: voterId ?? this.voterId,
      applicantName: applicantName ?? this.applicantName,
      applicantMobile: applicantMobile ?? this.applicantMobile,
      formType: formType ?? this.formType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

