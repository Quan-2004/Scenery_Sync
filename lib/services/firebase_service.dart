import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // User Properties
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userId => _auth.currentUser?.uid;
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;
  String? get userPhotoUrl => _auth.currentUser?.photoURL;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

  FirebaseService() {
    // Listen to auth state changes to notify listeners
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _fetchUserProfile();
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _userProfile = doc.data();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }
    }
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
      await _fetchUserProfile(); // Fetch profile after login

      return null; // Success (no error message)
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.message}');
      return e.message ?? 'An unknown error occurred';
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return 'Failed to sign in with Google';
    }
  }

  // Facebook Sign-In
  Future<String?> loginWithFacebook() async {
    try {
      // 1. Trigger Facebook Sign-In flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: [
          'public_profile',
          'email',
          'user_birthday',
          'user_gender',
        ],
      );

      if (result.status != LoginStatus.success) {
        return 'Facebook login was cancelled or failed';
      }

      // 2. Get the access token
      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        return 'Failed to get Facebook access token';
      }

      // 3. Create a Facebook credential
      final OAuthCredential credential = FacebookAuthProvider.credential(
        accessToken.token,
      );

      // 4. Sign in to Firebase with the Facebook credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // 5. Fetch Facebook user data (for high-res image)
      final userData = await FacebookAuth.instance.getUserData(
        fields: "name,email,picture.width(400)",
      );

      if (userCredential.user != null) {
        String? name = userData['name'];
        String? photoUrl = userData['picture']?['data']?['url'];

        // Update Firebase User Profile if data exists
        if (name != null || photoUrl != null) {
          await userCredential.user!.updateDisplayName(name);
          await userCredential.user!.updatePhotoURL(photoUrl);
          await userCredential.user!
              .reload(); // Reload to apply changes locally

          // Ensure Firestore document exists
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'name': name ?? '',
            'email': userCredential.user!.email ?? '',
            'photoUrl': photoUrl ?? '',
            // Facebook might return birthday/gender if asked/permitted, but we simplify here
          }, SetOptions(merge: true));

          notifyListeners(); // Notify UI to update
        }
      }

      await _fetchUserProfile();

      return null; // Success (no error message)
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.message}');
      return e.message ?? 'An unknown error occurred';
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      return 'Failed to sign in with Facebook';
    }
  }

  // Email/Password Login
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _fetchUserProfile();
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
        // Create initial Firestore doc
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _fetchUserProfile();

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
    _userProfile = null;
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email';
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to change password';
    } catch (e) {
      return 'An error occurred';
    }
  }

  List<String> get linkedProviders {
    return _auth.currentUser?.providerData.map((e) => e.providerId).toList() ??
        [];
  }

  // ==========================================================
  // STUBS for Firestore Data (To be implemented later)
  // ==========================================================

  // User Profile Stubs
  Future<String?> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';

      // Update Auth Profile if name/photo changed
      if (data.containsKey('name')) {
        await user.updateDisplayName(data['name']);
      }
      if (data.containsKey('photoUrl')) {
        await user.updatePhotoURL(data['photoUrl']);
      }

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      // Refresh local profile
      await _fetchUserProfile();

      return null;
    } catch (e) {
      return 'Failed to update profile: $e';
    }
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
