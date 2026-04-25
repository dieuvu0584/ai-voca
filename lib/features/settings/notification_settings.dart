import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _enabled = false;
  // List of (id, TimeOfDay) — id dùng để map với native alarm
  List<(int, TimeOfDay)> _times = [];
  bool _batteryOptDisabled = false;

  static const int _maxReminders = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notifService = ref.read(notifServiceProvider);
    final battOpt = await notifService.isBatteryOptimizationDisabled();

    final enabled = prefs.getBool('notif_enabled') ?? false;
    final count = prefs.getInt('notif_times_count') ?? 0;

    List<(int, TimeOfDay)> times = [];
    if (count > 0) {
      for (var i = 0; i < count; i++) {
        final id = prefs.getInt('notif_time_${i}_id') ?? i;
        final hour = prefs.getInt('notif_time_${i}_hour') ?? 9;
        final minute = prefs.getInt('notif_time_${i}_minute') ?? 0;
        times.add((id, TimeOfDay(hour: hour, minute: minute)));
      }
    } else {
      // Migrate từ setting cũ (single time)
      final oldHour = prefs.getInt('notif_hour');
      if (oldHour != null) {
        final oldMinute = prefs.getInt('notif_minute') ?? 0;
        times = [(0, TimeOfDay(hour: oldHour, minute: oldMinute))];
      } else if (enabled) {
        times = [(0, const TimeOfDay(hour: 9, minute: 0))];
      }
    }

    setState(() {
      _enabled = enabled;
      _times = times;
      _batteryOptDisabled = battOpt;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', _enabled);
    await prefs.setInt('notif_times_count', _times.length);
    for (var i = 0; i < _times.length; i++) {
      final (id, time) = _times[i];
      await prefs.setInt('notif_time_${i}_id', id);
      await prefs.setInt('notif_time_${i}_hour', time.hour);
      await prefs.setInt('notif_time_${i}_minute', time.minute);
    }
  }

  Future<void> _scheduleAll() async {
    final notifService = ref.read(notifServiceProvider);
    final lang = ref.read(guiLangProvider);

    if (!_enabled) {
      await notifService.cancelAll();
      return;
    }

    final granted = await notifService.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(lang, 'notif_permission_denied'))),
        );
      }
      return;
    }

    if (Platform.isAndroid && !_batteryOptDisabled) {
      await notifService.requestBatteryOptimizationExemption();
      final updated = await notifService.isBatteryOptimizationDisabled();
      setState(() => _batteryOptDisabled = updated);
    }

    // Cancel all rồi schedule lại toàn bộ
    await notifService.cancelAll();
    for (final (id, time) in _times) {
      await notifService.scheduleReminder(
        id: id,
        time: time,
        title: tr(lang, 'notif_title'),
        body: tr(lang, 'notif_body_simple'),
      );
    }
  }

  Future<void> _addTime() async {
    if (_times.length >= _maxReminders) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;

    // Tạo ID mới (max existing + 1)
    final newId = _times.isEmpty ? 0 : _times.map((e) => e.$1).reduce((a, b) => a > b ? a : b) + 1;
    setState(() => _times.add((newId, picked)));
    await _saveSettings();
    await _scheduleAll();
  }

  Future<void> _editTime(int index) async {
    final (id, oldTime) = _times[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: oldTime,
    );
    if (picked == null) return;

    setState(() => _times[index] = (id, picked));
    await _saveSettings();
    await _scheduleAll();
  }

  Future<void> _removeTime(int index) async {
    final notifService = ref.read(notifServiceProvider);
    final (id, _) = _times[index];
    await notifService.cancelReminder(id);
    setState(() => _times.removeAt(index));
    await _saveSettings();
    if (_times.isEmpty) {
      setState(() => _enabled = false);
      await _saveSettings();
    }
  }

  Future<void> _requestBatteryExemption() async {
    final notifService = ref.read(notifServiceProvider);
    await notifService.requestBatteryOptimizationExemption();
    await Future.delayed(const Duration(seconds: 2));
    final updated = await notifService.isBatteryOptimizationDisabled();
    setState(() => _batteryOptDisabled = updated);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guiLangProvider);
    final cs = appColors(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'study_reminder'))),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            SwitchListTile(
              title: Text(tr(lang, 'enable_daily')),
              value: _enabled,
              onChanged: (v) async {
                setState(() {
                  _enabled = v;
                  if (v && _times.isEmpty) {
                    _times = [(0, const TimeOfDay(hour: 9, minute: 0))];
                  }
                });
                await _saveSettings();
                await _scheduleAll();
              },
            ),

            if (_enabled) ...[
              const Divider(height: 1),

              // Danh sách giờ remind
              ..._times.asMap().entries.map((entry) {
                final i = entry.key;
                final (_, time) = entry.value;
                return ListTile(
                  leading: Icon(Icons.access_time, color: cs.primary),
                  title: Text(
                    time.format(context),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => _editTime(i),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent),
                    onPressed: () => _removeTime(i),
                  ),
                );
              }),

              // Nút thêm giờ
              if (_times.length < _maxReminders)
                ListTile(
                  leading: Icon(Icons.add_circle_outline, color: cs.primary),
                  title: Text(
                    tr(lang, 'add_reminder_time'),
                    style: TextStyle(color: cs.primary),
                  ),
                  onTap: _addTime,
                ),

              const Divider(height: 1),

              // Battery optimization warning (Android)
              if (Platform.isAndroid && !_batteryOptDisabled) ...[
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr(lang, 'battery_opt_warning'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(lang, 'battery_opt_desc'),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _requestBatteryExemption,
                          icon: const Icon(Icons.battery_saver, size: 18),
                          label: Text(tr(lang, 'battery_opt_button')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Battery optimization OK
              if (Platform.isAndroid && _batteryOptDisabled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        tr(lang, 'battery_opt_ok'),
                        style: TextStyle(
                            fontSize: 12, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
