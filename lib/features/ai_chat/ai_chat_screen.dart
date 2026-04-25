import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../data/languages.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  String _buildSystemPrompt(String guiLangCode) {
    final langState = ref.read(languageProvider);
    final guiLang = kLanguages.firstWhere(
      (l) => l.code == guiLangCode,
      orElse: () => kLanguages.first,
    );
    return 'You are a smart vocabulary learning assistant. '
        'Target language: ${langState.primary.name}. '
        '${langState.secondary != null ? 'Secondary language: ${langState.secondary!.name}. ' : ''}'
        'Always respond in ${guiLang.native} (${guiLang.name}). '
        'Explain clearly with concrete examples. '
        'When asked about vocabulary, provide: meaning, usage, examples, synonyms/antonyms.';
  }

  List<_QuickButton> _quickButtons(String lang) {
    final langState = ref.read(languageProvider);
    final targetLang = langState.primary.name;
    return [
      _QuickButton(
        label: tr(lang, 'new_words_today'),
        prompt: trArgs(lang, 'prompt_new_words', {'lang': targetLang}),
      ),
      _QuickButton(
        label: tr(lang, 'explain_grammar'),
        prompt: trArgs(lang, 'prompt_grammar', {'lang': targetLang}),
      ),
      _QuickButton(
        label: tr(lang, 'sample_conversation'),
        prompt: trArgs(lang, 'prompt_conversation', {'lang': targetLang}),
      ),
      _QuickButton(
        label: tr(lang, 'idioms'),
        prompt: trArgs(lang, 'prompt_idioms', {'lang': targetLang}),
      ),
    ];
  }

  Future<void> _send([String? text]) async {
    final content = text ?? _controller.text.trim();
    if (content.isEmpty) return;

    final aiService = ref.read(aiServiceProvider);
    if (aiService == null) return;

    setState(() {
      _messages.add({'role': 'user', 'content': content});
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final lang = ref.read(guiLangProvider);
    final response = await aiService.complete(
      messages: _messages,
      systemPrompt: _buildSystemPrompt(lang),
    );

    if (mounted) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response ?? tr(lang, 'sorry_cant_answer'),
        });
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final lang = ref.watch(guiLangProvider);

    if (aiSettings.mode == AIMode.none) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(lang, 'ask_ai'))),
        body: Center(
          child: Text(tr(lang, 'ai_disabled')),
        ),
      );
    }

    final providerIcon = aiProviderIcon(aiSettings.provider);
    final providerColor = appColors(context).primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(providerIcon, size: 18, color: providerColor),
            const SizedBox(width: 6),
            Text(tr(lang, 'ask_ai')),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _messages.clear()),
              tooltip: tr(lang, 'clear_history'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(lang, providerIcon, providerColor)
                  : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = _messages[i];
                      final isUser = msg['role'] == 'user';
                      return _buildMessage(msg['content']!, isUser);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: tr(lang, 'enter_question'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isTyping ? null : () => _send(),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang, IconData providerIcon, Color providerColor) {
    final cs = appColors(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(providerIcon, size: 48, color: providerColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            tr(lang, 'ask_ai_anything'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            tr(lang, 'ai_help_desc'),
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _quickButtons(lang)
                .map((b) => ActionChip(
                      label: Text(b.label),
                      onPressed: () => _send(b.prompt),
                      backgroundColor:
                          cs.secondary.withValues(alpha: 0.08),
                      labelStyle: TextStyle(color: cs.secondary),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String content, bool isUser) {
    final cs = appColors(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? cs.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : primaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedDot(delay: 0),
            const SizedBox(width: 4),
            _AnimatedDot(delay: 200),
            const SizedBox(width: 4),
            _AnimatedDot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _QuickButton {
  final String label;
  final String prompt;
  const _QuickButton({required this.label, required this.prompt});
}

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3 + _controller.value * 0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
