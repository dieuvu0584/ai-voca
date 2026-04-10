import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/flashcard/flashcard_screen.dart';
import 'features/quick_review/quick_review_screen.dart';
import 'features/lookup/lookup_screen.dart';
import 'features/ai_chat/ai_chat_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/session_preview/session_preview_screen.dart';
import 'widgets/main_screen.dart';

// Colors
const primaryColor = Color(0xFF111111);
const enColor = Color(0xFF1A6FB5);
const krColor = Color(0xFFC0392B);
const secondaryColor = Color(0xFF6C3FC7);
const bgColor = Color(0xFFF4F4EF);
const cardColor = Colors.white;
const successGreen = Color(0xFF27AE60);
const warningOrange = Color(0xFFE67E22);
const errorRed = Color(0xFFE74C3C);

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const MainScreen()),
    GoRoute(
        path: '/preview',
        builder: (_, state) => SessionPreviewScreen(
              mode: state.uri.queryParameters['mode'] ?? 'flashcard',
            )),
    GoRoute(path: '/flashcard', builder: (_, __) => const FlashcardScreen()),
    GoRoute(
        path: '/quick-review', builder: (_, __) => const QuickReviewScreen()),
    GoRoute(path: '/lookup', builder: (_, __) => const LookupScreen()),
    GoRoute(path: '/ai-chat', builder: (_, __) => const AIChatScreen()),
    GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class VocabAIApp extends StatelessWidget {
  const VocabAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vocab AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: enColor,
        scaffoldBackgroundColor: bgColor,
        cardColor: cardColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: enColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w800, color: primaryColor),
          headlineMedium: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: primaryColor),
          bodyLarge:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),
      routerConfig: _router,
    );
  }
}
