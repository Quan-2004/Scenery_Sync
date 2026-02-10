class Track {
  final String id;
  final String name;
  final String artistName;
  final String artistId;
  final String albumName;
  final String albumId;
  final String imageUrl;
  final String? previewUrl;
  final String? localPath; // path to downloaded file if available
  final bool isDownloaded;
  final int durationMs;
  final int popularity;

  Track({
    required this.id,
    required this.name,
    required this.artistName,
    required this.artistId,
    required this.albumName,
    required this.albumId,
    required this.imageUrl,
    this.previewUrl,
    this.localPath,
    this.isDownloaded = false,
    required this.durationMs,
    required this.popularity,
  });

  factory Track.fromDeezerJson(Map<String, dynamic> json) {
    return Track(
      id: json['id']?.toString() ?? '',
      name: json['title'] ?? 'Unknown',
      artistName: json['artist']?['name'] ?? 'Unknown Artist',
      artistId: json['artist']?['id']?.toString() ?? '',
      albumName: json['album']?['title'] ?? 'Unknown Album',
      albumId: json['album']?['id']?.toString() ?? '',
      imageUrl: json['album']?['cover_medium'] ?? '',
      previewUrl: json['preview'],
      localPath: null,
      isDownloaded: false,
      durationMs: (json['duration'] ?? 0) * 1000,
      popularity: json['rank'] ?? 0,
    );
  }

  /// Minimal Firestore schema supported (collection: `tracks`):
  /// - name: string
  /// - artistName: string
  /// - imageUrl: string
  /// - previewUrl: string (Cloudinary secure_url)
  /// Optional:
  /// - durationMs: number
  /// - popularity: number
  /// - albumName / albumId / artistId
  factory Track.fromFirestore(Map<String, dynamic> json, {required String id}) {
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String readString(dynamic value) => value?.toString() ?? '';

    return Track(
      id: id,
      name: readString(json['name']).isEmpty ? 'Unknown' : readString(json['name']),
      artistName: readString(json['artistName']).isEmpty ? 'Unknown Artist' : readString(json['artistName']),
      artistId: readString(json['artistId']),
      albumName: readString(json['albumName']),
      albumId: readString(json['albumId']),
      imageUrl: readString(json['imageUrl']),
      previewUrl: readString(json['previewUrl']).isEmpty ? null : readString(json['previewUrl']),
      localPath: null,
      isDownloaded: false,
      durationMs: readInt(json['durationMs']),
      popularity: readInt(json['popularity']),
    );
  }

  String get duration {
    final minutes = (durationMs / 60000).floor();
    final seconds = ((durationMs % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Track copyWith({
    String? localPath,
    bool? isDownloaded,
  }) {
    return Track(
      id: id,
      name: name,
      artistName: artistName,
      artistId: artistId,
      albumName: albumName,
      albumId: albumId,
      imageUrl: imageUrl,
      previewUrl: previewUrl,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      durationMs: durationMs,
      popularity: popularity,
    );
  }
}

class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> genres;
  final int followers;
  final int popularity;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.genres,
    required this.followers,
    required this.popularity,
  });

}

class Album {
  final String id;
  final String name;
  final String artistName;
  final String imageUrl;
  final String releaseDate;
  final int totalTracks;

  Album({
    required this.id,
    required this.name,
    required this.artistName,
    required this.imageUrl,
    required this.releaseDate,
    required this.totalTracks,
  });

}

class Playlist {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int tracksCount;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.tracksCount,
  });

}
