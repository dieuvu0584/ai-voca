import 'package:flutter/material.dart';
import '../../app.dart';
import '../../core/db/database.dart';
import '../../core/tts/tts_service.dart';
import '../../data/languages.dart';
import '../../data/vocab_data.dart';

class SecondaryStrip extends StatelessWidget {
  final Word word;
  final Language language;
  final TtsService ttsService;

  const SecondaryStrip({
    super.key,
    required this.word,
    required this.language,
    required this.ttsService,
  });

  // Strip flag emoji + leading spaces to get plain Vietnamese meaning text.
  // Meaning format is always "🇻🇳 nghĩa tiếng Việt"
  static String _stripFlag(String? s) {
    if (s == null || s.isEmpty) return '';
    final spaceIdx = s.indexOf(' ');
    if (spaceIdx < 0) return s.toLowerCase().trim();
    return s.substring(spaceIdx + 1).toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context) {
    final builtinWords = kBuiltinVocab[language.code] ?? [];
    if (builtinWords.isEmpty) return const SizedBox.shrink();

    // Match by Vietnamese meaning: find the secondary-language word
    // whose meaning corresponds to the primary word's definition/meaning.
    // e.g. English "iterate" has definition "🇻🇳 lặp lại"
    //      Korean "반복하다" has meaning "🇻🇳 lặp lại" → match!
    final primaryMeaning = _stripFlag(word.definition ?? word.word);

    BuiltinWord? secondaryWord;
    if (primaryMeaning.isNotEmpty) {
      for (final w in builtinWords) {
        if (_stripFlag(w.meaning) == primaryMeaning) {
          secondaryWord = w;
          break;
        }
      }
    }

    // No matching word in secondary language → hide strip
    if (secondaryWord == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secondaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Text(language.flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${language.name} · từ tương đương',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  secondaryWord.romanization != null
                      ? '${secondaryWord.word}  [${secondaryWord.romanization}]'
                      : secondaryWord.word,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  secondaryWord.meaning.substring(
                    secondaryWord.meaning.indexOf(' ') + 1,
                  ),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: secondaryColor),
            onPressed: () => ttsService.speak(
              secondaryWord!.word,
              ttsLang: language.ttsLang,
            ),
          ),
        ],
      ),
    );
  }
}
