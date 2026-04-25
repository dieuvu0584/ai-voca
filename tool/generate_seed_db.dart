/// Script tạo pre-populated SQLite database chứa toàn bộ từ English.
/// Chạy: dart run tool/generate_seed_db.dart
/// Output: assets/databases/en_seed.db
///
/// File này được bundle vào APK. Khi user cài app lần đầu,
/// AppDatabase sẽ copy file này làm DB khởi đầu thay vì tạo DB trống.

import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

// ─── Bộ lọc stopwords (giống vocab_sync_service.dart) ─────────────────────
const _enStopwords = {
  'the', 'a', 'an', 'in', 'on', 'at', 'to', 'of', 'and', 'or', 'but',
  'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
  'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might',
  'this', 'that', 'these', 'those', 'with', 'for', 'from', 'by', 'as',
  'it', 'its', 'he', 'she', 'they', 'we', 'you', 'i', 'me', 'him', 'her',
  'not', 'no', 'so', 'if', 'up', 'out', 'all', 'can', 'just', 'my', 'your',
  'his', 'our', 'their', 'about', 'into', 'than', 'more', 'also', 'some',
  'only', 'then', 'very', 'what', 'when', 'who', 'how', 'any', 'now', 'here',
  'there', 'each', 'other', 'after', 'before', 'over', 'such', 'even', 'most',
};

List<String> parseEnglishWords(String raw) {
  final result = <String>[];
  final alphaOnly = RegExp(r'^[a-z]+$');
  for (final line in raw.split('\n')) {
    final parts = line.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) continue;
    final word = parts[0].trim().toLowerCase();
    if (word.length < 4) continue;
    if (!alphaOnly.hasMatch(word)) continue;
    if (_enStopwords.contains(word)) continue;
    result.add(word);
  }
  return result;
}

void main() {
  final txtFile = File('assets/wordlists/en_50k.txt');
  if (!txtFile.existsSync()) {
    print('ERROR: assets/wordlists/en_50k.txt not found');
    exit(1);
  }

  // Đảm bảo thư mục output tồn tại
  Directory('assets/databases').createSync(recursive: true);

  final outputFile = File('assets/databases/en_seed.db');
  if (outputFile.existsSync()) outputFile.deleteSync();

  print('Đọc danh sách từ...');
  final raw = txtFile.readAsStringSync();
  final words = parseEnglishWords(raw);
  print('Tổng từ sau lọc: ${words.length}');

  print('Tạo SQLite database...');
  final db = sqlite3.open(outputFile.path);

  // ── Tạo schema khớp với Drift schema version 2 ────────────────────────
  db.execute('PRAGMA user_version = 2;');

  db.execute('''
    CREATE TABLE IF NOT EXISTS words (
      word          TEXT NOT NULL,
      lang_code     TEXT NOT NULL,
      phonetic      TEXT,
      phonetic_u_k  TEXT,
      audio_us      TEXT,
      audio_uk      TEXT,
      part_of_speech TEXT,
      definition    TEXT,
      definition_native TEXT,
      example       TEXT,
      romanization  TEXT,
      source        TEXT NOT NULL DEFAULT 'remote',
      cached_at     INTEGER,
      PRIMARY KEY (word, lang_code)
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS word_progress (
      word          TEXT NOT NULL,
      lang_code     TEXT NOT NULL,
      status        TEXT NOT NULL DEFAULT 'new',
      review_count  INTEGER NOT NULL DEFAULT 0,
      correct_count INTEGER NOT NULL DEFAULT 0,
      ease_factor   REAL NOT NULL DEFAULT 2.5,
      interval      INTEGER NOT NULL DEFAULT 1,
      next_review   INTEGER,
      last_seen     INTEGER,
      PRIMARY KEY (word, lang_code)
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS sessions (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      lang_code     TEXT NOT NULL,
      started_at    INTEGER NOT NULL,
      ended_at      INTEGER,
      words_studied INTEGER NOT NULL DEFAULT 0,
      words_known   INTEGER NOT NULL DEFAULT 0
    );
  ''');

  // ── Insert tất cả từ trong 1 transaction ──────────────────────────────
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final stmtWord = db.prepare(
      'INSERT OR IGNORE INTO words (word, lang_code, source, cached_at) VALUES (?, ?, ?, ?)');
  final stmtProgress = db.prepare(
      'INSERT OR IGNORE INTO word_progress (word, lang_code, status) VALUES (?, ?, ?)');

  print('Inserting ${words.length} từ × 2 langCode (en-US, en-GB)...');
  db.execute('BEGIN TRANSACTION');

  for (final word in words) {
    stmtWord.execute([word, 'en-US', 'remote', now]);
    stmtProgress.execute([word, 'en-US', 'new']);
    stmtWord.execute([word, 'en-GB', 'remote', now]);
    stmtProgress.execute([word, 'en-GB', 'new']);
  }

  db.execute('COMMIT');
  stmtWord.dispose();
  stmtProgress.dispose();

  // ── VACUUM để giảm dung lượng file ────────────────────────────────────
  print('VACUUM...');
  db.execute('VACUUM');
  db.dispose();

  final sizeKB = outputFile.lengthSync() ~/ 1024;
  print('✓ Done: assets/databases/en_seed.db ($sizeKB KB, ${words.length} từ)');
}
