/// Represents a Cooperative Housing Society in the ward / constituency
class HousingSocietyModel {
  final String id;
  final String? tenantId;
  final String name;
  final String? nameMarathi;
  final String? nameEnglish;
  final String chairmanName;
  final String chairmanMobile;
  final String secretaryName;
  final String secretaryMobile;
  final int voterCount;
  final int favourableVoterCount;
  final String area;
  final String address;
  final String notes;
  /// 'Active' | 'Inactive'
  final String status;
  final DateTime? createdAt;

  const HousingSocietyModel({
    required this.id,
    this.tenantId,
    required this.name,
    this.nameMarathi,
    this.nameEnglish,
    this.chairmanName = '',
    this.chairmanMobile = '',
    this.secretaryName = '',
    this.secretaryMobile = '',
    this.voterCount = 0,
    this.favourableVoterCount = 0,
    this.area = '',
    this.address = '',
    this.notes = '',
    this.status = 'Active',
    this.createdAt,
  });

  /// Favourable support percentage (0 - 100%)
  int get supportPercentage {
    if (voterCount <= 0) return 0;
    final pct = (favourableVoterCount / voterCount) * 100;
    return pct.clamp(0, 100).round();
  }

  /// Non-favourable or neutral voters count
  int get otherVotersCount {
    if (voterCount <= favourableVoterCount) return 0;
    return voterCount - favourableVoterCount;
  }

  /// Display name preferring Marathi if present or fallback
  String displayName([bool isMr = true]) {
    if (isMr) {
      if (nameMarathi != null && nameMarathi!.trim().isNotEmpty) {
        return nameMarathi!.trim();
      }
    } else {
      if (nameEnglish != null && nameEnglish!.trim().isNotEmpty) {
        return nameEnglish!.trim();
      }
    }
    return name.trim();
  }

  /// Subtitle or secondary name
  String? secondaryName([bool isMr = true]) {
    if (isMr) {
      if (nameEnglish != null && nameEnglish!.trim().isNotEmpty && nameEnglish != nameMarathi) {
        return nameEnglish!.trim();
      }
    } else {
      if (nameMarathi != null && nameMarathi!.trim().isNotEmpty && nameMarathi != nameEnglish) {
        return nameMarathi!.trim();
      }
    }
    return null;
  }

  factory HousingSocietyModel.fromJson(Map<String, dynamic> json) {
    return HousingSocietyModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      name: json['name']?.toString() ?? '',
      nameMarathi: json['name_marathi']?.toString() ?? json['name']?.toString(),
      nameEnglish: json['name_english']?.toString(),
      chairmanName: json['chairman_name']?.toString() ?? '',
      chairmanMobile: json['chairman_mobile']?.toString() ?? '',
      secretaryName: json['secretary_name']?.toString() ?? '',
      secretaryMobile: json['secretary_mobile']?.toString() ?? '',
      voterCount: int.tryParse(json['voter_count']?.toString() ?? '') ?? 0,
      favourableVoterCount: int.tryParse(json['favourable_voter_count']?.toString() ?? '') ?? 0,
      area: json['area']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      'name': name,
      'name_marathi': nameMarathi ?? name,
      'name_english': nameEnglish ?? name,
      'chairman_name': chairmanName,
      'chairman_mobile': chairmanMobile,
      'secretary_name': secretaryName,
      'secretary_mobile': secretaryMobile,
      'voter_count': voterCount,
      'favourable_voter_count': favourableVoterCount,
      'area': area,
      'address': address,
      'notes': notes,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  HousingSocietyModel copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? nameMarathi,
    String? nameEnglish,
    String? chairmanName,
    String? chairmanMobile,
    String? secretaryName,
    String? secretaryMobile,
    int? voterCount,
    int? favourableVoterCount,
    String? area,
    String? address,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return HousingSocietyModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      nameMarathi: nameMarathi ?? this.nameMarathi,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      chairmanName: chairmanName ?? this.chairmanName,
      chairmanMobile: chairmanMobile ?? this.chairmanMobile,
      secretaryName: secretaryName ?? this.secretaryName,
      secretaryMobile: secretaryMobile ?? this.secretaryMobile,
      voterCount: voterCount ?? this.voterCount,
      favourableVoterCount: favourableVoterCount ?? this.favourableVoterCount,
      area: area ?? this.area,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

