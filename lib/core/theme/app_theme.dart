import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Custom color extension — dùng trong toàn app ──────────────
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color primary;    // màu nút chính, highlight
  final Color secondary;  // màu ngôn ngữ phụ, secondary elements
  final Color background; // nền scaffold

  const AppColorScheme({
    required this.primary,
    required this.secondary,
    required this.background,
  });

  @override
  AppColorScheme copyWith({Color? primary, Color? secondary, Color? background}) =>
      AppColorScheme(
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        background: background ?? this.background,
      );

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other == null) return this;
    return AppColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
    );
  }
}

// Helper truy cập màu từ context
AppColorScheme appColors(BuildContext context) =>
    Theme.of(context).extension<AppColorScheme>() ??
    const AppColorScheme(
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF0EA5E9),
      background: Color(0xFFEFF9FF),
    );

// ── Theme presets ─────────────────────────────────────────────
class AppThemePreset {
  final String id;
  final String label;
  final Color swatch;   // màu hiển thị trong picker
  final Color seed;     // seed cho Material 3 ColorScheme
  final AppColorScheme colors;

  const AppThemePreset({
    required this.id,
    required this.label,
    required this.swatch,
    required this.seed,
    required this.colors,
  });
}

const kAppThemes = <AppThemePreset>[
  // Violet — violet-800 / violet-700 (AI logo purple)
  AppThemePreset(
    id: 'indigo',
    label: 'Violet',
    swatch: Color(0xFF5B21B6),
    seed:   Color(0xFF5B21B6),
    colors: AppColorScheme(
      primary:    Color(0xFF5B21B6),   // violet-800
      secondary:  Color(0xFF6D28D9),   // violet-700
      background: Color(0xFFF5F3FF),
    ),
  ),
  // Teal — teal-700 / teal-600
  AppThemePreset(
    id: 'teal',
    label: 'Teal',
    swatch: Color(0xFF0F766E),
    seed:   Color(0xFF0F766E),
    colors: AppColorScheme(
      primary:    Color(0xFF0F766E),   // teal-700
      secondary:  Color(0xFF0D9488),   // teal-600
      background: Color(0xFFEFFEFD),
    ),
  ),
  // Dark Red — red-800 / red-700
  AppThemePreset(
    id: 'rose',
    label: 'Dark Red',
    swatch: Color(0xFF991B1B),
    seed:   Color(0xFF991B1B),
    colors: AppColorScheme(
      primary:    Color(0xFF991B1B),   // red-800
      secondary:  Color(0xFFB91C1C),   // red-700
      background: Color(0xFFFFF5F5),
    ),
  ),
  // Sky — sky-600 / sky-500
  AppThemePreset(
    id: 'sky',
    label: 'Sky Blue',
    swatch: Color(0xFF0284C7),
    seed:   Color(0xFF0284C7),
    colors: AppColorScheme(
      primary:    Color(0xFF0284C7),   // sky-600
      secondary:  Color(0xFF0EA5E9),   // sky-500
      background: Color(0xFFEFF9FF),
    ),
  ),
  // Amber — amber-600 / amber-500
  AppThemePreset(
    id: 'amber',
    label: 'Amber',
    swatch: Color(0xFFD97706),
    seed:   Color(0xFFD97706),
    colors: AppColorScheme(
      primary:    Color(0xFFD97706),   // amber-600
      secondary:  Color(0xFFF59E0B),   // amber-500
      background: Color(0xFFFFFAE6),
    ),
  ),
  // Emerald — emerald-700 / emerald-600
  AppThemePreset(
    id: 'emerald',
    label: 'Emerald',
    swatch: Color(0xFF047857),
    seed:   Color(0xFF047857),
    colors: AppColorScheme(
      primary:    Color(0xFF047857),   // emerald-700
      secondary:  Color(0xFF059669),   // emerald-600
      background: Color(0xFFEEFDF5),
    ),
  ),
  // Slate — slate-700 / slate-600
  AppThemePreset(
    id: 'slate',
    label: 'Slate',
    swatch: Color(0xFF334155),
    seed:   Color(0xFF334155),
    colors: AppColorScheme(
      primary:    Color(0xFF334155),   // slate-700
      secondary:  Color(0xFF475569),   // slate-600
      background: Color(0xFFF8FAFC),
    ),
  ),
];

AppThemePreset findAppTheme(String id) =>
    kAppThemes.firstWhere((t) => t.id == id, orElse: () => kAppThemes.first);

// ── Provider ──────────────────────────────────────────────────
const _kThemePrefKey = 'app_theme_id';

class AppThemeNotifier extends StateNotifier<String> {
  AppThemeNotifier() : super('sky');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemePrefKey) ?? 'sky';
    if (state != saved) state = saved;
  }

  Future<void> setTheme(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemePrefKey, id);
  }
}

final appThemeProvider =
    StateNotifierProvider<AppThemeNotifier, String>((_) => AppThemeNotifier());
