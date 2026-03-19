import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for admin-only Firestore operations.
/// All methods assume the currently signed-in user has role == 'admin'.
/// Server-side enforcement is handled by firestore.rules.
class AdminService {
  AdminService._internal();
  static final AdminService instance = AdminService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────
  // USER MANAGEMENT
  // ──────────────────────────────────────────

  /// Stream of all users ordered by creation date.
  Stream<List<Map<String, dynamic>>> usersStream({int limit = 100}) {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'uid': doc.id, ...doc.data()})
            .toList());
  }

  /// Ban a user account.
  Future<String?> banUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({'status': 'banned'});
      return null;
    } catch (e) {
      debugPrint('AdminService.banUser error: $e');
      return 'Failed to ban user: $e';
    }
  }

  /// Unban a previously banned user.
  Future<String?> unbanUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({'status': 'active'});
      return null;
    } catch (e) {
      debugPrint('AdminService.unbanUser error: $e');
      return 'Failed to unban user: $e';
    }
  }

  // ──────────────────────────────────────────
  // ARTIST MANAGEMENT
  // ──────────────────────────────────────────

  /// List all pending artist requests.
  Stream<List<Map<String, dynamic>>> pendingArtistRequestsStream() {
    return _db
        .collection('artist_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'uid': doc.id, ...doc.data()})
            .toList());
  }

  /// Stream of all users with role == 'artist'.
  Stream<List<Map<String, dynamic>>> artistsStream({int limit = 100}) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'artist')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'uid': doc.id, ...doc.data()})
            .toList());
  }

  /// Approve an artist request — sets role to 'artist' and removes request doc.
  Future<String?> approveArtist(String uid) async {
    try {
      final batch = _db.batch();
      batch.update(_db.collection('users').doc(uid), {
        'role': 'artist',
        'artistVerified': true,
        'artistApprovedAt': FieldValue.serverTimestamp(),
      });
      batch.delete(_db.collection('artist_requests').doc(uid));
      await batch.commit();
      return null;
    } catch (e) {
      debugPrint('AdminService.approveArtist error: $e');
      return 'Failed to approve artist: $e';
    }
  }

  /// Revoke artist role — demotes back to regular user.
  Future<String?> revokeArtist(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'role': 'user',
        'artistVerified': false,
      });
      return null;
    } catch (e) {
      debugPrint('AdminService.revokeArtist error: $e');
      return 'Failed to revoke artist: $e';
    }
  }

  // ──────────────────────────────────────────
  // TRACK MANAGEMENT
  // ──────────────────────────────────────────

  /// Stream of ALL tracks (admin sees hidden ones too).
  Stream<List<Map<String, dynamic>>> allTracksStream({int limit = 200}) {
    return _db
        .collection('tracks')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Soft-hide a track (admin action).
  /// Sets isHidden = true, hiddenBy = 'admin'.
  Future<String?> hideTrack(String trackId) async {
    try {
      await _db.collection('tracks').doc(trackId).update({
        'isHidden': true,
        'hiddenBy': 'admin',
        'hiddenAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      debugPrint('AdminService.hideTrack error: $e');
      return 'Failed to hide track: $e';
    }
  }

  /// Restore a hidden track (admin action).
  Future<String?> unhideTrack(String trackId) async {
    try {
      await _db.collection('tracks').doc(trackId).update({
        'isHidden': false,
        'hiddenBy': FieldValue.delete(),
        'hiddenAt': FieldValue.delete(),
      });
      return null;
    } catch (e) {
      debugPrint('AdminService.unhideTrack error: $e');
      return 'Failed to unhide track: $e';
    }
  }

  // ──────────────────────────────────────────
  // DASHBOARD STATS
  // ──────────────────────────────────────────

  /// Get top detected keywords from admin_keyword_reports (for dashboard chart).
  Future<List<Map<String, dynamic>>> getTopKeywords({int limit = 15}) async {
    try {
      final snap = await _db
          .collection('admin_keyword_reports')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      // Aggregate keyword counts across reports
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final keywords = doc.data()['keywords'];
        if (keywords is List) {
          for (final k in keywords) {
            final key = k.toString();
            counts[key] = (counts[key] ?? 0) + 1;
          }
        }
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(limit)
          .map((e) => {'keyword': e.key, 'count': e.value})
          .toList();
    } catch (e) {
      debugPrint('AdminService.getTopKeywords error: $e');
      return [];
    }
  }

  /// Get aggregate counts for the dashboard (users, artists, tracks, plays).
  Future<Map<String, int>> getDashboardCounts() async {
    try {
      final results = await Future.wait([
        _db.collection('users').where('role', isEqualTo: 'user').count().get(),
        _db
            .collection('users')
            .where('role', isEqualTo: 'artist')
            .count()
            .get(),
        _db.collection('tracks').where('status', isEqualTo: 'published').count().get(),
        _db.collection('tracks').where('isHidden', isEqualTo: true).count().get(),
      ]);

      return {
        'totalUsers': results[0].count ?? 0,
        'totalArtists': results[1].count ?? 0,
        'totalTracks': results[2].count ?? 0,
        'hiddenTracks': results[3].count ?? 0,
      };
    } catch (e) {
      debugPrint('AdminService.getDashboardCounts error: $e');
      return {
        'totalUsers': 0,
        'totalArtists': 0,
        'totalTracks': 0,
        'hiddenTracks': 0,
      };
    }
  }
}
