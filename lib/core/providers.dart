import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai/ai_service.dart';
import 'auth/auth_service.dart';
import 'backup/backup_service.dart';
import 'db/database.dart';
import 'import_vocab/import_service.dart';
import 'tts/tts_service.dart';
import 'dictionary/dict_service.dart';
import 'notifications/notif_service.dart';
import 'vocab_sync/vocab_sync_service.dart';
import '../data/languages.dart';

// ── Firebase ─────────────────────────────────────────────────

/// true nếu Firebase.initializeApp() thành công
final firebaseReadyProvider = StateProvider<bool>((ref) => false);

// Auth
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return Stream.value(null);
  return ref.watch(authServiceProvider).authStateChanges;
});

// Backup
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

// Import
final importServiceProvider = Provider<ImportService>(
  (ref) => ImportService(
    db: ref.watch(databaseProvider),
    userAiService: ref.watch(aiServiceProvider),
    firebaseReady: ref.watch(firebaseReadyProvider),
  ),
);

// ── Database ─────────────────────────────────────────────────

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

}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>(
        (ref) => LanguageNotifier());

// Definition language (ngôn ngữ hiển thị nghĩa của từ)
class DefLangNotifier extends StateNotifier<String> {
  final String _prefKey;

  DefLangNotifier(this._prefKey) : super('en-US');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_prefKey) ?? 'en-US';
  }

  Future<void> setLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    state = code;
  }
}

/// Ngôn ngữ dịch nghĩa — dùng chung cho cả ngôn ngữ chính lẫn phụ
final defLangPrimaryProvider =
    StateNotifierProvider<DefLangNotifier, String>(
        (ref) => DefLangNotifier('def_lang_primary'));

// GUI language
class GuiLangNotifier extends StateNotifier<String> {
  GuiLangNotifier() : super('en-US');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('gui_lang') ?? 'en-US';
  }

  Future<void> setLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gui_lang', code);
    state = code;
  }
}

final guiLangProvider =
    StateNotifierProvider<GuiLangNotifier, String>(
        (ref) => GuiLangNotifier());

// Online status
final isOnlineProvider = StateProvider<bool>((ref) => true);

// Trigger reload stats trên homepage (increment để notify)
final statsRefreshProvider = StateProvider<int>((ref) => 0);

// Vocab sync
final vocabSyncProvider = Provider<VocabSyncService>(
    (ref) => VocabSyncService(ref.watch(databaseProvider)));
