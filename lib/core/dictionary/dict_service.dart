import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/word_dao.dart';
import 'free_dict_api.dart';

class DictService {
  final WordDao _wordDao;
  final FreeDictApi _api = FreeDictApi();

  DictService(this._wordDao);

  /// Tra từ: SQLite cache → API → null
  Future<Word?> lookup(String word, String langCode) async {
    // 1. Tìm trong cache
    final cached = await _wordDao.getWord(word.toLowerCase(), langCode);
    if (cached != null) return cached;

    // 2. Nếu là English và online → gọi API
    if (langCode.startsWith('en')) {
      final entry = await _api.lookup(word.toLowerCase());
      if (entry != null) {
        final companion = WordsCompanion(
          word: Value(entry.word),
          langCode: Value(langCode),
          phonetic: Value(entry.phoneticUS),
          phoneticUK: Value(entry.phoneticUK),
          audioUs: Value(entry.audioUS),
          audioUk: Value(entry.audioUK),
          partOfSpeech: Value(entry.partOfSpeech),
          definition: Value(entry.definition),
          example: Value(entry.example),
          source: const Value('api'),
          cachedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        );
        await _wordDao.insertWord(companion);
        return _wordDao.getWord(entry.word, langCode);
      }
    }

    return null;
  }
}
