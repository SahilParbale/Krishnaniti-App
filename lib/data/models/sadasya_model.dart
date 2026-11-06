/// Sadasya (Party Member) model matching Nagarsevak-Managment schema and database
class SadasyaModel {
  final String id;
  final String name;
  final String? nameMarathi;
  final String? nameEnglish;
  final String mobile;
  final int age;
  final String gender; // 'M', 'F', 'O'
  final String? ward;
  final String? area;
  final String address;
  final String? addressMarathi;
  final String? addressEnglish;
  final bool isVoter;
  final String? voterId; // EPIC No
  final String? linkedVoterId;
  final String status; // 'Active', 'Inactive'
  final String? role; // e.g. 'बूथ प्रमुख', 'वॉर्ड समन्वयक', 'सक्रिय कार्यकर्ता'
  final DateTime registeredAt;
  final String? tenantId;

  const SadasyaModel({
    required this.id,
    required this.name,
    this.nameMarathi,
    this.nameEnglish,
    required this.mobile,
    this.age = 0,
    this.gender = 'M',
    this.ward,
    this.area,
    required this.address,
    this.addressMarathi,
    this.addressEnglish,
    this.isVoter = false,
    this.voterId,
    this.linkedVoterId,
    this.status = 'Active',
    this.role,
    required this.registeredAt,
    this.tenantId,
  });

  /// Display name preferring Marathi if available
  String get displayName {
    if (nameMarathi != null && nameMarathi!.trim().isNotEmpty) {
      return nameMarathi!;
    }
    return name;
  }

  /// Display address preferring Marathi if available
  String get displayAddress {
    if (addressMarathi != null && addressMarathi!.trim().isNotEmpty) {
      return addressMarathi!;
    }
    return address;
  }

  /// Display gender in Marathi
  String get displayGender {
    switch (gender.toUpperCase()) {
      case 'M':
        return 'पुरुष (Male)';
      case 'F':
        return 'स्त्री (Female)';
      case 'O':
        return 'इतर (Other)';
      default:
        return gender;
    }
  }

  /// Initials for avatar
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'स';
    if (parts.length == 1) return parts[0].substring(0, 1);
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}';
  }

  SadasyaModel copyWith({
    String? id,
    String? name,
    String? nameMarathi,
    String? nameEnglish,
    String? mobile,
    int? age,
    String? gender,
    String? ward,
    String? area,
    String? address,
    String? addressMarathi,
    String? addressEnglish,
    bool? isVoter,
    String? voterId,
    String? linkedVoterId,
    String? status,
    String? role,
    DateTime? registeredAt,
    String? tenantId,
  }) {
    return SadasyaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameMarathi: nameMarathi ?? this.nameMarathi,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      mobile: mobile ?? this.mobile,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      ward: ward ?? this.ward,
      area: area ?? this.area,
      address: address ?? this.address,
      addressMarathi: addressMarathi ?? this.addressMarathi,
      addressEnglish: addressEnglish ?? this.addressEnglish,
      isVoter: isVoter ?? this.isVoter,
      voterId: voterId ?? this.voterId,
      linkedVoterId: linkedVoterId ?? this.linkedVoterId,
      status: status ?? this.status,
      role: role ?? this.role,
      registeredAt: registeredAt ?? this.registeredAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  factory SadasyaModel.fromJson(Map<String, dynamic> json) {
    return SadasyaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_english'] ?? json['name_marathi'] ?? '',
      nameMarathi: json['name_marathi']?.toString(),
      nameEnglish: json['name_english']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      gender: json['gender']?.toString() ?? 'M',
      ward: json['ward']?.toString(),
      area: json['area']?.toString(),
      address: json['address']?.toString() ?? json['address_marathi'] ?? json['address_english'] ?? '',
      addressMarathi: json['address_marathi']?.toString(),
      addressEnglish: json['address_english']?.toString(),
      isVoter: json['is_voter'] == true || json['isVoter'] == true,
      voterId: json['voter_id']?.toString() ?? json['voterId']?.toString(),
      linkedVoterId: json['linked_voter_id']?.toString(),
      status: json['status']?.toString() ?? 'Active',
      role: json['role']?.toString() ?? json['designation']?.toString(),
      registeredAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['registeredAt'] != null
              ? DateTime.tryParse(json['registeredAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_marathi': nameMarathi,
      'name_english': nameEnglish,
      'mobile': mobile,
      'age': age,
      'gender': gender,
      'ward': ward,
      'area': area,
      'address': address,
      'address_marathi': addressMarathi,
      'address_english': addressEnglish,
      'is_voter': isVoter,
      'voter_id': voterId,
      'linked_voter_id': linkedVoterId,
      'status': status,
      'role': role,
      'created_at': registeredAt.toIso8601String(),
      'tenant_id': tenantId,
    };
  }
}
