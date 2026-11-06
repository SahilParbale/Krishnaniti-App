import 'package:flutter/material.dart';

class WardMapPointModel {
  final String id;
  final String title;
  final String category; // 'Booth', 'CivilWorks', 'Amenity', 'ProblemSpot', 'Office'
  final String address;
  final double latitude;
  final double longitude;
  final String description;
  final double relativeX; // Normalized X coordinate on vector canvas (0.0 - 1.0)
  final double relativeY; // Normalized Y coordinate on vector canvas (0.0 - 1.0)
  final String? status;
  final String? photoUrl;

  const WardMapPointModel({
    required this.id,
    required this.title,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.relativeX,
    required this.relativeY,
    this.status,
    this.photoUrl,
  });

  Color get color {
    switch (category.toLowerCase()) {
      case 'booth':
        return const Color(0xFF2563EB); // Blue
      case 'civilworks':
        return const Color(0xFFEA580C); // Orange
      case 'amenity':
        return const Color(0xFF16A34A); // Green
      case 'problemspot':
        return const Color(0xFFDC2626); // Red
      case 'office':
        return const Color(0xFF7C3AED); // Purple
      default:
        return const Color(0xFF0284C7); // Sky Blue
    }
  }

  Color get bgColor => color.withValues(alpha: 0.15);

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'booth':
        return Icons.how_to_vote_rounded;
      case 'civilworks':
        return Icons.construction_rounded;
      case 'amenity':
        return Icons.park_rounded;
      case 'problemspot':
        return Icons.warning_amber_rounded;
      case 'office':
        return Icons.account_balance_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  String get categoryDisplay {
    switch (category.toLowerCase()) {
      case 'booth':
        return 'Polling Booth / मतदान केंद्र';
      case 'civilworks':
        return 'Civil Works / विकासकामे';
      case 'amenity':
        return 'Civic Amenity / नागरी सुविधा';
      case 'problemspot':
        return 'Problem Spot / समस्या ठिकाण';
      case 'office':
        return 'Ward Office / कार्यालय';
      default:
        return category;
    }
  }

  String get googleMapsUrl => 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  factory WardMapPointModel.fromJson(Map<String, dynamic> json) {
    return WardMapPointModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Amenity',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 18.5011,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8428,
      description: json['description']?.toString() ?? '',
      relativeX: (json['relative_x'] as num?)?.toDouble() ?? 0.5,
      relativeY: (json['relative_y'] as num?)?.toDouble() ?? 0.5,
      status: json['status']?.toString(),
      photoUrl: json['photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'relative_x': relativeX,
      'relative_y': relativeY,
      if (status != null) 'status': status,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
  }
}

