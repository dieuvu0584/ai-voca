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

  /// Xóa toàn bộ definitionNative của một ngôn ngữ (khi đổi ngôn ngữ dịch)
  Future<void> clearDefinitionNative(String langCode) =>
      (update(words)..where((t) => t.langCode.equals(langCode)))
          .write(const WordsCompanion(definitionNative: Value(null)));

  /// Cập nhật chỉ các field enrich (phonetic, definition, example...)
  /// KHÔNG overwrite source/langCode/word — dùng cho linked words
  Future<void> updateWordEnrichment(
    String word,
    String langCode, {
    String? phonetic,
    String? romanization,
    String? definition,
    String? example,
    String? partOfSpeechValue,
    String? audioUs,
    String? audioUk,
  }) async {
    await (update(words)
          ..where((t) => t.word.equals(word) & t.langCode.equals(langCode)))
        .write(WordsCompanion(
      phonetic: phonetic != null ? Value(phonetic) : const Value.absent(),
      romanization: romanization != null ? Value(romanization) : const Value.absent(),
      definition: definition != null ? Value(definition) : const Value.absent(),
      example: example != null ? Value(example) : const Value.absent(),
      partOfSpeech: partOfSpeechValue != null ? Value(partOfSpeechValue) : const Value.absent(),
      audioUs: audioUs != null ? Value(audioUs) : const Value.absent(),
      audioUk: audioUk != null ? Value(audioUk) : const Value.absent(),
    ));
  }

  /// Lưu definitionNative (nghĩa dịch theo ngôn ngữ defLang)
  Future<void> saveDefinitionNative(
      String word, String langCode, String definition) =>
      (update(words)
            ..where((t) =>
                t.word.equals(word) & t.langCode.equals(langCode)))
          .write(WordsCompanion(
              definitionNative: Value(definition)));

  /// Lấy các từ chưa được enrich (definition IS NULL) — dùng cho retry.
  /// Quy ước:
  ///   definition = NULL → chưa thử enrich, hoặc cần retry
  ///   definition = ''   → đã thử, API không có entry (không retry nữa)
  ///   definition = text → đã enrich thành công
  Future<List<Word>> getUnenrichedWords(String langCode, {int limit = 50}) =>
      (select(words)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.definition.isNull())
            ..limit(limit))
          .get();

  /// Lấy tất cả từ source='remote' của một ngôn ngữ
  Future<List<Word>> getRemoteWords(String langCode) =>
      (select(words)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.source.equals('remote')))
          .get();

  /// Xóa tất cả từ source='remote' của một ngôn ngữ (dùng để reset sync)
  Future<int> deleteRemoteWords(String langCode) =>
      (delete(words)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.source.equals('remote')))
          .go();

  /// Xóa tất cả từ source='linked' của một ngôn ngữ (ngôn ngữ phụ AI-generated)
  Future<int> deleteLinkedWords(String langCode) =>
      (delete(words)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.source.equals('linked')))
          .go();

  /// Xóa toàn bộ từ của một ngôn ngữ (mọi source: remote, linked, local)
  Future<int> deleteAllWords(String langCode) =>
      (delete(words)
            ..where((t) => t.langCode.equals(langCode)))
          .go();

  /// Xóa hàng loạt các từ xấu (typo, mảnh contraction...) khỏi bảng words
  Future<void> deleteBadWords(String langCode, Set<String> badWords) async {
    if (badWords.isEmpty) return;
    await (delete(words)
          ..where((t) =>
              t.langCode.equals(langCode) & t.word.isIn(badWords.toList())))
        .go();
  }

  /// Tìm từ theo definitionNative (dùng để tìm từ tương đương trong ngôn ngữ phụ)
  Future<Word?> findByDefinitionNative(String meaning, String langCode) =>
      (select(words)
            ..where((t) =>
                t.langCode.equals(langCode) &
                t.definitionNative.equals(meaning))
            ..limit(1))
          .getSingleOrNull();

  /// Tìm từ theo source='linked' và definition (linked từ ngôn ngữ chính)
  Future<Word?> findLinkedWord(String primaryWord, String secondaryLang) =>
      (select(words)
            ..where((t) =>
                t.langCode.equals(secondaryLang) &
                t.source.equals('linked') &
                t.partOfSpeech.equals('linked:$primaryWord'))
            ..limit(1))
          .getSingleOrNull();
}
