import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_models.dart';

class DownloadsService {
  DownloadsService._internal();
  static final DownloadsService instance = DownloadsService._internal();
  final Dio _dio = Dio();

  Future<Directory> _getDownloadsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final dl = Directory('${dir.path}/downloads');
    if (!await dl.exists()) {
      await dl.create(recursive: true);
    }
    return dl;
  }

  Future<File> _getIndexFile() async {
    final dir = await _getDownloadsDir();
    return File('${dir.path}/downloads.json');
  }

  Future<List<Track>> getDownloadedTracks() async {
    final indexFile = await _getIndexFile();
    if (!await indexFile.exists()) return [];
    final jsonStr = await indexFile.readAsString();
    final data = json.decode(jsonStr) as List<dynamic>;
    return data.map((e) => Track(
          id: e['id'],
          name: e['name'],
          artistName: e['artistName'],
          artistId: e['artistId'],
          albumName: e['albumName'],
          albumId: e['albumId'],
          imageUrl: e['imageUrl'],
          previewUrl: e['previewUrl'],
          localPath: e['localPath'],
          isDownloaded: true,
          durationMs: e['durationMs'] ?? 0,
          popularity: e['popularity'] ?? 0,
        )).toList();
  }

  Future<Track?> downloadTrack(Track track) async {
    if (track.previewUrl == null || track.previewUrl!.isEmpty) return null;
    final dir = await _getDownloadsDir();
    final file = File('${dir.path}/${track.id}.mp3');
    final resp = await _dio.download(track.previewUrl!, file.path);
    if (resp.statusCode == 200) {
      final updated = track.copyWith(localPath: file.path, isDownloaded: true);
      await _saveTrack(updated);
      return updated;
    }
    return null;
  }

  Future<void> _saveTrack(Track track) async {
    final indexFile = await _getIndexFile();
    final current = await getDownloadedTracks();
    final existsIndex = current.indexWhere((t) => t.id == track.id);
    if (existsIndex >= 0) {
      current[existsIndex] = track;
    } else {
      current.add(track);
    }
    final payload = current
        .map((t) => {
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
            })
        .toList();
    await indexFile.writeAsString(json.encode(payload));
  }

  Future<void> deleteTrack(Track track) async {
    final dir = await _getDownloadsDir();
    final file = File('${dir.path}/${track.id}.mp3');
    if (await file.exists()) {
      await file.delete();
    }
    final indexFile = await _getIndexFile();
    final current = await getDownloadedTracks();
    current.removeWhere((t) => t.id == track.id);
    final payload = current.map((t) => {
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
        }).toList();
    await indexFile.writeAsString(json.encode(payload));
  }
}
