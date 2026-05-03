import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/tts/tts_service.dart';

// ── Source filter config ──────────────────────────────────────

const _kSources = [
  (key: 'all',    label: 'Tất cả',   icon: Icons.list_rounded),
  (key: 'text',   label: 'Text',     icon: Icons.text_fields_rounded),
  (key: 'url',    label: 'URL',      icon: Icons.link_rounded),
  (key: 'image',  label: 'Ảnh',      icon: Icons.image_rounded),
  (key: 'voice',  label: 'Voice',    icon: Icons.mic_rounded),
  (key: 'manual', label: 'Thủ công', icon: Icons.edit_rounded),
];

const _kSourceColors = {
  'text':   Color(0xFF6366F1),
  'url':    Color(0xFF0EA5E9),
  'image':  Color(0xFFF59E0B),
  'voice':  Color(0xFF10B981),
  'manual': Color(0xFF8B5CF6),
};

IconData _sourceIcon(String? s) => switch (s) {
  'text'   => Icons.text_fields_rounded,
  'url'    => Icons.link_rounded,
  'image'  => Icons.image_rounded,
  'voice'  => Icons.mic_rounded,
  _        => Icons.edit_rounded,
};

Color _sourceColor(String? s) =>
    _kSourceColors[s] ?? const Color(0xFF8B5CF6);

String _sourceLabel(String? s) => switch (s) {
  'text'  => 'Text',
  'url'   => 'URL',
  'image' => 'Ảnh',
  'voice' => 'Voice',
  _       => 'Thủ công',
};

// ── Screen ────────────────────────────────────────────────────

class VocabListScreen extends ConsumerStatefulWidget {
  const VocabListScreen({super.key});

  @override
  ConsumerState<VocabListScreen> createState() => _VocabListScreenState();
}

class _VocabListScreenState extends ConsumerState<VocabListScreen> {
  String _selectedSource = 'all';
  String _searchQuery = '';
  List<Word> _words = [];
  Map<String, int> _counts = {};
  bool _loading = true;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final langCode = ref.read(languageProvider).primary.code;
    final dao = ref.read(wordDaoProvider);

    final results = await Future.wait([
      dao.getWordsBySource(
        langCode: langCode,
        sourceType: _selectedSource == 'all' ? null : _selectedSource,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      ),
      dao.countBySourceType(langCode),
    ]);

    if (!mounted) return;
    setState(() {
      _words = results[0] as List<Word>;
      _counts = results[1] as Map<String, int>;
      _loading = false;
    });
  }

  void _onSourceChanged(String key) {
    setState(() => _selectedSource = key);
    _load();
  }

  void _onSearch(String q) {
    setState(() => _searchQuery = q);
    _load();
  }

  Future<void> _deleteWord(Word word) async {
    final dao = ref.read(wordDaoProvider);
    await dao.deleteWord(word.word, word.langCode);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guiLangProvider);
    final langState = ref.watch(languageProvider);
    final ttsService = ref.read(ttsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Từ vựng của tôi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              '${langState.primary.flag} ${langState.primary.name}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Tìm từ...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // ── Source filter chips ───────────────────────────
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _kSources.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = _kSources[i];
                final count = s.key == 'all'
                    ? (_counts['all'] ?? 0)
                    : (_counts[s.key] ?? 0);
                final selected = _selectedSource == s.key;
                final color = s.key == 'all'
                    ? const Color(0xFF1F2937)
                    : _sourceColor(s.key);

                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon,
                          size: 14,
                          color: selected ? Colors.white : color),
                      const SizedBox(width: 4),
                      Text('${s.label} ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : color,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                  backgroundColor: color.withValues(alpha: 0.08),
                  selectedColor: color,
                  side: BorderSide(
                      color: selected
                          ? color
                          : color.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onSelected: (_) => _onSourceChanged(s.key),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Word list ─────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _words.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _words.length,
                          itemBuilder: (context, i) =>
                              _WordTile(
                            word: _words[i],
                            ttsService: ttsService,
                            ttsLang: langState.primary.ttsLang,
                            onDelete: () => _confirmDelete(_words[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy từ nào'
                : 'Chưa có từ vựng nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          if (_searchQuery.isEmpty && _selectedSource == 'all') ...[
            const SizedBox(height: 8),
            Text(
              'Import từ Text, URL, Ảnh hoặc Voice',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Word word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa từ'),
        content: Text('Xóa "${word.word}" khỏi danh sách?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Xóa', style: TextStyle(color: errorRed))),
        ],
      ),
    );
    if (confirmed == true) _deleteWord(word);
  }
}

// ── Word tile ─────────────────────────────────────────────────

class _WordTile extends StatelessWidget {
  final Word word;
  final TtsService ttsService;
  final String ttsLang;
  final VoidCallback onDelete;

  const _WordTile({
    required this.word,
    required this.ttsService,
    required this.ttsLang,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sourceType = word.sourceType;
    final color = _sourceColor(sourceType);

    return Dismissible(
      key: Key('${word.word}_${word.langCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: errorRed,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // xóa thủ công qua onDelete để có confirm dialog
      },
      child: InkWell(
        onTap: () => ttsService.speak(word.word, ttsLang: ttsLang),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_sourceIcon(sourceType),
                    size: 16, color: color),
              ),
              const SizedBox(width: 12),

              // Word + definition
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            word.word,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (word.partOfSpeech != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              word.partOfSpeech!,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    if (word.definition != null &&
                        word.definition!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        word.definition!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (word.sourceContext != null &&
                        word.sourceContext!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 11,
                              color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _kSourceColors.containsKey(sourceType)
                                  ? '${_sourceLabel(sourceType)}: ${word.sourceContext!}'
                                  : word.sourceContext!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // TTS button
              IconButton(
                onPressed: () =>
                    ttsService.speak(word.word, ttsLang: ttsLang),
                icon: const Icon(Icons.volume_up_outlined, size: 18),
                color: Colors.grey.shade400,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
