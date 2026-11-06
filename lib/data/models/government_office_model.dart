import 'package:flutter/material.dart';

class GovernmentOfficeModel {
  final String id;
  final String name;
  final String officerName;
  final String contactNumber;
  final String? secondaryContact;
  final String address;
  final String area;
  final String category; // 'Municipal PMC', 'Police', 'MSEDCL Electricity', 'Water Supply', 'Health & Hospital', 'Fire & Disaster', 'Revenue & Post'
  final String timing;
  final String? email;
  final double? latitude;
  final double? longitude;
  final bool isEmergency;
  final String createdAt;

  const GovernmentOfficeModel({
    required this.id,
    required this.name,
    required this.officerName,
    required this.contactNumber,
    this.secondaryContact,
    required this.address,
    this.area = 'Ward 12',
    this.category = 'Municipal PMC',
    this.timing = '9:45 AM - 5:45 PM',
    this.email,
    this.latitude,
    this.longitude,
    this.isEmergency = false,
    required this.createdAt,
  });

  factory GovernmentOfficeModel.fromJson(Map<String, dynamic> json) {
    return GovernmentOfficeModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      officerName: json['officer_name'] ?? json['officerName'] ?? 'Officer In-Charge',
      contactNumber: json['contact_number'] ?? json['contactNumber'] ?? '',
      secondaryContact: json['secondary_contact'] ?? json['secondaryContact'],
      address: json['address'] ?? '',
      area: json['area'] ?? 'Ward 12',
      category: json['category'] ?? 'Municipal PMC',
      timing: json['timing'] ?? '9:45 AM - 5:45 PM',
      email: json['email'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isEmergency: json['is_emergency'] ?? json['isEmergency'] ?? false,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'officer_name': officerName,
      'contact_number': contactNumber,
      'secondary_contact': secondaryContact,
      'address': address,
      'area': area,
      'category': category,
      'timing': timing,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'is_emergency': isEmergency,
      'created_at': createdAt,
    };
  }

  GovernmentOfficeModel copyWith({
    String? id,
    String? name,
    String? officerName,
    String? contactNumber,
    String? secondaryContact,
    String? address,
    String? area,
    String? category,
    String? timing,
    String? email,
    double? latitude,
    double? longitude,
    bool? isEmergency,
    String? createdAt,
  }) {
    return GovernmentOfficeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      officerName: officerName ?? this.officerName,
      contactNumber: contactNumber ?? this.contactNumber,
      secondaryContact: secondaryContact ?? this.secondaryContact,
      address: address ?? this.address,
      area: area ?? this.area,
      category: category ?? this.category,
      timing: timing ?? this.timing,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isEmergency: isEmergency ?? this.isEmergency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'police':
        return const Color(0xFF1E40AF); // Dark Blue
      case 'fire & disaster':
      case 'emergency':
        return const Color(0xFFDC2626); // Red
      case 'msedcl electricity':
      case 'electricity':
        return const Color(0xFFD97706); // Amber
      case 'water supply':
        return const Color(0xFF0284C7); // Sky Blue
      case 'health & hospital':
      case 'health':
        return const Color(0xFF16A34A); // Green
      case 'revenue & post':
        return const Color(0xFF7C3AED); // Purple
      case 'municipal pmc':
      default:
        return const Color(0xFF0369A1); // Cyan Blue
    }
  }

  Color get categoryBgColor {
    switch (category.toLowerCase()) {
      case 'police':
        return const Color(0xFFEFF6FF);
      case 'fire & disaster':
      case 'emergency':
        return const Color(0xFFFEF2F2);
      case 'msedcl electricity':
      case 'electricity':
        return const Color(0xFFFFFBEB);
      case 'water supply':
        return const Color(0xFFF0F9FF);
      case 'health & hospital':
      case 'health':
        return const Color(0xFFF0FDF4);
      case 'revenue & post':
        return const Color(0xFFF5F3FF);
      case 'municipal pmc':
      default:
        return const Color(0xFFE0F2FE);
    }
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'police':
        return Icons.local_police_outlined;
      case 'fire & disaster':
      case 'emergency':
        return Icons.local_fire_department_outlined;
      case 'msedcl electricity':
      case 'electricity':
        return Icons.bolt_outlined;
      case 'water supply':
        return Icons.water_drop_outlined;
      case 'health & hospital':
      case 'health':
        return Icons.local_hospital_outlined;
      case 'revenue & post':
        return Icons.receipt_long_outlined;
      case 'municipal pmc':
      default:
        return Icons.account_balance_outlined;
    }
  }

  String get categoryDisplayMr {
    switch (category.toLowerCase()) {
      case 'police':
        return 'पोलीस ठाणे';
      case 'fire & disaster':
      case 'emergency':
        return 'अग्निशमन व आपत्ती';
      case 'msedcl electricity':
      case 'electricity':
        return 'महावितरण विद्युत';
      case 'water supply':
        return 'पाणी पुरवठा विभाग';
      case 'health & hospital':
      case 'health':
        return 'आरोग्य व रुग्णालय';
      case 'revenue & post':
        return 'महसूल व पोस्ट';
      case 'municipal pmc':
      default:
        return 'मनपा क्षेत्रीय कार्यालय';
    }
  }
}

