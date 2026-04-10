import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/db/database.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';
import 'flashcard_card.dart';
import 'secondary_strip.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  List<Word> _words = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _loading = true;
  String? _aiExplanation;
  bool _aiLoading = false;
  int? _sessionId;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final langCode = ref.read(languageProvider).primary.code;
    final wordDao = ref.read(wordDaoProvider);
    final progressDao = ref.read(progressDaoProvider);

    // Start session
    _sessionId = await progressDao.startSession(langCode);

    // Load words to study (new + due)
    final allWords = await wordDao.getAllWordsForLang(langCode);
    final List<Word> studyWords = [];

    for (final w in allWords) {
      final p = await progressDao.getProgress(w.word, langCode);
      if (p == null || p.status == 'new' || p.status == 'learning' || p.status == 'review') {
        if (p?.status != 'skipped') {
          studyWords.add(w);
        }
      }
    }

    setState(() {
      _words = studyWords;
      _loading = false;
    });
  }

  void _flipCard() {
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _rate(int rating) async {
    if (_currentIndex >= _words.length) return;

    final langCode = ref.read(languageProvider).primary.code;
    final progressDao = ref.read(progressDaoProvider);
    final word = _words[_currentIndex];

    await progressDao.updateSM2(word.word, langCode, rating);

    // If forgot, request AI explanation
    if (rating == 0) {
      _requestAIExplanation(word);
    }

    setState(() {
      _aiExplanation = null;
      _isFlipped = false;
      _currentIndex++;
    });

    // End session if done
    if (_currentIndex >= _words.length) {
      _endSession();
    }
  }

  Future<void> _requestAIExplanation(Word word) async {
    final aiService = ref.read(aiServiceProvider);
    if (aiService == null) return;

    setState(() => _aiLoading = true);

    final langState = ref.read(languageProvider);
    final result = await aiService.complete(
      messages: [
        {
          'role': 'user',
          'content':
              'Giai thich tu "${word.word}" (${word.partOfSpeech}) trong ${langState.primary.name}. '
              'Cho meo nho va vi du de hieu. Tra loi bang tieng Viet, ngan gon.'
        }
      ],
      systemPrompt:
          'Ban la tro ly day tu vung. Tra loi bang tieng Viet, ngan gon, de hieu.',
    );

    if (mounted) {
      setState(() {
        _aiExplanation = result;
        _aiLoading = false;
      });
    }
  }

  Future<void> _askAI() async {
    if (_currentIndex >= _words.length) return;
    _requestAIExplanation(_words[_currentIndex]);
  }

  void _endSession() async {
    if (_sessionId == null) return;
    final progressDao = ref.read(progressDaoProvider);
    await progressDao.endSession(
      _sessionId!,
      wordsStudied: _currentIndex,
      wordsKnown: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final langState = ref.watch(languageProvider);
    final aiSettings = ref.watch(aiSettingsProvider);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDone = _currentIndex >= _words.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _endSession();
            context.go('/');
          },
        ),
        title: isDone
            ? const Text('Hoan thanh!')
            : Text('${_currentIndex + 1} / ${_words.length}'),
      ),
      body: SafeArea(
        top: false,
        child: isDone
          ? _buildDoneView()
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v.abs() < 200) return;
                if (v > 0) {
                  _rate(2); // swipe right = Nhớ
                } else {
                  _rate(0); // swipe left = Quên
                }
              },
              child: Column(
                children: [
                  Expanded(
                    child: FlashcardCard(
                      word: _words[_currentIndex],
                      isFlipped: _isFlipped,
                      onFlip: _flipCard,
                      aiExplanation: _aiExplanation,
                      aiLoading: _aiLoading,
                      ttsService: ref.read(ttsServiceProvider),
                      ttsLang: langState.primary.ttsLang,
                    ),
                  ),
                  if (langState.secondary != null && !isDone)
                    SecondaryStrip(
                      word: _words[_currentIndex],
                      language: langState.secondary!,
                      ttsService: ref.read(ttsServiceProvider),
                    ),
                  if (!_isFlipped)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swipe_left, size: 16, color: Colors.red[300]),
                          const SizedBox(width: 4),
                          Text('Quên', style: TextStyle(fontSize: 12, color: Colors.red[300])),
                          const SizedBox(width: 24),
                          Text('Nhớ', style: TextStyle(fontSize: 12, color: Colors.green[600])),
                          const SizedBox(width: 4),
                          Icon(Icons.swipe_right, size: 16, color: Colors.green[600]),
                        ],
                      ),
                    ),
                  if (_isFlipped && !isDone) _buildRatingButtons(),
                  if (!isDone && aiSettings.mode != AIMode.none)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextButton.icon(
                        onPressed: _aiLoading ? null : _askAI,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Hoi AI ve tu nay'),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildRatingButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _rate(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Quen'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _rate(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: warningOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kho'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _rate(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: successGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Nho'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 64, color: successGreen),
          const SizedBox(height: 16),
          Text(
            'Tuyet voi!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ban da hoc xong ${_words.length} tu',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Quay lai'),
          ),
        ],
      ),
    );
  }
}
