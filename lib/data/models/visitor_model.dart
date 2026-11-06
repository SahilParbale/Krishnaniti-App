import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisitorModel {
  final String id;
  final String name;
  final String mobile;
  final String purpose; // 'Complaint', 'Meeting', 'Greeting', 'Donation', 'Help', 'Other'
  final String? reference;
  final String? area;
  final String? remarks;
  final DateTime visitDate;
  final String status;
  final String? eventDate;
  final String? eventTime;
  final String? amount;
  final String? tenantId;

  VisitorModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.purpose,
    this.reference,
    this.area,
    this.remarks,
    required this.visitDate,
    this.status = 'CheckedIn',
    this.eventDate,
    this.eventTime,
    this.amount,
    this.tenantId,
  });

  bool get isToday {
    final now = DateTime.now();
    return visitDate.year == now.year &&
        visitDate.month == now.month &&
        visitDate.day == now.day;
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(visitDate);
  }

  String get formattedTime {
    return DateFormat('hh:mm a').format(visitDate);
  }

  Color get purposeColor {
    switch (purpose.toLowerCase()) {
      case 'complaint':
        return const Color(0xFFDC2626); // red-600
      case 'meeting':
        return const Color(0xFF0284C7); // blue-600
      case 'greeting':
      case 'invitation':
        return const Color(0xFF7C3AED); // purple-600
      case 'donation':
      case 'help':
        return const Color(0xFF16A34A); // green-600
      default:
        return const Color(0xFF475569); // slate-600
    }
  }

  Color get purposeBgColor {
    switch (purpose.toLowerCase()) {
      case 'complaint':
        return const Color(0xFFFEF2F2);
      case 'meeting':
        return const Color(0xFFF0F9FF);
      case 'greeting':
      case 'invitation':
        return const Color(0xFFF5F3FF);
      case 'donation':
      case 'help':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    // Handle metadata or message JSON
    Map<String, dynamic>? meta;
    if (json['metadata'] is Map) {
      meta = Map<String, dynamic>.from(json['metadata'] as Map);
    } else if (json['message'] is Map) {
      meta = Map<String, dynamic>.from(json['message'] as Map);
    }

    return VisitorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? 'Meeting',
      reference: json['reference']?.toString(),
      area: json['area']?.toString(),
      remarks: json['remarks']?.toString(),
      visitDate: parseDate(json['visit_date'] ?? json['created_at']),
      status: json['status']?.toString() ?? 'CheckedIn',
      eventDate: meta?['event_date']?.toString(),
      eventTime: meta?['event_time']?.toString(),
      amount: meta?['amount']?.toString(),
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) {
    return {
      'name': name,
      'mobile': mobile,
      'purpose': purpose,
      'reference': reference,
      'area': area,
      'remarks': remarks,
      'visit_date': visitDate.toIso8601String(),
      'status': status,
      'metadata': {
        if (eventDate != null && eventDate!.isNotEmpty) 'event_date': eventDate,
        if (eventTime != null && eventTime!.isNotEmpty) 'event_time': eventTime,
        if (amount != null && amount!.isNotEmpty) 'amount': amount,
      },
      if (tenantId != null) 'tenant_id': tenantId,
    };
  }

  VisitorModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? purpose,
    String? reference,
    String? area,
    String? remarks,
    DateTime? visitDate,
    String? status,
    String? eventDate,
    String? eventTime,
    String? amount,
    String? tenantId,
  }) {
    return VisitorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      purpose: purpose ?? this.purpose,
      reference: reference ?? this.reference,
      area: area ?? this.area,
      remarks: remarks ?? this.remarks,
      visitDate: visitDate ?? this.visitDate,
      status: status ?? this.status,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      amount: amount ?? this.amount,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}

