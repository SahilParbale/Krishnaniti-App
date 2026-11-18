class LetterTypeModel {
  final String id;
  final String name;
  final String? nameMarathi;
  final String? description;
  final String? templateContent;
  final bool isActive;
  final String? tenantId;
  final DateTime? createdAt;

  const LetterTypeModel({
    required this.id,
    required this.name,
    this.nameMarathi,
    this.description,
    this.templateContent,
    this.isActive = true,
    this.tenantId,
    this.createdAt,
  });

  factory LetterTypeModel.fromJson(Map<String, dynamic> json) {
    return LetterTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameMarathi: json['name_marathi']?.toString(),
      description: json['description']?.toString(),
      templateContent: json['template_content']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == null,
      tenantId: json['tenant_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'name_marathi': nameMarathi,
      'description': description,
      'template_content': templateContent,
      'is_active': isActive,
      'tenant_id': tenantId ?? this.tenantId,
    };
  }

  LetterTypeModel copyWith({
    String? id,
    String? name,
    String? nameMarathi,
    String? description,
    String? templateContent,
    bool? isActive,
    String? tenantId,
    DateTime? createdAt,
  }) {
    return LetterTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameMarathi: nameMarathi ?? this.nameMarathi,
      description: description ?? this.description,
      templateContent: templateContent ?? this.templateContent,
      isActive: isActive ?? this.isActive,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
