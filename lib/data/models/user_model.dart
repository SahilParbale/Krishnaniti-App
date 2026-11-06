class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin', 'nagarsevak', 'amdar', 'khasdar', 'minister', 'staff', 'karyakarta'
  final bool isStaff;
  final List<String> permissions;
  final String? tenantId;
  final String? assignedWard;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isStaff = false,
    this.permissions = const [],
    this.tenantId,
    this.assignedWard,
  });

  bool get isAdmin => ['admin', 'nagarsevak', 'amdar', 'khasdar', 'minister'].contains(role);

  bool hasPermission(String permission) {
    if (isAdmin) return true;
    if (permissions.contains(permission)) return true;
    return false;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Representative',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'nagarsevak',
      isStaff: json['is_staff'] as bool? ?? false,
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tenantId: json['tenant_id'] as String?,
      assignedWard: json['assigned_ward'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_staff': isStaff,
      'permissions': permissions,
      'tenant_id': tenantId,
      'assigned_ward': assignedWard,
    };
  }
}
