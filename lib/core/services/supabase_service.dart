import 'dart:io';
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

  static SupabaseClient? _fallbackClient;

  SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return _fallbackClient ??= SupabaseClient(
        AppConfig.supabaseUrl,
        AppConfig.supabaseAnonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  /// Resolves a stored storage path or URL to a valid loadable URL
  /// Mirrors web version's SecureStorageService.getUrl
  String resolveStorageUrl(String? pathOrUrl, {String bucket = 'app-assets'}) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return '';
    final clean = pathOrUrl.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    try {
      return client.storage.from(bucket).getPublicUrl(clean);
    } catch (_) {
      return clean;
    }
  }

  /// Asynchronously creates a signed URL for private buckets (e.g. 'documents')
  Future<String> getSignedStorageUrl(String pathOrUrl, {String bucket = 'documents', int expiresInSeconds = 3600}) async {
    if (pathOrUrl.trim().isEmpty) return '';
    final clean = pathOrUrl.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    try {
      final signedUrl = await client.storage.from(bucket).createSignedUrl(clean, expiresInSeconds);
      return signedUrl;
    } catch (_) {
      return resolveStorageUrl(pathOrUrl, bucket: bucket);
    }
  }

  /// Uploads a file to tenant-isolated storage path
  /// Format: {activeTenantId}/files/{module}/{uniqueId}
  /// Mirrors web version's SecureStorageService.uploadFile
  Future<String> uploadFile({
    required String bucket,
    required String module,
    required File file,
    String? customFileName,
  }) async {
    final tenant = activeTenantId ?? AppConfig.defaultTenantId;
    final fileExt = file.path.split('.').last;
    final uniqueId = customFileName ?? '${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecondsSinceEpoch % 10000)}.$fileExt';
    final relativePath = '$tenant/files/$module/$uniqueId';

    final bytes = await file.readAsBytes();
    await client.storage.from(bucket).uploadBinary(
      relativePath,
      bytes,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
      ),
    );

    return relativePath;
  }
}
