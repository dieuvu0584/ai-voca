import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart' show rootBundle;
import 'package:lpinyin/lpinyin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database.dart';
import '../dictionary/free_dict_api.dart';

// ─────────────────────────────────────────────────────────────
// Config
// ─────────────────────────────────────────────────────────────

/// Số từ `new` còn lại tối thiểu — dưới ngưỡng này sẽ fetch batch mới
const int kSyncThreshold = 25;

/// Số từ mỗi batch
const int kBatchSize = 50;

/// Tổng từ tối đa cho mỗi ngôn ngữ (frekwencja ~5050 từ)
const int kMaxWords = 5050;

/// Số từ 'new' tối đa trong tier miễn phí cho tiếng Anh (en-US / en-GB)
const int kFreeEnglishWordLimit = 150;


// ─────────────────────────────────────────────────────────────
// Nguồn từ vựng
// ─────────────────────────────────────────────────────────────

/// Enum nguồn từ vựng mà user có thể chọn
enum VocabSource { frekwencja, hermitDave }

/// Số từ tối đa tương ứng mỗi nguồn
int maxWordsForSource(VocabSource s) =>
    s == VocabSource.hermitDave ? 50000 : 5050;


// ─────────────────────────────────────────────────────────────
// Word list sources (frekwencja/most-common-words-multilingual)
// github.com/frekwencja/most-common-words-multilingual
// Format: 1 từ/dòng, sắp xếp giảm dần theo tần suất, ~5050 từ/ngôn ngữ
// Nguồn gốc: wordfrequency.info — sạch hơn và mới hơn Hermit Dave (2016)
// ─────────────────────────────────────────────────────────────

const String _kFrekwencjaBase =
    'https://raw.githubusercontent.com/frekwencja/most-common-words-multilingual/main/data/wordfrequency.info';

const Map<String, String> kFrequencyListUrls = {
  'en-US': '$_kFrekwencjaBase/en.txt',
  'en-GB': '$_kFrekwencjaBase/en.txt',
  'ko-KR': '$_kFrekwencjaBase/ko.txt',
  'ja-JP': '$_kFrekwencjaBase/ja.txt',
  'zh-CN': '$_kFrekwencjaBase/zh.txt',
  'zh-TW': '$_kFrekwencjaBase/zh.txt',
  'fr-FR': '$_kFrekwencjaBase/fr.txt',
  'de-DE': '$_kFrekwencjaBase/de.txt',
  'es-ES': '$_kFrekwencjaBase/es.txt',
  'pt-BR': '$_kFrekwencjaBase/pt.txt',
  'it-IT': '$_kFrekwencjaBase/it.txt',
  'ru-RU': '$_kFrekwencjaBase/ru.txt',
  'th-TH': '$_kFrekwencjaBase/th.txt',
  'vi-VN': '$_kFrekwencjaBase/vi.txt',
  'ar-SA': '$_kFrekwencjaBase/ar.txt',
  'hi-IN': '$_kFrekwencjaBase/hi.txt',
  'id-ID': '$_kFrekwencjaBase/id.txt',
  'nl-NL': '$_kFrekwencjaBase/nl.txt',
  'tr-TR': '$_kFrekwencjaBase/tr.txt',
  'ms-MY': '$_kFrekwencjaBase/ms.txt',
};

// ─────────────────────────────────────────────────────────────
// Word list sources (Hermit Dave — hermitdave/FrequencyWords)
// github.com/hermitdave/FrequencyWords
// Format: từ tần_suất, ~50k từ/ngôn ngữ, dữ liệu năm 2016
// ─────────────────────────────────────────────────────────────
const String _kHermitDaveBase =
    'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content';

const Map<String, String> kHermitDaveUrls = {
  'en-US': '$_kHermitDaveBase/2016/en/en_50k.txt',
  'en-GB': '$_kHermitDaveBase/2016/en/en_50k.txt',
  'ko-KR': '$_kHermitDaveBase/2016/ko/ko_50k.txt',
  'ja-JP': '$_kHermitDaveBase/2016/ja/ja_50k.txt',
  'zh-CN': '$_kHermitDaveBase/2016/zh_cn/zh_cn_50k.txt',
  'zh-TW': '$_kHermitDaveBase/2016/zh_cn/zh_cn_50k.txt',
  'fr-FR': '$_kHermitDaveBase/2016/fr/fr_50k.txt',
  'de-DE': '$_kHermitDaveBase/2016/de/de_50k.txt',
  'es-ES': '$_kHermitDaveBase/2016/es/es_50k.txt',
  'pt-BR': '$_kHermitDaveBase/2016/pt_br/pt_br_50k.txt',
  'it-IT': '$_kHermitDaveBase/2016/it/it_50k.txt',
  'ru-RU': '$_kHermitDaveBase/2016/ru/ru_50k.txt',
  'th-TH': '$_kHermitDaveBase/2016/th/th_50k.txt',
  'vi-VN': '$_kHermitDaveBase/2016/vi/vi_50k.txt',
  'ar-SA': '$_kHermitDaveBase/2016/ar/ar_50k.txt',
  'hi-IN': '$_kHermitDaveBase/2016/hi/hi_50k.txt',
  'id-ID': '$_kHermitDaveBase/2016/id/id_50k.txt',
  'nl-NL': '$_kHermitDaveBase/2016/nl/nl_50k.txt',
  'tr-TR': '$_kHermitDaveBase/2016/tr/tr_50k.txt',
  'ms-MY': '$_kHermitDaveBase/2016/ms/ms_50k.txt',
};

/// Wiktionary language code (ISO 639-1) tương ứng mỗi langCode
/// English ('en') cũng được hỗ trợ → Wiktionary trả về definition tiếng Anh
const Map<String, String> kWiktionaryLangCode = {
  'en-US': 'en', 'en-GB': 'en',
  'ko-KR': 'ko', 'ja-JP': 'ja', 'zh-CN': 'zh', 'zh-TW': 'zh',
  'fr-FR': 'fr', 'de-DE': 'de', 'es-ES': 'es',
  'pt-BR': 'pt', 'it-IT': 'it', 'ru-RU': 'ru',
  'th-TH': 'th', 'vi-VN': 'vi',
  'ar-SA': 'ar', 'hi-IN': 'hi', 'id-ID': 'id',
  'nl-NL': 'nl', 'tr-TR': 'tr', 'ms-MY': 'ms',
};

/// dictionaryapi.dev — CHỈ hỗ trợ tiếng Anh
/// Đã test: fr/bonjour, de/hallo, es/hola, ko/안녕, hi/नमस्ते → đều 404
/// Các ngôn ngữ khác không được đưa vào đây → dùng Wiktionary-only path
const Map<String, String> kFreeDictApiLangCodes = {
  'en-US': 'en_US',
  'en-GB': 'en_GB',
};

// ─────────────────────────────────────────────────────────────
// Stopwords tiếng Anh — từ quá phổ biến / ít giá trị học
// ─────────────────────────────────────────────────────────────
const _enStopwords = {
  'the', 'a', 'an', 'in', 'on', 'at', 'to', 'of', 'and', 'or', 'but',
  'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
  'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might',
  'this', 'that', 'these', 'those', 'with', 'for', 'from', 'by', 'as',
  'it', 'its', 'he', 'she', 'they', 'we', 'you', 'i', 'me', 'him', 'her',
  'not', 'no', 'so', 'if', 'up', 'out', 'all', 'can', 'just', 'my', 'your',
  'his', 'our', 'their', 'about', 'into', 'than', 'more', 'also', 'some',
  'only', 'then', 'very', 'what', 'when', 'who', 'how', 'any', 'now', 'here',
  'there', 'each', 'other', 'after', 'before', 'over', 'such', 'even', 'most',
};

// ─────────────────────────────────────────────────────────────
// Stopwords tiếng Trung — hư từ / trợ từ ngữ pháp ít giá trị học
// Chia thành nhóm để dễ bảo trì:
//   1. Trợ từ cấu trúc / ngữ khí — không có nghĩa độc lập (的了着地得 + modal particles)
//   2. Đại từ nhân xưng cơ bản — học viên biết từ ngày đầu tiên
//   3. Phó từ / liên từ — tần suất siêu cao, ít giá trị flashcard
//   4. Giới từ / hư từ ngữ pháp
//   5. Đại từ chỉ thị
//   6. Từ hệ từ / tồn tại cơ bản
// KHÔNG lọc: danh từ/động từ/tính từ dù ngắn (人好大小手...)
// ─────────────────────────────────────────────────────────────
const _zhStopwords = {
  // 1. Trợ từ cấu trúc & ngữ khí
  '的', '了', '着', '地', '得',          // structural particles
  '呢', '吧', '吗', '啊', '哦', '嗯', '哈', '嘛', '咧', '喔',  // modal/exclamation

  // 2. Đại từ nhân xưng (cực kỳ cơ bản)
  '我', '你', '他', '她', '它',

  // 3. Phó từ / liên từ tần suất cao
  '不', '没', '也', '都', '就', '还', '又',
  '很', '最', '太', '更', '非',

  // 4. Giới từ / hư từ ngữ pháp
  '被', '把', '给', '让', '使',          // causative / passive markers
  '和', '与', '或', '且',               // conjunctions
  '因', '由', '从', '向', '对',          // prepositions
  '以', '为', '将', '已', '曾',         // function words

  // 5. Đại từ chỉ thị
  '这', '那',

  // 6. Hệ từ / tồn tại / vị trí cực kỳ cơ bản
  '是', '有', '在', '来', '去',
};

// ─────────────────────────────────────────────────────────────
// Contraction fix map — corpus Hermit Dave loại bỏ dấu apostrophe,
// tạo ra các "từ" vô nghĩa. Map này phục hồi dạng đúng.
// VD: "didn" (tần suất 853,640) → "didn't"
// KHÔNG đụng các từ thật: haven (bến cảng), wont (thói quen),
//   cant (nói đạo đức giả), shell (vỏ)
// ─────────────────────────────────────────────────────────────
const _enContractionFix = <String, String>{
  'didn':    "didn't",
  'couldn':  "couldn't",
  'wouldn':  "wouldn't",
  'wasn':    "wasn't",
  'doesn':   "doesn't",
  'hasn':    "hasn't",
  'hadn':    "hadn't",
  'mustn':   "mustn't",
  'needn':   "needn't",
  'shouldn': "shouldn't",
  'aren':    "aren't",
  'mightn':  "mightn't",
  'oughtn':  "oughtn't",
  'daren':   "daren't",
  'shan':    "shan't",
};

// ─────────────────────────────────────────────────────────────
// Stopwords các ngôn ngữ — hư từ / trợ từ ít giá trị flashcard
// ─────────────────────────────────────────────────────────────

// Korean (ko) — 조사·대명사·접속사
const _koStopwords = {
  // 조사 (postposition particles)
  '은', '는', '이', '가', '을', '를', '의', '에', '에서',
  '로', '으로', '와', '과', '까지', '부터', '도', '만',
  '뿐', '면서', '처럼', '마다', '보다',
  // 대명사 (pronouns)
  '나', '저', '너', '그', '그녀', '우리', '저희',
  '이것', '저것', '그것',
  // 접속사·부사
  '안', '못', '더', '아주', '매우', '그리고', '또는', '그러나', '그래서', '하지만', '그런데',
  // 계사
  '이다', '아니다',
};

// Japanese (ja) — 助詞·代名詞·接続詞
const _jaStopwords = {
  // 助詞 (particles)
  'は', 'が', 'を', 'に', 'で', 'と', 'も', 'から', 'まで',
  'へ', 'より', 'や', 'の', 'か', 'ね', 'よ', 'な', 'ぞ',
  'ばかり', 'だけ', 'ほど', 'くらい', 'ながら',
  // 代名詞 (pronouns)
  '私', '僕', '君', '彼', '彼女', '俺', 'あなた',
  'あれ', 'これ', 'それ', 'あの', 'この', 'その',
  // 助動詞・接続詞
  'です', 'ます', 'だ', 'そして', 'しかし', 'または', 'など',
};

// French (fr) — articles·pronoms·prépositions·conjonctions
const _frStopwords = {
  // Articles
  'le', 'la', 'les', 'un', 'une', 'des', 'du', 'au', 'aux',
  // Pronoms
  'je', 'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles',
  'me', 'te', 'se', 'lui', 'y', 'en', 'moi', 'toi', 'eux',
  // Démonstratifs
  'ce', 'cet', 'cette', 'ces',
  // Prépositions
  'de', 'à', 'dans', 'sur', 'sous', 'par', 'pour',
  'avec', 'sans', 'entre', 'depuis', 'vers', 'chez',
  // Conjonctions
  'et', 'ou', 'mais', 'donc', 'car', 'ni', 'que',
  // Négation & modificateurs
  'pas', 'ne', 'plus', 'très', 'aussi',
};

// German (de) — Artikel·Pronomen·Präpositionen·Konjunktionen
const _deStopwords = {
  // Bestimmte Artikel
  'der', 'die', 'das', 'dem', 'den', 'des',
  // Unbestimmte Artikel
  'ein', 'eine', 'einem', 'einen', 'einer', 'eines',
  // Pronomen
  'ich', 'du', 'er', 'sie', 'es', 'wir', 'ihr',
  'mir', 'mich', 'dir', 'dich', 'ihm', 'ihn', 'uns', 'euch', 'sich',
  // Präpositionen
  'in', 'an', 'auf', 'bei', 'mit', 'nach', 'seit', 'von', 'vor',
  'zu', 'aus', 'durch', 'für', 'gegen', 'ohne', 'um', 'über',
  // Konjunktionen
  'und', 'oder', 'aber', 'denn', 'weil', 'dass', 'wenn', 'als', 'ob',
  // Partikeln
  'nicht', 'auch', 'noch', 'nur', 'sehr',
};

// Spanish (es) — artículos·pronombres·preposiciones·conjunciones
const _esStopwords = {
  // Artículos
  'el', 'la', 'los', 'las', 'al', 'del',
  'un', 'una', 'unos', 'unas',
  // Pronombres
  'yo', 'tú', 'él', 'ella', 'usted', 'nosotros', 'vosotros', 'ellos', 'ellas',
  'me', 'te', 'se', 'le', 'lo', 'les', 'nos',
  // Preposiciones
  'de', 'en', 'a', 'por', 'para', 'con', 'sin', 'sobre', 'entre', 'hasta', 'desde',
  // Conjunciones
  'y', 'o', 'pero', 'sino', 'aunque', 'porque', 'que', 'si', 'cuando', 'como', 'ni',
  // Modificadores
  'no', 'también', 'muy', 'más', 'menos',
};

// Portuguese (pt) — artigos·pronomes·preposições·conjunções
const _ptStopwords = {
  // Artigos
  'o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas',
  // Pronomes
  'eu', 'tu', 'ele', 'ela', 'nós', 'vós', 'eles', 'elas',
  'me', 'te', 'se', 'lhe', 'nos',
  // Preposições
  'de', 'em', 'para', 'por', 'com', 'sem', 'sobre', 'entre', 'até', 'desde',
  // Conjunções & partículas
  'e', 'ou', 'mas', 'porém', 'porque', 'que', 'quando', 'como', 'não', 'também',
};

// Italian (it) — articoli·pronomi·preposizioni·congiunzioni
const _itStopwords = {
  // Articoli
  'il', 'lo', 'la', 'i', 'gli', 'le', 'un', 'una', 'uno',
  // Pronomi
  'io', 'tu', 'lui', 'lei', 'noi', 'voi', 'loro',
  'mi', 'ti', 'si', 'ci', 'vi',
  // Preposizioni
  'di', 'in', 'a', 'da', 'con', 'su', 'per', 'tra', 'fra',
  // Congiunzioni
  'e', 'o', 'ma', 'però', 'perché', 'che', 'se', 'quando', 'come',
  // Modificatori
  'non', 'anche', 'molto',
};

// Russian (ru) — местоимения·предлоги·союзы
const _ruStopwords = {
  // Местоимения
  'я', 'ты', 'он', 'она', 'оно', 'мы', 'вы', 'они',
  'меня', 'тебя', 'его', 'её', 'нас', 'вас', 'их',
  'мне', 'тебе', 'ему', 'ей', 'нам', 'вам', 'им',
  // Предлоги
  'в', 'на', 'с', 'из', 'к', 'у', 'о', 'об', 'по',
  'за', 'под', 'над', 'при', 'до', 'от', 'без', 'для', 'между', 'через',
  // Союзы & частицы
  'и', 'или', 'но', 'а', 'что', 'если', 'когда', 'как',
  'так', 'уже', 'только', 'тоже', 'ещё', 'не',
};

// Arabic (ar) — ضمائر·حروف جر·أدوات ربط
const _arStopwords = {
  // ضمائر (pronouns)
  'أنا', 'أنت', 'هو', 'هي', 'نحن', 'أنتم', 'هم', 'هن',
  // أسماء إشارة (demonstratives)
  'هذا', 'هذه', 'ذلك', 'تلك',
  // حروف جر (prepositions)
  'في', 'على', 'من', 'إلى', 'عن', 'مع', 'بعد', 'قبل',
  'بين', 'تحت', 'فوق', 'عند', 'ب', 'ل', 'ك',
  // أدوات ربط & جسيمات
  'و', 'أو', 'لكن', 'أن', 'إذا', 'لأن', 'حتى',
  'لا', 'ما', 'هل', 'قد', 'كان',
};

// Hindi (hi) — सर्वनाम·परसर्ग·संयोजक
const _hiStopwords = {
  // सर्वनाम (pronouns)
  'मैं', 'तुम', 'आप', 'वह', 'हम', 'वे',
  'मुझे', 'तुम्हें', 'उसे', 'हमें', 'उन्हें',
  // परसर्ग (postpositions)
  'में', 'पर', 'से', 'को', 'के', 'की', 'का', 'ने', 'तक', 'लिए', 'साथ', 'बिना',
  // संयोजक & कण
  'और', 'या', 'लेकिन', 'तो', 'अगर', 'क्योंकि', 'इसलिए',
  // सहायक क्रियाएं
  'है', 'हैं', 'था', 'थी', 'थे', 'ही', 'भी', 'नहीं',
};

// Indonesian (id) — kata ganti·preposisi·konjungsi
const _idStopwords = {
  // Kata ganti orang
  'saya', 'aku', 'kamu', 'anda', 'dia', 'kami', 'kita', 'mereka',
  // Kata tunjuk & relatif
  'itu', 'ini', 'yang',
  // Preposisi
  'di', 'ke', 'dari', 'untuk', 'dengan', 'tanpa', 'oleh', 'pada', 'dalam',
  // Konjungsi & partikel
  'dan', 'atau', 'tapi', 'tetapi', 'karena', 'bahwa',
  'jika', 'ketika', 'seperti', 'juga', 'sudah', 'belum', 'akan',
};

// Dutch (nl) — lidwoorden·voornaamwoorden·voorzetsels·voegwoorden
const _nlStopwords = {
  // Lidwoorden
  'de', 'het', 'een',
  // Voornaamwoorden
  'ik', 'jij', 'je', 'hij', 'zij', 'ze', 'wij', 'we', 'jullie', 'u',
  'me', 'mij', 'jou', 'hem', 'haar', 'ons', 'hen', 'hun',
  // Voorzetsels
  'in', 'op', 'aan', 'bij', 'met', 'naar', 'van', 'voor',
  'uit', 'door', 'over', 'onder', 'tussen', 'om',
  // Voegwoorden & partikels
  'en', 'of', 'maar', 'want', 'omdat', 'dat', 'als', 'hoe', 'ook', 'niet',
};

// Turkish (tr) — zamirler·edatlar·bağlaçlar
const _trStopwords = {
  // Zamirler (pronouns) — 'o' (1-char) al klaar gefilterd door minLen=2
  'ben', 'sen', 'biz', 'siz', 'onlar',
  'beni', 'seni', 'onu', 'bizi', 'sizi', 'onları',
  'bana', 'sana', 'ona', 'bize', 'size', 'onlara',
  // Edatlar (postpositions)
  'için', 'gibi', 'kadar', 'göre', 'sonra', 'önce', 'karşı', 'rağmen',
  // Bağlaçlar & partikeller
  've', 'veya', 'ama', 'fakat', 'çünkü', 'ki', 'eğer', 'da', 'de', 'ile',
  // Zamirler / partikeller
  'bu', 'şu', 'ne', 'değil',
};

// Malay (ms) — kata ganti·kata depan·kata hubung
const _msStopwords = {
  // Kata ganti orang
  'saya', 'aku', 'kamu', 'awak', 'dia', 'kami', 'kita', 'mereka',
  // Kata tunjuk & relatif
  'itu', 'ini', 'yang',
  // Kata depan
  'di', 'ke', 'dari', 'untuk', 'dengan', 'tanpa', 'oleh', 'pada', 'dalam', 'kepada',
  // Kata hubung & partikel
  'dan', 'atau', 'tapi', 'tetapi', 'kerana', 'bahawa',
  'jika', 'apabila', 'seperti', 'juga', 'sudah', 'belum', 'akan',
};

// Vietnamese (vi) — đại từ·giới từ·liên từ·trợ từ
const _viStopwords = {
  // Đại từ nhân xưng (hệ thống phức tạp theo quan hệ xã hội)
  'tôi', 'tao', 'mày', 'nó', 'chúng', 'họ', 'mình', 'ta',
  'bạn', 'anh', 'chị', 'em', 'ông', 'bà',
  // Giới từ & hướng vị
  'ở', 'tại', 'từ', 'trong', 'trên', 'dưới', 'đến', 'về',
  // Liên từ
  'và', 'hay', 'hoặc', 'nhưng', 'vì', 'nên', 'nếu', 'khi', 'mà',
  // Trợ từ & phụ từ
  'của', 'là', 'không', 'có', 'được', 'cho', 'đã', 'đang', 'sẽ', 'rồi',
};

// Thai (th) — คำสรรพนาม·คำบุพบท·คำสันธาน·คำอนุภาค
const _thStopwords = {
  // คำสรรพนาม (pronouns)
  'ผม', 'ฉัน', 'คุณ', 'เขา', 'เธอ', 'เรา', 'พวกเขา',
  // คำชี้เฉพาะ (demonstratives)
  'นี้', 'นั้น',
  // คำบุพบท / อนุภาค
  'ใน', 'บน', 'จาก', 'ที่', 'ด้วย', 'ของ',
  // อนุภาคไวยากรณ์
  'ก็', 'ได้', 'ไม่', 'แล้ว', 'ยัง', 'มี', 'เป็น',
  // คำสันธาน
  'และ', 'หรือ', 'แต่', 'เพราะ', 'ว่า', 'ซึ่ง', 'เมื่อ', 'ถ้า',
};

// ─────────────────────────────────────────────────────────────
// Script filter — chỉ giữ từ thuộc đúng hệ chữ viết của ngôn ngữ.
// Corpus Hermit Dave / Frekwencja thường có lẫn từ Latin (tên riêng,
// loanwords chưa được chuyển tự) — cần lọc để tránh từ vô nghĩa.
//
// Các ngôn ngữ dùng chữ Latin (fr, de, es, pt, it, id, ms, tr, vi):
//   → KHÔNG cần script filter (Latin là bình thường).
// Các ngôn ngữ dùng chữ viết riêng:
//   ko  Hangul      U+AC00–U+D7AF (syllable blocks)  +  U+1100–U+11FF (jamo)
//   ja  Hiragana    U+3040–U+309F
//       Katakana    U+30A0–U+30FF
//       CJK         U+4E00–U+9FFF  (Kanji dùng trong văn viết)
//   zh  CJK         U+4E00–U+9FFF  +  U+3400–U+4DBF  (ext A)
//   th  Thai        U+0E00–U+0E7F
//   ar  Arabic      U+0600–U+06FF
//   hi  Devanagari  U+0900–U+097F
//   ru  Cyrillic    U+0400–U+04FF
// ─────────────────────────────────────────────────────────────
RegExp? _scriptPatternFor(String langCode) {
  if (langCode.startsWith('ko')) {
    // Hangul syllable blocks + jamo
    return RegExp(r'^[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]+$');
  }
  if (langCode.startsWith('ja')) {
    // Hiragana + Katakana + CJK (Kanji) — cho phép mix vì văn tiếng Nhật dùng cả 3
    return RegExp(r'^[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF\u3400-\u4DBF]+$');
  }
  if (langCode.startsWith('zh')) {
    // CJK Unified Ideographs + Extension A
    return RegExp(r'^[\u4E00-\u9FFF\u3400-\u4DBF]+$');
  }
  if (langCode.startsWith('th')) {
    return RegExp(r'^[\u0E00-\u0E7F]+$');
  }
  if (langCode.startsWith('ar')) {
    return RegExp(r'^[\u0600-\u06FF\u0750-\u077F]+$');
  }
  if (langCode.startsWith('hi')) {
    return RegExp(r'^[\u0900-\u097F]+$');
  }
  if (langCode.startsWith('ru')) {
    return RegExp(r'^[\u0400-\u04FF]+$');
  }
  // Các ngôn ngữ Latin (fr, de, es, pt, it, id, ms, tr, vi, nl): không cần filter
  return null;
}

// ─────────────────────────────────────────────────────────────
// Lookup map: langCode prefix → stopword set
// ─────────────────────────────────────────────────────────────
Set<String> _stopwordsForLang(String langCode) {
  if (langCode.startsWith('en')) return _enStopwords;
  if (langCode.startsWith('zh')) return _zhStopwords;
  if (langCode.startsWith('ko')) return _koStopwords;
  if (langCode.startsWith('ja')) return _jaStopwords;
  if (langCode.startsWith('fr')) return _frStopwords;
  if (langCode.startsWith('de')) return _deStopwords;
  if (langCode.startsWith('es')) return _esStopwords;
  if (langCode.startsWith('pt')) return _ptStopwords;
  if (langCode.startsWith('it')) return _itStopwords;
  if (langCode.startsWith('ru')) return _ruStopwords;
  if (langCode.startsWith('ar')) return _arStopwords;
  if (langCode.startsWith('hi')) return _hiStopwords;
  if (langCode.startsWith('id')) return _idStopwords;
  if (langCode.startsWith('nl')) return _nlStopwords;
  if (langCode.startsWith('tr')) return _trStopwords;
  if (langCode.startsWith('ms')) return _msStopwords;
  if (langCode.startsWith('vi')) return _viStopwords;
  if (langCode.startsWith('th')) return _thStopwords;
  return const {};
}

// ─────────────────────────────────────────────────────────────
// Wiktionary APIs (miễn phí, không cần key)
//
// Endpoint 1: REST definition API — trả về pos/definition/example
//   https://en.wiktionary.org/api/rest_v1/page/definition/{word}
//
// Endpoint 2: MediaWiki Action API — trả về wikitext thô, dùng để
//   extract IPA vì REST endpoint KHÔNG expose phonetic data.
//   IPA nằm trong section "Pronunciation" của wikitext, format:
//     {{IPA|fr|/bɔ̃.ʒuʁ/}}  hoặc  {{IPA|ko|[안.녕.ha.se.yo]}}
// ─────────────────────────────────────────────────────────────
class _WiktionaryApi {
  final Dio _dioRest = Dio(BaseOptions(
    baseUrl: 'https://en.wiktionary.org/api/rest_v1/page/definition',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final Dio _dioWiki = Dio(BaseOptions(
    baseUrl: 'https://en.wiktionary.org',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Dio không có baseUrl — dùng cho các Wiktionary domain khác (it, pt...)
  final Dio _dioAux = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ── Các phương thức helper lấy IPA từ nguồn bản ngữ ──────────────────────

  /// Lấy IPA từ wikitext của một Wiktionary bản ngữ.
  ///
  /// Dùng cho ngôn ngữ có IPA trực tiếp trong wikitext bản ngữ nhưng
  /// English Wiktionary lại dùng template phức tạp không chứa IPA text:
  ///   Italian:    it.wiktionary.org → {{IPA|/ˈt͡ʃao/}}
  ///   Portuguese: pt.wiktionary.org → {{AFI|/tɾɐ.ˈba.ʎu/}}
  Future<String> _fetchIPAFromNativeWikitext(
      String word, String baseUrl, RegExp ipaPattern) async {
    try {
      final response = await _dioAux.get<Map<String, dynamic>>(
        '$baseUrl/w/api.php',
        queryParameters: {
          'action': 'parse',
          'page': word,
          'prop': 'wikitext',
          'format': 'json',
        },
      );
      final wikitext =
          (response.data?['parse']?['wikitext']?['*'] ?? '') as String;
      final match = ipaPattern.firstMatch(wikitext);
      return match?.group(1)?.trim() ?? '';
    } on DioException {
      return '';
    }
  }

  /// Lấy IPA từ rendered HTML của English Wiktionary.
  ///
  /// Dùng cho Spanish: {{es-pr|+}} trong wikitext không chứa IPA text,
  /// nhưng Wiktionary render ra <span class="IPA">/tɾaˈbaxo/</span> trong HTML.
  ///
  /// [langSectionName]: tên section trong HTML (vd: "Spanish", "French")
  Future<String> _fetchIPAFromHTML(
      String word, String langSectionName) async {
    try {
      final response = await _dioWiki.get<String>(
        '/api/rest_v1/page/html/${Uri.encodeComponent(word)}',
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data ?? '';
      if (html.isEmpty) return '';

      // Tìm section cho ngôn ngữ target (id="Spanish" hoặc id="French"...)
      // Wiktionary HTML: <h2 id="Spanish">Spanish</h2> bắt đầu section
      final sectionMatch = RegExp(
        r'id="' + RegExp.escape(langSectionName) + r'"[^>]*>(.{0,3000})',
        dotAll: true,
      ).firstMatch(html);
      final section = sectionMatch?.group(1) ?? '';
      if (section.isEmpty) return '';

      // Lấy IPA đầu tiên trong section: <span class="IPA">/tɾaˈbaxo/</span>
      final ipaMatch =
          RegExp(r'class="IPA">([^<]+)<').firstMatch(section);
      return ipaMatch?.group(1)?.trim() ?? '';
    } on DioException {
      return '';
    }
  }

  /// Lấy IPA từ wikitext qua MediaWiki Action API.
  /// REST definition endpoint không expose phonetic — phải dùng endpoint này.
  ///
  /// Dispatch theo ngôn ngữ:
  ///   es → English Wiktionary rendered HTML ({{es-pr|+}} không có IPA text)
  ///   it → it.wiktionary.org wikitext: {{IPA|/ipa/}}
  ///   pt → pt.wiktionary.org wikitext: {{AFI|/ipa/}}
  ///   Còn lại → en.wiktionary.org wikitext: {{IPA|lang|/ipa/}}
  Future<String> _fetchIPA(String word, String wiktLangCode) async {
    // ── Dispatch cho ngôn ngữ dùng nguồn IPA khác English Wiktionary wikitext
    if (wiktLangCode == 'es') {
      return _fetchIPAFromHTML(word, 'Spanish');
    }
    if (wiktLangCode == 'it') {
      // it.wiktionary.org: {{IPA|/ˈt͡ʃao/}} — IPA là group(1)
      return _fetchIPAFromNativeWikitext(
        word,
        'https://it.wiktionary.org',
        RegExp(r'\{\{IPA\|(/[^|}>\n]+/)'),
      );
    }
    if (wiktLangCode == 'pt') {
      // pt.wiktionary.org: {{AFI|/tɾɐ.ˈba.ʎu/}} — IPA là group(1)
      return _fetchIPAFromNativeWikitext(
        word,
        'https://pt.wiktionary.org',
        RegExp(r'\{\{AFI\|(/[^|}>\n]+/)'),
      );
    }

    // ── Standard: English Wiktionary wikitext ────────────────────────────────
    try {
      final response = await _dioWiki.get<Map<String, dynamic>>(
        '/w/api.php',
        queryParameters: {
          'action': 'parse',
          'page': word,
          'prop': 'wikitext',
          'format': 'json',
        },
      );
      final wikitext =
          (response.data?['parse']?['wikitext']?['*'] ?? '') as String;
      if (wikitext.isEmpty) return '';

      // ── Bước 1: {{IPA|lang|/ipa/}} — ưu tiên tìm đúng lang code ────────
      // Ví dụ: {{IPA|fr|/bɔ̃.ʒuʁ/}} hoặc {{IPA|de|/ˈhalo/|/haˈloː/}}
      final withLang = RegExp(
        r'\{\{IPA\|' + RegExp.escape(wiktLangCode) + r'\|([^|}\n]+)',
      ).firstMatch(wikitext);
      if (withLang != null) return withLang.group(1)!.trim();

      // ── Bước 2: {{IPA|/ipa/}} không có lang code ──────────────────────
      // Bỏ qua nếu group(1) trông như một lang code (vd: "en", "fr-CA")
      final anyIPA = RegExp(r'\{\{IPA\|([^|}\n]+)').firstMatch(wikitext);
      if (anyIPA != null) {
        final val = anyIPA.group(1)!.trim();
        if (val.startsWith('/') || val.startsWith('[')) return val;
      }

      // ── Bước 3: IPA inline gần ==Pronunciation== heading ──────────────
      // Dùng cho ru, ar, hi — {{ru-IPA|...}} không chứa IPA text trực tiếp
      // nhưng đôi khi có /ipa/ hay [ipa] ở gần heading trong wikitext.
      final pronMatch = RegExp(
        r'==\s*Pronunciation\s*==(.{0,400})',
        dotAll: true,
      ).firstMatch(wikitext);
      if (pronMatch != null) {
        final block = pronMatch.group(1)!;
        final inlineIpa =
            RegExp(r'(/[^\s/]{2,30}/|\[[^\s\[\]]{2,30}\])').firstMatch(block);
        if (inlineIpa != null) return inlineIpa.group(1)!.trim();
      }

      return '';
    } on DioException {
      return '';
    }
  }

  /// Trả về (partOfSpeech, definition, example, phonetic) hoặc null nếu không tìm thấy.
  /// Gọi song song REST + wikitext IPA để tránh tăng latency.
  Future<({String pos, String definition, String example, String phonetic})?> lookup(
      String word, String wiktLangCode) async {
    try {
      // Gọi song song: REST definition + wikitext IPA
      final defFuture = _dioRest.get<Map<String, dynamic>>('/$word');
      final ipaFuture = _fetchIPA(word, wiktLangCode);

      final response = await defFuture;
      final data = response.data;
      if (data == null) return null;

      // Tìm section ngôn ngữ đúng (ví dụ: "fr", "ko", "ja")
      final langSection = data[wiktLangCode] as List?;
      if (langSection == null || langSection.isEmpty) return null;

      final entry = langSection[0] as Map<String, dynamic>;
      final pos = (entry['partOfSpeech'] ?? '') as String;

      final defs = entry['definitions'] as List?;
      if (defs == null || defs.isEmpty) return null;

      final firstDef = defs[0] as Map<String, dynamic>;

      // Strip HTML tags từ definition
      final rawDef = (firstDef['definition'] ?? '') as String;
      final definition = rawDef
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .trim();

      if (definition.isEmpty) return null;

      // Lấy example đầu tiên nếu có
      // Wiktionary trả về dạng List<Map> hoặc List<String> tùy từ/ngôn ngữ
      final examples = firstDef['examples'] as List?;
      String example = '';
      if (examples != null && examples.isNotEmpty) {
        final ex0 = examples[0];
        final raw = ex0 is Map
            ? (ex0['example'] ?? '') as String
            : ex0 is String
                ? ex0
                : '';
        example = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      }

      // Lấy IPA từ wikitext (đã chạy song song ở trên)
      final phonetic = await ipaFuture;

      return (pos: pos, definition: definition, example: example, phonetic: phonetic);
    } on DioException {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// VocabSyncService
// ─────────────────────────────────────────────────────────────
class VocabSyncService {
  final AppDatabase _db;
  final FreeDictApi _freeDictApi;
  final _WiktionaryApi _wiktionaryApi;
  final Dio _dio;

  /// Dedup: tránh gọi enrich cùng lúc cho cùng 1 từ
  final Set<String> _enrichingWords = {};

  VocabSyncService(this._db)
      : _freeDictApi = FreeDictApi(),
        _wiktionaryApi = _WiktionaryApi(),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
        ));

  // ── Public API ───────────────────────────────────────────

  /// Gọi mỗi khi mở Home.
  /// - English + HermitDave: bulk-load toàn bộ 50k từ từ asset vào DB nếu chưa có.
  /// - Các ngôn ngữ khác: lazy fetch từng batch từ network khi cần.
  Future<void> syncIfNeeded(String langCode, {bool isPremium = false}) async {
    if (!isSupported(langCode)) return;

    // Retry enrich các từ chưa hoàn tất (app đóng giữa chừng)
    enrichPendingWords(langCode).ignore();

    final isEnglish = langCode.startsWith('en');
    final isChinese = langCode.startsWith('zh');

    if (isEnglish) {
      // English: từ vựng đã được bundle sẵn trong seed DB (assets/databases/en_seed.db).
      // Database.dart copy file này vào app documents khi cài lần đầu → ~47k từ có ngay.
      // Flag 'english_init_done_*' để tránh re-init không cần thiết:
      //   - Fresh install: seed DB đã có ≥1000 từ → chỉ set flag, return.
      //   - User cũ (DB < 1000 từ từ batch cũ): bulk-load lại từ asset.
      final prefs = await SharedPreferences.getInstance();
      final initDone = prefs.getBool('english_init_done_$langCode') ?? false;
      if (!initDone) {
        final total = await _db.wordDao.countWordsForLang(langCode);
        if (total >= 1000) {
          // Seed DB đã populate đầy đủ — chỉ đánh dấu flag
          await prefs.setBool('english_init_done_$langCode', true);
        } else {
          // User cũ hoặc DB bị mất → xóa dữ liệu cũ, bulk-load lại từ asset
          await _db.progressDao.deleteAllProgress(langCode);
          await _db.wordDao.deleteAllWords(langCode);
          await _initEnglishWordList(langCode);
        }
      }

      // One-time migration: sửa mảnh contraction trong DB hiện tại
      // "didn" → "didn't", giữ nguyên progress nếu đã học
      final cleanupDone =
          prefs.getBool('english_cleanup_v1_$langCode') ?? false;
      if (!cleanupDone) {
        await _fixEnglishContractions(langCode);
        await prefs.setBool('english_cleanup_v1_$langCode', true);
      }

      // Giới hạn từ cho free user / unlock khi nâng cấp Premium
      // Logic đơn giản: đếm 'new' words, tự sửa nếu thiếu hoặc thừa — không cần flag
      if (isPremium) {
        // Premium: unlock tất cả từ còn lại
        await _db.progressDao.insertMissingProgressRows(langCode);
      } else {
        // Free: đảm bảo có đúng kFreeEnglishWordLimit từ 'new'
        final newCount = await _db.progressDao.countNewWords(langCode);
        if (newCount < kFreeEnglishWordLimit) {
          // Thiếu → restore thêm cho đủ (insert có giới hạn, không insert 47k)
          await _db.progressDao.insertMissingProgressRowsLimited(
              langCode, kFreeEnglishWordLimit - newCount);
        } else if (newCount > kFreeEnglishWordLimit) {
          // Thừa → xóa bớt
          await _db.progressDao.deleteNewProgressBeyondLimit(
              langCode, kFreeEnglishWordLimit);
        }
      }

      return;
    }

    if (isChinese) {
      // Chinese: bundle sẵn zh_seed.txt trong assets — load ngay khi install,
      // không cần mạng. Sau đó lazy fetch thêm từ network qua frekwencja.
      final prefs = await SharedPreferences.getInstance();
      final initDone = prefs.getBool('zh_seed_init_done_$langCode') ?? false;
      if (!initDone) {
        await _db.progressDao.deleteAllProgress(langCode);
        await _db.wordDao.deleteAllWords(langCode);
        await prefs.remove('vocab_offset_$langCode');
        await _initChineseWordList(langCode);
        await prefs.setBool('zh_seed_init_done_$langCode', true);
      }
      // Tiếp tục fetch thêm từ network nếu còn ít từ
    }

    final source = await VocabSyncService.getVocabSource();

    // Non-English: lazy fetch theo threshold
    final prefs = await SharedPreferences.getInstance();
    final autoFetch = prefs.getBool('vocab_auto_fetch') ?? true;
    if (!autoFetch) return;

    final maxWords = maxWordsForSource(source);
    var total = await _db.wordDao.countWordsForLang(langCode);
    if (total >= maxWords) return;

    // Auto-reset nếu batch trước bị filter quá nghiêm → rất ít từ được lưu
    // (VD: zh-CN với filter cũ word.length < 2 → chỉ lưu được vài từ đa ký tự)
    if (!isChinese) {
      final offset = prefs.getInt('vocab_offset_$langCode') ?? 0;
      if (offset > 0 && total < kSyncThreshold) {
        await _db.progressDao.deleteAllProgress(langCode);
        await _db.wordDao.deleteAllWords(langCode);
        await prefs.setInt('vocab_offset_$langCode', 0);
        total = 0;
      }
    }

    final newWords = await _db.progressDao.getNewWords(
        langCode, limit: kSyncThreshold + 1);
    if (newWords.length >= kSyncThreshold) return;

    await _fetchNextBatch(langCode);
  }

  /// Retry enrich các từ có definition = NULL (do app đóng hoặc API fail lần trước)
  Future<void> enrichPendingWords(String langCode) async {
    final unenriched = await _db.wordDao.getUnenrichedWords(langCode);
    if (unenriched.isEmpty) return;

    final words = unenriched.map((w) => w.word).toList();
    await _enrichDefinitions(langCode, words);
  }

  /// Enrich definition cho một từ duy nhất (on-demand từ FlashcardCard)
  /// Trả về Word đã được cập nhật, hoặc null nếu không tìm thấy
  Future<Word?> enrichSingleWord(String word, String langCode) async {
    final key = '$word|$langCode';
    if (_enrichingWords.contains(key)) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _db.wordDao.getWord(word, langCode);
    }

    _enrichingWords.add(key);
    final freeDictApiCode = kFreeDictApiLangCodes[langCode];
    final wiktCode = kWiktionaryLangCode[langCode];

    try {
      if (langCode.startsWith('zh')) {
        // Chinese: Pinyin offline (lpinyin) + Wiktionary definition
        await _enrichChinese(word, langCode);
      } else if (freeDictApiCode != null && wiktCode != null) {
        // Dual-source: dictionaryapi.dev (phonetic/audio/pos) + Wiktionary (definition/example)
        await _enrichDualSource(word, langCode, freeDictApiCode, wiktCode);
      } else if (wiktCode != null) {
        await _enrichWiktionary(word, langCode, wiktCode);
      } else {
        _enrichingWords.remove(key);
        return null;
      }
    } catch (_) {
      _enrichingWords.remove(key);
      return null;
    }

    _enrichingWords.remove(key);
    return _db.wordDao.getWord(word, langCode);
  }

  /// Fetch batch tiếp theo ngay lập tức (gọi từ Settings — có await, hiện loading)
  /// [isPremium]: free English user không được fetch thêm (giới hạn kFreeEnglishWordLimit)
  Future<void> fetchNextBatchManual(String langCode, {bool isPremium = false}) async {
    if (!isSupported(langCode)) return;
    // Free English: từ đã có sẵn trong seed DB — không fetch thêm qua network
    if (langCode.startsWith('en') && !isPremium) return;
    await _fetchNextBatch(langCode);
  }

  /// Xóa toàn bộ từ (mọi source) + toàn bộ progress + reset offset
  /// Sau đó re-init (English: bulk từ asset / các ngôn ngữ khác: fetch batch đầu)
  Future<void> resetVocabLibrary(String langCode) async {
    if (!isSupported(langCode)) return;

    await _db.progressDao.deleteAllProgress(langCode);
    await _db.wordDao.deleteAllWords(langCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vocab_offset_$langCode');
    await prefs.remove('english_init_done_$langCode'); // cho phép re-init

    final isEnglish = langCode.startsWith('en');

    if (isEnglish) {
      await _initEnglishWordList(langCode);
    } else {
      await _fetchNextBatch(langCode);
    }
  }

  /// Reset offset → fetch lại từ đầu (dùng trong debug)
  Future<void> resetAndSync(String langCode) async {
    if (!isSupported(langCode)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vocab_offset_$langCode');
    await _fetchNextBatch(langCode);
  }

  static bool isSupported(String langCode) =>
      kFrequencyListUrls.containsKey(langCode) ||
      kHermitDaveUrls.containsKey(langCode);

  /// Lấy nguồn từ vựng đang dùng từ SharedPreferences
  static Future<VocabSource> getVocabSource() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('vocab_source');
    if (raw == VocabSource.hermitDave.name) return VocabSource.hermitDave;
    return VocabSource.frekwencja;
  }

  /// Lưu nguồn từ vựng vào SharedPreferences
  static Future<void> setVocabSource(VocabSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vocab_source', source.name);
  }

  /// Đổi nguồn từ vựng, xóa toàn bộ từ hiện tại, fetch lại batch đầu tiên
  Future<void> resetVocabLibraryWithSource(
      String langCode, VocabSource newSource) async {
    await setVocabSource(newSource);
    await resetVocabLibrary(langCode);
  }

  // ── Core logic ───────────────────────────────────────────

  /// Migration một lần: phục hồi mảnh contraction trong DB về dạng đúng.
  /// VD: row "didn" → xóa đi, thêm "didn't" (giữ nguyên progress đã học).
  Future<void> _fixEnglishContractions(String langCode) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final entry in _enContractionFix.entries) {
      final bad = entry.key;
      final correct = entry.value;

      // Chỉ xử lý nếu form sai thực sự tồn tại trong DB
      final badWord = await _db.wordDao.getWord(bad, langCode);
      if (badWord == null) continue;

      // Lấy progress hiện tại (để preserve nếu đã học)
      final badProgress = await _db.progressDao.getProgress(bad, langCode);

      // Xóa form sai
      await _db.wordDao.deleteBadWords(langCode, {bad});
      await _db.progressDao.deleteProgressBatch(langCode, {bad});

      // Thêm form đúng nếu chưa có
      final alreadyExists = await _db.wordDao.getWord(correct, langCode);
      if (alreadyExists != null) continue;

      await _db.wordDao.insertWord(WordsCompanion(
        word: Value(correct),
        langCode: Value(langCode),
        source: const Value('remote'),
        cachedAt: Value(now),
      ));

      // Kế thừa toàn bộ progress (interval, ease, status...) nếu đã học
      await _db.progressDao.upsertProgress(WordProgressCompanion(
        word: Value(correct),
        langCode: Value(langCode),
        status: Value(badProgress?.status ?? 'new'),
        reviewCount: Value(badProgress?.reviewCount ?? 0),
        correctCount: Value(badProgress?.correctCount ?? 0),
        easeFactor: Value(badProgress?.easeFactor ?? 2.5),
        interval: Value(badProgress?.interval ?? 1),
        nextReview: Value(badProgress?.nextReview),
        lastSeen: Value(badProgress?.lastSeen),
      ));
    }
  }

  /// Bulk-load toàn bộ danh sách từ English từ asset vào DB.
  /// Dùng batch insert chia chunk để tránh OOM trên thiết bị yếu.
  /// Chỉ chạy 1 lần (khi DB còn trống), sau đó từ vựng luôn có sẵn offline.
  Future<void> _initEnglishWordList(String langCode) async {
    final raw = await rootBundle.loadString('assets/wordlists/en_50k.txt');
    final allWords = _parseFullList(raw, langCode);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const chunkSize = 500;
    for (var i = 0; i < allWords.length; i += chunkSize) {
      final chunk = allWords.skip(i).take(chunkSize).toList();

      await _db.wordDao.insertWords(chunk.map((w) => WordsCompanion(
            word: Value(w),
            langCode: Value(langCode),
            source: const Value('remote'),
            cachedAt: Value(now),
          )).toList());

      await _db.progressDao.upsertProgressBatch(chunk.map((w) => WordProgressCompanion(
            word: Value(w),
            langCode: Value(langCode),
            status: const Value('new'),
          )).toList());
    }

    // Đánh dấu đã init đầy đủ (để syncIfNeeded không chạy lại)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('english_init_done_$langCode', true);
  }

  /// Bulk-load danh sách từ Chinese từ asset bundled (zh_seed.txt) vào DB.
  /// Chạy 1 lần khi cài app, đảm bảo có từ offline ngay không cần mạng.
  /// Sau đó lazy fetch thêm từ network qua frekwencja/hermitDave như bình thường.
  Future<void> _initChineseWordList(String langCode) async {
    final raw = await rootBundle.loadString('assets/wordlists/zh_seed.txt');
    final allWords = _parseFullList(raw, langCode);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Pre-populate romanization (Pinyin) ngay khi insert — không cần chờ enrich
    await _db.wordDao.insertWords(allWords.map((w) {
      final pinyin = PinyinHelper.getPinyin(
        w,
        separator: ' ',
        format: PinyinFormat.WITH_TONE_MARK,
      ).trim();
      return WordsCompanion(
        word: Value(w),
        langCode: Value(langCode),
        source: const Value('local'),
        cachedAt: Value(now),
        romanization: Value(pinyin.isNotEmpty ? pinyin : null),
      );
    }).toList());

    await _db.progressDao.upsertProgressBatch(allWords.map((w) => WordProgressCompanion(
          word: Value(w),
          langCode: Value(langCode),
          status: const Value('new'),
        )).toList());
  }

  Future<void> _fetchNextBatch(String langCode) async {
    final source = await VocabSyncService.getVocabSource();
    final prefs = await SharedPreferences.getInstance();
    final offset = prefs.getInt('vocab_offset_$langCode') ?? 0;

    try {
      String rawContent;
      final isEnglish = langCode.startsWith('en');

      // Tiếng Anh + Hermit Dave → đọc từ asset bundled (không cần mạng)
      if (isEnglish && source == VocabSource.hermitDave) {
        rawContent =
            await rootBundle.loadString('assets/wordlists/en_50k.txt');
      } else {
        // Các ngôn ngữ khác → tải từ mạng
        final urlMap = source == VocabSource.hermitDave
            ? kHermitDaveUrls
            : kFrequencyListUrls;
        final url = urlMap[langCode];
        if (url == null) return;

        final response = await _dio.get<String>(
          url,
          options: Options(responseType: ResponseType.plain),
        );
        if (response.statusCode != 200 || response.data == null) return;
        rawContent = response.data!;
      }

      // Parse toàn bộ file → danh sách từ đã lọc (thứ tự tần suất)
      final allFiltered = _parseFullList(rawContent, langCode);

      // Lấy slice batch tiếp theo từ offset
      if (offset >= allFiltered.length) return; // Đã hết danh sách
      final batch = allFiltered.skip(offset).take(kBatchSize).toList();

      // Insert vào DB, trả về số từ thực sự mới
      final inserted = await _insertWords(langCode, batch);

      // Lưu offset mới (offset + số từ đã xử lý trong batch, kể cả từ đã có)
      await prefs.setInt('vocab_offset_$langCode', offset + batch.length);

      // Enrich definition chạy nền — không block việc load session
      if (inserted.isNotEmpty) {
        _enrichDefinitions(langCode, inserted).ignore();
      }
    } catch (_) {
      // Lỗi network → bỏ qua, sẽ thử lại lần sau khi syncIfNeeded được gọi
    }
  }

  /// Wrapper công khai chỉ dùng cho unit test
  // ignore: invalid_use_of_visible_for_testing_member
  List<String> parseFullListForTest(String raw, String langCode) =>
      _parseFullList(raw, langCode);

  /// Parse toàn bộ file → list từ đã qua bộ lọc, giữ nguyên thứ tự tần suất
  List<String> _parseFullList(String raw, String langCode) {
    final isEnglish = langCode.startsWith('en');
    final isChinese = langCode.startsWith('zh');
    final stopwords = _stopwordsForLang(langCode);
    final result = <String>[];

    for (final line in raw.split('\n')) {
      final parts = line.trim().split(' ');
      if (parts.isEmpty || parts[0].isEmpty) continue;
      final word = parts[0].trim().toLowerCase();

      if (isEnglish) {
        // Sửa mảnh contraction TRƯỚC các filter khác
        // (vd: "didn" → "didn't") — dạng đúng có dấu ' nên phải add trực tiếp
        final fixed = _enContractionFix[word];
        if (fixed != null) {
          result.add(fixed);
          continue;
        }
        if (word.length < 4) continue;
        if (!RegExp(r'^[a-z]+$').hasMatch(word)) continue;
      } else {
        // Tiếng Trung: cho phép từ đơn ký tự nội dung (人好大小...)
        final minLen = isChinese ? 1 : 2;
        if (word.length < minLen) continue;
        if (RegExp(r'[\d\s]').hasMatch(word)) continue;

        // Script filter — loại bỏ từ Latin lẫn vào corpus không phải Latin
        final scriptPattern = _scriptPatternFor(langCode);
        if (scriptPattern != null && !scriptPattern.hasMatch(word)) continue;
      }

      // Lọc stopwords — áp dụng cho tất cả ngôn ngữ
      if (stopwords.contains(word)) continue;

      result.add(word);
    }
    return result;
  }

  /// Insert batch vào Words + WordProgress. Trả về list từ thực sự mới (chưa có trong DB)
  Future<List<String>> _insertWords(String langCode, List<String> words) async {
    final inserted = <String>[];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final word in words) {
      final existing = await _db.wordDao.getWord(word, langCode);
      if (existing != null) continue; // đã có → bỏ qua

      await _db.wordDao.insertWord(WordsCompanion(
        word: Value(word),
        langCode: Value(langCode),
        source: const Value('remote'),
        cachedAt: Value(now),
        // phonetic, definition, example: null → sẽ enrich sau
      ));

      await _db.progressDao.upsertProgress(WordProgressCompanion(
        word: Value(word),
        langCode: Value(langCode),
        status: const Value('new'),
      ));

      inserted.add(word);
    }
    return inserted;
  }

  /// Enrich definition cho từng từ:
  ///   English (en-US/en-GB) → dual-source: dictionaryapi.dev + Wiktionary
  ///   Chinese              → lpinyin (offline) + Wiktionary
  ///   Tất cả ngôn ngữ khác → Wiktionary REST API (definition + IPA wikitext)
  ///
  /// Lưu ý phonetic support qua Wiktionary IPA:
  ///   ✓ Có IPA text: fr, de, ko, ja (dùng {{IPA|lang|...}})
  ///   ~ Partial: ru (regional variants)
  ///   ✗ Không có: es, it, ar, pt, hi, tr (dùng {{lang-pr|...}} không chứa IPA text)
  Future<void> _enrichDefinitions(String langCode, List<String> words) async {
    final freeDictApiCode = kFreeDictApiLangCodes[langCode];
    final wiktCode = kWiktionaryLangCode[langCode];

    for (final word in words) {
      final key = '$word|$langCode';
      if (_enrichingWords.contains(key)) continue;
      _enrichingWords.add(key);

      try {
        if (langCode.startsWith('zh')) {
          await _enrichChinese(word, langCode);
        } else if (freeDictApiCode != null && wiktCode != null) {
          await _enrichDualSource(word, langCode, freeDictApiCode, wiktCode);
        } else if (wiktCode != null) {
          await _enrichWiktionary(word, langCode, wiktCode);
        }
        // Throttle — tránh rate-limit API
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (_) {
        // Lỗi từng từ → tiếp tục, retry sau qua enrichPendingWords()
      } finally {
        _enrichingWords.remove(key);
      }
    }
  }

  /// Dual-source: gọi FreeDictApi + Wiktionary song song
  ///   FreeDictApi → phonetic, audio (chính xác hơn)
  ///   Wiktionary  → definition, example bằng tiếng Anh (hữu ích hơn cho người học)
  Future<void> _enrichDualSource(
      String word, String langCode, String apiLangCode, String wiktCode) async {
    // Gọi hai API song song
    final dictFuture =
        _freeDictApi.lookup(word, apiLangCode: apiLangCode);
    final wiktFuture = _wiktionaryApi.lookup(word, wiktCode);

    final dictEntry = await dictFuture;
    final wiktEntry = await wiktFuture;

    // Ưu tiên Wiktionary cho definition (tiếng Anh, dễ hiểu hơn cho người học)
    final definition = (wiktEntry != null && wiktEntry.definition.isNotEmpty)
        ? wiktEntry.definition
        : (dictEntry != null && dictEntry.definition.isNotEmpty
            ? dictEntry.definition
            : null);

    // Lưu '' khi cả hai nguồn đều fail → đánh dấu "đã thử, không tìm thấy"
    // definition IS NULL = chưa thử; definition = '' = đã thử, không có kết quả
    // Điều này ngăn enrichPendingWords retry mãi mãi các từ không bao giờ có định nghĩa
    if (definition == null) {
      await _db.wordDao.updateWordEnrichment(
        word, langCode,
        definition: '',
        phonetic: (dictEntry != null && dictEntry.phoneticUS.isNotEmpty)
            ? dictEntry.phoneticUS
            : null,
        partOfSpeechValue: (dictEntry != null && dictEntry.partOfSpeech.isNotEmpty)
            ? dictEntry.partOfSpeech
            : null,
      );
      return;
    }

    // Phonetic: ưu tiên FreeDictApi, fallback Wiktionary
    final phonetic =
        (dictEntry != null && dictEntry.phoneticUS.isNotEmpty)
            ? dictEntry.phoneticUS
            : (wiktEntry != null && wiktEntry.phonetic.isNotEmpty
                ? wiktEntry.phonetic
                : null);

    // Part of speech: ưu tiên Wiktionary (chuẩn hơn), fallback FreeDictApi
    final pos = (wiktEntry != null && wiktEntry.pos.isNotEmpty)
        ? wiktEntry.pos
        : (dictEntry != null && dictEntry.partOfSpeech.isNotEmpty
            ? dictEntry.partOfSpeech
            : null);

    final example =
        (wiktEntry != null && wiktEntry.example.isNotEmpty)
            ? wiktEntry.example
            : null;

    await _db.wordDao.updateWordEnrichment(
      word,
      langCode,
      phonetic: phonetic,
      audioUs: dictEntry != null && dictEntry.audioUS.isNotEmpty
          ? dictEntry.audioUS
          : null,
      audioUk: dictEntry != null && dictEntry.audioUK.isNotEmpty
          ? dictEntry.audioUK
          : null,
      partOfSpeechValue: pos,
      definition: definition,
      example: example,
    );
  }

  Future<void> _enrichWiktionary(
      String word, String langCode, String wiktCode) async {
    final result = await _wiktionaryApi.lookup(word, wiktCode);

    // Wiktionary không có entry → lưu '' để đánh dấu "đã thử, không tìm thấy"
    // Tránh enrichPendingWords retry mãi các từ hiếm/không có trong Wiktionary
    if (result == null) {
      await _db.wordDao.updateWordEnrichment(word, langCode, definition: '');
      return;
    }

    await _db.wordDao.updateWordEnrichment(
      word,
      langCode,
      phonetic: result.phonetic.isNotEmpty ? result.phonetic : null,
      partOfSpeechValue: result.pos.isNotEmpty ? result.pos : null,
      definition: result.definition,
      example: result.example.isNotEmpty ? result.example : null,
    );
  }

  /// Chinese enrichment:
  ///   - Pinyin: generate offline bằng lpinyin (luôn có, không cần mạng)
  ///   - Definition: Wiktionary (best-effort — đơn ký tự thường có, từ ghép có thể thiếu)
  Future<void> _enrichChinese(String word, String langCode) async {
    // Pinyin luôn có — generate offline
    final pinyin = PinyinHelper.getPinyin(
      word,
      separator: ' ',
      format: PinyinFormat.WITH_TONE_MARK,
    ).trim();

    // Definition + example từ Wiktionary (best-effort)
    String? definition;
    String? pos;
    String? example;

    final wiktCode = kWiktionaryLangCode[langCode];
    if (wiktCode != null) {
      try {
        final result = await _wiktionaryApi.lookup(word, wiktCode);
        if (result != null && result.definition.isNotEmpty) {
          definition = result.definition;
          pos = result.pos.isNotEmpty ? result.pos : null;
          example = result.example.isNotEmpty ? result.example : null;
        }
      } catch (_) {
        // Wiktionary thất bại → vẫn lưu Pinyin bên dưới
      }
    }

    // Lưu '' khi Wiktionary không có entry cho từ ghép này
    // (Wiktionary tiếng Anh có coverage hạn chế cho từ ghép tiếng Trung)
    // definition = null → Value.absent() → field không update → retry mãi mãi
    // definition = ''  → Value('') → đánh dấu "đã thử" → không retry nữa
    await _db.wordDao.updateWordEnrichment(
      word,
      langCode,
      romanization: pinyin.isNotEmpty ? pinyin : null,
      partOfSpeechValue: pos,
      definition: definition ?? '',
      example: example,
    );
  }
}
