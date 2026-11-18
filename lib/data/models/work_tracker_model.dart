class WorkTrackerMovementStage {
  final String id;
  final String workTrackerId;
  final String stageName;
  final String location;
  final String statusDescription;
  final String? updatedBy;
  final DateTime createdAt;
  final String? tenantId;

  const WorkTrackerMovementStage({
    required this.id,
    required this.workTrackerId,
    required this.stageName,
    required this.location,
    required this.statusDescription,
    this.updatedBy,
    required this.createdAt,
    this.tenantId,
  });

  factory WorkTrackerMovementStage.fromJson(Map<String, dynamic> json) {
    return WorkTrackerMovementStage(
      id: json['id']?.toString() ?? '',
      workTrackerId: json['work_tracker_id']?.toString() ?? '',
      stageName: json['stage_name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      statusDescription: json['status_description']?.toString() ?? '',
      updatedBy: json['updated_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'work_tracker_id': workTrackerId,
      'stage_name': stageName,
      'location': location,
      'status_description': statusDescription,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (tenantId != null) 'tenant_id': tenantId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class WorkTrackerModel {
  final String id;
  final String title;
  final String subject;
  final String department;
  final String inwardNumber;
  final String outwardNumber;
  final String currentStatus;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? tenantId;
  final List<WorkTrackerMovementStage> stages;

  const WorkTrackerModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.department,
    required this.inwardNumber,
    required this.outwardNumber,
    required this.currentStatus,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.tenantId,
    this.stages = const [],
  });

  factory WorkTrackerModel.fromJson(Map<String, dynamic> json, {List<WorkTrackerMovementStage> stages = const []}) {
    return WorkTrackerModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      inwardNumber: json['inward_number']?.toString() ?? '',
      outwardNumber: json['outward_number']?.toString() ?? '',
      currentStatus: json['current_status']?.toString() ?? 'Pending',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tenantId: json['tenant_id']?.toString(),
      stages: stages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'subject': subject,
      'department': department,
      'inward_number': inwardNumber,
      'outward_number': outwardNumber,
      'current_status': currentStatus,
      'description': description,
      if (tenantId != null) 'tenant_id': tenantId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
