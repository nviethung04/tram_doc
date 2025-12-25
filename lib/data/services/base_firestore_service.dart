import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Base service class cho các Firestore services
abstract class BaseFirestoreService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  BaseFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => auth.currentUser?.uid;

  /// Kiểm tra user đã authenticated chưa
  void requireAuth() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
  }

  /// Lấy collection reference
  CollectionReference collection(String collectionName) {
    return firestore.collection(collectionName);
  }

  /// Lấy document reference
  DocumentReference document(String collectionName, String documentId) {
    return firestore.collection(collectionName).doc(documentId);
  }
}


