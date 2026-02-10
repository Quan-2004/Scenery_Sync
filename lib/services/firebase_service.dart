import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // User Properties
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userId => _auth.currentUser?.uid;
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;
  String? get userPhotoUrl => _auth.currentUser?.photoURL;

  // Compatibility stub
  final Map<String, dynamic>? _userProfile = null;
  Map<String, dynamic>? get userProfile => _userProfile;

  FirebaseService() {
    // Listen to auth state changes to notify listeners
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  // Google Sign-In
  Future<String?> loginWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled the sign-in

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);

      return null; // Success (no error message)
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.message}');
      return e.message ?? 'An unknown error occurred';
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return 'Failed to sign in with Google';
    }
  }

  // Email/Password Login
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Register with Email
  Future<String?> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      if (result.user != null) {
        await result.user!.updateDisplayName(name);
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Logout
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email';
    }
  }

  // ==========================================================
  // STUBS for Firestore Data (To be implemented later)
  // ==========================================================

  // User Profile Stubs
  Future<String?> updateUserProfile(Map<String, dynamic> data) async {
    debugPrint('Stub: updateUserProfile called');
    return null; // Simulate success
  }

  Future<String?> uploadAvatar(Uint8List bytes) async {
    debugPrint('Stub: uploadAvatar called');
    return null; // Simulate success
  }

  Future<String?> removeAvatar() async {
    debugPrint('Stub: removeAvatar called');
    return null;
  }

  // Favorites Stubs
  Future<void> addToFavorites(String trackId) async {
    debugPrint('Stub: addToFavorites $trackId');
  }

  Future<void> removeFromFavorites(String trackId) async {
    debugPrint('Stub: removeFromFavorites $trackId');
  }

  bool isFavorite(String trackId) {
    return false;
  }

  List<String> getFavorites() {
    return [];
  }

  // Recently Played Stubs
  Future<void> saveRecentlyPlayed(Map<String, dynamic> track) async {
    debugPrint('Stub: saveRecentlyPlayed called');
  }

  Stream<dynamic> getRecentlyPlayed() {
    return const Stream.empty();
  }

  // Playlist Stubs
  Future<String?> createPlaylist({
    required String name,
    String? description,
    String? coverImage,
  }) async {
    debugPrint('Stub: createPlaylist called');
    return null;
  }

  Stream<dynamic> getUserPlaylists() {
    return const Stream.empty();
  }

  Future<String?> addTrackToPlaylist(
    String playlistId,
    Map<String, dynamic> track,
  ) async {
    debugPrint('Stub: addTrackToPlaylist called');
    return null;
  }

  Future<String?> removeTrackFromPlaylist(
    String playlistId,
    Map<String, dynamic> track,
  ) async {
    debugPrint('Stub: removeTrackFromPlaylist called');
    return null;
  }

  Future<String?> deletePlaylist(String playlistId) async {
    debugPrint('Stub: deletePlaylist called');
    return null;
  }

  // Artist Stubs
  Future<void> followArtist(String artistId) async {
    debugPrint('Stub: followArtist called');
  }

  Future<void> unfollowArtist(String artistId) async {
    debugPrint('Stub: unfollowArtist called');
  }

  bool isFollowingArtist(String artistId) {
    return false;
  }

  // Tracks Management Stubs
  Future<List<Map<String, dynamic>>> getAllTracks({int limit = 50}) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> searchTracks(
    String query, {
    int limit = 30,
  }) async {
    return [];
  }

  Future<Map<String, dynamic>?> getTrackById(String trackId) async {
    return null;
  }

  Stream<List<Map<String, dynamic>>> tracksStream({int limit = 50}) {
    return Stream.value([]);
  }
}
