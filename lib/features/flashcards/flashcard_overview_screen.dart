import 'package:flutter/material.dart';
import '../../components/primary_app_bar.dart';
import '../../components/app_chip.dart';
import '../../data/services/flashcard_service.dart';
import '../../models/flashcard.dart';
import 'flashcard_session_screen.dart';
import 'review_today_screen.dart';

class FlashcardOverviewScreen extends StatefulWidget {
  const FlashcardOverviewScreen({super.key});

  @override
  State<FlashcardOverviewScreen> createState() =>
      _FlashcardOverviewScreenState();
}

class _FlashcardOverviewScreenState extends State<FlashcardOverviewScreen> {
  final _flashcardService = FlashcardService();
  FlashcardStatus? _selectedStatus;
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final flashcards = _selectedStatus == null
          ? await _flashcardService.getAllFlashcards()
          : await _flashcardService.getFlashcardsByStatus(_selectedStatus!);

      if (mounted) {
        setState(() {
          _flashcards = flashcards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onStatusChanged(FlashcardStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadFlashcards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Flashcards', showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AppChip(
                  label: 'Tất cả',
                  selected: _selectedStatus == null,
                  onTap: () => _onStatusChanged(null),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Ôn hôm nay',
                  selected: _selectedStatus == FlashcardStatus.due,
                  onTap: () => _onStatusChanged(FlashcardStatus.due),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Chờ lần sau',
                  selected: _selectedStatus == FlashcardStatus.later,
                  onTap: () => _onStatusChanged(FlashcardStatus.later),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadFlashcards,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _flashcards.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.style_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có flashcard nào',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tạo flashcard từ ghi chú của bạn',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFlashcards,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _flashcards.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final card = _flashcards[i];
                        return Dismissible(
                          key: Key('flashcard_${card.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xóa flashcard?'),
                                content: const Text(
                                  'Bạn có chắc chắn muốn xóa flashcard này? Hành động này không thể hoàn tác.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              try {
                                await _flashcardService.deleteFlashcard(card.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã xóa flashcard'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadFlashcards();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi khi xóa: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                            return confirmed;
                          },
                          child: ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(card.question),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(card.bookTitle),
                                Text(
                                  'Đã ôn ${card.timesReviewed} lần · ${card.level}',
                                ),
                              ],
                            ),
                            trailing: Text(
                              card.status == FlashcardStatus.due
                                  ? 'Ôn hôm nay'
                                  : (card.status == FlashcardStatus.done
                                        ? 'Đã xong'
                                        : 'Chờ'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FlashcardSessionScreen(cards: _flashcards),
                                ),
                              );
                              if (result == true) {
                                _loadFlashcards();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ReviewTodayScreen()));
          if (result == true) {
            _loadFlashcards();
          }
        },
        label: const Text('Ôn tập hôm nay'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }
}
