import 'app_translations_data.dart';

/// Comprehensive 3-language translation dictionary matching Nagarsevak-Managment
/// Supports: 'en' (English), 'mr' (Marathi), 'hi' (Hindi)
class AppTranslations {
  AppTranslations._();

  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'mr', 'hi'];

  static const Map<String, dynamic> _translations = kAppTranslationsData;

  /// Custom overrides matching Nagarsevak-Managment CUSTOM_TRANSLATIONS
  static const Map<String, Map<String, String>> customOverrides = {
    'mr': {
      'Dhankawadi': 'धनकवडी',
      'Dhankwadi': 'धनकवडी',
      'Bibwewadi': 'बिबवेवाडी',
      'Katraj': 'कात्रज',
      'Sahakar Nagar': 'सहकार नगर',
      'Padmavati': 'पद्मावती',
      'Balaji Nagar': 'बालाजी नगर',
      'Parvati': 'पार्वती',
      'Pune': 'पुणे',
      'Maharashtra': 'महाराष्ट्र',
      'Lokmanya Nagar': 'लोकमान्य नगर',
      'Lokamanya Nagar': 'लोकमान्य नगर',
      'Lokmanya': 'लोकमान्य',
      'Nagar': 'नगर',
      'Community Engagement & Welfare Scheme Awareness': 'सामुदायिक सहभाग आणि कल्याणकारी योजना जनजागृती',
      'Monitoring Cleanliness & Sanitation Drive': 'स्वच्छता मोहीम आणि देखरेख',
      'Coordination with Municipal Officials': 'पालिका अधिकाऱ्यांशी समन्वय',
      'Residence Certificate': 'रहिवासी दाखला',
      'School Admission Recommendation': 'शालेय/महाविद्यालयीन प्रवेशासाठी शिफारस पत्र',
      'Job Recommendation Letter': 'नोकरीसाठी शिफारस पत्र',
      'Character & Identity Certificate': 'चारित्र्य व ओळखीचे प्रमाणपत्र',
      'Death Certificate Request': 'मृत्यू दाखला मिळण्याबाबत शिफारस',
      'Gas Connection Recommendation': 'नवीन गॅस कनेक्शन मिळण्यासाठी शिफारस पत्र',
      'Income Certificate Recommendation': 'उत्पन्नाचा दाखला मिळण्याबाबत शिफारस',
      'New Electricity Meter Recommendation': 'नवीन वीज मीटर मिळण्यासाठी शिफारस पत्र',
      'Police Verification Certificate': 'पोलीस पडताळणी प्रमाणपत्र',
      'Hospital Admission Recommendation': 'रुग्णालय प्रवेश शिफारस',
      'Financial Assistance Request (Medical)': 'आर्थिक मदत विनंती (वैद्यकीय)',
      'Character Certificate': 'चारित्र्य प्रमाणपत्र',
      'Water Connection Request': 'पाणी कनेक्शन विनंती',
      'Electricity Connection Request': 'वीज कनेक्शन विनंती',
      'Street Light Repair Request': 'पथदिवे दुरुस्ती विनंती',
      'Road Repair Request': 'रस्ते दुरुस्ती विनंती',
      'Drainage Cleaning/Repair Request': 'ड्रेनेज स्वच्छता/दुरुस्ती विनंती',
      'Garbage Collection Complaint': 'कचरा संकलन तक्रार',
      'Public Garden Maintenance': 'सार्वजनिक उद्यान देखभाल',
      'Community Hall Booking Request': 'समाज मंदिर बुकिंग विनंती',
      'Transfer of Property Tax Name': 'मालमत्ता कर नाव हस्तांतरण',
      'Birth Certificate Issue': 'जन्म प्रमाणपत्र',
      'Death Certificate Issue': 'मृत्यू प्रमाणपत्र',
      'Marriage Certificate Issue': 'विवाह प्रमाणपत्र',
      'Senior Citizen Card Recommendation': 'ज्येष्ठ नागरिक ओळखपत्र शिफारस',
      'Ration Card Name Addition/Deletion': 'शिधापत्रिकेत नाव समाविष्ट/कमी करणे',
      'Caste Certificate Recommendation': 'जात प्रमाणपत्र शिफारस',
      'Non-Creamy Layer Certificate Recommendation': 'नॉन-क्रीमी लेयर प्रमाणपत्र शिफारस',
      'Domicile Certificate Recommendation': 'अधिवास प्रमाणपत्र शिफारस',
      'EWS Certificate Recommendation': 'EWS प्रमाणपत्र शिफारस',
      'Waste Management': 'कचरा व्यवस्थापन',
      'Street Lighting': 'पथदिवे',
      'Water Distribution': 'पाणी पुरवठा',
      'Public Health': 'सार्वजनिक आरोग्य',
      'Road Construction': 'रस्ते बांधकाम',
      'Administration': 'प्रशासन',
      'Pending': 'प्रलंबित',
      'In Progress': 'काम चालू',
      'Resolved': 'सोडवलेले',
      'Closed': 'बंद',
      'Assigned': 'सोपवलेले',
      'Total': 'एकूण',
      'All': 'सर्व',
      'All Areas': 'सर्व भाग',
      'Filter by Area': 'भाग निवडा',
      'Filter by Status': 'स्थिती निवडा',
      'Download Report': 'अहवाल डाउनलोड करा',
      'Download PDF Report': 'अहवाल डाउनलोड करा',
      'Export PDF': 'पीडीएफ निर्यात',
      'Actions': 'कृती',
      'Save': 'जतन करा',
      'Cancel': 'रद्द करा',
      'Delete': 'हटवा',
      'Edit': 'संपादित करा',
      'View': 'पहा',
      'Search': 'शोधा',
      'Date': 'दिनांक',
      'Status': 'स्थिती',
      'Name': 'नाव',
      'Mobile': 'मोबाईल',
      'Category': 'वर्गवारी',
      'Area': 'परिसर / भाग',
      'Ward': 'प्रभाग',
      'Description': 'वर्णन',
      'Amount': 'रक्कम',
      'Priority': 'प्राधान्य',
      'Urgent': 'तातडीचे',
      'High': 'उच्च',
      'Medium': 'मध्यम',
      'Low': 'कमी',
    },
    'hi': {
      'Dhankawadi': 'धनकवडी',
      'Dhankwadi': 'धनकवडी',
      'Bibwewadi': 'बिबवेवाडी',
      'Katraj': 'कात्रज',
      'Sahakar Nagar': 'सहकार नगर',
      'Padmavati': 'पद्मावती',
      'Balaji Nagar': 'बालाजी नगर',
      'Parvati': 'पार्वती',
      'Pune': 'पुणे',
      'Maharashtra': 'महाराष्ट्र',
      'Lokmanya Nagar': 'लोकमान्य नगर',
      'Lokamanya Nagar': 'लोकमान्य नगर',
      'Lokmanya': 'लोकमान्य',
      'Nagar': 'नगर',
      'Community Engagement & Welfare Scheme Awareness': 'सामुदायिक सहभाग एवं कल्याणकारी योजना जागरूकता',
      'Monitoring Cleanliness & Sanitation Drive': 'स्वच्छता अभियान एवं निगरानी',
      'Coordination with Municipal Officials': 'नगर निगम अधिकारियों से समन्वय',
      'Residence Certificate': 'निवास प्रमाण पत्र',
      'School Admission Recommendation': 'स्कूल/कॉलेज प्रवेश सिफारिश पत्र',
      'Job Recommendation Letter': 'नौकरी के लिए सिफारिश पत्र',
      'Character & Identity Certificate': 'चरित्र एवं पहचान प्रमाण पत्र',
      'Death Certificate Request': 'मृत्यु प्रमाण पत्र अनुरोध',
      'Gas Connection Recommendation': 'गैस कनेक्शन सिफारिश पत्र',
      'Income Certificate Recommendation': 'आय प्रमाण पत्र सिफारिश',
      'New Electricity Meter Recommendation': 'नए बिजली मीटर की सिफारिश',
      'Police Verification Certificate': 'पुलिस सत्यापन प्रमाण पत्र',
      'Hospital Admission Recommendation': 'अस्पताल प्रवेश सिफारिश',
      'Financial Assistance Request (Medical)': 'वित्तीय सहायता अनुरोध (चिकित्सा)',
      'Character Certificate': 'चरित्र प्रमाण पत्र',
      'Water Connection Request': 'जल कनेक्शन अनुरोध',
      'Electricity Connection Request': 'बिजली कनेक्शन अनुरोध',
      'Street Light Repair Request': 'स्ट्रीट लाइट मरम्मत अनुरोध',
      'Road Repair Request': 'सड़क मरम्मत अनुरोध',
      'Drainage Cleaning/Repair Request': 'ड्रेनेज सफाई/मरम्मत अनुरोध',
      'Garbage Collection Complaint': 'कचरा संग्रहण शिकायत',
      'Public Garden Maintenance': 'सार्वजनिक उद्यान रखरखाव',
      'Community Hall Booking Request': 'सामुदायिक भवन बुकिंग अनुरोध',
      'Transfer of Property Tax Name': 'संपत्ति कर नाम स्थानांतरण',
      'Birth Certificate Issue': 'जन्म प्रमाण पत्र',
      'Death Certificate Issue': 'मृत्यु प्रमाण पत्र',
      'Marriage Certificate Issue': 'विवाह प्रमाण पत्र',
      'Senior Citizen Card Recommendation': 'वरिष्ठ नागरिक कार्ड सिफारिश',
      'Ration Card Name Addition/Deletion': 'राशन कार्ड में नाम जोड़ना/हटाना',
      'Caste Certificate Recommendation': 'जाति प्रमाण पत्र सिफारिश',
      'Non-Creamy Layer Certificate Recommendation': 'नॉन-क्रीमी लेयर प्रमाण पत्र सिफारिश',
      'Domicile Certificate Recommendation': 'अधिवास प्रमाण पत्र सिफारिश',
      'EWS Certificate Recommendation': 'EWS प्रमाण पत्र सिफारिश',
      'Waste Management': 'कचरा प्रबंधन',
      'Street Lighting': 'स्ट्रीट लाइट',
      'Water Distribution': 'जल वितरण',
      'Public Health': 'सार्वजनिक स्वास्थ्य',
      'Road Construction': 'सड़क निर्माण',
      'Administration': 'प्रशासन',
      'Pending': 'लंबित',
      'In Progress': 'प्रगति पर',
      'Resolved': 'समाधान हुआ',
      'Closed': 'बंद',
      'Assigned': 'सौंपा गया',
      'Total': 'कुल',
      'All': 'सभी',
      'All Areas': 'सभी क्षेत्र',
      'Filter by Area': 'क्षेत्र चुनें',
      'Filter by Status': 'स्थिति चुनें',
      'Download Report': 'रिपोर्ट डाउनलोड करें',
      'Download PDF Report': 'रिपोर्ट डाउनलोड करें',
      'Export PDF': 'पीडीएफ निर्यात',
      'Actions': 'कार्रवाई',
      'Save': 'सहेजें',
      'Cancel': 'रद्द करें',
      'Delete': 'हटाएं',
      'Edit': 'संपादित करें',
      'View': 'देखें',
      'Search': 'खोजें',
      'Date': 'दिनांक',
      'Status': 'स्थिति',
      'Name': 'नाम',
      'Mobile': 'मोबाइल',
      'Category': 'श्रेणी',
      'Area': 'क्षेत्र',
      'Ward': 'वार्ड',
      'Description': 'विवरण',
      'Amount': 'राशि',
      'Priority': 'प्राथमिकता',
      'Urgent': 'अति आवश्यक',
      'High': 'उच्च',
      'Medium': 'मध्यम',
      'Low': 'कम',
    },
  };

  /// Core lookup function: supports dot-notation like 'common.welcome'
  static String t(String key, {String? lang, Map<String, dynamic>? params}) {
    final language = (lang != null && supportedLanguages.contains(lang)) ? lang : defaultLanguage;
    final keys = key.split('.');

    dynamic current = _translations[language];
    bool found = true;

    for (final k in keys) {
      if (current is Map && current.containsKey(k)) {
        current = current[k];
      } else {
        found = false;
        break;
      }
    }

    // Fallback to English if not found
    if (!found || current is! String) {
      current = _translations['en'];
      for (final k in keys) {
        if (current is Map && current.containsKey(k)) {
          current = current[k];
        } else {
          return key;
        }
      }
    }

    var result = current?.toString() ?? key;

    // Interpolate params e.g. {{name}} or {name}
    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramValue) {
        result = result
            .replaceAll('{{$paramKey}}', paramValue.toString())
            .replaceAll('{$paramKey}', paramValue.toString());
      });
    }

    return result;
  }

  /// Complete navigation titles in Marathi for all 39 screens + 7 module groups
  static const Map<String, String> _navTitlesMr = {
    'dashboard': 'डॅशबोर्ड',
    'overview': 'डॅशबोर्ड',
    'daily_work': 'रोजचे कामकाज',
    'complaints': 'तक्रारी आणि विनंती',
    'letters': 'पत्र व्यवहार - आवक - जावक',
    'diary': 'कार्य नियोजन (दैनंदिनी)',
    'tasks': 'कार्य नियोजन (दैनंदिनी)',
    'task_management': 'कार्य नियोजन',
    'visitors': 'भेट देणारे (व्हिजिटर लॉग)',
    'visitor_log': 'भेट देणारे (व्हिजिटर लॉग)',
    'schemes': 'सरकारी योजना',
    'govt_schemes': 'सरकारी योजना',
    'government_schemes': 'सरकारी योजना',
    'ward_info': 'प्रभाग माहिती',
    'ward_problems': 'प्रभाग समस्या',
    'ward_problem': 'प्रभाग समस्या',
    'ward_map': 'प्रभाग नकाशा',
    'work_history': 'विकासाची केलेली कामे',
    'works': 'विकासाची केलेली कामे',
    'improvements': 'संभाव्य सुधारणा',
    'ward_improvement': 'संभाव्य सुधारणा',
    'ward_improvements': 'संभाव्य सुधारणा',
    'provisions': 'प्रभागनिहाय तरतूद',
    'ward_provision': 'प्रभागनिहाय तरतूद',
    'ward_provisions': 'प्रभागनिहाय तरतूद',
    'municipal': 'मनपा कामकाज',
    'municipal_work': 'मनपा कामकाज',
    'gb_register': 'जीबी रजिस्टर',
    'ward_budget': 'प्रभाग अंदाजपत्रक',
    'budget': 'प्रभाग अंदाजपत्रक',
    'gov_office': 'शासकीय कार्यालय',
    'government_office': 'शासकीय कार्यालय',
    'media': 'प्रसिद्धी आणि जाहिरात',
    'media_promotion': 'प्रसिद्धी आणि जाहिरात',
    'social_analytics': 'सोशल मीडिया विश्लेषण',
    'social': 'सोशल मीडिया विश्लेषण',
    'newspaper': 'वृत्तपत्र कात्रणे',
    'newspaper_clipping': 'वृत्तपत्र कात्रणे',
    'newspaper_clippings': 'वृत्तपत्र कात्रणे',
    'media_tracking': 'माध्यम मागोवा',
    'ai_content': 'AI कंटेंट स्टुडिओ',
    'programs': 'कार्यक्रम आणि उपक्रम',
    'programs_activities': 'कार्यक्रम आणि उपक्रम',
    'events': 'कार्यक्रम आणि आमंत्रणे',
    'events_invites': 'कार्यक्रम आणि आमंत्रणे',
    'gallery': 'गॅलरी आणि फोटो',
    'gallery_media': 'गॅलरी आणि फोटो',
    'political': 'राजकीय व निवडणूक',
    'result_analysis': 'निवडणूक निकाल विश्लेषण',
    'results': 'निवडणूक निकाल विश्लेषण',
    'sadasya': 'सदस्य नोंदणी',
    'surveys': 'नमुना सर्वेक्षणे',
    'sample_surveys': 'नमुना सर्वेक्षणे',
    'voters': 'मतदार शोध',
    'voter_search': 'मतदार शोध',
    'team': 'माझी टीम',
    'my_team': 'माझी टीम',
    'opposition': 'विरोधी पक्षाची माहिती',
    'opposition_info': 'विरोधी पक्षाची माहिती',
    'ngo_mandals': 'NGO व मंडळ माहिती',
    'social_organizations': 'NGO व मंडळ माहिती',
    'housing_societies': 'सोसायटी चेअरमन व मतदार',
    'duplicate_voters': 'दुसरे मतदार (ड्युप्लिकेट)',
    'voter_forms': 'मतदार अर्ज',
    'karyakarta_work': 'कार्यकर्ता काम व्यवस्थापन',
    'public_comm': 'जनसंवाद',
    'public_communication': 'जनसंवाद',
    'communication': 'जनसंवाद',
    'sms': 'SMS पाठवा',
    'send_sms': 'SMS पाठवा',
    'whatsapp_message': 'व्हॉट्सॲप संदेश',
    'whatsapp_msg': 'व्हॉट्सॲप संदेश',
    'whatsapp': 'व्हॉट्सॲप',
    'voice_call': 'व्हॉइस कॉल',
    'ai_voice_call': 'AI व्हॉइस कॉल',
    'conference_room': 'कॉन्फरन्स रूम',
    'whatsapp_call': 'व्हॉट्सॲप कॉल',
    'analysis_strategy': 'विश्लेषण व रणनीती',
    'analysis': 'विश्लेषण व रणनीती',
    'profile_settings': 'प्रोफाईल आणि सेटिंग्ज',
    'profile': 'प्रोफाईल',
    'bar_customization': 'मेनू सानुकूलन',
    'settings': 'सेटिंग्ज',
  };

  /// Complete navigation titles in Hindi for all 39 screens + 7 module groups
  static const Map<String, String> _navTitlesHi = {
    'dashboard': 'डैशबोर्ड',
    'overview': 'डैशबोर्ड',
    'daily_work': 'दैनिक कार्य',
    'complaints': 'शिकायतें और अनुरोध',
    'letters': 'पत्र व्यवहार - आवक - जावक',
    'diary': 'कार्य प्रबंधन (दैनंदिनी)',
    'tasks': 'कार्य प्रबंधन (दैनंदिनी)',
    'task_management': 'कार्य प्रबंधन',
    'visitors': 'आगंतुक लॉग',
    'visitor_log': 'आगंतुक लॉग',
    'schemes': 'सरकारी योजनाएं',
    'govt_schemes': 'सरकारी योजनाएं',
    'government_schemes': 'सरकारी योजनाएं',
    'ward_info': 'वार्ड जानकारी',
    'ward_problems': 'वार्ड की समस्याएं',
    'ward_problem': 'वार्ड की समस्याएं',
    'ward_map': 'वार्ड नक्शा',
    'work_history': 'विकास कार्य इतिहास',
    'works': 'विकास कार्य इतिहास',
    'improvements': 'सुधार के सुझाव',
    'ward_improvement': 'सुधार के सुझाव',
    'ward_improvements': 'सुधार के सुझाव',
    'provisions': 'वार्ड वार प्रावधान',
    'ward_provision': 'वार्ड वार प्रावधान',
    'ward_provisions': 'वार्ड वार प्रावधान',
    'municipal': 'नगरपालिका कार्य',
    'municipal_work': 'नगरपालिका कार्य',
    'gb_register': 'जीबी रजिस्टर',
    'ward_budget': 'वार्ड बजट',
    'budget': 'वार्ड बजट',
    'gov_office': 'शासकीय कार्यालय',
    'government_office': 'शासकीय कार्यालय',
    'media': 'डिजिटल और मीडिया',
    'media_promotion': 'डिजिटल और मीडिया',
    'social_analytics': 'सोशल मीडिया विश्लेषण',
    'social': 'सोशल मीडिया विश्लेषण',
    'newspaper': 'समाचार पत्र कतरनें',
    'newspaper_clipping': 'समाचार पत्र कतरनें',
    'newspaper_clippings': 'समाचार पत्र कतरनें',
    'media_tracking': 'मीडिया ट्रैकिंग',
    'ai_content': 'AI कंटेंट स्टूडियो',
    'programs': 'कार्यक्रम और गतिविधियां',
    'programs_activities': 'कार्यक्रम और गतिविधियां',
    'events': 'कार्यक्रम और निमंत्रण',
    'events_invites': 'कार्यक्रम और निमंत्रण',
    'gallery': 'गैलरी और मीडिया',
    'gallery_media': 'गैलरी और मीडिया',
    'political': 'राजनीतिक और चुनावी',
    'result_analysis': 'चुनाव परिणाम विश्लेषण',
    'results': 'चुनाव परिणाम विश्लेषण',
    'sadasya': 'सदस्य पंजीकरण',
    'surveys': 'नमूना सर्वेक्षण',
    'sample_surveys': 'नमूना सर्वेक्षण',
    'voters': 'मतदाता खोज',
    'voter_search': 'मतदाता खोज',
    'team': 'मेरी टीम',
    'my_team': 'मेरी टीम',
    'opposition': 'विपक्ष की जानकारी',
    'opposition_info': 'विपक्ष की जानकारी',
    'ngo_mandals': 'एनजीओ और मंडल जानकारी',
    'social_organizations': 'एनजीओ और मंडल जानकारी',
    'housing_societies': 'हाउसिंग सोसायटियां',
    'duplicate_voters': 'डुप्लीकेट मतदाता',
    'voter_forms': 'मतदाता प्रपत्र',
    'karyakarta_work': 'कार्यकर्ता कार्य प्रबंधन',
    'public_comm': 'जनसंचार',
    'public_communication': 'जनसंचार',
    'communication': 'जनसंचार',
    'sms': 'एसएमएस भेजें',
    'send_sms': 'एसएमएस भेजें',
    'whatsapp_message': 'व्हाट्सएप संदेश',
    'whatsapp_msg': 'व्हाट्सएप संदेश',
    'whatsapp': 'व्हाट्सएप',
    'voice_call': 'वॉयस कॉल',
    'ai_voice_call': 'एआई वॉयस कॉल',
    'conference_room': 'कॉन्फ्रेंस रूम',
    'whatsapp_call': 'व्हाट्सएप कॉल',
    'analysis_strategy': 'विश्लेषण और रणनीति',
    'analysis': 'विश्लेषण और रणनीति',
    'profile_settings': 'प्रोफाइल और सेटिंग्स',
    'profile': 'प्रोफाइल',
    'bar_customization': 'मेनू अनुकूलन',
    'settings': 'सेटिंग्स',
  };

  /// Complete English navigation labels
  static const Map<String, String> _navTitlesEn = {
    'dashboard': 'Dashboard',
    'overview': 'Dashboard',
    'daily_work': 'Daily Work',
    'complaints': 'Requests & Complaints',
    'letters': 'Letters',
    'diary': 'Task Management',
    'tasks': 'Task Management',
    'task_management': 'Task Management',
    'visitors': 'Visitor Log',
    'visitor_log': 'Visitor Log',
    'schemes': 'Govt Schemes',
    'govt_schemes': 'Govt Schemes',
    'government_schemes': 'Govt Schemes',
    'ward_info': 'Ward Information',
    'ward_problems': 'Ward Problems',
    'ward_problem': 'Ward Problems',
    'ward_map': 'Ward Map',
    'work_history': 'Work History',
    'works': 'Work History',
    'improvements': 'Possible Improvements',
    'ward_improvement': 'Possible Improvements',
    'ward_improvements': 'Possible Improvements',
    'provisions': 'Ward Wise Provision',
    'ward_provision': 'Ward Wise Provision',
    'ward_provisions': 'Ward Wise Provision',
    'municipal': 'Municipal Work',
    'municipal_work': 'Municipal Work',
    'gb_register': 'GB Register',
    'ward_budget': 'Ward Budget',
    'budget': 'Ward Budget',
    'gov_office': 'Government Office',
    'government_office': 'Government Office',
    'media': 'Media & Promotion',
    'media_promotion': 'Media & Promotion',
    'social_analytics': 'Social Analytics',
    'social': 'Social Analytics',
    'newspaper': 'Newspaper Clipping',
    'newspaper_clipping': 'Newspaper Clipping',
    'newspaper_clippings': 'Newspaper Clipping',
    'media_tracking': 'Media Tracking',
    'ai_content': 'AI Content Studio',
    'programs': 'Programs & Activities',
    'programs_activities': 'Programs & Activities',
    'events': 'Events & Invites',
    'events_invites': 'Events & Invites',
    'gallery': 'Gallery & Media',
    'gallery_media': 'Gallery & Media',
    'political': 'Political',
    'result_analysis': 'Result Analysis',
    'results': 'Result Analysis',
    'sadasya': 'Sadasya (Members)',
    'surveys': 'Sample Surveys',
    'sample_surveys': 'Sample Surveys',
    'voters': 'Voter Search',
    'voter_search': 'Voter Search',
    'team': 'My Team',
    'my_team': 'My Team',
    'opposition': 'Opposition Info',
    'opposition_info': 'Opposition Info',
    'ngo_mandals': 'NGO & Mandals Info',
    'social_organizations': 'NGO & Mandals Info',
    'housing_societies': 'Housing Societies',
    'duplicate_voters': 'Duplicate Voters',
    'voter_forms': 'Voter Forms',
    'karyakarta_work': 'Karyakarta Work Management',
    'public_comm': 'Public Communication',
    'public_communication': 'Public Communication',
    'communication': 'Public Communication',
    'sms': 'Send SMS',
    'send_sms': 'Send SMS',
    'whatsapp_message': 'WhatsApp Message',
    'whatsapp_msg': 'WhatsApp Message',
    'whatsapp': 'WhatsApp',
    'voice_call': 'Voice Call',
    'ai_voice_call': 'AI Voice Call',
    'conference_room': 'Conference Room',
    'whatsapp_call': 'WhatsApp Call',
    'analysis_strategy': 'Analysis & Strategy',
    'analysis': 'Analysis & Strategy',
    'profile_settings': 'Profile & Settings',
    'profile': 'Profile',
    'bar_customization': 'Bar Customization',
    'settings': 'Settings',
  };

  /// Instant synchronous translation lookup for any English, Marathi, or Hindi word, phrase or dot-key
  static String? tr(String text, {String? lang}) {
    final language = (lang != null && supportedLanguages.contains(lang)) ? lang : defaultLanguage;
    if (text.trim().isEmpty) return text;

    final trimmed = text.trim();
    final lower = trimmed.toLowerCase();

    // If English requested: check if text was originally Marathi or Hindi
    if (language == 'en') {
      if (kAppCrossMrToEn.containsKey(lower)) {
        final enVal = kAppCrossMrToEn[lower]!;
        return enVal.isNotEmpty ? '${enVal[0].toUpperCase()}${enVal.substring(1)}' : enVal;
      }
      if (kAppCrossHiToEn.containsKey(lower)) {
        final enVal = kAppCrossHiToEn[lower]!;
        return enVal.isNotEmpty ? '${enVal[0].toUpperCase()}${enVal.substring(1)}' : enVal;
      }
      return text;
    }

    // 1. Check dot-key if contains dot
    if (trimmed.contains('.')) {
      final res = t(trimmed, lang: language);
      if (res != trimmed) return res;
    }

    // 2. Check dedicated navigation titles first if applicable
    final keyCandidate = lower.replaceAll(' ', '_').replaceAll('&', '').replaceAll('-', '_');
    if (language == 'mr') {
      if (_navTitlesMr.containsKey(lower)) return _navTitlesMr[lower];
      if (_navTitlesMr.containsKey(keyCandidate)) return _navTitlesMr[keyCandidate];
    } else if (language == 'hi') {
      if (_navTitlesHi.containsKey(lower)) return _navTitlesHi[lower];
      if (_navTitlesHi.containsKey(keyCandidate)) return _navTitlesHi[keyCandidate];
    }

    // 3. Check custom overrides (exact and case-insensitive)
    final overrides = customOverrides[language];
    if (overrides != null) {
      if (overrides.containsKey(trimmed)) return overrides[trimmed];
      for (final entry in overrides.entries) {
        if (entry.key.toLowerCase() == lower) return entry.value;
      }
    }

    // 4. Check fast reverse and cross maps from extracted web translation database
    if (language == 'mr') {
      if (kAppReverseMr.containsKey(lower)) {
        return kAppReverseMr[lower];
      }
      if (kAppCrossHiToMr.containsKey(lower)) {
        return kAppCrossHiToMr[lower];
      }
    } else if (language == 'hi') {
      if (kAppReverseHi.containsKey(lower)) {
        return kAppReverseHi[lower];
      }
      if (kAppCrossMrToHi.containsKey(lower)) {
        return kAppCrossMrToHi[lower];
      }
    }

    return null;
  }

  /// Synchronous translation with safe fallback to original text
  static String translateDirect(String text, {required String lang}) {
    final found = tr(text, lang: lang);
    return found ?? text;
  }

  /// Helper to get report column title in given language
  static String getReportColumn(String columnKey, String lang) {
    return t('common.report_columns.$columnKey', lang: lang);
  }

  /// Helper to get navigation title in given language across all 39 screens & groups
  static String getNavTitle(String screenKey, String lang) {
    final cleanKey = screenKey.trim().toLowerCase();
    final normalized = cleanKey.replaceAll(' ', '_').replaceAll('&', '').replaceAll('-', '_');

    if (lang == 'mr') {
      if (_navTitlesMr.containsKey(cleanKey)) return _navTitlesMr[cleanKey]!;
      if (_navTitlesMr.containsKey(normalized)) return _navTitlesMr[normalized]!;
    } else if (lang == 'hi') {
      if (_navTitlesHi.containsKey(cleanKey)) return _navTitlesHi[cleanKey]!;
      if (_navTitlesHi.containsKey(normalized)) return _navTitlesHi[normalized]!;
    } else {
      if (_navTitlesEn.containsKey(cleanKey)) return _navTitlesEn[cleanKey]!;
      if (_navTitlesEn.containsKey(normalized)) return _navTitlesEn[normalized]!;
    }

    // Check dot key under nav
    final dotTitle = t('nav.$screenKey', lang: lang);
    if (dotTitle != 'nav.$screenKey') return dotTitle;

    // Direct lookup
    final direct = tr(screenKey, lang: lang);
    return direct ?? screenKey;
  }

  /// Helper to get common UI strings e.g. 'delete', 'cancel', 'save'
  static String getCommon(String key, String lang) {
    final val = t('common.$key', lang: lang);
    if (val != 'common.$key') return val;
    return tr(key, lang: lang) ?? key;
  }

  /// Helper to get localized status text
  static String getStatus(String status, String lang) {
    final trimmed = status.trim();
    final custom = customOverrides[lang]?[trimmed];
    if (custom != null) return custom;

    var key = trimmed.toLowerCase().replaceAll(' ', '_');
    if (key == 'inprogress') key = 'in_progress';

    // 1. Check complaints.status
    final valComplaints = t('complaints.status.$key', lang: lang);
    if (valComplaints != 'complaints.status.$key') return valComplaints;

    // 2. Check complaints.filters
    final valFilters = t('complaints.filters.$key', lang: lang);
    if (valFilters != 'complaints.filters.$key') return valFilters;

    final val = t('common.status.$key', lang: lang);
    if (val != 'common.status.$key') return val;

    final valCommon = t('common.$key', lang: lang);
    if (valCommon != 'common.$key') return valCommon;

    if (lang == 'en') {
      if (key == 'in_progress') return 'In Progress';
      return trimmed.isNotEmpty ? '${trimmed[0].toUpperCase()}${trimmed.substring(1)}' : trimmed;
    }

    return tr(trimmed, lang: lang) ?? status;
  }

  /// Converts ASCII digits (0-9) to Devanagari digits (०-९) for Marathi and Hindi
  static String formatDigits(dynamic value, String lang) {
    if (value == null) return '';
    final str = value.toString();
    if (lang != 'mr' && lang != 'hi') return str;

    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const devanagari = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    var result = str;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(western[i], devanagari[i]);
    }
    return result;
  }

  /// Standardized "Found: X" badge text in Devanagari or English
  static String formatFound(int count, String lang) {
    final devCount = formatDigits(count, lang);
    if (lang == 'mr') return 'सापडले: $devCount';
    if (lang == 'hi') return 'मिले: $devCount';
    return 'Found: $count';
  }

  /// Standardized "Download Report" button text
  static String getDownloadReport(String lang) {
    if (lang == 'mr') return 'अहवाल डाउनलोड करा';
    if (lang == 'hi') return 'रिपोर्ट डाउनलोड करें';
    return 'Download Report';
  }

  /// Standardized Area name translation with Devanagari numerals
  static String getAreaName(String area, String lang) {
    final trimmed = area.trim();
    if (trimmed.isEmpty || trimmed == 'All' || trimmed == 'All Areas') {
      if (lang == 'mr') return 'सर्व परिसर';
      if (lang == 'hi') return 'सभी क्षेत्र';
      return 'All Areas';
    }

    // Check custom overrides first
    final override = customOverrides[lang]?[trimmed];
    if (override != null) return formatDigits(override, lang);

    // Common areas map
    final lower = trimmed.toLowerCase();
    const areaMapMr = {
      'dhankawadi': 'धनकवडी',
      'dhankwadi': 'धनकवडी',
      'katraj': 'कात्रज',
      'bibwewadi': 'बिबवेवाडी',
      'sahakar nagar': 'सहकार नगर',
      'padmavati': 'पद्मावती',
      'balaji nagar': 'बालाजी नगर',
      'parvati': 'पार्वती',
      'pune': 'पुणे',
      'maharashtra': 'महाराष्ट्र',
      'lokmanya nagar': 'लोकमान्य नगर',
      'shivaji nagar': 'शिवाजी नगर',
      'kothrud': 'कोथरूड',
      'hadapsar': 'हडपसर',
      'viman nagar': 'विमान नगर',
      'kalyani nagar': 'कल्याणी नगर',
      'baner': 'बाणेर',
      'aundh': 'औंध',
      'wakad': 'वाकड',
      'pimpri': 'पिंपरी',
      'chinchwad': 'चिंचवड',
      'bhosari': 'भोसरी',
      'nigdi': 'निगडी',
      'airoli': 'ऐरोली',
      'ganesh nagar': 'गणेश नगर',
      'ambegaon': 'आंबेगाव',
      'vadgaon': 'वडगाव',
      'warje': 'वारजे',
      'karve nagar': 'कर्वे नगर',
      'kondhwa': 'कोंढवा',
      'swargate': 'स्वारगेट',
      'camp': 'कॅम्प',
      'model colony': 'मॉडेल कॉलनी',
      'deccan': 'डेक्कन',
      'sadashiv peth': 'सदाशिव पेठ',
      'narayan peth': 'नारायण पेठ',
      'shaniwar peth': 'शनिवार पेठ',
      'somwar peth': 'सोमवार पेठ',
      'manglwar peth': 'मंगळवार पेठ',
      'kasba peth': 'कसबा पेठ',
      'bhavani peth': 'भवानी पेठ',
      'nana peth': 'नाना पेठ',
      'rasta peth': 'रास्ता पेठ',
      'ganj peth': 'गंज पेठ',
    };

    const areaMapHi = {
      'dhankawadi': 'धनकवडी',
      'dhankwadi': 'धनकवडी',
      'katraj': 'कात्रज',
      'bibwewadi': 'बिबवेवाडी',
      'sahakar nagar': 'सहकार नगर',
      'padmavati': 'पद्मावती',
      'balaji nagar': 'बालाजी नगर',
      'parvati': 'पार्वती',
      'pune': 'पुणे',
      'maharashtra': 'महाराष्ट्र',
      'lokmanya nagar': 'लोकमान्य नगर',
      'shivaji nagar': 'शिवाजी नगर',
      'kothrud': 'कोथरूड',
      'hadapsar': 'हडपसर',
      'viman nagar': 'विमान नगर',
      'kalyani nagar': 'कल्याणी नगर',
      'baner': 'बानेर',
      'aundh': 'औंध',
      'wakad': 'वाकड',
      'pimpri': 'पिंपरी',
      'chinchwad': 'चिंचवाड़',
      'bhosari': 'भोसरी',
      'nigdi': 'निगडी',
      'airoli': 'ऐरोली',
      'ganesh nagar': 'गणेश नगर',
      'ambegaon': 'आंबेगांव',
      'vadgaon': 'वडगांव',
      'warje': 'वारजे',
      'karve nagar': 'कर्वे नगर',
      'kondhwa': 'कोंढवा',
      'swargate': 'स्वारगेट',
      'camp': 'कैंप',
      'model colony': 'मॉडल कॉलोनी',
      'deccan': 'डेक्कन',
    };

    if (lang == 'mr' && areaMapMr.containsKey(lower)) {
      return formatDigits(areaMapMr[lower]!, lang);
    }
    if (lang == 'hi' && areaMapHi.containsKey(lower)) {
      return formatDigits(areaMapHi[lower]!, lang);
    }

    // Pattern: Ward X -> प्रभाग X / वार्ड X
    final wardMatch = RegExp(r'^(?:Ward|Prabhag)\s*(\d+)$', caseSensitive: false).firstMatch(trimmed);
    if (wardMatch != null) {
      final numStr = wardMatch.group(1)!;
      final devNum = formatDigits(numStr, lang);
      if (lang == 'mr') return 'प्रभाग $devNum';
      if (lang == 'hi') return 'वार्ड $devNum';
      return 'Ward $numStr';
    }

    // Pattern: Lane X -> गल्ली क्र. X / गली नं. X
    final laneMatch = RegExp(r'^Lane\s*(\d+)$', caseSensitive: false).firstMatch(trimmed);
    if (laneMatch != null) {
      final numStr = laneMatch.group(1)!;
      final devNum = formatDigits(numStr, lang);
      if (lang == 'mr') return 'गल्ली क्र. $devNum';
      if (lang == 'hi') return 'गली नं. $devNum';
      return 'Lane $numStr';
    }

    // Pattern: Sector X -> सेक्टर X
    final sectorMatch = RegExp(r'^Sector\s*(\d+)$', caseSensitive: false).firstMatch(trimmed);
    if (sectorMatch != null) {
      final numStr = sectorMatch.group(1)!;
      final devNum = formatDigits(numStr, lang);
      if (lang == 'mr' || lang == 'hi') return 'सेक्टर $devNum';
      return 'Sector $numStr';
    }

    // Fallback: translateDirect and format digits
    final direct = tr(trimmed, lang: lang);
    return direct != null ? formatDigits(direct, lang) : formatDigits(trimmed, lang);
  }

  /// Standardized complaint type translation
  static String getComplaintType(String type, String lang) {
    final lower = type.trim().toLowerCase().replaceAll('_', ' ');

    if (lower.contains('clean') || lower.contains('garbage') || lower.contains('कचरा')) {
      if (lang == 'mr') return 'कचरा / स्वच्छता';
      if (lang == 'hi') return 'सफाई / कचरा';
      return 'Cleaning / Garbage';
    }
    if (lower.contains('water') || lower.contains('पाणी') || lower.contains('जल')) {
      if (lang == 'mr') return 'पाणी पुरवठा';
      if (lang == 'hi') return 'जल आपूर्ति';
      return 'Water Supply';
    }
    if (lower.contains('road') || lower.contains('pothole') || lower.contains('रस्ते') || lower.contains('सड़क')) {
      if (lang == 'mr') return 'रस्ते / खड्डे';
      if (lang == 'hi') return 'सड़क / गड्ढे';
      return 'Road / Potholes';
    }
    if (lower.contains('drain') || lower.contains('ड्रेनेज') || lower.contains('नाली')) {
      if (lang == 'mr') return 'ड्रेनेज / सांडपाणी';
      if (lang == 'hi') return 'ड्रेनेज / नाली';
      return 'Drainage';
    }
    if (lower.contains('light') || lower.contains('street') || lower.contains('पथदिवे')) {
      if (lang == 'mr') return 'पथदिवे';
      if (lang == 'hi') return 'स्ट्रीट लाइट';
      return 'Street Light';
    }
    if (lower.contains('ward problem') || lower.contains('self') || lower.contains('समस्या')) {
      if (lang == 'mr') return 'प्रभाग समस्या';
      if (lang == 'hi') return 'वार्ड समस्या';
      return 'Ward Problem';
    }
    if (lower.contains('medic') || lower.contains('health') || lower.contains('आरोग्य')) {
      if (lang == 'mr') return 'वैद्यकीय मदत';
      if (lang == 'hi') return 'चिकित्सा सहायता';
      return 'Medical Help';
    }
    if (lower.contains('finan') || lower.contains('आर्थिक') || lower.contains('वित्तीय')) {
      if (lang == 'mr') return 'आर्थिक मदत';
      if (lang == 'hi') return 'वित्तीय सहायता';
      return 'Financial Help';
    }
    if (lower.contains('admiss') || lower.contains('educat') || lower.contains('शिक्षण') || lower.contains('प्रवेश')) {
      if (lang == 'mr') return 'शिक्षण / प्रवेश';
      if (lang == 'hi') return 'शिक्षा / प्रवेश';
      return 'Education / Admission';
    }
    if (lower.contains('help') || lower.contains('personal') || lower.contains('मदत')) {
      if (lang == 'mr') return 'वैद्यकीय / वैयक्तिक मदत';
      if (lang == 'hi') return 'व्यक्तिगत सहायता';
      return 'Personal Help';
    }
    if (lower.contains('suggest') || lower.contains('सूचना') || lower.contains('सुझाव')) {
      if (lang == 'mr') return 'सूचना';
      if (lang == 'hi') return 'सुझाव';
      return 'Suggestion';
    }
    if (lower.contains('complaint') || lower.contains('तक्रार') || lower.contains('शिकायत')) {
      if (lang == 'mr') return 'तक्रार';
      if (lang == 'hi') return 'शिकायत';
      return 'Complaint';
    }

    return translateDirect(type, lang: lang);
  }

  /// Standardized Priority translation
  static String getPriority(String priority, String lang) {
    final lower = priority.trim().toLowerCase();
    if (lower == 'urgent' || lower == 'emergency' || lower == 'critical') {
      if (lang == 'mr') return 'तातडीचे';
      if (lang == 'hi') return 'अति आवश्यक';
      return 'Urgent';
    }
    if (lower == 'high') {
      if (lang == 'mr') return 'उच्च';
      if (lang == 'hi') return 'उच्च';
      return 'High';
    }
    if (lower == 'medium') {
      if (lang == 'mr') return 'मध्यम';
      if (lang == 'hi') return 'मध्यम';
      return 'Medium';
    }
    if (lower == 'low') {
      if (lang == 'mr') return 'कमी';
      if (lang == 'hi') return 'कम';
      return 'Low';
    }
    return translateDirect(priority, lang: lang);
  }

  /// Standardized Gender translation
  static String getGender(String gender, String lang) {
    final lower = gender.trim().toLowerCase();
    if (lower == 'male' || lower == 'm') {
      if (lang == 'mr') return 'पुरुष';
      if (lang == 'hi') return 'पुरुष';
      return 'Male';
    }
    if (lower == 'female' || lower == 'f') {
      if (lang == 'mr') return 'महिला';
      if (lang == 'hi') return 'महिला';
      return 'Female';
    }
    if (lower == 'other' || lower == 'o') {
      if (lang == 'mr') return 'इतर';
      if (lang == 'hi') return 'अन्य';
      return 'Other';
    }
    return translateDirect(gender, lang: lang);
  }

  /// Standardized currency formatting with Devanagari numerals
  static String formatCurrency(dynamic amount, String lang) {
    if (amount == null) return '₹ ०';
    final str = amount.toString();
    final devDigits = formatDigits(str, lang);
    return '₹ $devDigits';
  }

  /// All Areas label
  static String getAllAreas(String lang) {
    if (lang == 'mr') return 'सर्व भाग / परिसर';
    if (lang == 'hi') return 'सभी क्षेत्र / परिसर';
    return 'All Areas';
  }

  /// All label
  static String getAll(String lang) {
    if (lang == 'mr') return 'सर्व';
    if (lang == 'hi') return 'सभी';
    return 'All';
  }

  /// Details label
  static String getDetails(String lang) {
    if (lang == 'mr') return 'तपशील';
    if (lang == 'hi') return 'विवरण';
    return 'Details';
  }
}
