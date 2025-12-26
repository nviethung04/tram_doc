import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity.dart';
import 'base_firestore_service.dart';

class ActivitiesService extends BaseFirestoreService {
  ActivitiesService({super.firestore, super.auth});

  CollectionReference get _activitiesCollection => collection('activities');

  /// Tạo activity mới
  Future<Activity> createActivity({
    required ActivityType type,
    String? bookId,
    String? bookTitle,
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
        userBookId: userBookId,
        noteId: noteId,
        flashcardId: flashcardId,
        message: message,
        rating: rating,
        isPublic: isPublic,
        visibility: visibility ?? (isPublic ? 'public' : 'private'),
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _activitiesCollection.add(activity.toFirestore());
      final docSnapshot = await docRef.get();
      return Activity.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Error creating activity: $e');
    }
  }

  /// Lấy feed activities (của user và bạn bè)
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

  /// Lấy activities của user
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

  /// Xóa activity
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
}
