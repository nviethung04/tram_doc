import 'package:flutter/material.dart';
import '../../models/friend.dart';
import '../../data/mock_data.dart'; // Đảm bảo import đúng mock data của bạn

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Biến trạng thái để mô phỏng việc tìm kiếm
  // true: chưa tìm (hiện màn hình trống như ảnh Figma)
  // false: đã tìm (hiện list kết quả)
  bool _isInitialState = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Màu nền xám nhạt
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
          // --- Phần tìm kiếm (Input + Button) ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Input Field
                TextField(
                  controller: _searchController,
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
                  onChanged: (value) {
                    // Logic demo: nếu xóa hết chữ thì quay về trạng thái ban đầu
                    if (value.isEmpty && !_isInitialState) {
                      setState(() => _isInitialState = true);
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Button Tìm kiếm (Style giống Figma Code)
                Container(
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Giả lập hành động tìm kiếm
                        setState(() {
                          _isInitialState = false;
                        });
                        FocusScope.of(context).unfocus(); // Ẩn bàn phím
                      },
                      child: const Center(
                        child: Text(
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
                  ),
                ),
              ],
            ),
          ),

          // --- Phần nội dung bên dưới (Empty State hoặc List) ---
          Expanded(
            child: _isInitialState 
              ? _buildEmptyState() 
              : _buildResultList(),
          ),
        ],
      ),
    );
  }

  // 1. Màn hình trống (Giống ảnh image_e19963.png)
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
            child: const Icon(Icons.people_outline, size: 32, color: Color(0xFF9CA3AF)),
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

  // 2. Danh sách kết quả (Dùng lại logic list của bạn nhưng style đẹp hơn)
  Widget _buildResultList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(friend.avatarUrl ?? 'https://placehold.co/48x48'),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600, 
                        color: Color(0xFF111827)
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friend.headline ?? 'Người yêu sách', // Fallback text
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Action Button
              _buildActionButton(friend.status),
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

    switch (status) {
      case FriendStatus.friend:
        label = 'Bạn bè';
        bgColor = const Color(0xFFF0FDF4);
        txtColor = const Color(0xFF15803D);
        break;
      case FriendStatus.pending:
        label = 'Đã gửi';
        bgColor = const Color(0xFFFFF7ED);
        txtColor = const Color(0xFFC2410C);
        break;
      default: // Chưa kết bạn
        label = 'Kết bạn';
        bgColor = const Color(0xFFEFF6FF);
        txtColor = const Color(0xFF3056D3);
    }

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: txtColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}