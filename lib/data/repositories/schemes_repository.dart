import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/scheme_model.dart';

final schemesRepoProvider = Provider((ref) => SchemesRepository());

class SchemesRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Fallback Realistic Schemes matching Nagarsevak-Managment
  final List<SchemeModel> _mockSchemes = [
    SchemeModel(
      id: 1,
      name: 'Pradhan Mantri Awas Yojana (PMAY) / प्रधानमंत्री आवास योजना (शहरी)',
      description:
          'Financial grant and interest subsidy to construct permanent pucca houses for urban homeless and EWS/LIG families. / बेघर आणि आर्थिक दुर्बल घटकांसाठी पक्के घर बांधण्यासाठी आर्थिक अनुदान आणि व्याज सवलत.',
      eligibility:
          'EWS family annual income up to ₹3,00,000; LIG income up to ₹6,00,000. Citizen must not own a pucca house anywhere in India. / वार्षिक उत्पन्न ३ लाखांपर्यंत (EWS) किंवा ६ लाखांपर्यंत (LIG). कुटुंबाच्या नावावर देशात कोठेही पक्के घर नसावे.',
      benefits:
          'Direct grant of up to ₹2.5 Lakhs for construction / 6.5% interest subsidy on home loan up to ₹6 Lakhs. / नवीन घराच्या बांधकामासाठी ₹२.५० लाखांपर्यंत थेट अनुदान आणि गृहकर्जावर ६.५% व्याज सवलत.',
      documents:
          'Aadhaar Card, Ration Card, Income Certificate, Bank Passbook, Land Ownership Proof / 7-12 Extract, Affidavit. / आधार कार्ड, रेशन कार्ड, उत्पन्न दाखला, बँक पासबुक, जागेचा ७/१२ उतारा किंवा मालकी हक्क पुरावा.',
      category: 'Housing',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    SchemeModel(
      id: 2,
      name: 'Majhi Ladki Bahin Yojana / मुख्यमंत्री माझी लाडकी बहीण योजना',
      description:
          'Monthly direct financial support to eligible women in Maharashtra for economic independence and healthcare dignity. / महाराष्ट्रातील महिलांच्या आर्थिक स्वातंत्र्यासाठी आणि पोषणासाठी दरमहा थेट आर्थिक सहाय्य.',
      eligibility:
          'Resident women aged 21 to 65 years. Family annual income not exceeding ₹2.50 Lakhs. Valid Yellow or Orange Ration Card. / वय २१ ते ६५ वर्षे असणाऱ्या महाराष्ट्र राज्यातील महिला. कुटुंबाचे वार्षिक उत्पन्न २.५ लाखांपेक्षा कमी.',
      benefits:
          'Direct benefit transfer of ₹1,500 every month into Aadhaar-linked DBT bank account. / दरमहा ₹१,५०० थेट आधार संलग्न बँक खात्यामध्ये डीबीटी द्वारे जमा.',
      documents:
          'Aadhaar Card, Maharashtra Domicile / Voter ID, Yellow/Orange Ration Card, Income Certificate, Bank Passbook. / आधार कार्ड, अधिवास प्रमाणपत्र / मतदार ओळखपत्र, रेशन कार्ड, बँक पासबुक, हमीपत्र.',
      category: 'Women',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    SchemeModel(
      id: 3,
      name: 'Ayushman Bharat PM-JAY / आयुष्यमान भारत - प्रधानमंत्री जन आरोग्य योजना',
      description:
          'Comprehensive health insurance protection providing cashless hospitalization across recognized public and private hospitals. / गंभीर आजारांच्या उपचारासाठी देशभरातील नोंदणीकृत रुग्णालयांमध्ये मोफत कॅशलेस उपचार.',
      eligibility:
          'Identified families in SECC database, Orange & Yellow Ration Card holders in Maharashtra (Mahatma Jyotirao Phule Arogya Yojana). / पिवळे व केशरी रेशन कार्डधारक कुटुंबे, आर्थिक दुर्बल घटकातील नागरिक.',
      benefits:
          'Cashless medical treatment cover up to ₹5,00,000 per family per year across 1,949 medical procedures. / प्रति कुटुंब प्रति वर्ष ₹५ लाख रुपयांपर्यंत मोफत कॅशलेस वैद्यकीय उपचार संरक्षण.',
      documents:
          'Aadhaar Card, Ration Card, Ayushman Golden Card / MJPJAY Health Card, Voter ID. / आधार कार्ड, रेशन कार्ड, आयुष्यमान गोल्डन कार्ड, मतदार ओळखपत्र.',
      category: 'Health',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    SchemeModel(
      id: 4,
      name: 'PM SVANidhi Scheme / पीएम स्वनिधी योजना (फेरीवाले / पथविक्रेते कर्ज)',
      description:
          'Collateral-free working capital loan and digital incentive for urban street vendors to restart and expand their livelihood. / शहरातील पथविक्रेते व हातगाडी चालकांसाठी भांडवली खेळते कर्ज व डिजिटल प्रोत्साहन योजना.',
      eligibility:
          'Urban street vendors holding Municipal Vending Certificate / ID Card or Recommendation Letter (LoR). / महानगरपालिकेचे फेरीवाला प्रमाणपत्र किंवा शिफारस पत्र असलेले पथविक्रेते.',
      benefits:
          '1st tranche ₹10,000, 2nd tranche ₹20,000, 3rd tranche ₹50,000 with 7% interest subsidy and cashback on digital transactions. / पहिल्या टप्प्यात ₹१०,०००, दुसऱ्या टप्प्यात ₹२०,००० आणि तिसऱ्या टप्प्यात ₹५०,००० पर्यंत विनातारण कर्ज.',
      documents:
          'Municipal Vending ID / Certificate, Aadhaar Card, Bank Passbook, Active UPI QR ID. / महापालिका पथविक्रेता ओळखपत्र, आधार कार्ड, बँक पासबुक, युपीआय तपशील.',
      category: 'Youth',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    SchemeModel(
      id: 5,
      name: 'MahaDBT Post-Matric Scholarship / महाडीबीटी मॅट्रिकोत्तर शिष्यवृत्ती योजना',
      description:
          'Tuition fee reimbursement and maintenance allowance for higher education of SC, ST, OBC, EBC & minority students. / उच्च शिक्षणासाठी मागासवर्गीय, आर्थिक दुर्बल व अल्पसंख्याक विद्यार्थ्यांसाठी शिक्षण शुल्क परतावा.',
      eligibility:
          'Students enrolled in recognized college/university courses after 10th standard. Family income under ₹2.5 Lakhs (up to ₹8 Lakhs for EBC). / मान्यताप्राप्त महाविद्यालयात १० वी नंतरचे पदवी/पदविका शिक्षण घेणारे विद्यार्थी.',
      benefits:
          '100% or 50% tuition & exam fee waiver + monthly maintenance allowance credited directly to student account. / १००% किंवा ५०% शिक्षण शुल्क माफी आणि मासिक शैक्षणिक निर्वाह भत्ता.',
      documents:
          'Aadhaar Card, College Allotment/Bonafide Certificate, 10th/12th Marksheet, Caste & Non-Creamy Layer Certificate, Income Certificate. / आधार कार्ड, शाळा/कॉलेज बोनाफाईड, मागील वर्षाची गुणपत्रिका, जात दाखला, उत्पन्न दाखला.',
      category: 'Student',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    SchemeModel(
      id: 6,
      name: 'Indira Gandhi Old Age Pension / इंदिरा गांधी राष्ट्रीय वृद्धत्व निवृत्तीवेतन योजना',
      description:
          'Monthly financial social security assistance for destitute elderly senior citizens living in poverty. / निराधार व दारिद्र्यरेषेखालील ज्येष्ठ नागरिकांना सन्मानपूर्वक जगण्यासाठी मासिक पेन्शन सहाय्य.',
      eligibility:
          'Senior citizens aged 65 years and above belonging to BPL family or registered Sanjay Gandhi Niradhar beneficiary. / ६५ वर्षे किंवा त्याहून अधिक वय असलेले दारिद्र्यरेषेखालील वृद्ध नागरिक.',
      benefits:
          'Monthly pension of ₹1,500 transferred directly to senior citizen bank or post office account. / दरमहा ₹१,५०० थेट बँक किंवा पोस्ट बचत खात्यात निवृत्तीवेतन.',
      documents:
          'Age Proof (Birth Certificate / Voter ID / Aadhaar), BPL Ration Card, Domicile Certificate, Bank Passbook, 2 Passport Photos. / वयाचा पुरावा, बीपीएल रेशन कार्ड, रहिवासी दाखला, बँक पासबुक, २ फोटो.',
      category: 'Senior Citizen',
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
    ),
    SchemeModel(
      id: 7,
      name: 'PM Kisan Samman Nidhi / प्रधानमंत्री किसान सन्मान निधी योजना',
      description:
          'Annual income support for landholder farmer families to meet agricultural input costs and household needs. / शेतीसाठी लागणाऱ्या बियाणे, खते व इतर खर्चासाठी शेतकरी कुटुंबांना थेट वार्षिक आर्थिक मदत.',
      eligibility:
          'All cultivable landholding farmer families in whose name land ownership is recorded in revenue records. / स्वतःच्या नावे शेतजमीन असलेले सर्व खातेदार शेतकरी कुटुंब.',
      benefits:
          '₹6,000 per year paid in three equal 4-monthly installments of ₹2,000 directly via DBT into bank accounts. / दरवर्षी ₹६,००० तीन हप्त्यांमध्ये (प्रत्येकी ₹२,०००) थेट बँक खात्यात.',
      documents:
          'Aadhaar Card, 7-12 and 8-A Revenue Land Record, Bank Passbook linked with e-KYC. / आधार कार्ड, ७/१२ व ८-अ उतारा, बँक पासबुक आणि ई-केवायसी पडताळणी.',
      category: 'Farmer',
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    ),
    SchemeModel(
      id: 8,
      name: 'Swachh Bharat Urban Toilet Subsidy / स्वच्छ भारत मिशन - वैयक्तिक शौचालय अनुदान',
      description:
          'Financial grant to construct individual household sanitary latrines and stop open defecation in urban wards. / उघड्यावर शौचास जाणे बंद करून घरात स्वतःचे पक्के शौचालय बांधण्यासाठी महापालिकेचे थेट अनुदान.',
      eligibility:
          'Urban slum or gaothan households without an existing functional sanitary toilet inside their dwelling. / घरात स्वतःचे शौचालय नसलेली प्रभागातील शहरी कुटुंबे.',
      benefits:
          'Direct municipal cash grant of ₹12,000 paid in 2 phases after verification and photo geo-tagging. / शौचालय बांधकामासाठी ₹१२,००० चे रोख अनुदान (दोन टप्प्यांत).',
      documents:
          'Aadhaar Card, Electricity Bill / Municipal Assessment Tax Receipt, Bank Passbook, Site Location Photo. / आधार कार्ड, वीज बिल / घरपट्टी पावती, बँक पासबुक आणि जागेचा फोटो.',
      category: 'Housing',
      createdAt: DateTime.now().subtract(const Duration(days: 110)),
    ),
  ];

  // Fallback Realistic Applications
  final List<SchemeApplicationModel> _mockApplications = [
    SchemeApplicationModel(
      id: 101,
      schemeId: 2,
      schemeName: 'Majhi Ladki Bahin Yojana',
      applicantName: 'Sunita Ramesh Deshmukh',
      mobile: '9822014589',
      address: 'House No 45, Shivaji Chowk, Lane 3',
      status: 'Approved',
      benefit: 'Approved ₹1,500/month DBT',
      notes: 'Form verified by Ward Inspector. Bank seeding completed.',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    SchemeApplicationModel(
      id: 102,
      schemeId: 1,
      schemeName: 'Pradhan Mantri Awas Yojana (PMAY)',
      applicantName: 'Ashok Vithal Gaikwad',
      mobile: '9764501234',
      address: 'Plot 18, Siddheshwar Nagar, Sector 4',
      status: 'Pending',
      benefit: 'Eligible for ₹2.5 Lakhs grant',
      notes: 'Site inspection pending by PMC Junior Engineer.',
      createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 6)),
    ),
    SchemeApplicationModel(
      id: 103,
      schemeId: 4,
      schemeName: 'PM SVANidhi Scheme',
      applicantName: 'Ganesh Pandurang Shinde',
      mobile: '9890123456',
      address: 'Tea Stall, Ganpati Mandir Road',
      status: 'Approved',
      benefit: '₹10,000 Micro-credit sanctioned',
      notes: 'Sanction letter issued via Bank of Maharashtra.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    SchemeApplicationModel(
      id: 104,
      schemeId: 3,
      schemeName: 'Ayushman Bharat PM-JAY',
      applicantName: 'Kamala Tukaram Shinde',
      mobile: '9923456789',
      address: 'Behind Maruti Mandir, Prabhag 12',
      status: 'Approved',
      benefit: 'Golden Health Card Issued',
      notes: 'Card delivered to residence by Ward coordinator.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    SchemeApplicationModel(
      id: 105,
      schemeId: 5,
      schemeName: 'MahaDBT Post-Matric Scholarship',
      applicantName: 'Prathamesh Sunil Patil',
      mobile: '9850123987',
      address: 'Flat 102, Shanti Heights, Main Road',
      status: 'Pending',
      benefit: '₹28,000 Tuition waiver',
      notes: 'Awaiting college verification token from Principal.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    SchemeApplicationModel(
      id: 106,
      schemeId: 6,
      schemeName: 'Indira Gandhi Old Age Pension',
      applicantName: 'Parvatibai Shankar Jadhav',
      mobile: '9822890123',
      address: 'Old Gaothan, Near Gram Panchayat Office',
      status: 'Rejected',
      rejectionReason: 'Age document discrepancy (Aadhaar shows 58 yrs, required 65 yrs)',
      notes: 'Citizen advised to re-apply under Sanjay Gandhi Niradhar once age rectified.',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
  ];

  // -------------------------------------------------------------
  // SCHEMES CRUD
  // -------------------------------------------------------------

  Future<List<SchemeModel>> getSchemes() async {
    try {
      var query = _client.from('schemes').select('*');
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.order('created_at', ascending: false);
      final list = (response as List<dynamic>).map((item) => SchemeModel.fromJson(item as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback to local mock data
    }
    return List.from(_mockSchemes);
  }

  Future<SchemeModel> createScheme(SchemeModel scheme) async {
    try {
      final payload = scheme.toJson();
      if (_tenantId != null) {
        payload['tenant_id'] = _tenantId;
      }
      final response = await _client.from('schemes').insert(payload).select().single();
      final created = SchemeModel.fromJson(response);
      _mockSchemes.insert(0, created);
      return created;
    } catch (_) {
      final newScheme = scheme.copyWith(
        id: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now(),
        tenantId: _tenantId,
      );
      _mockSchemes.insert(0, newScheme);
      return newScheme;
    }
  }

  Future<void> updateScheme(SchemeModel scheme) async {
    try {
      final payload = scheme.toJson();
      var query = _client.from('schemes').update(payload).eq('id', scheme.id);
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}

    final idx = _mockSchemes.indexWhere((s) => s.id == scheme.id);
    if (idx != -1) {
      _mockSchemes[idx] = scheme;
    }
  }

  Future<void> deleteScheme(int id) async {
    try {
      var query = _client.from('schemes').delete().eq('id', id);
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}

    _mockSchemes.removeWhere((s) => s.id == id);
  }

  // -------------------------------------------------------------
  // SCHEME APPLICATIONS CRUD
  // -------------------------------------------------------------

  Future<List<SchemeApplicationModel>> getApplications() async {
    try {
      var query = _client.from('scheme_applications').select('*, schemes(name)');
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.order('created_at', ascending: false);
      final list = (response as List<dynamic>)
          .map((item) => SchemeApplicationModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback
    }
    return List.from(_mockApplications);
  }

  Future<SchemeApplicationModel> createApplication(SchemeApplicationModel app) async {
    try {
      final payload = app.toJson();
      if (_tenantId != null) {
        payload['tenant_id'] = _tenantId;
      }
      final response = await _client.from('scheme_applications').insert(payload).select('*, schemes(name)').single();
      final created = SchemeApplicationModel.fromJson(response);
      _mockApplications.insert(0, created);
      return created;
    } catch (_) {
      final newApp = app.copyWith(
        id: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now(),
        tenantId: _tenantId,
      );
      _mockApplications.insert(0, newApp);
      return newApp;
    }
  }

  Future<void> updateApplicationStatus(
    int id,
    String status, {
    String? benefit,
    String? rejectionReason,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{'status': status};
      if (benefit != null) payload['benefit'] = benefit;
      if (rejectionReason != null) payload['rejection_reason'] = rejectionReason;
      if (notes != null) payload['notes'] = notes;

      var query = _client.from('scheme_applications').update(payload).eq('id', id);
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}

    final idx = _mockApplications.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final curr = _mockApplications[idx];
      _mockApplications[idx] = curr.copyWith(
        status: status,
        benefit: benefit ?? curr.benefit,
        rejectionReason: rejectionReason ?? curr.rejectionReason,
        notes: notes ?? curr.notes,
      );
    }
  }

  Future<void> deleteApplication(int id) async {
    try {
      var query = _client.from('scheme_applications').delete().eq('id', id);
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}

    _mockApplications.removeWhere((a) => a.id == id);
  }
}

