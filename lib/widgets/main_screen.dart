import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../core/providers.dart';
import '../core/ai/ai_service.dart';
import '../core/ai/ai_settings.dart';
import 'lang_slot_bar.dart';
import 'ai_pill.dart';
import 'net_badge.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiSettings = ref.watch(aiSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocab AI'),
        actions: [
          const NetBadge(),
          const AiPill(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const LangSlotBar(),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _MenuCard(
                      icon: Icons.style,
                      label: 'Flashcard',
                      color: enColor,
                      onTap: () => context.push('/preview?mode=flashcard'),
                    ),
                    _MenuCard(
                      icon: Icons.bolt,
                      label: 'On tap nhanh',
                      color: warningOrange,
                      onTap: () => context.push('/preview?mode=quick-review'),
                    ),
                    _MenuCard(
                      icon: Icons.search,
                      label: 'Tra tu',
                      color: successGreen,
                      onTap: () => context.push('/lookup'),
                    ),
                    _MenuCard(
                      icon: Icons.auto_awesome,
                      label: 'Hoi AI',
                      color: secondaryColor,
                      onTap: aiSettings.mode == AIMode.none
                          ? null
                          : () => context.push('/ai-chat'),
                    ),
                    _MenuCard(
                      icon: Icons.bar_chart,
                      label: 'Tien do',
                      color: krColor,
                      onTap: () => context.push('/progress'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Card(
      elevation: enabled ? 2 : 0,
      color: enabled ? Colors.white : Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: enabled ? color : Colors.grey),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: enabled ? primaryColor : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
