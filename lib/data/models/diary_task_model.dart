import 'package:intl/intl.dart';

class DiaryTaskModel {
  final String id;
  final String title;
  final String? description;
  final String priority; // 'Low', 'Medium', 'High'
  final String status; // 'Pending', 'Completed', 'InProgress'
  final DateTime? dueDate;
  final String? dueTime; // e.g. '10:30', '16:00'
  final String? address;
  final String? officeName;
  final String? meetPersonName;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final DateTime? createdAt;
  final String? tenantId;

  DiaryTaskModel({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'Medium',
    this.status = 'Pending',
    this.dueDate,
    this.dueTime,
    this.address,
    this.officeName,
    this.meetPersonName,
    this.assignedStaffId,
    this.assignedStaffName,
    this.createdAt,
    this.tenantId,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isInProgress => status.toLowerCase() == 'inprogress' || status.toLowerCase() == 'in progress';

  bool get isHighPriority => priority.toLowerCase() == 'high';
  bool get isMediumPriority => priority.toLowerCase() == 'medium';
  bool get isLowPriority => priority.toLowerCase() == 'low';

  String get formattedDate {
    if (dueDate == null) return '-';
    return DateFormat('MMM d, yyyy').format(dueDate!);
  }

  String get formattedTime {
    if (dueTime == null || dueTime!.isEmpty) return '';
    try {
      final parts = dueTime!.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final dt = DateTime(2026, 1, 1, hour, min);
        return DateFormat('hh:mm a').format(dt);
      }
    } catch (_) {}
    return dueTime!;
  }

  factory DiaryTaskModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return DiaryTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Pending',
      dueDate: parseDate(json['due_date'] ?? json['dueDate']),
      dueTime: json['due_time']?.toString() ?? json['dueTime']?.toString(),
      address: json['address']?.toString(),
      officeName: json['office_name']?.toString() ?? json['officeName']?.toString(),
      meetPersonName: json['meet_person_name']?.toString() ?? json['meetPersonName']?.toString(),
      assignedStaffId: json['assigned_staff_id']?.toString() ?? json['assignedStaffId']?.toString(),
      assignedStaffName: json['assigned_staff_name']?.toString() ?? json['assigned_to']?.toString(),
      createdAt: parseDate(json['created_at']),
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'due_date': dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate!) : null,
      'due_time': dueTime,
      'address': address,
      'office_name': officeName,
      'meet_person_name': meetPersonName,
      'assigned_staff_id': assignedStaffId,
      'assigned_to': assignedStaffName,
      if (tenantId != null) 'tenant_id': tenantId,
    };
  }

  DiaryTaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? dueDate,
    String? dueTime,
    String? address,
    String? officeName,
    String? meetPersonName,
    String? assignedStaffId,
    String? assignedStaffName,
    DateTime? createdAt,
    String? tenantId,
  }) {
    return DiaryTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      address: address ?? this.address,
      officeName: officeName ?? this.officeName,
      meetPersonName: meetPersonName ?? this.meetPersonName,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      createdAt: createdAt ?? this.createdAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}

