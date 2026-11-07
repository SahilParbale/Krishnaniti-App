import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveScreenNotifier extends Notifier<String> {
  @override
  String build() => 'dashboard';

  void setScreen(String screenKey) {
    state = screenKey;
  }
}

final activeScreenProvider = NotifierProvider<ActiveScreenNotifier, String>(ActiveScreenNotifier.new);

class MainTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

final mainTabIndexProvider = NotifierProvider<MainTabNotifier, int>(MainTabNotifier.new);

String? resolveScreenKey(String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower == 'dashboard' || lower == 'home' || lower.contains('मुख्य')) return 'dashboard';
  if (lower.contains('complaint') || lower.contains('request') || lower.contains('तक्रार') || lower.contains('विनंती')) return 'complaints';
  if (lower == 'letters' || lower.contains('correspondence') || lower.contains('letter') || lower.contains('पत्र')) return 'letters';
  if (lower.contains('profile settings') || lower.contains('settings') || lower.contains('सेटिंग्ज')) return 'profile_settings';
  if (lower == 'ward map' || lower.contains('ward map') || lower.contains('नकाशा')) return 'ward_map';
  if (lower.contains('ward problem') || lower.contains('ward_problem') || lower.contains('समस्या')) return 'ward_problems';
  if (lower.contains('work history') || lower.contains('कामे') || lower.contains('इतिहास')) return 'work_history';
  if (lower.contains('improvement') || lower.contains('सुधारणा')) return 'improvements';
  if (lower.contains('provision') || lower.contains('तरतूद')) return 'provisions';
  if (lower.contains('budget') || lower.contains('अंदाजपत्रक')) return 'ward_budget';
  if (lower.contains('government office') || lower.contains('gov_office') || lower.contains('कार्यालय')) return 'gov_office';
  if (lower.contains('social analytics') || lower == 'social' || lower.contains('social media') || lower.contains('सोशल मीडिया')) return 'social_analytics';
  if (lower.contains('newspaper') || lower.contains('clipping') || lower.contains('वृत्तपत्र')) return 'newspaper';
  if (lower.contains('media tracking') || (lower.contains('tracking') && !lower.contains('visitor')) || lower.contains('मागोवा')) return 'media_tracking';
  if (lower.contains('ai content') || lower.contains('content studio') || lower.contains('कंटेंट स्टुडिओ')) return 'ai_content';
  if (lower.contains('event') || lower.contains('invite') || lower.contains('कार्यक्रम') || lower.contains('आमंत्रण')) return 'events';
  if (lower.contains('gallery') || lower.contains('गॅलरी') || lower.contains('फोटो')) return 'gallery';
  if (lower.contains('result') || lower.contains('election') || lower.contains('निकाल')) return 'result_analysis';
  if (lower.contains('sadasya') || lower.contains('सदस्य') || lower.contains('party member')) return 'sadasya';
  if (lower.contains('survey') || lower.contains('सर्वेक्षण') || lower.contains('चाचण्या')) return 'surveys';
  if (lower.contains('voter search') || lower.contains('मतदार शोध') || lower == 'voter search' || lower == 'voters') return 'voters';
  if (lower.contains('team') || lower.contains('staff') || lower.contains('कार्यसंघ') || lower.contains('कर्मचारी')) return 'team';
  if (lower.contains('opposition') || lower.contains('विरोध') || lower.contains('विरोधी')) return 'opposition';
  if (lower.contains('mandal') || lower.contains('ngo') || lower.contains('मंडळ') || lower.contains('संस्था')) return 'ngo_mandals';
  if (lower.contains('societ') || lower.contains('सोसायटी')) return 'housing_societies';
  if (lower.contains('duplicate') || lower.contains('ड्युप्लिकेट')) return 'duplicate_voters';
  if (lower.contains('form') || lower.contains('अर्ज')) return 'voter_forms';
  if (lower.contains('karyakarta') || lower.contains('कार्यकर्ता काम')) return 'karyakarta_work';
  if (lower.contains('send sms') || lower.contains('sms')) return 'sms';
  if (lower.contains('whatsapp message') || lower.contains('संदेश')) return 'whatsapp_message';
  if (lower.contains('whatsapp calling') || lower.contains('whatsapp call') || lower.contains('व्हॉट्सॲप कॉल')) return 'whatsapp_call';
  if (lower.contains('ai voice') || lower.contains('एआय व्हॉईस')) return 'ai_voice_call';
  if (lower == 'voice call' || lower.contains('voice call') || (lower.contains('voice') && !lower.contains('ai'))) return 'voice_call';
  if (lower.contains('conference') || lower.contains('कॉन्फरन्स')) return 'conference_room';
  if (lower.contains('scheme') || lower.contains('govt schemes') || lower.contains('योजना')) return 'schemes';
  if (lower == 'gb register' || lower.contains('gb register') || lower.contains('महासभा')) return 'gb_register';
  if (lower == 'diary' || (lower.contains('diary') && !lower.contains('gb')) || lower.contains('दैनंदिनी')) return 'diary';
  if (lower.contains('visitor') || lower.contains('भेट')) return 'visitors';
  if (lower.contains('analysis strategy') || lower.contains('strategy') || lower.contains('धोरण') || lower.contains('विश्लेषण')) return 'analysis_strategy';
  return null;
}
