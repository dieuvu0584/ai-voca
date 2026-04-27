import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';
import '../../core/premium/premium_notifier.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/vocab_sync/vocab_sync_service.dart';
import '../../data/en_topics.dart';
import '../premium/paywall_screen.dart';

class SessionPreviewScreen extends ConsumerStatefulWidget {
  const SessionPreviewScreen({super.key});

  @override
  ConsumerState<SessionPreviewScreen> createState() =>
      _SessionPreviewScreenState();
}

class _SessionPreviewScreenState extends ConsumerState<SessionPreviewScreen> {
  List<_PreviewWord> _allWords = []; // toàn bộ từ trước khi filter topic
  List<_PreviewWord> _words = [];   // từ sau khi filter (hiển thị trong list)
  final Set<int> _skippedIndices = {};
  bool _hitFreeLimit = false;
  bool _loading = true;
  String? _selectedTopic; // null = tất cả

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final langState = ref.read(languageProvider);
    final langCode = langState.primary.code;
    final isEn = langCode.startsWith('en');
    final progressDao = ref.read(progressDaoProvider);

    final prefs = await SharedPreferences.getInstance();
    final sessionLimit = prefs.getInt('session_word_count') ?? 50;

    final List<_PreviewWord> words = [];

    // Từ chưa học (new)
    final newProgress = await progressDao.getNewWords(langCode, limit: 9999);
    for (final p in newProgress) {
      final topics = isEn ? (kWordToTopics[p.word.toLowerCase()] ?? []) : <String>[];
      words.add(_PreviewWord(word: p.word, topics: topics));
    }

    // Từ đến hạn review
    final dueWords = await progressDao.getDueWords(langCode);
    for (final dw in dueWords) {
      if (!words.any((w) => w.word == dw.word)) {
        final topics = isEn ? (kWordToTopics[dw.word.toLowerCase()] ?? []) : <String>[];
        words.add(_PreviewWord(word: dw.word, isDue: true, topics: topics));
      }
    }

    // Nếu không có từ nào → thử fetch batch mới
    if (words.isEmpty && VocabSyncService.isSupported(langCode)) {
      final isPremium = ref.read(premiumProvider);
      await ref.read(vocabSyncProvider)
          .fetchNextBatchManual(langCode, isPremium: isPremium);

      final newProgress2 =
          await progressDao.getNewWords(langCode, limit: sessionLimit);
      for (final p in newProgress2) {
        words.add(_PreviewWord(word: p.word));
      }

      if (words.isEmpty && langCode.startsWith('en') && !isPremium) {
        setState(() {
          _hitFreeLimit = true;
          _loading = false;
        });
        return;
      }
    }

    setState(() {
      _allWords = words;
      _words = _applyTopicFilter(words, _selectedTopic, sessionLimit);
      _loading = false;
    });
  }

  /// Filter từ theo topic đang chọn, giới hạn sessionLimit
  List<_PreviewWord> _applyTopicFilter(
      List<_PreviewWord> all, String? topic, int limit) {
    if (topic == null) return all.take(limit).toList();
    final topicSet = kEnTopics[topic];
    if (topicSet == null) return all.take(limit).toList();
    final topicSetLower = topicSet.map((w) => w.toLowerCase()).toSet();
    return all
        .where((w) => topicSetLower.contains(w.word.toLowerCase()))
        .take(limit)
        .toList();
  }

  void _selectTopic(String? topic) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionLimit = prefs.getInt('session_word_count') ?? 50;
    setState(() {
      _selectedTopic = topic;
      _skippedIndices.clear();
      _words = _applyTopicFilter(_allWords, topic, sessionLimit);
    });
  }

  int get _remainingCount => _words.length - _skippedIndices.length;

  Future<void> _toggleSkip(int index) async {
    final langCode = ref.read(languageProvider).primary.code;
    final progressDao = ref.read(progressDaoProvider);
    final word = _words[index].word;
    if (_skippedIndices.contains(index)) {
      await progressDao.restoreWord(word, langCode);
      setState(() => _skippedIndices.remove(index));
    } else {
      await progressDao.skipWord(word, langCode);
      setState(() => _skippedIndices.add(index));
    }
    ref.read(statsRefreshProvider.notifier).update((s) => s + 1);
  }

  Future<void> _confirmAllKnown() async {
    if (!mounted) return;
    setState(() {
      _words = [];
      _allWords = [];
      _skippedIndices.clear();
      _loading = true;
    });
    _loadWords();
  }

  Future<void> _confirmStart() async {
    // Lưu danh sách từ đã filter (loại bỏ từ đã skip) để flashcard dùng đúng
    final wordsToStudy = [
      for (var i = 0; i < _words.length; i++)
        if (!_skippedIndices.contains(i)) _words[i].word,
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('session_word_list', wordsToStudy);
    if (mounted) context.go('/flashcard');
  }

  Future<void> _replaceKnownWithNew() async {
    final langCode = ref.read(languageProvider).primary.code;
    final progressDao = ref.read(progressDaoProvider);
    final prefs = await SharedPreferences.getInstance();
    final sessionLimit = prefs.getInt('session_word_count') ?? 50;

    final knownCount = _skippedIndices.length;

    final sortedIndices = _skippedIndices.toList()
      ..sort((a, b) => b.compareTo(a));
    final remaining = List<_PreviewWord>.from(_words);
    for (final i in sortedIndices) {
      remaining.removeAt(i);
    }

    // Tập từ đã có trong danh sách còn lại
    final existingWords = remaining.map((w) => w.word).toSet();
    // QUAN TRỌNG: loại cả từ đang bị skip — tránh re-add từ cũ làm replacement
    final skippedWords = _skippedIndices.map((i) => _words[i].word).toSet();
    existingWords.addAll(skippedWords);

    final replacements = <_PreviewWord>[];

    // Pool candidates từ _allWords (lọc topic nếu đang chọn)
    final allFiltered = _applyTopicFilter(_allWords, _selectedTopic, 9999);

    for (final candidate in allFiltered) {
      if (replacements.length >= knownCount) break;
      if (existingWords.contains(candidate.word)) continue;
      replacements.add(candidate);
      existingWords.add(candidate.word);
    }

    // Nếu vẫn thiếu → query DB lấy fresh new words chưa có trong _allWords
    if (replacements.length < knownCount) {
      final freshNew = await progressDao.getNewWords(langCode, limit: knownCount * 3);
      for (final p in freshNew) {
        if (replacements.length >= knownCount) break;
        if (existingWords.contains(p.word)) continue;
        final topics = langCode.startsWith('en')
            ? (kWordToTopics[p.word.toLowerCase()] ?? <String>[])
            : <String>[];
        replacements.add(_PreviewWord(word: p.word, topics: topics));
        existingWords.add(p.word);
      }
    }

    // Nếu vẫn thiếu → lấy thêm từ due words
    if (replacements.length < knownCount) {
      final dueWords = await progressDao.getDueWords(langCode);
      for (final dw in dueWords) {
        if (replacements.length >= knownCount) break;
        if (existingWords.contains(dw.word)) continue;
        replacements.add(_PreviewWord(word: dw.word, isDue: true));
        existingWords.add(dw.word);
      }
    }

    final merged = [...remaining, ...replacements].take(sessionLimit).toList();
    setState(() {
      _words = merged;
      _skippedIndices.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = appColors(context);
    final langState = ref.watch(languageProvider);
    final lang = ref.watch(guiLangProvider);
    final isEnglish = langState.primary.code.startsWith('en');

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(lang, 'new_session')),
        actions: const [],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _hitFreeLimit
                ? _buildFreeLimitView(lang)
                : _words.isEmpty && _allWords.isEmpty
                    ? _buildEmptyView(lang)
                    : Column(
                        children: [
                          // ── Header: tên ngôn ngữ + số từ + topic chips ──
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                            color: cs.primary.withValues(alpha: 0.05),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(langState.primary.flag,
                                        style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${langState.primary.name} · '
                                        '${trArgs(lang, 'n_words_queue', {'n': '${_words.length}'})}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isEnglish) ...[
                                  const SizedBox(height: 8),
                                  _buildTopicChips(lang, cs),
                                ],
                              ],
                            ),
                          ),

                          // ── Hint text ──
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              _words.isEmpty
                                  ? tr(lang, 'no_words_in_topic')
                                  : tr(lang, 'tap_known'),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ),

                          // ── Word list ──
                          Expanded(
                            child: _words.isEmpty
                                ? Center(
                                    child: Icon(Icons.search_off_rounded,
                                        size: 48, color: Colors.grey[300]),
                                  )
                                : ListView.separated(
                                    itemCount: _words.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final w = _words[i];
                                      final skipped =
                                          _skippedIndices.contains(i);
                                      return ListTile(
                                        dense: true,
                                        visualDensity: const VisualDensity(
                                            vertical: -2),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 0),
                                        onTap: () => _toggleSkip(i),
                                        leading: CircleAvatar(
                                          radius: 11,
                                          backgroundColor: skipped
                                              ? Colors.grey[300]
                                              : cs.primary
                                                  .withValues(alpha: 0.1),
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: skipped
                                                  ? Colors.grey
                                                  : cs.primary,
                                            ),
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Text(
                                              w.word,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                decoration: skipped
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                                color: skipped
                                                    ? Colors.grey
                                                    : null,
                                              ),
                                            ),
                                            if (w.isDue) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  tr(lang, 'due'),
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.orange,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                            // Topic badge — chỉ hiện khi đang xem "Tất cả"
                                            if (_selectedTopic == null &&
                                                w.topics.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              _TopicBadge(
                                                topic: w.topics.first,
                                                lang: lang,
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 0),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () => _toggleSkip(i),
                                          child: Text(
                                            skipped
                                                ? tr(lang, 'relearn')
                                                : tr(lang, 'known'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: skipped
                                                  ? cs.primary
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // ── Bottom action buttons ──
                          if (_words.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _remainingCount == 0
                                          ? _confirmAllKnown
                                          : _skippedIndices.isNotEmpty
                                              ? _replaceKnownWithNew
                                              : _confirmStart,
                                      child: Text(
                                        _remainingCount == 0
                                            ? tr(lang, 'all_known_load_new')
                                            : _skippedIndices.isNotEmpty
                                                ? trArgs(lang, 'known_load_new',
                                                    {'n': '${_skippedIndices.length}'})
                                                : trArgs(lang, 'start_n_words',
                                                    {'n': '$_remainingCount'}),
                                      ),
                                    ),
                                  ),
                                  if (_skippedIndices.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        trArgs(lang, 'skipped_n_known',
                                            {'n': '${_skippedIndices.length}'}),
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

  // ── Topic chips ──────────────────────────────────────────────

  Widget _buildTopicChips(String lang, AppColorScheme cs) {
    final topics = kEnTopics.keys.toList();

    // Tính số từ của mỗi topic từ _allWords (không query DB thêm)
    final topicWordSet = <String, Set<String>>{};
    for (final w in _allWords) {
      for (final t in w.topics) {
        topicWordSet.putIfAbsent(t, () => {}).add(w.word);
      }
    }

    return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _TopicChip(
            label: tr(lang, 'topic_all'),
            count: _allWords.length,
            selected: _selectedTopic == null,
            onTap: () => _selectTopic(null),
            cs: cs,
          ),
          ...topics
              .where((topic) => (topicWordSet[topic]?.length ?? 0) > 0)
              .map((topic) => _TopicChip(
                    label: tr(lang, 'topic_$topic'),
                    count: topicWordSet[topic]!.length,
                    selected: _selectedTopic == topic,
                    onTap: () => _selectTopic(topic),
                    cs: cs,
                  )),
        ],
    );
  }

  // ── Empty views ──────────────────────────────────────────────

  Widget _buildEmptyView(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              tr(lang, 'no_words_queue'),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text(tr(lang, 'go_back')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeLimitView(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              tr(lang, 'premium_title'),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr(lang, 'free_limit_msg'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await PaywallScreen.show(context, ref);
                  if (!mounted) return;
                  final nowPremium = ref.read(premiumProvider);
                  if (nowPremium) {
                    setState(() {
                      _hitFreeLimit = false;
                      _loading = true;
                    });
                    _loadWords();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  tr(lang, 'premium_upgrade_btn'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text(tr(lang, 'go_back')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Topic Chip ───────────────────────────────────────────────────

class _TopicChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final AppColorScheme cs;

  const _TopicChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : cs.primary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : cs.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────

class _PreviewWord {
  final String word;
  final bool isDue;
  final List<String> topics; // từ kWordToTopics

  const _PreviewWord({required this.word, this.isDue = false, this.topics = const []});
}

// ── Topic Badge (inline trong row) ───────────────────────────────

class _TopicBadge extends StatelessWidget {
  final String topic;
  final String lang;

  const _TopicBadge({required this.topic, required this.lang});

  @override
  Widget build(BuildContext context) {
    final color = _kTopicColors[topic] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tr(lang, 'topic_$topic'),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Màu cho từng topic ───────────────────────────────────────────

const _kTopicColors = <String, Color>{
  'food':       Color(0xFFE53935),
  'drink':      Color(0xFF039BE5),
  'household':  Color(0xFF8E24AA),
  'clothing':   Color(0xFFD81B60),
  'body':       Color(0xFF43A047),
  'family':     Color(0xFFFF8F00),
  'transport':  Color(0xFF00ACC1),
  'nature':     Color(0xFF558B2F),
  'animals':    Color(0xFF6D4C41),
  'work':       Color(0xFF1E88E5),
  'technology': Color(0xFF3949AB),
  'health':     Color(0xFF00897B),
  'education':  Color(0xFFE91E63),
  'money':      Color(0xFFFFB300),
  'sports':     Color(0xFFE65100),
  'emotions':   Color(0xFF9C27B0),
};
