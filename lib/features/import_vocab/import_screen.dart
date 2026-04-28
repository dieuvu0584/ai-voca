import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app.dart';
import '../../core/import_vocab/import_models.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import 'word_preview_screen.dart';

// ─────────────────────────────────────────────────────────────
// ImportScreen — 4 tabs: Text / URL / Image / Voice
// ─────────────────────────────────────────────────────────────
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  bool _loading = false;
  String? _error;

  // Voice
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _voiceTranscript = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (e) => setState(() => _error = e.errorMsg),
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _urlController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ── AI extraction ──────────────────────────────────────────

  Future<void> _extractFromText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _runExtraction(
        () => ref.read(importServiceProvider).parseText(
              text: text,
              langCode: ref.read(languageProvider).primary.code,
              defLang: ref.read(defLangPrimaryProvider),
            ));
  }

  Future<void> _extractFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    _runExtraction(
      () => ref.read(importServiceProvider).fetchAndParseUrl(
            url: url,
            langCode: ref.read(languageProvider).primary.code,
            defLang: ref.read(defLangPrimaryProvider),
          ),
    );
  }

  Future<void> _extractFromImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    _runExtraction(
      () => ref.read(importServiceProvider).parseImage(
            imageFile: File(picked.path),
            langCode: ref.read(languageProvider).primary.code,
            defLang: ref.read(defLangPrimaryProvider),
          ),
    );
  }

  Future<void> _extractFromVoice() async {
    if (_voiceTranscript.trim().isEmpty) return;
    _runExtraction(
      () => ref.read(importServiceProvider).parseVoiceText(
            transcript: _voiceTranscript,
            langCode: ref.read(languageProvider).primary.code,
            defLang: ref.read(defLangPrimaryProvider),
          ),
    );
  }

  Future<void> _runExtraction(
      Future<ImportParseResult> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await action();
      if (!mounted) return;

      if (!result.success) {
        setState(() => _error = result.error ?? 'Không trích xuất được từ vựng');
        return;
      }

      final langCode = ref.read(languageProvider).primary.code;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => WordPreviewScreen(
          parseResult: result,
          langCode: langCode,
        ),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Voice listening ────────────────────────────────────────

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    final lang = ref.read(languageProvider).primary.code;
    // Chuyển language code cho speech_to_text (lấy 2 ký tự đầu)
    final locale = lang.replaceAll('-', '_');

    setState(() {
      _isListening = true;
      _voiceTranscript = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() => _voiceTranscript = result.recognizedWords);
      },
      localeId: locale,
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guiLangProvider);
    final primaryLang = ref.watch(languageProvider).primary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(lang, 'import_vocab')),
            Text(
              '${primaryLang.flag} ${primaryLang.name}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.text_fields_rounded, size: 20),
                text: tr(lang, 'import_tab_text')),
            Tab(icon: const Icon(Icons.link_rounded, size: 20),
                text: tr(lang, 'import_tab_url')),
            Tab(icon: const Icon(Icons.image_outlined, size: 20),
                text: tr(lang, 'import_tab_image')),
            Tab(icon: const Icon(Icons.mic_outlined, size: 20),
                text: tr(lang, 'import_tab_voice')),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildTextTab(lang),
              _buildUrlTab(lang),
              _buildImageTab(lang),
              _buildVoiceTab(lang),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(tr(lang, 'import_extracting')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab: Text ──────────────────────────────────────────────

  Widget _buildTextTab(String lang) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_error != null) _buildErrorBanner(_error!),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: tr(lang, 'import_paste_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(height: 12),
          _buildExtractButton(
            lang: lang,
            label: tr(lang, 'import_extract'),
            icon: Icons.auto_awesome_rounded,
            onTap: _extractFromText,
            enabled: _textController.text.trim().isNotEmpty,
          ),
        ],
      ),
    );
  }

  // ── Tab: URL ───────────────────────────────────────────────

  Widget _buildUrlTab(String lang) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _buildErrorBanner(_error!),
          const SizedBox(height: 4),
          Text(
            tr(lang, 'import_url_desc'),
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _urlController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 8),
          // URL suggestions
          Wrap(
            spacing: 8,
            children: [
              'wikipedia.org',
              'bbc.com/news',
              'medium.com',
            ].map((site) => ActionChip(
              label: Text(site, style: const TextStyle(fontSize: 12)),
              onPressed: () {
                _urlController.text = 'https://$site';
                setState(() {});
              },
            )).toList(),
          ),
          const Spacer(),
          _buildExtractButton(
            lang: lang,
            label: tr(lang, 'import_fetch_url'),
            icon: Icons.travel_explore_rounded,
            onTap: _extractFromUrl,
            enabled: _urlController.text.trim().isNotEmpty,
          ),
        ],
      ),
    );
  }

  // ── Tab: Image ─────────────────────────────────────────────

  Widget _buildImageTab(String lang) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _buildErrorBanner(_error!),
          const SizedBox(height: 8),
          Text(
            tr(lang, 'import_image_desc'),
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Illustration
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.image_search_rounded,
                  size: 56, color: Color(0xFF3B82F6)),
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: _buildImageButton(
                  icon: Icons.camera_alt_outlined,
                  label: tr(lang, 'image_take_photo'),
                  onTap: () => _extractFromImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImageButton(
                  icon: Icons.photo_library_outlined,
                  label: tr(lang, 'image_select'),
                  onTap: () => _extractFromImage(ImageSource.gallery),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildUseCasesList(lang, [
            tr(lang, 'image_use_1'),
            tr(lang, 'image_use_2'),
            tr(lang, 'image_use_3'),
          ]),
        ],
      ),
    );
  }

  // ── Tab: Voice ─────────────────────────────────────────────

  Widget _buildVoiceTab(String lang) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_error != null) _buildErrorBanner(_error!),

          const SizedBox(height: 16),

          // Mic button
          Center(
            child: GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isListening ? 100 : 84,
                height: _isListening ? 100 : 84,
                decoration: BoxDecoration(
                  color: _isListening
                      ? errorRed
                      : _speechAvailable
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: errorRed.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: _isListening ? 44 : 36,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            !_speechAvailable
                ? tr(lang, 'voice_not_available')
                : _isListening
                    ? tr(lang, 'voice_listening')
                    : tr(lang, 'voice_tap_to_start'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isListening ? errorRed : Colors.grey[600],
              fontWeight:
                  _isListening ? FontWeight.w600 : FontWeight.normal,
            ),
          ),

          // Transcript
          if (_voiceTranscript.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _voiceTranscript,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            _buildExtractButton(
              lang: lang,
              label: tr(lang, 'import_extract'),
              icon: Icons.auto_awesome_rounded,
              onTap: _extractFromVoice,
              enabled: !_isListening,
            ),
          ] else ...[
            const SizedBox(height: 24),
            _buildUseCasesList(lang, [
              tr(lang, 'voice_use_1'),
              tr(lang, 'voice_use_2'),
              tr(lang, 'voice_use_3'),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────

  Widget _buildExtractButton({
    required String lang,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[200],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFF3B82F6)),
        foregroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: errorRed, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, size: 16, color: errorRed),
          ),
        ],
      ),
    );
  }

  Widget _buildUseCasesList(String lang, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(lang, 'use_cases_title').toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(item,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
