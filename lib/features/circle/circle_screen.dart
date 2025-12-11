import 'package:flutter/material.dart';
import '../../components/primary_app_bar.dart';
import '../../components/app_chip.dart';
import '../../components/book_card.dart';
import '../../components/app_button.dart';
import '../../data/mock_data.dart';
import '../../models/feed_item.dart';
import 'friend_search_screen.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  bool showFeed = true;
  FeedType? filter;

  @override
  Widget build(BuildContext context) {
    final filtered = filter == null ? feedItems : feedItems.where((f) => f.type == filter).toList();
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Vòng tròn tin cậy', showSearch: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                PrimaryButton(
                  label: 'Thêm bạn',
                  leading: const Icon(Icons.person_add_alt),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendSearchScreen()));
                  },
                ),
                const SizedBox(width: 12),
                SecondaryButton(
                  label: showFeed ? 'Bạn bè' : 'Feed',
                  onPressed: () => setState(() => showFeed = !showFeed),
                ),
              ],
            ),
          ),
          if (showFeed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppChip(
                      label: 'Tất cả',
                      selected: filter == null,
                      onTap: () => setState(() => filter = null),
                    ),
                    const SizedBox(width: 8),
                    AppChip(
                      label: 'Vừa đọc xong',
                      selected: filter == FeedType.finished,
                      onTap: () => setState(() => filter = FeedType.finished),
                    ),
                    const SizedBox(width: 8),
                    AppChip(
                      label: 'Muốn đọc',
                      selected: filter == FeedType.added,
                      onTap: () => setState(() => filter = FeedType.added),
                    ),
                    const SizedBox(width: 8),
                    AppChip(
                      label: 'Ghi chú mới',
                      selected: filter == FeedType.note,
                      onTap: () => setState(() => filter = FeedType.note),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: showFeed ? _buildFeed(filtered) : _buildFriends(),
          )
        ],
      ),
    );
  }

  Widget _buildFeed(List filtered) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = filtered[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.user, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${item.message} • ${item.time.hour}h'),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              BookCard(book: item.book, onTap: () {}),
              if (item.rating != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: List.generate(
                      item.rating!,
                      (index) => const Icon(Icons.star, color: Colors.amber, size: 18),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: const Text('Thêm vào tủ sách của tôi')),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriends() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final friend = friends[i];
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(friend.name),
          subtitle: Text(friend.currentBook != null ? 'Đang đọc: ${friend.currentBook}' : friend.headline),
          trailing: Text(
            friend.status.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
