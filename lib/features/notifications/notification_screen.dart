import 'dart:convert';

import 'package:flutter/material.dart';

import '../../components/empty_state.dart';
import '../../components/primary_app_bar.dart';
import '../../data/services/friends_service.dart';
import '../../data/services/user_service.dart';
import '../../models/app_user.dart';
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
  int _selectedIndex = 0; // 0: Thông báo, 1: Lời mời

  void _handleTabChange(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 1) {
      _userService.markFriendInvitesSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _userService.streamCurrentUser(),
      builder: (context, snapshot) {
        final lastSeen = snapshot.data?.lastSeenFriendInvitesAt;
        return StreamBuilder<List<Friend>>(
          stream: _friendsService.streamIncomingPendingRequests(),
          builder: (context, invitesSnapshot) {
            final invites = invitesSnapshot.data ?? const [];
            final inviteCount =
                _friendsService.countUnseenInvites(invites, lastSeen);
            return Scaffold(
              appBar: const PrimaryAppBar(title: 'Thông báo', showBack: true),
              backgroundColor: AppColors.background,
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _SegmentedControl(
                      currentIndex: _selectedIndex,
                      onChanged: _handleTabChange,
                      labels: [
                        const _SegmentLabel('Thông báo'),
                        _SegmentLabel('Lời mời', badgeCount: inviteCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _selectedIndex == 0
                          ? const _NotificationsTab(
                              key: ValueKey('notifications_tab'),
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
                  _SegmentBadge(count: label.badgeCount ?? 0, selected: selected),
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
        children: [
          item(labels[0], 0),
          item(labels[1], 1),
        ],
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
  const _NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.notifications_none,
      title: 'Chưa có thông báo',
      description: 'Khi có thông báo mới, bạn sẽ thấy ở đây.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận lời mời')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối lời mời')),
      );
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
            final otherId = _friendsService.getOtherUserId(friendship, currentId);
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
                        backgroundImage: hasPhoto ? _photoProvider(user!.photoUrl) : null,
                        child: !hasPhoto
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
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
