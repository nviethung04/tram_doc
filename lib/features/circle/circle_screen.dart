import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/services/friend_service.dart';
import '../../models/app_user.dart';
import '../../models/friendship.dart';
import '../../data/mock_data.dart';
import '../../models/book.dart';
import '../../models/feed_item.dart';
import '../../models/friend.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../library/book_detail_screen.dart';
import 'friend_search_screen.dart';
import '../library/book_search_screen.dart';
import 'recommendation_screen.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}
class _CircleScreenState extends State<CircleScreen> {
  final _friendService = FriendService();
  final _auth = FirebaseAuth.instance;
  bool showFeed = true;
  FeedType? filter;
  Future<List<AppUser>>? _friendsFuture;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      setState(() {
        _friendsFuture = _friendService.getFriends(uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFeed = filter == null
        ? feedItems
        : feedItems.where((f) => f.type == filter).toList();
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Vòng tròn tin cậy', style: AppTypography.h2),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Action Button (Thêm bạn)
            Center(
              child: InkWell(
                onTap: () async {
                  final res = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendSearchScreen()),
                  );
                  // Nếu user vừa gửi lời mời/đã thêm bạn, chuyển về tab Bạn bè
                  if (res == 'added') {
                    setState(() => showFeed = false);
                    _loadFriends(); // Quan trọng: Tải lại danh sách
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.22),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thêm bạn',
                        style: AppTypography.body.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle Feed/Friends
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showFeed = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: showFeed ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: showFeed
                              ? [
                                  const BoxShadow(
                                    color: Color(0x19000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          'Feed',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(color: showFeed ? Colors.white : AppColors.textBody),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showFeed = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !showFeed ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: !showFeed
                              ? [
                                  const BoxShadow(
                                    color: Color(0x19000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          'Bạn bè',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(color: !showFeed ? Colors.white : AppColors.textBody),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (showFeed) ...[
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', filter == null, () => setState(() => filter = null)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Vừa đọc xong', filter == FeedType.finished,
                        () => setState(() => filter = FeedType.finished)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Muốn đọc', filter == FeedType.added,
                        () => setState(() => filter = FeedType.added)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ghi chú mới', filter == FeedType.note,
                        () => setState(() => filter = FeedType.note)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recommendations Section
              _buildRecommendationsSection(),
              const SizedBox(height: 24),

              Text(
                'Hoạt động gần đây',
                style: AppTypography.h2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              // Feed Items
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFeed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildFeedItem(filteredFeed[i]),
              ),
            ] else ...[
              // Invite Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mời bạn bè tham gia', style: AppTypography.h2.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.share_outlined, size: 18, color: AppColors.textBody),
                                const SizedBox(width: 8),
                                Text(
                                  'Chia sẻ link',
                                  style: AppTypography.body.copyWith(color: AppColors.textBody),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code, size: 18, color: AppColors.textBody),
                                const SizedBox(width: 8),
                                Text(
                                  'Mã QR',
                                  style: AppTypography.body.copyWith(color: AppColors.textBody),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Real Friends List from Firebase
              if (currentUser != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Pending Requests (Giữ Stream để cập nhật realtime)
                    StreamBuilder<List<Friendship>>(
                      stream: _friendService.getRealFriendships(currentUser.uid),
                      builder: (context, snapshot) {
                        final friendships = snapshot.data ?? [];
                        final pendingIncoming = friendships
                            .where((f) => f.status == 'pending' && f.requestedBy != currentUser.uid)
                            .toList();

                        if (pendingIncoming.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lời mời kết bạn', style: AppTypography.h2.copyWith(fontSize: 18)),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pendingIncoming.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => _PendingFriendRequestItem(
                                friendship: pendingIncoming[i],
                                myUserId: currentUser.uid,
                                onAccepted: _loadFriends, // Reload list khi chấp nhận
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),

                    // 2. Friends List (Dùng FutureBuilder với getFriends)
                    Text('Bạn bè', style: AppTypography.h2.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    FutureBuilder<List<AppUser>>(
                      future: _friendsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final friends = snapshot.data ?? [];
                        if (friends.isEmpty) {
                          return Center(
                            child: Text('Chưa có bạn bè', style: AppTypography.body.copyWith(color: AppColors.textMuted)),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: friends.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _FriendListItem(user: friends[i]),
                        );
                      },
                    ),
                  ],
                )
              else
                Center(
                  child: Text(
                    'Vui lòng đăng nhập',
                    style: AppTypography.body.copyWith(color: AppColors.textMuted),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(color: isSelected ? Colors.white : AppColors.textBody),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF5FE), Color(0xFFFAF5FE)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDAEAFE), width: 1.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Được nhiều bạn yêu thích',
                style: AppTypography.h2.copyWith(fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x19000000), blurRadius: 3, offset: Offset(0, 1)),
                  ],
                ),
                child: const Icon(Icons.arrow_forward, size: 16, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 340,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildRecommendationCard(
                  title: 'Thinking, Fast and Slow',
                  author: 'Daniel Kahneman',
                  coverUrl: 'https://placehold.co/178x267',
                  readers: 3,
                ),
                const SizedBox(width: 12),
                _buildRecommendationCard(
                  title: 'The Power of Habit',
                  author: 'Charles Duhigg',
                  coverUrl: 'https://placehold.co/178x267',
                  readers: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({
    required String title,
    required String author,
    required String coverUrl,
    required int readers,
  }) {
    return Container(
      width: 178,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x19000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  coverUrl,
                  width: 178,
                  height: 267,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x19000000), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    '$readers bạn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.textBody),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Thêm vào tủ sách',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('https://placehold.co/48x48'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: item.user,
                            style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: item.message,
                            style: AppTypography.body.copyWith(color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateTime.now().difference(item.time).inHours} giờ trước',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.book.coverUrl ?? 'https://placehold.co/48x64',
                    width: 48,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.book.title,
                        style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
                      ),
                      if (item.book.author.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.book.author,
                          style: AppTypography.caption.copyWith(color: AppColors.textBody, fontStyle: FontStyle.italic),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BookDetailScreen(book: item.book)),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 1.22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Xem chi tiết',
                      style: AppTypography.body.copyWith(color: AppColors.primary, fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã thêm "${item.book.title}" vào tủ sách')),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Thêm vào tủ sách',
                      style: AppTypography.body.copyWith(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Friend friend) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://placehold.co/48x48'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                if (friend.currentBook != null)
                  RichText(
                    text: TextSpan(
                      style: AppTypography.body,
                      children: [
                        const TextSpan(
                          text: 'Đang đọc: ',
                          style: TextStyle(color: AppColors.textBody),
                        ),
                        TextSpan(
                          text: friend.currentBook,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Chưa có hoạt động',
                    style: AppTypography.body.copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusChip(friend.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(FriendStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case FriendStatus.friend:
        bg = const Color(0xFFF0FDF4);
        text = const Color(0xFF008235);
        label = 'Bạn bè';
        break;
      case FriendStatus.pending:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFBA4C00);
        label = 'Chờ';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF4B5563);
        label = 'Kết bạn';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.body.copyWith(color: text),
      ),
    );
  }
}

class _FriendListItem extends StatelessWidget {
  final AppUser user;

  const _FriendListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(user.photoUrl ?? 'https://placehold.co/48x48'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.bio!,
                    style: AppTypography.body.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Bạn bè',
              style: AppTypography.body.copyWith(color: const Color(0xFF008235)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingFriendRequestItem extends StatelessWidget {
  final Friendship friendship;
  final String myUserId;
  final VoidCallback? onAccepted;

  const _PendingFriendRequestItem({
    required this.friendship,
    required this.myUserId,
    this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final requesterId = friendship.requestedBy;
    final FriendService service = FriendService();

    String formattedDate() {
      try {
        final dt = friendship.createdAt;
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return '';
      }
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: service.getUserProfile(requesterId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?['displayName'] ?? 'Người dùng';
        final avatar = user?['photoUrl'] ?? 'https://placehold.co/48x48';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundImage: NetworkImage(avatar)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Đã gửi: ${formattedDate()}', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  // Accept button
                  InkWell(
                    onTap: () async {
                      try {
                        await service.updateFriendshipStatus(friendship.id, 'accepted');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chấp nhận lời mời')));
                        onAccepted?.call();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: Text('Chấp nhận', style: AppTypography.body.copyWith(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Decline button
                  InkWell(
                    onTap: () async {
                      try {
                        await service.deleteFriendship(friendship.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                      child: Text('Từ chối', style: AppTypography.body.copyWith(color: AppColors.textBody)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

