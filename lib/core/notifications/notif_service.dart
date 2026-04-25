import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotifService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Function(String?)? onNotificationTap;

  static const _channelId = 'vocab_alarm_v3';
  static const _channelName = 'Nhắc học từ vựng';
  static const _channelDesc = 'Nhắc nhở học từ vựng hàng ngày';

  /// Platform channels
  static const _batteryChannel = MethodChannel('com.vocabai/battery');
  static const _alarmChannel = MethodChannel('com.vocabai/alarm');

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      // Timezone fallback — native layer logs details
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );
    // Tạo notification channel (Android 8+)
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    }
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final notifGranted =
            await android.requestNotificationsPermission() ?? false;
        if (!notifGranted) return false;
        return true;
      }
    }
    return true;
  }

  /// Kiểm tra và yêu cầu tắt battery optimization
  Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _batteryChannel.invokeMethod<bool>('requestIgnoreBatteryOptimization');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Kiểm tra app đã được exempt khỏi battery optimization chưa
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _batteryChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Schedule reminder dùng native setAlarmClock (Samsung-proof)
  /// Schedule một reminder với ID cụ thể (hỗ trợ nhiều giờ)
  Future<void> scheduleReminder({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _alarmChannel.invokeMethod('scheduleAlarm', {
          'id': id,
          'hour': time.hour,
          'minute': time.minute,
          'title': title,
          'body': body,
        });
      } catch (_) {}
    } else {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'flashcard',
      );
    }
  }

  /// Huỷ một reminder theo ID
  Future<void> cancelReminder(int id) async {
    if (Platform.isAndroid) {
      try {
        await _alarmChannel.invokeMethod('cancelAlarm', {'id': id});
      } catch (_) {}
    } else {
      await _plugin.cancel(id);
    }
  }

  // Giữ backward-compat alias
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
    String? payload,
  }) => scheduleReminder(id: 0, time: time, title: title, body: body);

  /// Hiện notification ngay lập tức
  Future<void> showNow({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      99,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<int> getPendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    if (Platform.isAndroid) {
      try {
        await _alarmChannel.invokeMethod('cancelAlarm');
      } catch (_) {
        // Native layer handles its own logging
      }
    }
  }
}
