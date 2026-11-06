class TeamMemberModel {
  final String id;
  final String name;
  final String? nameMarathi;
  final String mobile;
  final String? email;
  final String role; // e.g. Office Admin, Sanitation Worker, Driver, Supervisor, Karyakarta
  final String? area;
  final String category; // 'Office', 'Party', 'Cooperative'
  final List<String> keywords; // Auto-assign keywords like 'पाणी', 'लाईट', 'गटार'
  final List<String>? permissions;
  final String? tenantId;
  final String? partyWing; // e.g. युवक आघाडी, महिला आघाडी, सोशल मीडिया सेल
  final String? paksh; // e.g. भाजप, राष्ट्रवादी, इ.
  final String? pad; // e.g. प्रभाग अध्यक्ष, सचिव, संघटक
  final String? societyName; // for Cooperative
  final bool canAssignWork;
  final String? avatarUrl;
  final DateTime? joinedDate;

  TeamMemberModel({
    required this.id,
    required this.name,
    this.nameMarathi,
    required this.mobile,
    this.email,
    required this.role,
    this.area,
    required this.category,
    this.keywords = const [],
    this.permissions,
    this.tenantId,
    this.partyWing,
    this.paksh,
    this.pad,
    this.societyName,
    this.canAssignWork = true,
    this.avatarUrl,
    this.joinedDate,
  });

  String get displayName => (nameMarathi != null && nameMarathi!.isNotEmpty) ? nameMarathi! : name;

  String get categoryLabelMarathi {
    switch (category.toLowerCase()) {
      case 'office':
        return 'कार्यालयीन टीम';
      case 'party':
        return 'पक्ष कार्यकर्ते';
      case 'cooperative':
        return 'शासकीय व सहकार';
      default:
        return category;
    }
  }

  String get roleLabelMarathi {
    switch (role.toLowerCase()) {
      case 'office admin':
        return 'कार्यालय प्रशासक';
      case 'supervisor':
        return 'क्षेत्रीय पर्यवेक्षक';
      case 'staff':
      case 'executive':
        return 'कार्यालयीन सहाय्यक';
      case 'driver':
        return 'अधिकृत चालक';
      case 'peon':
        return 'शिपाई व सेवक';
      case 'helper':
        return 'मदतनीस';
      case 'sanitation worker':
        return 'स्वच्छता समन्वयक';
      case 'karyakarta':
        return 'सक्रिय कार्यकर्ता';
      case 'it cell head':
        return 'आयटी व सोशल मीडिया प्रमुख';
      case 'pro':
        return 'जनसंपर्क अधिकारी';
      default:
        return role;
    }
  }

  TeamMemberModel copyWith({
    String? id,
    String? name,
    String? nameMarathi,
    String? mobile,
    String? email,
    String? role,
    String? area,
    String? category,
    List<String>? keywords,
    List<String>? permissions,
    String? tenantId,
    String? partyWing,
    String? paksh,
    String? pad,
    String? societyName,
    bool? canAssignWork,
    String? avatarUrl,
    DateTime? joinedDate,
  }) {
    return TeamMemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameMarathi: nameMarathi ?? this.nameMarathi,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      role: role ?? this.role,
      area: area ?? this.area,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      permissions: permissions ?? this.permissions,
      tenantId: tenantId ?? this.tenantId,
      partyWing: partyWing ?? this.partyWing,
      paksh: paksh ?? this.paksh,
      pad: pad ?? this.pad,
      societyName: societyName ?? this.societyName,
      canAssignWork: canAssignWork ?? this.canAssignWork,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedKeywords = [];
    if (json['keywords'] is List) {
      parsedKeywords = (json['keywords'] as List).map((e) => e.toString()).toList();
    } else if (json['keywords'] is String && (json['keywords'] as String).isNotEmpty) {
      parsedKeywords = (json['keywords'] as String).split(',').map((e) => e.trim()).toList();
    }

    List<String>? parsedPerms;
    if (json['permissions'] is List) {
      parsedPerms = (json['permissions'] as List).map((e) => e.toString()).toList();
    }

    DateTime? joined;
    if (json['created_at'] != null) {
      joined = DateTime.tryParse(json['created_at'].toString());
    }

    return TeamMemberModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameMarathi: json['name_marathi']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'Staff',
      area: json['area']?.toString(),
      category: json['category']?.toString() ?? 'Office',
      keywords: parsedKeywords,
      permissions: parsedPerms,
      tenantId: json['tenant_id']?.toString(),
      partyWing: json['party_wing']?.toString(),
      paksh: json['paksh']?.toString(),
      pad: json['pad']?.toString(),
      societyName: json['society_name']?.toString(),
      canAssignWork: json['can_assign_work'] ?? true,
      avatarUrl: json['avatar_url']?.toString(),
      joinedDate: joined,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_marathi': nameMarathi,
      'mobile': mobile,
      'email': email,
      'role': role,
      'area': area,
      'category': category,
      'keywords': keywords,
      'permissions': permissions,
      'tenant_id': tenantId,
      'party_wing': partyWing,
      'paksh': paksh,
      'pad': pad,
      'society_name': societyName,
      'can_assign_work': canAssignWork,
      'avatar_url': avatarUrl,
      'created_at': joinedDate?.toIso8601String(),
    };
  }
}

class TeamTaskModel {
  final String id;
  final String staffId;
  final String title;
  final String? description;
  final String priority; // 'Low', 'Medium', 'High'
  final String status; // 'Pending', 'In Progress', 'Completed'
  final DateTime? dueDate;
  final String? location;
  final DateTime createdAt;

  TeamTaskModel({
    required this.id,
    required this.staffId,
    required this.title,
    this.description,
    this.priority = 'Medium',
    this.status = 'Pending',
    this.dueDate,
    this.location,
    required this.createdAt,
  });

  String get statusLabelMarathi {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'resolved':
        return 'पूर्ण झाले';
      case 'in progress':
      case 'inprogress':
        return 'प्रगतीपथावर';
      case 'pending':
      default:
        return 'प्रलंबित';
    }
  }

  String get priorityLabelMarathi {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'तात्काळ (High)';
      case 'medium':
        return 'मध्यम (Medium)';
      case 'low':
      default:
        return 'सामान्य (Low)';
    }
  }

  TeamTaskModel copyWith({
    String? id,
    String? staffId,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? dueDate,
    String? location,
    DateTime? createdAt,
  }) {
    return TeamTaskModel(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TeamTaskModel.fromJson(Map<String, dynamic> json) {
    return TeamTaskModel(
      id: json['id']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? json['assigned_to']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Pending',
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      location: json['location']?.toString() ?? json['address']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

