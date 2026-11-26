import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_config.dart';
import '../../core/services/supabase_service.dart';
import '../models/tenant_model.dart';

class TenantRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Fetches a tenant by UUID.
  Future<TenantModel?> getTenantById(String tenantId) async {
    try {
      final res = await _client
          .from('tenants')
          .select('*')
          .eq('id', tenantId)
          .maybeSingle();

      if (res != null) {
        return TenantModel.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  /// Fetches default or demo tenant if specific ID fails or is not mapped.
  Future<TenantModel?> getFallbackTenant() async {
    try {
      final res = await _client
          .from('tenants')
          .select('*')
          .or('subdomain.eq.default,subdomain.eq.newnagarsevak,subdomain.eq.krishnaniti')
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return TenantModel.fromJson(res);
      }
    } catch (_) {}

    // In-memory baseline tenant for demo/offline resilience
    return const TenantModel(
      id: AppConfig.defaultTenantId,
      name: 'Krishnaniti Nagarsevak',
      subdomain: 'default',
      tier: 'nagarsevak',
      plan: 'advance',
      config: {
        'nagarsevak_name_english': 'Nagar Sevak Office',
        'nagarsevak_name_marathi': 'नगरसेवक कार्यालय',
        'ward_name': 'Prabhag 12',
        'party_name': 'Janata Party',
      },
    );
  }

  /// Fetches tenant-specific feature overrides.
  Future<Map<String, bool>> getFeatureOverrides(String tenantId) async {
    final overridesMap = <String, bool>{};
    try {
      final res = await _client
          .from('tenant_feature_overrides')
          .select('is_enabled, features!inner(feature_key)')
          .eq('tenant_id', tenantId);

      for (final row in res) {
        final isEnabled = row['is_enabled'] as bool? ?? false;
        final features = row['features'];
        if (features is Map && features['feature_key'] != null) {
          overridesMap[features['feature_key'].toString()] = isEnabled;
        }
      }
    } catch (_) {}
    return overridesMap;
  }

  /// Resolves the user's assigned tenant ID from user_tenant_mapping or staff table.
  Future<String?> getTenantIdForUser(String userId) async {
    try {
      final mapping = await _client
          .from('user_tenant_mapping')
          .select('tenant_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (mapping != null && mapping['tenant_id'] != null) {
        return mapping['tenant_id'].toString();
      }
    } catch (_) {}

    try {
      final staff = await _client
          .from('staff')
          .select('tenant_id')
          .eq('id', userId)
          .maybeSingle();

      if (staff != null && staff['tenant_id'] != null) {
        return staff['tenant_id'].toString();
      }
    } catch (_) {}

    return null;
  }
}
