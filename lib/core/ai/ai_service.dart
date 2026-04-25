import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_settings.dart';
import 'providers/claude_provider.dart';
import 'providers/openai_provider.dart';
import 'providers/gemini_provider.dart';
import 'providers/grok_provider.dart';
import 'providers/mistral_provider.dart';
import 'providers/openrouter_provider.dart';

enum AIMode { appDefault, userKey, none }

enum AIProvider { claude, openai, gemini, grok, mistral, openrouter }

abstract class AIService {
  Future<String?> complete({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 1000,
  });

  Future<bool> testConnection();
}

/// Factory tạo AIService dựa trên provider
AIService? createAIService({
  required AIProvider provider,
  required String apiKey,
  String? model,
}) {
  switch (provider) {
    case AIProvider.claude:
      return ClaudeProvider(apiKey: apiKey, model: model);
    case AIProvider.openai:
      return OpenAIProvider(apiKey: apiKey, model: model);
    case AIProvider.gemini:
      return GeminiProvider(apiKey: apiKey, model: model);
    case AIProvider.grok:
      return GrokProvider(apiKey: apiKey, model: model);
    case AIProvider.mistral:
      return MistralProvider(apiKey: apiKey, model: model);
    case AIProvider.openrouter:
      return OpenRouterProvider(apiKey: apiKey, model: model);
  }
}

/// Provider cho AIService hiện tại
final aiServiceProvider = Provider<AIService?>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  if (settings.mode == AIMode.none) return null;
  if (settings.apiKey == null || settings.apiKey!.isEmpty) return null;
  return createAIService(
    provider: settings.provider,
    apiKey: settings.apiKey!,
    model: settings.model,
  );
});
