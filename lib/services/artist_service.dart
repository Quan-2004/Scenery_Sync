import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'cloudinary_service.dart';

/// Service for artist-only operations.
/// All write operations enforce that ownerId == current user UID.
class ArtistService {
  ArtistService._internal();
  static final ArtistService instance = ArtistService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinary = const CloudinaryService();

  String? get _uid => _auth.currentUser?.uid;

  // ──────────────────────────────────────────
  // TRACK MANAGEMENT
  // ──────────────────────────────────────────

  /// Stream of tracks owned by the current artist.
  Stream<List<Map<String, dynamic>>> myTracksStream() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('tracks')
        .where('ownerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Upload a new track to Cloudinary then save metadata to Firestore.
  ///
  /// Returns the Firestore document ID on success, or null on failure.
  Future<String?> uploadTrack({
    required Uint8List audioBytes,
    required String filename,
    required Uint8List? coverBytes,
    required String title,
    required String genre,
    String? albumName,
    String? lyrics,
    int durationMs = 0,
  }) async {
    if (_uid == null) return null;

    try {
      // 1. Upload audio
      final audioResult = await _cloudinary.uploadAudio(
        bytes: audioBytes,
        filename: filename,
        publicId: '${_uid}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // 2. Upload cover if provided
      String coverUrl = '';
      if (coverBytes != null && coverBytes.isNotEmpty) {
        final coverResult = await _cloudinary.uploadTrackCover(bytes: coverBytes);
        coverUrl = coverResult.secureUrl;
      }

      // 3. Save metadata to Firestore
      final docRef = await _db.collection('tracks').add({
        'title': title,
        'name': title, // support both schemas
        'artist': _auth.currentUser?.displayName ?? '',
        'artistName': _auth.currentUser?.displayName ?? '',
        'ownerId': _uid,
        'audioUrl': audioResult.secureUrl,
        'previewUrl': audioResult.secureUrl,
        'artworkUrl': coverUrl,
        'imageUrl': coverUrl,
        'albumName': albumName ?? '',
        'genre': genre,
        'lyrics': lyrics ?? '',
        'durationMs': durationMs,
        'popularity': 0,
        'status': 'published',
        'isHidden': false,
        'isPublic': true,
        'stats': {
          'playCount': 0,
          'favoriteCount': 0,
          'sceneryMatchCount': 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('ArtistService.uploadTrack error: $e');
      return null;
    }
  }

  /// Update metadata of an owned track.
  Future<String?> updateTrackMetadata(
    String trackId,
    Map<String, dynamic> data,
  ) async {
    if (_uid == null) return 'Not authenticated';

    try {
      // Verify ownership
      final doc = await _db.collection('tracks').doc(trackId).get();
      if (!doc.exists || doc.data()?['ownerId'] != _uid) {
        return 'Not authorized to edit this track';
      }

      await _db.collection('tracks').doc(trackId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      debugPrint('ArtistService.updateTrackMetadata error: $e');
      return 'Failed to update track: $e';
    }
  }

  /// Artist hides their own track.
  Future<String?> hideMyTrack(String trackId) async {
    return updateTrackMetadata(trackId, {
      'isHidden': true,
      'hiddenBy': 'artist',
    });
  }

  /// Artist unhides their own track (only if hiddenBy == 'artist').
  Future<String?> unhideMyTrack(String trackId) async {
    if (_uid == null) return 'Not authenticated';

    try {
      final doc = await _db.collection('tracks').doc(trackId).get();
      final data = doc.data();
      if (data == null || data['ownerId'] != _uid) {
        return 'Not authorized';
      }
      // Cannot unhide if admin hid it
      if (data['hiddenBy'] == 'admin') {
        return 'This track was hidden by an admin and cannot be restored by you';
      }
      await _db.collection('tracks').doc(trackId).update({
        'isHidden': false,
        'hiddenBy': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      debugPrint('ArtistService.unhideMyTrack error: $e');
      return 'Failed to unhide track: $e';
    }
  }

  // ──────────────────────────────────────────
  // ANALYTICS
  // ──────────────────────────────────────────

  /// Get analytics summary for all tracks owned by the current artist.
  Future<Map<String, dynamic>> getMyAnalyticsSummary() async {
    if (_uid == null) return {};

    try {
      final snap = await _db
          .collection('tracks')
          .where('ownerId', isEqualTo: _uid)
          .get();

      int totalPlays = 0;
      int totalFavorites = 0;
      int totalSceneryMatches = 0;
      final List<Map<String, dynamic>> trackStats = [];

      for (final doc in snap.docs) {
        final data = doc.data();
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        final plays = (stats['playCount'] as num?)?.toInt() ?? 0;
        final favs = (stats['favoriteCount'] as num?)?.toInt() ?? 0;
        final scenery = (stats['sceneryMatchCount'] as num?)?.toInt() ?? 0;

        totalPlays += plays;
        totalFavorites += favs;
        totalSceneryMatches += scenery;

        trackStats.add({
          'id': doc.id,
          'title': data['title'] ?? data['name'] ?? 'Unknown',
          'imageUrl': data['imageUrl'] ?? data['artworkUrl'] ?? '',
          'playCount': plays,
          'favoriteCount': favs,
          'sceneryMatchCount': scenery,
          'isHidden': data['isHidden'] ?? false,
          'hiddenBy': data['hiddenBy'],
        });
      }

      // Sort by plays desc
      trackStats.sort((a, b) =>
          (b['playCount'] as int).compareTo(a['playCount'] as int));

      return {
        'totalPlays': totalPlays,
        'totalFavorites': totalFavorites,
        'totalSceneryMatches': totalSceneryMatches,
        'totalTracks': snap.docs.length,
        'tracks': trackStats,
      };
    } catch (e) {
      debugPrint('ArtistService.getMyAnalyticsSummary error: $e');
      return {};
    }
  }

  /// Apply to become an artist.
  Future<String?> applyForArtistRole({
    required String artistName,
    String? companyName,
    String? bio,
  }) async {
    if (_uid == null) return 'Not authenticated';

    try {
      await _db.collection('artist_requests').doc(_uid).set({
        'uid': _uid,
        'email': _auth.currentUser?.email,
        'displayName': _auth.currentUser?.displayName ?? artistName,
        'artistName': artistName,
        'companyName': companyName ?? '',
        'bio': bio ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      debugPrint('ArtistService.applyForArtistRole error: $e');
      return 'Failed to submit request: $e';
    }
  }
}
