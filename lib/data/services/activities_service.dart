import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity.dart';
import 'base_firestore_service.dart';

class ActivitiesService extends BaseFirestoreService {
  ActivitiesService({super.firestore, super.auth});

  CollectionReference get _activitiesCollection => collection('activities');
  DocumentReference<Map<String, dynamic>> _activityDoc(String activityId) {
    return _activitiesCollection.doc(activityId) as DocumentReference<Map<String, dynamic>>;
  }

  CollectionReference<Map<String, dynamic>> _likesCollection(String activityId) {
    return _activityDoc(activityId).collection('likes');
  }

  CollectionReference<Map<String, dynamic>> _commentsCollection(String activityId) {
    return _activityDoc(activityId).collection('comments');
  }

  /// T?o activity m?i
  Future<Activity> createActivity({
    required ActivityType type,
    String? bookId,
    String? bookTitle,
    String? bookAuthor,
    String? bookCoverUrl,
    String? userBookId,
    String? noteId,
    String? flashcardId,
    String? message,
    int? rating,
    bool isPublic = false,
    String? visibility,
  }) async {
    requireAuth();
    try {
      final now = DateTime.now();
      final activity = Activity(
        id: '',
        userId: currentUserId!,
        type: type,
        kind: type.name,
        bookId: bookId,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        bookCoverUrl: bookCoverUrl,
        userBookId: userBookId,
        noteId: noteId,
        flashcardId: flashcardId,
        message: message,
        rating: rating,
        isPublic: isPublic,
        visibility: visibility ?? (isPublic ? 'public' : 'private'),
        likeCount: 0,
        commentCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _activitiesCollection.add(activity.toFirestore());
      final docSnapshot = await docRef.get();
      await _trimActivities(currentUserId!, limit: 100);
      return Activity.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Error creating activity: $e');
    }
  }

  /// L?y feed activities (c?a user v… b?n bŠ)
  Future<List<Activity>> getFeed({int limit = 50}) async {
    requireAuth();
    try {
      final querySnapshot = await _activitiesCollection
          .where('visibility', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Activity.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error getting feed: $e');
    }
  }

  /// L?y activities c?a user
  Future<List<Activity>> getMyActivities({int limit = 50}) async {
    requireAuth();
    try {
      final querySnapshot = await _activitiesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Activity.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error getting my activities: $e');
    }
  }

  /// X¢a activity
  Future<void> deleteActivity(String activityId) async {
    requireAuth();
    try {
      final doc = await _activitiesCollection.doc(activityId).get();
      if (!doc.exists) {
        throw Exception('Activity not found');
      }
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUserId) {
        throw Exception('Unauthorized');
      }
      await _activitiesCollection.doc(activityId).delete();
    } catch (e) {
      throw Exception('Error deleting activity: $e');
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> activityStream(String activityId) {
    return _activityDoc(activityId).snapshots();
  }

  Stream<bool> isLikedStream(String activityId) {
    if (currentUserId == null) {
      return Stream.value(false);
    }
    return _likesCollection(activityId).doc(currentUserId).snapshots().map((doc) => doc.exists);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String activityId) {
    return _commentsCollection(activityId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> toggleLike(String activityId) async {
    requireAuth();
    final userId = currentUserId!;
    final activityRef = _activityDoc(activityId);
    final likeRef = _likesCollection(activityId).doc(userId);

    await firestore.runTransaction((tx) async {
      final activitySnap = await tx.get(activityRef);
      if (!activitySnap.exists) {
        throw Exception('Activity not found');
      }
      final likeSnap = await tx.get(likeRef);
      final data = activitySnap.data() ?? <String, dynamic>{};
      final currentCount = (data['likeCount'] as num?)?.toInt() ?? 0;

      if (likeSnap.exists) {
        tx.delete(likeRef);
        final nextCount = currentCount > 0 ? currentCount - 1 : 0;
        tx.update(activityRef, {'likeCount': nextCount});
      } else {
        tx.set(likeRef, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(activityRef, {'likeCount': currentCount + 1});
      }
    });
  }

  Future<void> addComment(String activityId, String text) async {
    requireAuth();
    final userId = currentUserId!;
    final activityRef = _activityDoc(activityId);
    final commentRef = _commentsCollection(activityId).doc();

    await firestore.runTransaction((tx) async {
      final activitySnap = await tx.get(activityRef);
      if (!activitySnap.exists) {
        throw Exception('Activity not found');
      }
      final data = activitySnap.data() ?? <String, dynamic>{};
      final currentCount = (data['commentCount'] as num?)?.toInt() ?? 0;

      tx.set(commentRef, {
        'userId': userId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(activityRef, {'commentCount': currentCount + 1});
    });
  }

  Future<void> deleteComment(String activityId, String commentId) async {
    requireAuth();
    final userId = currentUserId!;
    final activityRef = _activityDoc(activityId);
    final commentRef = _commentsCollection(activityId).doc(commentId);

    await firestore.runTransaction((tx) async {
      final activitySnap = await tx.get(activityRef);
      if (!activitySnap.exists) {
        throw Exception('Activity not found');
      }
      final commentSnap = await tx.get(commentRef);
      if (!commentSnap.exists) {
        throw Exception('Comment not found');
      }
      final commentData = commentSnap.data() as Map<String, dynamic>;
      if (commentData['userId'] != userId) {
        throw Exception('Unauthorized');
      }
      final data = activitySnap.data() ?? <String, dynamic>{};
      final currentCount = (data['commentCount'] as num?)?.toInt() ?? 0;
      final nextCount = currentCount > 0 ? currentCount - 1 : 0;
      tx.delete(commentRef);
      tx.update(activityRef, {'commentCount': nextCount});
    });
  }

  Future<void> _trimActivities(String userId, {int limit = 100}) async {
    try {
      final snap = await _activitiesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit + 1)
          .get();
      if (snap.docs.length <= limit) return;
      final toDelete = snap.docs.sublist(limit);
      final batch = firestore.batch();
      for (final doc in toDelete) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // Ignore trim errors to avoid blocking activity creation.
    }
  }
}
