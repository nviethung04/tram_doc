import 'package:flutter/material.dart';

// --- MOCK DATA (Dữ liệu giả lập kết quả tìm kiếm) ---
enum FriendStatus { friend, pending, none }

class SearchResultMock {
  final String name;
  final String avatarUrl;
  final String description; // Ví dụ: "Bạn chung...", "Người yêu sách"
  final FriendStatus status;

  SearchResultMock({
    required this.name,
    required this.avatarUrl,
    this.description = 'Người yêu sách',
    required this.status,
  });
}

// Danh sách kết quả giả lập
final List<SearchResultMock> mockSearchResults = [
  SearchResultMock(
    name: 'Hoàng Nam',
    avatarUrl: 'https://i.pravatar.cc/150?u=hoangnam',
    description: 'Bạn chung: Minh Anh',
    status: FriendStatus.none,
  ),
  SearchResultMock(
    name: 'Mai Linh',
    avatarUrl: 'https://i.pravatar.cc/150?u=mailinh',
    description: 'Thành viên mới',
    status: FriendStatus.pending, // Đã gửi lời mời
  ),
  SearchResultMock(
    name: 'Quốc Bảo',
    avatarUrl: 'https://i.pravatar.cc/150?u=quocbao',
    description: 'Đọc cùng: Atomic Habits',
    status: FriendStatus.friend, // Đã là bạn
  ),
];

// --- MÀN HÌNH TÌM KIẾM ---

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Trạng thái hiển thị: 
  // true = Màn hình trắng ban đầu (chưa tìm)
  // false = Đã bấm tìm (hiện danh sách)
  bool _isInitialState = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Màu nền chuẩn Figma
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thêm bạn',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: Column(
        children: [
          // 1. Phần Input tìm kiếm & Nút bấm
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    // Nếu xóa trắng thì quay về màn hình chờ
                    if (val.isEmpty) setState(() => _isInitialState = true);
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email hoặc username...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3056D3)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Nút "Tìm kiếm" (Style giống Figma Code: Shadow + Rounded)
                GestureDetector(
                  onTap: () {
                    // Giả lập hành động tìm kiếm
                    setState(() {
                      _isInitialState = false;
                    });
                    FocusScope.of(context).unfocus(); // Ẩn bàn phím
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3056D3),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Tìm kiếm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Nội dung bên dưới (Empty State hoặc Kết quả)
          Expanded(
            child: _isInitialState 
              ? _buildEmptyState() 
              : _buildResultList(),
          ),
        ],
      ),
    );
  }

  // Widget: Màn hình trống (Giống ảnh image_e19963.png)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 60), // Khoảng cách từ trên xuống giống ảnh
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_search_outlined, size: 32, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nhập tên hoặc email để tìm bạn bè',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Danh sách kết quả (Sau khi bấm Tìm kiếm)
  Widget _buildResultList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mockSearchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = mockSearchResults[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)), // Viền nhẹ
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(result.avatarUrl),
              ),
              const SizedBox(width: 12),
              
              // Tên & Mô tả
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600, 
                        color: Color(0xFF111827)
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Nút hành động (Kết bạn / Đã gửi / Bạn bè)
              _buildActionButton(result.status),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(FriendStatus status) {
    String label;
    Color bgColor;
    Color txtColor;
    IconData? icon;

    switch (status) {
      case FriendStatus.friend:
        label = 'Bạn bè';
        bgColor = const Color(0xFFF0FDF4); // Xanh lá nhạt
        txtColor = const Color(0xFF15803D); // Xanh lá đậm
        icon = Icons.check;
        break;
      case FriendStatus.pending:
        label = 'Đã gửi';
        bgColor = const Color(0xFFFFF7ED); // Cam nhạt
        txtColor = const Color(0xFFC2410C); // Cam đậm
        icon = Icons.hourglass_empty;
        break;
      case FriendStatus.none:
      default:
        label = 'Kết bạn';
        bgColor = const Color(0xFFEFF6FF); // Xanh dương nhạt
        txtColor = const Color(0xFF3056D3); // Xanh dương đậm
        icon = Icons.person_add_alt_1;
    }

    return InkWell(
      onTap: () {
        // Xử lý logic gửi lời mời kết bạn tại đây
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (icon != null) Icon(icon, size: 16, color: txtColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: txtColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}