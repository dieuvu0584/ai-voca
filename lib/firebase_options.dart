// ⚠️  PLACEHOLDER — Chạy lệnh sau để tạo file thật:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure --project=<your-firebase-project-id>
//
// File này sẽ bị ghi đè bởi flutterfire configure.
// Xem hướng dẫn chi tiết trong FIREBASE_SETUP.md
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions không hỗ trợ platform này. '
          'Chạy flutterfire configure để tạo config đúng.',
        );
    }
  }

  // ── PLACEHOLDER VALUES — Thay bằng giá trị thật từ flutterfire configure ──

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER_RUN_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-firebase-project-id',
    storageBucket: 'your-firebase-project-id.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER_RUN_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-firebase-project-id',
    storageBucket: 'your-firebase-project-id.appspot.com',
    iosBundleId: 'com.vocabai.learnwords',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER_RUN_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-firebase-project-id',
    storageBucket: 'your-firebase-project-id.appspot.com',
    authDomain: 'your-firebase-project-id.firebaseapp.com',
  );
}
