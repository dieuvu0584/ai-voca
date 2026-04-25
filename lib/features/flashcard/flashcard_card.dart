import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';
import '../../core/tts/tts_service.dart';
import '../../core/l10n/strings.dart';
import '../../data/languages.dart';

class FlashcardCard extends ConsumerStatefulWidget {
  final Word word;
  final Word? secondaryWord;
  final bool isFetchingSecondary;
  final bool isSecondaryAIBusy;
  final Language? secondaryLanguage;
  final String? aiExplanation;
  final bool aiLoading;
  final TtsService ttsService;
  final String ttsLang;
  final String guiLang;
  final void Function(Word enriched)? onEnriched;

  const FlashcardCard({
    super.key,
    required this.word,
    this.secondaryWord,
    this.isFetchingSecondary = false,
    this.isSecondaryAIBusy = false,
    this.secondaryLanguage,
    this.aiExplanation,
    this.aiLoading = false,
    required this.ttsService,
    required this.ttsLang,
    required this.guiLang,
    this.onEnriched,
  });

  @override
  ConsumerState<FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends ConsumerState<FlashcardCard> {
  Word? _enrichedWord;
  bool _enriching = false;

  @override
  void initState() {
    super.initState();
    _enrichIfNeeded(widget.word);
  }

  @override
  void didUpdateWidget(FlashcardCard old) {
    super.didUpdateWidget(old);
    if (old.word.word != widget.word.word ||
        old.word.langCode != widget.word.langCode) {
      // Reset cả _enrichedWord lẫn _enriching để từ mới được enrich ngay
      // (không bị block bởi enrichment đang chạy dở của từ cũ)
      _enrichedWord = null;
      _enriching = false;
      _enrichIfNeeded(widget.word);
    }
  }

  Future<void> _enrichIfNeeded(Word word) async {
    if (_enriching) return;

    final defLangCode = ref.read(defLangPrimaryProvider);
    final needNative = defLangCode != word.langCode &&
        (word.definitionNative == null || word.definitionNative!.isEmpty);
    // definition = null  → chưa thử enrich → cần enrich
    // definition = ''   → đã thử, API không có entry → không enrich lại
    // definition = text → đã có → không enrich lại
    final needDefinition = word.definition == null;

    if (!needDefinition && !needNative) return;

    setState(() => _enriching = true);

    // Step 1: Enrich definition gốc (FreeDictApi / Wiktionary) nếu chưa có
    Word? updated = word;
    if (needDefinition) {
      updated = await ref
              .read(vocabSyncProvider)
              .enrichSingleWord(word.word, word.langCode) ??
          word;
    }

    // Step 2: Fetch AI definition theo defLang nếu cần
    if (needNative) {
      final aiService = ref.read(aiServiceProvider);
      if (aiService != null) {
        final defLang = findLanguage(defLangCode);
        final studyLang = findLanguage(word.langCode);
        try {
          final result = await aiService.complete(
            messages: [
              {
                'role': 'user',
                'content':
                    'Give a concise meaning of the ${studyLang.name} word "${word.word}" in ${defLang.name}. '
                    'Reply with ONLY the meaning, no extra explanation, no example.'
              }
            ],
            systemPrompt:
                'You are a bilingual dictionary. Reply only in ${defLang.name}.',
          );
          if (result != null && result.isNotEmpty) {
            ref.read(aiSettingsProvider.notifier).reportAISuccess();
            await ref
                .read(wordDaoProvider)
                .saveDefinitionNative(word.word, word.langCode, result);
            updated = await ref
                    .read(wordDaoProvider)
                    .getWord(word.word, word.langCode) ??
                updated;
          }
        } catch (e) {
          ref.read(aiSettingsProvider.notifier).reportAIError(
              e.toString().contains('timeout') ? 'Timeout' : 'Lỗi kết nối');
        }
      }
    }

    if (mounted) {
      setState(() {
        _enrichedWord = updated;
        _enriching = false;
      });
      widget.onEnriched?.call(updated ?? word);
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  String _extractDisplayWord(String raw) {
    if (!raw.contains('\n') && raw.length <= 40) return raw;
    final lines = raw.split('\n');
    for (final line in lines.reversed) {
      final l = line.trim();
      if (l.isNotEmpty && l.length <= 40 && !l.endsWith('.')) return l;
    }
    return lines.last.trim();
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = appColors(context);
    final word = _enrichedWord ?? widget.word;
    final hasSecondary = widget.secondaryLanguage != null;

    return Column(
      children: [
        // ── Phần chính: chiếm hết không gian còn lại ─────────
        Expanded(
          child: _buildPrimarySection(word, cs),
        ),

        // ── Đường kẻ phân chia ────────────────────────────────
        if (hasSecondary)
          Container(height: 1, color: Colors.grey.shade200),

        // ── Phần phụ: co lại vừa đủ content ──────────────────
        if (hasSecondary)
          _buildSecondarySection(word, cs),
      ],
    );
  }

  // ── Nửa trên ────────────────────────────────────────────────

  Widget _buildPrimarySection(Word word, AppColorScheme cs) {
    final definition = word.definition;
    final primaryLang = ref.read(languageProvider).primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cờ + từ + TTS — cùng 1 dòng
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(primaryLang.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildTtsRow(word, cs),
            ],
          ),
          // Phonetic
          if (word.phonetic?.isNotEmpty == true) ...[
            const SizedBox(height: 3),
            Text(word.phonetic!,
                style: TextStyle(fontSize: 15, color: Colors.grey[500])),
          ] else if (word.romanization?.isNotEmpty == true) ...[
            const SizedBox(height: 3),
            Text('[${word.romanization}]',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],

          // Part of speech
          if (word.partOfSpeech != null && word.partOfSpeech!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                word.partOfSpeech!,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],

          // Definition (English)
          if (_enriching && definition == null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                ),
                const SizedBox(width: 8),
                Text('...', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          ] else if (definition != null && definition.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                definition,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Ví dụ
          if (word.example != null && word.example!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
              ),
              child: Text(
                word.example!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // AI explanation
          if (widget.aiLoading) ...[
            const SizedBox(height: 12),
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 6),
            Text(tr(widget.guiLang, 'ai_thinking'),
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
          if (widget.aiExplanation != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.secondary.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(builder: (_) {
                    final provider = ref.read(aiSettingsProvider).provider;
                    final pIcon = aiProviderIcon(provider);
                    return Row(
                      children: [
                        Icon(pIcon, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(tr(widget.guiLang, 'ai_explanation'),
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.primary,
                                fontSize: 12)),
                      ],
                    );
                  }),
                  const SizedBox(height: 6),
                  Text(widget.aiExplanation!,
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTtsRow(Word word, AppColorScheme cs) {
    final hasAudioUs = word.audioUs != null && word.audioUs!.isNotEmpty;

    return IconButton(
      icon: Icon(Icons.volume_up, size: 22, color: cs.primary),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(),
      onPressed: () => hasAudioUs
          ? widget.ttsService.speakWithAudio(
              word.word,
              audioUrl: word.audioUs,
              ttsLang: widget.ttsLang,
            )
          : widget.ttsService.speak(word.word, ttsLang: widget.ttsLang),
    );
  }

  // ── Nửa dưới ────────────────────────────────────────────────

  Widget _buildSecondarySection(Word primaryWord, AppColorScheme cs) {
    final secLang = widget.secondaryLanguage!;
    final secWord = widget.secondaryWord;
    final isFetching = widget.isFetchingSecondary;
    final isAIBusy = widget.isSecondaryAIBusy;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isFetching && secWord == null) ...[
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.secondary),
            ),
          ] else if (isAIBusy && secWord == null) ...[
            Text(
              tr(widget.guiLang, 'ai_busy_secondary'),
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ] else if (secWord != null) ...[
            // Cờ + từ + TTS + icon AI — cùng 1 dòng
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(secLang.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _extractDisplayWord(secWord.word),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: cs.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.volume_up, size: 18, color: cs.secondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.ttsService.speak(
                    _extractDisplayWord(secWord.word),
                    ttsLang: secLang.ttsLang,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.auto_awesome, size: 12, color: Colors.grey[400]),
              ],
            ),
            // Phonetic
            if (secWord.phonetic?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(secWord.phonetic!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ] else if (secWord.romanization?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text('[${secWord.romanization}]',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ] else ...[
            Text('—', style: TextStyle(fontSize: 22, color: Colors.grey[300])),
          ],
        ],
      ),
    );
  }
}
