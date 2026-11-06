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
    return StaffModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Staff',
      mobile: json['mobile']?.toString(),
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

