import 'package:flutter/material.dart';
import 'friend_search_screen.dart'; // Đảm bảo import màn hình tìm bạn nếu có

// --- DỮ LIỆU GIẢ LẬP (MOCK DATA) ĐỂ HIỂN THỊ UI ---
// Bạn có thể thay thế bằng Model thật của dự án sau này
class BookMock {
  final String title;
  final String author;
  final String imageUrl;
  final int friendCount; 

  BookMock(this.title, this.author, this.imageUrl, {this.friendCount = 0});
}

class ActivityMock {
  final String userName;
  final String userAvatar;
  final String actionText;
  final String time;
  final BookMock book;
  final double rating;
  
  ActivityMock({
    required this.userName,
    required this.userAvatar,
    required this.actionText,
    required this.time,
    required this.book,
    required this.rating,
  });
}

// Dữ liệu mẫu
final List<BookMock> popularBooks = [
  BookMock('Thinking, Fast and Slow', 'Daniel Kahneman', 'https://m.media-amazon.com/images/I/41shR51YdVL.jpg', friendCount: 3),
  BookMock('The Power of Habit', 'Charles Duhigg', 'https://m.media-amazon.com/images/I/81iRP+x+1ML.jpg', friendCount: 3),
];

final List<ActivityMock> activities = [
  ActivityMock(
    userName: 'Minh Anh',
    userAvatar: 'https://i.pravatar.cc/150?u=minhanh',
    actionText: 'vừa đọc xong',
    time: '2 giờ trước',
    book: BookMock('Atomic Habits', 'James Clear', 'https://m.media-amazon.com/images/I/91bYsX41DVL.jpg'),
    rating: 5,
  ),
  ActivityMock(
    userName: 'Tuấn Anh',
    userAvatar: 'https://i.pravatar.cc/150?u=tuananh',
    actionText: 'vừa thêm vào kệ "Muốn đọc"',
    time: '5 giờ trước',
    book: BookMock('Deep Work', 'Cal Newport', 'https://m.media-amazon.com/images/I/417ojj3P+GL.jpg'),
    rating: 4,
  ),
];

// --- MÀN HÌNH CHÍNH ---

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  int _selectedTabIndex = 0; // 0: Feed, 1: Bạn bè
  int _selectedFilterIndex = 0; // Filter: Tất cả, Vừa đọc xong...
  int _bottomNavIndex = 2; // Tab "Vòng tròn" đang được chọn

  final List<String> _filters = ['Tất cả', 'Vừa đọc xong', 'Muốn đọc', 'Ghi chú mới'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Màu nền xám nhạt chuẩn Figma
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Vòng tròn tin cậy',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Column(
        children: [
          // Header: Nút Thêm bạn & Tab Switch
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildAddFriendButton(),
                const SizedBox(height: 16),
                _buildTabSwitch(),
              ],
            ),
          ),
          
          // Nội dung chính (Feed hoặc Bạn bè)
          Expanded(
            child: _selectedTabIndex == 0 ? _buildFeedContent() : _buildFriendsContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // 1. Nút "Thêm bạn" outline xanh
  Widget _buildAddFriendButton() {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendSearchScreen()));
      },
      icon: const Icon(Icons.person_add_outlined, color: Color(0xFF3056D3)),
      label: const Text(
        'Thêm bạn',
        style: TextStyle(
          color: Color(0xFF3056D3),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        side: const BorderSide(color: Color(0xFF3056D3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
    );
  }

  // 2. Bộ chuyển đổi Tab (Feed - Bạn bè)
  Widget _buildTabSwitch() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _buildTabItem('Feed', 0),
          _buildTabItem('Bạn bè', 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3056D3) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // 3. Nội dung Tab Feed
  Widget _buildFeedContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng nút lọc (Filter Chips)
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3056D3) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3056D3) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Section: Được nhiều bạn yêu thích (List ngang)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Được nhiều bạn yêu thích',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 340,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: popularBooks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildPopularBookCard(popularBooks[index]),
            ),
          ),

          const SizedBox(height: 24),

          // Section: Hoạt động gần đây (List dọc)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Hoạt động gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildActivityCard(activities[index]),
          ),
        ],
      ),
    );
  }

  // Widget: Card sách phổ biến (Dọc)
  Widget _buildPopularBookCard(BookMock book) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(book.imageUrl, height: 220, width: double.infinity, fit: BoxFit.cover),
              ),
              if (book.friendCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3056D3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${book.friendCount} bạn',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3056D3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Thêm vào tủ sách', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget: Card hoạt động (Feed Item)
  Widget _buildActivityCard(ActivityMock activity) {
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
          // Header: Avatar + Tên + Hành động
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(activity.userAvatar),
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Color(0xFF111827), fontSize: 15, fontFamily: 'Inter'),
                        children: [
                          TextSpan(text: activity.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' '),
                          TextSpan(text: activity.actionText, style: const TextStyle(color: Color(0xFF4B5563))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 14, color: Color(0xFF22C55E)),
                        const SizedBox(width: 4),
                        Text(
                          activity.time,
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          
          const SizedBox(height: 12),

          // Content Box: Thông tin sách
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(activity.book.imageUrl, width: 50, height: 75, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.book.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color: index < activity.rating ? const Color(0xFFF59E0B) : Colors.grey[300],
                          );
                        }),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Buttons: Xem chi tiết & Thêm vào tủ sách
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3056D3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Xem chi tiết', style: TextStyle(color: Color(0xFF3056D3), fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3056D3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Thêm vào tủ sách', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Nội dung Tab Bạn bè (Placeholder)
  Widget _buildFriendsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Danh sách bạn bè đang trống", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // 4. Bottom Navigation Bar chuẩn thiết kế
  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3056D3),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'Thư viện'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Ghi chú'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Vòng tròn'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    );
  }
}