enum FlashcardStatus { due, done, later }

class Flashcard {
  final String id;
  final String bookTitle;
  final String question;
  final String answer;
  final int timesReviewed;
  final FlashcardStatus status;
  final String level; // Easy/Medium/Hard

  Flashcard({
    required this.id,
    required this.bookTitle,
    required this.question,
    required this.answer,
    required this.timesReviewed,
    required this.status,
    required this.level,
  });
}
