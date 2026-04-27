import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/premium/premium_notifier.dart';
import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import 'lang_picker_sheet.dart';

class LangSlotBar extends ConsumerWidget {
  const LangSlotBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langState = ref.watch(languageProvider);
    final isPremium = ref.watch(effectivePremiumProvider);
    final cs = appColors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _LangSelectTile(
        flag: langState.primary.flag,
        name: langState.primary.name,
        color: cs.primary,
        onTap: () => _showPicker(context, ref, isPrimary: true),
        showPremiumBadge: !isPremium,
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

class _LangSelectTile extends StatelessWidget {
  final String? flag;
  final String name;
  final Color color;
  final VoidCallback onTap;
  final bool showPremiumBadge;

  const _LangSelectTile({
    required this.flag,
    required this.name,
    required this.color,
    required this.onTap,
    this.showPremiumBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            if (flag != null)
              Text(flag!, style: const TextStyle(fontSize: 22)),
            if (flag != null) const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showPremiumBadge) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 11, color: Colors.amber),
                    SizedBox(width: 3),
                    Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.arrow_drop_down, color: color),
          ],
        ),
      ),
    );
  }
}
