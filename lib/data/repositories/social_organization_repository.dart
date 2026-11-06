import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/social_organization_model.dart';

final socialOrgRepoProvider = Provider<SocialOrganizationRepository>((ref) {
  return SocialOrganizationRepository();
});

class SocialOrganizationRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Realistic seed data for Prabhag 12 (Pune)
  final List<SocialOrganizationModel> _seedOrganizations = [
    // 1. Ganpati Mandal (Sector 3)
    SocialOrganizationModel(
      id: 'org-mandal-1',
      name: 'बाल गणेश तरुण मंडळ',
      nameMarathi: 'बाल गणेश तरुण मंडळ',
      nameEnglish: 'Bal Ganesh Tarun Mandal',
      type: 'ganpati_mandal',
      presidentName: 'गणेश पांडुरंग जाधव',
      presidentMobile: '+91 98221 44556',
      membersCount: 150,
      area: 'सेक्टर ३, मुख्य चौक',
      establishedYear: '2004',
      supportReceived: 'उत्सवासाठी मंडप उभारणी, ध्वनीक्षेपक परवाना व आरती साहित्य साहाय्य दिले.',
      description: 'सेक्टर ३ मधील सर्वात जुने आणि सामाजिक उपक्रम राबवणारे प्रतिष्ठित गणेश मंडळ.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-101',
          title: 'गणेशोत्सव व मोफत दंतरोग तपासणी',
          titleMr: 'गणेशोत्सव व मोफत दंतरोग तपासणी',
          year: 2026,
          description: 'स्थानिक रहिवाशांसाठी तज्ज्ञ डॉक्टरांच्या उपस्थितीत मोफत दंतरोग व नेत्रतपासणी शिबिर.',
          descriptionMr: 'स्थानिक रहिवाशांसाठी तज्ज्ञ डॉक्टरांच्या उपस्थितीत मोफत दंतरोग व नेत्रतपासणी शिबिर.',
        ),
        SocialOrgEventModel(
          id: 'evt-102',
          title: 'रक्तदान शिबिर व गुणवंत सत्कार',
          titleMr: 'रक्तदान शिबिर व गुणवंत सत्कार',
          year: 2025,
          description: '८५ रक्तदात्यांचा सहभाग आणि १० वी व १२ वीच्या गुणवंत विद्यार्थ्यांचा सत्कार.',
          descriptionMr: '८५ रक्तदात्यांचा सहभाग आणि १० वी व १२ वीच्या गुणवंत विद्यार्थ्यांचा सत्कार.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),

    // 2. Ganpati Mandal (Tilak Chowk)
    SocialOrganizationModel(
      id: 'org-mandal-2',
      name: 'शिवनेरी मित्र मंडळ',
      nameMarathi: 'शिवनेरी मित्र मंडळ',
      nameEnglish: 'Shivneri Mitra Mandal',
      type: 'ganpati_mandal',
      presidentName: 'मंगेश विठ्ठल तांबडे',
      presidentMobile: '+91 94220 77889',
      membersCount: 220,
      area: 'टिळक चौक, मेन रोड',
      establishedYear: '1998',
      supportReceived: 'उत्सव परिसरासाठी तात्पुरते सीसीटीव्ही कॅमेरे व एलईडी हायमास्ट दिवे बसवून दिले.',
      description: 'भव्य देखावे आणि पारंपरिक वाद्य पथकांसाठी संपूर्ण प्रभागात प्रसिद्ध असलेले मंडळ.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-201',
          title: 'शिवजयंती व्याख्यानमाला',
          titleMr: 'शिवजयंती व्याख्यानमाला',
          year: 2026,
          description: 'छत्रपती शिवाजी महाराजांच्या जीवनकार्यावर तीन दिवसीय व्याख्यानमालेचे आयोजन.',
          descriptionMr: 'छत्रपती शिवाजी महाराजांच्या जीवनकार्यावर तीन दिवसीय व्याख्यानमालेचे आयोजन.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 110)),
    ),

    // 3. Ganpati Mandal (Shanti Nagar)
    SocialOrganizationModel(
      id: 'org-mandal-3',
      name: 'जय भवानी गणेश मंडळ',
      nameMarathi: 'जय भवानी गणेश मंडळ',
      nameEnglish: 'Jai Bhavani Ganesh Mandal',
      type: 'ganpati_mandal',
      presidentName: 'अमोल बापूराव गायकवाड',
      presidentMobile: '+91 98811 22334',
      membersCount: 85,
      area: 'शांती नगर, लेन क्र. २',
      establishedYear: '2012',
      supportReceived: 'महाप्रसाद वाटपासाठी अन्नदान मंडप व पिण्याच्या पाण्याचे टँकर उपलब्ध केले.',
      description: 'शांती नगर परिसरातील तरुणांचे सक्रिय मंडळ, पर्यावरणपूरक गणेशोत्सवासाठी अग्रेसर.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-301',
          title: 'शाडूची मूर्ती कार्यशाळा',
          titleMr: 'शाडूची मूर्ती कार्यशाळा',
          year: 2026,
          description: 'शाळकरी मुलांसाठी पर्यावरणपूरक शाडूच्या मातीपासून मूर्ती बनवण्याची मोफत कार्यशाळा.',
          descriptionMr: 'शाळकरी मुलांसाठी पर्यावरणपूरक शाडूच्या मातीपासून मूर्ती बनवण्याची मोफत कार्यशाळा.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 95)),
    ),

    // 4. Navratri Mandal (Sector 9)
    SocialOrganizationModel(
      id: 'org-mandal-4',
      name: 'भवानी माता नवरात्रौत्सव मंडळ',
      nameMarathi: 'भवानी माता नवरात्रौत्सव मंडळ',
      nameEnglish: 'Bhavani Mata Navratrotsav Mandal',
      type: 'navratri_mandal',
      presidentName: 'सौ. सुलभा रमेश महाजन',
      presidentMobile: '+91 97630 11992',
      membersCount: 180,
      area: 'सेक्टर ९, भवानी माता मंदिर परिसर',
      establishedYear: '2008',
      supportReceived: 'महिला गरबा रास महोत्सवासाठी मंडप, प्रकाशयोजना व पारितोषिक प्रायोजकत्व दिले.',
      description: 'महिला संचलित आदर्श नवरात्रौत्सव मंडळ. गरबा, दांडिया आणि सांस्कृतिक स्पर्धांचे आयोजन.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-401',
          title: 'भव्य दांडिया रास व महिला हळदीकुंकू',
          titleMr: 'भव्य दांडिया रास व महिला हळदीकुंकू',
          year: 2026,
          description: '५०० हून अधिक महिलांचा सहभाग असलेला दांडिया रास आणि पारंपरिक खेळ स्पर्धा.',
          descriptionMr: '५०० हून अधिक महिलांचा सहभाग असलेला दांडिया रास आणि पारंपरिक खेळ स्पर्धा.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
    ),

    // 5. Navratri Mandal (Prabhat Colony)
    SocialOrganizationModel(
      id: 'org-mandal-5',
      name: 'नवदुर्गा उत्सव समिती',
      nameMarathi: 'नवदुर्गा उत्सव समिती',
      nameEnglish: 'Navdurga Utsav Samiti',
      type: 'navratri_mandal',
      presidentName: 'सौ. वंदना सुधीर कुलकर्णी',
      presidentMobile: '+91 99225 66110',
      membersCount: 95,
      area: 'प्रभात कॉलनी कम्युनिटी हॉल',
      establishedYear: '2016',
      supportReceived: 'मंडळाच्या विनंतीवरून मंदिरासमोरील रस्त्याचे डांबरीकरण पूर्ण करून दिले.',
      description: 'पारंपरिक भोंडला, गरबा आणि महिला आरोग्य विषयक कार्यशाळा राबवणारी संस्था.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-501',
          title: 'महिला बचत गट हस्तकला प्रदर्शन',
          titleMr: 'महिला बचत गट हस्तकला प्रदर्शन',
          year: 2025,
          description: 'स्थानिक बचत गटांच्या उत्पादनांची विक्री व प्रदर्शनाचे यशस्वी आयोजन.',
          descriptionMr: 'स्थानिक बचत गटांच्या उत्पादनांची विक्री व प्रदर्शनाचे यशस्वी आयोजन.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 70)),
    ),

    // 6. Cricket & Sports Club (Prabhat Colony Ground)
    SocialOrganizationModel(
      id: 'org-sports-1',
      name: 'प्रभात क्रिकेट क्लब',
      nameMarathi: 'प्रभात क्रिकेट क्लब',
      nameEnglish: 'Prabhat Cricket Club',
      type: 'sports_cricket',
      presidentName: 'स्वप्नील एकनाथ मोरे',
      presidentMobile: '+91 95520 88331',
      membersCount: 60,
      area: 'प्रभात कॉलनी क्रीडांगण',
      establishedYear: '2015',
      supportReceived: 'प्रभाग १२ चषक टेनिस बॉल क्रिकेट स्पर्धेसाठी रोख पारितोषिके व चषक प्रायोजकत्व.',
      description: 'तरुण खेळाडूंना क्रिकेटचे प्रशिक्षण देणारा आणि आंतर-सोसायटी सामने भरवणारा क्लब.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-601',
          title: 'अखिल प्रभाग चषक क्रिकेट स्पर्धा २०२६',
          titleMr: 'अखिल प्रभाग चषक क्रिकेट स्पर्धा २०२६',
          year: 2026,
          description: '३२ स्थानिक संघांचा सहभाग असलेली भव्य रात्रीची प्रकाशझोतातील क्रिकेट स्पर्धा.',
          descriptionMr: '३२ स्थानिक संघांचा सहभाग असलेली भव्य रात्रीची प्रकाशझोतातील क्रिकेट स्पर्धा.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),

    // 7. Sports Club (Vitthal Nagar)
    SocialOrganizationModel(
      id: 'org-sports-2',
      name: 'वीर संभाजी क्रीडा व व्यायाम मंडळ',
      nameMarathi: 'वीर संभाजी क्रीडा व व्यायाम मंडळ',
      nameEnglish: 'Veer Sambhaji Sports & Gym Club',
      type: 'sports_cricket',
      presidentName: 'सागर बाळकृष्ण सावंत',
      presidentMobile: '+91 98904 55112',
      membersCount: 110,
      area: 'विठ्ठल नगर, अण्णा भाऊ साठे उद्यान',
      establishedYear: '2010',
      supportReceived: 'उद्यानात ओपन जिम साहित्य बसवून दिले आणि मॅट खरेदीसाठी विशेष निधी दिला.',
      description: 'कुस्ती, कसरत आणि मैदानी खेळांना प्रोत्साहन देणारी प्रभागातील प्रमुख क्रीडा संस्था.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-701',
          title: 'भव्य कुस्ती दंगल व शरीरसौष्ठव स्पर्धा',
          titleMr: 'भव्य कुस्ती दंगल व शरीरसौष्ठव स्पर्धा',
          year: 2026,
          description: 'महाराष्ट्र केसरी मल्लांच्या उपस्थितीत निकाली कुस्त्यांचे जंगी मैदान.',
          descriptionMr: 'महाराष्ट्र केसरी मल्लांच्या उपस्थितीत निकाली कुस्त्यांचे जंगी मैदान.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
    ),

    // 8. NGO (Sector 2)
    SocialOrganizationModel(
      id: 'org-ngo-1',
      name: 'संकल्प समाज विकास संस्था (NGO)',
      nameMarathi: 'संकल्प समाज विकास संस्था',
      nameEnglish: 'Sankalp Social Development Foundation',
      type: 'ngo',
      presidentName: 'डॉ. राजेंद्र सदाशिव जोशी',
      presidentMobile: '+91 94231 99220',
      membersCount: 45,
      area: 'सेक्टर २, विकास चौक',
      establishedYear: '2005',
      supportReceived: 'ज्येष्ठ नागरिक विरंगुळा केंद्रासाठी महापालिका इमारतीत जागा उपलब्ध करून दिली.',
      description: 'ज्येष्ठ नागरिक कल्याण, शिक्षण आणि गरजू विद्यार्थ्यांना शैक्षणिक साहित्याचे वाटप.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-801',
          title: 'मोफत मोतिबिंदू शस्त्रक्रिया शिबिर',
          titleMr: 'मोफत मोतिबिंदू शस्त्रक्रिया शिबिर',
          year: 2026,
          description: '१२० ज्येष्ठ नागरिकांची नेत्रतपासणी व ४५ गरजू रुग्णांवर मोफत मोतिबिंदू शस्त्रक्रिया.',
          descriptionMr: '१२० ज्येष्ठ नागरिकांची नेत्रतपासणी व ४५ गरजू रुग्णांवर मोफत मोतिबिंदू शस्त्रक्रिया.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ),

    // 9. NGO (Vishrantwadi Road)
    SocialOrganizationModel(
      id: 'org-ngo-2',
      name: 'आरोग्यमित्र चॅरिटेबल ट्रस्ट (NGO)',
      nameMarathi: 'आरोग्यमित्र चॅरिटेबल ट्रस्ट',
      nameEnglish: 'Arogyamitra Charitable Trust',
      type: 'ngo',
      presidentName: 'सौ. अनुराधा प्रकाश देशपांडे',
      presidentMobile: '+91 98233 44001',
      membersCount: 35,
      area: 'विश्रांतवाडी रोड, समर्थ संकुल',
      establishedYear: '2018',
      supportReceived: 'आपत्कालीन रुग्णवाहिका संपर्क कक्ष आणि औषध वाटप केंद्र उभारणीत सहकार्य.',
      description: 'गरीब रुग्णांना औषधे, रक्ताच्या पिशव्या आणि मोफत वैद्यकीय समुपदेशन पुरवणारी ट्रस्ट.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-901',
          title: 'महिला कर्करोग प्राथमिक तपासणी मोहीम',
          titleMr: 'महिला कर्करोग प्राथमिक तपासणी मोहीम',
          year: 2025,
          description: 'तज्ज्ञ स्त्रीरोगतज्ज्ञांमार्फत २०० हून अधिक महिलांची मोफत आरोग्य तपासणी.',
          descriptionMr: 'तज्ज्ञ स्त्रीरोगतज्ज्ञांमार्फत २०० हून अधिक महिलांची मोफत आरोग्य तपासणी.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),

    // 10. NGO (Environment Protection)
    SocialOrganizationModel(
      id: 'org-ngo-3',
      name: 'पर्यावरण संवर्धन मंच (NGO)',
      nameMarathi: 'पर्यावरण संवर्धन मंच',
      nameEnglish: 'Paryavaran Sanvardhan Manch',
      type: 'ngo',
      presidentName: 'प्रा. मिलिंद गोपाळ फडके',
      presidentMobile: '+91 98901 33221',
      membersCount: 55,
      area: 'प्रभाग १२, संपूर्ण परिसर',
      establishedYear: '2019',
      supportReceived: 'महापालिका उद्यानातून ५०० रोपांची उपलब्धता व ट्री-गार्ड्स बसवण्यासाठी मदत.',
      description: 'वृक्षारोपण, प्लास्टिकमुक्ती आणि सोसायटींमध्ये ओला-सुका कचरा वर्गीकरण जनजागृती.',
      status: 'Active',
      eventsConducted: [
        SocialOrgEventModel(
          id: 'evt-1001',
          title: '५०० देशी वृक्षांची लागवड मोहीम',
          titleMr: '५०० देशी वृक्षांची लागवड मोहीम',
          year: 2026,
          description: 'रस्ता दुभाजक व मोकळ्या जागेत कडुनिंब, पिंपळ व वडाच्या रोपांचे रोपण व संगोपन.',
          descriptionMr: 'रस्ता दुभाजक व मोकळ्या जागेत कडुनिंब, पिंपळ व वडाच्या रोपांचे रोपण व संगोपन.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  /// Get organizations with filters
  Future<List<SocialOrganizationModel>> getOrganizations({
    String? type,
    String? status,
    String? area,
    String? query,
  }) async {
    try {
      var dbQuery = _client.from('social_organizations').select('*');
      final tId = _tenantId;
      if (tId != null && tId.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', tId);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      if ((response as List).isNotEmpty) {
        final dbList = response.map((json) => SocialOrganizationModel.fromJson(json)).toList();
        return _applyFilters(dbList, type: type, status: status, area: area, query: query);
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
    return _applyFilters(_seedOrganizations, type: type, status: status, area: area, query: query);
  }

  List<SocialOrganizationModel> _applyFilters(
    List<SocialOrganizationModel> list, {
    String? type,
    String? status,
    String? area,
    String? query,
  }) {
    return list.where((org) {
      if (type != null && type.isNotEmpty && type != 'all') {
        if (org.type != type) return false;
      }

      if (status != null && status.isNotEmpty && status != 'all') {
        if (org.status != status) return false;
      }

      if (area != null && area.isNotEmpty) {
        if (!org.area.toLowerCase().contains(area.toLowerCase())) return false;
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final nameMatch = org.name.toLowerCase().contains(q) ||
            (org.nameMarathi ?? '').toLowerCase().contains(q) ||
            (org.nameEnglish ?? '').toLowerCase().contains(q);
        final presMatch = org.presidentName.toLowerCase().contains(q);
        final phoneMatch = org.presidentMobile.toLowerCase().contains(q);
        final areaMatch = org.area.toLowerCase().contains(q);
        final descMatch = org.description.toLowerCase().contains(q);
        final supportMatch = org.supportReceived.toLowerCase().contains(q);
        if (!nameMatch && !presMatch && !phoneMatch && !areaMatch && !descMatch && !supportMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Add new organization
  Future<void> addOrganization(SocialOrganizationModel org) async {
    try {
      final payload = org.toJson();
      final tId = _tenantId;
      if (tId != null && tId.isNotEmpty) payload['tenant_id'] = tId;
      await _client.from('social_organizations').insert(payload);
    } catch (_) {}

    _seedOrganizations.insert(0, org);
  }

  /// Update existing organization
  Future<void> updateOrganization(SocialOrganizationModel org) async {
    try {
      final payload = org.toJson();
      await _client.from('social_organizations').update(payload).eq('id', org.id);
    } catch (_) {}

    final idx = _seedOrganizations.indexWhere((o) => o.id == org.id);
    if (idx != -1) {
      _seedOrganizations[idx] = org;
    }
  }

  /// Delete organization
  Future<void> deleteOrganization(String id) async {
    try {
      await _client.from('social_organizations').delete().eq('id', id);
    } catch (_) {}

    _seedOrganizations.removeWhere((o) => o.id == id);
  }

  /// Add event to organization
  Future<void> addEvent(String orgId, SocialOrgEventModel event) async {
    final idx = _seedOrganizations.indexWhere((o) => o.id == orgId);
    if (idx != -1) {
      final current = _seedOrganizations[idx];
      final updatedEvents = [event, ...current.eventsConducted];
      _seedOrganizations[idx] = current.copyWith(eventsConducted: updatedEvents);

      try {
        await _client.from('social_organizations').update({
          'events_conducted': updatedEvents.map((e) => e.toJson()).toList(),
        }).eq('id', orgId);
      } catch (_) {}
    }
  }

  /// Delete event from organization
  Future<void> deleteEvent(String orgId, String eventId) async {
    final idx = _seedOrganizations.indexWhere((o) => o.id == orgId);
    if (idx != -1) {
      final current = _seedOrganizations[idx];
      final updatedEvents = current.eventsConducted.where((e) => e.id != eventId).toList();
      _seedOrganizations[idx] = current.copyWith(eventsConducted: updatedEvents);

      try {
        await _client.from('social_organizations').update({
          'events_conducted': updatedEvents.map((e) => e.toJson()).toList(),
        }).eq('id', orgId);
      } catch (_) {}
    }
  }

  /// Get summary statistics
  Future<Map<String, int>> getOrganizationStats() async {
    int total = _seedOrganizations.length;
    int ngos = 0;
    int sports = 0;
    int mandals = 0;

    for (final o in _seedOrganizations) {
      if (o.type == 'ngo') {
        ngos++;
      } else if (o.type == 'sports_cricket') {
        sports++;
      } else if (o.type == 'ganpati_mandal' || o.type == 'navratri_mandal') {
        mandals++;
      }
    }

    return {
      'total': total,
      'ngos': ngos,
      'sports': sports,
      'mandals': mandals,
    };
  }
}

