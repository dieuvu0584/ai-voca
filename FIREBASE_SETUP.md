# Firebase Setup Guide — VocabAI

Hướng dẫn cấu hình Firebase để kích hoạt **Cloud Backup** và **AI Proxy** (Import feature).

---

## Yêu cầu

- Node.js 20+
- Flutter SDK
- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

---

## Bước 1 — Tạo Firebase Project

1. Vào [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → đặt tên (VD: `vocabai-prod`)
3. Bật **Google Analytics** (tuỳ chọn)
4. Chờ project được tạo

---

## Bước 2 — Kích hoạt các Firebase Services

Trong Firebase Console:

### Authentication
1. **Build → Authentication → Get started**
2. **Sign-in method → Google → Enable**
3. Điền **Project public-facing name**: `VocabAI`
4. Chọn **Support email**
5. Save

### Firestore Database
1. **Build → Firestore Database → Create database**
2. Chọn **Start in production mode**
3. Chọn region: **asia-southeast1 (Singapore)**
4. Enable

### Functions
1. **Build → Functions → Get started**
2. Cần **Blaze plan** (pay-as-you-go) — nhưng có free tier rộng
3. Upgrade billing nếu cần

---

## Bước 3 — Lấy SHA-1 cho Google Sign-In (Android)

```bash
# Debug keystore (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (production)
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Copy SHA-1 → Firebase Console → **Project settings → Your apps → Add fingerprint**

---

## Bước 4 — Kết nối Flutter app với Firebase

```bash
cd D:\Projects\vocab_ai

# Login Firebase
firebase login

# Configure FlutterFire (sẽ tự tạo google-services.json và firebase_options.dart)
flutterfire configure --project=<your-firebase-project-id>
```

Khi chạy lệnh trên:
- Chọn **Android** và **iOS**
- File `lib/firebase_options.dart` sẽ được ghi đè bằng config thật
- File `android/app/google-services.json` sẽ được tạo tự động

---

## Bước 5 — Deploy Firebase Functions

```bash
# Cài dependencies
cd functions
npm install

# Lưu Claude API key vào Secret Manager
firebase functions:secrets:set CLAUDE_API_KEY
# Paste Claude API key khi được hỏi

# Deploy
firebase deploy --only functions
```

Verify tại: Firebase Console → **Functions** → xem `callClaude` đã xuất hiện

---

## Bước 6 — Deploy Firestore Rules

```bash
cd D:\Projects\vocab_ai
firebase deploy --only firestore:rules
```

---

## Bước 7 — Test

```bash
# Build và chạy app
flutter pub get
flutter run

# Vào Settings → Backup & Sync → Đăng nhập với Google
# Thử Sao lưu ngay → kiểm tra Firestore Console
```

---

## Cấu trúc Firestore sau khi setup

```
users/
  {uid}/
    (document) → primaryLang, lastSync, wordCount
    words/
      {docId} → word, langCode, definition, status...
    progress/
      {docId} → word, langCode, status, interval, easeFactor...

usage/
  {uid}/
    daily/
      {YYYY-MM-DD} → count, lastUsed
```

---

## Chi phí ước tính (Firestore + Functions)

| Scale | Chi phí/tháng |
|-------|---------------|
| < 2,000 users | **$0** (free tier) |
| 10,000 users | ~$5–15 |
| 100,000 users | ~$50–150 |

Claude API (riêng):
| Scale | Chi phí/tháng |
|-------|---------------|
| 1,000 users × 2 imports/ngày | ~$54 |
| 10,000 users × 2 imports/ngày | ~$540 |

---

## Troubleshooting

**Lỗi `google-services.json not found`**
→ Chạy lại `flutterfire configure`

**Lỗi SHA-1 mismatch khi Google Sign-In**
→ Thêm SHA-1 vào Firebase Console (xem Bước 3)

**Functions deploy lỗi `Billing account not found`**
→ Upgrade Firebase project lên Blaze plan tại console.firebase.google.com

**App crash với `[Firebase] Chưa cấu hình`**
→ Bình thường nếu chưa chạy `flutterfire configure`. App vẫn chạy, chỉ tắt cloud sync.
