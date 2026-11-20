import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nagarsevak_mobile/core/constants/app_config.dart';

Future<String> testSignLogic(String pathOrUrl, {String bucket = 'documents'}) async {
  if (pathOrUrl.isEmpty) return '';
  String clean = pathOrUrl.trim();

  if (clean.contains('/object/sign/') && clean.contains('token=')) {
    return clean;
  }

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
  }

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

  print('Resolving targetPath: $targetPath in bucket: $bucket');

  final tenant = AppConfig.defaultTenantId;
  final candidates = <String>[];
  void addCandidate(String c) {
    if (c.isNotEmpty && !candidates.contains(c)) candidates.add(c);
  }

  addCandidate(targetPath);
  if (!targetPath.contains('/')) {
    addCandidate('$tenant/files/complaints/$targetPath');
    addCandidate('$tenant/complaints/$targetPath');
    addCandidate('$tenant/$targetPath');
    addCandidate('files/complaints/$targetPath');
    addCandidate('complaints/$targetPath');
  }

  final bucketsToTry = [bucket, bucket == 'documents' ? 'app-assets' : 'documents'];
  for (final b in bucketsToTry) {
    for (final c in candidates) {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/storage/v1/object/sign/$b/$c');
      final res = await http.post(
        uri,
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'expiresIn': 3600}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final signed = data['signedURL'] ?? data['signedUrl'];
        if (signed != null) {
          final full = signed.toString().startsWith('http')
              ? signed.toString()
              : '${AppConfig.supabaseUrl}/storage/v1$signed';
          return full;
        }
      }
    }
  }

  return clean;
}

void main() async {
  // Test public URL conversion
  final testPublic = 'https://qdvciisgxvupvrjygedr.supabase.co/storage/v1/object/public/documents/test.jpg';
  final res = await testSignLogic(testPublic);
  print('Result for public URL: $res');
}
