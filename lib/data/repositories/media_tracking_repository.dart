import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_tracking_model.dart';
import '../models/newspaper_clipping_model.dart';
import 'newspaper_clippings_repository.dart';

final mediaTrackingRepoProvider = Provider<MediaTrackingRepository>((ref) {
  final clippingRepo = ref.read(newspaperClippingsRepoProvider);
  return MediaTrackingRepository(clippingRepo: clippingRepo);
});

class MediaTrackingRepository {
  final NewspaperClippingsRepository? clippingRepo;

  MediaTrackingRepository({this.clippingRepo});

  final List<MediaTrackingArticleModel> _articles = [
    MediaTrackingArticleModel(
      id: 'med_01',
      title:
          'Pune Municipal Corporation Ward 12: Road Concretization Gathers Steam; Corporator Inspects Sites',
      titleMarathi:
          'पुणे महापालिका प्रभाग १२: रस्त्यांच्या काँक्रिटीकरण कामास गती, नगरसेवकांकडून प्रत्यक्ष जागेवर पाहणी',
      source: 'TV9 Marathi Web',
      sourceType: 'tv_web',
      date: '2026-01-21',
      time: '11:30 AM',
      sentiment: 'positive',
      personTracked: 'Amit Chougale (नगरसेवक)',
      url: 'https://tv9marathi.com/maharashtra/pune/ward-12-development-work-inspection',
      summary:
          'TV9 Marathi online portal covered the on-ground inspection of cement concrete roads and storm drain trenches in Budhwar Peth and Kasba Peth. Local shopkeepers praised the prompt completion.',
      summaryMarathi:
          'बुधवार पेठ व कसबा परिसरातील रस्ते विकास कामांची प्रत्यक्ष पाहणी नगरसेवकांनी केली. पावसाळ्यापूर्वी कामे पूर्ण करून नागरिकांना दिलासा देण्याचा मनोदय व्यक्त केला.',
      reachEstimate: 34500,
      keywords: ['#पुणेमनपा', '#रस्तेकामे', '#प्रभाग१२', '#TV9Marathi'],
    ),
    MediaTrackingArticleModel(
      id: 'med_02',
      title:
          'Grand Public Response to Free Multi-Specialty Health & Eye Camp in Kasba Ward',
      titleMarathi:
          'कसबा-विश्रामबाग प्रभागातील मोफत सर्वोपचार आरोग्य शिबिराला पुणेकरांचा उत्स्फूर्त प्रतिसाद',
      source: 'ABP Majha Online',
      sourceType: 'tv_web',
      date: '2026-01-19',
      time: '04:15 PM',
      sentiment: 'positive',
      personTracked: 'Amit Chougale (नगरसेवक)',
      url: 'https://abpmajha.abplive.in/pune/kasba-free-health-camp-report',
      summary:
          'ABP Majha digital team featured the joint healthcare initiative with municipal hospitals benefiting over 1,200 senior citizens and street vendors with free diagnostic screenings.',
      summaryMarathi:
          'एबीपी माझा डिजिटल पोर्टलवर बातमी. प्रभाग १२ मधील ज्येष्ठ नागरिक, महिला व कष्टकरी बांधवांसाठी आयोजित आरोग्य शिबिरात मोफत तपासणी व औषधोपचार करण्यात आले.',
      reachEstimate: 48000,
      keywords: ['#आरोग्यशिबिर', '#ABPMajha', '#कसबा', '#जनसेवा'],
    ),
    MediaTrackingArticleModel(
      id: 'med_03',
      title:
          '24-Hour Resolution to Drainage Leakage on Shaniwar Peth Lane 4 After Citizen Outcry',
      titleMarathi:
          'शनिवार पेठेत सांडपाण्याच्या समस्येवर २४ तासांत तोडगा; मनपा अधिकाऱ्यांची धाव',
      source: 'Lokmat News18',
      sourceType: 'portal',
      date: '2026-01-17',
      time: '01:20 PM',
      sentiment: 'positive',
      personTracked: 'Prabhag 12 Development',
      url: 'https://lokmat.news18.com/pune/shaniwar-peth-drainage-chamber-fixed',
      summary:
          'Lokmat online report highlighted the swift intervention of the ward office to deploy high-pressure jetting pumps and replace ruptured underground pipelines within 24 hours.',
      summaryMarathi:
          'नागरिकांच्या तक्रारीनंतर नगरसेवकांनी तत्काळ मनपा आरोग्य व ड्रेनेज विभागाला प्रत्यक्ष जागेवर पाचारण करून समस्या कायमस्वरूपी सोडविल्याची बातमी लोकमत न्यूज१८ वर प्रसिद्ध.',
      reachEstimate: 21500,
      keywords: ['#लोकमत', '#ड्रेनेजदुरुस्ती', '#शनिवारपेठ', '#SLAAction'],
    ),
    MediaTrackingArticleModel(
      id: 'med_04',
      title:
          'Historic Shaniwar Wada Surroundings Revamped with Heritage Pole Lighting and Pathways',
      titleMarathi:
          'ऐतिहासिक शनिवार वाडा परिसर सुशोभीकरण: पर्यटकांच्या सोयीसाठी आकर्षक हेरिटेज रोषणाई',
      source: 'Maharashtra Times Web',
      sourceType: 'portal',
      date: '2026-01-15',
      time: '07:45 PM',
      sentiment: 'positive',
      personTracked: 'Amit Chougale (नगरसेवक)',
      url: 'https://maharashtratimes.com/pune/shaniwar-wada-heritage-beautification',
      summary:
          'Digital article detailing the aesthetic upgrade of footpaths, bollards, and energy-saving LED heritage streetlamps installed around Pune’s central landmark.',
      summaryMarathi:
          'पुण्याच्या ऐतिहासिक वारशाचे रक्षण व पर्यटकांच्या सुरक्षिततेसाठी शनिवार वाडा परिसराचे सुशोभीकरण पूर्ण झाल्याचे महाराष्ट्र टाइम्स वेबने ठळकपणे मांडले.',
      reachEstimate: 42000,
      keywords: ['#शनिवारवाडा', '#MTWeb', '#हेरिटेजपुणे', '#विकास'],
    ),
    MediaTrackingArticleModel(
      id: 'med_05',
      title:
          'Traffic Congestion and Double Parking Chaos Near Bajirao Road Market Sparks Public Ire',
      titleMarathi:
          'विश्रामबाग वाड्याजवळ वाहतूक कोंडीची समस्या; नागरिकांकडून कडक नो-पार्किंग कारवाईची मागणी',
      source: 'Pudhari Online',
      sourceType: 'portal',
      date: '2026-01-11',
      time: '09:10 AM',
      sentiment: 'negative',
      personTracked: 'Prabhag 12 Development',
      url: 'https://pudhari.news/maharashtra/pune/traffic-bottleneck-bajirao-road',
      summary:
          'Pudhari web edition flagged recurring evening traffic delays caused by commercial encroachments and lack of dedicated parking slots near Vishrambaug Wada.',
      summaryMarathi:
          'पुढारी ऑनलाइनवर प्रसिद्ध बातमीनुसार, गर्दीच्या वेळी दुहेरी पार्किंगमुळे पादचाऱ्यांची होणारी कुचंबणा मांडली. प्रशासनाने तत्काळ पार्किंग नियोजन करण्याची मागणी.',
      reachEstimate: 16800,
      keywords: ['#पुढारी', '#वाहतूककोंडी', '#विश्रामबागवाडा', '#नागरीसमस्या'],
    ),
    MediaTrackingArticleModel(
      id: 'med_06',
      title:
          'Digital Pune: Ward 12 Activates 24x7 WhatsApp Chatbot for Instant Civic Complaint Logging',
      titleMarathi:
          'डिजिटल पुणे: प्रभाग १२ मध्ये सुरू झाली २४ तास चालणारी व्हॉट्सॲप नागरी तक्रार निवारण सेवा',
      source: 'Zee 24 Taas Web',
      sourceType: 'tv_web',
      date: '2026-01-09',
      time: '05:30 PM',
      sentiment: 'positive',
      personTracked: 'Amit Chougale (नगरसेवक)',
      url: 'https://zeenews.india.com/marathi/pune/digital-ward-whatsapp-bot-launched',
      summary:
          'Special feature on Zee 24 Taas Web reviewing the smart governance model of Prabhag 12 where citizens track complaint resolution status with real-time photographic proof.',
      summaryMarathi:
          'झी २४ तास वेबवर कौतुकास्पद बातमी. कचरा, पथदिवे आणि पाणीपुरवठा समस्यांसाठी आधुनिक तंत्रज्ञानाचा वापर करून नागरिकांना तत्काळ सेवा देणारे मॉडेल.',
      reachEstimate: 29000,
      keywords: ['#Zee24Taas', '#डिजिटलप्रभाग', '#स्मार्टपुणे', '#WhatsAppBot'],
    ),
    MediaTrackingArticleModel(
      id: 'med_07',
      title:
          'Pune Municipal Corporation Clears Kasba Peth Water Booster Pipeline Tender Worth ₹42 Lakh',
      titleMarathi:
          'कसबा पेठेतील पाणीटंचाईवर मात; नवीन ३०० मिमी बूस्टर पाईपलाईन कामास मंजुरी',
      source: 'Sakal e-Paper',
      sourceType: 'e_paper',
      date: '2026-01-05',
      time: '08:15 AM',
      sentiment: 'positive',
      personTracked: 'Pune Municipal Corporation',
      url: 'https://esakal.com/pune/water-pipeline-sanctioned-kasba-ward',
      summary:
          'Sakal digital edition reported on the clearance of tender by PMC Standing Committee to eliminate decades-old low pressure in Kasba Wada high-elevation clusters.',
      summaryMarathi:
          'उंचावरील घरांमध्ये सुरळीत दाबाने पाणी पोहोचवण्यासाठी नवीन जलवाहिनीस स्थायी समितीची मंजुरी मिळाल्याची बातमी सकाळ ई-पेपरवर प्रसिद्ध.',
      reachEstimate: 36000,
      keywords: ['#सकाळ', '#पाणीपुरवठा', '#कसबापेठ', '#मनपा'],
    ),
    MediaTrackingArticleModel(
      id: 'med_08',
      title:
          'Pune Municipal Budget Allocations: Substantial Capital Outlay Earmarked for Heritage Ward 12',
      titleMarathi:
          'पुणे महापालिका अर्थसंकल्प: कसबा-विश्रामबाग प्रभागाला विकासकामांसाठी भरीव तरतूद',
      source: 'Twitter / X News Alert',
      sourceType: 'social_web',
      date: '2026-01-02',
      time: '02:00 PM',
      sentiment: 'positive',
      personTracked: 'Opposition Party',
      url: 'https://twitter.com/punecivicnews/status/123456',
      summary:
          'News viral on social media detailing the budgetary sanction for school renovations, senior citizen parks, and underground optical fiber conduits in Ward 12.',
      summaryMarathi:
          'महापालिकेच्या आगामी अर्थसंकल्पात पेठांच्या सर्वांगीण विकासासाठी निधी मंजूर झाल्याबाबत सोशल मीडियावरील चर्चेचा आढावा.',
      reachEstimate: 14500,
      keywords: ['#PuneBudget', '#WardBudget', '#PMC2026', '#TwitterBuzz'],
    ),
  ];

  final List<TrackingProfileModel> _profiles = [
    const TrackingProfileModel(
      id: 'all',
      name: 'All Profiles',
      nameMarathi: 'सर्व प्रोफाइल्स',
      category: 'all',
      query: '',
      mentionsCount: 8,
    ),
    const TrackingProfileModel(
      id: 'prof_amit',
      name: 'Amit Chougale (नगरसेवक)',
      nameMarathi: 'अमित चौगुले (नगरसेवक)',
      category: 'corporator',
      query: 'Amit Chougale',
      mentionsCount: 4,
    ),
    const TrackingProfileModel(
      id: 'prof_ward',
      name: 'Prabhag 12 Development',
      nameMarathi: 'प्रभाग १२ विकासकामे',
      category: 'ward',
      query: 'Prabhag 12',
      mentionsCount: 2,
    ),
    const TrackingProfileModel(
      id: 'prof_pmc',
      name: 'Pune Municipal Corp',
      nameMarathi: 'पुणे मनपा बातम्या',
      category: 'civic_body',
      query: 'Municipal',
      mentionsCount: 1,
    ),
    const TrackingProfileModel(
      id: 'prof_opp',
      name: 'Opposition Watch',
      nameMarathi: 'विरोधी पक्ष बातम्या',
      category: 'opposition',
      query: 'Opposition',
      mentionsCount: 1,
    ),
  ];

  final List<TelemetryLogEntry> _telemetryLogs = [
    const TelemetryLogEntry(
      timestamp: '11:42:05',
      portal: 'TV9 Marathi RSS Gateway',
      message: 'Scanned 14 articles · 1 new mention matched "Amit Chougale"',
      status: 'found',
    ),
    const TelemetryLogEntry(
      timestamp: '11:41:52',
      portal: 'ABP Majha Newsfeed API',
      message: 'Scanned 28 regional items · High sentiment score (0.84)',
      status: 'found',
    ),
    const TelemetryLogEntry(
      timestamp: '11:40:15',
      portal: 'Lokmat News18 Webhook',
      message: 'Index verified for "Shaniwar Peth" civic news stream',
      status: 'completed',
    ),
    const TelemetryLogEntry(
      timestamp: '11:39:00',
      portal: 'Maharashtra Times E-Portal',
      message: 'Scraping Kasba ward heritage beat articles',
      status: 'scanning',
    ),
    const TelemetryLogEntry(
      timestamp: '11:38:22',
      portal: 'Pudhari Web Crawler',
      message: 'Traffic alert tagged under negative sentiment',
      status: 'found',
    ),
    const TelemetryLogEntry(
      timestamp: '11:36:10',
      portal: 'Twitter/X Political Stream',
      message: 'Scanning #Prabhag12 and #PMC2026 real-time hashtags',
      status: 'completed',
    ),
  ];

  Future<List<MediaTrackingArticleModel>> getArticles({
    String? query,
    String? profileId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var list = List<MediaTrackingArticleModel>.from(_articles);

    if (profileId != null && profileId != 'all') {
      final profile = _profiles.firstWhere((p) => p.id == profileId, orElse: () => _profiles.first);
      if (profile.query.isNotEmpty) {
        final q = profile.query.toLowerCase();
        list = list.where((a) => a.personTracked.toLowerCase().contains(q) || a.title.toLowerCase().contains(q)).toList();
      }
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((a) {
        final titleMatch = a.title.toLowerCase().contains(q) || a.titleMarathi.toLowerCase().contains(q);
        final sourceMatch = a.source.toLowerCase().contains(q);
        final summaryMatch = a.summary.toLowerCase().contains(q) || a.summaryMarathi.toLowerCase().contains(q);
        final personMatch = a.personTracked.toLowerCase().contains(q);
        final keywordMatch = a.keywords.any((k) => k.toLowerCase().contains(q));
        return titleMatch || sourceMatch || summaryMatch || personMatch || keywordMatch;
      }).toList();
    }

    return list;
  }

  Future<List<TrackingProfileModel>> getProfiles() async {
    return List.from(_profiles);
  }

  Future<List<TelemetryLogEntry>> getTelemetryLogs() async {
    return List.from(_telemetryLogs);
  }

  Future<bool> saveToClipping(String id) async {
    final idx = _articles.indexWhere((a) => a.id == id);
    if (idx == -1) return false;

    final article = _articles[idx];
    _articles[idx] = article.copyWith(isSavedToClipping: true);

    // Save into NewspaperClippingsRepository if available
    if (clippingRepo != null) {
      final newClip = NewspaperClippingModel(
        id: 'clip_tracked_${DateTime.now().millisecondsSinceEpoch}',
        title: article.title,
        titleMarathi: article.titleMarathi,
        newspaper: article.source.replaceAll(' Online', '').replaceAll(' Web', ''),
        date: article.date,
        sentiment: article.sentiment,
        imageUrl: 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&q=80&w=800',
        pageNumber: 'Digital Portal',
        edition: 'Web Edition',
        description: article.summary,
        descriptionMarathi: article.summaryMarathi,
        actionTaken: 'डिजिटल मीडिया ट्रॅकिंग प्रणालीद्वारे थेट सेव्ह केले.',
        journalistName: article.source,
      );
      await clippingRepo!.addClipping(newClip);
    }

    return true;
  }

  Future<void> addArticle(MediaTrackingArticleModel article) async {
    _articles.insert(0, article);
  }

  Future<void> deleteArticle(String id) async {
    _articles.removeWhere((a) => a.id == id);
  }
}

