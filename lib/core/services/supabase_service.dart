import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_config.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  String? _activeTenantId = AppConfig.defaultTenantId;

  String? get activeTenantId => _activeTenantId;

  void setActiveTenant(String? tenantId) {
    _activeTenantId = tenantId ?? AppConfig.defaultTenantId;
  }

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
}
