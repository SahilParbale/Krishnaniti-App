import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';

class ConstituentInviteContact {
  final String id;
  final String name;
  final String nameMr;
  final String mobile;
  final String area;
  final String address;
  final int age;
  final String gender;

  const ConstituentInviteContact({
    required this.id,
    required this.name,
    required this.nameMr,
    required this.mobile,
    required this.area,
    required this.address,
    required this.age,
    required this.gender,
  });
}

class EventsRepository {
  final List<EventModel> _events = [
    EventModel(
      id: 'evt-001',
      title: 'Inauguration of New Community Hall & Senior Citizen Center',
      titleMr: 'समाज मंदिर व ज्येष्ठ नागरिक विरंगुळा केंद्र भव्य लोकार्पण सोहळा',
      description:
          'प्रभाग १२ मधील नागरिकांसाठी नूतन समाज मंदिर आणि ज्येष्ठ नागरिक विरंगुळा केंद्राचे भव्य लोकार्पण सोहळा आयोजित केला आहे. सर्व नागरिकांनी सहकुटुंब उपस्थित राहावे.',
      eventDate: DateTime.now().add(const Duration(days: 4)),
      eventTime: 'सकाळी १०:०० वा.',
      location: 'Near Shaniwar Wada, Shaniwar Peth',
      locationMr: 'शनिवार वाड्याजवळ, शनिवार पेठ, पुणे',
      type: EventType.inauguration,
      status: 'Planned',
      area: 'शनिवार पेठ',
      targetAudience: 'Senior Citizens & Families',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      rsvps: [
        EventRsvpModel(
          id: 'rsvp-101',
          voterName: 'Ramesh Balwant Kulkarni',
          voterNameMr: 'रमेश बळवंत कुलकर्णी',
          mobile: '9822011223',
          address: 'घर क्र. ४५, शनिवार पेठ',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        EventRsvpModel(
          id: 'rsvp-102',
          voterName: 'Sunita Anand Joshi',
          voterNameMr: 'सुनिता आनंद जोशी',
          mobile: '9822044556',
          address: 'सदाशिव सदन, शनिवार पेठ',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        EventRsvpModel(
          id: 'rsvp-103',
          voterName: 'Prakash Mahadev Shinde',
          voterNameMr: 'प्रकाश महादेव शिंदे',
          mobile: '9422033445',
          address: 'फ्लॅट ३, ओम अपार्टमेंट, शनिवार पेठ',
          status: RsvpStatus.maybe,
          responseSource: 'Direct Call',
          respondedAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        EventRsvpModel(
          id: 'rsvp-104',
          voterName: 'Vandana Vijay Deshpande',
          voterNameMr: 'वंदना विजय देशपांडे',
          mobile: '9890123456',
          address: '१०२, शिवनेरी हाईट्स',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        EventRsvpModel(
          id: 'rsvp-105',
          voterName: 'Ganesh Ramchandra More',
          voterNameMr: 'गणेश रामचंद्र मोरे',
          mobile: '9765432190',
          address: '२२, कसबा पेठ चाळ',
          status: RsvpStatus.notGoing,
          responseSource: 'SMS',
          respondedAt: DateTime.now().subtract(const Duration(hours: 16)),
        ),
      ],
    ),
    EventModel(
      id: 'evt-002',
      title: 'Ward 12 Water Supply & Road Development Public Townhall',
      titleMr: 'प्रभाग १२ पाणीपुरवठा व रस्ते विकास जाहीर नागरिक सभा',
      description:
          'उन्हाळ्यातील पाणीपुरवठा नियोजन, नवीन जलवाहिन्या आणि सुरू असलेल्या अंतर्गत रस्त्यांच्या काँक्रीटीकरणाचा आढावा घेण्यासाठी जाहीर नागरिक सभेचे आयोजन.',
      eventDate: DateTime.now().add(const Duration(days: 7)),
      eventTime: 'सायंकाळी ०६:३० वा.',
      location: 'Kasba Ganpati Temple Trust Hall, Kasba Peth',
      locationMr: 'कसबा गणपती देवस्थान सभागृह, कसबा पेठ',
      type: EventType.publicMeeting,
      status: 'Planned',
      area: 'कसबा पेठ',
      targetAudience: 'All Citizens',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      rsvps: [
        EventRsvpModel(
          id: 'rsvp-201',
          voterName: 'Anil Dattatray Gaikwad',
          voterNameMr: 'अनिल दत्तात्रय गायकवाड',
          mobile: '9822334455',
          address: 'कसबा पेठ, घर क्र. १२',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        EventRsvpModel(
          id: 'rsvp-202',
          voterName: 'Prashant Madhukar Jagtap',
          voterNameMr: 'प्रशांत मधुकर जगताप',
          mobile: '9881023456',
          address: '५६, लाल महाल चौक परिसर',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        EventRsvpModel(
          id: 'rsvp-203',
          voterName: 'Meena Sanjay Patil',
          voterNameMr: 'मीना संजय पाटील',
          mobile: '9766554433',
          address: '१४, फडके हौद चौक',
          status: RsvpStatus.maybe,
          responseSource: 'Office',
          respondedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
    EventModel(
      id: 'evt-003',
      title: 'Free Mega Health & Eye Checkup Camp for Ward Residents',
      titleMr: 'भव्य मोफत महा-आरोग्य, मधुमेह व नेत्रतपासणी शिबिर',
      description:
          'तज्ज्ञ डॉक्टरांच्या उपस्थितीत ईसीजी, रक्तदाब, मधुमेह व डोळ्यांची मोफत तपासणी. गरजूंना जागेवर मोफत चष्मे व औषधे वाटप केली जातील.',
      eventDate: DateTime.now().add(const Duration(days: 10)),
      eventTime: 'सकाळी ०९:०० ते दुपारी ०२:००',
      location: 'Ahilyabai Holkar School Ground, Narayan Peth',
      locationMr: 'अहिल्याबाई होळकर शाळा प्रांगण, नारायण पेठ',
      type: EventType.healthCamp,
      status: 'Planned',
      area: 'नारायण पेठ',
      targetAudience: 'Senior Citizens & Women',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      rsvps: [
        EventRsvpModel(
          id: 'rsvp-301',
          voterName: 'Vijay Vasantrao Pawar',
          voterNameMr: 'विजय वसंतराव पवार',
          mobile: '9422556677',
          address: 'नारायण पेठ, मोदी गणपती गल्ली',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        EventRsvpModel(
          id: 'rsvp-302',
          voterName: 'Kavita Nitin Kadam',
          voterNameMr: 'कविता नितीन कदम',
          mobile: '9890445566',
          address: 'लक्ष्मी रोड कॉर्नर',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
    EventModel(
      id: 'evt-004',
      title: 'Swachh Prabhag Cleanliness & Plastic-Free Public Rally',
      titleMr: 'स्वच्छ प्रभाग - सुंदर प्रभाग जनजागृती महा-रॅली',
      description:
          'कचरा वर्गीकरण आणि प्लास्टिक मुक्ती जनजागृतीसाठी नागरिक, विद्यार्थी व स्वच्छता कर्मचाऱ्यांची भव्य पदयात्रा आणि रॅली.',
      eventDate: DateTime.now().add(const Duration(days: 14)),
      eventTime: 'सकाळी ०७:३० वा.',
      location: 'Starting from Phadke Haud Chowk to Shaniwar Wada',
      locationMr: 'फडके हौद चौक ते शनिवार वाडा, पुणे',
      type: EventType.rally,
      status: 'Planned',
      area: 'कसबा-विश्रामबाग',
      targetAudience: 'Youth & Citizens',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      rsvps: [
        EventRsvpModel(
          id: 'rsvp-401',
          voterName: 'Akash Sudhir Bhosale',
          voterNameMr: 'आकाश सुधीर भोसले',
          mobile: '9922001122',
          address: 'रास्ता पेठ, पॉवर हाऊस जवळ',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
    ),
    EventModel(
      id: 'evt-005',
      title: 'Women Self-Help Groups Empowerment & Haldi-Kumkum Gathering',
      titleMr: 'महिला बचत गट सक्षमीकरण व हळदी-कुंकू स्नेहमेळावा',
      description:
          'महिला बचत गटांच्या उत्पादनांचे प्रदर्शन, उद्योग मार्गदर्शन आणि वार्षिक हळदी-कुंकू स्नेहमेळावा मोठ्या उत्साहात संपन्न.',
      eventDate: DateTime.now().subtract(const Duration(days: 3)),
      eventTime: 'दुपारी ०४:०० वा.',
      location: 'Ramanbaug Highschool Auditorium, Shaniwar Peth',
      locationMr: 'रमणबाग प्रशाला सभागृह, शनिवार पेठ',
      type: EventType.cultural,
      status: 'Completed',
      area: 'शनिवार पेठ',
      targetAudience: 'Women',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      rsvps: [
        EventRsvpModel(
          id: 'rsvp-501',
          voterName: 'Shobha Pandurang Sane',
          voterNameMr: 'शोभा पांडुरंग साने',
          mobile: '9822998877',
          address: 'शनिवार पेठ, घर क्र. १२',
          status: RsvpStatus.going,
          responseSource: 'Direct Call',
          respondedAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
        EventRsvpModel(
          id: 'rsvp-502',
          voterName: 'Aarti Deepak Ranade',
          voterNameMr: 'आरती दीपक रानडे',
          mobile: '9890112233',
          address: 'अंजली सोसायटी, शनिवार पेठ',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
      ],
    ),
    EventModel(
      id: 'evt-006',
      title: 'Ward 12 Youth Sports Festival & Marathon Prize Ceremony',
      titleMr: 'युवा क्रीडा महोत्सव व मिनी मॅरेथॉन बक्षीस वितरण सोहळा',
      description:
          'प्रभागातील युवक-युवतींसाठी आयोजित क्रिकेट, बॅडमिंटन व ५ किमी मिनी मॅरेथॉन स्पर्धांचे भव्य पारितोषिक वितरण.',
      eventDate: DateTime.now().subtract(const Duration(days: 8)),
      eventTime: 'सायंकाळी ०५:३० वा.',
      location: 'Deccan Gymkhana Sports Complex Ground',
      locationMr: 'डेक्कन जिमखाना क्रीडा संकुल मैदान, पुणे',
      type: EventType.cultural,
      status: 'Completed',
      area: 'डेक्कन परिसर',
      targetAudience: 'Youth',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      rsvps: [
        EventRsvpModel(
          id: 'rsvp-601',
          voterName: 'Siddhesh Dilip Kadam',
          voterNameMr: 'सिद्धेश दिलीप कदम',
          mobile: '9922334411',
          address: 'शनिवार पेठ, व्यायामशाळा जवळ',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
    ),
    EventModel(
      id: 'evt-007',
      title: 'Door-to-Door Citizen Grievance Redressal Walkthrough',
      titleMr: 'घरोघरी जनसंवाद व समस्या निवारण थेट भेट दौरा',
      description:
          'नागरिकांशी थेट संवाद साधून वीज, पाणी, ड्रेनेज व रस्त्यांच्या अडचणी जागेवर समजून घेऊन मनपा अधिकाऱ्यांसमक्ष सोडविण्यासाठी भेट दौरा.',
      eventDate: DateTime.now().add(const Duration(days: 18)),
      eventTime: 'दुपारी ०४:३० वा.',
      location: 'Rasta Peth Powerhouse Chowk and Society Clusters',
      locationMr: 'रास्ता पेठ पॉवर हाऊस चौक व सोसायटी परिसर',
      type: EventType.doorToDoor,
      status: 'Planned',
      area: 'रास्ता पेठ',
      targetAudience: 'All Citizens',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      rsvps: [
        EventRsvpModel(
          id: 'rsvp-701',
          voterName: 'Nitin Arvind Bapat',
          voterNameMr: 'नितीन अरविंद बापट',
          mobile: '9822667788',
          address: 'रास्ता पेठ, लेन ४',
          status: RsvpStatus.going,
          responseSource: 'WhatsApp Bot',
          respondedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    ),
  ];

  final List<ConstituentInviteContact> _voters = const [
    ConstituentInviteContact(
      id: 'vt-1',
      name: 'Ramesh Balwant Kulkarni',
      nameMr: 'रमेश बळवंत कुलकर्णी',
      mobile: '9822011223',
      area: 'शनिवार पेठ',
      address: 'घर क्र. ४५, शनिवार पेठ, पुणे',
      age: 58,
      gender: 'M',
    ),
    ConstituentInviteContact(
      id: 'vt-2',
      name: 'Sunita Anand Joshi',
      nameMr: 'सुनिता आनंद जोशी',
      mobile: '9822044556',
      area: 'शनिवार पेठ',
      address: 'सदाशिव सदन, शनिवार पेठ, पुणे',
      age: 52,
      gender: 'F',
    ),
    ConstituentInviteContact(
      id: 'vt-3',
      name: 'Anil Dattatray Gaikwad',
      nameMr: 'अनिल दत्तात्रय गायकवाड',
      mobile: '9822334455',
      area: 'कसबा पेठ',
      address: 'घर क्र. १२, कसबा पेठ, पुणे',
      age: 46,
      gender: 'M',
    ),
    ConstituentInviteContact(
      id: 'vt-4',
      name: 'Vijay Vasantrao Pawar',
      nameMr: 'विजय वसंतराव पवार',
      mobile: '9422556677',
      area: 'नारायण पेठ',
      address: 'मोदी गणपती गल्ली, नारायण पेठ, पुणे',
      age: 61,
      gender: 'M',
    ),
    ConstituentInviteContact(
      id: 'vt-5',
      name: 'Akash Sudhir Bhosale',
      nameMr: 'आकाश सुधीर भोसले',
      mobile: '9922001122',
      area: 'रास्ता पेठ',
      address: 'पॉवर हाऊस जवळ, रास्ता पेठ, पुणे',
      age: 26,
      gender: 'M',
    ),
    ConstituentInviteContact(
      id: 'vt-6',
      name: 'Kavita Nitin Kadam',
      nameMr: 'कविता नितीन कदम',
      mobile: '9890445566',
      area: 'नारायण पेठ',
      address: 'लक्ष्मी रोड कॉर्नर, नारायण पेठ, पुणे',
      age: 38,
      gender: 'F',
    ),
    ConstituentInviteContact(
      id: 'vt-7',
      name: 'Prakash Mahadev Shinde',
      nameMr: 'प्रकाश महादेव शिंदे',
      mobile: '9422033445',
      area: 'शनिवार पेठ',
      address: 'ओम अपार्टमेंट, शनिवार पेठ, पुणे',
      age: 49,
      gender: 'M',
    ),
    ConstituentInviteContact(
      id: 'vt-8',
      name: 'Prashant Madhukar Jagtap',
      nameMr: 'प्रशांत मधुकर जगताप',
      mobile: '9881023456',
      area: 'कसबा पेठ',
      address: 'लाल महाल चौक परिसर, कसबा पेठ',
      age: 34,
      gender: 'M',
    ),
    ConstituentInviteContact(
      id: 'vt-9',
      name: 'Meena Sanjay Patil',
      nameMr: 'मीना संजय पाटील',
      mobile: '9766554433',
      area: 'कसबा पेठ',
      address: 'फडके हौद चौक, कसबा पेठ',
      age: 44,
      gender: 'F',
    ),
    ConstituentInviteContact(
      id: 'vt-10',
      name: 'Nitin Arvind Bapat',
      nameMr: 'नितीन अरविंद बापट',
      mobile: '9822667788',
      area: 'रास्ता पेठ',
      address: 'रास्ता पेठ लेन ४, पुणे',
      age: 55,
      gender: 'M',
    ),
  ];

  Future<List<EventModel>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_events);
  }

  Future<EventModel?> getEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<EventModel> createEvent(EventModel event) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _events.insert(0, event);
    return event;
  }

  Future<EventModel> updateEvent(EventModel event) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx != -1) {
      _events[idx] = event;
      return event;
    }
    throw Exception('Event not found');
  }

  Future<void> deleteEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _events.removeWhere((e) => e.id == id);
  }

  Future<void> addRsvp(String eventId, EventRsvpModel rsvp) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      final updatedRsvps = List<EventRsvpModel>.from(_events[idx].rsvps)
        ..removeWhere((r) => r.mobile == rsvp.mobile)
        ..insert(0, rsvp);
      _events[idx] = _events[idx].copyWith(rsvps: updatedRsvps);
    }
  }

  List<ConstituentInviteContact> getVotersForInvites() {
    return List.unmodifiable(_voters);
  }
}

final eventsRepoProvider = Provider<EventsRepository>((ref) {
  return EventsRepository();
});

