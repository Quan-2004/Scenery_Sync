import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_models.dart';

/// Jamendo API - nhạc không lời, Creative Commons, full song
/// Đăng ký tại: https://devportal.jamendo.com
class JamendoService {
  // TODO: Thay YOUR_CLIENT_ID bằng client_id lấy từ devportal.jamendo.com
  static const String _clientId = '675bd2b4';
  static const String _baseUrl = 'https://api.jamendo.com/v3.0';

  static final JamendoService _instance = JamendoService._internal();
  factory JamendoService() => _instance;
  JamendoService._internal();

  bool get isConfigured => _clientId != 'YOUR_CLIENT_ID';

  /// Tìm nhạc không lời theo tags (ví dụ: 'ambient', 'nature', 'cinematic')
  Future<List<Track>> getInstrumentalTracks({
    required List<String> tags,
    int limit = 10,
  }) async {
    if (!isConfigured) {
      debugPrint('⚠️ JamendoService: chưa cấu hình client_id');
      return [];
    }

    try {
      final tagParam = tags.join('+');
      final uri = Uri.parse(
        '$_baseUrl/tracks/'
        '?client_id=$_clientId'
        '&format=json'
        '&limit=$limit'
        '&tags=$tagParam'
        '&audioformat=mp32'
        '&include=musicinfo'
        '&order=popularity_total_desc',
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results
            .map((t) => _trackFromJamendo(t))
            .where((t) => t.previewUrl != null && t.previewUrl!.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('JamendoService error: $e');
      return [];
    }
  }

  /// Tìm nhạc theo keyword tự do
  Future<List<Track>> searchInstrumental(
    String query, {
    int limit = 10,
  }) async {
    if (!isConfigured) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl/tracks/'
        '?client_id=$_clientId'
        '&format=json'
        '&limit=$limit'
        '&search=$query'
        '&audioformat=mp32'
        '&order=popularity_total_desc',
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results
            .map((t) => _trackFromJamendo(t))
            .where((t) => t.previewUrl != null && t.previewUrl!.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('JamendoService searchInstrumental error: $e');
      return [];
    }
  }

  Track _trackFromJamendo(Map<String, dynamic> t) {
    return Track(
      id: t['id']?.toString() ?? '',
      name: t['name'] ?? 'Unknown',
      artistName: t['artist_name'] ?? 'Unknown Artist',
      artistId: t['artist_id']?.toString() ?? '',
      albumName: t['album_name'] ?? '',
      albumId: t['album_id']?.toString() ?? '',
      imageUrl: t['album_image'] ?? t['image'] ?? '',
      previewUrl: t['audio'] ?? '', // full song URL
      durationMs: ((t['duration'] ?? 0) * 1000).toInt(),
      popularity: (t['popularity_total'] ?? 0).toInt(),
    );
  }
}
