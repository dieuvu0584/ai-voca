import 'package:dio/dio.dart';
import '../ai_service.dart';

class GeminiProvider implements AIService {
  final String apiKey;
  final String model;
  final Dio _dio;

  GeminiProvider({required this.apiKey, String? model})
      : model = model ?? 'gemini-2.0-flash',
        _dio = Dio(BaseOptions(
          baseUrl: 'https://generativelanguage.googleapis.com',
          headers: {'Content-Type': 'application/json'},
        ));

  @override
  Future<String?> complete({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 1000,
  }) async {
    try {
      final contents = messages.map((m) => {
            'role': m['role'] == 'assistant' ? 'model' : 'user',
            'parts': [
              {'text': m['content']}
            ],
          }).toList();

      final response = await _dio.post(
        '/v1beta/models/$model:generateContent?key=$apiKey',
        data: {
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': contents,
          'generationConfig': {'maxOutputTokens': maxTokens},
        },
      );
      return response.data['candidates'][0]['content']['parts'][0]['text']
          as String?;
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
