import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/import_vocab/import_models.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';

/// Màn hình xem trước danh sách từ trích xuất — user chọn từ muốn import
class WordPreviewScreen extends ConsumerStatefulWidget {
  final ImportParseResult parseResult;
  final String langCode;

  const WordPreviewScreen({
    super.key,
    required this.parseResult,
    required this.langCode,
  });

  @override
  ConsumerState<WordPreviewScreen> createState() => _WordPreviewScreenState();
}

class _WordPreviewScreenState extends ConsumerState<WordPreviewScreen> {
  late List<ImportedWord> _words;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.parseResult.words);
    _markDuplicates();
  }

  Future<void> _markDuplicates() async {
    final svc = ref.read(importServiceProvider);
    await svc.markDuplicates(_words, widget.langCode);
    if (mounted) setState(() {});
  }

  int get _selectedCount =>
      _words.where((w) => w.selected && !w.alreadyInDb).length;

  void _toggleAll(bool select) {
    setState(() {
      for (final w in _words) {
        if (!w.alreadyInDb) w.selected = select;
      }
    });
  }

  Future<void> _importSelected() async {
    if (_selectedCount == 0) return;
    setState(() => _importing = true);

    try {
      final svc = ref.read(importServiceProvider);
      final count = await svc.importWords(
        words: _words,
        langCode: widget.langCode,
        source: widget.parseResult.source,
        sourceContext: widget.parseResult.sourceContext,
      );

      if (!mounted) return;

      // Reload stats trên homepage
      ref.read(statsRefreshProvider.notifier).update((s) => s + 1);

      Navigator.of(context).pop(); // đóng preview
      Navigator.of(context).pop(); // đóng import screen

      final lang = ref.read(guiLangProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(trArgs(lang, 'import_done', {'n': '$count'})),
            ],
          ),
          backgroundColor: successGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guiLangProvider);
    final newCount = _words.where((w) => !w.alreadyInDb).length;
    final dupCount = _words.length - newCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(lang, 'import_preview_title')),
        actions: [
          // Toggle all
          TextButton(
            onPressed: () => _toggleAll(_selectedCount < newCount),
            child: Text(
              _selectedCount < newCount
                  ? tr(lang, 'import_select_all')
                  : tr(lang, 'import_deselect_all'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                _StatChip(
                  label: '$newCount ${tr(lang, 'new_words_label')}',
                  color: successGreen,
                  icon: Icons.add_circle_outline,
                ),
                const SizedBox(width: 8),
                if (dupCount > 0)
                  _StatChip(
                    label: '$dupCount ${tr(lang, 'already_in_db')}',
                    color: Colors.grey,
                    icon: Icons.check_circle_outline,
                  ),
                const Spacer(),
                Text(
                  '${tr(lang, 'source')}: ${widget.parseResult.source.label}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Word list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _words.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) => _buildWordTile(_words[i], lang),
            ),
          ),
        ],
      ),

      // Import FAB
      floatingActionButton: _selectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: _importing ? null : _importSelected,
              backgroundColor: successGreen,
              icon: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.download_done_rounded,
                      color: Colors.white),
              label: Text(
                trArgs(lang, 'import_btn', {'n': '$_selectedCount'}),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildWordTile(ImportedWord word, String lang) {
    final isDup = word.alreadyInDb;

    return CheckboxListTile(
      value: isDup ? false : word.selected,
      onChanged: isDup
          ? null
          : (v) => setState(() => word.selected = v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Expanded(
            child: Text(
              word.word,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDup ? Colors.grey : null,
                decoration: isDup ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (word.partOfSpeech != null)
            _PosBadge(pos: word.partOfSpeech!),
          if (word.isPhrase)
            _PosBadge(pos: 'phrase', color: const Color(0xFF8B5CF6)),
          if (isDup)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                tr(lang, 'already_in_db'),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            word.definition,
            style: TextStyle(
              fontSize: 13,
              color: isDup ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          if (word.example != null && word.example!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '"${word.example}"',
              style: TextStyle(
                fontSize: 12,
                color: isDup ? Colors.grey[300] : Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Widgets nhỏ ────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PosBadge extends StatelessWidget {
  final String pos;
  final Color? color;

  const _PosBadge({required this.pos, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF3B82F6);
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        pos,
        style: TextStyle(
            fontSize: 10, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
