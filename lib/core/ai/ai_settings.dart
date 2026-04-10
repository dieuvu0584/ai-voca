import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';

class AISettings {
  final AIMode mode;
  final AIProvider provider;
  final String? apiKey;
  final String? model;

  const AISettings({
    this.mode = AIMode.none,
    this.provider = AIProvider.claude,
    this.apiKey,
    this.model,
  });

  AISettings copyWith({
    AIMode? mode,
    AIProvider? provider,
    String? apiKey,
    String? model,
  }) =>
      AISettings(
        mode: mode ?? this.mode,
        provider: provider ?? this.provider,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
      );
}

class AISettingsNotifier extends StateNotifier<AISettings> {
  final FlutterSecureStorage _secureStorage;

  AISettingsNotifier(this._secureStorage) : super(const AISettings());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('ai_mode') ?? 2; // default none
    final providerIndex = prefs.getInt('ai_provider') ?? 0;
    final model = prefs.getString('ai_model');

    final provider = AIProvider.values[providerIndex.clamp(0, AIProvider.values.length - 1)];
    final apiKey = await _secureStorage.read(key: 'ai_api_key_${provider.name}');

    state = AISettings(
      mode: AIMode.values[modeIndex.clamp(0, AIMode.values.length - 1)],
      provider: provider,
      apiKey: apiKey,
      model: model,
    );
  }

  Future<void> setMode(AIMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_mode', mode.index);
    state = state.copyWith(mode: mode);
  }

  Future<void> setProvider(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_provider', provider.index);
    final apiKey = await _secureStorage.read(key: 'ai_api_key_${provider.name}');
    state = state.copyWith(provider: provider, apiKey: apiKey);
  }

  Future<void> setApiKey(String key) async {
    await _secureStorage.write(
        key: 'ai_api_key_${state.provider.name}', value: key);
    state = state.copyWith(apiKey: key);
  }

  Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_model', model);
    state = state.copyWith(model: model);
  }
}

final aiSettingsProvider =
    StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  return AISettingsNotifier(const FlutterSecureStorage());
});

/// Map provider → danh sách model
const Map<AIProvider, List<String>> kAIModels = {
  AIProvider.claude: ['claude-sonnet-4-20250514', 'claude-haiku-4-5-20251001', 'claude-opus-4-5'],
  AIProvider.openai: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'],
  AIProvider.gemini: ['gemini-2.0-flash', 'gemini-1.5-pro', 'gemini-1.5-flash'],
  AIProvider.grok: ['grok-3', 'grok-3-mini', 'grok-2'],
  AIProvider.mistral: ['mistral-large-latest', 'mistral-small-latest', 'open-mistral-7b'],
};

/// Tên hiển thị
const Map<AIProvider, String> kAIProviderNames = {
  AIProvider.claude: 'Claude (Anthropic)',
  AIProvider.openai: 'ChatGPT (OpenAI)',
  AIProvider.gemini: 'Gemini (Google)',
  AIProvider.grok: 'Grok (xAI)',
  AIProvider.mistral: 'Mistral',
};
