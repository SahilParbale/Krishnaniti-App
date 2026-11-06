import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gallery_model.dart';

class GalleryRepository {
  final List<GalleryItemModel> _items = [
    GalleryItemModel(
      id: 'gal-001',
      title: 'Inauguration of Samaj Mandir & Senior Citizen Center',
      titleMr: 'समाज मंदिर व ज्येष्ठ नागरिक विरंगुळा केंद्र भव्य लोकार्पण सोहळा',
      category: GalleryCategory.event,
      imageUrl: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?auto=format&fit=crop&w=800&q=80',
      description:
          'प्रभाग १२ मधील ज्येष्ठ नागरिक आणि महिलांसाठी बांधण्यात आलेल्या अद्ययावत समाज मंदिर व विरंगुळा केंद्राचे हजारो नागरिकांच्या उपस्थितीत भव्य लोकार्पण.',
      descriptionMr:
          'प्रभाग १२ मधील ज्येष्ठ नागरिक आणि महिलांसाठी बांधण्यात आलेल्या अद्ययावत समाज मंदिर व विरंगुळा केंद्राचे हजारो नागरिकांच्या उपस्थितीत भव्य लोकार्पण.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      location: 'शनिवार पेठ, पुणे',
      tags: ['उद्घाटन', 'समाज मंदिर', 'शनिवार पेठ', 'ज्येष्ठ नागरिक'],
      isFavorite: true,
      viewsCount: 185,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    GalleryItemModel(
      id: 'gal-002',
      title: 'Cement Concreting of Main DP Road in Ward 12',
      titleMr: 'प्रभाग १२ मधील मुख्य डीपी रस्ता सिमेंट काँक्रीटीकरण पूर्ण',
      category: GalleryCategory.work,
      imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80',
      description:
          'नागरिकांच्या सुलभ प्रवासासाठी दर्जेदार सिमेंट काँक्रीट रस्त्याचे काम निर्धारित मुदतीत पूर्ण झाले असून वाहतूक सुरळीत सुरू झाली आहे.',
      descriptionMr:
          'नागरिकांच्या सुलभ प्रवासासाठी दर्जेदार सिमेंट काँक्रीट रस्त्याचे काम निर्धारित मुदतीत पूर्ण झाले असून वाहतूक सुरळीत सुरू झाली आहे.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      location: 'कसबा पेठ, पुणे',
      tags: ['रस्ता विकास', 'काँक्रीटीकरण', 'कसबा पेठ', 'पायाभूत सुविधा'],
      isFavorite: true,
      viewsCount: 240,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    GalleryItemModel(
      id: 'gal-003',
      title: 'PMC Best Corporator Civic Award 2024 Felicitation',
      titleMr: 'पुणे मनपा उत्कृष्ट नगरसेवक गौरव पुरस्कार २०२४ सन्मान',
      category: GalleryCategory.award,
      imageUrl: 'https://images.unsplash.com/photo-1569098644584-210bcd375b59?auto=format&fit=crop&w=800&q=80',
      description:
          'प्रभागातील जनहिताच्या विकासकामांमधील सातत्य आणि पारदर्शकतेबद्दल पुणे महानगरपालिका आयुक्तांच्या हस्ते उत्कृष्ट नगरसेवक पुरस्काराने सन्मानित.',
      descriptionMr:
          'प्रभागातील जनहिताच्या विकासकामांमधील सातत्य आणि पारदर्शकतेबद्दल पुणे महानगरपालिका आयुक्तांच्या हस्ते उत्कृष्ट नगरसेवक पुरस्काराने सन्मानित.',
      date: DateTime.now().subtract(const Duration(days: 9)),
      location: 'बालगंधर्व रंगमंदिर, पुणे',
      tags: ['पुरस्कार', 'उत्कृष्ट नगरसेवक', 'मनपा', 'सन्मान'],
      isFavorite: true,
      viewsCount: 410,
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
    ),
    GalleryItemModel(
      id: 'gal-004',
      title: 'Free Mega Health, Diabetes & Eye Checkup Camp',
      titleMr: 'मोफत महा-आरोग्य, मधुमेह व नेत्रतपासणी शिबिर',
      category: GalleryCategory.event,
      imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
      description:
          'नागरिकांच्या आरोग्यासाठी आयोजित शिबिरात ५०० हून अधिक बंधू-भगिनींची मोफत तपासणी करून गरजूंना चष्मे व औषधांचे वाटप करण्यात आले.',
      descriptionMr:
          'नागरिकांच्या आरोग्यासाठी आयोजित शिबिरात ५०० हून अधिक बंधू-भगिनींची मोफत तपासणी करून गरजूंना चष्मे व औषधांचे वाटप करण्यात आले.',
      date: DateTime.now().subtract(const Duration(days: 12)),
      location: 'अहिल्याबाई शाळा, नारायण पेठ',
      tags: ['आरोग्य शिबिर', 'नेत्र तपासणी', 'नारायण पेठ', 'जनसेवा'],
      isFavorite: false,
      viewsCount: 310,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    GalleryItemModel(
      id: 'gal-005',
      title: 'Underground Stormwater Drainage & Chamber Inspection',
      titleMr: 'भूमिगत पर्जन्यजल वाहिनी व चेंबर जोडणी काम प्रत्यक्ष पाहणी',
      category: GalleryCategory.work,
      imageUrl: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?auto=format&fit=crop&w=800&q=80',
      description:
          'पावसाळ्यात पाणी साचू नये म्हणून १२०० मिमी व्यासाच्या नवीन पर्जन्यजल वाहिन्या टाकण्याच्या कामाची मनपा अभियंत्यांसमवेत प्रत्यक्ष पाहणी.',
      descriptionMr:
          'पावसाळ्यात पाणी साचू नये म्हणून १२०० मिमी व्यासाच्या नवीन पर्जन्यजल वाहिन्या टाकण्याच्या कामाची मनपा अभियंत्यांसमवेत प्रत्यक्ष पाहणी.',
      date: DateTime.now().subtract(const Duration(days: 16)),
      location: 'रास्ता पेठ, लेन ४, पुणे',
      tags: ['ड्रेनेज काम', 'पर्जन्यजल वाहिनी', 'रास्ता पेठ', 'विकास'],
      isFavorite: false,
      viewsCount: 195,
      createdAt: DateTime.now().subtract(const Duration(days: 16)),
    ),
    GalleryItemModel(
      id: 'gal-006',
      title: 'Swachh Prabhag Cleanliness & Plastic-Free Public Rally',
      titleMr: 'स्वच्छ प्रभाग - प्लास्टिक मुक्ती भव्य जनजागृती रॅली',
      category: GalleryCategory.campaign,
      imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80',
      description:
          'परिसर स्वच्छ आणि सुंदर ठेवण्यासाठी नागरिक व शालेय विद्यार्थ्यांच्या सहभागाने भव्य स्वच्छता रॅली आणि जनजागृती मोहीम.',
      descriptionMr:
          'परिसर स्वच्छ आणि सुंदर ठेवण्यासाठी नागरिक व शालेय विद्यार्थ्यांच्या सहभागाने भव्य स्वच्छता रॅली आणि जनजागृती मोहीम.',
      date: DateTime.now().subtract(const Duration(days: 20)),
      location: 'शनिवार वाडा परिसर, पुणे',
      tags: ['स्वच्छता मोहीम', 'प्लास्टिक मुक्ती', 'रॅली', 'जनजागृती'],
      isFavorite: true,
      viewsCount: 280,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    GalleryItemModel(
      id: 'gal-007',
      title: 'Smart LED Streetlighting & CCTV Surveillance Network',
      titleMr: 'स्मार्ट एलईडी पथदिवे व सीसीटीव्ही नेटवर्क लोकार्पण',
      category: GalleryCategory.work,
      imageUrl: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=800&q=80',
      description:
          'महिलांच्या सुरक्षिततेसाठी प्रभागातील सर्व गल्ल्यांमध्ये १००% एलईडी दिवे आणि ५० हून अधिक सीसीटीव्ही कॅमेरे कार्यान्वित.',
      descriptionMr:
          'महिलांच्या सुरक्षिततेसाठी प्रभागातील सर्व गल्ल्यांमध्ये १००% एलईडी दिवे आणि ५० हून अधिक सीसीटीव्ही कॅमेरे कार्यान्वित.',
      date: DateTime.now().subtract(const Duration(days: 25)),
      location: 'शनिवार पेठ व कसबा परिसर',
      tags: ['एलईडी पथदिवे', 'सीसीटीव्ही', 'सुरक्षित प्रभाग', 'स्मार्ट सिटी'],
      isFavorite: false,
      viewsCount: 320,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    GalleryItemModel(
      id: 'gal-008',
      title: 'Women Self-Help Groups Haldi-Kumkum & Entrepreneurship Meet',
      titleMr: 'महिला बचत गट सक्षमीकरण व हळदी-कुंकू स्नेहमेळावा',
      category: GalleryCategory.event,
      imageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=800&q=80',
      description:
          'प्रभागातील महिला बचत गटांना आर्थिक स्वावलंबन मार्गदर्शन आणि पारंपरिक हळदी-कुंकू स्नेहमेळावा उत्साहात संपन्न.',
      descriptionMr:
          'प्रभागातील महिला बचत गटांना आर्थिक स्वावलंबन मार्गदर्शन आणि पारंपरिक हळदी-कुंकू स्नेहमेळावा उत्साहात संपन्न.',
      date: DateTime.now().subtract(const Duration(days: 30)),
      location: 'रमणबाग प्रशाला सभागृह, पुणे',
      tags: ['महिला बचत गट', 'हळदी-कुंकू', 'महिला सक्षमीकरण'],
      isFavorite: false,
      viewsCount: 190,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    GalleryItemModel(
      id: 'gal-009',
      title: 'Mutha Riverfront Greenery & Massive Tree Plantation Drive',
      titleMr: 'मुठा नदीकाठ संवर्धन व भव्य पर्यावरण वृक्षारोपण मोहीम',
      category: GalleryCategory.campaign,
      imageUrl: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&w=800&q=80',
      description:
          'पर्यावरण संतुलनासाठी स्थानिक रहिवाशांच्या सहकार्याने नदीकाठ परिसरात २०० हून अधिक देशी वृक्षांची लागवड व संवर्धन संकल्प.',
      descriptionMr:
          'पर्यावरण संतुलनासाठी स्थानिक रहिवाशांच्या सहकार्याने नदीकाठ परिसरात २०० हून अधिक देशी वृक्षांची लागवड व संवर्धन संकल्प.',
      date: DateTime.now().subtract(const Duration(days: 35)),
      location: 'ओंकारेश्वर घाट परिसर, पुणे',
      tags: ['वृक्षारोपण', 'पर्यावरण', 'मुठा नदीकाठ', 'हरित प्रभाग'],
      isFavorite: true,
      viewsCount: 215,
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
    GalleryItemModel(
      id: 'gal-010',
      title: 'State Level Ideal Public Representative Special Honor',
      titleMr: 'राज्यस्तरीय आदर्श लोकप्रतिनिधी विशेष गौरव सन्मान',
      category: GalleryCategory.award,
      imageUrl: 'https://images.unsplash.com/photo-1531058020387-3be344556be6?auto=format&fit=crop&w=800&q=80',
      description:
          'नागरी समस्यांचे जलद निवारण आणि प्रभावी डिजिटल जनसंपर्कासाठी राज्यस्तरीय सामाजिक संस्थेमार्फत विशेष सन्मानपत्र प्रदान.',
      descriptionMr:
          'नागरी समस्यांचे जलद निवारण आणि प्रभावी डिजिटल जनसंपर्कासाठी राज्यस्तरीय सामाजिक संस्थेमार्फत विशेष सन्मानपत्र प्रदान.',
      date: DateTime.now().subtract(const Duration(days: 45)),
      location: 'मुंबई विधानसभा परिसर',
      tags: ['आदर्श लोकप्रतिनिधी', 'राज्यस्तरीय सन्मान', 'गौरव'],
      isFavorite: true,
      viewsCount: 520,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  Future<List<GalleryItemModel>> getGalleryItems({GalleryCategory? category}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (category != null) {
      return _items.where((i) => i.category == category).toList();
    }
    return List.unmodifiable(_items);
  }

  Future<GalleryItemModel?> getGalleryItemById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<GalleryItemModel> addGalleryItem(GalleryItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _items.insert(0, item);
    return item;
  }

  Future<GalleryItemModel> updateGalleryItem(GalleryItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _items[idx] = item;
      return item;
    }
    throw Exception('Gallery item not found');
  }

  Future<void> deleteGalleryItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _items.removeWhere((i) => i.id == id);
  }

  Future<bool> toggleFavorite(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final updated = _items[idx].copyWith(
        isFavorite: !_items[idx].isFavorite,
      );
      _items[idx] = updated;
      return updated.isFavorite;
    }
    return false;
  }

  void incrementViews(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(viewsCount: _items[idx].viewsCount + 1);
    }
  }
}

final galleryRepoProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository();
});

