import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _wordCount = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('notif_enabled') ?? false;
      _time = TimeOfDay(
        hour: prefs.getInt('notif_hour') ?? 9,
        minute: prefs.getInt('notif_minute') ?? 0,
      );
      _wordCount = prefs.getInt('notif_word_count') ?? 10;
    });
  }

  Future<void> _saveAndSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', _enabled);
    await prefs.setInt('notif_hour', _time.hour);
    await prefs.setInt('notif_minute', _time.minute);
    await prefs.setInt('notif_word_count', _wordCount);

    final notifService = ref.read(notifServiceProvider);

    if (_enabled) {
      final granted = await notifService.requestPermission();
      if (granted) {
        await notifService.scheduleDailyReminder(
          time: _time,
          title: 'Vocab AI - Tu moi hom nay',
          body: 'Hay on tap $_wordCount tu vung ngay hom nay!',
        );
      }
    } else {
      await notifService.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhac hoc')),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
          SwitchListTile(
            title: const Text('Bat nhac hoc hang ngay'),
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              _saveAndSchedule();
            },
          ),
          if (_enabled) ...[
            ListTile(
              title: const Text('Gio nhac'),
              trailing: Text(
                _time.format(context),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) {
                  setState(() => _time = picked);
                  _saveAndSchedule();
                }
              },
            ),
            ListTile(
              title: const Text('So tu moi lan nhac'),
              trailing: DropdownButton<int>(
                value: _wordCount,
                items: [5, 10, 20]
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text('$c tu')))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _wordCount = v);
                  _saveAndSchedule();
                },
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }
}
