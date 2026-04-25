import 'package:drift/drift.dart';

/// Bảng từ vựng — cached từ API hoặc built-in
class Words extends Table {
  TextColumn get word => text()();
  TextColumn get langCode => text()();
  TextColumn get phonetic => text().nullable()();
  TextColumn get phoneticUK => text().nullable()();
  TextColumn get audioUs => text().nullable()();
  TextColumn get audioUk => text().nullable()();
  TextColumn get partOfSpeech => text().nullable()();
  TextColumn get definition => text().nullable()();
  // Nghĩa trong ngôn ngữ native của user (defLang) — AI translated
  TextColumn get definitionNative => text().nullable()();
  TextColumn get example => text().nullable()();
  TextColumn get romanization => text().nullable()();
  TextColumn get source =>
      text().withDefault(const Constant('local'))(); // 'api'|'cache'|'local'
  IntColumn get cachedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {word, langCode};
}

/// Bảng tiến trình học — per user per language
class WordProgress extends Table {
  TextColumn get word => text()();
  TextColumn get langCode => text()();
  TextColumn get status => text().withDefault(const Constant('new'))();
  // status: 'new' | 'learning' | 'review' | 'known' | 'skipped'
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  IntColumn get nextReview => integer().nullable()();
  IntColumn get lastSeen => integer().nullable()();

  @override
  Set<Column> get primaryKey => {word, langCode};
}

/// Bảng phiên học
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get langCode => text()();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  IntColumn get wordsStudied => integer().withDefault(const Constant(0))();
  IntColumn get wordsKnown => integer().withDefault(const Constant(0))();
}
