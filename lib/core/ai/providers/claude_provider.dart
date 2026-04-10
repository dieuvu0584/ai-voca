import 'package:dio/dio.dart';
import '../ai_service.dart';

class ClaudeProvider implements AIService {
  final String apiKey;
  final String model;
  final Dio _dio;

  ClaudeProvider({required this.apiKey, String? model})
      : model = model ?? 'claude-sonnet-4-20250514',
        _dio = Dio(BaseOptions(
          baseUrl: 'https://api.anthropic.com',
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ));

  @override
  Future<String?> complete({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 1000,
  }) async {
    try {
      final response = await _dio.post('/v1/messages', data: {
        'model': model,
        'max_tokens': maxTokens,
        'system': systemPrompt,
        'messages': messages,
      });
      return response.data['content'][0]['text'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final result = await complete(
        messages: [
          {'role': 'user', 'content': 'Hi'}
        ],
        systemPrompt: 'Reply with "OK"',
        maxTokens: 10,
      );
      return result != null;
    } catch (_) {
      return false;
    }
  }
}
