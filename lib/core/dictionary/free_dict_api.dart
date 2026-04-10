import 'package:dio/dio.dart';

class DictEntry {
  final String word;
  final String phoneticUS;
  final String phoneticUK;
  final String audioUS;
  final String audioUK;
  final String partOfSpeech;
  final String definition;
  final String example;

  const DictEntry({
    required this.word,
    this.phoneticUS = '',
    this.phoneticUK = '',
    this.audioUS = '',
    this.audioUK = '',
    this.partOfSpeech = '',
    this.definition = '',
    this.example = '',
  });
}

class FreeDictApi {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.dictionaryapi.dev/api/v2/entries/en',
  ));

  Future<DictEntry?> lookup(String word) async {
    try {
      final response = await _dio.get('/$word');
      final entries = response.data as List;
      if (entries.isEmpty) return null;

      final entry = entries[0] as Map<String, dynamic>;

      String phoneticUS = '', phoneticUK = '', audioUS = '', audioUK = '';

      final phonetics = entry['phonetics'] as List? ?? [];
      for (final ph in phonetics) {
        final audio = (ph['audio'] ?? '') as String;
        final text = (ph['text'] ?? '') as String;
        if (audio.contains('-us') ||
            audio.contains('_us') ||
            (audioUS.isEmpty && audio.isNotEmpty)) {
          if (phoneticUS.isEmpty) phoneticUS = text;
          if (audioUS.isEmpty) audioUS = audio;
        }
        if (audio.contains('-uk') || audio.contains('_uk')) {
          if (phoneticUK.isEmpty) phoneticUK = text;
          if (audioUK.isEmpty) audioUK = audio;
        }
      }
      if (phoneticUS.isEmpty) phoneticUS = (entry['phonetic'] ?? '') as String;
      if (phoneticUK.isEmpty) phoneticUK = phoneticUS;

      final meanings = entry['meanings'] as List? ?? [];
      String partOfSpeech = '', definition = '', example = '';
      if (meanings.isNotEmpty) {
        final meaning = meanings[0] as Map<String, dynamic>;
        partOfSpeech = (meaning['partOfSpeech'] ?? '') as String;
        final defs = meaning['definitions'] as List? ?? [];
        if (defs.isNotEmpty) {
          final def = defs[0] as Map<String, dynamic>;
          definition = (def['definition'] ?? '') as String;
          example = (def['example'] ?? '') as String;
        }
      }

      return DictEntry(
        word: word,
        phoneticUS: phoneticUS,
        phoneticUK: phoneticUK,
        audioUS: audioUS,
        audioUK: audioUK,
        partOfSpeech: partOfSpeech,
        definition: definition,
        example: example,
      );
    } on DioException {
      return null;
    }
  }
}
