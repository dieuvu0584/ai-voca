import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';

class AISettings {
  final AIMode mode;
  final AIProvider provider;
  final String? apiKey;
  final String? model;
  /// Thông báo chờ hiển thị (auto-disable notification)
  final String? pendingNotification;

  const AISettings({
    this.mode = AIMode.none,
    this.provider = AIProvider.claude,
    this.apiKey,
    this.model,
    this.pendingNotification,
  });

  AISettings copyWith({
    AIMode? mode,
    AIProvider? provider,
    String? apiKey,
    String? model,
    bool clearModel = false,
    String? pendingNotification,
    bool clearNotification = false,
  }) =>
      AISettings(
        mode: mode ?? this.mode,
        provider: provider ?? this.provider,
        apiKey: apiKey ?? this.apiKey,
        model: clearModel ? null : (model ?? this.model),
        pendingNotification: clearNotification
            ? null
            : (pendingNotification ?? this.pendingNotification),
      );
}

class AISettingsNotifier extends StateNotifier<AISettings> {
  final FlutterSecureStorage _secureStorage;
  int _consecutiveErrors = 0;
  static const int _kAutoDisableThreshold = 3;

  AISettingsNotifier(this._secureStorage)
      : super(const AISettings(mode: AIMode.appDefault));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Mặc định: appDefault (dùng AI của app qua Firebase)
    final modeIndex = prefs.getInt('ai_mode') ?? AIMode.appDefault.index;
    final providerIndex = prefs.getInt('ai_provider') ?? 0;
    final model = prefs.getString('ai_model');

    final provider = AIProvider.values[providerIndex.clamp(0, AIProvider.values.length - 1)];
    final apiKey = await _secureStorage.read(key: 'ai_api_key_${provider.name}');
    var mode = AIMode.values[modeIndex.clamp(0, AIMode.values.length - 1)];

    // Migration: nếu mode = none mà chưa có API key riêng → reset về appDefault
    // (xảy ra khi code cũ đã lưu none vào prefs trước khi có Firebase proxy)
    if (mode == AIMode.none && (apiKey == null || apiKey.isEmpty)) {
      mode = AIMode.appDefault;
      await prefs.setInt('ai_mode', AIMode.appDefault.index);
    }

    state = AISettings(
      mode: mode,
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
    await prefs.remove('ai_model'); // reset model khi đổi provider
    final apiKey = await _secureStorage.read(key: 'ai_api_key_${provider.name}');
    state = state.copyWith(provider: provider, apiKey: apiKey, clearModel: true);
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

  /// Gọi khi AI call thành công — reset bộ đếm lỗi
  void reportAISuccess() {
    _consecutiveErrors = 0;
  }

  /// Gọi khi AI call thất bại (lỗi / timeout)
  /// Tự động disable AI sau [_kAutoDisableThreshold] lần liên tiếp
  Future<void> reportAIError(String reason) async {
    if (state.mode == AIMode.none) return;
    _consecutiveErrors++;
    if (_consecutiveErrors >= _kAutoDisableThreshold) {
      _consecutiveErrors = 0;
      await setMode(AIMode.none);
      state = state.copyWith(
        pendingNotification: 'AI bị tắt tự động: $reason',
      );
    }
  }

  /// Xóa thông báo sau khi đã hiển thị
  void clearNotification() {
    state = state.copyWith(clearNotification: true);
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
  AIProvider.gemini: [
    'gemini-2.0-flash',       // v1beta — ổn định, nhanh
    'gemini-2.0-flash-lite',  // v1beta — nhẹ hơn
    'gemini-1.5-pro',         // v1 — mạnh hơn
    'gemini-1.5-flash',       // v1 — cân bằng
    'gemini-1.5-flash-8b',    // v1 — nhẹ nhất
  ],
  AIProvider.grok: ['grok-3', 'grok-3-mini', 'grok-2'],
  AIProvider.mistral: ['mistral-large-latest', 'mistral-small-latest', 'open-mistral-7b'],
  AIProvider.openrouter: [
    'meta-llama/llama-3.3-70b-instruct:free',  // miễn phí
    'deepseek/deepseek-chat-v3-0324:free',      // miễn phí
    'google/gemini-2.0-flash-exp:free',         // miễn phí
    'anthropic/claude-sonnet-4-5',
    'openai/gpt-4o',
    'openai/gpt-4o-mini',
    'google/gemini-2.0-flash',
    'deepseek/deepseek-chat',
    'meta-llama/llama-3.3-70b-instruct',
    'mistralai/mistral-large',
  ],
};

/// Tên hiển thị
const Map<AIProvider, String> kAIProviderNames = {
  AIProvider.claude: 'Claude (Anthropic)',
  AIProvider.openai: 'ChatGPT (OpenAI)',
  AIProvider.gemini: 'Gemini (Google)',
  AIProvider.grok: 'Grok (xAI)',
  AIProvider.mistral: 'Mistral',
  AIProvider.openrouter: 'OpenRouter',
};

/// Icon theo provider
const Map<AIProvider, IconData> kAIProviderIcons = {
  AIProvider.claude:     Icons.auto_awesome_rounded,   // sparkles — Claude
  AIProvider.openai:     Icons.smart_toy_rounded,       // robot — ChatGPT
  AIProvider.gemini:     Icons.auto_fix_high_rounded,   // wand — Gemini
  AIProvider.grok:       Icons.bolt_rounded,            // bolt — Grok
  AIProvider.mistral:    Icons.air_rounded,             // wind — Mistral
  AIProvider.openrouter: Icons.hub_rounded,             // hub — OpenRouter
};

/// Màu accent theo provider
const Map<AIProvider, Color> kAIProviderColors = {
  AIProvider.claude:     Color(0xFF7C3AED), // tím Anthropic
  AIProvider.openai:     Color(0xFF10A37F), // xanh lá OpenAI
  AIProvider.gemini:     Color(0xFF1A73E8), // xanh dương Google
  AIProvider.grok:       Color(0xFFFF6B00), // cam xAI
  AIProvider.mistral:    Color(0xFF00897B), // teal Mistral
  AIProvider.openrouter: Color(0xFF6B7280), // xám trung tính
};

/// Helper lấy icon của provider hiện tại
IconData aiProviderIcon(AIProvider provider) =>
    kAIProviderIcons[provider] ?? Icons.auto_awesome_rounded;

/// Helper lấy màu của provider hiện tại
Color aiProviderColor(AIProvider provider) =>
    kAIProviderColors[provider] ?? const Color(0xFF7C3AED);
