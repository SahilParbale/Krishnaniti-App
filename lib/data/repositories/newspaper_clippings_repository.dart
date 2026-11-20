import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/newspaper_clipping_model.dart';

final newspaperClippingsRepoProvider =
    Provider<NewspaperClippingsRepository>((ref) {
  return NewspaperClippingsRepository();
});

class NewspaperClippingsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<NewspaperClippingModel>> getClippings({
    String? sentiment,
    String? newspaper,
    String? query,
  }) async {
    try {
      var dbQuery = _client.from('gallery').select('*').eq('category', 'Newspaper');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (sentiment != null && sentiment.isNotEmpty && sentiment != 'all') {
        dbQuery = dbQuery.eq('sentiment', sentiment);
      }

      final response = await dbQuery.order('date', ascending: false);
      final rawList = response as List<dynamic>;

      final List<NewspaperClippingModel> list = [];
      for (final item in rawList) {
        final map = Map<String, dynamic>.from(item as Map);
        final rawImg = map['image_url']?.toString() ?? '';
        if (rawImg.isNotEmpty) {
          map['image_url'] = SupabaseService.instance.resolveStorageUrl(rawImg);
        }
        list.add(NewspaperClippingModel.fromJson(map));
      }

      var filtered = list;
      if (newspaper != null && newspaper.isNotEmpty && newspaper != 'all') {
        filtered = filtered
            .where((c) => c.newspaper.toLowerCase() == newspaper.toLowerCase())
            .toList();
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        filtered = filtered.where((c) {
          return c.title.toLowerCase().contains(q) ||
              c.titleMarathi.toLowerCase().contains(q) ||
              c.newspaper.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q) ||
              c.descriptionMarathi.toLowerCase().contains(q);
        }).toList();
      }

      return filtered;
    } catch (_) {
      return [];
    }
  }

  Future<NewspaperClippingModel?> getClippingById(String id) async {
    try {
      var query = _client.from('gallery').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;

      final map = Map<String, dynamic>.from(response);
      final rawImg = map['image_url']?.toString() ?? '';
      if (rawImg.isNotEmpty) {
        map['image_url'] = SupabaseService.instance.resolveStorageUrl(rawImg);
      }
      return NewspaperClippingModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<NewspaperClippingModel> addClipping(NewspaperClippingModel clipping) async {
    final effectiveTitle = clipping.title.isNotEmpty ? clipping.title : clipping.titleMarathi;
    final effectiveDesc = clipping.newspaper.isNotEmpty
        ? '[${clipping.newspaper}] ${clipping.description.isNotEmpty ? clipping.description : clipping.descriptionMarathi}'
        : (clipping.description.isNotEmpty ? clipping.description : clipping.descriptionMarathi);

    final payload = {
      'title': effectiveTitle,
      'category': 'Newspaper',
      'date': clipping.date,
      'sentiment': clipping.sentiment,
      'image_url': clipping.imageUrl,
      'description': effectiveDesc,
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _client.from('gallery').insert(payload).select().single();
    return NewspaperClippingModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<NewspaperClippingModel> updateClipping(NewspaperClippingModel clipping) async {
    final effectiveTitle = clipping.title.isNotEmpty ? clipping.title : clipping.titleMarathi;
    final effectiveDesc = clipping.newspaper.isNotEmpty
        ? '[${clipping.newspaper}] ${clipping.description.isNotEmpty ? clipping.description : clipping.descriptionMarathi}'
        : (clipping.description.isNotEmpty ? clipping.description : clipping.descriptionMarathi);

    final payload = {
      'title': effectiveTitle,
      'date': clipping.date,
      'sentiment': clipping.sentiment,
      'image_url': clipping.imageUrl,
      'description': effectiveDesc,
      'updated_at': DateTime.now().toIso8601String(),
    };

    var query = _client.from('gallery').update(payload).eq('id', clipping.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return clipping;
  }

  Future<bool> deleteClipping(String id) async {
    try {
      var query = _client.from('gallery').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final list = await getClippings();
    final total = list.length;
    final positive = list.where((c) => c.isPositive).length;
    final negative = list.where((c) => !c.isPositive).length;
    final positivePct = total > 0 ? ((positive / total) * 100).round() : 0;

    return {
      'total': total,
      'positive': positive,
      'negative': negative,
      'positivePct': positivePct,
    };
  }
}
