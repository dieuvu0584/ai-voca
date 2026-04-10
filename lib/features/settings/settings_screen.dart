import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';
import '../../core/providers.dart';
import 'ai_settings_screen.dart';
import 'notification_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoFlip = false;
  int _autoFlipSeconds = 5;
  int _sessionGoal = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoFlip = prefs.getBool('quick_review_auto_flip') ?? false;
      _autoFlipSeconds = prefs.getInt('quick_review_seconds') ?? 5;
      _sessionGoal = prefs.getInt('session_goal') ?? 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiSettings = ref.watch(aiSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cai dat')),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
          // AI Settings section
          _SectionHeader(title: 'Tro ly AI'),
          _buildAIModeCards(aiSettings),

          const Divider(),
          _SectionHeader(title: 'On tap nhanh'),

          SwitchListTile(
            title: const Text('Tu dong lat the'),
            subtitle: const Text('Tu dong hien dap an sau vai giay'),
            value: _autoFlip,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('quick_review_auto_flip', v);
              setState(() => _autoFlip = v);
            },
          ),

          if (_autoFlip)
            ListTile(
              title: const Text('Thoi gian moi the'),
              trailing: DropdownButton<int>(
                value: _autoFlipSeconds,
                items: [3, 5, 8, 10, 15]
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text('$s giay')))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('quick_review_seconds', v);
                  setState(() => _autoFlipSeconds = v);
                },
              ),
            ),

          ListTile(
            title: const Text('Muc tieu moi phien'),
            trailing: DropdownButton<int>(
              value: _sessionGoal,
              items: [5, 10, 20, 0]
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s == 0 ? 'Khong gioi han' : '$s tu')))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('session_goal', v);
                setState(() => _sessionGoal = v);
              },
            ),
          ),

          const Divider(),
          _SectionHeader(title: 'Thong bao'),
          ListTile(
            title: const Text('Nhac hoc hang ngay'),
            subtitle: const Text('Cai dat gio nhac va so tu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()),
            ),
          ),

          const Divider(),
          _SectionHeader(title: 'Thong tin'),
          const ListTile(
            title: Text('Phien ban'),
            trailing: Text('1.0.0'),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIModeCards(AISettings aiSettings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _AIModeCard(
            title: 'App mac dinh',
            subtitle: 'Dung AI do app cung cap san',
            badge: 'Mien phi',
            isSelected: aiSettings.mode == AIMode.appDefault,
            onTap: () =>
                ref.read(aiSettingsProvider.notifier).setMode(AIMode.appDefault),
          ),
          const SizedBox(height: 8),
          _AIModeCard(
            title: 'API key cua toi',
            subtitle: 'Claude / ChatGPT / Gemini / Grok / Mistral',
            badge: 'Tuy chinh',
            isSelected: aiSettings.mode == AIMode.userKey,
            onTap: () {
              ref.read(aiSettingsProvider.notifier).setMode(AIMode.userKey);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AISettingsDetailScreen()),
              );
            },
            trailing: aiSettings.mode == AIMode.userKey
                ? IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AISettingsDetailScreen()),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          _AIModeCard(
            title: 'Khong dung AI',
            subtitle: 'Flashcard, TTS, Tra tu van hoat dong',
            badge: 'Offline',
            isSelected: aiSettings.mode == AIMode.none,
            onTap: () =>
                ref.read(aiSettingsProvider.notifier).setMode(AIMode.none),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AIModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _AIModeCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? enColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_on : Icons.radio_button_off,
                color: isSelected ? enColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: enColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge,
                    style: const TextStyle(fontSize: 11, color: enColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
