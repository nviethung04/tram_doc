import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.createdAt,
    this.lastLoginAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// Lấy tất cả users
  Future<List<AppUser>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Lấy user theo ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Cập nhật hoặc tạo user profile khi login
  Future<bool> updateUserProfile(
    String userId,
    String email, {
    String? displayName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(userId).set({
        'email': email,
        'displayName': displayName,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Đếm tổng số users
  Future<int> getUsersCount() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting users count: $e');
      return 0;
    }
  }

  /// Tìm kiếm user theo email
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where(
            (user) =>
                user.email.toLowerCase().contains(query.toLowerCase()) ||
                (user.displayName?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
