import 'package:dio/dio.dart';
import '../ai_service.dart';

class MistralProvider implements AIService {
  final String apiKey;
  final String model;
  final Dio _dio;

  MistralProvider({required this.apiKey, String? model})
      : model = model ?? 'mistral-small-latest',
        _dio = Dio(BaseOptions(
          baseUrl: 'https://api.mistral.ai',
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  @override
  Future<String?> complete({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 1000,
  }) async {
    try {
      final allMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ];
      final response = await _dio.post('/v1/chat/completions', data: {
        'model': model,
        'messages': allMessages,
        'max_tokens': maxTokens,
      });
      return response.data['choices'][0]['message']['content'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final result = await complete(
        messages: [{'role': 'user', 'content': 'Hi'}],
        systemPrompt: 'Reply with "OK"',
        maxTokens: 10,
      );
      return result != null;
    } catch (_) {
      return false;
    }
  }
}
