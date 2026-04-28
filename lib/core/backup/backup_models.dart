library;

/// Data models cho Backup & Restore
/// Dùng để serialize/deserialize dữ liệu học sang JSON

class BackupWord {
  final String word;
  final String langCode;
  final String? phonetic;
  final String? phoneticUK;
  final String? audioUs;
  final String? audioUk;
  final String? partOfSpeech;
  final String? definition;
  final String? definitionNative;
  final String? example;
  final String? romanization;
  final String source;

  const BackupWord({
    required this.word,
    required this.langCode,
    this.phonetic,
    this.phoneticUK,
    this.audioUs,
    this.audioUk,
    this.partOfSpeech,
    this.definition,
    this.definitionNative,
    this.example,
    this.romanization,
    this.source = 'backup',
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'langCode': langCode,
        if (phonetic != null) 'phonetic': phonetic,
        if (phoneticUK != null) 'phoneticUK': phoneticUK,
        if (audioUs != null) 'audioUs': audioUs,
        if (audioUk != null) 'audioUk': audioUk,
        if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
        if (definition != null) 'definition': definition,
        if (definitionNative != null) 'definitionNative': definitionNative,
        if (example != null) 'example': example,
        if (romanization != null) 'romanization': romanization,
        'source': source,
      };

  factory BackupWord.fromJson(Map<String, dynamic> j) => BackupWord(
        word: j['word'] as String,
        langCode: j['langCode'] as String,
        phonetic: j['phonetic'] as String?,
        phoneticUK: j['phoneticUK'] as String?,
        audioUs: j['audioUs'] as String?,
        audioUk: j['audioUk'] as String?,
        partOfSpeech: j['partOfSpeech'] as String?,
        definition: j['definition'] as String?,
        definitionNative: j['definitionNative'] as String?,
        example: j['example'] as String?,
        romanization: j['romanization'] as String?,
        source: j['source'] as String? ?? 'backup',
      );
}

class BackupProgress {
  final String word;
  final String langCode;
  final String status;
  final int reviewCount;
  final int correctCount;
  final double easeFactor;
  final int interval;
  final int? nextReview;
  final int? lastSeen;
  final int updatedAt; // Unix ms — dùng cho conflict resolution

  const BackupProgress({
    required this.word,
    required this.langCode,
    required this.status,
    required this.reviewCount,
    required this.correctCount,
    required this.easeFactor,
    required this.interval,
    this.nextReview,
    this.lastSeen,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'langCode': langCode,
        'status': status,
        'reviewCount': reviewCount,
        'correctCount': correctCount,
        'easeFactor': easeFactor,
        'interval': interval,
        if (nextReview != null) 'nextReview': nextReview,
        if (lastSeen != null) 'lastSeen': lastSeen,
        'updatedAt': updatedAt,
      };

  factory BackupProgress.fromJson(Map<String, dynamic> j) => BackupProgress(
        word: j['word'] as String,
        langCode: j['langCode'] as String,
        status: j['status'] as String? ?? 'new',
        reviewCount: j['reviewCount'] as int? ?? 0,
        correctCount: j['correctCount'] as int? ?? 0,
        easeFactor: (j['easeFactor'] as num?)?.toDouble() ?? 2.5,
        interval: j['interval'] as int? ?? 1,
        nextReview: j['nextReview'] as int?,
        lastSeen: j['lastSeen'] as int?,
        updatedAt:
            j['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
}

class BackupData {
  static const int currentVersion = 1;

  final int version;
  final String exportedAt; // ISO8601
  final String appVersion;
  final String primaryLang;
  final String? secondaryLang;
  final List<BackupWord> words;
  final List<BackupProgress> progress;

  const BackupData({
    this.version = currentVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.primaryLang,
    this.secondaryLang,
    required this.words,
    required this.progress,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt,
        'appVersion': appVersion,
        'primaryLang': primaryLang,
        if (secondaryLang != null) 'secondaryLang': secondaryLang,
        'words': words.map((w) => w.toJson()).toList(),
        'progress': progress.map((p) => p.toJson()).toList(),
      };

  factory BackupData.fromJson(Map<String, dynamic> j) => BackupData(
        version: j['version'] as int? ?? 1,
        exportedAt: j['exportedAt'] as String? ?? '',
        appVersion: j['appVersion'] as String? ?? '1.0.0',
        primaryLang: j['primaryLang'] as String? ?? 'en-US',
        secondaryLang: j['secondaryLang'] as String?,
        words: (j['words'] as List<dynamic>? ?? [])
            .map((w) => BackupWord.fromJson(w as Map<String, dynamic>))
            .toList(),
        progress: (j['progress'] as List<dynamic>? ?? [])
            .map((p) => BackupProgress.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

/// Kết quả sau mỗi thao tác backup/restore
class BackupResult {
  final bool success;
  final String? error;
  final int? wordCount;
  final int? progressCount;

  const BackupResult({
    required this.success,
    this.error,
    this.wordCount,
    this.progressCount,
  });

  factory BackupResult.ok({int? words, int? progress}) => BackupResult(
        success: true,
        wordCount: words,
        progressCount: progress,
      );

  factory BackupResult.fail(String error) =>
      BackupResult(success: false, error: error);
}
