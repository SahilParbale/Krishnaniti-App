import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
    if (clean.startsWith('http://') ||
        clean.startsWith('https://') ||
        clean.startsWith('data:') ||
        clean.startsWith('blob:')) {
      return clean;
    }

    try {
      String targetBucket = bucket;
      String targetPath = clean;

      // Strip leading slashes
      while (targetPath.startsWith('/')) {
        targetPath = targetPath.substring(1);
      }

      // Automatically identify bucket prefix if embedded in the path
      if (targetPath.startsWith('documents/')) {
        targetBucket = 'documents';
        targetPath = targetPath.substring('documents/'.length);
      } else if (targetPath.startsWith('app-assets/')) {
        targetBucket = 'app-assets';
        targetPath = targetPath.substring('app-assets/'.length);
      } else if (targetPath.contains('complaints/') || targetPath.contains('letters/')) {
        targetBucket = 'documents';
      }

      return client.storage.from(targetBucket).getPublicUrl(targetPath);
    } catch (_) {
      return clean;
    }
  }

  /// Asynchronously creates a signed URL for private buckets (e.g. 'documents')
  /// Mirrors web version's SecureStorageService.getUrl
  Future<String> getSignedStorageUrl(
    String? pathOrUrl, {
    String bucket = 'documents',
    int expiresInSeconds = 3600,
  }) async {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return '';
    String clean = pathOrUrl.trim();

    // 1. If it is already a signed URL with active token, return directly
    if (clean.contains('/object/sign/') && clean.contains('token=')) {
      return clean;
    }

    // 2. If it is a public URL pointing to Supabase storage, extract bucket & path
    if (clean.contains('/storage/v1/object/public/')) {
      final parts = clean.split('/storage/v1/object/public/');
      if (parts.length > 1) {
        final afterPublic = parts[1].split('?').first;
        final slashIndex = afterPublic.indexOf('/');
        if (slashIndex != -1) {
          bucket = afterPublic.substring(0, slashIndex);
          clean = afterPublic.substring(slashIndex + 1);
        } else {
          clean = afterPublic;
        }
      }
    } else if (clean.startsWith('http://') ||
        clean.startsWith('https://') ||
        clean.startsWith('data:') ||
        clean.startsWith('blob:')) {
      // Non-Supabase external URL (e.g. external CDN or blob)
      return clean;
    }

    // 3. Clean path: remove query parameters and slashes
    String targetPath = clean.split('?').first;
    while (targetPath.startsWith('/')) {
      targetPath = targetPath.substring(1);
    }
    if (targetPath.startsWith('public/')) {
      targetPath = targetPath.substring('public/'.length);
    }
    if (targetPath.startsWith('documents/')) {
      bucket = 'documents';
      targetPath = targetPath.substring('documents/'.length);
    } else if (targetPath.startsWith('app-assets/')) {
      bucket = 'app-assets';
      targetPath = targetPath.substring('app-assets/'.length);
    }

    final tenant = activeTenantId ?? AppConfig.defaultTenantId;

    // 4. Build candidate paths to test
    final candidates = <String>[];
    void addCandidate(String c) {
      final trimmed = c.trim();
      if (trimmed.isNotEmpty && !candidates.contains(trimmed)) {
        candidates.add(trimmed);
      }
    }

    addCandidate(targetPath);
    if (!targetPath.contains('/')) {
      // Bare filename e.g. "1000068947.jpg"
      addCandidate('$tenant/files/complaints/$targetPath');
      addCandidate('$tenant/complaints/$targetPath');
      addCandidate('$tenant/$targetPath');
      addCandidate('files/complaints/$targetPath');
      addCandidate('complaints/$targetPath');
      addCandidate('default/files/complaints/$targetPath');
      addCandidate('default/complaints/$targetPath');
    } else if (!targetPath.startsWith(tenant) && !targetPath.startsWith('default')) {
      addCandidate('$tenant/$targetPath');
    }

    // 5. Try signing with Supabase client across candidate paths and buckets
    final bucketsToTry = [bucket, bucket == 'documents' ? 'app-assets' : 'documents'];
    for (final b in bucketsToTry) {
      for (final c in candidates) {
        try {
          final signed = await client.storage.from(b).createSignedUrl(c, expiresInSeconds);
          if (signed.isNotEmpty) {
            if (signed.startsWith('http')) return signed;
            return '${AppConfig.supabaseUrl}/storage/v1$signed';
          }
        } catch (_) {}
      }
    }

    // 6. Direct HTTP fallback using anonKey in case client auth session is null/expired
    for (final b in bucketsToTry) {
      for (final c in candidates) {
        try {
          final uri = Uri.parse('${AppConfig.supabaseUrl}/storage/v1/object/sign/$b/$c');
          final response = await http.post(
            uri,
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'expiresIn': expiresInSeconds}),
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final signedUrl = data['signedURL'] ?? data['signedUrl'];
            if (signedUrl != null) {
              final str = signedUrl.toString();
              return str.startsWith('http') ? str : '${AppConfig.supabaseUrl}/storage/v1$str';
            }
          }
        } catch (_) {}
      }
    }

    // 7. If everything failed, fallback to public URL (transitional)
    return resolveStorageUrl(pathOrUrl, bucket: bucket);
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
