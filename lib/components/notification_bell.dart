import 'package:flutter/material.dart';

import '../data/services/friends_service.dart';
import '../data/services/in_app_notification_service.dart';
import '../data/services/user_service.dart';
import '../models/friend.dart';
import '../models/app_notification.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? iconColor;

  const NotificationBell({
    super.key,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final service = FriendsService();
    final notificationService = InAppNotificationService();
    final userService = UserService();
    return StreamBuilder(
      stream: userService.streamCurrentUser(),
      builder: (context, snapshot) {
        final lastSeenInvites = snapshot.data?.lastSeenFriendInvitesAt;
        final lastSeenNotifications = snapshot.data?.lastSeenNotificationsAt;
        return StreamBuilder<List<Friend>>(
          stream: service.streamIncomingPendingRequests(),
          builder: (context, inviteSnapshot) {
            final invites = inviteSnapshot.data ?? const [];
            final inviteCount = service.countUnseenInvites(invites, lastSeenInvites);
            return StreamBuilder<List<AppNotification>>(
              stream: notificationService.streamNotificationsForCurrentUser(),
              builder: (context, notificationSnapshot) {
                final notifications = notificationSnapshot.data ?? const [];
                final notificationCount = notificationService.countUnseenNotifications(
                  notifications,
                  lastSeenNotifications,
                );
                final count = inviteCount + notificationCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_none, color: iconColor),
                      onPressed: onPressed,
                      tooltip: 'Thông báo',
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: _Badge(count: count),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
