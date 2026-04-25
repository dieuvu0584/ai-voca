import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/ai/ai_service.dart';
import '../core/ai/ai_settings.dart';

class AiPill extends ConsumerWidget {
  const AiPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);

    final (String label, Color color) = switch (settings.mode) {
      AIMode.userKey => ('AI', const Color(0xFF27AE60)),
      AIMode.none || AIMode.appDefault => ('No AI', Colors.grey),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
