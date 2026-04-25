import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  // v1 stable cho model 1.5-x (không hỗ trợ systemInstruction)
  // v1beta cho model 2.0+ (hỗ trợ systemInstruction)
  String get _apiVersion =>
      model.startsWith('gemini-1.') ? 'v1' : 'v1beta';

  @override
  Future<String?> complete({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 1000,
  }) async {
    try {
      // v1 (model 1.5-x) không hỗ trợ systemInstruction → ghép vào user message đầu
      // v1beta (model 2.0+) hỗ trợ systemInstruction bình thường
      final useSystemInstruction = _apiVersion == 'v1beta';

      List<Map<String, dynamic>> contents;
      if (useSystemInstruction) {
        contents = messages.map((m) => {
              'role': m['role'] == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m['content']}
              ],
            }).toList();
      } else {
        // Ghép system prompt vào message đầu tiên
        final messagesWithSystem = List<Map<String, String>>.from(messages);
        if (messagesWithSystem.isNotEmpty &&
            messagesWithSystem.first['role'] == 'user') {
          messagesWithSystem[0] = {
            'role': 'user',
            'content': '$systemPrompt\n\n${messagesWithSystem.first['content']}',
          };
        }
        contents = messagesWithSystem.map((m) => {
              'role': m['role'] == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m['content']}
              ],
            }).toList();
      }

      final body = <String, dynamic>{
        'contents': contents,
        'generationConfig': {'maxOutputTokens': maxTokens},
      };
      if (useSystemInstruction) {
        body['systemInstruction'] = {
          'parts': [
            {'text': systemPrompt}
          ]
        };
      }

      final response = await _dio.post(
        '/$_apiVersion/models/$model:generateContent?key=$apiKey',
        data: body,
      );

      // Parse response an toàn
      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('[Gemini] Empty candidates in response: ${response.data}');
        return null;
      }
      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        debugPrint('[Gemini] Empty parts in response: ${candidates[0]}');
        return null;
      }
      return parts[0]['text'] as String?;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      debugPrint('[Gemini] HTTP $status — $body');
      // Ném lại lỗi có status để testConnection xử lý riêng
      throw _GeminiApiException(status ?? 0, body?.toString() ?? '');
    } catch (e) {
      if (e is _GeminiApiException) rethrow;
      debugPrint('[Gemini] Unexpected error: $e');
      return null;
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final result = await complete(
        messages: [{'role': 'user', 'content': 'Hi'}],
        systemPrompt: 'Reply with OK',
        maxTokens: 10,
      );
      return result != null && result.isNotEmpty;
    } on _GeminiApiException catch (e) {
      if (e.statusCode == 429) {
        // 429 = quota exceeded → API key hợp lệ nhưng hết quota
        debugPrint('[Gemini] Quota exceeded — API key is valid');
        return true; // key đúng, chỉ hết quota
      }
      debugPrint('[Gemini] testConnection HTTP ${e.statusCode}: ${e.body}');
      return false;
    } catch (e) {
      debugPrint('[Gemini] testConnection error: $e');
      return false;
    }
  }
}

class _GeminiApiException implements Exception {
  final int statusCode;
  final String body;
  const _GeminiApiException(this.statusCode, this.body);
}
