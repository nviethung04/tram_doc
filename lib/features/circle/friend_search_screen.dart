import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/friends_service.dart';
import '../../models/friend.dart';

enum _RelationStatus { none, outgoing, incoming, friend, blocked }

class _UserResult {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final _RelationStatus relation;

  const _UserResult({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.relation,
  });

  _UserResult copyWith({
    _RelationStatus? relation,
  }) {
    return _UserResult(
      id: id,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      relation: relation ?? this.relation,
    );
  }
}

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _friendsService = FriendsService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isInitialState = true;
  bool _isLoading = false;
  List<_UserResult> _results = [];
  final Map<String, Friend> _friendships = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendships() async {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return;
    final friendships = await _friendsService.getFriendships();
    _friendships
      ..clear()
      ..addEntries(
        friendships.map((friendship) {
          final otherId = _friendsService.getOtherUserId(friendship, currentId);
          return MapEntry(otherId, friendship);
        }),
      );
  }

  _RelationStatus _relationForUser(String userId) {
    final currentId = _auth.currentUser?.uid;
    final friendship = _friendships[userId];
    if (friendship == null || currentId == null) return _RelationStatus.none;

    if (friendship.status == FriendStatus.accepted) return _RelationStatus.friend;
    if (friendship.status == FriendStatus.blocked) return _RelationStatus.blocked;
    if (friendship.status == FriendStatus.pending) {
      return friendship.requestedBy == currentId
          ? _RelationStatus.outgoing
          : _RelationStatus.incoming;
    }
    return _RelationStatus.none;
  }

  Future<void> _applySearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isInitialState = true;
        _results = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isInitialState = false;
    });

    final currentId = _auth.currentUser?.uid;
    await _loadFriendships();

    final lowerQuery = query.toLowerCase();
    final nameDocs = await _queryUsersByPrefix('displayName', query);
    final emailDocs = await _queryUsersByPrefix('email', query);

    final combined = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in [...nameDocs, ...emailDocs]) {
      if (doc.id == currentId) continue;
      combined[doc.id] = doc;
    }

    final results = combined.values
        .map((doc) {
          final data = doc.data();
          final displayName = (data['displayName'] ?? '') as String;
          final email = (data['email'] ?? '') as String;
          final photoUrl = data['photoUrl'] as String?;
          final match = displayName.toLowerCase().contains(lowerQuery) ||
              email.toLowerCase().contains(lowerQuery);
          if (!match) return null;

          return _UserResult(
            id: doc.id,
            displayName: displayName.isEmpty ? 'Không có tên' : displayName,
            email: email,
            photoUrl: photoUrl,
            relation: _relationForUser(doc.id),
          );
        })
        .whereType<_UserResult>()
        .toList();

    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _queryUsersByPrefix(
    String field,
    String query,
  ) async {
    final end = '$query\uf8ff';
    final snap = await _firestore
        .collection('users')
        .where(field, isGreaterThanOrEqualTo: query)
        .where(field, isLessThanOrEqualTo: end)
        .limit(20)
        .get();
    return snap.docs;
  }

  Future<void> _handleAction(_UserResult result) async {
    try {
      if (result.relation == _RelationStatus.none) {
        await _friendsService.sendFriendRequest(result.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lời mời kết bạn')),
        );
      } else if (result.relation == _RelationStatus.incoming) {
        await _friendsService.acceptFriendRequest(result.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chấp nhận lời mời')),
        );
      } else if (result.relation == _RelationStatus.outgoing) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã gửi lời mời')),
        );
      } else if (result.relation == _RelationStatus.friend) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã là bạn bè')),
        );
      } else if (result.relation == _RelationStatus.blocked) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã chặn người dùng này')),
        );
      }

      await _applySearch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    if (val.isEmpty) {
                      setState(() {
                        _isInitialState = true;
                        _results = [];
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc email...',
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
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _applySearch,
                  child: Container(
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
                    alignment: Alignment.center,
                    child: const Text(
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
              ],
            ),
          ),
          Expanded(
            child: _isInitialState
                ? _buildEmptyState()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildResultList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_search_outlined, size: 32, color: Color(0xFF9CA3AF)),
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

  Widget _buildResultList() {
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy người dùng phù hợp',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = _results[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: result.photoUrl != null && result.photoUrl!.isNotEmpty
                    ? NetworkImage(result.photoUrl!)
                    : null,
                child: result.photoUrl == null || result.photoUrl!.isEmpty
                    ? Text(result.displayName.isNotEmpty ? result.displayName[0].toUpperCase() : '?')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.email.isEmpty ? 'Không có email' : result.email,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildActionButton(result),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(_UserResult result) {
    String label;
    Color bgColor;
    Color txtColor;
    IconData? icon;

    switch (result.relation) {
      case _RelationStatus.friend:
        label = 'Bạn bè';
        bgColor = const Color(0xFFF0FDF4);
        txtColor = const Color(0xFF15803D);
        icon = Icons.check;
        break;
      case _RelationStatus.outgoing:
        label = 'Đã gửi';
        bgColor = const Color(0xFFFFF7ED);
        txtColor = const Color(0xFFC2410C);
        icon = Icons.hourglass_empty;
        break;
      case _RelationStatus.incoming:
        label = 'Chấp nhận';
        bgColor = const Color(0xFFEFF6FF);
        txtColor = const Color(0xFF3056D3);
        icon = Icons.person_add_alt_1;
        break;
      case _RelationStatus.blocked:
        label = 'Đã chặn';
        bgColor = const Color(0xFFF3F4F6);
        txtColor = const Color(0xFF6B7280);
        icon = Icons.block;
        break;
      case _RelationStatus.none:
      default:
        label = 'Kết bạn';
        bgColor = const Color(0xFFEFF6FF);
        txtColor = const Color(0xFF3056D3);
        icon = Icons.person_add_alt_1;
    }

    return InkWell(
      onTap: () => _handleAction(result),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (icon != null) Icon(icon, size: 16, color: txtColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: txtColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
