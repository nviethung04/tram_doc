import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../data/mock_data.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
                onPressed: () {
                  setState(() => _showResults = true);
                  FocusScope.of(context).unfocus();
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
    return ListView.separated(
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final friend = friends[i];
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(friend.name),
          subtitle: Text(friend.headline),
          trailing: PrimaryButton(
            label: friend.status == FriendStatus.friend
                ? 'Bạn bè'
                : friend.status == FriendStatus.pending
                    ? 'Đã gửi'
                    : 'Kết bạn',
            onPressed: () {},
          ),
        );
      },
    );
  }
}
