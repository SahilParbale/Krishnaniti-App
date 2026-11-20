class StaffModel {
  final String id;
  final String name;
  final String? role;
  final String? mobile;
  final String? email;
  final String? tenantId;

  StaffModel({
    required this.id,
    required this.name,
    this.role,
    this.mobile,
    this.email,
    this.tenantId,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    String resolvedName = json['name']?.toString() ?? '';
    if (resolvedName.trim().isEmpty) {
      resolvedName = json['name_marathi']?.toString() ??
          json['name_english']?.toString() ??
          json['full_name']?.toString() ??
          'Staff Member';
    }
    return StaffModel(
      id: json['id']?.toString() ?? '',
      name: resolvedName,
      role: json['role']?.toString() ?? json['category']?.toString() ?? 'Staff',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString(),
      email: json['email']?.toString(),
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'mobile': mobile,
    'email': email,
    'tenant_id': tenantId,
  };
}

