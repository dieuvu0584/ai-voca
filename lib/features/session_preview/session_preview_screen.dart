import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/db/database.dart';
import '../../data/vocab_data.dart';
import 'package:drift/drift.dart' hide Column;

class SessionPreviewScreen extends ConsumerStatefulWidget {
  final String mode; // 'flashcard' or 'quick-review'

  const SessionPreviewScreen({super.key, required this.mode});

  @override
  ConsumerState<SessionPreviewScreen> createState() =>
      _SessionPreviewScreenState();
}

class _SessionPreviewScreenState extends ConsumerState<SessionPreviewScreen> {
  List<_PreviewWord> _words = [];
  final Set<int> _skippedIndices = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final langState = ref.read(languageProvider);
    final langCode = langState.primary.code;
    final progressDao = ref.read(progressDaoProvider);
    final wordDao = ref.read(wordDaoProvider);

    // Load built-in words
    final builtinWords = kBuiltinVocab[langCode] ?? [];
    final List<_PreviewWord> words = [];

    for (final bw in builtinWords) {
      // Ensure progress entry exists
      final progress = await progressDao.getProgress(bw.word, langCode);
      if (progress == null) {
        await progressDao.upsertProgress(WordProgressCompanion(
          word: Value(bw.word),
          langCode: Value(langCode),
          status: const Value('new'),
        ));
      }

      // Ensure word entry exists
      final wordEntry = await wordDao.getWord(bw.word, langCode);
      if (wordEntry == null) {
        await wordDao.insertWord(WordsCompanion(
          word: Value(bw.word),
          langCode: Value(langCode),
          phonetic: Value(bw.phonetic),
          phoneticUK: Value(bw.phoneticUK),
          partOfSpeech: Value(bw.type),
          definition: Value(bw.meaning),
          example: Value(bw.example),
          romanization: Value(bw.romanization),
          source: const Value('local'),
        ));
      }

      final p = await progressDao.getProgress(bw.word, langCode);
      if (p != null && p.status != 'skipped' && p.status != 'known') {
        words.add(_PreviewWord(
          word: bw.word,
          phonetic: bw.phonetic ?? '',
          meaning: bw.meaning,
          romanization: bw.romanization,
        ));
      }
    }

    // Also add due words
    final dueWords = await progressDao.getDueWords(langCode);
    for (final dw in dueWords) {
      if (!words.any((w) => w.word == dw.word)) {
        final wordEntry = await wordDao.getWord(dw.word, langCode);
        if (wordEntry != null) {
          words.add(_PreviewWord(
            word: dw.word,
            phonetic: wordEntry.phonetic ?? '',
            meaning: wordEntry.definition ?? '',
            romanization: wordEntry.romanization,
          ));
        }
      }
    }

    setState(() {
      _words = words;
      _loading = false;
    });
  }

  int get _remainingCount => _words.length - _skippedIndices.length;

  void _toggleSkip(int index) {
    setState(() {
      if (_skippedIndices.contains(index)) {
        _skippedIndices.remove(index);
      } else {
        _skippedIndices.add(index);
      }
    });
  }

  Future<void> _confirmStart() async {
    final langCode = ref.read(languageProvider).primary.code;
    final progressDao = ref.read(progressDaoProvider);

    // Mark skipped words
    for (final i in _skippedIndices) {
      await progressDao.skipWord(_words[i].word, langCode);
    }

    if (mounted) {
      final route = widget.mode == 'flashcard' ? '/flashcard' : '/quick-review';
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langState = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phien hoc moi'),
        actions: [
          TextButton(
            onPressed: () {
              final route =
                  widget.mode == 'flashcard' ? '/flashcard' : '/quick-review';
              context.go(route);
            },
            child: const Text('Bo qua'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Khong co tu nao trong hang doi!',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Quay lai'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: enColor.withValues(alpha: 0.05),
                      child: Row(
                        children: [
                          Text(langState.primary.flag,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${langState.primary.name} · ${_words.length} tu trong hang doi',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Nhan "Biet roi" de bo qua tu da biet',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _words.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final w = _words[i];
                          final skipped = _skippedIndices.contains(i);
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: skipped
                                  ? Colors.grey[300]
                                  : enColor.withValues(alpha: 0.1),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: skipped ? Colors.grey : enColor,
                                ),
                              ),
                            ),
                            title: Text(
                              w.romanization != null
                                  ? '${w.word}  [${w.romanization}]'
                                  : '${w.word}  ${w.phonetic}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: skipped
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: skipped ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Text(
                              w.meaning,
                              style: TextStyle(
                                  color: skipped ? Colors.grey : null),
                            ),
                            trailing: TextButton(
                              onPressed: () => _toggleSkip(i),
                              child: Text(
                                skipped ? 'Hoc lai' : 'Biet roi',
                                style: TextStyle(
                                  color: skipped ? enColor : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _remainingCount > 0 ? _confirmStart : null,
                              child: Text(
                                  'Bat dau hoc $_remainingCount tu'),
                            ),
                          ),
                          if (_skippedIndices.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Da bo qua ${_skippedIndices.length} tu ban da biet',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _PreviewWord {
  final String word;
  final String phonetic;
  final String meaning;
  final String? romanization;

  const _PreviewWord({
    required this.word,
    required this.phonetic,
    required this.meaning,
    this.romanization,
  });
}
