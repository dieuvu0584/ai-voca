library;

/// Một từ/cụm từ được AI trích xuất từ nội dung import
class ImportedWord {
  final String word;
  final String definition;
  final String? example;
  final String? partOfSpeech;
  final bool isPhrase;

  /// Đã tồn tại trong DB — đánh dấu trong preview UI
  bool alreadyInDb;

  /// User tick chọn để import
  bool selected;

  ImportedWord({
    required this.word,
    required this.definition,
    this.example,
    this.partOfSpeech,
    this.isPhrase = false,
    this.alreadyInDb = false,
    this.selected = true,
  });

  factory ImportedWord.fromJson(Map<String, dynamic> j) => ImportedWord(
        word: (j['word'] as String? ?? '').trim(),
        definition: (j['definition'] as String? ?? '').trim(),
        example: (j['example'] as String?)?.trim(),
        partOfSpeech: j['partOfSpeech'] as String?,
        isPhrase: j['isPhrase'] as bool? ?? false,
      );

  ImportedWord copyWith({bool? selected, bool? alreadyInDb}) => ImportedWord(
        word: word,
        definition: definition,
        example: example,
        partOfSpeech: partOfSpeech,
        isPhrase: isPhrase,
        alreadyInDb: alreadyInDb ?? this.alreadyInDb,
        selected: selected ?? this.selected,
      );
}

/// Nguồn import
enum ImportSource { text, url, image, voice }

extension ImportSourceExt on ImportSource {
  String get dbValue => name; // 'text'|'url'|'image'|'voice'

  String get label {
    switch (this) {
      case ImportSource.text:
        return 'Văn bản';
      case ImportSource.url:
        return 'URL';
      case ImportSource.image:
        return 'Ảnh';
      case ImportSource.voice:
        return 'Giọng nói';
    }
  }
}

/// Kết quả sau khi AI parse
class ImportParseResult {
  final List<ImportedWord> words;
  final String? error;
  final ImportSource source;
  final String? sourceContext; // URL hoặc snippet gốc

  const ImportParseResult({
    required this.words,
    this.error,
    required this.source,
    this.sourceContext,
  });

  bool get success => error == null && words.isNotEmpty;

  factory ImportParseResult.error(ImportSource source, String error) =>
      ImportParseResult(words: [], error: error, source: source);
}
