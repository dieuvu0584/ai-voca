import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/l10n/strings.dart';
import '../core/theme/app_theme.dart';
import '../data/languages.dart';


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
    final cs = appColors(context);
    final langState = ref.watch(languageProvider);
    final lang = ref.watch(guiLangProvider);
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
                hintText: tr(lang, 'search_language'),
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
                final l = filtered[i];
                final isPrimary = l.code == langState.primary.code;
                final isSecondary = l.code == langState.secondary?.code;

                return ListTile(
                  leading: Text(l.flag, style: const TextStyle(fontSize: 28)),
                  title: Text(
                    l.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPrimary
                          ? cs.primary
                          : isSecondary
                              ? cs.secondary
                              : null,
                    ),
                  ),
                  subtitle: Text(l.native),
                  trailing: isPrimary
                      ? Icon(Icons.star, color: cs.primary)
                      : isSecondary
                          ? Icon(Icons.check_circle, color: cs.secondary)
                          : null,
                  onTap: () {
                    if (widget.isPrimary) {
                      ref.read(languageProvider.notifier).setPrimary(l);
                    } else {
                      if (isSecondary) {
                        ref
                            .read(languageProvider.notifier)
                            .setSecondary(null);
                      } else {
                        ref
                            .read(languageProvider.notifier)
                            .setSecondary(l);
                      }
                    }
                    Navigator.pop(context);
                  },
                  onLongPress: () {
                    ref.read(languageProvider.notifier).setPrimary(l);
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
