import 'package:drift/drift.dart' hide isNull, isNotNull;
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
  // Insert & Get
  // ─────────────────────────────────────────────
  group('WordDao: insertWord & getWord', () {
    test('insertWord → getWord trả về đúng từ', () async {
      await insertWord(db, 'hello', 'en-US',
          definition: 'A greeting', phonetic: '/hɛˈloʊ/');

      final w = await db.wordDao.getWord('hello', 'en-US');
      expect(w, isNotNull);
      expect(w!.word, equals('hello'));
      expect(w.langCode, equals('en-US'));
      expect(w.definition, equals('A greeting'));
      expect(w.phonetic, equals('/hɛˈloʊ/'));
    });

    test('getWord trả về null khi không tồn tại', () async {
      final w = await db.wordDao.getWord('nonexistent', 'en-US');
      expect(w, isNull);
    });

    test('insertWord cùng key → upsert (ghi đè)', () async {
      await insertWord(db, 'test', 'en-US', definition: 'First def');
      await db.wordDao.insertWord(const WordsCompanion(
        word: Value('test'),
        langCode: Value('en-US'),
        source: Value('remote'),
        definition: Value('Updated def'),
      ));

      final w = await db.wordDao.getWord('test', 'en-US');
      expect(w!.definition, equals('Updated def'));
    });

    test('hai ngôn ngữ khác nhau cùng từ → tách biệt', () async {
      await insertWord(db, 'chat', 'fr-FR',
          definition: 'Cat in French');
      await insertWord(db, 'chat', 'en-US',
          definition: 'Talk informally');

      final fr = await db.wordDao.getWord('chat', 'fr-FR');
      final en = await db.wordDao.getWord('chat', 'en-US');
      expect(fr!.definition, equals('Cat in French'));
      expect(en!.definition, equals('Talk informally'));
    });
  });

  // ─────────────────────────────────────────────
  // Count
  // ─────────────────────────────────────────────
  group('WordDao: countWordsForLang', () {
    test('đếm đúng số từ theo ngôn ngữ', () async {
      await insertWord(db, 'apple', 'en-US');
      await insertWord(db, 'banana', 'en-US');
      await insertWord(db, 'cherry', 'fr-FR');

      expect(await db.wordDao.countWordsForLang('en-US'), equals(2));
      expect(await db.wordDao.countWordsForLang('fr-FR'), equals(1));
      expect(await db.wordDao.countWordsForLang('de-DE'), equals(0));
    });

    test('count=0 khi bảng rỗng', () async {
      expect(await db.wordDao.countWordsForLang('en-US'), equals(0));
    });
  });

  // ─────────────────────────────────────────────
  // Search
  // ─────────────────────────────────────────────
  group('WordDao: searchWords', () {
    test('tìm từ khớp pattern LIKE', () async {
      await insertWord(db, 'application', 'en-US');
      await insertWord(db, 'apple', 'en-US');
      await insertWord(db, 'book', 'en-US');

      final results = await db.wordDao.searchWords('app', 'en-US');
      expect(results.length, equals(2));
      expect(results.any((w) => w.word == 'application'), isTrue);
      expect(results.any((w) => w.word == 'apple'), isTrue);
      expect(results.any((w) => w.word == 'book'), isFalse);
    });

    test('không có kết quả → list rỗng', () async {
      await insertWord(db, 'apple', 'en-US');
      final results = await db.wordDao.searchWords('xyz', 'en-US');
      expect(results, isEmpty);
    });

    test('search chỉ trong đúng ngôn ngữ', () async {
      await insertWord(db, 'application', 'en-US');
      await insertWord(db, 'application', 'fr-FR');

      final results = await db.wordDao.searchWords('app', 'fr-FR');
      expect(results.every((w) => w.langCode == 'fr-FR'), isTrue);
    });
  });

  // ─────────────────────────────────────────────
  // Enrichment
  // ─────────────────────────────────────────────
  group('WordDao: updateWordEnrichment', () {
    test('cập nhật phonetic, definition, partOfSpeech đúng', () async {
      await insertWord(db, 'world', 'en-US');

      await db.wordDao.updateWordEnrichment(
        'world', 'en-US',
        phonetic: '/wɜːrld/',
        definition: 'The earth and all life on it',
        partOfSpeechValue: 'noun',
      );

      final w = await db.wordDao.getWord('world', 'en-US');
      expect(w!.phonetic, equals('/wɜːrld/'));
      expect(w.definition, equals('The earth and all life on it'));
      expect(w.partOfSpeech, equals('noun'));
    });

    test('saveDefinitionNative lưu nghĩa tiếng Việt', () async {
      await insertWord(db, 'hello', 'en-US');

      await db.wordDao.saveDefinitionNative('hello', 'en-US', 'Xin chào');

      final w = await db.wordDao.getWord('hello', 'en-US');
      expect(w!.definitionNative, equals('Xin chào'));
    });
  });

  // ─────────────────────────────────────────────
  // Delete
  // ─────────────────────────────────────────────
  group('WordDao: delete methods', () {
    test('deleteAllWords xóa toàn bộ từ của một ngôn ngữ', () async {
      await insertWord(db, 'a', 'en-US');
      await insertWord(db, 'b', 'en-US');
      await insertWord(db, 'c', 'fr-FR');

      await db.wordDao.deleteAllWords('en-US');

      expect(await db.wordDao.countWordsForLang('en-US'), equals(0));
      expect(await db.wordDao.countWordsForLang('fr-FR'), equals(1));
    });

    test('deleteBadWords chỉ xóa đúng các từ trong set', () async {
      await insertWord(db, 'bad1', 'en-US');
      await insertWord(db, 'bad2', 'en-US');
      await insertWord(db, 'good', 'en-US');

      await db.wordDao.deleteBadWords('en-US', {'bad1', 'bad2'});

      expect(await db.wordDao.countWordsForLang('en-US'), equals(1));
      final good = await db.wordDao.getWord('good', 'en-US');
      expect(good, isNotNull);
    });

    test('getUnenrichedWords chỉ trả về từ definition=null', () async {
      await insertWord(db, 'no_def', 'en-US'); // definition=null
      await insertWord(db, 'has_def', 'en-US', definition: 'A def');

      final unenriched = await db.wordDao.getUnenrichedWords('en-US');
      expect(unenriched.length, equals(1));
      expect(unenriched.first.word, equals('no_def'));
    });

    test('insertWords batch insert nhiều từ cùng lúc', () async {
      await db.wordDao.insertWords([
        const WordsCompanion(
            word: Value('batch1'),
            langCode: Value('en-US'),
            source: Value('remote')),
        const WordsCompanion(
            word: Value('batch2'),
            langCode: Value('en-US'),
            source: Value('remote')),
        const WordsCompanion(
            word: Value('batch3'),
            langCode: Value('en-US'),
            source: Value('remote')),
      ]);

      expect(await db.wordDao.countWordsForLang('en-US'), equals(3));
    });
  });
}
