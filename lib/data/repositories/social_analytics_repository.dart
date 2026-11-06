import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/social_post_model.dart';

final socialAnalyticsRepoProvider = Provider<SocialAnalyticsRepository>((ref) {
  return SocialAnalyticsRepository();
});

class SocialAnalyticsSummary {
  final int totalReach;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final double averageEngagementRate;
  final String monthlyGrowth;
  final int totalPosts;

  const SocialAnalyticsSummary({
    required this.totalReach,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.averageEngagementRate,
    required this.monthlyGrowth,
    required this.totalPosts,
  });
}

class SocialAnalyticsRepository {
  final List<SocialPostModel> _posts = [
    SocialPostModel(
      id: 'soc_01',
      platform: 'Facebook',
      content:
          'Visited Ward 12 today to inspect the new road concretization and drainage culvert work in Budhwar Peth. The work is progressing rapidly on schedule and will be dedicated to citizens by next month.',
      contentMarathi:
          'आज प्रभाग १२ बुधवार पेठ येथे नवीन सिमेंट काँक्रिटीकरण रस्ता व भूमिगत ड्रेनेज लाईन कामाची प्रत्यक्ष पाहणी केली. काम वेगाने सुरू असून पुढील महिन्यापर्यंत नागरिकांसाठी खुले होईल. #विकास #नगरसेवक #प्रभाग१२',
      contentKey: 'social.post_1',
      likes: 1240,
      comments: 45,
      shares: 82,
      reach: 14200,
      date: '2026-01-20',
      imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=800',
      postUrl: 'https://facebook.com/nagarsevak.ward12/posts/101',
      tags: ['#विकास', '#रस्तेबांधणी', '#प्रभाग१२', '#PMC'],
    ),
    SocialPostModel(
      id: 'soc_02',
      platform: 'Instagram',
      content:
          'Grand Ganesh Chaturthi celebrations and public safety preparations in full swing across all mandals of Prabhag 12! Dedicated cleanliness drives and LED lighting deployed. Ganpati Bappa Morya!',
      contentMarathi:
          'प्रभाग १२ मधील सर्व गणेशोत्सव मंडळांची जय्यत तयारी व भाविकांच्या सुरक्षेसाठी विशेष सोयी! अखंड वीजपुरवठा, स्वच्छता व आपत्कालीन मदत कक्ष सज्ज. गणपती बाप्पा मोरया! #गणेशोत्सव #पुणे #प्रभाग१२',
      contentKey: 'social.post_2',
      likes: 3500,
      comments: 120,
      shares: 450,
      reach: 28500,
      date: '2026-01-18',
      imageUrl: 'https://images.unsplash.com/photo-1567591414240-e1cff72516c8?auto=format&fit=crop&q=80&w=800',
      postUrl: 'https://instagram.com/p/C_abc123',
      tags: ['#गणेशोत्सव', '#पुणेरीउत्सव', '#गणपतीबाप्पा', '#Prabhag12'],
    ),
    SocialPostModel(
      id: 'soc_03',
      platform: 'Facebook',
      content:
          'Free Multi-Specialty Health Checkup & Eye Screening Camp this Sunday at Shivaji Mandir Hall, Budhwar Peth. Free medicines, diabetes screening and eyeglasses will be distributed. Health is Wealth!',
      contentMarathi:
          'येत्या रविवारी बुधवार पेठेतील छत्रपती शिवाजी मंदिर सभागृहात भव्य मोफत सर्वोपचार व नेत्र तपासणी शिबिर. तज्ज्ञ डॉक्टरांकडून मोफत औषधोपचार व चष्मा वाटप केले जाईल. आरोग्य हीच खरी संपत्ती! #आरोग्यशिबिर #प्रभाग१२',
      contentKey: 'social.post_3',
      likes: 890,
      comments: 34,
      shares: 89,
      reach: 8900,
      date: '2026-01-15',
      imageUrl: 'https://images.unsplash.com/photo-1576091160550-217358c7db81?auto=format&fit=crop&q=80&w=800',
      postUrl: 'https://facebook.com/nagarsevak.ward12/posts/102',
      tags: ['#आरोग्यशिबिर', '#मोफतसेवा', '#सेवाभाव', '#HealthIsWealth'],
    ),
    SocialPostModel(
      id: 'soc_04',
      platform: 'Instagram',
      content:
          'Inspiring interactive dialogue with youth leaders, college students & karyakartas on civic leadership, employment drives, and digital voter assistance. The energy of our youth is our real strength!',
      contentMarathi:
          'प्रभाग १२ मधील तरुण कार्यकर्ते, महाविद्यालयीन विद्यार्थी व युवा नेत्यांशी थेट संवाद. रोजगार मार्गदर्शन, स्पर्धा परीक्षा कक्ष व डिजिटल प्रभाग उपक्रमांवर चर्चा. तरुणाईची ऊर्जा हेच आपले खरे बळ! #युवाशक्ती #पुणे',
      contentKey: 'social.post_4',
      likes: 4200,
      comments: 210,
      shares: 120,
      reach: 31400,
      date: '2026-01-10',
      imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&q=80&w=800',
      postUrl: 'https://instagram.com/p/C_xyz456',
      tags: ['#युवाशक्ती', '#संवाद', '#तरुणाई', '#YouthLeaders'],
    ),
    SocialPostModel(
      id: 'soc_05',
      platform: 'Twitter',
      content:
          'Chaired high-level review meeting with PMC Swargate Water Supply Executive Engineers regarding regularizing water pressure in Shaniwar Peth Lane 4. New 150mm booster pipeline work sanctioned.',
      contentMarathi:
          'शनिवार पेठ गल्ली क्र. ४ मधील कमी पाण्याच्या दाबाच्या तक्रारीबाबत मनपा स्वारगेट जलशुद्धीकरण अभियंत्यांसमवेत तातडीची आढावा बैठक. १५० मिमी नवीन बूस्टर पाईपलाईन कामास तत्काळ मंजुरी. #पाणीपुरवठा #पुणेमनपा',
      likes: 640,
      comments: 58,
      shares: 140,
      reach: 11200,
      date: '2026-01-08',
      imageUrl: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&q=80&w=800',
      postUrl: 'https://twitter.com/nagarsevak12/status/105',
      tags: ['#पाणीपुरवठा', '#पुणेमनपा', '#जलसेवा', '#Prabhag12'],
    ),
    SocialPostModel(
      id: 'soc_06',
      platform: 'Facebook',
      content:
          'Hearty felicitations to respected senior citizens, retired teachers and housing society office bearers at our Prabhag Jan Sampark Karyalay. Your wisdom and blessings guide our path of civic service.',
      contentMarathi:
          'प्रभाग १२ जनसंपर्क कार्यालयात ज्येष्ठ नागरिक, निवृत्त शिक्षक व गृहनिर्माण संस्थांच्या पदाधिकाऱ्यांचा स्नेहसंवाद व कृतज्ञता सत्कार संपन्न. ज्येष्ठांचे आशीर्वाद व मार्गदर्शन हीच आमची खरी प्रेरणा! #ज्येष्ठनागरिक',
      likes: 1120,
      comments: 42,
      shares: 65,
      reach: 12800,
      date: '2026-01-05',
      imageUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&q=80&w=800',
      postUrl: 'https://facebook.com/nagarsevak.ward12/posts/106',
      tags: ['#ज्येष्ठनागरिक', '#स्नेहमेळावा', '#सत्कार', '#प्रभाग१२'],
    ),
  ];

  final List<VoterBirthdayModel> _birthdays = [
    const VoterBirthdayModel(
      id: 'MH12-V-08492',
      name: 'Santosh R. Deshmukh',
      nameMarathi: 'संतोष रामचंद्र देशमुख',
      mobile: '+919822014589',
      area: 'Shaniwar Peth',
      boothNumber: 'Booth 12-A (Bhave High School)',
      age: 48,
    ),
    const VoterBirthdayModel(
      id: 'MH12-V-12054',
      name: 'Sunita Vijay Kulkarni',
      nameMarathi: 'सुनिता विजय कुलकर्णी',
      mobile: '+919422315678',
      area: 'Sadashiv Peth',
      boothNumber: 'Booth 12-C (SP College)',
      age: 39,
    ),
    const VoterBirthdayModel(
      id: 'MH12-V-33910',
      name: 'Aniket M. Jagtap',
      nameMarathi: 'अनिकेत महेश जगताप',
      mobile: '+919921045612',
      area: 'Budhwar Peth',
      boothNumber: 'Booth 12-B (City High School)',
      age: 26,
    ),
    const VoterBirthdayModel(
      id: 'MH12-V-45129',
      name: 'Prakash D. Shinde',
      nameMarathi: 'प्रकाश दत्तात्रय शिंदे',
      mobile: '+919850123890',
      area: 'Kasba Peth',
      boothNumber: 'Booth 12-D (Kasba Ganpati School)',
      age: 54,
    ),
  ];

  Future<List<SocialPostModel>> getPosts() async {
    // Simulate lightweight async loading
    await Future.delayed(const Duration(milliseconds: 250));
    return List.from(_posts);
  }

  Future<List<VoterBirthdayModel>> getBirthdays() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(_birthdays);
  }

  Future<SocialAnalyticsSummary> getSummary() async {
    int reach = 0;
    int likes = 0;
    int comments = 0;
    int shares = 0;
    double totalEngRate = 0;

    for (final p in _posts) {
      reach += p.reach;
      likes += p.likes;
      comments += p.comments;
      shares += p.shares;
      totalEngRate += p.engagementRate;
    }

    final avgRate = _posts.isNotEmpty ? (totalEngRate / _posts.length) : 0.0;

    return SocialAnalyticsSummary(
      totalReach: reach > 0 ? reach : 45200,
      totalLikes: likes,
      totalComments: comments,
      totalShares: shares,
      averageEngagementRate: avgRate,
      monthlyGrowth: '+12% vs last month',
      totalPosts: _posts.length,
    );
  }

  Future<void> addPost(SocialPostModel post) async {
    _posts.insert(0, post);
  }

  Future<void> updatePost(SocialPostModel post) async {
    final idx = _posts.indexWhere((p) => p.id == post.id);
    if (idx != -1) {
      _posts[idx] = post;
    }
  }

  Future<void> deletePost(String id) async {
    _posts.removeWhere((p) => p.id == id);
  }
}

