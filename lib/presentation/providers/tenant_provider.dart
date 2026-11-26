import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_config.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/feature_matrix.dart';
import '../../data/models/tenant_model.dart';
import '../../data/repositories/tenant_repository.dart';
import 'auth_provider.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository();
});

class TenantState {
  final TenantModel? tenant;
  final Map<String, bool> featureOverrides;
  final bool isLoading;
  final bool featureAccessReady;
  final String? lastFetchedUserId;

  const TenantState({
    this.tenant,
    this.featureOverrides = const {},
    this.isLoading = true,
    this.featureAccessReady = false,
    this.lastFetchedUserId,
  });

  TenantState copyWith({
    TenantModel? tenant,
    Map<String, bool>? featureOverrides,
    bool? isLoading,
    bool? featureAccessReady,
    String? lastFetchedUserId,
  }) {
    return TenantState(
      tenant: tenant ?? this.tenant,
      featureOverrides: featureOverrides ?? this.featureOverrides,
      isLoading: isLoading ?? this.isLoading,
      featureAccessReady: featureAccessReady ?? this.featureAccessReady,
      lastFetchedUserId: lastFetchedUserId ?? this.lastFetchedUserId,
    );
  }

  String get tier => tenant?.tier ?? 'nagarsevak';
  String get plan => tenant?.plan ?? 'basic';
  bool get isNagarsevak => tier == 'nagarsevak';
  bool get isAmdar => tier == 'amdar';
  bool get isKhasdar => tier == 'khasdar';
  bool get isMinister => tier == 'minister';

  /// Evaluates feature access matching web TenantContext.tsx hasFeature exactly
  bool hasFeature(String featureKey) {
    if (!featureAccessReady) {
      return false;
    }
    if (featureOverrides.containsKey(featureKey)) {
      return featureOverrides[featureKey]!;
    }
    return FeatureMatrix.checkFeatureAccess(featureKey, plan);
  }
}

class TenantNotifier extends Notifier<TenantState> {
  @override
  TenantState build() {
    // Re-fetch when current user profile changes
    final user = ref.watch(currentUserProvider);
    Future.microtask(() => _loadTenant(user?.id, user?.email, user?.tenantId));
    return const TenantState(isLoading: true, featureAccessReady: false);
  }

  Future<void> _loadTenant(String? userId, String? email, String? assignedTenantId) async {
    state = state.copyWith(isLoading: true, featureAccessReady: false);
    final repo = ref.read(tenantRepositoryProvider);

    final cleanEmail = (email ?? '').toLowerCase();
    final isDemo = cleanEmail == 'demo_nagarsevak@demo.com' ||
        cleanEmail.contains('demo') ||
        cleanEmail.contains('krishnaniti') ||
        userId == 'demo-krishnaniti-user';

    // In demo mode or quota restriction, immediately serve the in-memory advanced tenant
    if (isDemo) {
      const demoTenant = TenantModel(
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
      SupabaseService.instance.setActiveTenant(demoTenant.id);
      state = TenantState(
        tenant: demoTenant,
        featureOverrides: const {},
        isLoading: false,
        featureAccessReady: true,
        lastFetchedUserId: userId,
      );
      return;
    }

    try {
      String? targetTenantId;

      if (assignedTenantId != null && assignedTenantId.isNotEmpty) {
        targetTenantId = assignedTenantId;
      }

      if (targetTenantId == null && userId != null) {
        targetTenantId = await repo.getTenantIdForUser(userId);
      }

      targetTenantId ??= SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;

      TenantModel? tenant;
      if (targetTenantId.isNotEmpty) {
        tenant = await repo.getTenantById(targetTenantId);
      }

      tenant ??= await repo.getFallbackTenant();

      Map<String, bool> overrides = const {};
      if (tenant != null) {
        overrides = await repo.getFeatureOverrides(tenant.id);
        SupabaseService.instance.setActiveTenant(tenant.id);
      }

      state = TenantState(
        tenant: tenant,
        featureOverrides: overrides,
        isLoading: false,
        featureAccessReady: true,
        lastFetchedUserId: userId,
      );
    } catch (_) {
      final fallback = await repo.getFallbackTenant();
      state = TenantState(
        tenant: fallback,
        featureOverrides: const {},
        isLoading: false,
        featureAccessReady: true,
        lastFetchedUserId: userId,
      );
    }
  }

  Future<void> refreshTenant() async {
    final user = ref.read(currentUserProvider);
    await _loadTenant(user?.id, user?.email, user?.tenantId);
  }
}

final tenantProvider = NotifierProvider<TenantNotifier, TenantState>(TenantNotifier.new);
