import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ai/core/db/database.dart';
import '../helpers/test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDb();
  });

  tearDown(() async => db.close());

  // ─────────────────────────────────────────────
  // upsert & get
  // ─────────────────────────────────────────────
  group('ProgressDao: upsert & getProgress', () {
    test('upsertProgress → getProgress trả về đúng dữ liệu', () async {
      await insertWordWithProgress(db, 'hello', 'en-US',
          status: 'review',
          interval: 6,
          easeFactor: 2.5,
          reviewCount: 2,
          correctCount: 2);

      final p = await db.progressDao.getProgress('hello', 'en-US');
      expect(p, isNotNull);
      expect(p!.status, equals('review'));
      expect(p.interval, equals(6));
      expect(p.easeFactor, closeTo(2.5, 0.001));
      expect(p.reviewCount, equals(2));
      expect(p.correctCount, equals(2));
    });

    test('getProgress trả về null khi không tồn tại', () async {
      final p = await db.progressDao.getProgress('nonexistent', 'en-US');
      expect(p, isNull);
    });

    test('upsert hai lần → dữ liệu mới ghi đè dữ liệu cũ', () async {
      await insertWordWithProgress(db, 'world', 'en-US', status: 'new', interval: 1);
      await insertWordWithProgress(db, 'world', 'en-US',
          status: 'review', interval: 6);

      final p = await db.progressDao.getProgress('world', 'en-US');
      expect(p!.status, equals('review'));
      expect(p.interval, equals(6));
    });
  });

  // ─────────────────────────────────────────────
  // getNewWords
  // ─────────────────────────────────────────────
  group('ProgressDao: getNewWords', () {
    test('chỉ trả về từ có status=new', () async {
      await insertWordWithProgress(db, 'apple', 'en-US', status: 'new');
      await insertWordWithProgress(db, 'banana', 'en-US', status: 'review');
      await insertWordWithProgress(db, 'cherry', 'en-US', status: 'new');
      await insertWordWithProgress(db, 'date', 'en-US', status: 'skipped');

      final newWords = await db.progressDao.getNewWords('en-US');
      expect(newWords.length, equals(2));
      expect(newWords.every((w) => w.status == 'new'), isTrue);
    });

    test('respect limit parameter', () async {
      for (var i = 0; i < 5; i++) {
        await insertWordWithProgress(db, 'word$i', 'en-US', status: 'new');
      }

      final limited = await db.progressDao.getNewWords('en-US', limit: 3);
      expect(limited.length, equals(3));
    });

    test('tách biệt theo ngôn ngữ', () async {
      await insertWordWithProgress(db, 'apple', 'en-US', status: 'new');
      await insertWordWithProgress(db, 'pomme', 'fr-FR', status: 'new');

      final enNew = await db.progressDao.getNewWords('en-US');
      expect(enNew.every((w) => w.langCode == 'en-US'), isTrue);
    });
  });

  // ─────────────────────────────────────────────
  // getDueWords
  // ─────────────────────────────────────────────
  group('ProgressDao: getDueWords', () {
    test('trả về từ có nextReview <= now', () async {
      final past = DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch ~/
          1000;
      final future = DateTime.now()
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch ~/
          1000;

      await insertWordWithProgress(db, 'due_now', 'en-US',
          status: 'review', nextReview: past);
      await insertWordWithProgress(db, 'not_due', 'en-US',
          status: 'review', nextReview: future);

      final due = await db.progressDao.getDueWords('en-US');
      expect(due.length, equals(1));
      expect(due.first.word, equals('due_now'));
    });

    test('không trả về từ status=new hoặc skipped', () async {
      final past = DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;

      await insertWordWithProgress(db, 'new_w', 'en-US',
          status: 'new', nextReview: past);
      await insertWordWithProgress(db, 'skipped_w', 'en-US',
          status: 'skipped', nextReview: past);
      await insertWordWithProgress(db, 'review_w', 'en-US',
          status: 'review', nextReview: past);
      await insertWordWithProgress(db, 'learning_w', 'en-US',
          status: 'learning', nextReview: past);

      final due = await db.progressDao.getDueWords('en-US');
      expect(due.length, equals(2));
      final words = due.map((w) => w.word).toSet();
      expect(words, containsAll(['review_w', 'learning_w']));
    });

    test('trả về list rỗng khi không có từ đến hạn', () async {
      final future = DateTime.now()
              .add(const Duration(days: 7))
              .millisecondsSinceEpoch ~/
          1000;

      await insertWordWithProgress(db, 'future_word', 'en-US',
          status: 'review', nextReview: future);

      final due = await db.progressDao.getDueWords('en-US');
      expect(due, isEmpty);
    });
  });

  // ─────────────────────────────────────────────
  // skipWord / restoreWord
  // ─────────────────────────────────────────────
  group('ProgressDao: skipWord & restoreWord', () {
    test('skipWord → status=skipped', () async {
      await insertWordWithProgress(db, 'skip_me', 'en-US', status: 'new');

      await db.progressDao.skipWord('skip_me', 'en-US');

      final p = await db.progressDao.getProgress('skip_me', 'en-US');
      expect(p!.status, equals('skipped'));
    });

    test('restoreWord → status=new', () async {
      await insertWordWithProgress(db, 'restore_me', 'en-US', status: 'skipped');

      await db.progressDao.restoreWord('restore_me', 'en-US');

      final p = await db.progressDao.getProgress('restore_me', 'en-US');
      expect(p!.status, equals('new'));
    });

    test('skip → restore → kiểm tra round-trip', () async {
      await insertWordWithProgress(db, 'round_trip', 'en-US', status: 'new');

      await db.progressDao.skipWord('round_trip', 'en-US');
      await db.progressDao.restoreWord('round_trip', 'en-US');

      final p = await db.progressDao.getProgress('round_trip', 'en-US');
      expect(p!.status, equals('new'));
    });
  });

  // ─────────────────────────────────────────────
  // count methods
  // ─────────────────────────────────────────────
  group('ProgressDao: count methods', () {
    test('countNewWords đếm đúng', () async {
      await insertWordWithProgress(db, 'w1', 'en-US', status: 'new');
      await insertWordWithProgress(db, 'w2', 'en-US', status: 'new');
      await insertWordWithProgress(db, 'w3', 'en-US', status: 'review');

      expect(await db.progressDao.countNewWords('en-US'), equals(2));
    });

    test('countSkippedWords đếm đúng', () async {
      await insertWordWithProgress(db, 'w1', 'en-US', status: 'skipped');
      await insertWordWithProgress(db, 'w2', 'en-US', status: 'new');
      await insertWordWithProgress(db, 'w3', 'en-US', status: 'skipped');

      expect(await db.progressDao.countSkippedWords('en-US'), equals(2));
    });

    test('countStudiedWords không tính new và skipped', () async {
      await insertWordWithProgress(db, 'w1', 'en-US', status: 'review');
      await insertWordWithProgress(db, 'w2', 'en-US', status: 'known');
      await insertWordWithProgress(db, 'w3', 'en-US', status: 'new');
      await insertWordWithProgress(db, 'w4', 'en-US', status: 'skipped');

      expect(await db.progressDao.countStudiedWords('en-US'), equals(2));
    });
  });

  // ─────────────────────────────────────────────
  // resetAllProgress
  // ─────────────────────────────────────────────
  group('ProgressDao: resetAllProgress', () {
    test('reset toàn bộ về status=new, interval=1, ease=2.5', () async {
      await insertWordWithProgress(db, 'w1', 'en-US',
          status: 'known', reviewCount: 10, easeFactor: 3.0, interval: 30);
      await insertWordWithProgress(db, 'w2', 'en-US',
          status: 'review', reviewCount: 5, easeFactor: 2.0, interval: 6);

      await db.progressDao.resetAllProgress('en-US');

      final p1 = await db.progressDao.getProgress('w1', 'en-US');
      final p2 = await db.progressDao.getProgress('w2', 'en-US');
      expect(p1!.status, equals('new'));
      expect(p1.reviewCount, equals(0));
      expect(p1.easeFactor, closeTo(2.5, 0.001));
      expect(p1.interval, equals(1));
      expect(p2!.status, equals('new'));
    });

    test('reset chỉ ảnh hưởng đến ngôn ngữ chỉ định', () async {
      await insertWordWithProgress(db, 'en_word', 'en-US',
          status: 'known', reviewCount: 5, easeFactor: 2.8, interval: 20);
      await insertWordWithProgress(db, 'fr_word', 'fr-FR',
          status: 'review', reviewCount: 3, easeFactor: 2.5, interval: 6);

      await db.progressDao.resetAllProgress('en-US');

      final en = await db.progressDao.getProgress('en_word', 'en-US');
      final fr = await db.progressDao.getProgress('fr_word', 'fr-FR');
      expect(en!.status, equals('new'));
      expect(fr!.status, equals('review')); // fr không bị ảnh hưởng
    });
  });

  // ─────────────────────────────────────────────
  // Sessions
  // ─────────────────────────────────────────────
  group('ProgressDao: Sessions', () {
    test('startSession → endSession → getSessionsForLang', () async {
      final sessionId = await db.progressDao.startSession('en-US');
      await db.progressDao.endSession(sessionId,
          wordsStudied: 10, wordsKnown: 3);

      final sessions = await db.progressDao.getSessionsForLang('en-US');
      expect(sessions.length, equals(1));
      expect(sessions.first.wordsStudied, equals(10));
      expect(sessions.first.wordsKnown, equals(3));
      expect(sessions.first.endedAt, isNotNull);
    });

    test('nhiều session → getSessionsForLang trả về đủ số lượng', () async {
      await db.progressDao.startSession('en-US');
      await db.progressDao.startSession('en-US');
      await db.progressDao.startSession('en-US');

      final sessions = await db.progressDao.getSessionsForLang('en-US');
      expect(sessions.length, equals(3));
    });
  });
}
