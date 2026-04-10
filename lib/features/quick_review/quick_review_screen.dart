import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/db/database.dart';

class QuickReviewScreen extends ConsumerStatefulWidget {
  const QuickReviewScreen({super.key});

  @override
  ConsumerState<QuickReviewScreen> createState() => _QuickReviewScreenState();
}

class _QuickReviewScreenState extends ConsumerState<QuickReviewScreen>
    with SingleTickerProviderStateMixin {
  List<Word> _words = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _loading = true;
  double _dragX = 0;
  bool _autoFlip = false;
  int _autoFlipSeconds = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadWords();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoFlip = prefs.getBool('quick_review_auto_flip') ?? false;
      _autoFlipSeconds = prefs.getInt('quick_review_seconds') ?? 5;
    });
  }

  Future<void> _loadWords() async {
    final langCode = ref.read(languageProvider).primary.code;
    final wordDao = ref.read(wordDaoProvider);
    final progressDao = ref.read(progressDaoProvider);

    final allWords = await wordDao.getAllWordsForLang(langCode);
    final List<Word> studyWords = [];

    for (final w in allWords) {
      final p = await progressDao.getProgress(w.word, langCode);
      if (p == null || p.status != 'skipped') {
        studyWords.add(w);
      }
    }

    setState(() {
      _words = studyWords;
      _loading = false;
    });
  }

  void _flip() => setState(() => _isFlipped = !_isFlipped);

  void _rate(int rating) async {
    if (_currentIndex >= _words.length) return;

    final langCode = ref.read(languageProvider).primary.code;
    await ref
        .read(progressDaoProvider)
        .updateSM2(_words[_currentIndex].word, langCode, rating);

    setState(() {
      _isFlipped = false;
      _dragX = 0;
      _currentIndex++;
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.arrowDown:
        _flip();
      case LogicalKeyboardKey.arrowRight:
        _rate(2); // Nho
      case LogicalKeyboardKey.arrowLeft:
        _rate(0); // Quen
      case LogicalKeyboardKey.arrowUp:
        _rate(1); // Kho
      case LogicalKeyboardKey.escape:
        context.go('/');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isDone = _currentIndex >= _words.length;

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: isDone
              ? _buildDoneView()
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => context.go('/'),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentIndex + 1} / ${_words.length}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    // Progress bar
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _words.length,
                      backgroundColor: Colors.white12,
                      color: warningOrange,
                      minHeight: 3,
                    ),
                    // Card
                    Expanded(
                      child: GestureDetector(
                        onTap: _flip,
                        onHorizontalDragUpdate: (d) =>
                            setState(() => _dragX += d.delta.dx),
                        onHorizontalDragEnd: (d) {
                          if (_dragX > 80) {
                            _rate(2); // Nho
                          } else if (_dragX < -80) {
                            _rate(0); // Quen
                          }
                          setState(() => _dragX = 0);
                        },
                        onVerticalDragEnd: (d) {
                          if (d.velocity.pixelsPerSecond.dy < -200) {
                            _rate(1); // Kho (swipe up)
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: Matrix4.identity()
                            ..translate(_dragX, 0)
                            ..rotateZ(_dragX * 0.001),
                          child: _buildCard(),
                        ),
                      ),
                    ),
                    // Swipe hints
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('← Quen',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3))),
                          Text('Nho →',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rating buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _RatingButton(
                              label: 'Quen',
                              color: errorRed,
                              onTap: () => _rate(0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RatingButton(
                              label: 'Kho',
                              color: warningOrange,
                              onTap: () => _rate(1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RatingButton(
                              label: 'Nho',
                              color: successGreen,
                              onTap: () => _rate(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final word = _words[_currentIndex];
    final langState = ref.watch(languageProvider);

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${langState.primary.flag} ${langState.primary.name}',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Text(
            word.word,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (word.phonetic != null && word.phonetic!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${word.phonetic} ${word.partOfSpeech ?? ''}',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
          if (word.romanization != null) ...[
            const SizedBox(height: 4),
            Text(
              '[${word.romanization}]',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref.read(ttsServiceProvider).speak(
                  word.word,
                  audioUrl: word.audioUs,
                  ttsLang: langState.primary.ttsLang,
                ),
            icon: const Icon(Icons.volume_up, color: Colors.white70),
            label: const Text('Nghe phat am',
                style: TextStyle(color: Colors.white70)),
          ),
          if (_isFlipped) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            if (word.definition != null)
              Text(
                word.definition!,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
            if (word.example != null && word.example!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '📝 ${word.example}',
                style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 64, color: warningOrange),
          const SizedBox(height: 16),
          const Text(
            'Hoan thanh!',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Da on tap ${_words.length} tu',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: warningOrange,
            ),
            child: const Text('Quay lai'),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
