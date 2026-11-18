import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_config.dart';
import '../../core/services/supabase_service.dart';

final barCustomizationRepoProvider = Provider<BarCustomizationRepository>((ref) {
  return BarCustomizationRepository();
});

class BarCustomizationRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _activeTenantId =>
      SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;

  static const String _prefBottomSlots = 'custom_bottom_bar_slots';
  static const String _prefQuickSlots = 'custom_quick_action_slots_v5';

  /// Loads bar customization from Supabase DB (tenants.config).
  /// Falls back to local SharedPreferences if offline or not found.
  Future<({List<String>? bottomSlots, List<String>? quickSlots})> loadFromDatabase({
    String? userId,
    bool isStaff = false,
  }) async {
    List<String>? remoteBottom;
    List<String>? remoteQuick;

    try {
      final tenantId = _activeTenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        final res = await _client
            .from('tenants')
            .select('config')
            .eq('id', tenantId)
            .maybeSingle();

        if (res != null && res['config'] != null) {
          final config = res['config'] is Map
              ? Map<String, dynamic>.from(res['config'] as Map)
              : (res['config'] is String
                  ? Map<String, dynamic>.from(jsonDecode(res['config'] as String) as Map)
                  : <String, dynamic>{});

          // Check if this user is a staff member with personalized bar slots
          if (isStaff && userId != null && config['staff_bar_customizations'] is Map) {
            final staffMap = Map<String, dynamic>.from(config['staff_bar_customizations'] as Map);
            if (staffMap[userId] is Map) {
              final userCustom = Map<String, dynamic>.from(staffMap[userId] as Map);
              if (userCustom['bottom_bar'] is List) {
                remoteBottom = (userCustom['bottom_bar'] as List).map((e) => e.toString()).toList();
              }
              if (userCustom['quick_actions'] is List) {
                remoteQuick = (userCustom['quick_actions'] as List).map((e) => e.toString()).toList();
              }
            }
          }

          // Fallback to tenant-level custom slots
          if (remoteBottom == null && config['custom_bottom_bar_slots'] is List) {
            remoteBottom = (config['custom_bottom_bar_slots'] as List).map((e) => e.toString()).toList();
          }
          if (remoteQuick == null && config['custom_quick_action_slots'] is List) {
            remoteQuick = (config['custom_quick_action_slots'] as List).map((e) => e.toString()).toList();
          }
        }
      }
    } catch (_) {
      // Network or RLS failure, keep remote as null to fallback to local storage
    }

    // Cache to local storage if loaded from DB
    if (remoteBottom != null && remoteBottom.isNotEmpty) {
      await _cacheBottomSlots(remoteBottom);
    }
    if (remoteQuick != null && remoteQuick.isNotEmpty) {
      await _cacheQuickSlots(remoteQuick);
    }

    return (bottomSlots: remoteBottom, quickSlots: remoteQuick);
  }

  /// Saves bar customization to the Supabase database (tenants.config)
  /// and updates local SharedPreferences cache.
  Future<void> saveToDatabase({
    List<String>? bottomSlots,
    List<String>? quickSlots,
    String? userId,
    bool isStaff = false,
  }) async {
    // 1. Immediately cache locally
    if (bottomSlots != null) {
      await _cacheBottomSlots(bottomSlots);
    }
    if (quickSlots != null) {
      await _cacheQuickSlots(quickSlots);
    }

    // 2. Persist to Supabase Database
    try {
      final tenantId = _activeTenantId;
      if (tenantId == null || tenantId.isEmpty) return;

      // Fetch existing config to merge
      final res = await _client
          .from('tenants')
          .select('config')
          .eq('id', tenantId)
          .maybeSingle();

      Map<String, dynamic> currentConfig = {};
      if (res != null && res['config'] != null) {
        if (res['config'] is Map) {
          currentConfig = Map<String, dynamic>.from(res['config'] as Map);
        } else if (res['config'] is String) {
          currentConfig = Map<String, dynamic>.from(jsonDecode(res['config'] as String) as Map);
        }
      }

      if (isStaff && userId != null) {
        // Staff-specific customization
        Map<String, dynamic> staffCustomizations = {};
        if (currentConfig['staff_bar_customizations'] is Map) {
          staffCustomizations = Map<String, dynamic>.from(currentConfig['staff_bar_customizations'] as Map);
        }
        Map<String, dynamic> userRecord = {};
        if (staffCustomizations[userId] is Map) {
          userRecord = Map<String, dynamic>.from(staffCustomizations[userId] as Map);
        }

        if (bottomSlots != null) userRecord['bottom_bar'] = bottomSlots;
        if (quickSlots != null) userRecord['quick_actions'] = quickSlots;

        staffCustomizations[userId] = userRecord;
        currentConfig['staff_bar_customizations'] = staffCustomizations;
      } else {
        // Admin / Tenant-level customization
        if (bottomSlots != null) {
          currentConfig['custom_bottom_bar_slots'] = bottomSlots;
        }
        if (quickSlots != null) {
          currentConfig['custom_quick_action_slots'] = quickSlots;
        }
      }

      await _client
          .from('tenants')
          .update({'config': currentConfig})
          .eq('id', tenantId);
    } catch (_) {
      // Safe non-blocking: local storage is already updated
    }
  }

  Future<void> _cacheBottomSlots(List<String> slots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefBottomSlots, slots);
    } catch (_) {}
  }

  Future<void> _cacheQuickSlots(List<String> slots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefQuickSlots, slots);
    } catch (_) {}
  }

  Future<List<String>?> getLocalBottomSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_prefBottomSlots);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> getLocalQuickSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_prefQuickSlots);
    } catch (_) {
      return null;
    }
  }

  /// Queries tenant_feature_overrides table to retrieve per-tenant feature toggle matrix (matching TenantContext.tsx)
  Future<Map<String, bool>> getTenantFeatureOverrides() async {
    try {
      final tenantId = _activeTenantId;
      if (tenantId == null || tenantId.isEmpty) return {};

      final res = await _client
          .from('tenant_feature_overrides')
          .select('is_enabled, features!inner(feature_key)')
          .eq('tenant_id', tenantId);

      final Map<String, bool> overrides = {};
      for (final row in res as List<dynamic>) {
        final feat = row['features'];
        if (feat is Map && feat['feature_key'] != null) {
          overrides[feat['feature_key'].toString()] = row['is_enabled'] == true;
        }
      }
      return overrides;
    } catch (_) {
      return {};
    }
  }

}
