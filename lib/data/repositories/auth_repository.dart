import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_config.dart';
import '../../core/services/supabase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  UserModel? _mockSession;

  static const String _sessionStorageKey = 'nagarsevak_active_session_v1';

  UserModel? get mockSession => _mockSession;

  /// Restores any persisted session on app launch
  Future<UserModel?> restorePersistedSession() async {
    // 1. Check live Supabase Auth session first
    final currentSupabaseUser = _client.auth.currentUser;
    if (currentSupabaseUser != null) {
      try {
        final profile = await loadUserProfile(currentSupabaseUser);
        return profile;
      } catch (_) {
        // Fallback to local cached profile if offline
      }
    }

    // 2. Check local persistent storage for demo or cached sessions
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionStorageKey);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final map = jsonDecode(sessionJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(map);
        _mockSession = user;
        if (user.tenantId != null && user.tenantId!.isNotEmpty) {
          SupabaseService.instance.setActiveTenant(user.tenantId);
        }
        return user;
      }
    } catch (_) {}

    return null;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
    String? role,
    bool isStaff = false,
  }) async {
    String cleanEmail = email.trim().toLowerCase();

    // Map common role keywords/usernames to their official demo accounts
    if (cleanEmail == 'demo_nagarsevak' ||
        cleanEmail == 'nagarsevak' ||
        cleanEmail == 'admin' ||
        cleanEmail == 'demo') {
      cleanEmail = 'demo_nagarsevak@demo.com';
    } else if (cleanEmail == 'staff_prabhag12' ||
        cleanEmail == 'staff' ||
        cleanEmail == 'karyakarta') {
      cleanEmail = 'staff_prabhag12@demo.com';
    } else if (cleanEmail == 'amdar_demo' || cleanEmail == 'amdar') {
      cleanEmail = 'amdar_demo@krishnaniti.in';
    } else if (cleanEmail == 'khasdar_demo' || cleanEmail == 'khasdar') {
      cleanEmail = 'khasdar_demo@krishnaniti.in';
    } else if (cleanEmail == 'minister_demo' || cleanEmail == 'minister') {
      cleanEmail = 'minister_demo@krishnaniti.in';
    }

    // 1. Built-in demo accounts matching Nagarsevak-Managment AuthContext.tsx
    // Demo accounts allow testing without separate Supabase Auth signups
    final isDemoAccount = cleanEmail == 'demo_nagarsevak@demo.com' ||
        cleanEmail == 'staff_prabhag12@demo.com' ||
        cleanEmail == 'amdar_demo@krishnaniti.in' ||
        cleanEmail == 'khasdar_demo@krishnaniti.in' ||
        cleanEmail == 'minister_demo@krishnaniti.in' ||
        cleanEmail == 'admin@ns.com' ||
        cleanEmail == 'staff@ns.com' ||
        cleanEmail == 'voter@ns.com';

    if (isDemoAccount) {
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

      // The Krishnaniti demo tenant UUID in database
      const demoTenantId = AppConfig.defaultTenantId;
      SupabaseService.instance.setActiveTenant(demoTenantId);

      // Attempt live Supabase Auth login for demo_nagarsevak in background for valid JWT
      if (cleanEmail == 'demo_nagarsevak@demo.com') {
        try {
          await _client.auth.signInWithPassword(
            email: 'demo_nagarsevak@demo.com',
            password: 'Password@123',
          );
        } catch (_) {
          // Offline or network error - offline mock session continues safely
        }
      }

      final user = UserModel(
        id: (cleanEmail == 'demo_nagarsevak@demo.com')
            ? '3cf3d997-c0f7-4f69-8e70-a0f938f6e088'
            : 'demo-user-id',
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
        tenantId: demoTenantId,
      );

      _mockSession = user;
      await _persistSession(user);
      return user;
    }

    // 2. Real Supabase Authentication
    // Connects to live Supabase backend sharing exact credentials with web app
    final response = await _client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Authentication failed. User session is null.');
    }

    final profile = await loadUserProfile(user);

    // 3. Log successful login to login_logs table (matching web AuthContext)
    try {
      String osName = 'Unknown';
      if (kIsWeb) {
        osName = 'Web';
      } else {
        try {
          osName = Platform.isAndroid
              ? 'Android'
              : Platform.isIOS
                  ? 'iOS'
                  : Platform.operatingSystem;
        } catch (_) {
          osName = 'Mobile';
        }
      }

      await _client.from('login_logs').insert({
        'user_id': user.id,
        'email': user.email,
        'device_type': kIsWeb ? 'Web' : 'Mobile',
        'browser': kIsWeb ? 'Browser' : 'Flutter Mobile App',
        'os': osName,
        'user_agent': 'Krishnaniti-Mobile/1.0.0',
        'tenant_id': profile.tenantId,
        'status': 'success'
      });
    } catch (_) {
      // Non-blocking for login flow
    }

    await _persistSession(profile);
    return profile;
  }

  Future<UserModel> loadUserProfile(User sessionUser) async {
    Map<String, dynamic>? staffRes;
    Map<String, dynamic>? mappingRes;

    // 1. Fetch staff record if exists (safely catch any RLS/missing table error)
    try {
      staffRes = await _client
          .from('staff')
          .select('id, role, permissions, can_assign_work')
          .eq('id', sessionUser.id)
          .maybeSingle();
    } catch (_) {}

    // 2. Fetch role & tenant_id from user_tenant_mapping
    try {
      mappingRes = await _client
          .from('user_tenant_mapping')
          .select('role, tenant_id')
          .eq('user_id', sessionUser.id)
          .maybeSingle();
    } catch (_) {}

    final dbRole = mappingRes?['role'] ?? (staffRes != null ? 'staff' : 'nagarsevak');
    final tenantId = mappingRes?['tenant_id'] ?? SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;

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

  Future<void> _persistSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionStorageKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> signOut() async {
    _mockSession = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionStorageKey);
    } catch (_) {}

    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  User? get currentAuthUser => _client.auth.currentUser;
}
