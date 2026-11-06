import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/newspaper_clipping_model.dart';

final newspaperClippingsRepoProvider =
    Provider<NewspaperClippingsRepository>((ref) {
  return NewspaperClippingsRepository();
});

class NewspaperClippingsRepository {
  final List<NewspaperClippingModel> _clippings = [
    NewspaperClippingModel(
      id: 'clip_01',
      title:
          'Major Sanction of ₹95 Lakh for Road Concretization and Underground Storm Drainage in Ward 12',
      titleMarathi:
          'प्रभाग १२ मध्ये रस्ते सिमेंट काँक्रिटीकरण व भूमिगत ड्रेनेजसाठी ९५ लाखांचा निधी मंजूर; कामाला प्रारंभ',
      newspaper: 'Lokmat',
      date: '2026-01-20',
      sentiment: 'positive',
      pageNumber: 'Page 3 • Pune Metro',
      edition: 'Pune Main Edition',
      imageUrl:
          'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=800',
      description:
          'Special feature coverage on the long-pending demand of Budhwar Peth and Kasba Peth residents. Highlighting the swift intervention of the local Nagarsevak to secure funds before monsoon.',
      descriptionMarathi:
          'बुधवार पेठ व कसबा पेठेतील नागरिकांच्या अनेक वर्षांच्या मागणीला अखेर यश. स्थानिक नगरसेवकांच्या पाठपुराव्यामुळे पावसाळ्यापूर्वी रस्ते व सांडपाणी वाहिन्यांचे काम पूर्ण होणार असल्याचे लोकमतने ठळकपणे प्रसिद्ध केले.',
      actionTaken:
          'मनपा रस्ते व ड्रेनेज विभागाच्या कार्यकारी अभियंत्यांसोबत प्रत्यक्ष पाहणी करून वर्क ऑर्डर जारी केली.',
      journalistName: 'सुनील तांबोळी (विशेष प्रतिनिधी)',
    ),
    NewspaperClippingModel(
      id: 'clip_02',
      title:
          'Free Multi-Specialty Health & Eye Camp Organized in Kasba Peth: Over 1,200 Citizens Benefited',
      titleMarathi:
          'कसबा पेठेत भव्य मोफत सर्वोपचार व नेत्र तपासणी शिबिर संपन्न; १२०० हून अधिक नागरिकांनी घेतला लाभ',
      newspaper: 'Sakal',
      date: '2026-01-18',
      sentiment: 'positive',
      pageNumber: 'Page 5 • Kasba Prabhag',
      edition: 'Pune City Edition',
      imageUrl:
          'https://images.unsplash.com/photo-1576091160550-217358c7db81?auto=format&fit=crop&q=80&w=800',
      description:
          'Sakal reported on the successful mega health camp organized in collaboration with KEM and Kamla Nehru Hospitals. Free medicines, diagnostic screening, and eyeglasses were distributed to senior citizens.',
      descriptionMarathi:
          'केईएम व कमला नेहरू रुग्णालयाच्या सहकार्याने आयोजित आरोग्य शिबिराचे सकाळमध्ये वृत्त. ज्येष्ठ नागरिकांना मोफत चष्मे व औषध वाटप. नगरसेवकांच्या लोककल्याणकारी उपक्रमाचे नागरिकांकडून कौतुक.',
      actionTaken:
          'आरोग्य कार्ड तयार करून गरजू रुग्णांना पुढील मोफत उपचारासाठी मनपा रुग्णालयात दाखल केले.',
      journalistName: 'महेश देशपांडे',
    ),
    NewspaperClippingModel(
      id: 'clip_03',
      title:
          'Severe Sewage Overflow in Shaniwar Peth Lane 4: Residents Distressed by Foul Odor',
      titleMarathi:
          'शनिवार पेठ गल्ली क्र. ४ मध्ये रस्त्यावर सांडपाणी साचल्याने नागरिक त्रस्त; साथीच्या रोगांची भीती',
      newspaper: 'Lokmat',
      date: '2026-01-16',
      sentiment: 'negative',
      pageNumber: 'Page 4 • City Complaints',
      edition: 'Pune City Edition',
      imageUrl:
          'https://images.unsplash.com/photo-1584467735815-f778f274e296?auto=format&fit=crop&q=80&w=800',
      description:
          'Citizens voiced anguish over blocked municipal chamber lines causing contaminated overflow on the main chowk. Demanded immediate action from ward office authorities.',
      descriptionMarathi:
          'भूमिगत ड्रेनेज लाईन चोक झाल्याने रस्त्यावर सांडपाणी वाहत असल्याबाबत लोकमतची सचित्र बातमी. नागरिकांच्या तक्रारीची तातडीने दखल घेण्याचे आवाहन.',
      actionTaken:
          'वृत्त प्रसिद्ध होताच अवघ्या ३ तासांत मनपा जेटिंग मशीन व आरोग्य पथकाला पाचारण करून लाईन दुरुस्त केली आणि जंतुनाशक फवारणी केली.',
      journalistName: 'आनंद खरात',
    ),
    NewspaperClippingModel(
      id: 'clip_04',
      title:
          'Beautification and Heritage Lighting of Historic Shaniwar Wada Vicinity Completed',
      titleMarathi:
          'ऐतिहासिक शनिवार वाडा परिसराचे सुशोभीकरण व हेरिटेज एलईडी स्ट्रीटलाईट्स प्रकल्प पूर्ण',
      newspaper: 'Maharashtra Times',
      date: '2026-01-15',
      sentiment: 'positive',
      pageNumber: 'Page 2 • Heritage Pune',
      edition: 'Pune Metro Edition',
      imageUrl:
          'https://images.unsplash.com/photo-1567591414240-e1cff72516c8?auto=format&fit=crop&q=80&w=800',
      description:
          'Special feature in Maharashtra Times commending the aesthetic revitalization of tourist pathways and heritage pole illumination around Pune\'s pride, Shaniwar Wada.',
      descriptionMarathi:
          'शनिवार वाडा परिसरातील पर्यटकांच्या पदपथांचे नूतनीकरण व आकर्षक विद्युत रोषणाई पूर्ण झाल्याबद्दल म. टा. चे कौतुक. पुणेकरांसाठी ऐतिहासिक वारसा जपण्याचा नगरसेवकांचा स्तुत्य उपक्रम.',
      actionTaken:
          'पर्यटन विभाग व पुरातत्व खात्याकडून एनओसी मिळवून वेळेत प्रकल्प पूर्ण करून लोकार्पण केले.',
      journalistName: 'पराग कुलकर्णी',
    ),
    NewspaperClippingModel(
      id: 'clip_05',
      title:
          'Dedicated 24x7 Citizen Grievance Redressal Cell Inaugurated in Ward 12 Office',
      titleMarathi:
          'प्रभाग १२ च्या नागरिकांसाठी २४x७ जनसंपर्क व डिजिटल तक्रार निवारण कक्ष सुरू',
      newspaper: 'Pudhari',
      date: '2026-01-12',
      sentiment: 'positive',
      pageNumber: 'Page 6 • Prabhag Special',
      edition: 'Pune City Edition',
      imageUrl:
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&q=80&w=800',
      description:
          'Pudhari highlighted the modern civic initiative where citizens can register complaints via WhatsApp bot or toll-free helpline, with time-bound SLA tracking.',
      descriptionMarathi:
          'पुढारी वृत्तपत्रात विशेष प्रसिद्धी. व्हॉट्सॲप आणि हेल्पलाइनद्वारे प्रभाग १२ मधील नागरिकांच्या नागरी समस्यांवर तत्काळ तोडगा काढण्याची आदर्श प्रणाली कार्यान्वित.',
      actionTaken:
          '८ प्रभाग समन्वयकांची नियुक्ती करून दैनंदिन डॅशबोर्ड मॉनिटरिंग सुरू केले.',
      journalistName: 'अजित मोरे',
    ),
    NewspaperClippingModel(
      id: 'clip_06',
      title:
          'Traffic Congestion and Illegal Parking Woes Near Vishrambaug Wada Market',
      titleMarathi:
          'विश्रामबाग वाडा व बाजीराव रस्ता परिसरात अवैध पार्किंगमुळे वाहतूक कोंडी; पादचाऱ्यांची कसरत',
      newspaper: 'Maharashtra Times',
      date: '2026-01-10',
      sentiment: 'negative',
      pageNumber: 'Page 4 • Traffic Watch',
      edition: 'Pune Metro Edition',
      imageUrl:
          'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&q=80&w=800',
      description:
          'Maharashtra Times published citizen distress regarding double parking and encroached footpaths along Bajirao Road, causing severe bottleneck during evening hours.',
      descriptionMarathi:
          'बाजीराव रस्ता व विश्रामबाग वाड्याभोवती बेशिस्त पार्किंगमुळे होणाऱ्या वाहतूक कोंडीवर म. टा. चे ताशेरे. खरेदीदारांना चालणेही मुश्किल.',
      actionTaken:
          'वाहतूक पोलीस उपायुक्त व मनपा अतिक्रमण विभागासोबत तातडीची बैठक घेऊन पे-अँड-पार्क व्यवस्था व नो-पार्किंग कारवाई सुरू केली.',
      journalistName: 'सचिन जोशी',
    ),
    NewspaperClippingModel(
      id: 'clip_07',
      title:
          'New Senior Citizen Recreation Center and Digital Reading Hall Inaugurated in Sadashiv Peth',
      titleMarathi:
          'सदाशिव पेठेत ज्येष्ठ नागरिकांसाठी अत्याधुनिक विरंगुळा केंद्र व ई-वाचनालयाचे लोकार्पण',
      newspaper: 'Loksatta',
      date: '2026-01-08',
      sentiment: 'positive',
      pageNumber: 'Page 7 • City Culture',
      edition: 'Pune Main Edition',
      imageUrl:
          'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&q=80&w=800',
      description:
          'Loksatta published an article praising the eco-friendly senior citizen center equipped with newspaper archives, blood pressure monitors, and Wi-Fi reading facilities.',
      descriptionMarathi:
          'लोकसत्ता मध्ये बातमी. पेठेतील ज्येष्ठांच्या आरोग्यासाठी व वाचन संस्कृती वाढवण्यासाठी नगरसेवकांच्या स्थानिक विकास निधीतून सुंदर वास्तू उभी राहिली.',
      actionTaken:
          'स्थानिक ज्येष्ठ नागरिक संघाकडे व्यवस्थापनाची जबाबदारी सोपवून दरमहा विनामूल्य आरोग्य तपासणी सुरू ठेवली.',
      journalistName: 'रोहित बापट',
    ),
    NewspaperClippingModel(
      id: 'clip_08',
      title:
          'PMC Accelerates Kasba Feeder Pipeline Replacement to Resolve Decades-Old Low Water Pressure',
      titleMarathi:
          'कसबा पेठेतील कमी पाण्याच्या दाबाची समस्या मिटणार; नवीन ३०० मिमी फीडर लाईनचे काम वेगात',
      newspaper: 'The Indian Express',
      date: '2026-01-04',
      sentiment: 'positive',
      pageNumber: 'Page 3 • Urban Governance',
      edition: 'Pune City Edition',
      imageUrl:
          'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&q=80&w=800',
      description:
          'The Indian Express reported on PMC Water Supply Department completing the pipeline installation in historic Kasba lanes to supply 150 LPCD uninterrupted water.',
      descriptionMarathi:
          'द इंडियन एक्सप्रेस मधील वृत्तानुसार, कसबा पेठेतील उंचावरील वस्त्यांमध्ये पाणीपुरवठा सुरळीत करण्यासाठी नगरसेवकांच्या विशेष प्रयत्नातून ३०० मिमी जलवाहिनी पूर्णत्वास येत आहे.',
      actionTaken:
          'स्वारगेट जलकेंद्रावरून अतिरिक्त दाबाचे पाणी सोडण्यासाठी व्हॉल्व्ह सिस्टीम अपग्रेड करून घेतली.',
      journalistName: 'Neha Deshmukh',
    ),
  ];

  Future<List<NewspaperClippingModel>> getClippings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_clippings);
  }

  Future<void> addClipping(NewspaperClippingModel item) async {
    _clippings.insert(0, item);
  }

  Future<void> updateClipping(NewspaperClippingModel item) async {
    final idx = _clippings.indexWhere((c) => c.id == item.id);
    if (idx != -1) {
      _clippings[idx] = item;
    }
  }

  Future<void> deleteClipping(String id) async {
    _clippings.removeWhere((c) => c.id == id);
  }
}

