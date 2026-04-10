# VOCAB AI — Flutter App Build Prompt
# Dùng với Claude Code: claude < PROMPT.md

---

## MỤC TIÊU

Xây dựng ứng dụng di động **Vocab AI** bằng Flutter — ứng dụng học từ vựng đa ngôn ngữ thông minh, hỗ trợ học cùng lúc tối đa 2 ngôn ngữ (1 chính + 1 phụ), tích hợp AI, phát âm TTS, tra từ điển online/offline.

---

## TECH STACK

| Thành phần | Lựa chọn |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State management | Riverpod |
| Local DB | SQLite (drift package) |
| HTTP | Dio |
| TTS | flutter_tts |
| Notifications | flutter_local_notifications |
| Secure storage | flutter_secure_storage (lưu API keys) |
| Home widget | home_widget package |
| Navigation | go_router |
| Backend AI proxy | Python FastAPI (optional — nếu dùng App Default AI) |

---

## CẤU TRÚC DỰ ÁN

```
lib/
├── main.dart
├── app.dart                  # GoRouter, theme, providers
├── core/
│   ├── db/
│   │   ├── database.dart     # Drift database setup
│   │   ├── word_dao.dart     # Word CRUD
│   │   └── progress_dao.dart # Learning progress CRUD
│   ├── ai/
│   │   ├── ai_service.dart   # Abstract AI caller
│   │   ├── providers/
│   │   │   ├── claude_provider.dart
│   │   │   ├── openai_provider.dart
│   │   │   ├── gemini_provider.dart
│   │   │   ├── grok_provider.dart
│   │   │   └── mistral_provider.dart
│   │   └── ai_settings.dart  # Mode enum + persisted config
│   ├── dictionary/
│   │   ├── dict_service.dart     # Unified lookup (API → cache → local)
│   │   └── free_dict_api.dart    # dictionaryapi.dev integration
│   ├── tts/
│   │   └── tts_service.dart      # flutter_tts wrapper, voice picker
│   └── notifications/
│       └── notif_service.dart    # Daily reminder scheduling
├── data/
│   ├── languages.dart        # 20 language definitions
│   └── vocab_data.dart       # Built-in offline word lists
├── features/
│   ├── session_preview/
│   │   └── session_preview_screen.dart
│   ├── flashcard/
│   │   ├── flashcard_screen.dart
│   │   ├── flashcard_card.dart
│   │   └── secondary_strip.dart
│   ├── quick_review/
│   │   └── quick_review_screen.dart
│   ├── lookup/
│   │   └── lookup_screen.dart
│   ├── ai_chat/
│   │   └── ai_chat_screen.dart
│   ├── progress/
│   │   └── progress_screen.dart
│   └── settings/
│       ├── settings_screen.dart
│       ├── ai_settings_screen.dart
│       └── notification_settings.dart
└── widgets/
    ├── lang_slot_bar.dart
    ├── lang_picker_sheet.dart
    ├── ai_pill.dart
    └── net_badge.dart
```

---

## DATABASE SCHEMA (Drift / SQLite)

```dart
// words table — cached from API or built-in
class Words extends Table {
  TextColumn get word       => text()();          // PK
  TextColumn get langCode   => text()();          // e.g. 'en-US'
  TextColumn get phonetic   => text().nullable()();
  TextColumn get phoneticUK => text().nullable()();
  TextColumn get audioUs    => text().nullable()();
  TextColumn get audioUk    => text().nullable()();
  TextColumn get partOfSpeech => text().nullable()();
  TextColumn get definition => text().nullable()();
  TextColumn get example    => text().nullable()();
  TextColumn get romanization => text().nullable()(); // for CJK/Korean
  TextColumn get source     => text().withDefault(const Constant('local'))(); // 'api'|'cache'|'local'
  IntColumn  get cachedAt   => integer().nullable()();
  @override Set<Column> get primaryKey => {word, langCode};
}

// progress table — per user per language
class WordProgress extends Table {
  TextColumn get word       => text()();
  TextColumn get langCode   => text()();
  TextColumn get status     => text().withDefault(const Constant('new'))();
  // status: 'new' | 'learning' | 'review' | 'known' | 'skipped'
  IntColumn  get reviewCount  => integer().withDefault(const Constant(0))();
  IntColumn  get correctCount => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor   => real().withDefault(const Constant(2.5))(); // SM-2
  IntColumn  get interval     => integer().withDefault(const Constant(1))(); // days
  IntColumn  get nextReview   => integer().nullable()(); // unix timestamp
  IntColumn  get lastSeen     => integer().nullable()();
  @override Set<Column> get primaryKey => {word, langCode};
}

// sessions table
class Sessions extends Table {
  IntColumn  get id         => integer().autoIncrement()();
  TextColumn get langCode   => text()();
  IntColumn  get startedAt  => integer()();
  IntColumn  get endedAt    => integer().nullable()();
  IntColumn  get wordsStudied => integer().withDefault(const Constant(0))();
  IntColumn  get wordsKnown   => integer().withDefault(const Constant(0))();
}
```

---

## NGÔN NGỮ HỖ TRỢ

```dart
class Language {
  final String code;    // 'en-US', 'ko-KR', ...
  final String name;    // 'English US'
  final String native;  // 'English'
  final String flag;    // '🇺🇸'
  final String ttsLang; // 'en-US'
  final bool hasDictAPI; // Free Dictionary API (chỉ English)
}

const List<Language> LANGUAGES = [
  Language(code:'en-US', name:'English US',   native:'English',    flag:'🇺🇸', ttsLang:'en-US', hasDictAPI:true),
  Language(code:'en-GB', name:'English UK',   native:'English',    flag:'🇬🇧', ttsLang:'en-GB', hasDictAPI:true),
  Language(code:'ko-KR', name:'Korean',       native:'한국어',      flag:'🇰🇷', ttsLang:'ko-KR', hasDictAPI:false),
  Language(code:'ja-JP', name:'Japanese',     native:'日本語',      flag:'🇯🇵', ttsLang:'ja-JP', hasDictAPI:false),
  Language(code:'zh-CN', name:'Chinese CN',   native:'普通话',      flag:'🇨🇳', ttsLang:'zh-CN', hasDictAPI:false),
  Language(code:'zh-TW', name:'Chinese TW',   native:'繁體中文',    flag:'🇹🇼', ttsLang:'zh-TW', hasDictAPI:false),
  Language(code:'fr-FR', name:'French',       native:'Français',   flag:'🇫🇷', ttsLang:'fr-FR', hasDictAPI:false),
  Language(code:'de-DE', name:'German',       native:'Deutsch',    flag:'🇩🇪', ttsLang:'de-DE', hasDictAPI:false),
  Language(code:'es-ES', name:'Spanish',      native:'Español',    flag:'🇪🇸', ttsLang:'es-ES', hasDictAPI:false),
  Language(code:'it-IT', name:'Italian',      native:'Italiano',   flag:'🇮🇹', ttsLang:'it-IT', hasDictAPI:false),
  Language(code:'pt-BR', name:'Portuguese',   native:'Português',  flag:'🇧🇷', ttsLang:'pt-BR', hasDictAPI:false),
  Language(code:'ru-RU', name:'Russian',      native:'Русский',    flag:'🇷🇺', ttsLang:'ru-RU', hasDictAPI:false),
  Language(code:'th-TH', name:'Thai',         native:'ภาษาไทย',   flag:'🇹🇭', ttsLang:'th-TH', hasDictAPI:false),
  Language(code:'vi-VN', name:'Vietnamese',   native:'Tiếng Việt', flag:'🇻🇳', ttsLang:'vi-VN', hasDictAPI:false),
  Language(code:'ar-SA', name:'Arabic',       native:'العربية',    flag:'🇸🇦', ttsLang:'ar-SA', hasDictAPI:false),
  Language(code:'hi-IN', name:'Hindi',        native:'हिन्दी',     flag:'🇮🇳', ttsLang:'hi-IN', hasDictAPI:false),
  Language(code:'id-ID', name:'Indonesian',   native:'Bahasa',     flag:'🇮🇩', ttsLang:'id-ID', hasDictAPI:false),
  Language(code:'nl-NL', name:'Dutch',        native:'Nederlands', flag:'🇳🇱', ttsLang:'nl-NL', hasDictAPI:false),
  Language(code:'tr-TR', name:'Turkish',      native:'Türkçe',     flag:'🇹🇷', ttsLang:'tr-TR', hasDictAPI:false),
  Language(code:'ms-MY', name:'Malay',        native:'Melayu',     flag:'🇲🇾', ttsLang:'ms-MY', hasDictAPI:false),
];
```

---

## AI LAYER

### Chế độ AI

```dart
enum AIMode {
  appDefault, // Gọi backend FastAPI của app owner (Claude)
  userKey,    // Dùng API key do người dùng nhập
  none,       // Tắt AI hoàn toàn
}

enum AIProvider {
  claude,   // api.anthropic.com
  openai,   // api.openai.com
  gemini,   // generativelanguage.googleapis.com
  grok,     // api.x.ai
  mistral,  // api.mistral.ai
}
```

### Abstract AI Service

```dart
abstract class AIService {
  Future<String?> complete({
    required List<Map<String,String>> messages, // [{role, content}]
    required String systemPrompt,
    int maxTokens = 1000,
  });
}
```

### Các AI Provider — endpoint + format

**Claude (Anthropic)**
- POST `https://api.anthropic.com/v1/messages`
- Headers: `x-api-key`, `anthropic-version: 2023-06-01`
- Models: `claude-opus-4-5`, `claude-sonnet-4-20250514`, `claude-haiku-4-5-20251001`
- Body: `{model, max_tokens, system, messages:[{role,content}]}`
- Response: `data.content[0].text`

**OpenAI (ChatGPT)**
- POST `https://api.openai.com/v1/chat/completions`
- Headers: `Authorization: Bearer <key>`
- Models: `gpt-4o`, `gpt-4o-mini`, `gpt-4-turbo`, `gpt-3.5-turbo`
- Body: `{model, messages:[{role:"system",content:sys},...messages]}`
- Response: `data.choices[0].message.content`

**Gemini (Google)**
- POST `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key=<key>`
- Models: `gemini-2.0-flash`, `gemini-1.5-pro`, `gemini-1.5-flash`
- Body: `{systemInstruction:{parts:[{text:sys}]}, contents:[{role,parts:[{text}]}]}`
- Note: role `assistant` → `model` trong Gemini format
- Response: `data.candidates[0].content.parts[0].text`

**Grok (xAI)**
- POST `https://api.x.ai/v1/chat/completions`
- Headers: `Authorization: Bearer <key>`
- Models: `grok-3`, `grok-3-mini`, `grok-2`
- Format: giống OpenAI
- Response: `data.choices[0].message.content`

**Mistral**
- POST `https://api.mistral.ai/v1/chat/completions`
- Headers: `Authorization: Bearer <key>`
- Models: `mistral-large-latest`, `mistral-small-latest`, `open-mistral-7b`
- Format: giống OpenAI
- Response: `data.choices[0].message.content`

### Lưu API key
Dùng `flutter_secure_storage` — KHÔNG lưu SharedPreferences.
```dart
await storage.write(key: 'ai_api_key_${provider.name}', value: apiKey);
```

---

## LUỒNG DỮ LIỆU TỪ VỰNG

```
Người dùng học từ W trong ngôn ngữ L
  │
  ├─ 1. Tìm trong SQLite (words table, langCode=L)
  │      → Nếu có: dùng luôn (source='cache')
  │
  ├─ 2. Nếu không có && L là English && online:
  │      → Gọi dictionaryapi.dev/api/v2/entries/en/{word}
  │      → Parse: phonetic US/UK, audio MP3 URLs, partOfSpeech, definition, example
  │      → Lưu vào SQLite
  │
  └─ 3. Nếu offline hoặc không phải English:
         → Dùng built-in vocab_data.dart (hardcoded)
```

### Free Dictionary API Response Parser

```dart
// GET https://api.dictionaryapi.dev/api/v2/entries/en/{word}
// Response là List, lấy entry đầu tiên

String phoneticUS = '', phoneticUK = '', audioUS = '', audioUK = '';
for (final ph in entry['phonetics']) {
  final audio = ph['audio'] ?? '';
  final text  = ph['text'] ?? '';
  if (audio.contains('-us') || audio.contains('_us') || (audioUS.isEmpty && audio.isNotEmpty)) {
    if (phoneticUS.isEmpty) phoneticUS = text;
    if (audioUS.isEmpty)    audioUS    = audio;
  }
  if (audio.contains('-uk') || audio.contains('_uk')) {
    if (phoneticUK.isEmpty) phoneticUK = text;
    if (audioUK.isEmpty)    audioUK    = audio;
  }
}
if (phoneticUS.isEmpty) phoneticUS = entry['phonetic'] ?? '';
if (phoneticUK.isEmpty) phoneticUK = phoneticUS;

final meaning = entry['meanings'][0];
final def     = meaning['definitions'][0];
final partOfSpeech = meaning['partOfSpeech'];
final definition   = def['definition'];
final example      = def['example'] ?? '';
```

---

## SPACED REPETITION (SM-2)

```dart
// Sau mỗi lần đánh giá, tính interval + easeFactor mới
// rating: 0=wrong, 1=hard, 2=good

void updateSM2(WordProgress p, int rating) {
  if (rating == 0) {
    // Quên: reset về đầu
    p.interval    = 1;
    p.reviewCount += 1;
  } else {
    // Hard hoặc Good
    if (p.reviewCount == 0)      p.interval = 1;
    else if (p.reviewCount == 1) p.interval = 6;
    else p.interval = (p.interval * p.easeFactor).round();

    // Cập nhật ease factor
    final q = rating == 1 ? 3 : 5; // hard=3, good=5
    p.easeFactor = max(1.3, p.easeFactor + 0.1 - (5-q)*(0.08 + (5-q)*0.02));
    p.reviewCount += 1;
    p.correctCount += 1;
  }
  p.nextReview = DateTime.now()
    .add(Duration(days: p.interval))
    .millisecondsSinceEpoch ~/ 1000;
  p.status = rating == 0 ? 'learning' : (p.interval >= 21 ? 'known' : 'review');
}
```

---

## MÀNG HÌNH & TÍNH NĂNG

### 1. Language Bar (top of main screen)

```
┌─────────────────────┬────┬─────────────────────┐
│ ★ Ngôn ngữ chính   │ VS │  + Ngôn ngữ phụ     │
│ 🇺🇸 English US      │    │  (optional)          │
│ [Ngôn ngữ chính]   │    │  [Ngôn ngữ phụ]     │
└─────────────────────┴────┴─────────────────────┘
```

**Rules:**
- Luôn có đúng 1 ngôn ngữ chính (không thể xóa)
- Ngôn ngữ phụ: optional, nhấn ✕ để xóa
- Tối đa 2 ngôn ngữ
- Mặc định khởi động: `en-US` là ngôn ngữ chính
- Nhấn slot → mở `LanguagePickerSheet` (bottom sheet)

### 2. Language Picker Bottom Sheet

- Search bar lọc theo tên
- Danh sách 20 ngôn ngữ, mỗi item hiện: flag, tên, native name, badge số từ offline
- Nút **"★ Đặt làm chính"** → swap ngôn ngữ chính, ngôn ngữ cũ xuống slot phụ nếu cần
- Ngôn ngữ đang là chính: highlight xanh, không thể bỏ chọn
- Ngôn ngữ đang là phụ: highlight tím, nhấn lại để bỏ chọn

### 3. Session Preview Screen (bắt buộc trước mỗi phiên)

Hiển thị TRƯỚC khi vào Flashcard hoặc Quick Review:

```
┌─────────────────────────────────────┐
│ 📋 Phiên học mới          Bỏ qua → │
│ 🇺🇸 English US · 15 từ trong hàng đợi│
│ Nhấn "Biết rồi" để bỏ qua         │
├─────────────────────────────────────┤
│  1  persevere  /ˌpɜːrsɪˈvɪər/     [Biết rồi] │
│     🇻🇳 kiên trì, bền bỉ vượt khó            │
├─────────────────────────────────────┤
│  2  meticulous  /məˈtɪkjʊləs/     [Biết rồi] │
│     🇻🇳 tỉ mỉ, cẩn thận từng chi tiết         │
├─────────────────────────────────────┤
│           [Bắt đầu học 13 từ]               │
│      Đã bỏ qua 2 từ bạn đã biết            │
└─────────────────────────────────────┘
```

**Logic:**
- Từ được đánh "Biết rồi" → status = `'skipped'`, không xuất hiện trong phiên, hiện gạch ngang
- Nút "Bắt đầu học N từ" cập nhật realtime
- Nhấn "Bỏ qua →" → học tất cả không preview

### 4. Flashcard Screen

**Layout:** 1 card lớn (primary) + secondary strip bên dưới (nếu có ngôn ngữ phụ)

```
┌─────────────────────────┐
│ 1 / 13           US | UK│
│                         │
│  🇺🇸 English US          │ ← Primary card (full width)
│                         │
│  persevere              │
│  /ˌpɜːrsɪˈvɪər/         │
│  [verb]                 │
│  [🔊 US]  [🎵 UK]        │
│                         │
│  👆 Nhấn để xem nghĩa   │
│                         │
│  [Sau khi lật:]         │
│  🇻🇳 kiên trì, bền bỉ    │
│  📝 She persevered...    │
│  [🔊 Câu ví dụ]          │
│  ✦ AI giải thích...      │ ← Hiện khi bấm "Quên"
└─────────────────────────┘

┌─────────────────────────┐
│ 🇰🇷 Korean · Thêm thông tin · không bắt buộc │
│ 열심히  [yeolsimhi]     🔊 │
│ 🇻🇳 chăm chỉ, hết lòng  │
└─────────────────────────┘

[😰 Quên]  [😅 Khó]  [😊 Nhớ]
[✨ Hỏi AI về từ này]
```

**Card behaviors:**
- Nhấn card → lật (AnimationController, flip 3D)
- Chỉ cần lật PRIMARY card mới hiện nút rating
- Secondary strip: LUÔN hiện nghĩa, không cần lật, chỉ có nút 🔊
- Phát âm: nếu có MP3 URL → AudioPlayer; nếu không → flutter_tts
- Sau "😰 Quên": gọi AI, hiện box tím giải thích + mẹo nhớ

**Audio playback priority:**
```
1. MP3 từ Free Dictionary API (audio_us / audio_uk)
2. flutter_tts fallback
```

### 5. Quick Review Screen (full-screen dark mode)

```
┌─────────────────────────────────────┐
│ ✕                 3 / 10           │  ← header
│ ████████████░░░░░░░░░░░░░░░░░      │  ← timer bar (auto-flip mode)
│                                     │
│           🇺🇸 English US             │
│                                     │
│            persevere               │  ← 52px bold white
│       /ˌpɜːrsɪˈvɪər/ verb          │
│       [🔊 Nghe phát âm]            │
│                                     │
│    [sau khi lật / tự động:]         │
│    🇻🇳 kiên trì, bền bỉ             │
│    📝 She persevered...             │
│                                     │
│  ← Quên          Nhớ →             │  ← swipe hints
│                                     │
│  [😰 Quên]  [😅 Khó]  [😊 Nhớ]   │  ← rating buttons
└─────────────────────────────────────┘
```

**Gestures:**
- Tap card → lật (reveal)
- Swipe right (>80px) → Nhớ
- Swipe left  (>80px) → Quên
- Swipe up           → Khó
- Kéo: card xoay theo ngón tay, hiện emoji 😰/😊 ở cạnh

**Keyboard (tablet/desktop):**
- Space / ↓ → lật
- → → Nhớ, ← → Quên, ↑ → Khó
- Esc → đóng

**Quick Review queue:** mix primary words (remaining + review) theo SM-2 `nextReview`. Secondary language words được xen kẽ như "bonus info card" — không có nút rating, hiện rõ label "Ngôn ngữ phụ".

### 6. Lookup Screen (Tra từ)

- Chỉ hỗ trợ tiếng Anh (Free Dictionary API)
- Search bar → Enter / nút Tra
- Nguồn: SQLite cache → API online → thông báo lỗi nếu offline
- Kết quả hiện: từ, phiên âm US/UK, loại từ, định nghĩa, ví dụ
- Nút: 🔊 US, 🔊 UK, "+ Thêm vào học", "✦ AI giải thích"
- Source badge: 🌐 API / 💾 Cache / 📦 Local

### 7. AI Chat Screen

- Disabled hoàn toàn nếu `AIMode.none`
- Multi-turn chat, lưu history trong bộ nhớ (không persist)
- System prompt điều chỉnh theo ngôn ngữ đang học
- Quick buttons tự động cập nhật theo ngôn ngữ được chọn
- Typing indicator (animated dots) khi chờ AI

### 8. Progress Screen

Stats cards (2x2 grid):
- Học hôm nay / Đã nhớ / Cần ôn / Streak 🔥

Per-language sections:
- Tiêu đề màu theo ngôn ngữ
- Badge cache count (chỉ English)
- 3 chip lists: ✅ Đã nhớ / 🔄 Cần ôn / 📘 Chưa học
- Nhấn chip → phát âm từ đó

### 9. Settings Screen

#### AI Mode (3 options, radio cards):

```
┌─────────────────────────────────────┐
│ ○ App mặc định          [Miễn phí] │
│   Dùng AI do app cung cấp sẵn      │
├─────────────────────────────────────┤
│ ● API key của tôi       [Tùy chỉnh]│
│   Claude / ChatGPT / Gemini / Grok  │
│   ┌───────────────────────────────┐ │
│   │ Provider: [Claude▼]           │ │
│   │ API Key:  [••••••••••••]      │ │
│   │ Model:    [claude-sonnet-4▼]  │ │
│   │ [🔌 Test kết nối] [💾 Lưu]   │ │
│   └───────────────────────────────┘ │
├─────────────────────────────────────┤
│ ○ Không dùng AI         [Offline]  │
│   ✅ Flashcard, TTS, Tra từ        │
│   ❌ AI giải thích, Hỏi AI         │
└─────────────────────────────────────┘
```

#### Nhắc học hàng ngày:
- Toggle on/off → xin quyền notification
- Giờ nhắc (picker)
- Số từ mỗi lần nhắc (5/10/20)
- Notification hiển thị từ + nghĩa, nhấn → mở Quick Review

#### Quick Review:
- Toggle tự động lật thẻ (on/off)
- Thời gian mỗi thẻ (3/5/8/10/15 giây)
- Mục tiêu mỗi phiên (5/10/20/không giới hạn)

---

## HOME SCREEN WIDGET (Android + iOS)

### Android (AppWidgetProvider)
File: `android/app/src/main/kotlin/.../VocabWidget.kt`

```kotlin
// Widget 2x2: hiện từ ngày hôm nay
// - Từ (large text)
// - Phiên âm
// - Nghĩa tiếng Việt (1 dòng)
// - Nút 🔊 phát âm (intent → app)
// - Nút "Học ngay" → mở Quick Review
```

### iOS (WidgetKit)
File: `ios/VocabWidget/VocabWidget.swift`

```swift
// Small widget: từ + nghĩa
// Medium widget: từ + phiên âm + nghĩa + ví dụ
// Link deeplink → quick_review
```

### Data bridge (home_widget package)
```dart
// Trong Flutter, cập nhật widget data:
await HomeWidget.saveWidgetData('current_word', wordJson);
await HomeWidget.updateWidget(
  name: 'VocabWidgetProvider',
  iOSName: 'VocabWidget',
);
```

---

## NOTIFICATION LOGIC

```dart
// Lên lịch daily notification
Future<void> scheduleDailyReminder({
  required TimeOfDay time,
  required int wordCount,
}) async {
  final word = await getNextWordForLang(defaultLang);
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    '🌏 Vocab AI — Từ mới hôm nay',
    '${word.flag} ${word.word} — ${word.shortMeaning}',
    _nextInstanceOfTime(time),
    NotificationDetails(
      android: AndroidNotificationDetails('vocab_daily', 'Nhắc học',
        importance: Importance.high, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    payload: 'quick_review',
  );
}

// Handle notification tap → navigate to Quick Review
// In main.dart: setup onDidReceiveNotificationResponse callback
```

---

## DEEPLINKS / NAVIGATION

```dart
// GoRouter routes
final router = GoRouter(routes: [
  GoRoute(path: '/',        builder: (_, __) => MainScreen()),
  GoRoute(path: '/preview', builder: (_, __) => SessionPreviewScreen()),
  GoRoute(path: '/flashcard', builder: (_, __) => FlashcardScreen()),
  GoRoute(path: '/quick-review', builder: (_, __) => QuickReviewScreen()),
  GoRoute(path: '/lookup',    builder: (_, __) => LookupScreen()),
  GoRoute(path: '/ai-chat',   builder: (_, __) => AIChatScreen()),
  GoRoute(path: '/progress',  builder: (_, __) => ProgressScreen()),
  GoRoute(path: '/settings',  builder: (_, __) => SettingsScreen()),
]);
```

---

## OFFLINE DATA (built-in vocab_data.dart)

Mỗi ngôn ngữ có sẵn 10–20 từ hardcoded. English 20 từ chủ đề IT + học thuật. Korean 12 từ IT + giao tiếp. Japanese 10 từ. Chinese 10 từ. French/German/Spanish/Portuguese 6–8 từ mỗi ngôn ngữ.

Format mỗi từ:
```dart
class BuiltinWord {
  final String word;
  final String? romanization; // Korean, Japanese, Chinese
  final String? phonetic;     // IPA
  final String? phoneticUK;   // nếu khác US
  final String type;          // verb, noun, adj...
  final String meaning;       // nghĩa tiếng Việt, prefix 🇻🇳
  final String example;       // câu ví dụ
}
```

---

## THEME & DESIGN

### Colors
```dart
const primaryColor   = Color(0xFF111111);
const enColor        = Color(0xFF1A6FB5);   // English — xanh dương
const krColor        = Color(0xFFC0392B);   // Korean — đỏ
const secondaryColor = Color(0xFF6C3FC7);   // Secondary lang — tím
const bgColor        = Color(0xFFF4F4EF);   // nền app
const cardColor      = Colors.white;
const successGreen   = Color(0xFF27AE60);
const warningOrange  = Color(0xFFE67E22);
const errorRed       = Color(0xFFE74C3C);
```

### Typography
- Primary font: system default (SF Pro trên iOS, Roboto trên Android)
- Word display: `fontWeight: FontWeight.w800, fontSize: 32`
- Quick Review word: `fontSize: 52, fontWeight: FontWeight.w800`
- Body: `fontSize: 14, fontWeight: FontWeight.w400`

### Animations
- Card flip: `AnimationController` 400ms, `TweenAnimationBuilder` + `Transform`
- Swipe gesture: custom `GestureDetector` + `AnimatedPositioned`
- Sheet transitions: `showModalBottomSheet` với `isScrollControlled: true`
- Page transitions: slide từ phải sang

---

## PUBSPEC.YAML DEPENDENCIES

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  # Navigation
  go_router: ^14.2.0
  # Database
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0
  # HTTP
  dio: ^5.4.3
  # TTS
  flutter_tts: ^4.0.2
  # Audio playback (MP3)
  just_audio: ^0.9.40
  # Notifications
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4
  # Secure storage
  flutter_secure_storage: ^9.2.2
  # Home widget
  home_widget: ^0.5.0
  # Shared prefs (non-sensitive settings)
  shared_preferences: ^2.3.2
  # Utils
  intl: ^0.19.0
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.11
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.3
  flutter_lints: ^4.0.0
```

---

## HƯỚNG DẪN BUILD TỪNG BƯỚC

Claude Code nên thực hiện theo thứ tự này:

### Phase 1 — Foundation
1. `flutter create vocab_ai --org com.vocabai`
2. Cập nhật `pubspec.yaml` với các dependencies trên
3. Tạo `core/db/` — Drift schema + DAOs
4. Tạo `data/languages.dart` + `data/vocab_data.dart`
5. Tạo `core/ai/` — abstract + 5 providers
6. Tạo `core/tts/tts_service.dart`
7. Tạo `core/dictionary/dict_service.dart`

### Phase 2 — Main UI
8. `app.dart` — theme + GoRouter
9. `widgets/lang_slot_bar.dart` — 2 slot với VS divider
10. `widgets/lang_picker_sheet.dart` — bottom sheet 20 ngôn ngữ
11. `features/session_preview/` — word list + skip logic
12. `features/flashcard/flashcard_screen.dart` — card + flip + secondary strip
13. `features/flashcard/secondary_strip.dart` — strip ngôn ngữ phụ

### Phase 3 — Features
14. `features/quick_review/` — dark fullscreen + swipe + timer
15. `features/lookup/` — search + API + display
16. `features/ai_chat/` — chat UI + AI integration
17. `features/progress/` — stats + per-lang chip lists
18. `features/settings/` — AI mode + provider picker + notification

### Phase 4 — Native
19. `core/notifications/notif_service.dart` + scheduling
20. Android widget (`VocabWidget.kt`)
21. iOS widget (`VocabWidget.swift`)
22. Home widget data bridge

---

## GHI CHÚ QUAN TRỌNG

1. **API keys bảo mật:** Dùng `flutter_secure_storage`, không bao giờ dùng `SharedPreferences` cho key. Không hardcode key trong code.

2. **App Default AI key:** Lưu trong biến môi trường build-time (`--dart-define=APP_AI_KEY=xxx`), đọc bằng `const String.fromEnvironment('APP_AI_KEY')`.

3. **Offline first:** Mọi tính năng cốt lõi (flashcard, TTS, xem tiến độ) phải hoạt động không cần mạng. API chỉ là enhancement.

4. **T+2 awareness:** Không áp dụng ở đây (đây là vocab app, không phải stock app).

5. **Session Preview bắt buộc:** Mỗi khi bắt đầu phiên mới (navigating đến Flashcard hoặc Quick Review) phải qua màn hình preview trước, TRỪ KHI user chủ động nhấn "Bỏ qua →".

6. **Primary vs Secondary:** Chỉ PRIMARY language mới có rating (Quên/Khó/Nhớ) và progress tracking. Secondary language luôn hiện answer (không cần lật), không có rating, rotate theo nhịp primary.

7. **SM-2 Algorithm:** Implement đúng công thức, không dùng random interval. Từ có `nextReview <= now` được ưu tiên trong queue.

8. **Tiếng Việt UI:** Toàn bộ UI text bằng tiếng Việt. AI responses cũng yêu cầu tiếng Việt qua system prompt.

---

*Prompt version: 1.0 — Generated từ Vocab AI web prototype*
*Tham chiếu: vocab-ai-app.html (web prototype đầy đủ)*
