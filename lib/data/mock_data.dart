import '../models/book.dart';
import '../models/note.dart';
import '../models/flashcard.dart';
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

final notes = <Note>[
  Note(
    id: 'n1',
    bookId: '1',
    bookTitle: 'Deep Work',
    content: 'Chặn thời gian 90 phút, tắt thông báo, để làm việc sâu.',
    updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    page: 45,
    isFlashcard: true,
  ),
  Note(
    id: 'n2',
    bookId: '3',
    bookTitle: 'Range',
    content: 'Tư duy đa ngành giúp giải quyết vấn đề tốt hơn.',
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    page: 150,
  ),
];

final flashcards = <Flashcard>[
  Flashcard(
    id: 'f1',
    bookTitle: 'Deep Work',
    question: 'Hai loại làm việc theo Cal Newport?',
    answer: 'Deep work và Shallow work.',
    timesReviewed: 3,
    status: FlashcardStatus.due,
    level: 'Medium',
  ),
  Flashcard(
    id: 'f2',
    bookTitle: 'Atomic Habits',
    question: '4 bước của vòng lặp thói quen?',
    answer: 'Cue, Craving, Response, Reward.',
    timesReviewed: 1,
    status: FlashcardStatus.later,
    level: 'Easy',
  ),
];

final friends = <Friend>[
  Friend(
    name: 'Minh Anh',
    headline: 'Thích sách self-help',
    status: FriendStatus.friend,
    currentBook: 'Atomic Habits',
  ),
  Friend(
    name: 'Tuấn Anh',
    headline: 'Yêu sách kinh doanh',
    status: FriendStatus.friend,
    currentBook: 'Deep Work',
  ),
  Friend(
    name: 'Thu Hà',
    headline: 'Đam mê phát triển bản thân',
    status: FriendStatus.friend,
    currentBook: 'The 7 Habits',
  ),
  Friend(
    name: 'Hoàng Nam',
    headline: 'Mới tham gia',
    status: FriendStatus.pending,
    currentBook: null,
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
