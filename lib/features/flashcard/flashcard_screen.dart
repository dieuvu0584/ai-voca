import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../app.dart';
import '../../core/providers.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/db/database.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/premium/premium_notifier.dart';
import '../../core/theme/app_theme.dart';
import '../../data/languages.dart';
import '../../features/premium/paywall_screen.dart';
import 'flashcard_card.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  List<Word> _words = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _syncingVocab = false; // đang tải từ vựng lần đầu cho ngôn ngữ mới
  bool _hitFreeLimit = false; // free English user đã dùng hết 150 từ miễn phí
  String? _aiExplanation;
  bool _aiLoading = false;
  int? _sessionId;

  // Autoplay
  bool _autoPlay = false;
  Timer? _autoPlayTimer;
  int _autoPlayInterval = 5;
  bool _autoPlayLoop = true;

  // Auto TTS (từ settings "Tự động phát âm")
  bool _autoTTS = true;

  // Secondary language — lazy fetch per word
  final Map<String, Word?> _secondaryCache = {}; // primaryWord → secondary Word
  final Set<String> _fetchingSecondary = {};
  final Set<String> _secondaryAIBusy = {}; // cacheKey khi AI bị overload/lỗi tạm thời

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadAutoPlaySettings();
    await _loadSession();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _loadAutoPlaySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoPlayInterval = prefs.getInt('auto_run_seconds') ?? 5;
      _autoPlayLoop = prefs.getBool('autoplay_loop') ?? true;
      _autoTTS = prefs.getBool('auto_run_tts') ?? true;
    });
  }

  Future<void> _loadSession() async {
    final langState = ref.read(languageProvider);
    final langCode = langState.primary.code;
    final wordDao = ref.read(wordDaoProvider);
    final progressDao = ref.read(progressDaoProvider);

    // Đọc số từ mỗi phiên từ settings
    final prefs = await SharedPreferences.getInstance();
    final sessionLimit = prefs.getInt('session_word_count') ?? 50;

    _sessionId = await progressDao.startSession(langCode);

    final List<Word> studyWords = [];
    final addedWords = <String>{};

    // Ưu tiên danh sách từ do Session Preview truyền qua (topic filter / skip)
    final sessionWordList = prefs.getStringList('session_word_list');
    await prefs.remove('session_word_list'); // dùng 1 lần rồi xóa

    if (sessionWordList != null && sessionWordList.isNotEmpty) {
      // Load đúng danh sách từ Session Preview đã chọn
      for (final word in sessionWordList) {
        if (studyWords.length >= sessionLimit) break;
        final wordEntry = await wordDao.getWord(word, langCode);
        if (wordEntry != null && addedWords.add(word)) {
          studyWords.add(wordEntry);
        }
      }
    } else {
      // Fallback: load từ new + due bình thường (vd: vào flashcard không qua preview)
      final newProgress = await progressDao.getNewWords(langCode, limit: sessionLimit);
      for (final p in newProgress) {
        if (studyWords.length >= sessionLimit) break;
        final wordEntry = await wordDao.getWord(p.word, langCode);
        if (wordEntry != null && addedWords.add(p.word)) {
          studyWords.add(wordEntry);
        }
      }

      final dueProgress = await progressDao.getDueWords(langCode);
      for (final p in dueProgress) {
        if (studyWords.length >= sessionLimit) break;
        if (addedWords.add(p.word)) {
          final wordEntry = await wordDao.getWord(p.word, langCode);
          if (wordEntry != null) {
            studyWords.add(wordEntry);
          }
        }
      }
    }

    // Nếu DB trống (ngôn ngữ mới chưa từng sync) → trigger sync và chờ
    if (studyWords.isEmpty) {
      setState(() => _syncingVocab = true);
      final isPremium = ref.read(effectivePremiumProvider);
      await ref.read(vocabSyncProvider).syncIfNeeded(langCode, isPremium: isPremium);
      setState(() => _syncingVocab = false);

      // Retry load sau khi sync
      final newProgress2 = await progressDao.getNewWords(langCode, limit: sessionLimit);
      for (final p in newProgress2) {
        if (studyWords.length >= sessionLimit) break;
        final wordEntry = await wordDao.getWord(p.word, langCode);
        if (wordEntry != null && addedWords.add(p.word)) {
          studyWords.add(wordEntry);
        }
      }

      // Free English + vẫn không có từ → đã dùng hết giới hạn miễn phí
      if (studyWords.isEmpty && langCode.startsWith('en') && !isPremium) {
        setState(() {
          _hitFreeLimit = true;
          _loading = false;
        });
        return;
      }
    }

    setState(() {
      _words = studyWords;
      _loading = false;
    });

    // Bắt đầu fetch secondary cho từ đầu tiên
    if (_words.isNotEmpty) {
      _ensureSecondaryWord(_words[0]);
      // Tự động phát âm từ đầu tiên
      if (_autoTTS) {
        _speakFirstWord();
      }
      // Background: enrich tất cả từ chưa có definition trong session này
      _enrichSessionInBackground(studyWords, langCode);
    }
  }

  /// Enrich toàn bộ từ chưa có definition trong session — chạy nền, không block UI.
  /// Sau mỗi từ enrich xong → cập nhật _words để card hiện data ngay khi đến lượt.
  Future<void> _enrichSessionInBackground(List<Word> words, String langCode) async {
    for (int i = 0; i < words.length; i++) {
      if (!mounted) return;
      final w = words[i];
      // Bỏ qua từ đã có definition
      if (w.definition != null && w.definition!.isNotEmpty) continue;
      final enriched = await ref.read(vocabSyncProvider)
          .enrichSingleWord(w.word, w.langCode);
      if (!mounted) return;
      if (enriched != null) {
        setState(() {
          // Cập nhật _words để FlashcardCard nhận được word đã có định nghĩa
          if (i < _words.length) _words[i] = enriched;
        });
      }
      // Throttle nhẹ giữa các từ — tránh hammering API
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // ── Secondary language lazy-fetch ─────────────────────────

  /// Parse AI response dạng WORD|PHONETIC — xử lý cả khi AI trả về long text
  ({String word, String? phonetic}) _parseSecondaryAIResponse(String response) {
    final lines = response.trim().split('\n');

    // Duyệt từ cuối lên — AI thường đặt WORD|PHONETIC ở cuối response
    for (final line in lines.reversed) {
      final l = line.trim();
      if (l.isEmpty) continue;

      if (l.contains('|')) {
        final parts = l.split('|');
        final word = parts[0].trim();
        // Hợp lệ: ngắn, không phải câu văn, không có dấu chấm cuối câu
        if (word.isNotEmpty && word.length <= 40 && !word.contains('. ')) {
          final phonetic = parts.length > 1 && parts[1].trim().isNotEmpty
              ? parts[1].trim()
              : null;
          return (word: word, phonetic: phonetic);
        }
      }
    }

    // Fallback: tìm dòng ngắn nhất không phải câu văn tiếng Anh
    for (final line in lines.reversed) {
      final l = line.trim();
      if (l.isEmpty) continue;
      // Từ ngắn, không chứa dấu chấm, không bắt đầu bằng chữ in hoa tiếng Anh dài
      if (l.length <= 30 &&
          !l.endsWith('.') &&
          !RegExp(r'^[A-Z][a-z]+ ').hasMatch(l)) {
        return (word: l, phonetic: null);
      }
    }

    return (word: '', phonetic: null);
  }

  Future<void> _ensureSecondaryWord(Word primary) async {
    final langState = ref.read(languageProvider);
    final secondary = langState.secondary;
    if (secondary == null) return;

    final cacheKey = '${primary.word}→${secondary.code}';
    if (_secondaryCache.containsKey(cacheKey)) return;
    if (_fetchingSecondary.contains(cacheKey)) return;

    _fetchingSecondary.add(cacheKey);
    // Rebuild ngay để SecondaryStrip hiện spinner trong khi chờ
    if (mounted) setState(() {});

    final wordDao = ref.read(wordDaoProvider);

    // Bước 1: tìm trong DB (từ đã lưu lần trước)
    Word? found = await wordDao.findLinkedWord(primary.word, secondary.code);

    // Bước 2: tìm theo definitionNative trùng khớp
    if (found == null &&
        primary.definitionNative != null &&
        primary.definitionNative!.isNotEmpty) {
      found = await wordDao.findByDefinitionNative(
          primary.definitionNative!, secondary.code);
    }

    // Bước 3: dùng AI để tìm từ tương đương
    if (found == null) {
      final aiService = ref.read(aiServiceProvider);
      if (aiService != null) {
        final meaning = primary.definitionNative?.isNotEmpty == true
            ? primary.definitionNative
            : primary.definition?.isNotEmpty == true
                ? primary.definition
                : null;
        final secLang = findLanguage(secondary.code);
        final primaryLang = findLanguage(primary.langCode);
        final meaningHint = meaning != null ? ' (meaning: "$meaning")' : '';
        try {
          final result = await aiService.complete(
            messages: [
              {
                'role': 'user',
                'content':
                    'What is the most common ${secLang.name} equivalent of the ${primaryLang.name} word "${primary.word}"$meaningHint?\n'
                    'Reply ONLY in this format (nothing else): WORD|PHONETIC\n'
                    'Examples: 좋아하다|jo-a-ha-da  /  어떻게|eo-tteok-e  /  いつ|  /  chat|ʃa\n'
                    'No explanations. No extra text.',
              }
            ],
            systemPrompt:
                'You are a strict multilingual dictionary. Output ONLY: WORD|PHONETIC. No other text.',
          );
          if (result == null) {
            // AI trả null → overload hoặc lỗi tạm thời, cho retry
            _secondaryAIBusy.add(cacheKey);
          } else if (result.trim().isNotEmpty) {
            ref.read(aiSettingsProvider.notifier).reportAISuccess();
            final parsed = _parseSecondaryAIResponse(result);
            final secWord = parsed.word;
            final secPhonetic = parsed.phonetic;
            if (secWord.isNotEmpty) {
              // Tạo Word object ngay lập tức để hiển thị — không chờ DB
              found = Word(
                word: secWord,
                langCode: secondary.code,
                source: 'linked',
                phonetic: secPhonetic,
                definitionNative: meaning,
              );
              // Lưu DB và enrich ở background — không await
              wordDao.insertWord(WordsCompanion(
                word: Value(secWord),
                langCode: Value(secondary.code),
                source: const Value('linked'),
                partOfSpeech: Value('linked:${primary.word}'),
                definitionNative: Value(meaning ?? ''),
                phonetic: Value(secPhonetic),
              )).then((_) {
                ref.read(vocabSyncProvider)
                    .enrichSingleWord(secWord, secondary.code);
              });
            }
          }
        } catch (e) {
          final msg = e.toString();
          final isTransient = msg.contains('529') || msg.contains('timeout') || msg.contains('503');
          if (isTransient) {
            // Lỗi tạm thời — đánh dấu busy để hiện thông báo, không cache null (cho phép retry)
            _secondaryAIBusy.add(cacheKey);
          } else {
            ref.read(aiSettingsProvider.notifier).reportAIError('Lỗi kết nối');
          }
        }
      }
    }

    _fetchingSecondary.remove(cacheKey);
    // Nếu fetch thành công thì xóa trạng thái busy cũ
    if (found != null) _secondaryAIBusy.remove(cacheKey);
    if (mounted) {
      setState(() {
        // Chỉ cache khi có kết quả hoặc chắc chắn không tìm được (không busy)
        if (found != null || !_secondaryAIBusy.contains(cacheKey)) {
          _secondaryCache[cacheKey] = found;
        }
      });
    }
  }

  /// Gọi lại _ensureSecondaryWord sau khi primary word đã được enrich
  /// (FlashcardCard gọi callback này khi _enrichedWord cập nhật)
  void _onPrimaryEnriched(Word enriched) {
    // Tìm đúng slot theo word+langCode — KHÔNG dùng _currentIndex vì user
    // có thể đã navigate sang từ khác trong lúc enrich đang chạy.
    // Nếu dùng _currentIndex thì _words[sai_index] bị overwrite bởi từ sai.
    final idx = _words.indexWhere(
      (w) => w.word == enriched.word && w.langCode == enriched.langCode,
    );
    if (mounted && idx >= 0) {
      setState(() => _words[idx] = enriched);
    }
    // Chỉ fetch secondary khi đây đúng là từ đang hiển thị
    final realIndex = _currentIndex % _words.length;
    if (idx >= 0 && idx == realIndex) {
      _ensureSecondaryWord(enriched);
    }
  }

  // ── Autoplay ──────────────────────────────────────────────

  void _toggleAutoPlay() {
    if (_autoPlay) {
      _stopAutoPlay();
    } else {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    setState(() => _autoPlay = true);
    WakelockPlus.enable();
    if (_autoTTS) _speakCurrent();
    _scheduleNext();
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    setState(() => _autoPlay = false);
    WakelockPlus.disable();
  }

  void _scheduleNext() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer(Duration(seconds: _autoPlayInterval), () {
      if (!mounted || !_autoPlay) return;
      _nextAutoPlay();
    });
  }

  /// Phát âm từ đầu tiên khi mới vào flashcard — delay để TTS engine kịp sẵn sàng
  Future<void> _speakFirstWord() async {
    if (_words.isEmpty) return;
    final ttsService = ref.read(ttsServiceProvider);
    final ttsLang = ref.read(languageProvider).primary.ttsLang;
    final word = _words[0];

    // Đợi 600ms để UI sẵn sàng
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || !_autoTTS) return;

    await ttsService.speak(word.word, ttsLang: ttsLang);
  }

  /// Auto-TTS: luôn dùng flutter_tts (ổn định), không dùng audioUrl
  void _speakCurrent() {
    if (_words.isEmpty) return;
    final word = _words[_currentIndex % _words.length];
    final ttsService = ref.read(ttsServiceProvider);
    final ttsLang = ref.read(languageProvider).primary.ttsLang;
    ttsService.speak(word.word, ttsLang: ttsLang);
  }

  void _nextAutoPlay() {
    if (_words.isEmpty) return;

    final langCode = ref.read(languageProvider).primary.code;
    final progressDao = ref.read(progressDaoProvider);

    // Ghi nhận tiến độ từ hiện tại
    if (_currentIndex < _words.length) {
      progressDao.updateSM2(_words[_currentIndex].word, langCode, 1);
    }

    final nextIndex = _currentIndex + 1;

    if (nextIndex >= _words.length) {
      if (_autoPlayLoop) {
        // Lặp lại từ đầu
        setState(() {
          _currentIndex = 0;
          _aiExplanation = null;
        });
        _ensureSecondaryWord(_words[0]);
        if (_autoTTS) _speakCurrent();
        _scheduleNext();
      } else {
        // Kết thúc
        _stopAutoPlay();
        _endSession();
        setState(() => _currentIndex = _words.length);
      }
    } else {
      setState(() {
        _currentIndex = nextIndex;
        _aiExplanation = null;
      });
      _ensureSecondaryWord(_words[nextIndex]);
      if (_autoTTS) _speakCurrent();
      _scheduleNext();
    }
  }

  // ── Manual navigation ─────────────────────────────────────

  /// rating: 0 = Hay quên, 1 = Khó (default khi vuốt), 2 = Đã nhớ
  Future<void> _rateAndNext(int rating) async {
    if (_words.isEmpty) return;

    // Nếu đang auto play: hủy timer hiện tại nhưng GIỮ _autoPlay = true
    if (_autoPlay) {
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
    }

    // Tính index thực — round 2+ dùng modulo
    final realIndex = _currentIndex % _words.length;
    final langCode = ref.read(languageProvider).primary.code;
    final progressDao = ref.read(progressDaoProvider);
    final word = _words[realIndex];

    await progressDao.updateSM2(word.word, langCode, rating);

    final nextIndex = _currentIndex + 1;
    final isRoundEnd = nextIndex >= _words.length * ((_currentIndex ~/ _words.length) + 1);

    setState(() {
      _aiExplanation = null;
      _currentIndex = nextIndex;
    });

    if (isRoundEnd && !_autoPlayLoop) {
      // Không loop → kết thúc
      if (_autoPlay) _stopAutoPlay();
      _endSession();
    } else if (isRoundEnd && _autoPlayLoop) {
      // Loop → reset về đầu round mới
      if (_autoPlay) {
        _ensureSecondaryWord(_words[0]);
        if (_autoTTS) _speakCurrent();
        _scheduleNext();
      } else {
        _ensureSecondaryWord(_words[_currentIndex % _words.length]);
        if (_autoTTS) _speakCurrent();
      }
    } else {
      // Tiếp tục bình thường
      _ensureSecondaryWord(_words[_currentIndex % _words.length]);
      if (_autoTTS) _speakCurrent();
      if (_autoPlay) _scheduleNext();
    }
  }

  /// Chỉ navigate sang từ tiếp theo — KHÔNG rate.
  /// Rating chỉ qua buttons Quên/Khó/Nhớ (per CLAUDE.md).
  void _next() {
    if (_words.isEmpty) return;
    if (_autoPlay) {
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
    }

    final nextIndex = _currentIndex + 1;
    final isRoundEnd = nextIndex >= _words.length * ((_currentIndex ~/ _words.length) + 1);

    setState(() {
      _aiExplanation = null;
      _currentIndex = nextIndex;
    });

    if (isRoundEnd && !_autoPlayLoop) {
      if (_autoPlay) _stopAutoPlay();
      _endSession();
    } else if (isRoundEnd && _autoPlayLoop) {
      _ensureSecondaryWord(_words[0]);
      if (_autoTTS) _speakCurrent();
      if (_autoPlay) _scheduleNext();
    } else {
      _ensureSecondaryWord(_words[_currentIndex % _words.length]);
      if (_autoTTS) _speakCurrent();
      if (_autoPlay) _scheduleNext();
    }
  }

  void _prev() {
    if (_autoPlay) _stopAutoPlay();
    if (_currentIndex <= 0) return;
    setState(() {
      _aiExplanation = null;
      _currentIndex--;
    });
    // Đảm bảo secondary đã fetch cho từ hiện tại
    _ensureSecondaryWord(_words[_currentIndex]);
    // Tự động phát âm khi quay lại từ trước
    if (_autoTTS) _speakCurrent();
  }

  Future<void> _requestAIExplanation(Word word) async {
    final aiService = ref.read(aiServiceProvider);
    if (aiService == null) return;

    setState(() => _aiLoading = true);

    final langState = ref.read(languageProvider);
    final defLangCode = ref.read(defLangPrimaryProvider);
    final defLang = findLanguage(defLangCode);
    final result = await aiService.complete(
      messages: [
        {
          'role': 'user',
          'content':
              'Explain the word "${word.word}" (${word.partOfSpeech ?? ""}) in ${langState.primary.name}. '
              'Give meaning, usage tip, and a short example. Reply in ${defLang.name}.'
        }
      ],
      systemPrompt:
          'You are a vocabulary tutor. Reply in ${defLang.name}, concise and easy to understand.',
    );

    if (mounted) {
      setState(() {
        _aiExplanation = result;
        _aiLoading = false;
      });
    }
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;
    final progressDao = ref.read(progressDaoProvider);
    await progressDao.endSession(
      _sessionId!,
      wordsStudied: _currentIndex,
      wordsKnown: 0,
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final langState = ref.watch(languageProvider);
    final aiSettings = ref.watch(aiSettingsProvider);
    final lang = ref.watch(guiLangProvider);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (_syncingVocab) ...[
                const SizedBox(height: 16),
                Text(
                  tr(lang, 'syncing_vocab'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // isDone chỉ khi không loop VÀ đã qua hết round đầu tiên
    final isDone = !_autoPlayLoop && _currentIndex >= _words.length && !_autoPlay;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _stopAutoPlay();
            _endSession();
            context.go('/home');
          },
        ),
        title: _words.isEmpty
            ? Text(tr(lang, 'completed'))
            : Text('${(_currentIndex % _words.length) + 1} / ${_words.length}'),
        actions: [
          if (_words.isNotEmpty && !isDone)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Autoplay toggle
                Tooltip(
                  message: tr(lang, 'autoplay'),
                  child: InkWell(
                    onTap: _toggleAutoPlay,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 3, 8),
                      child: Icon(
                        _autoPlay
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        color: _autoPlay ? Colors.amber : null,
                      ),
                    ),
                  ),
                ),
                // AI button
                if (aiSettings.mode != AIMode.none)
                  Tooltip(
                    message: tr(lang, 'ask_ai_about'),
                    child: InkWell(
                      onTap: _aiLoading
                          ? null
                          : () => _requestAIExplanation(_words[_currentIndex]),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(3, 8, 8, 8),
                        child: _aiLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: appColors(context).primary),
                              )
                            : Icon(
                                aiProviderIcon(aiSettings.provider),
                                color: appColors(context).primary,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: isDone
            ? _buildDoneView(lang)
            : _words.isEmpty
                ? (_hitFreeLimit ? _buildFreeLimitView(lang) : _buildDoneView(lang))
                : Stack(
                    children: [
                      GestureDetector(
                        onHorizontalDragEnd: (d) {
                          final v = d.primaryVelocity ?? 0;
                          if (v.abs() < 250) return;
                          if (v < 0) { _next(); } else { _prev(); }
                        },
                        onVerticalDragEnd: (d) {
                          final v = d.primaryVelocity ?? 0;
                          if (v.abs() < 250) return;
                          if (v < 0) { _next(); } else { _prev(); }
                        },
                        child: Column(
                          children: [
                            // Card chính: nửa trên (4/7) + nửa dưới (2/7)
                            Expanded(
                              flex: 6,
                              child: Builder(builder: (_) {
                                final primary = _words[_currentIndex % _words.length];
                                final hasSecondary = langState.secondary != null &&
                                    aiSettings.mode != AIMode.none;
                                final cacheKey = hasSecondary
                                    ? '${primary.word}→${langState.secondary!.code}'
                                    : '';
                                final secWord = hasSecondary
                                    ? _secondaryCache[cacheKey]
                                    : null;
                                final isFetching = hasSecondary &&
                                    _fetchingSecondary.contains(cacheKey);
                                final isAIBusy = hasSecondary &&
                                    _secondaryAIBusy.contains(cacheKey);
                                return FlashcardCard(
                                  // Key theo word+lang để Flutter tạo fresh state khi đổi từ,
                                  // đồng thời tái sử dụng state khi cùng từ (vd: round 2)
                                  key: ValueKey('${primary.word}_${primary.langCode}'),
                                  word: primary,
                                  secondaryWord: secWord,
                                  isFetchingSecondary: isFetching,
                                  isSecondaryAIBusy: isAIBusy,
                                  secondaryLanguage: hasSecondary
                                      ? langState.secondary
                                      : null,
                                  aiExplanation: _aiExplanation,
                                  aiLoading: _aiLoading,
                                  ttsService: ref.read(ttsServiceProvider),
                                  ttsLang: langState.primary.ttsLang,
                                  guiLang: lang,
                                  onEnriched: _onPrimaryEnriched,
                                );
                              }),
                            ),
                            // Rating buttons (1/7)
                            Expanded(
                              flex: 1,
                              child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              child: Builder(builder: (context) {
                                final primary = appColors(context).primary;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _rateAndNext(0),
                                        icon: const Icon(Icons.replay_rounded,
                                            size: 18),
                                        label: Text(tr(lang, 'rating_forgot')),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: primary,
                                          side: BorderSide(
                                              color: primary.withValues(
                                                  alpha: 0.5)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _rateAndNext(2),
                                        icon: const Icon(Icons.check_rounded,
                                            size: 18),
                                        label:
                                            Text(tr(lang, 'rating_remembered')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            )),
                            // Autoplay progress bar
                            if (_autoPlay)
                              _AutoPlayProgressBar(
                                  duration: _autoPlayInterval),
                          ],
                        ),
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
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr(lang, 'free_limit_msg'),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await PaywallScreen.show(context, ref);
                  if (!mounted) return;
                  final nowPremium = ref.read(effectivePremiumProvider);
                  if (nowPremium) {
                    setState(() {
                      _hitFreeLimit = false;
                      _loading = true;
                    });
                    _loadAll();
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

  Widget _buildDoneView(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 64, color: successGreen),
          const SizedBox(height: 16),
          Text(
            tr(lang, 'awesome'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            trArgs(lang, 'studied_n_words', {'n': '${_words.length}'}),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: Text(tr(lang, 'go_back')),
          ),
        ],
      ),
    );
  }
}

// ── AutoPlay progress bar ─────────────────────────────────────
// Thanh tiến trình chạy từ đầu → cuối theo đúng thời gian interval

class _AutoPlayProgressBar extends StatefulWidget {
  final int duration;
  const _AutoPlayProgressBar({required this.duration});

  @override
  State<_AutoPlayProgressBar> createState() => _AutoPlayProgressBarState();
}

class _AutoPlayProgressBarState extends State<_AutoPlayProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..forward();
  }

  @override
  void didUpdateWidget(_AutoPlayProgressBar old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) {
      _ctrl.duration = Duration(seconds: widget.duration);
    }
    // Reset mỗi khi widget rebuild (từ mới)
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => LinearProgressIndicator(
        value: _ctrl.value,
        minHeight: 3,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(appColors(context).primary),
      ),
    );
  }
}
