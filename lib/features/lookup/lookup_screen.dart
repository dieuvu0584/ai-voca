import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/db/database.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../data/languages.dart';

class LookupScreen extends ConsumerStatefulWidget {
  const LookupScreen({super.key});

  @override
  ConsumerState<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends ConsumerState<LookupScreen> {
  final _controller = TextEditingController();

  // Kết quả từ dict API (tiếng Anh)
  Word? _result;
  // Kết quả từ AI (ngôn ngữ không phải tiếng Anh)
  String? _aiLookupResult;
  String? _aiLookupWord; // từ đã tra để hiển thị tiêu đề

  bool _loading = false;
  String? _error;
  String? _aiExplanation;
  bool _aiLoading = false;
  String? _lookupLangCode; // null = dùng primary language

  String _getEffectiveLangCode() {
    return _lookupLangCode ?? ref.read(languageProvider).primary.code;
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    final lang = ref.read(guiLangProvider);
    final isOnline = ref.read(isOnlineProvider);

    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'offline_notice')),
          backgroundColor: warningOrange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final langCode = _getEffectiveLangCode();

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _aiLookupResult = null;
      _aiLookupWord = null;
      _aiExplanation = null;
    });

    // Ngôn ngữ không phải tiếng Anh → dùng AI tra từ
    if (!langCode.startsWith('en')) {
      final aiService = ref.read(aiServiceProvider);

      if (aiService == null) {
        setState(() {
          _loading = false;
          _error = tr(lang, 'ai_required_for_lookup');
        });
        return;
      }

      // Dùng AI lấy định nghĩa trong ngôn ngữ đó
      final lookupLang = findLanguage(langCode);
      try {
        final result = await aiService.complete(
          messages: [
            {
              'role': 'user',
              'content':
                  'Define the word or phrase "$query" in ${lookupLang.name}. '
                  'Provide: meaning, part of speech (if applicable), usage notes, '
                  'and 1–2 example sentences. Reply entirely in ${lookupLang.name}.',
            }
          ],
          systemPrompt:
              'You are a bilingual dictionary assistant. '
              'Reply entirely in ${lookupLang.name}.',
        );
        setState(() {
          _aiLookupResult = result;
          _aiLookupWord = query;
          _loading = false;
          if (result == null) {
            _error = trArgs(lang, 'word_not_found', {'q': query});
          }
        });
      } catch (e) {
        setState(() {
          _loading = false;
          _error = tr(lang, 'lookup_error');
        });
      }
      return;
    }

    // Tiếng Anh → dùng dict service
    final dictService = ref.read(dictServiceProvider);
    try {
      final word = await dictService.lookup(query, langCode);
      setState(() {
        _result = word;
        _loading = false;
        if (word == null) {
          _error = trArgs(lang, 'word_not_found', {'q': query});
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = tr(lang, 'lookup_error');
      });
    }
  }

  Future<void> _askAI() async {
    if (_result == null) return;
    final aiService = ref.read(aiServiceProvider);
    if (aiService == null) return;

    setState(() => _aiLoading = true);

    final defLangCode = ref.read(defLangPrimaryProvider);
    final defLang = findLanguage(defLangCode);
    final result = await aiService.complete(
      messages: [
        {
          'role': 'user',
          'content':
              'Explain the word "${_result!.word}" (${_result!.partOfSpeech ?? ""}). '
              'Give meaning, usage, example, and a memory tip. Reply in ${defLang.name}.'
        }
      ],
      systemPrompt: 'You are a vocabulary tutor. Reply in ${defLang.name}.',
    );

    if (mounted) {
      setState(() {
        _aiExplanation = result;
        _aiLoading = false;
      });
    }
  }

  Future<void> _addToStudy() async {
    final langCode = _getEffectiveLangCode();
    final progressDao = ref.read(progressDaoProvider);
    final lang = ref.read(guiLangProvider);

    final wordText = _result?.word ?? _aiLookupWord ?? '';
    if (wordText.isEmpty) return;

    final existing = await progressDao.getProgress(wordText, langCode);
    if (existing == null) {
      await progressDao.upsertProgress(WordProgressCompanion(
        word: drift.Value(wordText),
        langCode: drift.Value(langCode),
        status: const drift.Value('new'),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trArgs(lang, 'added_word', {'w': wordText})),
          backgroundColor: successGreen,
        ),
      );
    }
  }

  void _showLangPicker(String lang) {
    final currentCode = _getEffectiveLangCode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                tr(lang, 'lookup_lang'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: kLanguages.length,
                itemBuilder: (_, i) {
                  final l = kLanguages[i];
                  final selected = l.code == currentCode;
                  return ListTile(
                    leading: Text(l.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(l.name),
                    trailing: selected
                        ? Icon(Icons.check, color: appColors(context).primary)
                        : null,
                    onTap: () {
                      setState(() => _lookupLangCode = l.code);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final aiService = ref.watch(aiServiceProvider);
    final lang = ref.watch(guiLangProvider);
    final langState = ref.watch(languageProvider);
    final effectiveLangCode = _lookupLangCode ?? langState.primary.code;
    final effectiveLang = findLanguage(effectiveLangCode);
    final needsAI = !effectiveLangCode.startsWith('en');
    final aiNotReady = needsAI && aiService == null;

    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'lookup_online'))),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Language selector + search bar cùng hàng
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  child: Row(
                    children: [
                      // Flag button
                      InkWell(
                        onTap: () => _showLangPicker(lang),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(effectiveLang.flag,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down,
                                  size: 18, color: Colors.grey[500]),
                            ],
                          ),
                        ),
                      ),
                      // Divider dọc
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.grey[300],
                      ),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: tr(lang, 'enter_word'),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      // Search button
                      ElevatedButton(
                        onPressed: _loading ? null : _search,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(tr(lang, 'search')),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Warning: ngôn ngữ cần AI nhưng AI chưa được cài đặt
            if (aiNotReady)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warningOrange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: warningOrange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr(lang, 'lookup_ai_banner'),
                        style: TextStyle(
                            fontSize: 13, color: warningOrange),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      style: TextButton.styleFrom(
                          foregroundColor: warningOrange,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(tr(lang, 'go_to_settings'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // Kết quả
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: TextStyle(color: Colors.grey[600])))
                      : _result != null
                          ? _buildDictResult(lang, aiSettings)
                          : _aiLookupResult != null
                              ? _buildAILookupResult(lang, effectiveLang)
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search,
                                          size: 48, color: Colors.grey[300]),
                                      const SizedBox(height: 8),
                                      Text(tr(lang, 'enter_word_hint'),
                                          style: TextStyle(
                                              color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  // Kết quả từ dict API (tiếng Anh)
  Widget _buildDictResult(String lang, AISettings aiSettings) {
    final w = _result!;
    final ttsService = ref.read(ttsServiceProvider);
    final effectiveLangCode = _lookupLangCode ?? ref.read(languageProvider).primary.code;
    final effectiveLang = findLanguage(effectiveLangCode);
    final ttsLang = effectiveLang.ttsLang;

    final cs = appColors(context);
    final sourceBadge = switch (w.source) {
      'api' => ('🌐 API', cs.primary),
      'cache' => ('💾 Cache', warningOrange),
      _ => ('📦 Local', Colors.grey),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(w.word,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sourceBadge.$2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(sourceBadge.$1,
                    style: TextStyle(
                        fontSize: 11,
                        color: sourceBadge.$2,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (w.phonetic != null && w.phonetic!.isNotEmpty)
            Text('US: ${w.phonetic}',
                style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          if (w.phoneticUK != null &&
              w.phoneticUK!.isNotEmpty &&
              w.phoneticUK != w.phonetic)
            Text('UK: ${w.phoneticUK}',
                style: TextStyle(fontSize: 15, color: Colors.grey[600])),

          const SizedBox(height: 12),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    ttsService.speakWithAudio(w.word, audioUrl: w.audioUs, ttsLang: ttsLang),
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('US'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              if (w.audioUk != null && w.audioUk!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => ttsService.speakWithAudio(w.word,
                      audioUrl: w.audioUk, ttsLang: ttsLang),
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: const Text('UK'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: krColor,
                      foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (w.partOfSpeech != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(w.partOfSpeech!,
                  style: TextStyle(color: cs.primary)),
            ),
          const SizedBox(height: 8),
          if (w.definition != null && w.definition!.isNotEmpty)
            Text(w.definition!,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          if (w.example != null && w.example!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('📝 ${w.example}',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700])),
            ),
          ],
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToStudy,
                  icon: const Icon(Icons.add),
                  label: Text(tr(lang, 'add_to_study')),
                ),
              ),
              if (aiSettings.mode != AIMode.none) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _aiLoading ? null : _askAI,
                    icon: Icon(aiProviderIcon(aiSettings.provider),
                        color: appColors(context).primary),
                    label: Text(tr(lang, 'ai_explain')),
                  ),
                ),
              ],
            ],
          ),

          if (_aiLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],
          if (_aiExplanation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: cs.secondary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(aiProviderIcon(aiSettings.provider),
                          size: 16, color: appColors(context).primary),
                      const SizedBox(width: 4),
                      Text(tr(lang, 'ai_explanation'),
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: appColors(context).primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiExplanation!,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Kết quả từ AI (ngôn ngữ không phải tiếng Anh)
  Widget _buildAILookupResult(String lang, Language lookupLang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề từ
          Row(
            children: [
              Text(lookupLang.flag,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _aiLookupWord ?? '',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lookupLang.name,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),

          // Nội dung định nghĩa từ AI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: appColors(context).secondary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: appColors(context).secondary.withValues(alpha: 0.18)),
            ),
            child: Builder(builder: (context) {
              final provider = ref.read(aiSettingsProvider).provider;
              final pIcon = aiProviderIcon(provider);
              final pColor = appColors(context).primary;
              return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(pIcon, size: 15, color: pColor),
                    const SizedBox(width: 6),
                    Text(
                      tr(lang, 'ai_explanation'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: pColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_aiLookupResult!,
                    style: const TextStyle(fontSize: 15, height: 1.5)),
              ],
            );
            }),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _addToStudy,
            icon: const Icon(Icons.add),
            label: Text(tr(lang, 'add_to_study')),
          ),
        ],
      ),
    );
  }
}
