import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../core/providers.dart';
import '../data/languages.dart';
import 'lang_picker_sheet.dart';

class LangSlotBar extends ConsumerWidget {
  const LangSlotBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langState = ref.watch(languageProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Primary slot
          Expanded(
            child: _LangSlot(
              label: 'Ngon ngu chinh',
              language: langState.primary,
              isPrimary: true,
              onTap: () => _showPicker(context, ref, isPrimary: true),
            ),
          ),
          // VS divider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey[400],
              ),
            ),
          ),
          // Secondary slot
          Expanded(
            child: langState.secondary != null
                ? _LangSlot(
                    label: 'Ngon ngu phu',
                    language: langState.secondary!,
                    isPrimary: false,
                    onTap: () => _showPicker(context, ref, isPrimary: false),
                    onRemove: () =>
                        ref.read(languageProvider.notifier).setSecondary(null),
                  )
                : _AddSlot(
                    onTap: () => _showPicker(context, ref, isPrimary: false),
                  ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref,
      {required bool isPrimary}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LangPickerSheet(isPrimary: isPrimary),
    );
  }
}

class _LangSlot extends StatelessWidget {
  final String label;
  final Language language;
  final bool isPrimary;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _LangSlot({
    required this.label,
    required this.language,
    required this.isPrimary,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPrimary)
                  const Icon(Icons.star, size: 14, color: enColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(Icons.close, size: 14, color: Colors.grey[400]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${language.flag} ${language.name}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? enColor : secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSlot extends StatelessWidget {
  final VoidCallback onTap;

  const _AddSlot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Ngon ngu phu',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              '+ Them',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
