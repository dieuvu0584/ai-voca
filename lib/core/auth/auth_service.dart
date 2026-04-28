import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// AuthService — quản lý đăng nhập Google + Firebase Auth
/// Dùng cho tính năng Backup & Sync
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ── Getters ──────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isSignedIn => _auth.currentUser != null;

  String? get uid => _auth.currentUser?.uid;

  String? get displayName => _auth.currentUser?.displayName;

  String? get email => _auth.currentUser?.email;

  String? get photoUrl => _auth.currentUser?.photoURL;

  // ── Sign In ────────────────────────────────────────────────��─

  /// Đăng nhập với Google — trả về UserCredential hoặc null nếu user huỷ
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User huỷ

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('[AuthService] signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Đăng xuất khỏi cả Firebase và Google
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
