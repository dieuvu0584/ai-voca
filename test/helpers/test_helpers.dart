import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:vocab_ai/core/db/database.dart';

/// Tạo DB in-memory dùng cho mọi unit test
AppDatabase createTestDb() =>
    AppDatabase.forTesting(NativeDatabase.memory());

/// Insert một từ vào bảng words
Future<void> insertWord(
  AppDatabase db,
  String word,
  String langCode, {
  String? definition,
  String? phonetic,
  String? romanization,
}) async {
  await db.wordDao.insertWord(WordsCompanion(
    word: Value(word),
    langCode: Value(langCode),
    source: const Value('remote'),
    definition: Value(definition),
    phonetic: Value(phonetic),
    romanization: Value(romanization),
  ));
}

/// Insert word + progress (status='new') — dùng để setup test SM-2
Future<void> insertWordWithProgress(
  AppDatabase db,
  String word,
  String langCode, {
  String status = 'new',
  int interval = 1,
  double easeFactor = 2.5,
  int reviewCount = 0,
  int correctCount = 0,
  int? nextReview,
  int? lastSeen,
}) async {
  await db.wordDao.insertWord(WordsCompanion(
    word: Value(word),
    langCode: Value(langCode),
    source: const Value('remote'),
  ));
  await db.progressDao.upsertProgress(WordProgressCompanion(
    word: Value(word),
    langCode: Value(langCode),
    status: Value(status),
    interval: Value(interval),
    easeFactor: Value(easeFactor),
    reviewCount: Value(reviewCount),
    correctCount: Value(correctCount),
    nextReview: Value(nextReview),
    lastSeen: Value(lastSeen),
  ));
}
