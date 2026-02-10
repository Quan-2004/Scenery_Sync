import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });
}

class CloudinaryService {
  const CloudinaryService();

  static Uri _uploadUri() {
    final cloudName = CloudinaryConfig.cloudName.trim();
    return Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
  }

  static Uri _audioUploadUri() {
    final cloudName = CloudinaryConfig.cloudName.trim();
    // Cloudinary handles audio files under the `video` resource type.
    return Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');
  }

  /// Uploads avatar bytes using an *unsigned* upload preset.
  ///
  /// Notes:
  /// - Unsigned upload cannot securely delete assets from the client.
  /// - We set `public_id` to the user's uid so re-uploads overwrite the previous avatar.
  Future<CloudinaryUploadResult> uploadAvatar({
    required String uid,
    required Uint8List bytes,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw StateError(
        'Cloudinary chưa cấu hình. Hãy chạy app với --dart-define=CLOUDINARY_CLOUD_NAME=... '
        'và --dart-define=CLOUDINARY_UPLOAD_PRESET=... (upload preset unsigned).',
      );
    }

    final request = http.MultipartRequest('POST', _uploadUri())
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset.trim()
      ..fields['folder'] = CloudinaryConfig.avatarFolder.trim()
      ..fields['resource_type'] = 'image'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'avatar.jpg',
        ),
      );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      // Cloudinary error response includes JSON with `error.message`.
      try {
        final decoded = jsonDecode(body);
        final message = decoded is Map && decoded['error'] is Map
            ? (decoded['error']['message']?.toString() ?? 'Upload failed')
            : 'Upload failed';
        throw Exception('Cloudinary upload failed: $message');
      } catch (_) {
        throw Exception('Cloudinary upload failed (HTTP ${streamed.statusCode}): $body');
      }
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Cloudinary upload failed: invalid response');
    }

    final secureUrl = decoded['secure_url']?.toString();
    final publicId = decoded['public_id']?.toString();

    if (secureUrl == null || secureUrl.isEmpty || publicId == null || publicId.isEmpty) {
      throw Exception('Cloudinary upload failed: missing secure_url/public_id');
    }

    return CloudinaryUploadResult(secureUrl: secureUrl, publicId: publicId);
  }

  /// Uploads an audio file (mp3/m4a/wav/...) and returns a public HTTPS URL for streaming.
  ///
  /// Notes:
  /// - Cloudinary categorizes audio under `resource_type=video`.
  /// - For client-side uploads you should use an *unsigned* upload preset.
  Future<CloudinaryUploadResult> uploadAudio({
    required Uint8List bytes,
    required String filename,
    String? publicId,
  }) async {
    if (!CloudinaryConfig.isAudioConfigured) {
      throw StateError(
        'Cloudinary audio chưa cấu hình. Hãy chạy app với --dart-define=CLOUDINARY_CLOUD_NAME=... '
        'và --dart-define=CLOUDINARY_AUDIO_UPLOAD_PRESET=... (upload preset unsigned cho audio).',
      );
    }

    final request = http.MultipartRequest('POST', _audioUploadUri())
      ..fields['upload_preset'] = CloudinaryConfig.effectiveAudioUploadPreset
      ..fields['folder'] = CloudinaryConfig.audioFolder.trim()
      ..fields['resource_type'] = 'video';

    final trimmedPublicId = publicId?.trim();
    if (trimmedPublicId != null && trimmedPublicId.isNotEmpty) {
      request.fields['public_id'] = trimmedPublicId;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      try {
        final decoded = jsonDecode(body);
        final message = decoded is Map && decoded['error'] is Map
            ? (decoded['error']['message']?.toString() ?? 'Upload failed')
            : 'Upload failed';
        throw Exception('Cloudinary upload failed: $message');
      } catch (_) {
        throw Exception('Cloudinary upload failed (HTTP ${streamed.statusCode}): $body');
      }
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Cloudinary upload failed: invalid response');
    }

    final secureUrl = decoded['secure_url']?.toString();
    final returnedPublicId = decoded['public_id']?.toString();

    if (secureUrl == null || secureUrl.isEmpty || returnedPublicId == null || returnedPublicId.isEmpty) {
      throw Exception('Cloudinary upload failed: missing secure_url/public_id');
    }

    return CloudinaryUploadResult(secureUrl: secureUrl, publicId: returnedPublicId);
  }

  /// Uploads a track cover image (album art) to Cloudinary.
  ///
  /// This uploads to a separate folder (track_covers) to keep track artwork
  /// organized separately from user avatars.
  Future<CloudinaryUploadResult> uploadTrackCover({
    required Uint8List bytes,
    String? publicId,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw StateError(
        'Cloudinary chưa cấu hình. Hãy chạy app với --dart-define=CLOUDINARY_CLOUD_NAME=... '
        'và --dart-define=CLOUDINARY_UPLOAD_PRESET=... (upload preset unsigned).',
      );
    }

    final request = http.MultipartRequest('POST', _uploadUri())
      ..fields['upload_preset'] = CloudinaryConfig.effectiveTrackCoverUploadPreset
      ..fields['folder'] = CloudinaryConfig.trackCoverFolder.trim()
      ..fields['resource_type'] = 'image';

    final trimmedPublicId = publicId?.trim();
    if (trimmedPublicId != null && trimmedPublicId.isNotEmpty) {
      request.fields['public_id'] = trimmedPublicId;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'track_cover.jpg',
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      try {
        final decoded = jsonDecode(body);
        final message = decoded is Map && decoded['error'] is Map
            ? (decoded['error']['message']?.toString() ?? 'Upload failed')
            : 'Upload failed';
        throw Exception('Cloudinary upload failed: $message');
      } catch (_) {
        throw Exception('Cloudinary upload failed (HTTP ${streamed.statusCode}): $body');
      }
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Cloudinary upload failed: invalid response');
    }

    final secureUrl = decoded['secure_url']?.toString();
    final returnedPublicId = decoded['public_id']?.toString();

    if (secureUrl == null || secureUrl.isEmpty || returnedPublicId == null || returnedPublicId.isEmpty) {
      throw Exception('Cloudinary upload failed: missing secure_url/public_id');
    }

    return CloudinaryUploadResult(secureUrl: secureUrl, publicId: returnedPublicId);
  }
}
