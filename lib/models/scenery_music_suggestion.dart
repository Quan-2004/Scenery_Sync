class SceneryDetectionResult {
  final String atmosphere;
  final String mood;
  final List<String> detectedElements;
  final String timeOfDay;
  final double confidenceScore;

  const SceneryDetectionResult({
    required this.atmosphere,
    required this.mood,
    required this.detectedElements,
    required this.timeOfDay,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'atmosphere': atmosphere,
      'mood': mood,
      'detectedElements': detectedElements,
      'timeOfDay': timeOfDay,
      'confidenceScore': confidenceScore,
    };
  }

  factory SceneryDetectionResult.fromJson(Map<String, dynamic> json) {
    return SceneryDetectionResult(
      atmosphere: json['atmosphere'] as String? ?? 'Unknown',
      mood: json['mood'] as String? ?? 'Neutral',
      detectedElements:
          (json['detectedElements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timeOfDay: json['timeOfDay'] as String? ?? 'Day',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MusicSuggestion {
  final String trackId;
  final String title;
  final String artist;
  final String albumCover;
  final String previewUrl;
  final int duration;
  final String genre;
  final int bpm;
  final double matchScore;

  const MusicSuggestion({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.albumCover,
    required this.previewUrl,
    required this.duration,
    required this.genre,
    required this.bpm,
    required this.matchScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'trackId': trackId,
      'title': title,
      'artist': artist,
      'albumCover': albumCover,
      'previewUrl': previewUrl,
      'duration': duration,
      'genre': genre,
      'bpm': bpm,
      'matchScore': matchScore,
    };
  }

  factory MusicSuggestion.fromJson(Map<String, dynamic> json) {
    return MusicSuggestion(
      trackId: json['trackId'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Track',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      albumCover: json['albumCover'] as String? ?? '',
      previewUrl: json['previewUrl'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      genre: json['genre'] as String? ?? 'Unknown',
      bpm: json['bpm'] as int? ?? 120,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
