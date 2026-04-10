import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers.dart';
import 'core/ai/ai_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Load saved settings
  await container.read(languageProvider.notifier).load();
  await container.read(aiSettingsProvider.notifier).load();
  await container.read(ttsServiceProvider).init();
  await container.read(notifServiceProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VocabAIApp(),
    ),
  );
}
