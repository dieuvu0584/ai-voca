import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import 'backup_models.dart';

const _kLastBackupKey = 'last_backup_timestamp';
const _kAppVersion = '1.0.0';

/// BackupService — quản lý sao lưu và khôi phục dữ liệu học
///
/// Hỗ trợ 2 phương thức:
///   1. Local JSON  — export/import file JSON thủ công
///   2. Cloud Firestore — sync tự động với tài khoản Google
class BackupService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BackupService(this._db);

  // ── Helpers ─────────────────────────────────────────────────

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Document ID an toàn từ langCode + word
  String _docId(String langCode, String word) {
    final key = '$langCode|$word';
    return base64Url.encode(utf8.encode(key)).replaceAll('=', '');
  }

  DateTime? get lastBackupTime {
    // Đọc synchronous từ SharedPreferences — gọi async version riêng
    return null;
  }

  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastBackupKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> _saveLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastBackupKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ── Đọc dữ liệu từ DB ────────��───────────────────────────────

  /// Lấy tất c��� dữ liệu cần backup từ SQLite
  Future<BackupData> _buildBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryLang = prefs.getString('primary_lang') ?? 'en-US';
    final secondaryLang = prefs.getString('secondary_lang');

    // Lấy tất cả lang codes cần backup
    final langs = <String>{primaryLang, ?secondaryLang};

    final backupWords = <BackupWord>[];
    final backupProgress = <BackupProgress>[];

    for (final lang in langs) {
      // Words
      final words = await _db.wordDao.getAllWordsForLang(lang);
      backupWords.addAll(words.map((w) => BackupWord(
            word: w.word,
            langCode: w.langCode,
            phonetic: w.phonetic,
            phoneticUK: w.phoneticUK,
            audioUs: w.audioUs,
            audioUk: w.audioUk,
            partOfSpeech: w.partOfSpeech,
            definition: w.definition,
            definitionNative: w.definitionNative,
            example: w.example,
            romanization: w.romanization,
            source: w.source,
          )));

      // Progress
      final progList = await _db.progressDao.getAllProgressForLang(lang);
      backupProgress.addAll(progList.map((p) => BackupProgress(
            word: p.word,
            langCode: p.langCode,
            status: p.status,
            reviewCount: p.reviewCount,
            correctCount: p.correctCount,
            easeFactor: p.easeFactor,
            interval: p.interval,
            nextReview: p.nextReview,
            lastSeen: p.lastSeen,
            updatedAt: p.lastSeen ?? DateTime.now().millisecondsSinceEpoch,
          )));
    }

    return BackupData(
      exportedAt: DateTime.now().toIso8601String(),
      appVersion: _kAppVersion,
      primaryLang: primaryLang,
      secondaryLang: secondaryLang,
      words: backupWords,
      progress: backupProgress,
    );
  }

  // ── Ghi dữ liệu vào DB ─────────���─────────────────────────────

  /// Khôi phục dữ liệu từ BackupData vào SQLite
  /// Chiến lược: upsert (giữ data mới hơn)
  Future<void> _restoreToDb(BackupData data) async {
    // Restore words
    if (data.words.isNotEmpty) {
      final companions = data.words
          .map((w) => WordsCompanion(
                word: Value(w.word),
                langCode: Value(w.langCode),
                phonetic: Value(w.phonetic),
                phoneticUK: Value(w.phoneticUK),
                audioUs: Value(w.audioUs),
                audioUk: Value(w.audioUk),
                partOfSpeech: Value(w.partOfSpeech),
                definition: Value(w.definition),
                definitionNative: Value(w.definitionNative),
                example: Value(w.example),
                romanization: Value(w.romanization),
                source: Value(w.source),
              ))
          .toList();
      await _db.wordDao.insertWords(companions);
    }

    // Restore progress — only update if restored data has higher progress
    for (final p in data.progress) {
      final existing = await _db.progressDao.getProgress(p.word, p.langCode);
      // Ưu tiên status "cao hơn" — known > review > learning > new
      final shouldUpdate = existing == null ||
          _statusRank(p.status) > _statusRank(existing.status) ||
          (p.updatedAt > (existing.lastSeen ?? 0));

      if (shouldUpdate) {
        await _db.progressDao.upsertProgress(WordProgressCompanion(
          word: Value(p.word),
          langCode: Value(p.langCode),
          status: Value(p.status),
          reviewCount: Value(p.reviewCount),
          correctCount: Value(p.correctCount),
          easeFactor: Value(p.easeFactor),
          interval: Value(p.interval),
          nextReview: Value(p.nextReview),
          lastSeen: Value(p.lastSeen),
        ));
      }
    }

    // Lưu ngôn ngữ primary/secondary nếu chưa có
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('primary_lang')) {
      await prefs.setString('primary_lang', data.primaryLang);
    }
    if (data.secondaryLang != null && !prefs.containsKey('secondary_lang')) {
      await prefs.setString('secondary_lang', data.secondaryLang!);
    }
  }

  int _statusRank(String status) {
    switch (status) {
      case 'known':
        return 4;
      case 'review':
        return 3;
      case 'learning':
        return 2;
      case 'new':
        return 1;
      default:
        return 0;
    }
  }

  // ── LOCAL JSON ───────────────────────────────────────────────

  /// Export dữ liệu ra file JSON và mở share sheet
  Future<BackupResult> exportToJson() async {
    try {
      final data = await _buildBackupData();
      final json = jsonEncode(data.toJson());

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final file = File('${dir.path}/vocabai_backup_$timestamp.json');
      await file.writeAsString(json, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'VocabAI Backup $timestamp',
      );

      return BackupResult.ok(
        words: data.words.length,
        progress: data.progress.length,
      );
    } catch (e) {
      debugPrint('[BackupService] exportToJson error: $e');
      return BackupResult.fail(e.toString());
    }
  }

  /// Import dữ liệu từ file JSON do user chọn
  Future<BackupResult> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return BackupResult.fail('Không có file được chọn');
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) return BackupResult.fail('Không đọc được file');

      final jsonStr = utf8.decode(bytes);
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final data = BackupData.fromJson(jsonMap);

      await _restoreToDb(data);

      return BackupResult.ok(
        words: data.words.length,
        progress: data.progress.length,
      );
    } catch (e) {
      debugPrint('[BackupService] importFromJson error: $e');
      return BackupResult.fail(e.toString());
    }
  }

  // ── CLOUD FIRESTORE ──────────��───────────────────────────────

  /// Upload dữ liệu lên Firestore
  Future<BackupResult> syncToCloud() async {
    final uid = _uid;
    if (uid == null) return BackupResult.fail('Chưa đăng nhập');

    try {
      final data = await _buildBackupData();
      final batch = _firestore.batch();

      final userRef = _firestore.collection('users').doc(uid);

      // Profile document
      batch.set(
        userRef,
        {
          'primaryLang': data.primaryLang,
          'secondaryLang': data.secondaryLang,
          'appVersion': data.appVersion,
          'lastSync': FieldValue.serverTimestamp(),
          'wordCount': data.words.length,
          'progressCount': data.progress.length,
        },
        SetOptions(merge: true),
      );

      // Words — batch write (Firestore batch max 500 ops)
      final wordsCol = userRef.collection('words');
      for (final w in data.words) {
        final docId = _docId(w.langCode, w.word);
        batch.set(wordsCol.doc(docId), w.toJson(), SetOptions(merge: true));
      }

      // Firestore batch limit = 500. Nếu > 500 từ, chia batch
      if (data.words.length <= 400) {
        await batch.commit();
      } else {
        // Commit profile
        final profileBatch = _firestore.batch();
        profileBatch.set(
          userRef,
          {
            'primaryLang': data.primaryLang,
            'secondaryLang': data.secondaryLang,
            'appVersion': data.appVersion,
            'lastSync': FieldValue.serverTimestamp(),
            'wordCount': data.words.length,
            'progressCount': data.progress.length,
          },
          SetOptions(merge: true),
        );
        await profileBatch.commit();

        // Commit words in chunks of 400
        await _batchWriteChunked(
          wordsCol,
          data.words.map((w) => MapEntry(_docId(w.langCode, w.word), w.toJson())).toList(),
        );
      }

      // Sync progress
      final progressCol = userRef.collection('progress');
      await _batchWriteChunked(
        progressCol,
        data.progress
            .map((p) => MapEntry(_docId(p.langCode, p.word), p.toJson()))
            .toList(),
      );

      await _saveLastBackupTime();

      return BackupResult.ok(
        words: data.words.length,
        progress: data.progress.length,
      );
    } catch (e) {
      debugPrint('[BackupService] syncToCloud error: $e');
      return BackupResult.fail(e.toString());
    }
  }

  /// Tải dữ liệu từ Firestore và restore vào DB
  Future<BackupResult> restoreFromCloud() async {
    final uid = _uid;
    if (uid == null) return BackupResult.fail('Chưa đăng nhập');

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final profileSnap = await userRef.get();

      if (!profileSnap.exists) {
        return BackupResult.fail('Không tìm thấy backup trên cloud');
      }

      final profileData = profileSnap.data()!;

      // Tải words
      final wordsSnap = await userRef.collection('words').get();
      final words = wordsSnap.docs
          .map((d) => BackupWord.fromJson(d.data()))
          .toList();

      // Tải progress
      final progressSnap = await userRef.collection('progress').get();
      final progress = wordsSnap.docs.isNotEmpty
          ? progressSnap.docs
              .map((d) => BackupProgress.fromJson(d.data()))
              .toList()
          : <BackupProgress>[];

      final data = BackupData(
        exportedAt: DateTime.now().toIso8601String(),
        appVersion: profileData['appVersion'] as String? ?? _kAppVersion,
        primaryLang: profileData['primaryLang'] as String? ?? 'en-US',
        secondaryLang: profileData['secondaryLang'] as String?,
        words: words,
        progress: progress,
      );

      await _restoreToDb(data);

      return BackupResult.ok(
        words: words.length,
        progress: progress.length,
      );
    } catch (e) {
      debugPrint('[BackupService] restoreFromCloud error: $e');
      return BackupResult.fail(e.toString());
    }
  }

  /// Kiểm tra có backup trên cloud không (dùng khi mở app lần đầu sau cài lại)
  Future<bool> hasCloudBackup() async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final snap =
          await _firestore.collection('users').doc(uid).get();
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ─────���───────────────────────────────────────────

  /// Write nhiều documents theo chunks để tránh Firestore batch limit (500)
  Future<void> _batchWriteChunked(
    CollectionReference col,
    List<MapEntry<String, Map<String, dynamic>>> entries, {
    int chunkSize = 400,
  }) async {
    for (int i = 0; i < entries.length; i += chunkSize) {
      final chunk = entries.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final entry in chunk) {
        batch.set(col.doc(entry.key), entry.value, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}
