import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/karyakarta_work_model.dart';

final karyakartaWorkRepoProvider = Provider<KaryakartaWorkRepository>((ref) {
  return KaryakartaWorkRepository();
});

class KaryakartaWorkRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // ─────────────────────────────────────────────────────────────
  // 1. Seed Staff Members (Office, Cooperative, Party)
  // ─────────────────────────────────────────────────────────────
  final List<KaryakartaWorkStaff> _seedStaff = [
    // Office Team
    const KaryakartaWorkStaff(
      id: 'stf-001',
      name: 'Adv. Sachin Deshmukh',
      nameMarathi: 'अ‍ॅड. सचिन सुधाकर देशमुख',
      mobile: '9822011223',
      email: 'sachin.deshmukh@nagarsevak.office',
      role: 'Office Admin (कार्यालय प्रमुख)',
      area: 'शनिवार पेठ',
      category: 'Office',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-002',
      name: 'Ramesh Balasaheb Kadam',
      nameMarathi: 'रमेश बाळासाहेब कदम',
      mobile: '9850334455',
      email: 'ramesh.kadam@nagarsevak.office',
      role: 'Supervisor (क्षेत्रीय पर्यवेक्षक)',
      area: 'कसबा पेठ',
      category: 'Office',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-003',
      name: 'Pooja Anand Shinde',
      nameMarathi: 'पूजा आनंद शिंदे',
      mobile: '9890556677',
      email: 'pooja.shinde@nagarsevak.office',
      role: 'Executive (योजना समन्वयक)',
      area: 'रविवार पेठ',
      category: 'Office',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-005',
      name: 'Omkar Rajendra Jagtap',
      nameMarathi: 'ओंकार राजेंद्र जगताप',
      mobile: '9823998877',
      email: 'omkar.jagtap@nagarsevak.office',
      role: 'IT Cell Head (माहिती तंत्रज्ञान)',
      area: 'शनिवार पेठ',
      category: 'Office',
    ),

    // Cooperative / Government Work
    const KaryakartaWorkStaff(
      id: 'stf-009',
      name: 'Suresh Vitthalrao Mane',
      nameMarathi: 'सुरेश विठ्ठलराव माने',
      mobile: '9822771144',
      role: 'Ward Officer Liaison (शासकीय समन्वयक)',
      area: 'कसबा पेठ',
      category: 'Cooperative',
      pad: 'वरिष्ठ संपर्क अधिकारी',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-010',
      name: 'Deepak Manohar More',
      nameMarathi: 'दीपक मनोहर मोरे',
      mobile: '9850119933',
      role: 'Health & Sanitation Inspector (आरोग्य निरीक्षक)',
      area: 'शनिवार पेठ',
      category: 'Cooperative',
      pad: 'वॉर्ड आरोग्य प्रमुख',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-011',
      name: 'Archana Pravin Joshi',
      nameMarathi: 'अर्चना प्रवीण जोशी',
      mobile: '9422556688',
      role: 'Housing Society Liaison (सोसायटी समन्वयक)',
      area: 'प्रभात रोड',
      category: 'Cooperative',
      pad: 'सहकार सेल प्रमुख',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-012',
      name: 'Ganesh Babanrao Jagtap',
      nameMarathi: 'गणेश बबनराव जगताप',
      mobile: '9823004411',
      role: 'PMC Electrical Liaison (विद्युत अभियंता)',
      area: 'शुक्रवार पेठ',
      category: 'Cooperative',
      pad: 'विद्युत व दिवाबत्ती',
    ),

    // Party Workers (पक्ष कार्यकर्ता)
    const KaryakartaWorkStaff(
      id: 'stf-006',
      name: 'Swapnil Vilasrao More',
      nameMarathi: 'स्वप्नील विलासराव मोरे',
      mobile: '9422019988',
      role: 'Karyakarta (युवक आघाडी)',
      area: 'शनिवार पेठ',
      category: 'Party',
      partyWing: 'युवक आघाडी',
      pad: 'प्रभाग युवक अध्यक्ष',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-007',
      name: 'Vaishali Nilesh Kulkarni',
      nameMarathi: 'वैशाली निलेश कुलकर्णी',
      mobile: '9881234567',
      role: 'Karyakarta (महिला आघाडी)',
      area: 'कसबा पेठ',
      category: 'Party',
      partyWing: 'महिला आघाडी',
      pad: 'प्रभाग महिला संयोजिका',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-008',
      name: 'Nitin Pandurang Jadhav',
      nameMarathi: 'नितीन पांडुरंग जाधव',
      mobile: '9763445566',
      role: 'Karyakarta (ज्येष्ठ नागरिक आघाडी)',
      area: 'रविवार पेठ',
      category: 'Party',
      partyWing: 'ज्येष्ठ नागरिक आघाडी',
      pad: 'संघटक',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-013',
      name: 'Sagar Baburao Shinde',
      nameMarathi: 'सागर बाबुराव शिंदे',
      mobile: '9890123456',
      role: 'Booth Pramukh (बूथ प्रमुख)',
      area: 'शनिवार पेठ',
      category: 'Party',
      partyWing: 'बूथ समिती',
      pad: 'बूथ क्र. १२/४ प्रमुख',
    ),
    const KaryakartaWorkStaff(
      id: 'stf-014',
      name: 'Rahul Dattatray Patil',
      nameMarathi: 'राहुल दत्तात्रय पाटील',
      mobile: '9822889900',
      role: 'Karyakarta (विद्यार्थी आघाडी)',
      area: 'कसबा पेठ',
      category: 'Party',
      partyWing: 'विद्यार्थी आघाडी',
      pad: 'विद्यार्थी प्रतिनिधी',
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // 2. Seed Tasks (Authentic tasks linked to staff & unassigned)
  // ─────────────────────────────────────────────────────────────
  late List<KaryakartaWorkTask> _seedTasks = [
    // stf-001 (Adv. Sachin Deshmukh - Office)
    KaryakartaWorkTask(
      id: 'TSK-101',
      title: 'महानगरपालिका सामान्य सभा (GB) प्रश्नपत्रिका तपासणी',
      description: 'आगामी मंगळवारच्या GB मधील प्रभाग १२ चे प्रलंबित प्रश्न व मंजुरी नोंदी अंतिम करणे.',
      priority: 'High',
      status: 'Pending',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      dueTime: '11:00',
      address: 'नागरसेवक जनसंपर्क कार्यालय, शनिवार पेठ',
      assignedStaffId: 'stf-001',
      assignedStaffName: 'Adv. Sachin Deshmukh',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    KaryakartaWorkTask(
      id: 'TSK-102',
      title: 'नागरिक विकास निधी पत्रव्यवहार संचिका मंजुरी',
      description: 'रस्ता डांबरीकरण व भुयारी गटार अंदाजपत्रकाची अधिकृत PMC कडे स्वाक्षरी फाइल तयार करणे.',
      priority: 'Medium',
      status: 'In Progress',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      dueTime: '15:00',
      address: 'पालिका मुख्यालय, २ रा मजला',
      assignedStaffId: 'stf-001',
      assignedStaffName: 'Adv. Sachin Deshmukh',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    KaryakartaWorkTask(
      id: 'TSK-103',
      title: 'कार्यालयीन आवक-जावक रजिस्टर साप्ताहिक आढावा',
      description: 'नागरिकांच्या ७५ अर्जांचा पाठपुरावा व निपटारा नोंदवही पूर्ण झाली आहे.',
      priority: 'Low',
      status: 'Completed',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      dueTime: '18:00',
      address: 'कार्यालय शनिवार पेठ',
      assignedStaffId: 'stf-001',
      assignedStaffName: 'Adv. Sachin Deshmukh',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),

    // stf-002 (Ramesh Balasaheb Kadam - Office Supervisor)
    KaryakartaWorkTask(
      id: 'TSK-104',
      title: 'कसबा पेठ गल्ली नं. ४ जलवाहिनी गळती प्रत्यक्ष पाहणी',
      description: 'पाण्याच्या कमी दाबाबाबत तक्रार होती, PMC पाणीपुरवठा कंत्राटदारासमवेत साईट इन्स्पेक्शन.',
      priority: 'High',
      status: 'In Progress',
      dueDate: DateTime.now(),
      dueTime: '10:30',
      address: 'कसबा पेठ, गणपती मंदिर परिसर',
      assignedStaffId: 'stf-002',
      assignedStaffName: 'Ramesh Balasaheb Kadam',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    KaryakartaWorkTask(
      id: 'TSK-105',
      title: 'काँक्रीट रस्ता पुनर्बांधणी कंत्राटदार काम तपासणी',
      description: 'सेक्टर २ मुख्य बाजारपेठ रस्ता डांबरीकरण जाडी व गट्टू पेव्हिंग ब्लॉक काम पूर्ण झाले.',
      priority: 'Medium',
      status: 'Completed',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      dueTime: '16:00',
      address: 'सेक्टर २ मेन रोड',
      assignedStaffId: 'stf-002',
      assignedStaffName: 'Ramesh Balasaheb Kadam',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),

    // stf-003 (Pooja Anand Shinde - Office)
    KaryakartaWorkTask(
      id: 'TSK-106',
      title: 'लाडकी बहीण योजना प्रलंबित १०० अर्जांची ऑनलाइन पडताळणी',
      description: 'आधार प्रमाणीकरण न झालेल्या महिलांना संपर्क करून बँक खाती सीड करणे.',
      priority: 'High',
      status: 'In Progress',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      dueTime: '14:00',
      address: 'रविवार पेठ संपर्क केंद्र',
      assignedStaffId: 'stf-003',
      assignedStaffName: 'Pooja Anand Shinde',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    KaryakartaWorkTask(
      id: 'TSK-107',
      title: 'ज्येष्ठ नागरिक पेन्शन शिबिर प्रमाणपत्र वाटप',
      description: 'संजय गांधी निराधार योजनेचे ४२ लाभार्थ्यांना मंजुरी पत्र वाटप यशस्वीपणे पूर्ण.',
      priority: 'Low',
      status: 'Completed',
      dueDate: DateTime.now().subtract(const Duration(days: 3)),
      dueTime: '11:30',
      address: 'नागरसेवक जनसंपर्क कार्यालय',
      assignedStaffId: 'stf-003',
      assignedStaffName: 'Pooja Anand Shinde',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // stf-005 (Omkar Rajendra Jagtap - Office IT)
    KaryakartaWorkTask(
      id: 'TSK-108',
      title: 'विकासकामांची सोशल मीडिया माहिती पत्रके व व्हिडिओ तयार करणे',
      description: 'प्रभाग १२ मधील नवीन उद्यानाच्या उद्घाटनाचे रील्स आणि व्हॉट्सॲप स्टेटस बॅनर तयार करा.',
      priority: 'Medium',
      status: 'Pending',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      dueTime: '17:00',
      address: 'सोशल मीडिया सेल, शनिवार पेठ',
      assignedStaffId: 'stf-005',
      assignedStaffName: 'Omkar Rajendra Jagtap',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // stf-009 (Suresh Vitthalrao Mane - Cooperative / Liaison)
    KaryakartaWorkTask(
      id: 'TSK-109',
      title: 'PMC प्रभाग अधिकारी वॉर्ड समन्वय बैठक',
      description: 'ड्रेनेज स्वच्छता आणि आगामी पावसाळा पूर्वतयारी कामांचे नियोजन बैठकीत सादर करणे.',
      priority: 'High',
      status: 'Pending',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      dueTime: '11:00',
      address: 'PMC प्रभाग कार्यालय क्र. १२',
      assignedStaffId: 'stf-009',
      assignedStaffName: 'Suresh Vitthalrao Mane',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    KaryakartaWorkTask(
      id: 'TSK-110',
      title: 'शासकीय वृक्ष प्राधिकरण झाडे छाटणी परवानग्या',
      description: 'धोकादायक झाडांच्या फांद्या छाटणीसाठी उद्यान विभागाशी संपर्क साधून वर्क ऑर्डर मिळवली.',
      priority: 'Medium',
      status: 'Completed',
      dueDate: DateTime.now().subtract(const Duration(days: 4)),
      dueTime: '14:30',
      address: 'कसबा पेठ',
      assignedStaffId: 'stf-009',
      assignedStaffName: 'Suresh Vitthalrao Mane',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),

    // stf-010 (Deepak Manohar More - Cooperative Health)
    KaryakartaWorkTask(
      id: 'TSK-111',
      title: 'प्रभाग १२ मधील डास प्रतिबंधक धुरळणी (Fogging) मोहीम',
      description: 'डेंग्यू आणि मलेरिया प्रतिबंधासाठी शनिवार पेठ व रविवार पेठेत धूर फवारणी पूर्ण करणे.',
      priority: 'High',
      status: 'In Progress',
      dueDate: DateTime.now(),
      dueTime: '18:00',
      address: 'शनिवार पेठ व आसपास',
      assignedStaffId: 'stf-010',
      assignedStaffName: 'Deepak Manohar More',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // stf-011 (Archana Pravin Joshi - Cooperative Societies)
    KaryakartaWorkTask(
      id: 'TSK-112',
      title: 'प्रभात रोड परिसरातील २५ सोसायट्यांचे कचरा वर्गीकरण मार्गदर्शन',
      description: 'सोसायटी चेअरमन व सेक्रेटरींसोबत ओला व सुका कचरा प्रकल्प बैठक.',
      priority: 'Medium',
      status: 'Pending',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      dueTime: '10:00',
      address: 'प्रभात रोड सोसायटी सभागृह',
      assignedStaffId: 'stf-011',
      assignedStaffName: 'Archana Pravin Joshi',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),

    // stf-012 (Ganesh Babanrao Jagtap - Cooperative Electrical)
    KaryakartaWorkTask(
      id: 'TSK-113',
      title: 'शुक्रवार पेठेतील ४५ नवीन एलईडी पथदिवे कार्यान्वित करणे',
      description: 'MSEDCL व पालिका विद्युत विभागाकडून बंद दिवे बदलून नवीन एलईडी दिवे बसवणे.',
      priority: 'Medium',
      status: 'Completed',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      dueTime: '19:00',
      address: 'शुक्रवार पेठ मेन चौक',
      assignedStaffId: 'stf-012',
      assignedStaffName: 'Ganesh Babanrao Jagtap',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),

    // stf-006 (Swapnil Vilasrao More - Party Youth)
    KaryakartaWorkTask(
      id: 'TSK-114',
      title: 'शनिवार पेठ युवा मेळावा व मतदार नोंदणी स्टॉल नियोजन',
      description: '१८ वर्षे पूर्ण झालेल्या महाविद्यालयीन तरुणांचे फॉर्म ६ ऑनलाईन भरण्यासाठी शिबिर.',
      priority: 'High',
      status: 'In Progress',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      dueTime: '09:30',
      address: 'शनिवार पेठ कम्युनिटी हॉल',
      assignedStaffId: 'stf-006',
      assignedStaffName: 'Swapnil Vilasrao More',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    KaryakartaWorkTask(
      id: 'TSK-115',
      title: 'वॉर्ड क्रीडा महोत्सव मैदान आरक्षण व परवानग्या',
      description: 'क्रिकेट व कबड्डी स्पर्धा आयोजनासाठी पालिका क्रीडा विभागाची परवानगी प्राप्त.',
      priority: 'Medium',
      status: 'Completed',
      dueDate: DateTime.now().subtract(const Duration(days: 3)),
      dueTime: '16:00',
      address: 'टिळक मैदान',
      assignedStaffId: 'stf-006',
      assignedStaffName: 'Swapnil Vilasrao More',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // stf-007 (Vaishali Nilesh Kulkarni - Party Women)
    KaryakartaWorkTask(
      id: 'TSK-116',
      title: 'महिला बचत गट मेळावा व गृहउद्योग प्रदर्शन समन्वय',
      description: 'कसबा पेठेत बचत गटांच्या उत्पादनांचे प्रदर्शन व कर्ज मार्गदर्शन शिबिर.',
      priority: 'Medium',
      status: 'Pending',
      dueDate: DateTime.now().add(const Duration(days: 4)),
      dueTime: '15:00',
      address: 'कसबा पेठ सांस्कृतिक केंद्र',
      assignedStaffId: 'stf-007',
      assignedStaffName: 'Vaishali Nilesh Kulkarni',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),

    // stf-013 (Sagar Baburao Shinde - Booth Pramukh)
    KaryakartaWorkTask(
      id: 'TSK-117',
      title: 'बूथ क्र. १२/४ मतदार यादी पडताळणी व घरोघरी पत्रक वाटप',
      description: 'बूथवरील १,१०० मतदारांना विकासकामांची माहिती देणारे पत्रक वाटप करणे.',
      priority: 'High',
      status: 'Pending',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      dueTime: '17:30',
      address: 'बूथ क्षेत्र १२/४, शनिवार पेठ',
      assignedStaffId: 'stf-013',
      assignedStaffName: 'Sagar Baburao Shinde',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // UNASSIGNED TASKS (Work Pool)
    KaryakartaWorkTask(
      id: 'TSK-901',
      title: 'सार्वजनिक शौचालय स्वच्छता कंत्राटदार तक्रार निवारण',
      description: 'रविवार पेठेतील सार्वजनिक स्वच्छतागृहामध्ये पाणी तुंबल्याची नागरिकांची तक्रार, त्वरित काम सोपवावे.',
      priority: 'High',
      status: 'Pending',
      dueDate: DateTime.now(),
      dueTime: '12:00',
      address: 'रविवार पेठ भाजी मार्केट जवळ',
      assignedStaffId: null,
      assignedStaffName: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    KaryakartaWorkTask(
      id: 'TSK-902',
      title: 'नवीन गतिरोधक (Speed Breaker) पांढरे पट्टे रंगवणे',
      description: 'शाळेसमोरील गतिरोधकावर रात्रीच्या वेळी अपघात टाळण्यासाठी रिफ्लेक्टीव्ह पट्टे मारणे.',
      priority: 'Medium',
      status: 'Pending',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      dueTime: '21:00',
      address: 'विद्यामंदिर शाळा चौक, कसबा पेठ',
      assignedStaffId: null,
      assignedStaffName: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    KaryakartaWorkTask(
      id: 'TSK-903',
      title: 'गणेशोत्सवाच्या पार्श्वभूमीवर रस्त्यावरील खड्डे बुजविणे',
      description: 'मिरवणूक मार्गावरील खड्डे त्वरित कोल्ड मिक्स अस्फाल्टने बुजवण्यासाठी काम सोपवा.',
      priority: 'High',
      status: 'Pending',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      dueTime: '16:00',
      address: 'शिवाजी रोड मुख्य चौक',
      assignedStaffId: null,
      assignedStaffName: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // 3. Seed Complaints (Linked to staff & unassigned)
  // ─────────────────────────────────────────────────────────────
  late List<KaryakartaWorkComplaint> _seedComplaints = [
    // stf-001 (Adv. Sachin Deshmukh)
    KaryakartaWorkComplaint(
      id: 'CMP-201',
      title: 'सोसायटीच्या कंपाऊंड वॉल परवानग्या बाबत PMC नोटीस',
      description: 'PMC कडून अनधिकृत बांधकामाची चुकीची नोटीस आली आहे, कागदपत्रे तपासून दुरुस्ती करावी.',
      type: 'प्रशासन / परवानग्या',
      area: 'शनिवार पेठ',
      location: 'रामनारायण सोसायटी, शनिवार पेठ',
      status: 'InProgress',
      voterName: 'श्री. विजय रामचंद्र जोशी',
      voterMobile: '9822445566',
      assignedTo: 'stf-001',
      assignedStaffName: 'Adv. Sachin Deshmukh',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    KaryakartaWorkComplaint(
      id: 'CMP-202',
      title: 'वृद्ध निवृत्तीवेतन प्रमाणपत्र अर्ज गहाळ तक्रार',
      description: 'तहसीलदार कार्यालयाकडून मंजुरी पत्र मिळवून लाभार्थ्याला सुपूर्द करण्यात आले.',
      type: 'शासकीय योजना',
      area: 'शनिवार पेठ',
      location: 'घर क्र. १२४, शनिवार पेठ',
      status: 'Resolved',
      voterName: 'श्रीमती मंदाकिनी प्रभाकर कुलकर्णी',
      voterMobile: '9422001122',
      assignedTo: 'stf-001',
      assignedStaffName: 'Adv. Sachin Deshmukh',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // stf-002 (Ramesh Balasaheb Kadam - Office Supervisor)
    KaryakartaWorkComplaint(
      id: 'CMP-203',
      title: 'कसबा पेठ गल्ली नं. २ गटार तुंबून दुर्गंधी पसरली',
      description: 'सकाळी पाणी सोडल्यावर चेंबर ओसंडून वाहत आहे. त्वरित जेटिंग मशीन मागवावे.',
      type: 'ड्रेनेज व स्वच्छता',
      area: 'कसबा पेठ',
      location: 'गल्ली नं. २, कसबा पेठ',
      status: 'Pending',
      voterName: 'श्री. आनंद विष्णू घोडके',
      voterMobile: '9850667788',
      assignedTo: 'stf-002',
      assignedStaffName: 'Ramesh Balasaheb Kadam',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    KaryakartaWorkComplaint(
      id: 'CMP-204',
      title: 'पिण्याच्या पाण्याची मुख्य पाइपलाइन गळती',
      description: 'पालिका पाणीपुरवठा विभागाशी संपर्क करून गळती दुरुस्त करण्यात आली.',
      type: 'पाणीपुरवठा',
      area: 'कसबा पेठ',
      location: 'तांबट आळी, कसबा पेठ',
      status: 'Resolved',
      voterName: 'श्री. सुधीर मारुती तांबट',
      voterMobile: '9764553322',
      assignedTo: 'stf-002',
      assignedStaffName: 'Ramesh Balasaheb Kadam',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),

    // stf-003 (Pooja Anand Shinde)
    KaryakartaWorkComplaint(
      id: 'CMP-205',
      title: 'नवीन शिधापत्रिका (Ration Card) नाव समाविष्ट न होणे',
      description: 'पुरवठा कार्यालयात आवश्यक कागदपत्रांची पूर्तता करून नाव समाविष्ट करून दिले.',
      type: 'नागरी सेवा',
      area: 'रविवार पेठ',
      location: 'रविवार पेठ, लेन ४',
      status: 'Resolved',
      voterName: 'श्रीमती सविता किशोर मोरे',
      voterMobile: '9881112233',
      assignedTo: 'stf-003',
      assignedStaffName: 'Pooja Anand Shinde',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),

    // stf-009 (Suresh Vitthalrao Mane - Cooperative)
    KaryakartaWorkComplaint(
      id: 'CMP-206',
      title: 'रस्त्यावरील मोकाट श्वानांचा उपद्रव व चावा घेण्याच्या घटना',
      description: 'PMC श्वान नियंत्रण पथकाला कळवून निर्बीजीकरण गाडी मागवली आहे.',
      type: 'आरोग्य व स्वच्छता',
      area: 'कसबा पेठ',
      location: 'कसबा पेठ मारुती मंदिर परिसर',
      status: 'InProgress',
      voterName: 'श्री. प्रकाश जगन्नाथ शिंदे',
      voterMobile: '9822998811',
      assignedTo: 'stf-009',
      assignedStaffName: 'Suresh Vitthalrao Mane',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),

    // stf-010 (Deepak Manohar More - Cooperative Health)
    KaryakartaWorkComplaint(
      id: 'CMP-207',
      title: 'कचरा उचलण्याची घंटागाडी सकाळी वेळेवर न येणे',
      description: 'आरोग्य विभागाच्या कचरा व्हॅन ड्रायव्हरला नोटीस देऊन वेळेत बदल केला.',
      type: 'घनकचरा व्यवस्थापन',
      area: 'शनिवार पेठ',
      location: 'शनिवार पेठ लेन ५',
      status: 'Resolved',
      voterName: 'श्रीमती नीलिमा विवेक पटवर्धन',
      voterMobile: '9423114455',
      assignedTo: 'stf-010',
      assignedStaffName: 'Deepak Manohar More',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),

    // stf-012 (Ganesh Babanrao Jagtap - Cooperative Electrical)
    KaryakartaWorkComplaint(
      id: 'CMP-208',
      title: 'शुक्रवार पेठेतील २ स्ट्रीट लाईट खांब बंद असल्याने अंधार',
      description: 'स्थानिक रहिवाशांना रात्री चोरीची भीती वाटते, त्वरित दुरुस्ती व्हावी.',
      type: 'पथदिवे व वीज',
      area: 'शुक्रवार पेठ',
      location: 'शुक्रवार पेठ, पोतदार गल्ली',
      status: 'Pending',
      voterName: 'श्री. महेश बाळकृष्ण पोतदार',
      voterMobile: '9890223344',
      assignedTo: 'stf-012',
      assignedStaffName: 'Ganesh Babanrao Jagtap',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // stf-006 (Swapnil Vilasrao More - Party Youth)
    KaryakartaWorkComplaint(
      id: 'CMP-209',
      title: 'स्थानिक क्रीडांगणावर रात्री समाजकंटकांचा वावर',
      description: 'पोलिस गस्त वाढवण्यासाठी शनिवार पेठ पोलीस चौकीशी संपर्क साधून पत्र दिले.',
      type: 'सुरक्षा व कायदा',
      area: 'शनिवार पेठ',
      location: 'टिळक क्रीडा मैदान परिसर',
      status: 'Resolved',
      voterName: 'श्री. सचिन भास्कर पाटील',
      voterMobile: '9765001122',
      assignedTo: 'stf-006',
      assignedStaffName: 'Swapnil Vilasrao More',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),

    // stf-007 (Vaishali Nilesh Kulkarni - Party Women)
    KaryakartaWorkComplaint(
      id: 'CMP-210',
      title: 'सार्वजनिक नळावर महिलांच्या पिण्याच्या पाण्याची वादावादी',
      description: 'पाण्याची वेळ वाढवण्यासाठी पाणीपुरवठा अधिकाऱ्यांशी चर्चा करून वेळ सकाळी ६ ते ८ केली.',
      type: 'पाणीपुरवठा',
      area: 'कसबा पेठ',
      location: 'कसबा पेठ सार्वजनिक हौद',
      status: 'Resolved',
      voterName: 'श्रीमती आशा अशोक गायकवाड',
      voterMobile: '9850442211',
      assignedTo: 'stf-007',
      assignedStaffName: 'Vaishali Nilesh Kulkarni',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // UNASSIGNED COMPLAINTS (Work Pool)
    KaryakartaWorkComplaint(
      id: 'CMP-901',
      title: 'रविवार पेठेत झाडाची धोकादायक फांदी तारांवर लटकली',
      description: 'जोरदार वाऱ्यामुळे फांदी विजेच्या तारांवर पडली आहे, शॉर्ट सर्किट होण्याचा धोका आहे.',
      type: 'आपत्कालीन / वीज',
      area: 'रविवार पेठ',
      location: 'रविवार पेठ कापड बाजार',
      status: 'Pending',
      voterName: 'श्री. दिलीप ताराचंद ओसवाल',
      voterMobile: '9822338899',
      assignedTo: null,
      assignedStaffName: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    KaryakartaWorkComplaint(
      id: 'CMP-902',
      title: 'रस्त्यावरील उघडे मॅनहोल चेंबर झाकण तुटले',
      description: 'पादचारी व दुचाकी चालकांसाठी अत्यंत धोकादायक, त्वरित नवीन काँक्रीट झाकण बसवणे आवश्यक.',
      type: 'ड्रेनेज व रस्ते',
      area: 'कसबा पेठ',
      location: 'कसबा पेठ मेन रोड कोपरा',
      status: 'Pending',
      voterName: 'श्री. अभय मोरेश्वर बर्वे',
      voterMobile: '9850884422',
      assignedTo: null,
      assignedStaffName: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // 4. API Queries & Filter Operations
  // ─────────────────────────────────────────────────────────────

  Future<List<KaryakartaWorkStaff>> getStaff({
    String? category,
    String? query,
    String? area,
  }) async {
    try {
      var dbQuery = _client.from('staff').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final response = await dbQuery.order('name', ascending: true);
      final list = (response as List<dynamic>)
          .map((item) => KaryakartaWorkStaff.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) {
        return _filterStaff(list, category: category, query: query, area: area);
      }
    } catch (_) {}

    return _filterStaff(_seedStaff, category: category, query: query, area: area);
  }

  List<KaryakartaWorkStaff> _filterStaff(
    List<KaryakartaWorkStaff> staffList, {
    String? category,
    String? query,
    String? area,
  }) {
    return staffList.where((s) {
      if (category != null && category.isNotEmpty && category != 'All') {
        if (s.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (area != null && area.isNotEmpty && area != 'All') {
        if (s.area == null || !s.area!.toLowerCase().contains(area.toLowerCase())) {
          return false;
        }
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchName = s.name.toLowerCase().contains(q) ||
            (s.nameMarathi?.toLowerCase().contains(q) ?? false);
        final matchMobile = s.mobile.contains(q);
        final matchRole = s.role.toLowerCase().contains(q);
        final matchArea = s.area?.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchMobile && !matchRole && !matchArea) return false;
      }
      return true;
    }).toList();
  }

  Future<List<KaryakartaWorkTask>> getTasks() async {
    try {
      var dbQuery = _client.from('tasks').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      final list = (response as List<dynamic>)
          .map((item) => KaryakartaWorkTask.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    return List.from(_seedTasks);
  }

  Future<List<KaryakartaWorkComplaint>> getComplaints() async {
    try {
      var dbQuery = _client.from('complaints').select('*, voter:voters(name_english, name_marathi, mobile)');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      final list = (response as List<dynamic>)
          .map((item) => KaryakartaWorkComplaint.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    return List.from(_seedComplaints);
  }

  Future<List<KaryakartaStaffWorkload>> getStaffWorkloads({
    String? category,
    String? query,
    String? area,
  }) async {
    final staff = await getStaff(category: category, query: query, area: area);
    final tasks = await getTasks();
    final complaints = await getComplaints();

    final workloads = staff.map((s) {
      final sTasks = tasks.where((t) => t.assignedStaffId == s.id).toList();
      final sComplaints = complaints.where((c) => c.assignedTo == s.id).toList();
      return KaryakartaStaffWorkload(
        staff: s,
        tasks: sTasks,
        complaints: sComplaints,
      );
    }).toList();

    // Sort by busiest workload (descending totalAssigned, then pending)
    workloads.sort((a, b) {
      if (b.totalAssigned != a.totalAssigned) {
        return b.totalAssigned.compareTo(a.totalAssigned);
      }
      return b.totalPending.compareTo(a.totalPending);
    });

    return workloads;
  }

  Future<KaryakartaWorkloadSummary> getSummaryStats({String? category}) async {
    final staff = await getStaff(category: category);
    final staffIds = staff.map((s) => s.id).toSet();

    final allTasks = await getTasks();
    final allComplaints = await getComplaints();

    final categoryTasks = (category == null || category.isEmpty || category == 'All')
        ? allTasks
        : allTasks.where((t) => t.assignedStaffId != null && staffIds.contains(t.assignedStaffId)).toList();

    final categoryComplaints = (category == null || category.isEmpty || category == 'All')
        ? allComplaints
        : allComplaints.where((c) => c.assignedTo != null && staffIds.contains(c.assignedTo)).toList();

    final totalTasks = categoryTasks.length;
    final completedTasks = categoryTasks.where((t) => t.isCompleted).length;
    final inProgressTasks = categoryTasks.where((t) => t.isInProgress).length;
    final pendingTasks = categoryTasks.where((t) => t.isPending).length;

    final totalComplaints = categoryComplaints.length;
    final resolvedComplaints = categoryComplaints.where((c) => c.isResolved).length;
    final inProgressComplaints = categoryComplaints.where((c) => c.isInProgress).length;
    final pendingComplaints = categoryComplaints.where((c) => c.isPending).length;

    return KaryakartaWorkloadSummary(
      totalLoad: totalTasks + totalComplaints,
      pendingLoad: pendingTasks + pendingComplaints,
      inProgressLoad: inProgressTasks + inProgressComplaints,
      completedLoad: completedTasks + resolvedComplaints,
      totalTasks: totalTasks,
      totalComplaints: totalComplaints,
    );
  }

  List<KaryakartaWorkTask> getUnassignedTasks() {
    return _seedTasks.where((t) => t.assignedStaffId == null || t.assignedStaffId!.isEmpty).toList();
  }

  List<KaryakartaWorkComplaint> getUnassignedComplaints() {
    return _seedComplaints.where((c) => c.assignedTo == null || c.assignedTo!.isEmpty).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Actions: Assign, Update, Reassign
  // ─────────────────────────────────────────────────────────────

  Future<void> assignTask({
    required String staffId,
    required String title,
    String? description,
    String priority = 'Medium',
    DateTime? dueDate,
    String? dueTime,
    String? address,
  }) async {
    final staff = _seedStaff.firstWhere(
      (s) => s.id == staffId,
      orElse: () => const KaryakartaWorkStaff(id: '', name: 'Staff', mobile: '', role: '', category: 'Office'),
    );

    final newTask = KaryakartaWorkTask(
      id: 'TSK-${DateTime.now().millisecondsSinceEpoch % 10000}',
      title: title,
      description: description,
      priority: priority,
      status: 'Pending',
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
      dueTime: dueTime ?? '10:00',
      address: address,
      assignedStaffId: staffId,
      assignedStaffName: staff.name,
      createdAt: DateTime.now(),
    );

    try {
      final payload = newTask.toJson(tenantId: _tenantId);
      await _client.from('tasks').insert(payload);
    } catch (_) {}

    _seedTasks.insert(0, newTask);
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _client.from('tasks').update({'status': newStatus}).eq('id', taskId);
    } catch (_) {}

    final idx = _seedTasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _seedTasks[idx] = _seedTasks[idx].copyWith(status: newStatus);
    }
  }

  Future<void> reassignTask(String taskId, String newStaffId) async {
    final staff = _seedStaff.firstWhere(
      (s) => s.id == newStaffId,
      orElse: () => const KaryakartaWorkStaff(id: '', name: 'Staff', mobile: '', role: '', category: 'Office'),
    );

    try {
      await _client.from('tasks').update({
        'assigned_staff_id': newStaffId.isEmpty ? null : newStaffId,
      }).eq('id', taskId);
    } catch (_) {}

    final idx = _seedTasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _seedTasks[idx] = _seedTasks[idx].copyWith(
        assignedStaffId: newStaffId.isEmpty ? null : newStaffId,
        assignedStaffName: newStaffId.isEmpty ? null : staff.name,
      );
    }
  }

  Future<void> updateComplaintStatus(String complaintId, String newStatus) async {
    try {
      await _client.from('complaints').update({'status': newStatus}).eq('id', complaintId);
    } catch (_) {}

    final idx = _seedComplaints.indexWhere((c) => c.id == complaintId);
    if (idx != -1) {
      _seedComplaints[idx] = _seedComplaints[idx].copyWith(status: newStatus);
    }
  }

  Future<void> reassignComplaint(String complaintId, String newStaffId) async {
    final staff = _seedStaff.firstWhere(
      (s) => s.id == newStaffId,
      orElse: () => const KaryakartaWorkStaff(id: '', name: 'Staff', mobile: '', role: '', category: 'Office'),
    );

    try {
      await _client.from('complaints').update({
        'assigned_to': newStaffId.isEmpty ? null : newStaffId,
        'status': newStaffId.isNotEmpty ? 'Assigned' : 'Pending',
      }).eq('id', complaintId);
    } catch (_) {}

    final idx = _seedComplaints.indexWhere((c) => c.id == complaintId);
    if (idx != -1) {
      _seedComplaints[idx] = _seedComplaints[idx].copyWith(
        assignedTo: newStaffId.isEmpty ? null : newStaffId,
        assignedStaffName: newStaffId.isEmpty ? null : staff.name,
        status: newStaffId.isNotEmpty ? 'Assigned' : 'Pending',
      );
    }
  }

  List<String> getAvailableAreas() {
    final areas = <String>{};
    for (final s in _seedStaff) {
      if (s.area != null && s.area!.isNotEmpty) areas.add(s.area!);
    }
    return areas.toList()..sort();
  }

  List<KaryakartaWorkStaff> getAllStaffList() {
    return List.unmodifiable(_seedStaff);
  }
}

