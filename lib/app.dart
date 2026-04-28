import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/l10n/strings.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/flashcard/flashcard_screen.dart';
import 'features/lookup/lookup_screen.dart';
import 'features/ai_chat/ai_chat_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/backup/backup_screen.dart';
import 'features/import_vocab/import_screen.dart';
import 'features/session_preview/session_preview_screen.dart';
import 'features/splash/splash_screen.dart';
import 'widgets/main_screen.dart';

// ── Màu cố định (không đổi theo theme) ───────────────────────
const primaryColor  = Color(0xFF1F2937);  // text, heading — luôn dark
const cardColor     = Colors.white;
const successGreen  = Color(0xFF10B981);
const warningOrange = Color(0xFFF59E0B);
const errorRed      = Color(0xFFEF4444);

// ── Màu cố định theo ngữ nghĩa (không đổi theo theme) ────────
const krColor = Color(0xFFF59E0B);  // amber — UK audio badge

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, _) => const MainScreen()),
    GoRoute(
        path: '/preview',
        builder: (_, _) => const SessionPreviewScreen()),
    GoRoute(path: '/flashcard', builder: (_, _) => const FlashcardScreen()),
    GoRoute(path: '/lookup', builder: (_, _) => const LookupScreen()),
    GoRoute(path: '/ai-chat', builder: (_, _) => const AIChatScreen()),
    GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/backup', builder: (_, _) => const BackupScreen()),
    GoRoute(path: '/import', builder: (_, _) => const ImportScreen()),
  ],
);

class VocabAIApp extends ConsumerWidget {
  const VocabAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang      = ref.watch(guiLangProvider);
    final themeId   = ref.watch(appThemeProvider);
    final preset = findAppTheme(themeId);
    final cs = preset.colors;

    return MaterialApp.router(
      title: tr(lang, 'app_title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: preset.seed,
          primary: cs.primary,
          secondary: cs.secondary,
          surface: cs.background,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: cs.background,
        cardColor: cardColor,
        extensions: [cs],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          shadowColor: cs.primary.withValues(alpha: 0.08),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? cs.primary : null),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? cs.primary.withValues(alpha: 0.4)
                  : null),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w800, color: primaryColor),
          headlineMedium: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: primaryColor),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),
      routerConfig: _router,
    );
  }
}
