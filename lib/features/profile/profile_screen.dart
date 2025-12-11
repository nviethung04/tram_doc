import 'package:flutter/material.dart';
import '../../components/primary_app_bar.dart';
import '../../components/app_chip.dart';
import '../../components/app_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 32)),
                  const SizedBox(height: 12),
                  const Text('Người dùng Trạm Đọc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text('Thích sách self-help & productivity'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      AppChip(label: 'Sách: 12'),
                      SizedBox(width: 8),
                      AppChip(label: 'Đã đọc: 5'),
                      SizedBox(width: 8),
                      AppChip(label: 'Flashcard: 20'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Cài đặt nhanh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Thông báo ôn tập'),
              subtitle: const Text('Nhắc bạn mỗi ngày lúc 20:00'),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Đồng bộ trên nhiều thiết bị'),
              subtitle: const Text('Đang bật'),
              value: true,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Đăng xuất', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
