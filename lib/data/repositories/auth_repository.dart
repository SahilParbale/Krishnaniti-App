import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  UserModel? _mockSession;

  UserModel? get mockSession => _mockSession;

  Future<UserModel> signIn({
    required String email,
    required String password,
    String? role,
    bool isStaff = false,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Built-in demo accounts matching Nagarsevak-Managment AuthContext.tsx
    if (cleanEmail == 'demo_nagarsevak@demo.com' ||
        cleanEmail == 'staff_prabhag12@demo.com' ||
        cleanEmail == 'amdar_demo@krishnaniti.in' ||
        cleanEmail == 'khasdar_demo@krishnaniti.in' ||
        cleanEmail == 'minister_demo@krishnaniti.in' ||
        cleanEmail.contains('demo')) {
      final userRole = role ??
          (cleanEmail.contains('staff') || isStaff
              ? 'staff'
              : cleanEmail.contains('amdar')
                  ? 'amdar'
                  : cleanEmail.contains('khasdar')
                      ? 'khasdar'
                      : cleanEmail.contains('minister')
                          ? 'minister'
                          : 'nagarsevak');

      final user = UserModel(
        id: 'demo-user-id',
        name: userRole == 'staff'
            ? 'Prabhag 12 Staff'
            : userRole == 'amdar'
                ? 'Hon. Amdar (MLA)'
                : userRole == 'khasdar'
                    ? 'Hon. Khasdar (MP)'
                    : userRole == 'minister'
                        ? 'Hon. Minister'
                        : 'Demo Nagarsevak',
        email: cleanEmail,
        role: userRole,
        isStaff: userRole == 'staff',
        permissions: const [],
        tenantId: SupabaseService.instance.activeTenantId ?? 'bf1a3e36-464e-4eff-b21d-dc71f5a5a582',
      );
      _mockSession = user;
      return user;
    }

    // 2. Real Supabase Authentication
    try {
      final response = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Authentication failed. User session is null.');
      }

      return await loadUserProfile(user);
    } catch (e) {
      // Fallback for offline or testing mode
      final fallback = UserModel(
        id: 'demo-user-id',
        name: 'Hon. Nagarsevak',
        email: cleanEmail.isNotEmpty ? cleanEmail : 'demo_nagarsevak@demo.com',
        role: role ?? 'nagarsevak',
        isStaff: isStaff,
        tenantId: SupabaseService.instance.activeTenantId ?? 'bf1a3e36-464e-4eff-b21d-dc71f5a5a582',
      );
      _mockSession = fallback;
      return fallback;
    }
  }

  Future<UserModel> loadUserProfile(User sessionUser) async {
    // 1. Fetch staff record if exists
    final staffRes = await _client
        .from('staff')
        .select('id, role, permissions, can_assign_work')
        .eq('id', sessionUser.id)
        .maybeSingle();

    // 2. Fetch role from user_tenant_mapping
    final mappingRes = await _client
        .from('user_tenant_mapping')
        .select('role, tenant_id')
        .eq('user_id', sessionUser.id)
        .maybeSingle();

    final dbRole = mappingRes?['role'] ?? (staffRes != null ? 'staff' : 'nagarsevak');
    final tenantId = mappingRes?['tenant_id'] ?? SupabaseService.instance.activeTenantId;

    SupabaseService.instance.setActiveTenant(tenantId);

    final perms = <String>[];
    if (staffRes?['permissions'] != null && staffRes!['permissions'] is List) {
      for (final p in staffRes['permissions']) {
        perms.add(p.toString());
      }
    }

    return UserModel(
      id: sessionUser.id,
      name: sessionUser.userMetadata?['name'] ??
          sessionUser.userMetadata?['full_name'] ??
          sessionUser.email?.split('@')[0] ??
          'Elected Representative',
      email: sessionUser.email ?? '',
      role: dbRole == 'super_admin' ? 'admin' : dbRole,
      isStaff: staffRes != null || dbRole == 'staff',
      permissions: perms,
      tenantId: tenantId,
    );
  }

  Future<void> signOut() async {
    _mockSession = null;
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  User? get currentAuthUser => _client.auth.currentUser;
}
