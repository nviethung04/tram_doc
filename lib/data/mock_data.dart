import '../models/book.dart';
import '../models/friend.dart';
import '../models/feed_item.dart';

final books = <Book>[
  Book(
    id: '1',
    title: 'Deep Work',
    author: 'Cal Newport',
    status: BookStatus.reading,
    readPages: 120,
    totalPages: 304,
    description: 'Kỹ năng tập trung sâu để làm việc hiệu quả.',
  ),
  Book(
    id: '2',
    title: 'Atomic Habits',
    author: 'James Clear',
    status: BookStatus.wantToRead,
    readPages: 0,
    totalPages: 320,
    description: 'Xây dựng thói quen nhỏ mang lại thay đổi lớn.',
  ),
  Book(
    id: '3',
    title: 'Range',
    author: 'David Epstein',
    status: BookStatus.read,
    readPages: 320,
    totalPages: 320,
    description: 'Lợi thế của sự đa dạng kinh nghiệm.',
  ),
];

final friends = <Friend>[
  Friend(
    name: 'Lan Phạm',
    headline: 'Thích sách self-help & productivity',
    status: FriendStatus.friend,
    currentBook: 'Deep Work',
  ),
  Friend(
    name: 'Minh Trần',
    headline: 'Yêu sách kinh doanh',
    status: FriendStatus.pending,
    currentBook: 'Zero to One',
  ),
  Friend(
    name: 'Hùng Lê',
    headline: 'Đọc fiction & khoa học',
    status: FriendStatus.invited,
    currentBook: 'Dune',
  ),
];

final feedItems = <FeedItem>[
  FeedItem(
    user: 'Lan Phạm',
    message: 'vừa đọc xong và đánh giá 5 sao',
    type: FeedType.finished,
    rating: 5,
    book: books[0],
    time: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  FeedItem(
    user: 'Minh Trần',
    message: 'vừa thêm vào kệ "Muốn đọc"',
    type: FeedType.added,
    book: books[1],
    time: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  FeedItem(
    user: 'Hùng Lê',
    message: 'vừa ghi chú một ý tưởng hay',
    type: FeedType.note,
    book: books[2],
    time: DateTime.now().subtract(const Duration(hours: 8)),
  ),
];
