import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/db/database.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';

class LookupScreen extends ConsumerStatefulWidget {
  const LookupScreen({super.key});

  @override
  ConsumerState<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends ConsumerState<LookupScreen> {
  final _controller = TextEditingController();
  Word? _result;
  bool _loading = false;
  String? _error;
  String? _aiExplanation;
  bool _aiLoading = false;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _aiExplanation = null;
    });

    final langCode = ref.read(languageProvider).primary.code;
    final dictService = ref.read(dictServiceProvider);

    try {
      final word = await dictService.lookup(query, langCode);
      setState(() {
        _result = word;
        _loading = false;
        if (word == null) {
          _error = 'Khong tim thay tu "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Loi khi tra tu. Kiem tra ket noi mang.';
      });
    }
  }

  Future<void> _askAI() async {
    if (_result == null) return;
    final aiService = ref.read(aiServiceProvider);
    if (aiService == null) return;

    setState(() => _aiLoading = true);

    final result = await aiService.complete(
      messages: [
        {
          'role': 'user',
          'content':
              'Giai thich tu "${_result!.word}" (${_result!.partOfSpeech}). '
              'Cho nghia, cach dung, vi du, va meo nho. Tra loi bang tieng Viet.'
        }
      ],
      systemPrompt: 'Ban la tro ly day tu vung. Tra loi bang tieng Viet.',
    );

    if (mounted) {
      setState(() {
        _aiExplanation = result;
        _aiLoading = false;
      });
    }
  }

  Future<void> _addToStudy() async {
    if (_result == null) return;
    final langCode = ref.read(languageProvider).primary.code;
    final progressDao = ref.read(progressDaoProvider);

    final existing = await progressDao.getProgress(_result!.word, langCode);
    if (existing == null) {
      await progressDao.upsertProgress(WordProgressCompanion(
        word: drift.Value(_result!.word),
        langCode: drift.Value(langCode),
        status: const drift.Value('new'),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Da them "${_result!.word}" vao danh sach hoc'),
          backgroundColor: successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiSettings = ref.watch(aiSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tra tu')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhap tu can tra...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _search,
                  child: const Text('Tra'),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: TextStyle(color: Colors.grey[600])))
                    : _result != null
                        ? _buildResult()
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 8),
                                Text('Nhap tu tieng Anh de tra',
                                    style:
                                        TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final w = _result!;
    final aiSettings = ref.watch(aiSettingsProvider);
    final ttsService = ref.read(ttsServiceProvider);
    final ttsLang = ref.read(languageProvider).primary.ttsLang;

    // Source badge
    final sourceBadge = switch (w.source) {
      'api' => ('🌐 API', enColor),
      'cache' => ('💾 Cache', warningOrange),
      _ => ('📦 Local', Colors.grey),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word header
          Row(
            children: [
              Expanded(
                child: Text(
                  w.word,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sourceBadge.$2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sourceBadge.$1,
                  style: TextStyle(
                      fontSize: 11,
                      color: sourceBadge.$2,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Phonetics
          if (w.phonetic != null && w.phonetic!.isNotEmpty)
            Text('US: ${w.phonetic}',
                style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          if (w.phoneticUK != null &&
              w.phoneticUK!.isNotEmpty &&
              w.phoneticUK != w.phonetic)
            Text('UK: ${w.phoneticUK}',
                style: TextStyle(fontSize: 15, color: Colors.grey[600])),

          const SizedBox(height: 12),

          // Audio buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => ttsService.speak(
                  w.word,
                  audioUrl: w.audioUs,
                  ttsLang: ttsLang,
                ),
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('US'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: enColor, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              if (w.audioUk != null && w.audioUk!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => ttsService.speak(
                    w.word,
                    audioUrl: w.audioUk,
                    ttsLang: ttsLang,
                  ),
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: const Text('UK'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: krColor,
                      foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Part of speech + definition
          if (w.partOfSpeech != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: enColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(w.partOfSpeech!,
                  style: const TextStyle(color: enColor)),
            ),
          const SizedBox(height: 8),
          if (w.definition != null)
            Text(w.definition!,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                      fontStyle: FontStyle.italic, color: Colors.grey[700])),
            ),
          ],
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToStudy,
                  icon: const Icon(Icons.add),
                  label: const Text('Them vao hoc'),
                ),
              ),
              if (aiSettings.mode != AIMode.none) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _aiLoading ? null : _askAI,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI giai thich'),
                  ),
                ),
              ],
            ],
          ),

          // AI explanation
          if (_aiLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],
          if (_aiExplanation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: secondaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: secondaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 16, color: secondaryColor),
                      SizedBox(width: 4),
                      Text('AI giai thich',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: secondaryColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiExplanation!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
