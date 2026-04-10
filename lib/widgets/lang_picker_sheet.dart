import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../core/providers.dart';
import '../data/languages.dart';
import '../data/vocab_data.dart';

class LangPickerSheet extends ConsumerStatefulWidget {
  final bool isPrimary;

  const LangPickerSheet({super.key, required this.isPrimary});

  @override
  ConsumerState<LangPickerSheet> createState() => _LangPickerSheetState();
}

class _LangPickerSheetState extends ConsumerState<LangPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final langState = ref.watch(languageProvider);
    final filtered = kLanguages.where((l) {
      final q = _search.toLowerCase();
      return l.name.toLowerCase().contains(q) ||
          l.native.toLowerCase().contains(q) ||
          l.code.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tim ngon ngu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final lang = filtered[i];
                final isPrimary = lang.code == langState.primary.code;
                final isSecondary = lang.code == langState.secondary?.code;
                final wordCount = kBuiltinVocab[lang.code]?.length ?? 0;

                return ListTile(
                  leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
                  title: Text(
                    lang.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPrimary
                          ? enColor
                          : isSecondary
                              ? secondaryColor
                              : null,
                    ),
                  ),
                  subtitle: Text('${lang.native}  ·  $wordCount tu offline'),
                  trailing: isPrimary
                      ? const Icon(Icons.star, color: enColor)
                      : isSecondary
                          ? const Icon(Icons.check_circle,
                              color: secondaryColor)
                          : null,
                  onTap: () {
                    if (widget.isPrimary) {
                      ref.read(languageProvider.notifier).setPrimary(lang);
                    } else {
                      if (isSecondary) {
                        ref
                            .read(languageProvider.notifier)
                            .setSecondary(null);
                      } else {
                        ref
                            .read(languageProvider.notifier)
                            .setSecondary(lang);
                      }
                    }
                    Navigator.pop(context);
                  },
                  onLongPress: () {
                    // Long press → set as primary
                    ref.read(languageProvider.notifier).setPrimary(lang);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
