import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../ai_service.dart';

/// AIService dùng Firebase Functions — gọi Claude bằng app key trong Secret Manager.
/// Không cần user tự nhập API key.
/// Tự động sign in ẩn danh nếu chưa đăng nhập để vẫn có UID cho rate limiting.
class FirebaseFunctionProvider implements AIService {
  static const _region = 'asia-southeast1';

  /// Đảm bảo có auth (Google hoặc anonymous) trước khi gọi function
  Future<bool> _ensureAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) return true;
      // Tự sign in ẩn danh
      await auth.signInAnonymously();
      return auth.currentUser != null;
    } catch (e) {
      debugPrint('[FirebaseFunctionProvider] signInAnonymously error: $e');
      return false;
    }
  }

  @override
  Future<String?> complete({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 1000,
  }) async {
    try {
      final authed = await _ensureAuth();
      if (!authed) {
        debugPrint('[FirebaseFunctionProvider] Không có auth, bỏ qua');
        return null;
      }

      final callable = FirebaseFunctions.instanceFor(region: _region)
          .httpsCallable('callClaude');

      final result = await callable.call({
        'systemPrompt': systemPrompt,
        'messages': messages,
        'maxTokens': maxTokens,
        'isPremium': false,
      });
      return result.data['text'] as String?;
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
      systemPrompt: 'You are a test assistant. Reply with just "ok".',
      maxTokens: 10,
    );
    return result != null && result.isNotEmpty;
  }
}
