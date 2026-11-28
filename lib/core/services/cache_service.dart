import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:path_provider/path_provider.dart';

/// Service to calculate and safely clear temporary app caches across mobile and desktop.
///
/// This cleans:
/// - In-memory image cache (RAM)
/// - Temporary files (generated report PDFs, cropped images, picker buffers)
/// - Application cache directory files
///
/// NOTE: This NEVER touches Supabase data, user login sessions, credentials, or saved settings.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  /// Calculates the total cache size in bytes.
  Future<int> getCacheSizeBytes() async {
    int totalBytes = 0;

    // 1. Add Flutter in-memory image cache size
    try {
      totalBytes += PaintingBinding.instance.imageCache.currentSizeBytes;
    } catch (_) {}

    // 2. On Web, disk directories are not available
    if (kIsWeb) {
      return totalBytes;
    }

    // 3. Scan temporary directory
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        totalBytes += await _getDirSize(tempDir);
      }
    } catch (_) {}

    // 4. Scan application cache directory (if supported on platform)
    try {
      final appCacheDir = await getApplicationCacheDirectory();
      if (await appCacheDir.exists()) {
        totalBytes += await _getDirSize(appCacheDir);
      }
    } catch (_) {}

    return totalBytes;
  }

  /// Returns human-readable formatted cache size (e.g. "24.5 MB", "520 KB", "0.0 MB").
  Future<String> getFormattedCacheSize() async {
    final bytes = await getCacheSizeBytes();
    return formatBytes(bytes);
  }

  /// Clears in-memory image cache and temporary directory files safely.
  /// Returns the number of bytes freed.
  Future<int> clearCache() async {
    final initialBytes = await getCacheSizeBytes();

    // 1. Flush in-memory image cache
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}

    // 2. If Web, return immediately
    if (kIsWeb) {
      return initialBytes;
    }

    // 3. Safely delete temporary directory files
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await _deleteDirectoryContents(tempDir);
      }
    } catch (_) {}

    // 4. Safely delete application cache directory files
    try {
      final appCacheDir = await getApplicationCacheDirectory();
      if (await appCacheDir.exists()) {
        await _deleteDirectoryContents(appCacheDir);
      }
    } catch (_) {}

    return initialBytes;
  }

  /// Helper to calculate directory size recursively
  Future<int> _getDirSize(Directory dir) async {
    int size = 0;
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return size;
  }

  /// Helper to delete directory contents safely
  Future<void> _deleteDirectoryContents(Directory dir) async {
    try {
      final entities = dir.listSync(recursive: false, followLinks: false);
      for (final entity in entities) {
        try {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        } catch (_) {
          // File might be locked or currently in use by the OS, safe to skip
        }
      }
    } catch (_) {}
  }

  /// Format raw byte count into readable String
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0.0 MB';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double dBytes = bytes.toDouble();
    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }
    // If less than 1 MB, show in KB or MB
    if (i == 0) return '${dBytes.toInt()} B';
    return '${dBytes.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
