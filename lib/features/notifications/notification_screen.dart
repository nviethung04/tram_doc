import 'dart:convert';

import 'package:flutter/material.dart';

import '../../components/empty_state.dart';
import '../../components/primary_app_bar.dart';
import '../../data/services/friends_service.dart';
import '../../data/services/in_app_notification_service.dart';
import '../../data/services/local_notification_service.dart';
import '../../data/services/user_service.dart';
import '../../models/app_user.dart';
import '../../models/app_notification.dart';
import '../../models/friend.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _friendsService = FriendsService();
  final _userService = UserService();
  final _notificationService = InAppNotificationService();
  int _selectedIndex = 0; // 0: Thong bao, 1: Nhac nho, 2: Loi moi
  bool _hasMarkedNotifications = false;

  void _handleTabChange(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 0) {
      _markNotificationsSeenOnce();
    }
    if (index == 2) {
      _userService.markFriendInvitesSeen();
    }
  }

  void _markNotificationsSeenOnce() {
    if (_hasMarkedNotifications) return;
    _hasMarkedNotifications = true;
    _userService.markNotificationsSeen();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex == 0 && !_hasMarkedNotifications) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _markNotificationsSeenOnce();
      });
    }
    return StreamBuilder<AppUser?>(
      stream: _userService.streamCurrentUser(),
      builder: (context, userSnapshot) {
        final lastSeenInvites = userSnapshot.data?.lastSeenFriendInvitesAt;
        final lastSeenNotifications =
            userSnapshot.data?.lastSeenNotificationsAt;
        return StreamBuilder<List<AppNotification>>(
          stream: _notificationService.streamNotificationsForCurrentUser(),
          builder: (context, notificationSnapshot) {
            final notifications = notificationSnapshot.data ?? const [];
            final notificationCount = _notificationService
                .countUnseenNotifications(notifications, lastSeenNotifications);
            return StreamBuilder<List<Friend>>(
              stream: _friendsService.streamIncomingPendingRequests(),
              builder: (context, invitesSnapshot) {
                final invites = invitesSnapshot.data ?? const [];
                final inviteCount = _friendsService.countUnseenInvites(
                  invites,
                  lastSeenInvites,
                );
                return Scaffold(
                  appBar: const PrimaryAppBar(
                    title: 'Thông báo',
                    showBack: true,
                  ),
                  backgroundColor: AppColors.background,
                  body: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _SegmentedControl(
                          currentIndex: _selectedIndex,
                          onChanged: _handleTabChange,
                          labels: [
                            _SegmentLabel(
                              'Thông báo',
                              badgeCount: notificationCount,
                            ),
                            _SegmentLabel('Nhắc nhở'),
                            _SegmentLabel('Lời mời', badgeCount: inviteCount),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _selectedIndex == 0
                              ? _NotificationsTab(
                                  key: const ValueKey('notifications_tab'),
                                  notifications: notifications,
                                )
                              : _selectedIndex == 1
                              ? const _ReminderTab(
                                  key: ValueKey('reminder_tab'),
                                )
                              : const _InvitesTab(key: ValueKey('invites_tab')),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SegmentLabel {
  final String text;
  final int? badgeCount;

  const _SegmentLabel(this.text, {this.badgeCount});
}

class _SegmentedControl extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<_SegmentLabel> labels;

  const _SegmentedControl({
    required this.currentIndex,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(_SegmentLabel label, int index) {
      final selected = currentIndex == index;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(index),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: selected ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if ((label.badgeCount ?? 0) > 0) ...[
                  const SizedBox(width: 6),
                  _SegmentBadge(
                    count: label.badgeCount ?? 0,
                    selected: selected,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(
          labels.length,
          (index) => item(labels[index], index),
        ),
      ),
    );
  }
}

class _SegmentBadge extends StatelessWidget {
  final int count;
  final bool selected;

  const _SegmentBadge({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? Colors.white : const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? AppColors.primary : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationsTab({super.key, required this.notifications});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final items = notifications;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'Chưa có thông báo',
        description: 'Khi có thông báo mới, bạn sẽ thấy ở đây.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notification = items[index];
        final name = (notification.actorName ?? '').isNotEmpty
            ? notification.actorName!
            : 'Người dùng';
        final bookTitle = notification.bookTitle ?? 'một cuốn sách';
        final message = (notification.message ?? '').isNotEmpty
            ? notification.message!
            : notification.type == 'friend_share'
            ? '$name đã chia sẻ sách "$bookTitle"'
            : notification.type == 'activity_like'
            ? '$name đã thích bài viết của bạn'
            : notification.type == 'activity_comment'
            ? '$name đã bình luận về bài viết của bạn'
            : '$name có một cập nhật mới';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReminderTab extends StatefulWidget {
  const _ReminderTab({super.key});

  @override
  State<_ReminderTab> createState() => _ReminderTabState();
}

class _ReminderTabState extends State<_ReminderTab> {
  final _notificationService = LocalNotificationService();
  bool _isEnabled = false;
  int _selectedHour = 9;
  int _selectedMinute = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final enabled = await _notificationService.isReminderEnabled();
      final time = await _notificationService.getReminderTime();

      setState(() {
        _isEnabled = enabled;
        _selectedHour = time['hour']!;
        _selectedMinute = time['minute']!;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime() async {
    if (!_isEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cần bật nhắc nhở trước')));
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });

      await _notificationService.setReminderTime(
        _selectedHour,
        _selectedMinute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã đặt giờ nhắc nhở: ${_formatTime(_selectedHour, _selectedMinute)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'CH' : 'SA';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quản lý nhắc nhở ôn tập trong thông báo.',
                    style: AppTypography.body.copyWith(
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_isEnabled ? AppColors.success : Colors.grey)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: _isEnabled ? AppColors.success : Colors.grey,
                ),
              ),
              title: Text('Trạng thái nhắc nhở', style: AppTypography.bodyBold),
              subtitle: Text(
                _isEnabled ? 'Đang bật' : 'Đang tắt',
                style: AppTypography.caption,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.access_time, color: AppColors.primary),
              ),
              title: Text('Giờ nhắc nhở', style: AppTypography.bodyBold),
              subtitle: Text(
                _formatTime(_selectedHour, _selectedMinute),
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitesTab extends StatefulWidget {
  const _InvitesTab({super.key});

  @override
  State<_InvitesTab> createState() => _InvitesTabState();
}

class _InvitesTabState extends State<_InvitesTab> {
  final _friendsService = FriendsService();
  final _userService = UserService();
  final Map<String, AppUser> _userCache = {};

  ImageProvider? _photoProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      final commaIndex = photoUrl.indexOf(',');
      if (commaIndex == -1) return null;
      final raw = photoUrl.substring(commaIndex + 1);
      try {
        return MemoryImage(base64Decode(raw));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(photoUrl);
  }

  Future<AppUser?> _getUser(String userId) async {
    final cached = _userCache[userId];
    if (cached != null) return cached;
    final user = await _userService.getUserById(userId);
    if (user != null) _userCache[userId] = user;
    return user;
  }

  Future<void> _acceptRequest(Friend friendship) async {
    final currentId = _friendsService.currentUserId;
    if (currentId == null) return;
    final otherId = _friendsService.getOtherUserId(friendship, currentId);
    try {
      await _friendsService.acceptFriendRequest(otherId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã chấp nhận lời mời')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chấp nhận lời mời')),
      );
    }
  }

  Future<void> _declineRequest(Friend friendship) async {
    final currentId = _friendsService.currentUserId;
    if (currentId == null) return;
    final otherId = _friendsService.getOtherUserId(friendship, currentId);
    try {
      await _friendsService.removeFriend(otherId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã từ chối lời mời')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể từ chối lời mời')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: _friendsService.streamIncomingPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Không thể tải lời mời'));
        }

        final invites = snapshot.data ?? [];
        if (invites.isEmpty) {
          return const EmptyState(
            icon: Icons.mail_outline,
            title: 'Chưa có lời mời',
            description: 'Lời mời kết bạn sẽ hiển thị ở đây.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: invites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final friendship = invites[index];
            final currentId = _friendsService.currentUserId;
            if (currentId == null) {
              return const SizedBox.shrink();
            }
            final otherId = _friendsService.getOtherUserId(
              friendship,
              currentId,
            );
            return FutureBuilder<AppUser?>(
              future: _getUser(otherId),
              builder: (context, userSnapshot) {
                final user = userSnapshot.data;
                final name = user?.displayName ?? 'Người dùng';
                final hasPhoto = user?.photoUrl?.isNotEmpty == true;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: hasPhoto
                            ? _photoProvider(user!.photoUrl)
                            : null,
                        child: !hasPhoto
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _declineRequest(friendship),
                        child: const Text('Từ chối'),
                      ),
                      ElevatedButton(
                        onPressed: () => _acceptRequest(friendship),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3056D3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Chấp nhận'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
