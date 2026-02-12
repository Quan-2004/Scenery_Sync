/// Cloudinary configuration.
///
/// This project uses *unsigned uploads* for avatars so we don't ship secrets in the app.
class CloudinaryConfig {
  static const String cloudName = 'dvcebine7';
  static const String uploadPreset = 'scenery_upload';

  /// Optional separate preset for audio uploads (Cloudinary treats audio as `resource_type=video`).
  /// If not provided, falls back to `CLOUDINARY_UPLOAD_PRESET`.
  static const String audioUploadPreset = String.fromEnvironment(
    'CLOUDINARY_AUDIO_UPLOAD_PRESET',
    defaultValue: 'scenery_upload',
  );

  /// Optional separate preset for track cover images.
  /// If not provided, falls back to `CLOUDINARY_UPLOAD_PRESET`.
  static const String trackCoverUploadPreset = String.fromEnvironment(
    'CLOUDINARY_TRACK_COVER_UPLOAD_PRESET',
    defaultValue: 'scenery_upload',
  );

  /// Optional separate preset for lyrics (raw/auto resource type).
  /// If not provided, falls back to `CLOUDINARY_UPLOAD_PRESET`.
  static const String lyricUploadPreset = String.fromEnvironment(
    'CLOUDINARY_LYRIC_UPLOAD_PRESET',
    defaultValue: 'scenery_upload',
  );

  static const String avatarFolder = String.fromEnvironment(
    'CLOUDINARY_AVATAR_FOLDER',
    defaultValue: 'avatars',
  );

  static const String audioFolder = String.fromEnvironment(
    'CLOUDINARY_AUDIO_FOLDER',
    defaultValue: 'audio',
  );

  static const String trackCoverFolder = String.fromEnvironment(
    'CLOUDINARY_TRACK_COVER_FOLDER',
    defaultValue: 'track_covers',
  );

  static const String lyricFolder = String.fromEnvironment(
    'CLOUDINARY_LYRIC_FOLDER',
    defaultValue: 'lyrics',
  );

  static bool get isConfigured =>
      cloudName.trim().isNotEmpty && uploadPreset.trim().isNotEmpty;

  static String get effectiveAudioUploadPreset {
    final preset = audioUploadPreset.trim();
    return preset.isNotEmpty ? preset : uploadPreset.trim();
  }

  static String get effectiveTrackCoverUploadPreset {
    final preset = trackCoverUploadPreset.trim();
    return preset.isNotEmpty ? preset : uploadPreset.trim();
  }

  static String get effectiveLyricUploadPreset {
    final preset = lyricUploadPreset.trim();
    return preset.isNotEmpty ? preset : uploadPreset.trim();
  }

  static bool get isAudioConfigured =>
      cloudName.trim().isNotEmpty && effectiveAudioUploadPreset.isNotEmpty;
}
