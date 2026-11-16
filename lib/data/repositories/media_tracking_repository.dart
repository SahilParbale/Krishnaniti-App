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

  final List<TrackingProfileModel> _profiles = const [
    TrackingProfileModel(
      id: 'prof_01',
      name: 'Nagarsevak Office',
      nameMarathi: 'नगरसेवक कार्यालय',
      category: 'Leader',
      query: 'Nagarsevak',
      mentionsCount: 24,
    ),
    TrackingProfileModel(
      id: 'prof_02',
      name: 'Ward Development Works',
      nameMarathi: 'प्रभाग विकासकामे',
      category: 'Ward',
      query: 'Prabhag',
      mentionsCount: 18,
    ),
  ];

  Future<List<MediaTrackingArticleModel>> getArticles({
    String? query,
    String? profileId,
  }) async {
    List<MediaTrackingArticleModel> list = [];

    if (clippingRepo != null) {
      try {
        final clippings = await clippingRepo!.getClippings();
        list = clippings.map((c) => MediaTrackingArticleModel(
          id: c.id,
          title: c.title,
          titleMarathi: c.titleMarathi,
          source: c.newspaper,
          sourceType: 'e_paper',
          date: c.date,
          time: '10:00 AM',
          sentiment: c.sentiment,
          personTracked: c.journalistName ?? 'Ward Corporator',
          url: c.imageUrl,
          summary: c.description,
          summaryMarathi: c.descriptionMarathi,
          reachEstimate: 15000,
          isSavedToClipping: true,
          keywords: [c.newspaper, '#Prabhag'],
        )).toList();
      } catch (_) {}
    }

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
    return const [];
  }

  Future<bool> saveToClipping(String id) async {
    return true;
  }

  Future<void> addArticle(MediaTrackingArticleModel article) async {}

  Future<void> deleteArticle(String id) async {}
}
