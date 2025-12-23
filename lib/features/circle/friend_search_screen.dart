import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../data/mock_data.dart';
import '../../data/services/friend_service.dart';
import '../../models/friend.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final _searchController = TextEditingController();
  bool _showResults = false;
  final _service = FriendService();
  final _auth = FirebaseAuth.instance;
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];
  
  // Cache trạng thái bạn bè: { userId: status }
  Map<String, String> _friendStatus = {};
  bool _hasChanges = false; // Đánh dấu nếu có thay đổi để reload màn hình trước

  @override
  void initState() {
    super.initState();
    _loadFriendStatuses();
  }

  Future<void> _loadFriendStatuses() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final status = await _service.getFriendshipStatusMap(uid);
      if (mounted) setState(() => _friendStatus = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng PopScope để trả về kết quả khi bấm nút Back cứng hoặc trên AppBar
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(_hasChanges ? 'added' : null);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(_hasChanges ? 'added' : null),
          ),
          title: Text('Thêm bạn', style: AppTypography.h2),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.divider, height: 1),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            // Search Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.divider, width: 1.27),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, email hoặc username...',
                  hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => setState(() => _showResults = true),
              ),
            ),
            const SizedBox(height: 12),
            // Search Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _showResults = true;
                    _loading = true;
                    _results = [];
                  });
                  try {
                    final r = await _service.searchUsers(_searchController.text);
                    setState(() => _results = r);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tìm kiếm: $e')));
                  } finally {
                    setState(() => _loading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0x19000000),
                ),
                child: Text(
                  'Tìm kiếm',
                  style: AppTypography.body.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Content
            Expanded(
              child: _showResults ? _buildResults() : _buildEmptyState(),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_search_outlined, size: 32, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Text(
          'Nhập tên hoặc email để tìm bạn bè',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.textBody),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_results.isEmpty) return Center(child: Text('Không tìm thấy kết quả', style: AppTypography.body.copyWith(color: AppColors.textMuted)));

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final user = _results[i];
        final name = user['displayName'] ?? 'Người dùng';
        final bio = user['bio'] ?? '';
        final userId = user['id'];
        final currentUid = _auth.currentUser?.uid;

        // Xác định trạng thái nút bấm
        final status = _friendStatus[userId];
        final isMe = userId == currentUid;
        
        String btnLabel = 'Kết bạn';
        VoidCallback? onPressed;
        Color btnColor = AppColors.primary;
        Color txtColor = Colors.white;

        if (isMe) {
          btnLabel = 'Bạn';
          btnColor = Colors.grey[300]!;
          txtColor = Colors.black54;
          onPressed = null;
        } else if (status == 'accepted') {
          btnLabel = 'Bạn bè';
          btnColor = const Color(0xFFF0FDF4); // Xanh nhạt
          txtColor = const Color(0xFF008235);
          onPressed = null;
        } else if (status == 'pending_sent') {
          btnLabel = 'Đã gửi';
          btnColor = const Color(0xFFFFFBEB); // Vàng nhạt
          txtColor = const Color(0xFFBA4C00);
          onPressed = null;
        } else if (status == 'pending_received') {
          btnLabel = 'Chấp nhận'; 
          onPressed = null; // User should go to main screen to accept
        } else {
          // Chưa kết bạn
          onPressed = () => _sendRequest(userId);
        }

        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: CircleAvatar(backgroundImage: NetworkImage(user['photoUrl'] ?? 'https://placehold.co/48x48')),
          title: Text(name),
          subtitle: Text(bio, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: txtColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(btnLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Future<void> _sendRequest(String targetUserId) async {
    final current = _auth.currentUser;
    if (current == null) return;

    setState(() => _loading = true);
    try {
      await _service.createFriendRequest(current.uid, targetUserId);
      
      // Cập nhật UI ngay lập tức
      setState(() {
        _friendStatus[targetUserId] = 'pending_sent';
        _hasChanges = true; // Đánh dấu để reload màn hình cha
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi lời mời kết bạn')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
