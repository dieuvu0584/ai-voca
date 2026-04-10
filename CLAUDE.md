# CLAUDE.md
# File này được Claude Code tự động đọc khi làm việc trong project

## Project: Vocab AI — Flutter multilingual vocabulary app

## Ngôn ngữ giao tiếp
Luôn trả lời bằng **tiếng Việt**. Code comments và code strings UI bằng tiếng Việt. Tên biến/function bằng tiếng Anh.

## Stack
- Flutter 3.x + Dart
- Riverpod (state management)
- Drift + SQLite (local database)
- Dio (HTTP)
- flutter_tts (TTS), just_audio (MP3)
- go_router (navigation)
- flutter_secure_storage (API keys)

## Quy tắc code

### State Management
- Dùng Riverpod providers, không dùng setState trực tiếp ở widget phức tạp
- Mỗi feature có riêng provider file trong `lib/features/<feature>/`
- Global providers trong `lib/core/`

### Database (Drift)
- Schema định nghĩa trong `lib/core/db/tables.dart`
- DAO riêng cho mỗi entity
- Mọi DB operation phải async

### AI Layer
- Không bao giờ gọi AI trực tiếp từ widget
- Luôn qua `AIService` abstraction
- Check `AIMode` trước mọi AI call
- Handle lỗi gracefully — app không crash khi AI fail

### Security
- API keys: chỉ dùng `flutter_secure_storage`
- App default key: `const String.fromEnvironment('APP_AI_KEY')`
- Không log API keys

### Offline First
- Mọi core feature phải hoạt động offline
- Sequence: SQLite cache → API → local fallback

## Primary vs Secondary Language Logic

```dart
// CHỈ Primary language có:
// - Rating buttons (Quên/Khó/Nhớ)  
// - Progress tracking
// - SM-2 scheduling

// Secondary language:
// - Hiện answer luôn (không cần lật)
// - Chỉ có nút 🔊 phát âm
// - Rotate theo nhịp primary (không track riêng)
// - Không có rating
```

## Session Preview — bắt buộc trước mỗi phiên

```dart
// Từ flow khi user vào Flashcard hoặc Quick Review:
// 1. Check remaining words > 0
// 2. Mở SessionPreviewScreen
// 3. User đánh dấu "Biết rồi" các từ đã biết
// 4. confirmStart() → cập nhật DB (status = 'skipped')
// 5. Mới vào học
// Exception: user nhấn "Bỏ qua →" → skip preview
```

## Folder structure chuẩn
```
lib/
  core/        # services, db, ai, tts, notifications
  data/        # static data (languages, built-in vocab)
  features/    # màn hình, mỗi feature 1 folder
  widgets/     # shared widgets
```

## Khi gặp lỗi build
1. Chạy `flutter pub get` trước
2. Drift: chạy `dart run build_runner build --delete-conflicting-outputs`
3. Riverpod: chạy `dart run build_runner watch`

## Test checklist trước commit
- [ ] Offline mode hoạt động (tắt mạng)
- [ ] AI mode = none → không crash, UI ẩn đúng
- [ ] Secondary language không có rating buttons
- [ ] Session preview hiện trước flashcard
- [ ] API key không log ra console
