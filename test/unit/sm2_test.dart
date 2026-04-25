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
  // rating = 0 (Quên)
  // ─────────────────────────────────────────────
  group('SM-2: rating=0 (Quên)', () {
    test('interval reset về 1, status=learning, reviewCount tăng', () async {
      await insertWordWithProgress(db, 'hello', 'en-US',
          status: 'review', interval: 6, reviewCount: 1, correctCount: 1);

      await db.progressDao.updateSM2('hello', 'en-US', 0);

      final p = await db.progressDao.getProgress('hello', 'en-US');
      expect(p!.interval, equals(1));
      expect(p.status, equals('learning'));
      expect(p.reviewCount, equals(2)); // reviewCount tăng
      expect(p.correctCount, equals(1)); // correctCount không tăng khi quên
    });

    test('quên từ lần đầu (reviewCount=0) → reviewCount=1, correctCount=0', () async {
      await insertWordWithProgress(db, 'world', 'en-US',
          status: 'new', reviewCount: 0, correctCount: 0);

      await db.progressDao.updateSM2('world', 'en-US', 0);

      final p = await db.progressDao.getProgress('world', 'en-US');
      expect(p!.reviewCount, equals(1));
      expect(p.correctCount, equals(0));
      expect(p.status, equals('learning'));
    });

    test('quên từ đang known → reset về learning', () async {
      await insertWordWithProgress(db, 'known_word', 'en-US',
          status: 'known', interval: 30, reviewCount: 5, correctCount: 5);

      await db.progressDao.updateSM2('known_word', 'en-US', 0);

      final p = await db.progressDao.getProgress('known_word', 'en-US');
      expect(p!.interval, equals(1));
      expect(p.status, equals('learning'));
    });
  });

  // ─────────────────────────────────────────────
  // rating = 2 (Good) — interval progression
  // ─────────────────────────────────────────────
  group('SM-2: rating=2 (Good) — interval progression', () {
    test('lần review đầu tiên (reviewCount=0): interval=1, status=review', () async {
      await insertWordWithProgress(db, 'apple', 'en-US',
          status: 'new', reviewCount: 0, correctCount: 0);

      await db.progressDao.updateSM2('apple', 'en-US', 2);

      final p = await db.progressDao.getProgress('apple', 'en-US');
      expect(p!.interval, equals(1));
      expect(p.status, equals('review'));
      expect(p.reviewCount, equals(1));
      expect(p.correctCount, equals(1));
    });

    test('lần review thứ 2 (reviewCount=1): interval=6', () async {
      await insertWordWithProgress(db, 'book', 'en-US',
          status: 'review', interval: 1, reviewCount: 1, correctCount: 1);

      await db.progressDao.updateSM2('book', 'en-US', 2);

      final p = await db.progressDao.getProgress('book', 'en-US');
      expect(p!.interval, equals(6));
      expect(p.status, equals('review'));
    });

    test('lần review thứ 3+ (reviewCount=2): interval=round(interval*ease)', () async {
      await insertWordWithProgress(db, 'chair', 'en-US',
          status: 'review',
          interval: 6,
          easeFactor: 2.5,
          reviewCount: 2,
          correctCount: 2);

      await db.progressDao.updateSM2('chair', 'en-US', 2);

      final p = await db.progressDao.getProgress('chair', 'en-US');
      // round(6 * 2.5) = 15
      expect(p!.interval, equals(15));
      expect(p.status, equals('review'));
    });

    test('interval >= 21 → status=known', () async {
      await insertWordWithProgress(db, 'master', 'en-US',
          status: 'review',
          interval: 15,
          easeFactor: 2.5,
          reviewCount: 3,
          correctCount: 3);

      await db.progressDao.updateSM2('master', 'en-US', 2);

      final p = await db.progressDao.getProgress('master', 'en-US');
      // round(15 * 2.5) = 38 >= 21 → known
      expect(p!.interval, greaterThanOrEqualTo(21));
      expect(p.status, equals('known'));
    });
  });

  // ─────────────────────────────────────────────
  // rating = 1 (Hard)
  // ─────────────────────────────────────────────
  group('SM-2: rating=1 (Hard)', () {
    test('Hard lần đầu: interval=1, correctCount tăng', () async {
      await insertWordWithProgress(db, 'hard_word', 'en-US',
          status: 'new', reviewCount: 0, correctCount: 0);

      await db.progressDao.updateSM2('hard_word', 'en-US', 1);

      final p = await db.progressDao.getProgress('hard_word', 'en-US');
      expect(p!.interval, equals(1));
      expect(p.correctCount, equals(1));
    });

    test('Hard làm giảm easeFactor', () async {
      await insertWordWithProgress(db, 'hard2', 'en-US',
          status: 'review',
          interval: 6,
          easeFactor: 2.5,
          reviewCount: 2,
          correctCount: 2);

      await db.progressDao.updateSM2('hard2', 'en-US', 1);

      final p = await db.progressDao.getProgress('hard2', 'en-US');
      // ease mới = max(1.3, 2.5 + 0.1 - 2*(0.08+0.04)) = max(1.3, 2.5-0.14) = 2.36
      expect(p!.easeFactor, lessThan(2.5));
    });
  });

  // ─────────────────────────────────────────────
  // easeFactor boundary
  // ─────────────────────────────────────────────
  group('SM-2: easeFactor không bao giờ dưới 1.3', () {
    test('rating=1 nhiều lần → easeFactor >= 1.3', () async {
      await insertWordWithProgress(db, 'very_hard', 'en-US',
          status: 'review',
          interval: 6,
          easeFactor: 1.35, // gần sát ngưỡng
          reviewCount: 2,
          correctCount: 2);

      await db.progressDao.updateSM2('very_hard', 'en-US', 1);

      final p = await db.progressDao.getProgress('very_hard', 'en-US');
      expect(p!.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('rating=2 tăng easeFactor lên đúng (+0.1)', () async {
      await insertWordWithProgress(db, 'easy_word', 'en-US',
          status: 'review',
          interval: 6,
          easeFactor: 2.5,
          reviewCount: 2,
          correctCount: 2);

      await db.progressDao.updateSM2('easy_word', 'en-US', 2);

      final p = await db.progressDao.getProgress('easy_word', 'en-US');
      // ease mới = max(1.3, 2.5 + 0.1 - 0) = 2.6
      expect(p!.easeFactor, closeTo(2.6, 0.001));
    });
  });

  // ─────────────────────────────────────────────
  // nextReview & auto-create
  // ─────────────────────────────────────────────
  group('SM-2: nextReview & auto-create', () {
    test('nextReview được set về tương lai sau review', () async {
      final beforeTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await insertWordWithProgress(db, 'future', 'en-US', reviewCount: 0);

      await db.progressDao.updateSM2('future', 'en-US', 2);

      final p = await db.progressDao.getProgress('future', 'en-US');
      expect(p!.nextReview, isNotNull);
      expect(p.nextReview!, greaterThan(beforeTs));
    });

    test('word có sẵn trong words nhưng chưa có progress → auto-create và update', () async {
      await insertWord(db, 'auto_create', 'en-US');
      // không gọi insertWordWithProgress → chưa có progress row

      await db.progressDao.updateSM2('auto_create', 'en-US', 2);

      final p = await db.progressDao.getProgress('auto_create', 'en-US');
      expect(p, isNotNull);
      expect(p!.reviewCount, equals(1));
    });
  });
}
