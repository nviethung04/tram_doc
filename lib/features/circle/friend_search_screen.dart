import 'package:flutter/material.dart';
import '../../components/app_input.dart';
import '../../components/app_button.dart';
import '../../data/mock_data.dart';
import '../../models/friend.dart';

class FriendSearchScreen extends StatelessWidget {
  const FriendSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm bạn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SearchBarInput(hint: 'Tìm theo tên / email / username'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
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
              ),
            )
          ],
        ),
      ),
    );
  }
}
