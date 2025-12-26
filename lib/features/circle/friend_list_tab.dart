import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/services/friends_service.dart';
import '../../data/services/user_service.dart';
import '../../models/app_user.dart';
import '../../models/book.dart';
import '../../models/friend.dart';

class FriendListTab extends StatefulWidget {
  const FriendListTab({super.key});

  @override
  State<FriendListTab> createState() => _FriendListTabState();
}

class _FriendListTabState extends State<FriendListTab> {
  final _friendsService = FriendsService();
  final _userService = UserService();
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<_FriendItem> _friends = [];
  List<_PendingItem> _pending = [];
  List<_OutgoingItem> _outgoing = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final currentId = _friendsService.currentUserId;
      if (currentId == null) {
        setState(() {
          _friends = [];
          _pending = [];
          _isLoading = false;
        });
        return;
      }

      final friendships = await _friendsService.getFriends();
      final friendIds = friendships
          .map((friendship) => _friendsService.getOtherUserId(friendship, currentId))
          .toList();

      final friendItems = await Future.wait(
        friendIds.map((friendId) async {
          final user = await _userService.getUserById(friendId);
          if (user == null) return null;
          final latestBook = await _fetchLatestBook(friendId);
          return _FriendItem(user: user, latestBook: latestBook);
        }),
      );

      final pending = await _friendsService.getPendingRequests();
      final allFriendships = await _friendsService.getFriendships();
      final pendingItems = await Future.wait(
        pending.map((friendship) async {
          final otherId = _friendsService.getOtherUserId(friendship, currentId);
          final user = await _userService.getUserById(otherId);
          if (user == null) return null;
          return _PendingItem(user: user, friendship: friendship);
        }),
      );

      final outgoingItems = await Future.wait(
        allFriendships
            .where(
              (friendship) =>
                  friendship.status == FriendStatus.pending &&
                  friendship.requestedBy == currentId,
            )
            .map((friendship) async {
              final otherId = _friendsService.getOtherUserId(friendship, currentId);
              final user = await _userService.getUserById(otherId);
              if (user == null) return null;
              return _OutgoingItem(user: user, friendship: friendship);
            }),
      );

      setState(() {
        _friends = friendItems.whereType<_FriendItem>().toList();
        _pending = pendingItems.whereType<_PendingItem>().toList();
        _outgoing = outgoingItems.whereType<_OutgoingItem>().toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _friends = [];
        _pending = [];
        _outgoing = [];
        _isLoading = false;
      });
    }
  }

  Future<Book?> _fetchLatestBook(String userId) async {
    try {
      final snap = await _firestore
          .collection('books')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return Book.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }

  Future<void> _acceptRequest(_PendingItem item) async {
    await _friendsService.acceptFriendRequest(item.user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chấp nhận lời mời')),
    );
    await _loadFriends();
  }

  Future<void> _declineRequest(_PendingItem item) async {
    await _friendsService.removeFriend(item.user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã từ chối lời mời')),
    );
    await _loadFriends();
  }

  Future<void> _cancelRequest(_OutgoingItem item) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy lời mời'),
        content: Text('Bạn có chắc muốn hủy lời mời với ${item.user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
    if (shouldCancel != true) return;
    await _friendsService.removeFriend(item.user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hủy lời mời')),
    );
    await _loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Mời bạn bè
            _buildInviteSection(context),
            const SizedBox(height: 24),

            if (_pending.isNotEmpty) ...[
              const Text(
                'Lời mời kết bạn',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pending.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildPendingItem(_pending[index]);
                },
              ),
              const SizedBox(height: 24),
            ],

            if (_outgoing.isNotEmpty) ...[
              const Text(
                'Lời mời đã gửi',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _outgoing.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildOutgoingItem(_outgoing[index]);
                },
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'Bạn bè',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),

            if (_friends.isEmpty)
              _buildEmptyFriends()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildFriendItem(_friends[index]);
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mời bạn bè tham gia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInviteButton(
                  Icons.link,
                  'Chia sẻ link',
                  () => _showInviteSnack(context, 'Chia sẻ link sẽ có sớm'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInviteButton(
                  Icons.qr_code,
                  'Mã QR',
                  () => _showInviteSnack(context, 'Mã QR sẽ có sớm'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInviteButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF4B5563)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildEmptyFriends() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Bạn chưa có bạn bè nào',
        style: TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }

  Widget _buildPendingItem(_PendingItem item) {
    final user = item.user;
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
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _declineRequest(item),
            child: const Text('Từ chối'),
          ),
          ElevatedButton(
            onPressed: () => _acceptRequest(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3056D3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(_FriendItem item) {
    final user = item.user;
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
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                item.latestBook != null
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                          children: [
                            const TextSpan(
                              text: 'Sách gần đây: ',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                            TextSpan(
                              text: item.latestBook!.title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Text(
                        'Chưa có sách',
                        style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      ),
              ],
            ),
          ),
          _buildStatusBadge(FriendStatus.accepted),
        ],
      ),
    );
  }

  Widget _buildOutgoingItem(_OutgoingItem item) {
    final user = item.user;
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
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _cancelRequest(item),
            child: const Text('Hủy'),
          ),
          _buildStatusBadge(FriendStatus.pending),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FriendStatus status) {
    Color bgColor;
    Color textColor;
    String text;
    IconData? icon;

    switch (status) {
      case FriendStatus.accepted:
        bgColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF15803D);
        text = 'Bạn bè';
        icon = Icons.check_circle_outline;
        break;
      case FriendStatus.pending:
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        text = 'Chờ';
        icon = Icons.access_time;
        break;
      case FriendStatus.blocked:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        text = 'Đã chặn';
        icon = Icons.block;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 14, color: textColor),
          if (icon != null) const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendItem {
  final AppUser user;
  final Book? latestBook;

  const _FriendItem({
    required this.user,
    required this.latestBook,
  });
}

class _PendingItem {
  final AppUser user;
  final Friend friendship;

  const _PendingItem({
    required this.user,
    required this.friendship,
  });
}

class _OutgoingItem {
  final AppUser user;
  final Friend friendship;

  const _OutgoingItem({
    required this.user,
    required this.friendship,
  });
}
