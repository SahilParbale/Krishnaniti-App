import 'package:intl/intl.dart';

class KaryakartaWorkStaff {
  final String id;
  final String name;
  final String? nameMarathi;
  final String mobile;
  final String? email;
  final String role;
  final String? area;
  final String category; // 'Office' | 'Cooperative' | 'Party'
  final String? partyWing;
  final String? pad;
  final String? societyName;
  final String? avatarUrl;

  const KaryakartaWorkStaff({
    required this.id,
    required this.name,
    this.nameMarathi,
    required this.mobile,
    this.email,
    required this.role,
    this.area,
    required this.category,
    this.partyWing,
    this.pad,
    this.societyName,
    this.avatarUrl,
  });

  String get displayName => (nameMarathi != null && nameMarathi!.isNotEmpty) ? nameMarathi! : name;

  factory KaryakartaWorkStaff.fromJson(Map<String, dynamic> json) {
    return KaryakartaWorkStaff(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameMarathi: json['name_marathi']?.toString() ?? json['nameMarathi']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'Staff',
      area: json['area']?.toString(),
      category: json['category']?.toString() ?? 'Office',
      partyWing: json['party_wing']?.toString() ?? json['partyWing']?.toString(),
      pad: json['pad']?.toString(),
      societyName: json['society_name']?.toString() ?? json['societyName']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_marathi': nameMarathi,
    'mobile': mobile,
    'email': email,
    'role': role,
    'area': area,
    'category': category,
    'party_wing': partyWing,
    'pad': pad,
    'society_name': societyName,
    'avatar_url': avatarUrl,
  };
}

class KaryakartaWorkTask {
  final String id;
  final String title;
  final String? description;
  final String priority; // 'Low', 'Medium', 'High'
  final String status; // 'Pending', 'In Progress', 'Completed'
  final DateTime? dueDate;
  final String? dueTime;
  final String? address;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final DateTime createdAt;

  const KaryakartaWorkTask({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'Medium',
    this.status = 'Pending',
    this.dueDate,
    this.dueTime,
    this.address,
    this.assignedStaffId,
    this.assignedStaffName,
    required this.createdAt,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isInProgress => status.toLowerCase() == 'in progress' || status.toLowerCase() == 'inprogress';
  bool get isPending => status.toLowerCase() == 'pending';

  String get formattedDueDate {
    if (dueDate == null) return '-';
    return DateFormat('dd MMM yyyy').format(dueDate!);
  }

  KaryakartaWorkTask copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? dueDate,
    String? dueTime,
    String? address,
    String? assignedStaffId,
    String? assignedStaffName,
    DateTime? createdAt,
  }) {
    return KaryakartaWorkTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      address: address ?? this.address,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory KaryakartaWorkTask.fromJson(Map<String, dynamic> json) {
    return KaryakartaWorkTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Pending',
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      dueTime: json['due_time']?.toString(),
      address: json['address']?.toString() ?? json['location']?.toString(),
      assignedStaffId: json['assigned_staff_id']?.toString() ?? json['assigned_to']?.toString(),
      assignedStaffName: json['assigned_staff_name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority,
    'status': status,
    'due_date': dueDate?.toIso8601String().split('T').first,
    'due_time': dueTime,
    'address': address,
    'assigned_staff_id': assignedStaffId,
    if (tenantId != null) 'tenant_id': tenantId,
    'created_at': createdAt.toIso8601String(),
  };
}

class KaryakartaWorkComplaint {
  final String id;
  final String title;
  final String? description;
  final String? type;
  final String? area;
  final String? location;
  final String status; // 'Pending', 'Assigned', 'InProgress', 'Resolved', 'Closed'
  final String? voterName;
  final String? voterMobile;
  final String? assignedTo;
  final String? assignedStaffName;
  final DateTime createdAt;

  const KaryakartaWorkComplaint({
    required this.id,
    required this.title,
    this.description,
    this.type,
    this.area,
    this.location,
    required this.status,
    this.voterName,
    this.voterMobile,
    this.assignedTo,
    this.assignedStaffName,
    required this.createdAt,
  });

  bool get isResolved => status.toLowerCase() == 'resolved' || status.toLowerCase() == 'closed';
  bool get isInProgress => status.toLowerCase() == 'inprogress' || status.toLowerCase() == 'in progress';
  bool get isPending => status.toLowerCase() == 'pending' || status.toLowerCase() == 'assigned';

  String get formattedDate => DateFormat('dd MMM yyyy').format(createdAt);

  KaryakartaWorkComplaint copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? area,
    String? location,
    String? status,
    String? voterName,
    String? voterMobile,
    String? assignedTo,
    String? assignedStaffName,
    DateTime? createdAt,
  }) {
    return KaryakartaWorkComplaint(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      area: area ?? this.area,
      location: location ?? this.location,
      status: status ?? this.status,
      voterName: voterName ?? this.voterName,
      voterMobile: voterMobile ?? this.voterMobile,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory KaryakartaWorkComplaint.fromJson(Map<String, dynamic> json) {
    String? vName;
    String? vMob;
    if (json['voter'] != null && json['voter'] is Map) {
      final v = json['voter'] as Map;
      vName = v['name_marathi']?.toString() ?? v['name_english']?.toString();
      vMob = v['mobile']?.toString();
    } else {
      vName = json['citizen_name']?.toString() ?? json['voter_name']?.toString();
      vMob = json['citizen_mobile']?.toString() ?? json['voter_mobile']?.toString();
    }

    return KaryakartaWorkComplaint(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? json['category']?.toString(),
      area: json['area']?.toString(),
      location: json['location']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      voterName: vName,
      voterMobile: vMob,
      assignedTo: json['assigned_to']?.toString(),
      assignedStaffName: json['assigned_staff_name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'area': area,
    'location': location,
    'status': status,
    'assigned_to': assignedTo,
    if (tenantId != null) 'tenant_id': tenantId,
    'created_at': createdAt.toIso8601String(),
  };
}

class KaryakartaStaffWorkload {
  final KaryakartaWorkStaff staff;
  final List<KaryakartaWorkTask> tasks;
  final List<KaryakartaWorkComplaint> complaints;

  const KaryakartaStaffWorkload({
    required this.staff,
    required this.tasks,
    required this.complaints,
  });

  int get tasksTotal => tasks.length;
  int get tasksPending => tasks.where((t) => t.isPending || t.isInProgress).length;
  int get tasksCompleted => tasks.where((t) => t.isCompleted).length;

  int get complaintsTotal => complaints.length;
  int get complaintsPending => complaints.where((c) => c.isPending || c.isInProgress).length;
  int get complaintsCompleted => complaints.where((c) => c.isResolved).length;

  int get totalAssigned => tasksTotal + complaintsTotal;
  int get totalPending => tasksPending + complaintsPending;
  int get totalCompleted => tasksCompleted + complaintsCompleted;

  int get progressPct =>
      totalAssigned > 0 ? ((totalCompleted / totalAssigned) * 100).round() : 0;
}

class KaryakartaWorkloadSummary {
  final int totalLoad;
  final int pendingLoad;
  final int inProgressLoad;
  final int completedLoad;
  final int totalTasks;
  final int totalComplaints;

  const KaryakartaWorkloadSummary({
    required this.totalLoad,
    required this.pendingLoad,
    required this.inProgressLoad,
    required this.completedLoad,
    required this.totalTasks,
    required this.totalComplaints,
  });

  factory KaryakartaWorkloadSummary.empty() {
    return const KaryakartaWorkloadSummary(
      totalLoad: 0,
      pendingLoad: 0,
      inProgressLoad: 0,
      completedLoad: 0,
      totalTasks: 0,
      totalComplaints: 0,
    );
  }
}

