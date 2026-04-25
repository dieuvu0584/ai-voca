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

  /// Bulk upsert nhiều progress rows cùng lúc (dùng khi khởi tạo danh sách từ lớn)
  Future<void> upsertProgressBatch(List<WordProgressCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(wordProgress, entries);
    });
  }

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

  /// Đếm tổng số từ đã có progress record (mọi status)
  Future<int> countAllProgressForLang(String langCode) async {
    final count = countAll();
    final query = selectOnly(wordProgress)
      ..addColumns([count])
      ..where(wordProgress.langCode.equals(langCode));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Đếm từ chưa học (status = 'new')
  Future<int> countNewWords(String langCode) async {
    final count = countAll();
    final query = selectOnly(wordProgress)
      ..addColumns([count])
      ..where(wordProgress.langCode.equals(langCode) &
          wordProgress.status.equals('new'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Đếm từ đã học (status không phải 'new' và không phải 'skipped')
  /// Dùng thay cho (totalWords - newWords) để tránh lỗi khi có từ không có progress record
  Future<int> countStudiedWords(String langCode) async {
    final count = countAll();
    final query = selectOnly(wordProgress)
      ..addColumns([count])
      ..where(wordProgress.langCode.equals(langCode) &
          wordProgress.status.isNotIn(['new', 'skipped']));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Đếm từ bị skip
  Future<int> countSkippedWords(String langCode) async {
    final count = countAll();
    final query = selectOnly(wordProgress)
      ..addColumns([count])
      ..where(wordProgress.langCode.equals(langCode) &
          wordProgress.status.equals('skipped'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Lấy từ đã biết (known qua flashcard + skipped ở session preview)
  Future<List<WordProgressData>> getKnownWords(String langCode) =>
      (select(wordProgress)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.status.isIn(['known', 'skipped'])))
          .get();

  /// Lấy từ đang học / cần review
  Future<List<WordProgressData>> getLearningWords(String langCode) =>
      (select(wordProgress)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.status.isIn(['learning', 'review'])))
          .get();

  /// Đánh dấu "Biết rồi" (skip)
  /// Xóa progress của một từ cụ thể (dùng khi xóa từ khỏi DB)
  Future<int> deleteProgress(String word, String langCode) =>
      (delete(wordProgress)
            ..where(
                (t) => t.word.equals(word) & t.langCode.equals(langCode)))
          .go();

  /// Xóa toàn bộ progress rows của một ngôn ngữ (dùng khi reset hoàn toàn)
  Future<int> deleteAllProgress(String langCode) =>
      (delete(wordProgress)
            ..where((t) => t.langCode.equals(langCode)))
          .go();

  /// Xóa progress rows 'new' cho các từ NGOÀI top [limit] từ tần suất cao nhất
  /// Dùng thứ tự words.rowid (tần suất) thay vì word_progress.rowid (thứ tự insert)
  /// → nhất quán với insertMissingProgressRowsLimited, tránh xóa nhầm body/topic words
  Future<void> deleteNewProgressBeyondLimit(String langCode, int limit) async {
    await customStatement(
      "DELETE FROM word_progress WHERE lang_code = ? AND status = 'new' "
      "AND word NOT IN ("
      "  SELECT w.word FROM words w "
      "  WHERE w.lang_code = ? "
      "  ORDER BY w.rowid LIMIT ?"
      ")",
      [langCode, langCode, limit],
    );
  }

  /// Thêm lại progress 'new' cho tất cả từ trong words table chưa có progress row
  /// Dùng khi user nâng cấp Premium để unlock toàn bộ từ vựng tiếng Anh
  Future<void> insertMissingProgressRows(String langCode) async {
    await customStatement(
      "INSERT OR IGNORE INTO word_progress "
      "(word, lang_code, status, review_count, correct_count, ease_factor, interval, next_review, last_seen) "
      "SELECT w.word, w.lang_code, 'new', 0, 0, 2.5, 1, NULL, NULL "
      "FROM words w WHERE w.lang_code = ? "
      "AND NOT EXISTS ("
      "  SELECT 1 FROM word_progress p "
      "  WHERE p.word = w.word AND p.lang_code = w.lang_code"
      ")",
      [langCode],
    );
  }

  /// Thêm tối đa [limit] progress 'new' cho từ chưa có progress (theo thứ tự rowid)
  /// Dùng để restore đúng số từ cần thiết mà không insert thừa 47k rows
  Future<void> insertMissingProgressRowsLimited(String langCode, int limit) async {
    if (limit <= 0) return;
    await customStatement(
      "INSERT OR IGNORE INTO word_progress "
      "(word, lang_code, status, review_count, correct_count, ease_factor, interval, next_review, last_seen) "
      "SELECT w.word, w.lang_code, 'new', 0, 0, 2.5, 1, NULL, NULL "
      "FROM words w WHERE w.lang_code = ? "
      "AND NOT EXISTS ("
      "  SELECT 1 FROM word_progress p "
      "  WHERE p.word = w.word AND p.lang_code = w.lang_code"
      ") "
      "ORDER BY w.rowid LIMIT ?",
      [langCode, limit],
    );
  }

  /// Xóa hàng loạt progress rows cho danh sách từ cụ thể (dùng khi cleanup bad words)
  Future<void> deleteProgressBatch(String langCode, Set<String> badWords) async {
    if (badWords.isEmpty) return;
    await (delete(wordProgress)
          ..where((t) =>
              t.langCode.equals(langCode) & t.word.isIn(badWords.toList())))
        .go();
  }

  Future<void> skipWord(String word, String langCode) =>
      (update(wordProgress)
            ..where(
                (t) => t.word.equals(word) & t.langCode.equals(langCode)))
          .write(const WordProgressCompanion(
              status: Value('skipped')));

  /// Khôi phục từ đã skip về trạng thái 'new' (khi user bỏ chọn "Đã biết")
  Future<void> restoreWord(String word, String langCode) =>
      (update(wordProgress)
            ..where(
                (t) => t.word.equals(word) & t.langCode.equals(langCode)))
          .write(const WordProgressCompanion(
              status: Value('new')));

  /// Reset toàn bộ tiến trình học của 1 ngôn ngữ về trạng thái ban đầu
  Future<void> resetAllProgress(String langCode) async {
    await (update(wordProgress)
          ..where((t) => t.langCode.equals(langCode)))
        .write(const WordProgressCompanion(
      status: Value('new'),
      reviewCount: Value(0),
      correctCount: Value(0),
      easeFactor: Value(2.5),
      interval: Value(1),
      nextReview: Value(null),
      lastSeen: Value(null),
    ));
    // Xóa toàn bộ sessions
    await (delete(sessions)
          ..where((t) => t.langCode.equals(langCode)))
        .go();
  }

  /// SM-2 update sau khi rating
  Future<void> updateSM2(
      String word, String langCode, int rating) async {
    var progress = await getProgress(word, langCode);
    if (progress == null) {
      // Tạo progress row mặc định nếu chưa có (từ lookup hoặc import)
      await upsertProgress(WordProgressCompanion(
        word: Value(word),
        langCode: Value(langCode),
        status: const Value('new'),
      ));
      progress = await getProgress(word, langCode);
      if (progress == null) return;
    }

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

  /// Lịch sử học theo ngày (7 ngày gần nhất)
  Future<List<Map<String, dynamic>>> getDailyStudyHistory(
      String langCode) async {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day)
              .millisecondsSinceEpoch ~/
          1000;
      final end = start + 86400;
      final count = countAll();
      final query = selectOnly(wordProgress)
        ..addColumns([count])
        ..where(wordProgress.langCode.equals(langCode) &
            wordProgress.lastSeen.isBiggerOrEqualValue(start) &
            wordProgress.lastSeen.isSmallerThanValue(end));
      final row = await query.getSingle();
      result
          .add({'date': day, 'count': row.read(count) ?? 0});
    }
    return result;
  }

  /// Lịch sử học theo tuần (8 tuần gần nhất)
  Future<List<Map<String, dynamic>>> getWeeklyStudyHistory(
      String langCode) async {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    // Tìm đầu tuần hiện tại (thứ Hai)
    final currentWeekStart =
        now.subtract(Duration(days: now.weekday - 1));
    for (int i = 7; i >= 0; i--) {
      final weekStart =
          currentWeekStart.subtract(Duration(days: i * 7));
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day)
              .millisecondsSinceEpoch ~/
          1000;
      final end = start + 7 * 86400;
      final count = countAll();
      final query = selectOnly(wordProgress)
        ..addColumns([count])
        ..where(wordProgress.langCode.equals(langCode) &
            wordProgress.lastSeen.isBiggerOrEqualValue(start) &
            wordProgress.lastSeen.isSmallerThanValue(end));
      final row = await query.getSingle();
      result.add(
          {'date': weekStart, 'count': row.read(count) ?? 0});
    }
    return result;
  }

  /// Lịch sử học theo tháng (6 tháng gần nhất)
  Future<List<Map<String, dynamic>>> getMonthlyStudyHistory(
      String langCode) async {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;
      int year = now.year;
      while (month <= 0) {
        month += 12;
        year--;
      }
      final start =
          DateTime(year, month, 1).millisecondsSinceEpoch ~/ 1000;
      final nextMonth = month == 12 ? 1 : month + 1;
      final nextYear = month == 12 ? year + 1 : year;
      final end = DateTime(nextYear, nextMonth, 1)
              .millisecondsSinceEpoch ~/
          1000;
      final count = countAll();
      final query = selectOnly(wordProgress)
        ..addColumns([count])
        ..where(wordProgress.langCode.equals(langCode) &
            wordProgress.lastSeen.isBiggerOrEqualValue(start) &
            wordProgress.lastSeen.isSmallerThanValue(end));
      final row = await query.getSingle();
      result.add({
        'date': DateTime(year, month, 1),
        'count': row.read(count) ?? 0
      });
    }
    return result;
  }

  /// Số ngày học liên tiếp (streak)
  Future<int> getCurrentStreak(String langCode) async {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day)
              .millisecondsSinceEpoch ~/
          1000;
      final end = start + 86400;
      final count = countAll();
      final query = selectOnly(wordProgress)
        ..addColumns([count])
        ..where(wordProgress.langCode.equals(langCode) &
            wordProgress.lastSeen.isBiggerOrEqualValue(start) &
            wordProgress.lastSeen.isSmallerThanValue(end));
      final row = await query.getSingle();
      if ((row.read(count) ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Số lần ôn trung bình mỗi từ
  Future<double> getAvgReviewsPerWord(String langCode) async {
    final allProgress = await getAllProgressForLang(langCode);
    final reviewed = allProgress.where((p) => p.reviewCount > 0).toList();
    if (reviewed.isEmpty) return 0.0;
    final total = reviewed.fold(0, (sum, p) => sum + p.reviewCount);
    return total / reviewed.length;
  }
}
