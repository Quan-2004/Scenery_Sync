import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_models.dart';

// Deezer API không cần authentication - dễ dùng hơn Spotify cho development
class DeezerService {
  static const String _baseUrl = 'https://api.deezer.com';

  static final DeezerService _instance = DeezerService._internal();
  factory DeezerService() => _instance;
  DeezerService._internal();

  // Tìm kiếm bài hát
  Future<List<Track>> searchTracks(String query, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=$query&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['data'] as List;
        return tracks.map((json) => Track.fromDeezerJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching tracks: $e');
      return [];
    }
  }

  // Lấy chart (top tracks)
  Future<List<Track>> getChartTracks({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chart/0/tracks?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['data'] as List;
        return tracks.map((json) => Track.fromDeezerJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting chart tracks: $e');
      return [];
    }
  }

  // Lấy thông tin track
  Future<Track?> getTrack(String trackId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/track/$trackId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Track.fromDeezerJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting track: $e');
      return null;
    }
  }

  // Lấy top tracks của artist
  Future<List<Track>> getArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/artist/$artistId/top?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['data'] as List;
        return tracks.map((json) => Track.fromDeezerJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting artist top tracks: $e');
      return [];
    }
  }

  // Lấy tracks từ playlist
  Future<List<Track>> getPlaylistTracks(
    String playlistId, {
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/playlist/$playlistId/tracks?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['data'] as List;
        return tracks.map((json) => Track.fromDeezerJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting playlist tracks: $e');
      return [];
    }
  }

  // Lấy tracks theo genre
  Future<List<Track>> getGenreTracks(String genreId, {int limit = 20}) async {
    try {
      // Lấy artists của genre
      final response = await http.get(
        Uri.parse('$_baseUrl/genre/$genreId/artists?limit=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final artists = data['data'] as List;

        if (artists.isEmpty) return [];

        // Lấy top tracks của artist đầu tiên
        final firstArtistId = artists[0]['id'].toString();
        return await getArtistTopTracks(firstArtistId, limit: limit);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting genre tracks: $e');
      return [];
    }
  }

  // Lấy radio tracks (similar to track)
  Future<List<Track>> getRadioTracks(String trackId, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/track/$trackId/radio?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['data'] as List;
        return tracks.map((json) => Track.fromDeezerJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting radio tracks: $e');
      return [];
    }
  }

  // Lấy top artists từ chart Deezer
  Future<List<Artist>> getChartArtists({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chart/0/artists?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final artists = data['data'] as List;
        return artists.map((json) => Artist.fromDeezerJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting chart artists: $e');
      return [];
    }
  }

  // Lấy tracks theo album
  Future<List<Track>> getAlbumTracks(String albumId, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/album/$albumId/tracks?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['data'] as List;
        // Album track list doesn't include full track info, need to enrich
        return tracks.map((t) {
          // artist may be nested differently
          final artistName = t['artist']?['name'] ?? '';
          final artistId = t['artist']?['id']?.toString() ?? '';
          return Track(
            id: t['id']?.toString() ?? '',
            name: t['title'] ?? 'Unknown',
            artistName: artistName.isNotEmpty ? artistName : 'Unknown Artist',
            artistId: artistId,
            albumName: '',
            albumId: albumId,
            imageUrl: '',
            previewUrl: t['preview'],
            durationMs: (t['duration'] ?? 0) * 1000,
            popularity: t['rank'] ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting album tracks: $e');
      return [];
    }
  }
}
