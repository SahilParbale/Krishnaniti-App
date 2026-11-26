class TenantModel {
  final String id;
  final String name;
  final String subdomain;
  final String tier; // 'nagarsevak' | 'amdar' | 'khasdar' | 'minister'
  final String plan; // 'basic' | 'pro' | 'advance'
  final Map<String, dynamic> config;

  const TenantModel({
    required this.id,
    required this.name,
    required this.subdomain,
    this.tier = 'nagarsevak',
    this.plan = 'basic',
    this.config = const {},
  });

  bool get isNagarsevak => tier.toLowerCase() == 'nagarsevak';
  bool get isAmdar => tier.toLowerCase() == 'amdar';
  bool get isKhasdar => tier.toLowerCase() == 'khasdar';
  bool get isMinister => tier.toLowerCase() == 'minister';

  String get displayNameEnglish =>
      (config['nagarsevak_name_english'] as String?)?.trim().isNotEmpty == true
          ? config['nagarsevak_name_english'] as String
          : (name.trim().isNotEmpty ? name : 'Nagar Sevak');

  String get displayNameMarathi =>
      (config['nagarsevak_name_marathi'] as String?)?.trim().isNotEmpty == true
          ? config['nagarsevak_name_marathi'] as String
          : displayNameEnglish;

  String get wardName =>
      (config['ward_name'] as String?)?.trim().isNotEmpty == true
          ? config['ward_name'] as String
          : '';

  String get partyName =>
      (config['party_name'] as String?)?.trim().isNotEmpty == true
          ? config['party_name'] as String
          : '';

  String? get profileImageUrl => config['profile_image_url'] as String?;
  String? get partyLogoUrl => config['party_logo_url'] as String?;

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final rawPlan = (json['plan'] as String? ?? 'basic').toLowerCase();
    final normalizedPlan = rawPlan == 'advanced' ? 'advance' : rawPlan;
    return TenantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subdomain: json['subdomain'] as String? ?? 'default',
      tier: (json['tier'] as String? ?? 'nagarsevak').toLowerCase(),
      plan: normalizedPlan,
      config: json['config'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['config'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subdomain': subdomain,
      'tier': tier,
      'plan': plan,
      'config': config,
    };
  }
}
