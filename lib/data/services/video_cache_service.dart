import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  final Map<String, String> _cache = {};

  /// Get cached video path, or download and cache if not exists
  Future<String?> getCachedVideoPath(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;

    // Check memory cache first
    if (_cache.containsKey(url)) {
      final localPath = _cache[url]!;
      if (await File(localPath).exists()) {
        return localPath;
      } else {
        _cache.remove(url);
      }
    }

    // Download and cache
    try {
      final localPath = await _downloadAndCache(url);
      if (localPath != null) {
        _cache[url] = localPath;
      }
      return localPath;
    } catch (e) {
      print('Video cache error: $e');
      return null;
    }
  }

  Future<String?> _downloadAndCache(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    // Create cache directory
    final cacheDir = await getTemporaryDirectory();
    final videoCacheDir = Directory('${cacheDir.path}/video_cache');
    if (!await videoCacheDir.exists()) {
      await videoCacheDir.create(recursive: true);
    }

    // Generate unique filename based on URL hash
    final urlHash = md5.convert(utf8.encode(url)).toString();
    final extension = _getExtension(url);
    final localPath = '${videoCacheDir.path}/$urlHash$extension';

    final file = File(localPath);
    await file.writeAsBytes(response.bodyBytes);

    return localPath;
  }

  String _getExtension(String url) {
    // Try to extract extension from URL
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final lastSegment = pathSegments.last;
      if (lastSegment.contains('.')) {
        final ext = lastSegment.split('.').last.toLowerCase();
        if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
          return '.$ext';
        }
      }
    }
    return '.mp4';
  }

  /// Clear all cached videos
  Future<void> clearCache() async {
    _cache.clear();
    final cacheDir = await getTemporaryDirectory();
    final videoCacheDir = Directory('${cacheDir.path}/video_cache');
    if (await videoCacheDir.exists()) {
      await videoCacheDir.delete(recursive: true);
    }
  }
}
