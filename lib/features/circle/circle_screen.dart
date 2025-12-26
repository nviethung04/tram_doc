import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/services/book_service.dart';
import '../../data/services/friends_service.dart';
import '../../data/services/user_service.dart';
import '../../models/activity.dart';
import '../../models/app_user.dart';
import '../../models/book.dart';
import '../../models/friend.dart';
import '../library/book_detail_screen.dart';
import 'friend_list_tab.dart';
import 'friend_search_screen.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  int _selectedTabIndex = 0; // 0: Bảng tin, 1: Bạn bè
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'Tất cả',
    'Vừa đọc xong',
    'Muốn đọc',
    'Ghi chú mới',
  ];

  final _friendsService = FriendsService();
  final _userService = UserService();
  final _bookService = BookService();
  final _firestore = FirebaseFirestore.instance;

  final Map<String, Friend> _friendshipsUser1 = {};
  final Map<String, Friend> _friendshipsUser2 = {};
  final Map<String, Activity> _publicActivities = {};
  final Map<int, Map<String, Activity>> _friendActivitiesChunks = {};
  final Map<String, AppUser> _userCache = {};
  final Map<String, Book> _bookCache = {};
  final Map<String, Book?> _latestBookCache = {};

  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _friendshipSubs = [];
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _friendActivitySubs = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _publicActivitiesSub;

  bool _isLoadingFeed = true;
  bool _hasLoadedOnce = false;
  int _feedRequestId = 0;

  Set<String> _friendIds = {};
  List<_FeedItem> _feedItems = [];
  List<Book> _friendBooks = [];

  @override
  void initState() {
    super.initState();
    _startRealtime();
  }

  @override
  void dispose() {
    for (final sub in _friendshipSubs) {
      sub.cancel();
    }
    for (final sub in _friendActivitySubs) {
      sub.cancel();
    }
    _publicActivitiesSub?.cancel();
    super.dispose();
  }

  void _startRealtime() {
    final currentId = _friendsService.currentUserId;
    if (currentId == null) {
      setState(() {
        _feedItems = [];
        _friendBooks = [];
        _isLoadingFeed = false;
      });
      return;
    }

    _listenToFriendships(currentId);
    _listenToPublicActivities();
  }

  void _listenToFriendships(String currentId) {
    for (final sub in _friendshipSubs) {
      sub.cancel();
    }
    _friendshipSubs.clear();

    _friendshipSubs.add(
      _firestore
          .collection('friendships')
          .where('userId1', isEqualTo: currentId)
          .snapshots()
          .listen((snap) => _onFriendshipSnapshot(snap, _friendshipsUser1)),
    );

    _friendshipSubs.add(
      _firestore
          .collection('friendships')
          .where('userId2', isEqualTo: currentId)
          .snapshots()
          .listen((snap) => _onFriendshipSnapshot(snap, _friendshipsUser2)),
    );
  }

  void _onFriendshipSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
    Map<String, Friend> target,
  ) {
    target
      ..clear()
      ..addEntries(
        snap.docs.map(
          (doc) => MapEntry(
            doc.id,
            Friend.fromFirestore(doc.data(), doc.id),
          ),
        ),
      );
    _refreshFriendIds();
  }

  void _refreshFriendIds() {
    final currentId = _friendsService.currentUserId;
    if (currentId == null) return;

    final all = <String, Friend>{
      ..._friendshipsUser1,
      ..._friendshipsUser2,
    };

    final nextFriendIds = <String>{};
    for (final friendship in all.values) {
      if (friendship.status != FriendStatus.accepted) continue;
      nextFriendIds.add(_friendsService.getOtherUserId(friendship, currentId));
    }

    final changed = !setEquals(_friendIds, nextFriendIds);
    _friendIds = nextFriendIds;

    _listenToFriendActivities(currentId, nextFriendIds);
    if (changed) {
      _rebuildFeed();
    }
  }

  void _listenToFriendActivities(String currentId, Set<String> friendIds) {
    for (final sub in _friendActivitySubs) {
      sub.cancel();
    }
    _friendActivitySubs.clear();
    _friendActivitiesChunks.clear();

    final ids = {...friendIds, currentId}.toList();
    if (ids.isEmpty) {
      _rebuildFeed();
      return;
    }

    final chunks = <List<String>>[];
    for (int i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final sub = _firestore
          .collection('activities')
          .where('userId', whereIn: chunk)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snap) => _onFriendActivitiesSnapshot(i, snap));
      _friendActivitySubs.add(sub);
    }
  }

  void _onFriendActivitiesSnapshot(
    int chunkIndex,
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final data = <String, Activity>{};
    for (final doc in snap.docs) {
      data[doc.id] = Activity.fromFirestore(doc.data(), doc.id);
    }
    _friendActivitiesChunks[chunkIndex] = data;
    _rebuildFeed();
  }

  void _listenToPublicActivities() {
    _publicActivitiesSub?.cancel();
    _publicActivitiesSub = _firestore
        .collection('activities')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      _publicActivities
        ..clear()
        ..addEntries(
          snap.docs.map(
            (doc) => MapEntry(doc.id, Activity.fromFirestore(doc.data(), doc.id)),
          ),
        );
      _rebuildFeed();
    });
  }

  Future<void> _rebuildFeed() async {
    final requestId = ++_feedRequestId;
    if (!_hasLoadedOnce) {
      setState(() => _isLoadingFeed = true);
    }

    final activities = _mergeActivities();
    final friendBooks = await _loadFriendBooks(_friendIds.toList());
    final feedItems = await _buildFeedItems(activities);

    if (!mounted || requestId != _feedRequestId) return;

    setState(() {
      _feedItems = feedItems;
      _friendBooks = friendBooks;
      _isLoadingFeed = false;
      _hasLoadedOnce = true;
    });
  }

  List<Activity> _mergeActivities() {
    final friendActivities = <String, Activity>{};
    for (final chunk in _friendActivitiesChunks.values) {
      friendActivities.addAll(chunk);
    }

    final allActivities = <String, Activity>{};
    for (final activity in friendActivities.values) {
      allActivities[activity.id] = activity;
    }
    for (final activity in _publicActivities.values) {
      allActivities.putIfAbsent(activity.id, () => activity);
    }

    final uniqueActivities = allActivities.values.toList();
    uniqueActivities.sort((a, b) {
      final aIsFriend = _friendIds.contains(a.userId) || a.userId == _friendsService.currentUserId;
      final bIsFriend = _friendIds.contains(b.userId) || b.userId == _friendsService.currentUserId;
      if (aIsFriend != bIsFriend) return aIsFriend ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    if (uniqueActivities.length > 50) {
      return uniqueActivities.sublist(0, 50);
    }
    return uniqueActivities;
  }

  Future<List<_FeedItem>> _buildFeedItems(List<Activity> activities) async {
    final userIds = activities.map((a) => a.userId).toSet().toList();
    final users = await Future.wait(userIds.map(_getUserCached));

    final userMap = <String, AppUser>{};
    for (int i = 0; i < userIds.length; i++) {
      final user = users[i];
      if (user != null) userMap[userIds[i]] = user;
    }

    final books = await Future.wait(
      activities.map((activity) async {
        if (activity.bookId == null || activity.bookId!.isEmpty) return null;
        return _getBookByIdCached(activity.bookId!);
      }),
    );

    final items = <_FeedItem>[];
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      final user = userMap[activity.userId] ?? _fallbackUser(activity.userId);
      items.add(
        _FeedItem(
          activity: activity,
          user: user,
          book: books[i],
        ),
      );
    }

    return items;
  }

  Future<List<Book>> _loadFriendBooks(List<String> friendIds) async {
    final books = <Book>[];
    for (final friendId in friendIds) {
      final latest = await _fetchLatestBook(friendId);
      if (latest != null) books.add(latest);
    }
    return books;
  }

  Future<Book?> _fetchLatestBook(String userId) async {
    if (_latestBookCache.containsKey(userId)) {
      return _latestBookCache[userId];
    }
    try {
      final snap = await _firestore
          .collection('books')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final book = Book.fromFirestore(snap.docs.first);
      _latestBookCache[userId] = book;
      return book;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> _getUserCached(String userId) async {
    final cached = _userCache[userId];
    if (cached != null) return cached;
    final user = await _userService.getUserById(userId);
    if (user != null) _userCache[userId] = user;
    return user;
  }

  Future<Book?> _getBookByIdCached(String bookId) async {
    final cached = _bookCache[bookId];
    if (cached != null) return cached;
    final book = await _bookService.getBookById(bookId);
    if (book != null) _bookCache[bookId] = book;
    return book;
  }

  Future<void> _manualRefresh() async {
    _userCache.clear();
    _bookCache.clear();
    _latestBookCache.clear();
    await _rebuildFeed();
  }

  AppUser _fallbackUser(String id) {
    return AppUser(
      id: id,
      displayName: 'Người dùng',
      email: '',
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  String _activityText(Activity activity) {
    if (activity.message != null && activity.message!.isNotEmpty) {
      return activity.message!;
    }

    String base;
    switch (activity.type) {
      case ActivityType.bookFinished:
        base = 'vừa đọc xong';
        break;
      case ActivityType.noteCreated:
        base = 'vừa tạo ghi chú';
        break;
      case ActivityType.flashcardCreated:
        base = 'vừa tạo flashcard';
        break;
      case ActivityType.bookAdded:
      default:
        base = 'vừa thêm sách';
    }

    if (activity.bookTitle != null && activity.bookTitle!.isNotEmpty) {
      return '$base "${activity.bookTitle}"';
    }
    return base;
  }

  List<_FeedItem> _filteredFeedItems() {
    if (_selectedFilterIndex == 0) return _feedItems;

    switch (_selectedFilterIndex) {
      case 1:
        return _feedItems
            .where((item) => item.activity.type == ActivityType.bookFinished)
            .toList();
      case 2:
        return _feedItems
            .where((item) => item.activity.type == ActivityType.bookAdded)
            .toList();
      case 3:
        return _feedItems
            .where((item) => item.activity.type == ActivityType.noteCreated)
            .toList();
      default:
        return _feedItems;
    }
  }

  Book _copyToLibraryBook(Book book) {
    return Book(
      id: '',
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      isbn: book.isbn,
      status: BookStatus.wantToRead,
      readPages: 0,
      totalPages: book.totalPages,
      description: book.description,
    );
  }

  Book _createBookFromActivity(Activity activity) {
    return Book(
      id: '',
      title: activity.bookTitle?.isNotEmpty == true ? activity.bookTitle! : 'Sách mới',
      author: '',
      status: BookStatus.wantToRead,
      readPages: 0,
      totalPages: 0,
      description: '',
    );
  }

  Future<void> _addToLibrary(Book? book, Activity activity) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final source = book ?? _createBookFromActivity(activity);
      final ok = await _bookService.upsertBook(_copyToLibraryBook(source));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(ok ? 'Đã thêm vào tủ sách' : 'Không thể thêm sách')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  void _openBookDetail(Book? book) {
    if (book == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
          Expanded(
            child: _selectedTabIndex == 0 ? _buildFeedContent() : _buildFriendsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsContent() {
    return const FriendListTab();
  }

  Widget _buildAddFriendButton() {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FriendSearchScreen()),
        );
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
          _buildTabItem('Bảng tin', 0),
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

  Widget _buildFeedContent() {
    final feedItems = _filteredFeedItems();

    return RefreshIndicator(
      onRefresh: _manualRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingFeed && !_hasLoadedOnce)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Sách mới từ bạn bè',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 340,
            child: _friendBooks.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có sách từ bạn bè',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _friendBooks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _buildBookCard(_friendBooks[index]),
                  ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Hoạt động gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 12),
          if (feedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Chưa có hoạt động nào',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildActivityCard(feedItems[index]),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildBookCard(Book book) {
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                ? Image.network(book.coverUrl!, height: 220, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    height: 220,
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.menu_book_outlined, size: 48, color: Color(0xFF9CA3AF)),
                  ),
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
                  book.author.isNotEmpty ? book.author : 'Không rõ tác giả',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _addToLibrary(
                      book,
                      Activity(
                        id: '',
                        userId: '',
                        type: ActivityType.bookAdded,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        bookTitle: book.title,
                      ),
                    ),
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

  Widget _buildActivityCard(_FeedItem item) {
    final activity = item.activity;
    final user = item.user;
    final book = item.book;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                radius: 22,
                child: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?')
                    : null,
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
                          TextSpan(text: user.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: _activityText(activity),
                            style: const TextStyle(color: Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 14, color: Color(0xFF22C55E)),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(activity.createdAt),
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
                  child: book != null && book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(book.coverUrl!, width: 50, height: 75, fit: BoxFit.cover)
                      : Container(
                          width: 50,
                          height: 75,
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(Icons.menu_book_outlined, color: Color(0xFF9CA3AF)),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book?.title ?? activity.bookTitle ?? 'Sách mới',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (book?.author.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          book!.author,
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (book == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hãy thêm vào tủ sách để xem chi tiết')),
                      );
                      return;
                    }
                    _openBookDetail(book);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3056D3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    style: TextStyle(color: Color(0xFF3056D3), fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addToLibrary(book, activity),
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
}

class _FeedItem {
  final Activity activity;
  final AppUser user;
  final Book? book;

  const _FeedItem({
    required this.activity,
    required this.user,
    required this.book,
  });
}
