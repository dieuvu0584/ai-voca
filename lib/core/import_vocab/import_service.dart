import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../ai/ai_service.dart';
import '../db/database.dart';
import 'import_models.dart';

/// ImportService — trích xuất từ vựng từ text/URL/image/voice qua AI
///
/// Ưu tiên AI:
///   1. Firebase Functions (app key) — nếu Firebase sẵn sàng + đã đăng nhập
///   2. User's own AI key — nếu đã cấu hình trong Settings
///   3. Báo lỗi — cần cấu hình AI
class ImportService {
  final AppDatabase _db;
  final AIService? _userAiService;
  final bool _firebaseReady;

  static const int _maxWords = 25;
  static const int _maxTextLength = 5000;

  ImportService({
    required AppDatabase db,
    required AIService? userAiService,
    required bool firebaseReady,
  })  : _db = db,
        _userAiService = userAiService,
        _firebaseReady = firebaseReady;

  // ── Public API ───────────────────────────────────────────────

  /// Parse văn bản thuần
  Future<ImportParseResult> parseText({
    required String text,
    required String langCode,
    required String defLang,
  }) async {
    if (text.trim().isEmpty) {
      return ImportParseResult.error(ImportSource.text, 'Văn bản trống');
    }
    final truncated = text.length > _maxTextLength
        ? text.substring(0, _maxTextLength)
        : text;

    return _parseWithAI(
      content: truncated,
      langCode: langCode,
      defLang: defLang,
      source: ImportSource.text,
      sourceContext: text.length > 200 ? '${text.substring(0, 200)}...' : text,
    );
  }

  /// Fetch URL → trích xuất text → parse
  Future<ImportParseResult> fetchAndParseUrl({
    required String url,
    required String langCode,
    required String defLang,
  }) async {
    // Chuẩn hóa URL
    if (!url.startsWith('http')) url = 'https://$url';

    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ImportParseResult.error(
          ImportSource.url,
          'Không tải được trang (HTTP ${response.statusCode})',
        );
      }

      final extractedText = _extractTextFromHtml(response.body);
      if (extractedText.trim().isEmpty) {
        return ImportParseResult.error(
            ImportSource.url, 'Không đọc được nội dung trang');
      }

      return _parseWithAI(
        content: extractedText,
        langCode: langCode,
        defLang: defLang,
        source: ImportSource.url,
        sourceContext: url,
      );
    } on SocketException {
      return ImportParseResult.error(ImportSource.url, 'Không có kết nối mạng');
    } catch (e) {
      return ImportParseResult.error(ImportSource.url, e.toString());
    }
  }

  /// Parse ảnh qua Claude Vision — yêu cầu Firebase Functions
  Future<ImportParseResult> parseImage({
    required File imageFile,
    required String langCode,
    required String defLang,
  }) async {
    // Vision chỉ hỗ trợ qua Firebase Function (app's Claude key)
    if (!_firebaseReady || FirebaseAuth.instance.currentUser == null) {
      // Thử dùng user's Claude key nếu có
      if (_userAiService == null) { // ignore: unnecessary_null_comparison
        return ImportParseResult.error(
          ImportSource.image,
          'Cần đăng nhập Google hoặc cấu hình Claude API key để dùng tính năng này',
        );
      }
      // User's own AI key — chỉ Claude hỗ trợ vision trực tiếp
      // Tạm thời báo lỗi nếu không phải Firebase path
      return ImportParseResult.error(
        ImportSource.image,
        'Tính năng nhận dạng ảnh cần đăng nhập với Google (dùng AI của app)',
      );
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : ext == 'gif'
              ? 'image/gif'
              : 'image/jpeg';

      final systemPrompt = _buildSystemPrompt(langCode, defLang);
      final userPrompt =
          'Extract vocabulary from this image. Return JSON array only.';

      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('callClaude');

      final result = await callable.call({
        'systemPrompt': systemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mimeType,
                  'data': base64Image,
                },
              },
              {'type': 'text', 'text': userPrompt},
            ],
          }
        ],
        'maxTokens': 1024,
        'isPremium': false,
      });

      final text = result.data['text'] as String;
      final words = _parseJsonResponse(text);

      return ImportParseResult(
        words: words,
        source: ImportSource.image,
        sourceContext: 'image:${imageFile.path.split('/').last}',
      );
    } catch (e) {
      debugPrint('[ImportService] parseImage error: $e');
      return ImportParseResult.error(ImportSource.image, e.toString());
    }
  }

  /// Parse text từ giọng nói (transcript từ speech_to_text)
  Future<ImportParseResult> parseVoiceText({
    required String transcript,
    required String langCode,
    required String defLang,
  }) async {
    if (transcript.trim().isEmpty) {
      return ImportParseResult.error(
          ImportSource.voice, 'Không nhận được giọng nói');
    }

    return _parseWithAI(
      content: transcript,
      langCode: langCode,
      defLang: defLang,
      source: ImportSource.voice,
      sourceContext: transcript,
    );
  }

  /// Đánh dấu từ đã có trong DB
  Future<void> markDuplicates(
      List<ImportedWord> words, String langCode) async {
    for (final w in words) {
      final existing = await _db.wordDao.getWord(w.word, langCode);
      w.alreadyInDb = existing != null;
    }
  }

  /// Lưu danh sách từ đã chọn vào DB
  Future<int> importWords({
    required List<ImportedWord> words,
    required String langCode,
    required ImportSource source,
    String? sourceContext,
  }) async {
    final selected = words.where((w) => w.selected && !w.alreadyInDb).toList();
    if (selected.isEmpty) return 0;

    final companions = selected
        .map((w) => WordsCompanion(
              word: Value(w.word.toLowerCase().trim()),
              langCode: Value(langCode),
              definition: Value(w.definition.isNotEmpty ? w.definition : null),
              example: Value(w.example),
              partOfSpeech: Value(w.partOfSpeech),
              source: const Value('import'),
              sourceType: Value(source.dbValue),
              sourceContext: Value(sourceContext),
              isPhrase: Value(w.isPhrase),
            ))
        .toList();

    await _db.wordDao.insertWords(companions);
    return selected.length;
  }

  // ── Private helpers ─────────────────────────────────────────

  /// Gọi AI để parse text → word list
  Future<ImportParseResult> _parseWithAI({
    required String content,
    required String langCode,
    required String defLang,
    required ImportSource source,
    String? sourceContext,
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt(langCode, defLang);
      final userPrompt = 'Text to extract vocabulary from:\n\n$content';
      String? rawResponse;

      // Ưu tiên 1: Firebase Function (app's Claude key)
      if (_firebaseReady &&
          FirebaseAuth.instance.currentUser != null) {
        rawResponse = await _callViaFirebase(systemPrompt, userPrompt);
      }

      // Ưu tiên 2: User's own AI key
      if (rawResponse == null && _userAiService != null) {
        rawResponse = await _userAiService.complete(
          messages: [
            {'role': 'user', 'content': userPrompt}
          ],
          systemPrompt: systemPrompt,
          maxTokens: 1024,
        );
      }

      if (rawResponse == null) {
        return ImportParseResult.error(
          source,
          'Không có AI để xử lý. Đăng nhập Google hoặc cấu hình API key trong Settings.',
        );
      }

      final words = _parseJsonResponse(rawResponse);
      if (words.isEmpty) {
        return ImportParseResult.error(source, 'Không tìm thấy từ vựng nào phù hợp');
      }

      return ImportParseResult(
        words: words,
        source: source,
        sourceContext: sourceContext,
      );
    } catch (e) {
      debugPrint('[ImportService] _parseWithAI error: $e');
      return ImportParseResult.error(source, e.toString());
    }
  }

  Future<String?> _callViaFirebase(
      String systemPrompt, String userPrompt) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('callClaude');
      final result = await callable.call({
        'systemPrompt': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userPrompt}
        ],
        'maxTokens': 1024,
        'isPremium': false,
      });
      return result.data['text'] as String?;
    } catch (e) {
      debugPrint('[ImportService] Firebase call error: $e');
      return null;
    }
  }

  String _buildSystemPrompt(String langCode, String defLang) {
    return '''You are a vocabulary extraction assistant.
Extract the most useful and interesting vocabulary from the provided text.
Return ONLY a valid JSON array. No markdown, no explanation, just JSON.

Rules:
- Max $_maxWords words/phrases
- Skip very common words (the, is, have, go, etc.) and proper nouns
- Include multi-word phrases and idioms as single items
- Definitions must be in $defLang language
- Keep definitions concise (1 sentence max)

JSON format (return this exact structure):
[{"word":"string","definition":"string","example":"string or null","partOfSpeech":"noun|verb|adjective|adverb|phrase","isPhrase":false}]''';
  }

  /// Parse JSON response từ AI (robust — handle markdown, whitespace, etc.)
  List<ImportedWord> _parseJsonResponse(String raw) {
    try {
      // Loại bỏ markdown code blocks
      var text = raw
          .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // Tìm JSON array
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) return [];

      final jsonStr = text.substring(start, end + 1);
      final list = jsonDecode(jsonStr) as List<dynamic>;

      return list
          .whereType<Map<String, dynamic>>()
          .map((j) => ImportedWord.fromJson(j))
          .where((w) => w.word.isNotEmpty && w.definition.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[ImportService] JSON parse error: $e\nRaw: $raw');
      return [];
    }
  }

  /// Trích xuất text thuần từ HTML
  String _extractTextFromHtml(String html) {
    var text = html
        // Xóa scripts
        .replaceAll(
            RegExp(r'<script[^>]*>.*?</script>',
                dotAll: true, caseSensitive: false),
            ' ')
        // Xóa styles
        .replaceAll(
            RegExp(r'<style[^>]*>.*?</style>',
                dotAll: true, caseSensitive: false),
            ' ')
        // Xóa tất cả HTML tags
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        // Decode HTML entities cơ bản
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        // Chuẩn hóa khoảng trắng
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Giới hạn độ dài
    if (text.length > _maxTextLength) {
      text = text.substring(0, _maxTextLength);
    }
    return text;
  }
}
