import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/ai/ai_settings.dart';
import 'core/l10n/strings.dart';
import 'core/premium/premium_notifier.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Khởi tạo Firebase (optional — app vẫn chạy nếu chưa cấu hình)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    container.read(firebaseReadyProvider.notifier).state = true;
    debugPrint('[Firebase] Khởi tạo thành công');
  } catch (e) {
    // Firebase chưa cấu hình hoặc lỗi — app vẫn chạy bình thường
    // Chạy `flutterfire configure` để kích hoạt cloud backup
    debugPrint('[Firebase] Chưa cấu hình hoặc lỗi: $e');
  }

  // Load saved settings
  await container.read(languageProvider.notifier).load();
  await container.read(guiLangProvider.notifier).load();
  await container.read(defLangPrimaryProvider.notifier).load();
  await container.read(appThemeProvider.notifier).load();
  await container.read(aiSettingsProvider.notifier).load();
  await container.read(ttsServiceProvider).init();
  await container.read(notifServiceProvider).init();
  // Khởi tạo Premium (load cached + lắng nghe purchase stream)
  container.read(premiumProvider);

  // Re-schedule notification nếu user đã bật
  _rescheduleNotification(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VocabAIApp(),
    ),
  );
}

/// Re-schedule daily reminder mỗi khi app khởi động
/// (cần thiết vì Android có thể xóa alarm khi reboot hoặc force-stop)
Future<void> _rescheduleNotification(ProviderContainer container) async {
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('notif_enabled') ?? false;
  if (!enabled) return;

  final hour = prefs.getInt('notif_hour') ?? 9;
  final minute = prefs.getInt('notif_minute') ?? 0;
  final lang = prefs.getString('gui_lang') ?? 'en-US';
  final notifService = container.read(notifServiceProvider);

  await notifService.scheduleDailyReminder(
    time: TimeOfDay(hour: hour, minute: minute),
    title: tr(lang, 'notif_title'),
    body: tr(lang, 'notif_body_simple'),
  );
}
