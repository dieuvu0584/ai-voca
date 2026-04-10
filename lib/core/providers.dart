import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/database.dart';
import 'tts/tts_service.dart';
import 'dictionary/dict_service.dart';
import 'notifications/notif_service.dart';
import '../data/languages.dart';

// Database
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final wordDaoProvider = Provider((ref) => ref.watch(databaseProvider).wordDao);
final progressDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).progressDao);

// TTS
final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

// Dictionary
final dictServiceProvider = Provider<DictService>(
    (ref) => DictService(ref.watch(wordDaoProvider)));

// Notifications
final notifServiceProvider = Provider<NotifService>((ref) => NotifService());

// Language state
class LanguageState {
  final Language primary;
  final Language? secondary;

  const LanguageState({required this.primary, this.secondary});

  LanguageState copyWith({Language? primary, Language? secondary, bool clearSecondary = false}) =>
      LanguageState(
        primary: primary ?? this.primary,
        secondary: clearSecondary ? null : (secondary ?? this.secondary),
      );
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier()
      : super(LanguageState(primary: findLanguage('en-US')));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryCode = prefs.getString('primary_lang') ?? 'en-US';
    final secondaryCode = prefs.getString('secondary_lang');
    state = LanguageState(
      primary: findLanguage(primaryCode),
      secondary: secondaryCode != null ? findLanguage(secondaryCode) : null,
    );
  }

  Future<void> setPrimary(Language lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primary_lang', lang.code);
    // Nếu secondary trùng primary mới → xóa secondary
    if (state.secondary?.code == lang.code) {
      await prefs.remove('secondary_lang');
      state = LanguageState(primary: lang);
    } else {
      state = state.copyWith(primary: lang);
    }
  }

  Future<void> setSecondary(Language? lang) async {
    final prefs = await SharedPreferences.getInstance();
    if (lang == null) {
      await prefs.remove('secondary_lang');
      state = state.copyWith(clearSecondary: true);
    } else {
      await prefs.setString('secondary_lang', lang.code);
      state = state.copyWith(secondary: lang);
    }
  }

  Future<void> swapPrimarySecondary() async {
    if (state.secondary == null) return;
    final oldPrimary = state.primary;
    final oldSecondary = state.secondary!;
    await setPrimary(oldSecondary);
    await setSecondary(oldPrimary);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>(
        (ref) => LanguageNotifier());

// Online status
final isOnlineProvider = StateProvider<bool>((ref) => true);
