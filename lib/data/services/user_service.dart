import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';

class UserService {
  UserService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'users';

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Create Firestore user document right after registration.
  Future<void> createUserProfile(
    User user, {
    required String displayName,
    String? photoUrl,
    String? bio,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(user.uid).set({
      'displayName': displayName,
      'email': user.email ?? '',
      'bio': bio ?? '',
      'photoUrl': photoUrl ?? user.photoURL ?? '',
      'dailyReviewHour': 2,
      'timezone': DateTime.now().timeZoneName,
      'pushToken': '',
      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// Lấy hồ sơ user theo uid.
  Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      debugPrint('getUserById error: $e');
      return null;
    }
  }

  /// Read current user profile once.
  Future<AppUser?> getCurrentUser() async {
    final uid = _currentUserId;
    if (uid == null) return null;
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Stream current user profile for real-time updates.
  Stream<AppUser?> streamCurrentUser() {
    final uid = _currentUserId;
    if (uid == null) return const Stream.empty();
    return _firestore.collection(_collection).doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromFirestore(doc) : null,
        );
  }

  /// Update profile fields in Firestore and mirror basic fields to FirebaseAuth.
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? photoUrl,
    String? email,
  }) async {
    final uid = _currentUserId;
    final user = _auth.currentUser;
    if (uid == null || user == null) throw Exception('User not authenticated');

    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (email != null) data['email'] = email;

    await _firestore.collection(_collection).doc(uid).set(data, SetOptions(merge: true));

    try {
      if (displayName != null) await user.updateDisplayName(displayName);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      if (email != null && email != user.email) await user.updateEmail(email);
    } catch (e) {
      debugPrint('Auth profile update failed: $e');
    }
  }
}
