import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_models.dart';

class DownloadsService {
  DownloadsService._internal();
  static final DownloadsService instance = DownloadsService._internal();
  final Dio _dio = Dio();

  static const _boxName = 'downloads';

  Box<Map> get _box => Hive.box<Map>(_boxName);

  Map<String, dynamic> _trackToMap(Track t) => {
        'id': t.id,
        'name': t.name,
        'artistName': t.artistName,
        'artistId': t.artistId,
        'albumName': t.albumName,
        'albumId': t.albumId,
        'imageUrl': t.imageUrl,
        'previewUrl': t.previewUrl,
        'localPath': t.localPath,
        'durationMs': t.durationMs,
        'popularity': t.popularity,
      };

  Track _mapToTrack(Map raw) {
    final e = Map<String, dynamic>.from(raw);
    return Track(
      id: e['id'] ?? '',
      name: e['name'] ?? '',
      artistName: e['artistName'] ?? '',
      artistId: e['artistId'] ?? '',
      albumName: e['albumName'] ?? '',
      albumId: e['albumId'] ?? '',
      imageUrl: e['imageUrl'] ?? '',
      previewUrl: e['previewUrl'],
      localPath: e['localPath'],
      isDownloaded: true,
      durationMs: e['durationMs'] ?? 0,
      popularity: e['popularity'] ?? 0,
    );
  }

  List<Track> getDownloadedTracks() {
    return _box.values.map(_mapToTrack).toList();
  }

  bool isDownloaded(String trackId) => _box.containsKey(trackId);

  Future<Track?> downloadTrack(Track track) async {
    if (track.previewUrl == null || track.previewUrl!.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final dlDir = Directory('${dir.path}/downloads');
    if (!await dlDir.exists()) await dlDir.create(recursive: true);
    final file = File('${dlDir.path}/${track.id}.mp3');
    final resp = await _dio.download(track.previewUrl!, file.path);
    if (resp.statusCode == 200) {
      final updated = track.copyWith(localPath: file.path, isDownloaded: true);
      await _box.put(track.id, _trackToMap(updated));
      return updated;
    }
    return null;
  }

  Future<void> deleteTrack(Track track) async {
    if (track.localPath != null) {
      final file = File(track.localPath!);
      if (await file.exists()) await file.delete();
    }
    await _box.delete(track.id);
  }
}
