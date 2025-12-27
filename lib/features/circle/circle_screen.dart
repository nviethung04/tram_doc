import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/services/activities_service.dart';
import '../../data/services/book_service.dart';
import '../../data/services/friends_service.dart';
import '../../data/services/user_service.dart';
import '../../models/activity.dart';
import '../../models/app_user.dart';
import '../../models/book.dart';
import '../../models/friend.dart';
import 'activity_book_detail_screen.dart';
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
  final _activitiesService = ActivitiesService();
  final _firestore = FirebaseFirestore.instance;

  final Map<String, Friend> _friendshipsUser1 = {};
  final Map<String, Friend> _friendshipsUser2 = {};
  final Map<String, Activity> _publicActivities = {};
  final Map<int, Map<String, Activity>> _friendActivitiesChunks = {};
  final Map<String, AppUser> _userCache = {};
  final Map<String, Book> _bookCache = {};
  final Map<String, Book?> _latestBookCache = {};

  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _friendshipSubs = [];
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _friendActivitySubs = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _publicVisibilitySub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _publicLegacySub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _booksSub;
  static const int _popularBooksSourceLimit = 500;

  bool _isLoadingFeed = true;
  bool _hasLoadedOnce = false;
  int _feedRequestId = 0;

  Set<String> _friendIds = {};
  List<_FeedItem> _feedItems = [];
  List<_PopularBook> _popularBooks = [];

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
    _publicVisibilitySub?.cancel();
    _publicLegacySub?.cancel();
    _booksSub?.cancel();
    super.dispose();
  }

  void _startRealtime() {
    final currentId = _friendsService.currentUserId;
    if (currentId == null) {
      setState(() {
        _feedItems = [];
        _popularBooks = [];
        _isLoadingFeed = false;
      });
      return;
    }

    _listenToFriendships(currentId);
    _listenToPublicActivities();
    _listenToPopularBooks();
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
          (doc) => MapEntry(doc.id, Friend.fromFirestore(doc.data(), doc.id)),
        ),
      );
    _refreshFriendIds();
  }

  void _refreshFriendIds() {
    final currentId = _friendsService.currentUserId;
    if (currentId == null) return;

    final all = <String, Friend>{..._friendshipsUser1, ..._friendshipsUser2};

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
    _publicVisibilitySub?.cancel();
    _publicLegacySub?.cancel();

    _publicVisibilitySub = _firestore
        .collection('activities')
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
          _publicActivities
            ..clear()
            ..addEntries(
              snap.docs.map(
                (doc) => MapEntry(
                  doc.id,
                  Activity.fromFirestore(doc.data(), doc.id),
                ),
              ),
            );
          _rebuildFeed();
        });

    _publicLegacySub = _firestore
        .collection('activities')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
          for (final doc in snap.docs) {
            _publicActivities.putIfAbsent(
              doc.id,
              () => Activity.fromFirestore(doc.data(), doc.id),
            );
          }
          _rebuildFeed();
        });
  }

  Future<void> _rebuildFeed() async {
    final requestId = ++_feedRequestId;
    if (!_hasLoadedOnce) {
      setState(() => _isLoadingFeed = true);
    }

    final activities = _mergeActivities();
    final feedItems = await _buildFeedItems(activities);

    if (!mounted || requestId != _feedRequestId) return;

    setState(() {
      _feedItems = feedItems;
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
      final aIsFriend =
          _friendIds.contains(a.userId) ||
          a.userId == _friendsService.currentUserId;
      final bIsFriend =
          _friendIds.contains(b.userId) ||
          b.userId == _friendsService.currentUserId;
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
      items.add(_FeedItem(activity: activity, user: user, book: books[i]));
    }

    return items;
  }

  void _listenToPopularBooks() {
    _booksSub?.cancel();
    _booksSub = _firestore
        .collection('books')
        .orderBy('createdAt', descending: true)
        .limit(_popularBooksSourceLimit)
        .snapshots()
        .listen(_onBooksSnapshot);
  }

  void _onBooksSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final counts = <String, int>{};
    final booksByKey = <String, Book>{};

    for (final doc in snap.docs) {
      final book = Book.fromFirestore(doc);
      final title = book.title.trim();
      final author = book.author.trim();
      if (title.isEmpty) continue;
      final key = '$title||$author';
      counts[key] = (counts[key] ?? 0) + 1;
      booksByKey.putIfAbsent(key, () => book);
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTwo = sorted.take(2).toList();

    final popular = <_PopularBook>[];
    for (final entry in topTwo) {
      final book = booksByKey[entry.key];
      if (book == null) continue;
      popular.add(_PopularBook(book: book, count: entry.value));
    }

    if (!mounted) return;
    setState(() {
      _popularBooks = popular;
    });
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
    return AppUser(id: id, displayName: 'Người dùng', email: '');
  }

  ImageProvider? _photoProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      final commaIndex = photoUrl.indexOf(',');
      if (commaIndex == -1) return null;
      final raw = photoUrl.substring(commaIndex + 1);
      try {
        return MemoryImage(base64Decode(raw));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(photoUrl);
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
      title: activity.bookTitle?.isNotEmpty == true
          ? activity.bookTitle!
          : 'Sách mới',
      author: '',
      status: BookStatus.wantToRead,
      readPages: 0,
      totalPages: 0,
      description: '',
    );
  }

  Future<void> _addToLibrary(Book? book, Activity activity) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentId = _friendsService.currentUserId;
    if (currentId == null) return;
    try {
      final source = book ?? _createBookFromActivity(activity);
      final alreadyInLibrary = await _isBookInLibraryByTitle(
        source.title,
        currentId,
      );
      if (alreadyInLibrary) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Sách đã có trong thư viện')),
        );
        return;
      }
      final ok = await _bookService.upsertBook(_copyToLibraryBook(source));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? 'Đã thêm vào tủ sách' : 'Không thể thêm sách'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  void _openFriendSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FriendSearchScreen()));
  }

  void _openBookDetail(Activity activity, Book? book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ActivityBookDetailScreen(activity: activity, book: book),
      ),
    );
  }

  Activity _createActivityFromBook(Book book) {
    return Activity(
      id: '',
      userId: '',
      type: ActivityType.bookAdded,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      bookId: book.id,
      bookTitle: book.title,
      bookAuthor: book.author,
      bookCoverUrl: book.coverUrl,
    );
  }

  void _openComments(Activity activity) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _CommentsSheet(
          activity: activity,
          activitiesService: _activitiesService,
          getUser: _getUserCached,
          fallbackUser: _fallbackUser,
          photoProvider: _photoProvider,
          formatTime: _formatTime,
        );
      },
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: [
                _buildAddFriendButton(),
                const SizedBox(height: 8),
                _buildTabSwitch(),
              ],
            ),
          ),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildFeedContent()
                : _buildFriendsContent(),
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
      onPressed: _openFriendSearch,
      icon: const Icon(
        Icons.person_add_outlined,
        color: Color(0xFF3056D3),
        size: 18,
      ),
      label: const Text(
        'Thêm bạn',
        style: TextStyle(
          color: Color(0xFF3056D3),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 28),
        side: const BorderSide(color: Color(0xFF3056D3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [_buildTabItem('Bảng tin', 0), _buildTabItem('Bạn bè', 1)],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3056D3) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedContent() {
    final feedItems = _filteredFeedItems();
    final recentItems = feedItems.take(10).toList();

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
              padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filters.length, (index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedFilterIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3056D3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3056D3)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Sách được yêu thích',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: _popularBooks.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có sách được yêu thích',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularBooks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _buildPopularBookCard(_popularBooks[index]),
                    ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (recentItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                itemCount: recentItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildActivityCard(recentItems[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularBookCard(_PopularBook popularBook) {
    final book = popularBook.book;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBookDetail(_createActivityFromBook(book), book),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? Image.network(
                            book.coverUrl!,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 170,
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(
                              Icons.menu_book_outlined,
                              size: 40,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3056D3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${popularBook.count} lượt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author.isNotEmpty ? book.author : 'Không rõ tác giả',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addPopularBook(book),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3056D3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text(
                          'Thêm nhanh',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPopularBook(Book book) async {
    final currentId = _friendsService.currentUserId;
    if (currentId == null) return;

    final alreadyInLibrary = await _isBookInLibrary(book, currentId);
    if (alreadyInLibrary) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sách đã có trong thư viện')),
      );
      return;
    }

    await _addToLibrary(
      book,
      Activity(
        id: '',
        userId: '',
        type: ActivityType.bookAdded,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bookTitle: book.title,
      ),
    );
  }

  Future<bool> _isBookInLibrary(Book book, String userId) async {
    return _isBookInLibraryByTitle(book.title, userId);
  }

  Future<bool> _isBookInLibraryByTitle(String title, String userId) async {
    try {
      var query = _firestore
          .collection('books')
          .where('userId', isEqualTo: userId);
      query = query.where('title', isEqualTo: title);
      final snap = await query.limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Widget _buildActivityCard(_FeedItem item) {
    final activity = item.activity;
    final user = item.user;
    final book = item.book;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBookDetail(activity, book),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                    backgroundImage: _photoProvider(user.photoUrl),
                    radius: 22,
                    child: user.photoUrl == null || user.photoUrl!.isEmpty
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                            children: [
                              TextSpan(
                                text: user.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: _activityText(activity),
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.menu_book_outlined,
                              size: 14,
                              color: Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(activity.createdAt),
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                      child:
                          (book?.coverUrl ?? activity.bookCoverUrl)
                                  ?.isNotEmpty ==
                              true
                          ? Image.network(
                              book?.coverUrl ?? activity.bookCoverUrl!,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 50,
                              height: 75,
                              color: const Color(0xFFE5E7EB),
                              child: const Icon(
                                Icons.menu_book_outlined,
                                color: Color(0xFF9CA3AF),
                              ),
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
                              fontSize: 12,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if ((book?.author ?? activity.bookAuthor)
                                  ?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 4),
                            Text(
                              book?.author ?? activity.bookAuthor!,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _buildActivityMeta(activity),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openBookDetail(activity, book),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3056D3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          color: Color(0xFF3056D3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _addToLibrary(book, activity),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3056D3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Thêm vào tủ sách',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityMeta(Activity activity) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _activitiesService.activityStream(activity.id),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final likeCount =
            (data?['likeCount'] as num?)?.toInt() ?? activity.likeCount;
        final commentCount =
            (data?['commentCount'] as num?)?.toInt() ?? activity.commentCount;

        return StreamBuilder<bool>(
          stream: _activitiesService.isLikedStream(activity.id),
          builder: (context, likedSnapshot) {
            final isLiked = likedSnapshot.data ?? false;
            final likeColor = isLiked
                ? const Color(0xFF3056D3)
                : const Color(0xFF6B7280);

            return Row(
              children: [
                InkWell(
                  onTap: () async {
                    try {
                      await _activitiesService.toggleLike(activity.id);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: ${e.toString()}')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.thumb_up_alt_outlined,
                          size: 18,
                          color: likeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          likeCount.toString(),
                          style: TextStyle(color: likeColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _openComments(activity),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mode_comment_outlined,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          commentCount.toString(),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final Activity activity;
  final ActivitiesService activitiesService;
  final Future<AppUser?> Function(String) getUser;
  final AppUser Function(String) fallbackUser;
  final ImageProvider? Function(String?) photoProvider;
  final String Function(DateTime) formatTime;

  const _CommentsSheet({
    required this.activity,
    required this.activitiesService,
    required this.getUser,
    required this.fallbackUser,
    required this.photoProvider,
    required this.formatTime,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await widget.activitiesService.addComment(widget.activity.id, text);
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await widget.activitiesService.deleteComment(
        widget.activity.id,
        commentId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('L?i: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bình luận',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: widget.activitiesService.commentsStream(
                    widget.activity.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Không thể tải bình luận'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chưa có bình luận nào',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final commentId = docs[index].id;
                        final userId = (data['userId'] ?? '') as String;
                        final text = (data['text'] ?? '') as String;
                        final createdAt = (data['createdAt'] as Timestamp?)
                            ?.toDate();
                        final currentUserId =
                            widget.activitiesService.currentUserId;
                        final canDelete =
                            currentUserId != null && currentUserId == userId;

                        return FutureBuilder<AppUser?>(
                          future: widget.getUser(userId),
                          builder: (context, userSnapshot) {
                            final user =
                                userSnapshot.data ??
                                widget.fallbackUser(userId);
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: widget.photoProvider(
                                    user.photoUrl,
                                  ),
                                  child:
                                      user.photoUrl == null ||
                                          user.photoUrl!.isEmpty
                                      ? Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          if (createdAt != null)
                                            Text(
                                              widget.formatTime(createdAt),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          if (canDelete) ...[
                                            const SizedBox(width: 6),
                                            IconButton(
                                              onPressed: () =>
                                                  _deleteComment(commentId),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                              tooltip: 'Xoá bình luận',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        text,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _submit,
                      icon: const Icon(Icons.send, color: Color(0xFF3056D3)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _PopularBook {
  final Book book;
  final int count;

  const _PopularBook({required this.book, required this.count});
}
