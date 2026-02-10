/// Cloudinary configuration.
///
/// This project uses *unsigned uploads* for avatars so we don't ship secrets in the app.
///
/// Provide values at build/run time using `--dart-define`:
///
/// - `CLOUDINARY_CLOUD_NAME`
/// - `CLOUDINARY_UPLOAD_PRESET`
/// - (optional) `CLOUDINARY_AUDIO_UPLOAD_PRESET` (default: CLOUDINARY_UPLOAD_PRESET)
/// - (optional) `CLOUDINARY_AVATAR_FOLDER` (default: avatars)
/// - (optional) `CLOUDINARY_AUDIO_FOLDER` (default: audio)
///
/// Example:
/// `flutter run -d windows --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy`
class CloudinaryConfig {
  static const String cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  /// Optional separate preset for audio uploads (Cloudinary treats audio as `resource_type=video`).
  /// If not provided, falls back to `CLOUDINARY_UPLOAD_PRESET`.
  static const String audioUploadPreset = String.fromEnvironment(
    'CLOUDINARY_AUDIO_UPLOAD_PRESET',
  );

  /// Optional separate preset for track cover images.
  /// If not provided, falls back to `CLOUDINARY_UPLOAD_PRESET`.
  static const String trackCoverUploadPreset = String.fromEnvironment(
    'CLOUDINARY_TRACK_COVER_UPLOAD_PRESET',
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

  static bool get isConfigured => cloudName.trim().isNotEmpty && uploadPreset.trim().isNotEmpty;

  static String get effectiveAudioUploadPreset {
    final preset = audioUploadPreset.trim();
    return preset.isNotEmpty ? preset : uploadPreset.trim();
  }

  static String get effectiveTrackCoverUploadPreset {
    final preset = trackCoverUploadPreset.trim();
    return preset.isNotEmpty ? preset : uploadPreset.trim();
  }

  static bool get isAudioConfigured => cloudName.trim().isNotEmpty && effectiveAudioUploadPreset.isNotEmpty;
}
