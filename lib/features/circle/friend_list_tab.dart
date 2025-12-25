import 'package:flutter/material.dart';

// --- MOCK DATA MODEL ---
enum FriendStatus { friend, pending, invite }

class FriendMock {
  final String name;
  final String avatarUrl;
  final String? currentBook; // Sách đang đọc (null nếu chưa có)
  final FriendStatus status;

  FriendMock({
    required this.name,
    required this.avatarUrl,
    this.currentBook,
    required this.status,
  });
}

// --- DỮ LIỆU GIẢ LẬP (Giống trong ảnh) ---
final List<FriendMock> friendList = [
  FriendMock(
    name: 'Minh Anh',
    avatarUrl: 'https://i.pravatar.cc/150?u=minhanh',
    currentBook: 'Atomic Habits',
    status: FriendStatus.friend,
  ),
  FriendMock(
    name: 'Tuấn Anh',
    avatarUrl: 'https://i.pravatar.cc/150?u=tuananh',
    currentBook: 'Deep Work',
    status: FriendStatus.friend,
  ),
  FriendMock(
    name: 'Thu Hà',
    avatarUrl: 'https://i.pravatar.cc/150?u=thuha',
    currentBook: 'The 7 Habits',
    status: FriendStatus.friend,
  ),
  FriendMock(
    name: 'Hoàng Nam',
    avatarUrl: 'https://i.pravatar.cc/150?u=hoangnam',
    currentBook: null, // Chưa có hoạt động
    status: FriendStatus.pending,
  ),
];

// --- WIDGET CHÍNH ---
class FriendListTab extends StatelessWidget {
  const FriendListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Mời bạn bè (Invite)
            _buildInviteSection(),
            
            const SizedBox(height: 24),
            
            // Section 2: Danh sách bạn bè
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
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friendList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildFriendItem(friendList[index]);
              },
            ),
            const SizedBox(height: 40), // Padding bottom
          ],
        ),
      ),
    );
  }

  // Widget: Section Mời bạn bè
  Widget _buildInviteSection() {
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
                child: _buildInviteButton(Icons.link, 'Chia sẻ link'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInviteButton(Icons.qr_code, 'Mã QR'),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Widget: Nút mời nhỏ
  Widget _buildInviteButton(IconData icon, String label) {
    return Container(
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
    );
  }

  // Widget: Item Bạn bè
  Widget _buildFriendItem(FriendMock friend) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(friend.avatarUrl),
          ),
          const SizedBox(width: 12),
          
          // Tên + Sách đang đọc
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                friend.currentBook != null
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                          children: [
                            const TextSpan(
                              text: 'Đang đọc: ',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                            TextSpan(
                              text: friend.currentBook,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Text(
                        'Chưa có hoạt động',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
              ],
            ),
          ),
          
          // Badge Trạng thái (Bạn bè / Chờ)
          _buildStatusBadge(friend.status),
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
      case FriendStatus.friend:
        bgColor = const Color(0xFFF0FDF4); // Xanh nhạt
        textColor = const Color(0xFF15803D); // Xanh đậm
        text = 'Bạn bè';
        icon = Icons.check_circle_outline;
        break;
      case FriendStatus.pending:
        bgColor = const Color(0xFFFFF7ED); // Cam nhạt
        textColor = const Color(0xFFC2410C); // Cam đậm
        text = 'Chờ';
        icon = Icons.access_time;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey;
        text = '';
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