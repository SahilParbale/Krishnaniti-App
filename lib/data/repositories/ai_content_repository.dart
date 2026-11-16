import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/ai_content_model.dart';

class AiContentRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

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
    try {
      var query = _client.from('ai_history').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((item) => AiContentHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AiContentHistoryItem> generateContent({
    required String topic,
    required AiContentType type,
    required AiToneType tone,
    required AiLanguageType language,
  }) async {
    final generatedText = _generateText(
      topic: topic,
      type: type,
      tone: tone,
      language: language,
    );

    final payload = {
      'title': topic.trim(),
      'content_type': type.id,
      'tone': tone.id,
      'language': language.id,
      'generated_content': generatedText,
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _client.from('ai_history').insert(payload).select().single();
      return AiContentHistoryItem.fromJson(res);
    } catch (_) {
      return AiContentHistoryItem(
        id: 'ai-gen-${DateTime.now().millisecondsSinceEpoch}',
        title: topic.trim(),
        contentType: type,
        tone: tone,
        language: language,
        generatedContent: generatedText,
        createdAt: DateTime.now(),
        isFavorite: false,
      );
    }
  }

  Future<void> deleteHistoryItem(String id) async {
    try {
      var query = _client.from('ai_history').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  Future<bool> toggleFavorite(String id) async {
    try {
      var query = _client.from('ai_history').select('is_favorite').eq('id', id).maybeSingle();
      final res = await query;
      final current = res != null && res['is_favorite'] == true;
      final newFav = !current;
      await _client.from('ai_history').update({'is_favorite': newFav}).eq('id', id);
      return newFav;
    } catch (_) {
      return false;
    }
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
          return 'सन्माननीय व्यासपीठ, प्रभागातील वडीलधारे ज्येष्ठ नागरिक आणि माझ्या प्रिय बंधू-भगिनींनो,\n\n'
              'आजचा दिवस आपल्या संपूर्ण प्रभागासाठी अतिशय महत्त्वाचा आहे - \'$cleanTopic\'.\n\n'
              'आपल्या प्रभागाचा सर्वांगीण विकास आणि प्रत्येक घटकाचे कल्याण हेच आमचे प्रथम कर्तव्य आहे. \'$cleanTopic\' च्या माध्यमातून आपण नागरिकांच्या जीवनमानात सकारात्मक बदल घडवून आणण्यासाठी कटिबद्ध आहोत. हे काम विहित मुदतीत आणि उत्कृष्ट दर्जाचे व्हावे यासाठी आम्ही वैयक्तिक लक्ष ठेवून आहोत.\n\n'
              'आपण दाखवलेला विश्वास आणि दिलेले सहकार्य हीच आमची ऊर्जा आहे. एकत्र येऊन आपण आपला प्रभाग अधिक सुंदर आणि समृद्ध करूया.\n\n'
              'जय हिंद! जय महाराष्ट्र!\n'
              '- आपला नम्र सेवक, नगरसेवक जनसंपर्क कार्यालय';

        case AiContentType.socialMediaCaption:
          return '📢 **प्रभाग १२ विकास वार्ता : $cleanTopic** 🌟\n\n'
              'प्रभाग १२ मधील नागरिकांच्या सुविधेसाठी आणि समस्यांच्या कायमस्वरूपी निराकरणासाठी \'$cleanTopic\' संदर्भात तातडीने कार्यवाही सुरू करण्यात आली आहे. विकासाचे हे पर्व अखंडपणे सुरू राहील. 💪✨\n\n'
              'आपल्या सूचना आणि सहकार्य सदैव मोलाचे आहे!\n\n'
              '#Ward12 #PrabhagVikas #PuneDevelopment #NagarSevak #CitizenFirst #SmartWard';

        case AiContentType.pressRelease:
          return '📰 **प्रेस नोट : \'$cleanTopic\' बाबत महत्त्वाची घोषणा**\n\n'
              'पुणे, विशेष प्रतिनिधी:\n'
              'प्रभाग १२ मधील जनहिताच्या दृष्टिकोनातून \'$cleanTopic\' या महत्त्वपूर्ण कामाला गती देण्यात आली असल्याची माहिती स्थानिक नगरसेवक जनसंपर्क कार्यालयामार्फत देण्यात आली.\n\n'
              'या कामामुळे स्थानिक परिसरातील हजारो नागरिकांना थेट लाभ होणार असून प्रशासकीय पातळीवर सर्व परवानग्या युद्धपातळीवर पूर्ण करून घेण्यात आल्या आहेत. कामाची गुणवत्ता आणि सुरक्षितता याबाबत कोणतीही तडजोड केली जाणार नाही, अशी ग्वाही यावेळी देण्यात आली.';

        case AiContentType.letterNotice:
          return '📜 **नागरिकांसाठी जाहीर सूचना**\n\n'
              'विषय: \'$cleanTopic\' बाबत.\n\n'
              'प्रभाग १२ मधील सर्व सन्माननीय नागरिकांना कळविण्यात येते की, प्रभागाच्या विकास नियोजनांतर्गत \'$cleanTopic\' चे काम हाती घेण्यात आले आहे. या कालावधीत नागरिकांना होणाऱ्या तात्पुरत्या असुविधेबद्दल दिलगीर आहोत.\n\n'
              'कोणत्याही आपत्कालीन मदतीसाठी किंवा तक्रारीसाठी नगरसेवक जनसंपर्क कार्यालयाशी संपर्क साधावा.\n\n'
              'आपला नम्र,\n'
              'नगरसेवक जनसंपर्क कार्यालय, प्रभाग १२';

        case AiContentType.email:
          return 'विषय: \'$cleanTopic\' संदर्भातील अद्ययावत माहिती.\n\n'
              'सस्नेह नमस्कार,\n\n'
              'आपल्या विनंती आणि अर्जानुसार, आम्ही \'$cleanTopic\' या विषयावर तातडीने लक्ष केंद्रित केले आहे. संबंधित मनपा अधिकारी व अभियंत्यांशी चर्चा करून यावर आवश्यक कार्यवाही सुरू करण्यात आली आहे.\n\n'
              'याबाबतची पुढील प्रगती लवकरच आपणास कळविण्यात येईल. काही अडचण असल्यास आपण कार्यालयात थेट संपर्क करू शकता.\n\n'
              'धन्यवाद.\n\n'
              'आपला नम्र,\n'
              'नगरसेवक जनसंपर्क कार्यालय, प्रभाग १२';

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
              '- आपका सेवक, नगरसेवक जनसंपर्क कार्यालय';

        case AiContentType.socialMediaCaption:
          return '📢 **वार्ड विकास अपडेट: $cleanTopic** ✨\n\n'
              'आज हमारे वार्ड में \'$cleanTopic\' के संबंध में एक महत्वपूर्ण कार्य शुरू किया गया है। नागरिकों की सुविधा और सुरक्षा के लिए हम निरंतर प्रयासरत हैं। 💪\n\n'
              'आपके सुझाव और सहयोग का सदैव स्वागत है!\n\n'
              '#WardDevelopment #Pune #NagarSevak #Community #Progress';

        default:
          return 'विषय: \'$cleanTopic\' के संबंध में सार्वजनिक सूचना.\n\n'
              'सभी सम्मानित नागरिकों को सूचित किया जाता है कि \'$cleanTopic\' का कार्य प्रगति पर है। किसी भी असुविधा के लिए हमें खेद है, सहयोग की अपेक्षा है।\n\n'
              'भवदीय,\n'
              'नगरसेवक कार्यालय';
      }
    } else {
      switch (type) {
        case AiContentType.speech:
          return 'Respected dignitaries on the dais, esteemed elders, and my dear citizens,\n\n'
              'It gives me immense pride and joy to address you today on this significant milestone: \'$cleanTopic\'.\n\n'
              'Public service is a sacred pledge. Through \'$cleanTopic\', we are taking a definitive leap toward building a modern, inclusive, and thriving neighborhood. I assure every single resident that this work will be delivered with uncompromised quality and utmost transparency.\n\n'
              'Thank you for your relentless trust, guidance, and cooperation.\n\n'
              '- Corporator Public Liaison Office';

        case AiContentType.socialMediaCaption:
          return '📢 **Ward Milestone Update: $cleanTopic** 🚀\n\n'
              'We are thrilled to announce that work regarding \'$cleanTopic\' is now officially in full swing across our ward! Delivering world-class infrastructure and peace of mind to our citizens remains our top priority. 💪\n\n'
              '#Ward12Pune #CommunityDevelopment #PuneMunicipalCorporation #SmartWard #CitizenFirst';

        case AiContentType.pressRelease:
          return '📰 **PRESS RELEASE**\n\n'
              'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\n'
              '**Major Milestone: \'$cleanTopic\' Announced by Corporator Public Liaison Office**\n\n'
              'In a dedicated effort to accelerate civic infrastructure, comprehensive implementation of \'$cleanTopic\' has been fast-tracked to ensure completion within the stipulated timeline with strict adherence to civic standards.\n\n'
              'Issued by:\n'
              'Office of the Corporator, Ward 12';

        case AiContentType.letterNotice:
          return '📜 **PUBLIC NOTICE**\n\n'
              'Subject: Regarding \'$cleanTopic\'.\n\n'
              'This is to officially inform all residents that civic work regarding \'$cleanTopic\' has commenced. We sincerely regret any temporary inconvenience caused during the execution of this public work.\n\n'
              'Sincerely,\n'
              'Office of the Corporator, Ward 12';

        case AiContentType.email:
          return 'Subject: Status Update on \'$cleanTopic\'\n\n'
              'Dear Citizen,\n\n'
              'With reference to your representations regarding \'$cleanTopic\', we have taken up the matter on high priority with the municipal authorities.\n\n'
              'Warm regards,\n\n'
              'Corporator Public Liaison Office';

        case AiContentType.workReport:
          return '📋 **CIVIC WORK COMPLETION REPORT**\n\n'
              'Project Title: \'$cleanTopic\'\n'
              'Status: 100% Successfully Executed\n\n'
              'Under this initiative, we have successfully accomplished all scheduled milestones for \'$cleanTopic\'. On-site inspections have confirmed high construction standards and citizen satisfaction.';
      }
    }
  }
}

final aiContentRepoProvider = Provider<AiContentRepository>((ref) {
  return AiContentRepository();
});
