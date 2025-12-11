class Note {
  final String id;
  final String bookId;
  final String bookTitle;
  final String content;
  final int? page;
  final bool isFlashcard;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.content,
    required this.updatedAt,
    this.page,
    this.isFlashcard = false,
  });
}
