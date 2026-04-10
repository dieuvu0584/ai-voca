import 'dart:math';

import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'progress_dao.g.dart';

@DriftAccessor(tables: [WordProgress, Sessions])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  // --- WordProgress ---

  Future<WordProgressData?> getProgress(String word, String langCode) =>
      (select(wordProgress)
            ..where(
                (t) => t.word.equals(word) & t.langCode.equals(langCode)))
          .getSingleOrNull();

  Future<List<WordProgressData>> getAllProgressForLang(String langCode) =>
      (select(wordProgress)
            ..where((t) => t.langCode.equals(langCode)))
          .get();

  Future<int> upsertProgress(WordProgressCompanion entry) =>
      into(wordProgress).insertOnConflictUpdate(entry);

  /// Lấy từ cần ôn (nextReview <= now)
  Future<List<WordProgressData>> getDueWords(String langCode) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (select(wordProgress)
          ..where((t) =>
              t.langCode.equals(langCode) &
              t.status.isNotIn(['skipped', 'new']) &
              (t.nextReview.isSmallerOrEqualValue(now) |
                  t.nextReview.isNull()))
          ..orderBy([(t) => OrderingTerm.asc(t.nextReview)]))
        .get();
  }

  /// Lấy từ mới chưa học
  Future<List<WordProgressData>> getNewWords(String langCode,
      {int limit = 20}) =>
      (select(wordProgress)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.status.equals('new'))
            ..limit(limit))
          .get();

  /// Lấy từ đã biết
  Future<List<WordProgressData>> getKnownWords(String langCode) =>
      (select(wordProgress)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.status.equals('known')))
          .get();

  /// Lấy từ đang học / cần review
  Future<List<WordProgressData>> getLearningWords(String langCode) =>
      (select(wordProgress)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.status.isIn(['learning', 'review'])))
          .get();

  /// Đánh dấu "Biết rồi" (skip)
  Future<void> skipWord(String word, String langCode) =>
      (update(wordProgress)
            ..where(
                (t) => t.word.equals(word) & t.langCode.equals(langCode)))
          .write(const WordProgressCompanion(
              status: Value('skipped')));

  /// SM-2 update sau khi rating
  Future<void> updateSM2(
      String word, String langCode, int rating) async {
    var progress = await getProgress(word, langCode);
    if (progress == null) return;

    int newInterval = progress.interval;
    double newEase = progress.easeFactor;
    int newReviewCount = progress.reviewCount;
    int newCorrectCount = progress.correctCount;
    String newStatus;

    if (rating == 0) {
      // Quên: reset
      newInterval = 1;
      newReviewCount += 1;
      newStatus = 'learning';
    } else {
      // Hard (1) hoặc Good (2)
      if (progress.reviewCount == 0) {
        newInterval = 1;
      } else if (progress.reviewCount == 1) {
        newInterval = 6;
      } else {
        newInterval = (progress.interval * progress.easeFactor).round();
      }

      final q = rating == 1 ? 3 : 5;
      newEase = max(1.3,
          progress.easeFactor + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
      newReviewCount += 1;
      newCorrectCount += 1;
      newStatus = newInterval >= 21 ? 'known' : 'review';
    }

    final nextReview = DateTime.now()
            .add(Duration(days: newInterval))
            .millisecondsSinceEpoch ~/
        1000;

    await (update(wordProgress)
          ..where(
              (t) => t.word.equals(word) & t.langCode.equals(langCode)))
        .write(WordProgressCompanion(
      interval: Value(newInterval),
      easeFactor: Value(newEase),
      reviewCount: Value(newReviewCount),
      correctCount: Value(newCorrectCount),
      status: Value(newStatus),
      nextReview: Value(nextReview),
      lastSeen:
          Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
    ));
  }

  // --- Sessions ---

  Future<int> startSession(String langCode) => into(sessions).insert(
        SessionsCompanion.insert(
          langCode: langCode,
          startedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );

  Future<void> endSession(int sessionId,
      {required int wordsStudied, required int wordsKnown}) =>
      (update(sessions)..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(
          endedAt:
              Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          wordsStudied: Value(wordsStudied),
          wordsKnown: Value(wordsKnown),
        ),
      );

  Future<List<Session>> getSessionsForLang(String langCode) =>
      (select(sessions)
            ..where((t) => t.langCode.equals(langCode))
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  /// Đếm số từ học hôm nay
  Future<int> wordsStudiedToday(String langCode) async {
    final todayStart = DateTime.now()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)
        .millisecondsSinceEpoch ~/
        1000;
    final count = countAll();
    final query = selectOnly(wordProgress)
      ..addColumns([count])
      ..where(wordProgress.langCode.equals(langCode) &
          wordProgress.lastSeen.isBiggerOrEqualValue(todayStart));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}
