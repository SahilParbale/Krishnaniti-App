import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/gallery_model.dart';

class GalleryRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  final Set<String> _localFavorites = {};
  final Map<String, int> _localViews = {};

  Future<List<GalleryItemModel>> getGalleryItems({GalleryCategory? category}) async {
    try {
      var query = _client.from('gallery').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      if (category != null) {
        query = query.eq('category', category.id);
      }

      final cacheKey = 'gallery_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = query;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('date', ascending: false);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      final rawList = response as List<dynamic>;

      final List<GalleryItemModel> items = [];
      for (final item in rawList) {
        final map = Map<String, dynamic>.from(item as Map);
        final rawImg = map['image_url']?.toString() ?? '';
        if (rawImg.isNotEmpty) {
          map['image_url'] = SupabaseService.instance.resolveStorageUrl(rawImg);
        }
        final id = map['id']?.toString() ?? '';
        final model = GalleryItemModel.fromJson(map);
        items.add(model.copyWith(
          isFavorite: _localFavorites.contains(id) ? true : model.isFavorite,
          viewsCount: model.viewsCount + (_localViews[id] ?? 0),
        ));
      }

      return items;
    } catch (_) {
      return [];
    }
  }

  Future<GalleryItemModel?> getGalleryItemById(String id) async {
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
      return GalleryItemModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<GalleryItemModel> addGalleryItem(GalleryItemModel item) async {
    final payload = item.toJson(tenantId: _tenantId);
    final res = await _client.from('gallery').insert(payload).select().single();
    return GalleryItemModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<GalleryItemModel> updateGalleryItem(GalleryItemModel item) async {
    final payload = item.toJson(tenantId: _tenantId);
    var query = _client.from('gallery').update(payload).eq('id', item.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return item;
  }

  Future<void> deleteGalleryItem(String id) async {
    try {
      var query = _client.from('gallery').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  Future<bool> toggleFavorite(String id) async {
    if (_localFavorites.contains(id)) {
      _localFavorites.remove(id);
      return false;
    } else {
      _localFavorites.add(id);
      return true;
    }
  }

  void incrementViews(String id) {
    _localViews[id] = (_localViews[id] ?? 0) + 1;
  }
}

final galleryRepoProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository();
});
