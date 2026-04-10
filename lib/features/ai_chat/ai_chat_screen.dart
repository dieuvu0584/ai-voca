import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';

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

  String get _systemPrompt {
    final langState = ref.read(languageProvider);
    return 'Ban la tro ly day tu vung thong minh. '
        'Ngon ngu chinh: ${langState.primary.name}. '
        '${langState.secondary != null ? "Ngon ngu phu: ${langState.secondary!.name}. " : ""}'
        'Tra loi bang tieng Viet. Giai thich ro rang, cho vi du cu the. '
        'Khi nguoi dung hoi ve tu vung, cho: nghia, cach dung, vi du, tu dong nghia/trai nghia.';
  }

  List<_QuickButton> get _quickButtons {
    final langState = ref.read(languageProvider);
    return [
      _QuickButton(
        label: 'Tu moi hom nay',
        prompt: 'Goi y 5 tu vung ${langState.primary.name} moi phu hop voi trinh do trung cap.',
      ),
      _QuickButton(
        label: 'Giai thich ngu phap',
        prompt: 'Giai thich mot diem ngu phap thuong gap trong ${langState.primary.name}.',
      ),
      _QuickButton(
        label: 'Hoi thoai mau',
        prompt: 'Viet mot doan hoi thoai ngan bang ${langState.primary.name} ve chu de mua sam.',
      ),
      _QuickButton(
        label: 'Thanh ngu',
        prompt: 'Goi y 3 thanh ngu/tuc ngu trong ${langState.primary.name} va giai thich.',
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

    final response = await aiService.complete(
      messages: _messages,
      systemPrompt: _systemPrompt,
    );

    if (mounted) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response ?? 'Xin loi, khong the tra loi luc nay.',
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

    if (aiSettings.mode == AIMode.none) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hoi AI')),
        body: const Center(
          child: Text('AI da tat. Bat AI trong Cai dat de su dung.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoi AI'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _messages.clear()),
              tooltip: 'Xoa lich su',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
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
          // Input
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
                      hintText: 'Nhap cau hoi...',
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(Icons.auto_awesome, size: 48, color: secondaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Hoi AI bat cu dieu gi!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'AI se giup ban hoc tu vung, ngu phap, va nhieu hon',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _quickButtons
                .map((b) => ActionChip(
                      label: Text(b.label),
                      onPressed: () => _send(b.prompt),
                      backgroundColor:
                          secondaryColor.withValues(alpha: 0.08),
                      labelStyle: const TextStyle(color: secondaryColor),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? enColor : Colors.white,
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
      builder: (_, __) => Container(
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
