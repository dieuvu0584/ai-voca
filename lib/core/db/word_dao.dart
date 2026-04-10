import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'word_dao.g.dart';

@DriftAccessor(tables: [Words])
class WordDao extends DatabaseAccessor<AppDatabase> with _$WordDaoMixin {
  WordDao(super.db);

  Future<List<Word>> getAllWordsForLang(String langCode) =>
      (select(words)..where((t) => t.langCode.equals(langCode))).get();

  Future<Word?> getWord(String word, String langCode) =>
      (select(words)
            ..where((t) => t.word.equals(word) & t.langCode.equals(langCode)))
          .getSingleOrNull();

  Future<int> insertWord(WordsCompanion entry) =>
      into(words).insertOnConflictUpdate(entry);

  Future<void> insertWords(List<WordsCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(words, entries);
    });
  }

  Future<int> countWordsForLang(String langCode) async {
    final count = countAll();
    final query = selectOnly(words)
      ..addColumns([count])
      ..where(words.langCode.equals(langCode));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<Word>> searchWords(String query, String langCode) =>
      (select(words)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.word.like('%$query%'))
            ..limit(20))
          .get();
}
