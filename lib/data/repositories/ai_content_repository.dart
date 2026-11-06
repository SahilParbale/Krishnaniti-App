import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_content_model.dart';

class AiContentRepository {
  final List<AiContentHistoryItem> _history = [
    AiContentHistoryItem(
      id: 'ai-gen-001',
      title: 'समाज मंदिर व ज्येष्ठ नागरिक विरंगुळा केंद्र लोकार्पण सोहळा',
      contentType: AiContentType.speech,
      tone: AiToneType.enthusiastic,
      language: AiLanguageType.marathi,
      generatedContent:
          'सन्माननीय व्यासपीठ, प्रभागातील वडीलधारे ज्येष्ठ नागरिक आणि माझ्या प्रिय बंधू-भगिनींनो,\n\n'
          'आजचा दिवस आपल्या संपूर्ण प्रभागासाठी अतिशय अभिमानाचा आणि आनंदाचा आहे! गेल्या अनेक महिन्यांपासून आपण ज्या समाज मंदिराची आणि ज्येष्ठ नागरिक विरंगुळा केंद्राची प्रतीक्षा करत होतो, त्या वास्तूचे लोकार्पण करताना मला अत्यंत समाधान वाटत आहे.\n\n'
          'आपल्या प्रभागातील ज्येष्ठांना शांततेत बसता यावे, वर्तमानपत्रे वाचता यावीत, आणि महिला भगिनींना विविध सामाजिक उपक्रम राबवता यावेत, हाच या केंद्रामागील मूळ उद्देश होता. महापालिकेकडून विशेष तरतूद मंजूर करून घेऊन आपण हे काम विहित मुदतीत पूर्ण केले आहे.\n\n'
          'मी नेहमी मानतो की राजकारण हे समाजकारणाचे साधन आहे, आणि प्रभागाचा सर्वांगीण विकास हेच माझे एकमेव ध्येय आहे. आपण सर्वांनी दाखवलेला विश्वास हीच माझी खरी ताकद आहे.\n\n'
          'या वास्तूचा लाभ सर्व नागरिकांनी घ्यावा ही नम्र विनंती.\n\n'
          'जय हिंद! जय महाराष्ट्र!\n'
          '- आपला नम्र सेवक, अमित चौगुले (नगरसेवक, प्रभाग क्र. १२)',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isFavorite: true,
    ),
    AiContentHistoryItem(
      id: 'ai-gen-002',
      title: 'प्रभाग १२ मधील मुख्य डीपी रस्त्याच्या डांबरीकरण कामाचा शुभारंभ',
      contentType: AiContentType.socialMediaCaption,
      tone: AiToneType.professional,
      language: AiLanguageType.marathi,
      generatedContent:
          '📢 **प्रभाग १२ विकास वार्ता : मुख्य डीपी रस्ता डांबरीकरण कामाचा शुभारंभ!** 🛣️✨\n\n'
          'नागरिकांच्या सुलभ व सुरक्षित प्रवासासाठी प्रभाग १२ मधील मुख्य डीपी रस्त्याच्या उच्च दर्जाच्या डांबरीकरण कामास आज प्रत्यक्ष सुरुवात झाली आहे. पावसाळ्यापूर्वी हे काम पूर्ण करण्याचे निर्देश संबंधित कंत्राटदार व मनपा अभियंत्यांना दिले आहेत. गुणवत्ता व वेळेची अचूकता राखण्यासाठी आम्ही स्वतः कामावर लक्ष ठेवून आहोत. 💪\n\n'
          'नागरिकांना प्रवासात होणाऱ्या तात्पुरत्या असुविधेबद्दल दिलगीर आहोत, सहकार्य करावे ही विनंती.\n\n'
          '#Ward12 #RoadDevelopment #PuneMunicipalCorporation #NagarSevak #AmitChougale #SmartWard #Infrastructure #PrabhagVikas',
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      isFavorite: true,
    ),
    AiContentHistoryItem(
      id: 'ai-gen-003',
      title: 'पाणीपुरवठा मुख्य जलवाहिनी तातडीची दुरुस्ती सूचना',
      contentType: AiContentType.letterNotice,
      tone: AiToneType.urgent,
      language: AiLanguageType.marathi,
      generatedContent:
          '**नागरिकांसाठी अत्यंत महत्त्वाची तातडीची जाहीर सूचना**\n\n'
          'विषय: प्रभाग १२ मधील मुख्य जलवाहिनी दुरुस्तीमुळे पाणीपुरवठा बंद राहण्याबाबत.\n\n'
          'प्रभाग क्र. १२ मधील सर्व सन्माननीय नागरिकांना कळविण्यात येते की, शिवाजी चौक परिसरातील मुख्य ८०० मिमी जलवाहिनीला अचानक मोठी गळती लागल्याने पुणे महानगरपालिका पाणीपुरवठा विभागामार्फत तातडीचे दुरुस्ती काम हाती घेण्यात आले आहे.\n\n'
          'यामुळे उद्या गुरुवार, सकाळी १०:०० ते संध्याकाळी ६:०० या वेळेत प्रभागातील पाणीपुरवठा बंद राहील. नागरिकांनी आजच पुरेसा पाणीसाठा करून ठेवावा.\n\n'
          'आवश्यकतेनुसार पिण्याच्या पाण्याचे टँकर उपलब्ध करून देण्यासाठी नगरसेवक जनसंपर्क कार्यालयाशी संपर्क साधावा.\n'
          '📞 जनसंपर्क हेल्पलाईन: ०२०-२५५०१२३४ / ९८२२००००००\n\n'
          'आपला नम्र,\n'
          'अमित चौगुले (नगरसेवक, प्रभाग १२)',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isFavorite: false,
    ),
    AiContentHistoryItem(
      id: 'ai-gen-004',
      title: 'प्रभाग विकासकामांसाठी महापालिकेकडून ₹२.५० कोटींचा विशेष निधी मंजूर',
      contentType: AiContentType.pressRelease,
      tone: AiToneType.formal,
      language: AiLanguageType.marathi,
      generatedContent:
          '**प्रेस नोट / प्रसिद्धी पत्रक**\n\n'
          'पुणे, दिनांक: काल\n'
          '**प्रभाग १२ मधील मूलभूत विकासकामांसाठी ₹२.५० कोटींचा विशेष निधी मंजूर : नगरसेवक अमित चौगुले**\n\n'
          'पुणे महानगरपालिकेच्या यंदाच्या वार्षिक अंदाजपत्रकात प्रभाग क्र. १२ मधील विविध प्रलंबित विकासकामांसाठी २ कोटी ५० लाख रुपयांचा विशेष विकास निधी मंजूर करण्यात आला असल्याची माहिती नगरसेवक अमित चौगुले यांनी पत्रकार परिषदेत दिली.\n\n'
          'या निधीमधून प्रभागातील अंतर्गत रस्त्यांचे काँक्रीटीकरण, नवीन भूमिगत पर्जन्यजल वाहिन्या, उद्यानांचे सुशोभीकरण, आणि महिला बचत गटांसाठी बहुउद्देशीय सभागृहाची उभारणी केली जाणार आहे. येत्या १५ दिवसांत सर्व कामांच्या निविदा प्रसिद्ध होणार असून प्रत्यक्ष कामाला गती दिली जाईल, असा विश्वास नगरसेवक चौगुले यांनी व्यक्त केला.\n\n'
          'प्रसिद्धीसाठी रवाना -\n'
          'नगरसेवक जनसंपर्क कार्यालय, प्रभाग १२, पुणे मनपा.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isFavorite: true,
    ),
    AiContentHistoryItem(
      id: 'ai-gen-005',
      title: 'शिवजयंती व युवा क्रीडा महोत्सव उद्घाटनपर अध्यक्षीय भाषण',
      contentType: AiContentType.speech,
      tone: AiToneType.enthusiastic,
      language: AiLanguageType.marathi,
      generatedContent:
          'प्रौढ प्रताप पुरंदर, क्षत्रिय कुलावतंस, सिंहासनाधीश्वर, महाराजाधिराज छत्रपती शिवाजी महाराज की जय!\n\n'
          'उपस्थित सर्व मान्यवर, क्रीडाप्रेमी आणि माझ्या तरुण युवा मित्रांनो,\n\n'
          'आज शिवजयंतीच्या पावन पर्वावर आयोजित भव्य प्रभाग क्रीडा महोत्सवाचे उद्घाटन करताना माझा ऊर अभिमानाने भरून आला आहे. छत्रपती शिवरायांचा इतिहास आपल्याला सांगतो की शरीर सुदृढ आणि मन कणखर असेल तर कोणतीही लढाई जिंकता येते.\n\n'
          'आपल्या प्रभागातील तरुणांना आंतरराष्ट्रीय दर्जाच्या क्रीडा सुविधा मिळाव्यात यासाठी आपण अद्ययावत खुली व्यायामशाळा व सिंथेटिक रनिंग ट्रॅक उभारला आहे. खेळाडू हा प्रभागाची शान असतो, आणि तुमच्या पाठीशी तुमचा हा सेवक सदैव खंबीरपणे उभा राहील!\n\n'
          'सर्व सहभागी खेळाडूंना मनःपूर्वक शुभेच्छा!\n\n'
          'जय भवानी, जय शिवाजी!',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isFavorite: false,
    ),
    AiContentHistoryItem(
      id: 'ai-gen-006',
      title: 'प्रभाग १२ अंतर्गत भूमिगत ड्रेनेज लाईन व चेंबर स्वच्छता पूर्ण कामाचा अहवाल',
      contentType: AiContentType.workReport,
      tone: AiToneType.formal,
      language: AiLanguageType.marathi,
      generatedContent:
          '**कामाचा संक्षिप्त अहवाल (Work Completion Report)**\n\n'
          'काम: प्रभाग १२ मधील मुख्य व अंतर्गत ड्रेनेज लाईन गाळ काढणे व नवीन चेंबर बसविणे.\n'
          'निधी: प्रभाग विकास निधी (मनपा २०२५-२६)\n'
          'स्थिती: १००% यशस्वीरित्या पूर्ण.\n\n'
          'अहवाल तपशील: पावसाळ्याच्या पार्श्वभूमीवर नागरिकांना सांडपाण्याचा त्रास होऊ नये या उद्देशाने प्रभागातील एकूण ४.५ किमी लांबीच्या ड्रेनेज लाईनची अत्याधुनिक सक्शन मशीनद्वारे स्वच्छता करण्यात आली आहे. तसेच खराब झालेले ४२ चेंबर्स नवीन सिमेंट काँक्रीट झाकणांसह बसविण्यात आले आहेत. यामुळे स्थानिक नागरिकांची अनेक महिन्यांची सांडपाण्याची समस्या मुळापासून सुटली आहे.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      isFavorite: false,
    ),
    AiContentHistoryItem(
      id: 'ai-gen-007',
      title: 'Smart CCTV Ward Surveillance & LED Streetlights Network',
      contentType: AiContentType.socialMediaCaption,
      tone: AiToneType.enthusiastic,
      language: AiLanguageType.english,
      generatedContent:
          '🔒 **Mission Safer Ward 12: 50+ Smart HD CCTV Cameras & 100% LED Streetlighting Completed!** 💡🏙️\n\n'
          'Women\'s safety, citizen security, and illuminated streets have always been our highest priority. We are proud to announce that the integrated round-the-clock surveillance network in Ward 12 is now fully operational with live police command integration.\n\n'
          'Together, let\'s build a safer, smarter, and greener neighborhood for every family. Your safety is our unwavering commitment! 🙌\n\n'
          '#Ward12Pune #WomenSafety #SmartSurveillance #SafeStreets #AmitChougale #PuneCorporation #CitizenFirst',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isFavorite: true,
    ),
    AiContentHistoryItem(
      id: 'ai-gen-008',
      title: 'मोफत महा-आरोग्य व मोफत चष्मा वाटप शिबिर जाहीर आवाहन',
      contentType: AiContentType.letterNotice,
      tone: AiToneType.emotional,
      language: AiLanguageType.marathi,
      generatedContent:
          '**आपल्या हक्काचे आरोग्य, आपल्याच दारी!**\n\n'
          'सन्माननीय माता-भगिनींनो, वडीलधाऱ्या ज्येष्ठ नागरिकांनो आणि प्रभागातील बांधवांनो,\n\n'
          'आरोग्य हीच खरी संपत्ती आहे. वाढत्या महागाईच्या काळात प्रत्येक कुटुंबाला मोफत आणि दर्जेदार आरोग्य सेवा मिळावी या तळमळीतून, आपल्या नगरसेवक जनसंपर्क कार्यालयातर्फे रविवार, दिनांक १० रोजी भव्य "मोफत महा-आरोग्य, नेत्रतपासणी व मोफत चष्मा वाटप शिबिराचे" आयोजन करण्यात आले आहे.\n\n'
          'पुण्यातील नामवंत तज्ज्ञ डॉक्टर्स या शिबिरात उपस्थित राहून ईसीजी, रक्तदाब, मधुमेह व डोळ्यांची तपासणी करणार आहेत. गरजूंना जागेवरच मोफत औषधे व चष्मे वाटप करण्यात येईल.\n\n'
          'नाते विश्वासाचे, काम विकासाचे! आपण सहकुटुंब या शिबिराचा अवश्य लाभ घ्यावा.\n\n'
          'स्थळ: समाज मंदिर सभागृह, प्रभाग १२, पुणे.\n'
          '- आपला नम्र, नगरसेवक अमित चौगुले',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      isFavorite: true,
    ),
  ];

  final List<AiPromptTemplate> _templates = const [
    AiPromptTemplate(
      id: 'tmpl-1',
      title: 'Inauguration Speech',
      titleMr: 'उद्घाटन भाषण',
      subtitle: 'समाज मंदिर, रस्ता, उद्यान उद्घाटनपर भाषण',
      prompt: 'प्रभाग १२ मधील नवीन समाज मंदिर व वाचनालय लोकार्पण सोहळा',
      defaultType: AiContentType.speech,
      defaultTone: AiToneType.enthusiastic,
      icon: Icons.record_voice_over_rounded,
    ),
    AiPromptTemplate(
      id: 'tmpl-2',
      title: 'Water Supply Notice',
      titleMr: 'पाणीपुरवठा दुरुस्ती नोटीस',
      subtitle: 'जलवाहिनी दुरुस्ती व टँकर सुविधेची जाहीर सूचना',
      prompt: 'मुख्य जलवाहिनी दुरुस्ती कामामुळे गुरुवारी पाणीपुरवठा बंद राहण्याबाबत',
      defaultType: AiContentType.letterNotice,
      defaultTone: AiToneType.urgent,
      icon: Icons.water_drop_rounded,
    ),
    AiPromptTemplate(
      id: 'tmpl-3',
      title: 'Road Concreting Post',
      titleMr: 'रस्ता काँक्रीटीकरण पोस्ट',
      subtitle: 'सोशल मीडियासाठी कामाचा शुभारंभ व प्रगती पोस्ट',
      prompt: 'प्रभागातील अंतर्गत रस्त्यांचे दर्जेदार सिमेंट काँक्रीटीकरण कामाचा शुभारंभ',
      defaultType: AiContentType.socialMediaCaption,
      defaultTone: AiToneType.professional,
      icon: Icons.add_road_rounded,
    ),
    AiPromptTemplate(
      id: 'tmpl-4',
      title: 'Health Camp Appeal',
      titleMr: 'आरोग्य शिबिर जाहीर आवाहन',
      subtitle: 'मोफत आरोग्य व नेत्रतपासणी शिबिर निमंत्रण पत्र',
      prompt: 'ज्येष्ठ नागरिक व महिलांसाठी मोफत महा-आरोग्य शिबिर आयोजन',
      defaultType: AiContentType.letterNotice,
      defaultTone: AiToneType.emotional,
      icon: Icons.medical_services_rounded,
    ),
    AiPromptTemplate(
      id: 'tmpl-5',
      title: 'Budget Allocation Press Note',
      titleMr: 'विकास निधी मंजुरी प्रसिद्धी पत्रक',
      subtitle: 'मनपा अर्थसंकल्पातून विकासकामांसाठी निधी मंजुरी',
      prompt: 'प्रभाग १२ च्या विकासकामांसाठी मनपाकडून ₹३.०० कोटी निधी मंजूर झाल्याची प्रेस नोट',
      defaultType: AiContentType.pressRelease,
      defaultTone: AiToneType.formal,
      icon: Icons.newspaper_rounded,
    ),
    AiPromptTemplate(
      id: 'tmpl-6',
      title: 'Festival Greetings',
      titleMr: 'सण व उत्सव सदिच्छा संदेश',
      subtitle: 'दिवाळी, गणेशोत्सव, शिवजयंती डिजिटल शुभेच्छा',
      prompt: 'प्रभागातील सर्व नागरिकांना गणेशोत्सव आणि अनंत चतुर्दशीच्या मंगलमय शुभेच्छा',
      defaultType: AiContentType.socialMediaCaption,
      defaultTone: AiToneType.enthusiastic,
      icon: Icons.celebration_rounded,
    ),
  ];

  List<AiPromptTemplate> getTemplates() => List.unmodifiable(_templates);

  Future<List<AiContentHistoryItem>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_history);
  }

  Future<AiContentHistoryItem> generateContent({
    required String topic,
    required AiContentType type,
    required AiToneType tone,
    required AiLanguageType language,
  }) async {
    // Simulate intelligent AI thinking and generation delay (1.2s)
    await Future.delayed(const Duration(milliseconds: 1200));

    final generatedText = _generateText(
      topic: topic,
      type: type,
      tone: tone,
      language: language,
    );

    final newItem = AiContentHistoryItem(
      id: 'ai-gen-${DateTime.now().millisecondsSinceEpoch}',
      title: topic.trim(),
      contentType: type,
      tone: tone,
      language: language,
      generatedContent: generatedText,
      createdAt: DateTime.now(),
      isFavorite: false,
    );

    _history.insert(0, newItem);
    return newItem;
  }

  Future<void> deleteHistoryItem(String id) async {
    _history.removeWhere((item) => item.id == id);
  }

  Future<bool> toggleFavorite(String id) async {
    final idx = _history.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final updated = _history[idx].copyWith(
        isFavorite: !_history[idx].isFavorite,
      );
      _history[idx] = updated;
      return updated.isFavorite;
    }
    return false;
  }

  String _generateText({
    required String topic,
    required AiContentType type,
    required AiToneType tone,
    required AiLanguageType language,
  }) {
    final cleanTopic = topic.trim();

    if (language == AiLanguageType.marathi) {
      switch (type) {
        case AiContentType.speech:
          return 'सन्माननीय व्यासपीठ, प्रभागातील आदरणीय नागरिक आणि माझ्या प्रिय बंधू-भगिनींनो,\n\n'
              'आज आपण एका अत्यंत महत्त्वाच्या प्रसंगी येथे उपस्थित राहिलो आहोत - \'$cleanTopic\'.\n\n'
              'आपल्या प्रभागाचा सर्वांगीण विकास आणि प्रत्येक नागरिकाचे जीवनमान उंचावणे हेच माझे प्रथम कर्तव्य आणि व्रत आहे. \'$cleanTopic\' या संकल्पनेच्या माध्यमातून आपण आपल्या प्रभागाच्या विकासाचा एक नवा अध्याय सुरू करत आहोत. विकासाची कामे करताना गुणवत्तेशी कोणतीही तडजोड केली जाणार नाही, अशी मी आपणांस ग्वाही देतो.\n\n'
              'आपण सर्वांनी आजवर दाखवलेला अतूट विश्वास आणि दिलेल्या प्रेमामुळेच मला काम करण्याची नवी ऊर्जा मिळते. हे कार्य यशस्वी करण्यासाठी आपले सहकार्य असेच पाठीशी राहील हा विश्वास आहे.\n\n'
              'जय हिंद! जय महाराष्ट्र!\n'
              '- आपला नम्र सेवक, अमित चौगुले (नगरसेवक, प्रभाग १२)';

        case AiContentType.socialMediaCaption:
          return '📢 **महत्त्वपूर्ण प्रभाग विकास वार्ता : $cleanTopic** ✨\n\n'
              'आज आपल्या प्रभागात \'$cleanTopic\' संदर्भात अत्यंत महत्त्वाचे पाऊल उचलण्यात आले आहे. नागरिकांना उत्तम पायाभूत सुविधा, सुरक्षितता आणि स्वच्छ परिसर उपलब्ध करून देण्यासाठी आम्ही अविरत कटिबद्ध आहोत. 💪\n\n'
              'आपल्या सूचना, अभिप्राय आणि सहकार्याचे सदैव स्वागत आहे. प्रभाग विकासाचा हा संकल्प आपण सर्वजण मिळून पूर्ण करूया!\n\n'
              '#Ward12 #PrabhagVikas #PuneMunicipalCorporation #AmitChougale #NagarSevak #CommunityFirst #Development #Pune';

        case AiContentType.pressRelease:
          return '📰 **प्रेस नोट / प्रसिद्धी पत्रक**\n\n'
              'पुणे, दिनांक: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\n'
              '**\'$cleanTopic\' बाबत नगरसेवक अमित चौगुले यांची महत्त्वपूर्ण घोषणा**\n\n'
              'पुणे महानगरपालिकेच्या प्रभाग क्र. १२ मध्ये \'$cleanTopic\' या महत्त्वाकांक्षी उपक्रमास वेग आला असून, यामुळे प्रभागातील हजारो नागरिकांना थेट लाभ होणार असल्याची माहिती स्थानिक नगरसेवक अमित चौगुले यांनी दिली आहे.\n\n'
              'सदर कामासाठी आवश्यक सर्व प्रशासकीय व तांत्रिक परवानग्या पूर्ण झाल्या असून मनपाच्या संबंधित विभागांना वेळेत व दर्जेदार काम पूर्ण करण्याचे सक्त आदेश देण्यात आले आहेत. प्रभागाचा सुनियोजित विकास साधणे हेच आमचे प्राधान्य राहिले आहे, असे नगरसेवकांनी नमूद केले.\n\n'
              'अधिक माहितीसाठी:\n'
              'नगरसेवक जनसंपर्क कार्यालय, प्रभाग १२, पुणे मनपा\n'
              'संपर्क: ०२०-२५५०१२३४';

        case AiContentType.letterNotice:
          return '📜 **जाहीर नोटीस / जाहीर पत्र**\n\n'
              'प्रति: प्रभागातील सर्व सन्माननीय नागरिक बंधू-भगिनी.\n'
              'विषय: \'$cleanTopic\' बाबत.\n\n'
              'तमाम नागरिकांना सूचित करण्यात येते की, आपल्या परिसरातील \'$cleanTopic\' या कामास प्रत्यक्ष सुरुवात करण्यात आली आहे. या कामाच्या कालावधीत नागरिकांना होणाऱ्या कोणत्याही संभाव्य असुविधेबद्दल आम्ही दिलगीर आहोत.\n\n'
              'हे काम भविष्यात आपल्या सर्वांसाठी दीर्घकालीन सोयीचे ठरणार आहे. नागरिकांनी सहकार्य करावे, तसेच कोणत्याही तातडीच्या अडचणीसाठी आमच्या जनसंपर्क कार्यालयाशी संपर्क साधावा.\n\n'
              'आपला नम्र,\n'
              'अमित चौगुले (नगरसेवक, प्रभाग क्र. १२)\n'
              'पुणे महानगरपालिका';

        case AiContentType.email:
          return 'विषय: \'$cleanTopic\' संदर्भातील अद्ययावत माहिती.\n\n'
              'सस्नेह नमस्कार,\n\n'
              'आपल्या विनंती आणि अर्जानुसार, आम्ही \'$cleanTopic\' या विषयावर तातडीने लक्ष केंद्रित केले आहे. संबंधित मनपा अधिकारी व अभियंत्यांशी चर्चा करून यावर आवश्यक कार्यवाही सुरू करण्यात आली आहे.\n\n'
              'याबाबतची पुढील प्रगती लवकरच आपणास कळविण्यात येईल. काही अडचण असल्यास आपण कार्यालयात थेट संपर्क करू शकता.\n\n'
              'धन्यवाद.\n\n'
              'आपला नम्र,\n'
              'अमित चौगुले (नगरसेवक, प्रभाग १२)';

        case AiContentType.workReport:
          return '📋 **प्रभाग विकास काम पूर्तता अहवाल (Work Report)**\n\n'
              'काम तपशील: \'$cleanTopic\'\n'
              'प्रभाग: प्रभाग क्र. १२, पुणे महानगरपालिका\n'
              'कामाची स्थिती: नियोजनानुसार यशस्वी अंमलबजावणी\n\n'
              'या विकासकामांतर्गत आम्ही \'$cleanTopic\' चे उद्दिष्ट साध्य केले आहे. कामाचा दर्जा व पारदर्शकता राखण्यासाठी नियमित क्षेत्रीय पाहणी करण्यात आली. यामुळे स्थानिक रहिवाशांची दीर्घकालीन अडचण दूर झाली असून प्रभागाच्या विकासात हे एक ठोस पाऊल सिद्ध झाले आहे.';
      }
    } else if (language == AiLanguageType.hindi) {
      switch (type) {
        case AiContentType.speech:
          return 'आदरणीय मंच, वार्ड के सभी सम्मानित नागरिक और मेरे प्रिय भाइयों और बहनों,\n\n'
              'आज हम सभी एक अत्यंत महत्वपूर्ण अवसर पर एकत्रित हुए हैं - \'$cleanTopic\'.\n\n'
              'हमारे वार्ड का समग्र विकास और हर नागरिक का कल्याण ही मेरा सर्वोच्च कर्तव्य है। \'$cleanTopic\' के माध्यम से हम अपने क्षेत्र में सकारात्मक बदलाव ला रहे हैं। गुणवत्ता और समयबद्धता के साथ यह कार्य संपन्न होगा।\n\n'
              'आपके अटूट विश्वास और सहयोग के लिए मैं दिल से आभारी हूँ।\n\n'
              'जय हिन्द! जय भारत!\n'
              '- आपका सेवक, अमित चौगुले (नगरसेवक, प्रभाग १२)';

        case AiContentType.socialMediaCaption:
          return '📢 **वार्ड विकास अपडेट: $cleanTopic** ✨\n\n'
              'आज हमारे वार्ड में \'$cleanTopic\' के संबंध में एक महत्वपूर्ण कार्य शुरू किया गया है। नागरिकों की सुविधा और सुरक्षा के लिए हम निरंतर प्रयासरत हैं। 💪\n\n'
              'आपके सुझाव और सहयोग का सदैव स्वागत है!\n\n'
              '#WardDevelopment #Pune #AmitChougale #NagarSevak #Community #Progress';

        default:
          return 'विषय: \'$cleanTopic\' के संबंध में सार्वजनिक सूचना.\n\n'
              'सभी सम्मानित नागरिकों को सूचित किया जाता है कि \'$cleanTopic\' का कार्य प्रगति पर है। किसी भी असुविधा के लिए हमें खेद है, सहयोग की अपेक्षा है।\n\n'
              'भवदीय,\n'
              'अमित चौगुले (नगरसेवक, वार्ड १२)';
      }
    } else {
      // English
      switch (type) {
        case AiContentType.speech:
          return 'Respected dignitaries on the dais, esteemed elders, and my dear citizens of Ward 12,\n\n'
              'It gives me immense pride and joy to address you today on this significant milestone: \'$cleanTopic\'.\n\n'
              'Public service is not just an office for me—it is a sacred pledge. Through \'$cleanTopic\', we are taking a definitive leap toward building a modern, inclusive, and thriving neighborhood. I assure every single resident that this work will be delivered with uncompromised quality and utmost transparency.\n\n'
              'Thank you for your relentless trust, guidance, and cooperation.\n\n'
              'Jai Hind! Jai Maharashtra!\n'
              '- Your Council Member, Amit Chougale (Ward 12)';

        case AiContentType.socialMediaCaption:
          return '📢 **Ward 12 Milestone Update: $cleanTopic** 🚀\n\n'
              'We are thrilled to announce that work regarding \'$cleanTopic\' is now officially in full swing across our ward! Delivering world-class infrastructure and peace of mind to our citizens remains our top priority. 💪\n\n'
              'Your constant support inspires us to serve better every single day. Let us keep moving Ward 12 forward together!\n\n'
              '#Ward12Pune #CommunityDevelopment #PuneMunicipalCorporation #AmitChougale #SmartWard #CitizenFirst';

        case AiContentType.pressRelease:
          return '📰 **PRESS RELEASE**\n\n'
              'Pune, Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\n'
              '**Major Milestone: \'$cleanTopic\' Announced for Ward 12 by Corporator Amit Chougale**\n\n'
              'In a dedicated effort to accelerate civic infrastructure, Corporator Amit Chougale today announced comprehensive implementation of \'$cleanTopic\' in Ward 12 under Pune Municipal Corporation.\n\n'
              'The initiative will directly benefit thousands of local residents and commuters. Administrative clearances have been fast-tracked to ensure completion within the stipulated timeline with strict adherence to civic standards.\n\n'
              'Issued by:\n'
              'Office of the Corporator, Ward 12, Pune Municipal Corporation\n'
              'Contact: 020-25501234';

        case AiContentType.letterNotice:
          return '📜 **PUBLIC NOTICE**\n\n'
              'Subject: Regarding \'$cleanTopic\' in Ward 12.\n\n'
              'This is to officially inform all residents that civic work regarding \'$cleanTopic\' has commenced. We sincerely regret any temporary inconvenience caused during the execution of this public work.\n\n'
              'This project will provide lasting benefits and improved civic amenities for everyone. For any emergency assistance or queries, please reach out to our Ward Public Liaison Office.\n\n'
              'Sincerely,\n'
              'Amit Chougale (Corporator, Ward 12)\n'
              'Pune Municipal Corporation';

        case AiContentType.email:
          return 'Subject: Status Update on \'$cleanTopic\'\n\n'
              'Dear Citizen,\n\n'
              'With reference to your representations regarding \'$cleanTopic\', we have taken up the matter on high priority with the municipal authorities. Necessary engineering steps are being expedited.\n\n'
              'We will keep you informed of further progress. Please feel free to contact my office for any further clarifications.\n\n'
              'Warm regards,\n\n'
              'Amit Chougale\n'
              'Corporator, Ward 12';

        case AiContentType.workReport:
          return '📋 **CIVIC WORK COMPLETION REPORT**\n\n'
              'Project Title: \'$cleanTopic\'\n'
              'Location: Ward 12, Pune Municipal Corporation\n'
              'Status: 100% Successfully Executed\n\n'
              'Under this initiative, we have successfully accomplished all scheduled milestones for \'$cleanTopic\'. On-site inspections have confirmed high construction standards and citizen satisfaction. This marks another fulfilled promise for the sustained growth of Ward 12.';
      }
    }
  }
}

final aiContentRepoProvider = Provider<AiContentRepository>((ref) {
  return AiContentRepository();
});

