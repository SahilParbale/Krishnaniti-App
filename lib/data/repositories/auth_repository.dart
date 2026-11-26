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
    // 1. Check local persistent storage for demo or cached sessions first
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

    // 2. Check live Supabase Auth session if no local session found
    try {
      final currentSupabaseUser = _client.auth.currentUser;
      if (currentSupabaseUser != null) {
        final profile = await loadUserProfile(currentSupabaseUser);
        return profile;
      }
    } catch (_) {
      // Fallback to local cached profile if offline
    }

    return null;
  }

  // Staff mobile number to registered email mapping for phone-based logins
  static const Map<String, String> _staffMobileToEmail = {
    '7977157629': 'abhijit1714@gmail.com',
    '9833948379': 'mane.mahendra1@gmail.com',
    '7977688328': 'mantrisachin12@gmail.com',
    '9876543210': 'soham@gmail.com',
    '8356017704': 'satishmore6810@gmail.com',
    '9833873707': 'sushilkumarkadam78@gmail.com',
    '8286272727': 'sherkhanesandy@gmail.com',
    '9773600736': 'shubham.k2001@gmail.com',
    '8839958350': 'raghvendra.mcu@gmail.com',
    '9167219955': 'nehalbakhai93@gmail.com',
    '8767152299': 'aghuge229@gmail.com',
    '6577577754': 'pranjall@gmail.com',
    '8446588526': 'sahilparbale777@gmail.com',
  };

  Future<UserModel> signIn({
    required String email,
    required String password,
    String? role,
    bool isStaff = false,
  }) async {
    String cleanIdentifier = email.trim();

    // If user enters a 10-digit mobile number or formatted mobile number, resolve to their email
    final digitsOnly = cleanIdentifier.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigit = digitsOnly.length >= 10
        ? digitsOnly.substring(digitsOnly.length - 10)
        : digitsOnly;
    if (_staffMobileToEmail.containsKey(tenDigit)) {
      cleanIdentifier = _staffMobileToEmail[tenDigit]!;
    }

    final cleanEmail = cleanIdentifier.toLowerCase();

    // Fast path: Demo accounts log in immediately without hitting Supabase Auth endpoint
    // Matches Nagarsevak-Managment/src/context/AuthContext.tsx lines 156-169 exactly
    final isDemoAccount = cleanEmail == 'demo_nagarsevak@demo.com' ||
        cleanEmail == 'krishnaniti@gmail.com' ||
        cleanEmail.contains('demo');

    if (isDemoAccount) {
      final selectedRole = role ?? 'nagarsevak';
      final mockUser = UserModel(
        id: 'demo-krishnaniti-user',
        name: cleanEmail.contains('krishnaniti') ? 'Krishnaniti Representative' : 'Demo Nagarsevak',
        email: cleanEmail,
        role: selectedRole,
        isStaff: isStaff,
        permissions: const [
          'all',
          'admin',
          'manage_staff',
          'manage_complaints',
          'daily_work',
          'ward_info',
          'municipal',
          'media',
          'programs',
          'political',
          'communication',
        ],
        tenantId: AppConfig.defaultTenantId,
      );
      _mockSession = mockUser;
      SupabaseService.instance.setActiveTenant(mockUser.tenantId);
      await _persistSession(mockUser);
      return mockUser;
    }

    try {
      // Authenticate with live Supabase GoTrue Auth
      final response = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Authentication failed. User session is null.');
      }

      final profile = await loadUserProfile(user);

      // Log successful login to login_logs table (matching web AuthContext)
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
    } catch (e) {
      final errStr = e.toString().toLowerCase();

      // Handle Supabase 402 Payment Required / quota exceed error cleanly
      if (errStr.contains('402') ||
          errStr.contains('payment required') ||
          errStr.contains('quota') ||
          errStr.contains('exceed_storage_size_quota')) {
        throw Exception(
          'Supabase project storage quota exceeded (402 Payment Required). '
          'The project owner must upgrade their plan or remove spend caps in the Supabase dashboard. '
          'You can sign in with the demo account (demo_nagarsevak@demo.com / Password@123) in the meantime.',
        );
      }

      if (errStr.contains('socket') ||
          errStr.contains('host lookup') ||
          errStr.contains('network') ||
          errStr.contains('errno = 7') ||
          errStr.contains('authretryablefetchexception') ||
          errStr.contains('clientexception')) {
        throw Exception(
          'Network connection error: Unable to reach server. Please check your internet connection.',
        );
      }
      rethrow;
    }
  }

  Future<UserModel> loadUserProfile(User sessionUser) async {
    Map<String, dynamic>? staffRes;
    Map<String, dynamic>? mappingRes;

    // 1. Fetch staff record if exists
    try {
      staffRes = await _client
          .from('staff')
          .select('id, role, permissions, can_assign_work, tenant_id')
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
    final tenantId = mappingRes?['tenant_id'] ??
        staffRes?['tenant_id'] ??
        SupabaseService.instance.activeTenantId ??
        AppConfig.defaultTenantId;

    SupabaseService.instance.setActiveTenant(tenantId);

    final perms = <String>[];
    if (staffRes?['permissions'] != null && staffRes!['permissions'] is List) {
      for (final p in staffRes['permissions']) {
        perms.add(p.toString());
      }
    }

    final resolvedRole = dbRole == 'super_admin' ? 'admin' : dbRole;

    return UserModel(
      id: sessionUser.id,
      name: sessionUser.userMetadata?['name'] ??
          sessionUser.userMetadata?['full_name'] ??
          sessionUser.email?.split('@')[0] ??
          'User',
      email: sessionUser.email ?? '',
      role: resolvedRole,
      isStaff: staffRes != null || resolvedRole == 'staff',
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
