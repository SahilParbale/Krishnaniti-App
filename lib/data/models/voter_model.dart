class VoterModel {
  final String id;
  final String nameMarathi;
  final String nameEnglish;
  final String epicNo;
  final String booth;
  final int? serialNo;
  final String address;
  final String? houseNo;
  final int age;
  final String gender; // 'M', 'F', 'O'
  final String? mobile;
  final String? caste;
  final String? favour; // 'Favourable', 'Against', 'Neutral', 'Swing'
  final bool isFriendRelative;
  final String? tenantId;
  final String? pollingStation;
  final String? relationType; // 'Self', 'Spouse', 'Son', 'Daughter', 'Father', 'Mother'

  VoterModel({
    required this.id,
    required this.nameMarathi,
    required this.nameEnglish,
    required this.epicNo,
    required this.booth,
    this.serialNo,
    required this.address,
    this.houseNo,
    required this.age,
    required this.gender,
    this.mobile,
    this.caste,
    this.favour,
    this.isFriendRelative = false,
    this.tenantId,
    this.pollingStation,
    this.relationType,
  });

  String get displayName => nameMarathi.isNotEmpty ? nameMarathi : nameEnglish;

  String displayNameFor(String lang) {
    if (lang == 'en' && nameEnglish.trim().isNotEmpty) {
      return nameEnglish;
    }
    return nameMarathi.trim().isNotEmpty ? nameMarathi : nameEnglish;
  }

  String get genderLabelMarathi {
    switch (gender.toUpperCase()) {
      case 'F':
        return 'महिला';
      case 'M':
        return 'पुरुष';
      default:
        return 'इतर';
    }
  }

  String genderLabel(String lang) {
    final g = gender.toUpperCase();
    if (g == 'F') {
      return lang == 'mr' ? 'महिला' : (lang == 'hi' ? 'महिला' : 'Female');
    }
    if (g == 'M') {
      return lang == 'mr' ? 'पुरुष' : (lang == 'hi' ? 'पुरुष' : 'Male');
    }
    return lang == 'mr' ? 'इतर' : (lang == 'hi' ? 'अन्य' : 'Other');
  }

  String get favourLabelMarathi {
    switch (favour?.toLowerCase()) {
      case 'favourable':
        return 'अनुकूल';
      case 'against':
        return 'प्रतिकूल';
      case 'neutral':
        return 'तटस्थ';
      case 'swing':
        return 'अनिश्चित';
      default:
        return 'नोंद नाही';
    }
  }

  String favourLabel(String lang) {
    switch (favour?.toLowerCase()) {
      case 'favourable':
        return lang == 'mr' ? 'अनुकूल' : (lang == 'hi' ? 'अनुकूल' : 'Favourable');
      case 'against':
        return lang == 'mr' ? 'प्रतिकूल' : (lang == 'hi' ? 'प्रतिकूल' : 'Against');
      case 'neutral':
        return lang == 'mr' ? 'तटस्थ' : (lang == 'hi' ? 'तटस्थ' : 'Neutral');
      case 'swing':
        return lang == 'mr' ? 'अनिश्चित' : (lang == 'hi' ? 'अनिश्चित' : 'Undecided');
      default:
        return lang == 'mr' ? 'नोंद नाही' : (lang == 'hi' ? 'दर्ज नहीं' : 'Not Tagged');
    }
  }

  String get displayPollingStation => displayPollingStationFor('mr');

  String displayPollingStationFor(String lang) {
    if (pollingStation != null && pollingStation!.isNotEmpty) {
      return pollingStation!;
    }
    // Standard booth-to-station mapping in Prabhag 12 (Kasba Peth - 214)
    if (booth.contains('28') || booth.contains('२८')) {
      return lang == 'en'
          ? 'New English School, Shaniwar Peth, Pune - 411030'
          : (lang == 'hi'
              ? 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३०'
              : 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३०');
    } else if (booth.contains('29') || booth.contains('२९')) {
      return lang == 'en'
          ? 'Pune Municipal School No. 15 (Boys), Kasba Peth, Pune'
          : (lang == 'hi'
              ? 'पुणे मनपा स्कूल क्र. १५ (लड़के), कसबा पेठ, पुणे'
              : 'पुणे मनपा शाळा क्र. १५ (मुलांची), कसबा पेठ, पुणे');
    } else if (booth.contains('30') || booth.contains('३०')) {
      return lang == 'en'
          ? 'Ahilyadevi High School, Shaniwar Peth, Pune - 411030'
          : (lang == 'hi'
              ? 'अहिल्यादेवी हाई स्कूल, शनिवार पेठ, पुणे - ४११०३०'
              : 'अहिल्यादेवी हायस्कूल, शनिवार पेठ, पुणे - ४११०३०');
    } else if (booth.contains('31') || booth.contains('३१')) {
      return lang == 'en'
          ? 'K.P.B. Hindu High School, Raviwar Peth, Pune'
          : (lang == 'hi'
              ? 'के.पी.बी. हिंदू हाई स्कूल, रविवार पेठ, पुणे'
              : 'के.पी.बी. हिंदू हायस्कूल, रविवार पेठ, पुणे');
    }
    return lang == 'en'
        ? 'Polling Station No. $booth, Ward 12, Pune'
        : (lang == 'hi'
            ? 'मतदान केंद्र क्र. $booth, वार्ड १२, पुणे'
            : 'मतदान केंद्र क्र. $booth, प्रभाग १२, पुणे');
  }

  VoterModel copyWith({
    String? id,
    String? nameMarathi,
    String? nameEnglish,
    String? epicNo,
    String? booth,
    int? serialNo,
    String? address,
    String? houseNo,
    int? age,
    String? gender,
    String? mobile,
    String? caste,
    String? favour,
    bool? isFriendRelative,
    String? tenantId,
    String? pollingStation,
    String? relationType,
  }) {
    return VoterModel(
      id: id ?? this.id,
      nameMarathi: nameMarathi ?? this.nameMarathi,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      epicNo: epicNo ?? this.epicNo,
      booth: booth ?? this.booth,
      serialNo: serialNo ?? this.serialNo,
      address: address ?? this.address,
      houseNo: houseNo ?? this.houseNo,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      mobile: mobile ?? this.mobile,
      caste: caste ?? this.caste,
      favour: favour ?? this.favour,
      isFriendRelative: isFriendRelative ?? this.isFriendRelative,
      tenantId: tenantId ?? this.tenantId,
      pollingStation: pollingStation ?? this.pollingStation,
      relationType: relationType ?? this.relationType,
    );
  }

  factory VoterModel.fromJson(Map<String, dynamic> json) {
    return VoterModel(
      id: json['id']?.toString() ?? '',
      nameMarathi: json['name_marathi'] ?? json['name'] ?? '',
      nameEnglish: json['name_english'] ?? json['name'] ?? '',
      epicNo: json['epic_no'] ?? json['epicNo'] ?? '',
      booth: json['booth']?.toString() ?? json['part_no']?.toString() ?? '',
      serialNo: json['serial_no'] is int
          ? json['serial_no']
          : int.tryParse(json['serial_no']?.toString() ?? ''),
      address: json['address_marathi'] ?? json['address'] ?? json['address_english'] ?? '',
      houseNo: json['house_no']?.toString() ?? json['houseNo']?.toString(),
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      gender: json['gender']?.toString() ?? 'M',
      mobile: json['mobile']?.toString(),
      caste: json['caste']?.toString(),
      favour: json['favour']?.toString(),
      isFriendRelative: json['is_friend_relative'] == true,
      tenantId: json['tenant_id']?.toString(),
      pollingStation: json['polling_station']?.toString() ?? json['booth_address']?.toString(),
      relationType: json['relation_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_marathi': nameMarathi,
      'name_english': nameEnglish,
      'epic_no': epicNo,
      'booth': booth,
      'serial_no': serialNo,
      'address_marathi': address,
      'house_no': houseNo,
      'age': age,
      'gender': gender,
      'mobile': mobile,
      'caste': caste,
      'favour': favour,
      'is_friend_relative': isFriendRelative,
      'tenant_id': tenantId,
      'polling_station': pollingStation,
      'relation_type': relationType,
    };
  }
}
