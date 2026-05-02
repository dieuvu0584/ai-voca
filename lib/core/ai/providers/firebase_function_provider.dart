import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../ai_service.dart';

/// AIService dùng Firebase HTTPS Function — gọi Claude bằng app key trong Secret Manager.
/// Dùng HTTP trực tiếp thay vì callable SDK để tránh phụ thuộc Firebase Auth / GMS.
class FirebaseFunctionProvider implements AIService {
  static const _functionUrl =
      'https://asia-southeast1-vocab-ai-2ff78.cloudfunctions.net/callClaude';
  static const _appSecret = 'vocabai-proxy-2024';

  @override
  Future<String?> complete({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 1000,
  }) async {
    try {
      // Lấy UID nếu đang đăng nhập (để rate limit chính xác hơn)
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-app-secret': _appSecret,
          if (uid != null) 'x-user-id': uid,
        },
        body: jsonEncode({
          'systemPrompt': systemPrompt,
          'messages': messages,
          'maxTokens': maxTokens,
          'isPremium': false,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['text'] as String?;
      } else if (response.statusCode == 429) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[FirebaseFunctionProvider] Rate limit: ${json['error']}');
        return null;
      } else {
        debugPrint('[FirebaseFunctionProvider] HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[FirebaseFunctionProvider] error: $e');
      return null;
    }
  }

  @override
  Future<bool> testConnection() async {
    final result = await complete(
      messages: [
        {'role': 'user', 'content': 'Reply "ok" only.'}
      ],
      systemPrompt: 'Reply with just "ok".',
      maxTokens: 10,
    );
    return result != null && result.isNotEmpty;
  }
}
