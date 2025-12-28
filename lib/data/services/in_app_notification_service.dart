import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_notification.dart';
import 'base_firestore_service.dart';

class InAppNotificationService extends BaseFirestoreService {
  InAppNotificationService({super.firestore, super.auth});

  CollectionReference get _collection => collection('notifications');

  Stream<List<AppNotification>> streamNotificationsForCurrentUser() {
    final currentId = currentUserId;
    if (currentId == null) return const Stream<List<AppNotification>>.empty();

    return _collection
        .where('recipientId', isEqualTo: currentId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  int countUnseenNotifications(
    List<AppNotification> items,
    DateTime? lastSeen,
  ) {
    if (items.isEmpty) return 0;
    if (lastSeen == null) return items.length;
    return items.where((item) {
      final createdAt = item.createdAt;
      if (createdAt == null) return true;
      return createdAt.isAfter(lastSeen);
    }).length;
  }
}
