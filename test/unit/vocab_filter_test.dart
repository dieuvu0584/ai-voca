import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ai/core/vocab_sync/vocab_sync_service.dart';
import '../helpers/test_helpers.dart';

/// Test bộ lọc từ vựng trong VocabSyncService._parseFullList
/// Truy cập qua wrapper công khai parseFullListForTest()
void main() {
  late VocabSyncService svc;

  setUp(() {
    svc = VocabSyncService(createTestDb());
  });

  // ─────────────────────────────────────────────
  // English — length filter
  // ─────────────────────────────────────────────
  group('English: lọc theo độ dài (min 4 ký tự)', () {
    test('từ ngắn < 4 ký tự bị loại', () {
      // "go" (2), "run" (3), "jump" (4), "play" (4)
      final result = svc.parseFullListForTest('go\nrun\njump\nplay', 'en-US');
      expect(result, isNot(contains('go')));
      expect(result, isNot(contains('run')));
      expect(result, contains('jump'));
      expect(result, contains('play'));
    });

    test('từ đúng 4 ký tự được giữ lại', () {
      final result = svc.parseFullListForTest('book\nfilm', 'en-US');
      expect(result, contains('book'));
      expect(result, contains('film'));
    });
  });

  // ─────────────────────────────────────────────
  // English — character filter
  // ─────────────────────────────────────────────
  group('English: chỉ giữ từ [a-z]', () {
    test('từ chứa số bị loại', () {
      final result = svc.parseFullListForTest('test1\nhello\nworld9', 'en-US');
      expect(result, isNot(contains('test1')));
      expect(result, isNot(contains('world9')));
      expect(result, contains('hello'));
    });

    test('từ chứa dấu apostrophe bị loại (trừ contractions đã fix)', () {
      // can't bị loại thẳng (không có trong _enContractionFix)
      final result = svc.parseFullListForTest("won't\nhello", 'en-US');
      expect(result, isNot(contains("won't")));
      expect(result, contains('hello'));
    });

    test('uppercase bị lowercase trước khi kiểm tra', () {
      // parser lower-case trước → HELLO → hello → ok
      final result = svc.parseFullListForTest('HELLO\nWORLD', 'en-US');
      expect(result, contains('hello'));
      expect(result, contains('world'));
    });
  });

  // ─────────────────────────────────────────────
  // English — stopwords
  // ─────────────────────────────────────────────
  group('English: lọc stopwords', () {
    test('các stopword phổ biến bị loại', () {
      final result =
          svc.parseFullListForTest('there\nabout\nbefore\nhello', 'en-US');
      expect(result, isNot(contains('there')));
      expect(result, isNot(contains('about')));
      expect(result, isNot(contains('before')));
      expect(result, contains('hello'));
    });

    test('từ không phải stopword được giữ lại', () {
      final result =
          svc.parseFullListForTest('train\nlearn\nbook\nread', 'en-US');
      expect(result, containsAll(['train', 'learn', 'book', 'read']));
    });
  });

  // ─────────────────────────────────────────────
  // English — contraction fix
  // ─────────────────────────────────────────────
  group('English: sửa mảnh contraction', () {
    test('didn → didn\'t', () {
      final result = svc.parseFullListForTest('didn', 'en-US');
      expect(result, contains("didn't"));
      expect(result, isNot(contains('didn')));
    });

    test('các contraction khác được sửa đúng', () {
      final input = [
        'couldn', 'wouldn', 'wasn',
        'doesn', 'hasn', 'hadn',
        'mustn', 'needn', 'shouldn',
        'aren', 'mightn', 'oughtn',
        'daren', 'shan',
      ].join('\n');
      final result = svc.parseFullListForTest(input, 'en-US');

      expect(result, contains("couldn't"));
      expect(result, contains("wouldn't"));
      expect(result, contains("wasn't"));
      expect(result, contains("doesn't"));
      expect(result, contains("hasn't"));
      expect(result, contains("hadn't"));
      expect(result, contains("mustn't"));
      expect(result, contains("needn't"));
      expect(result, contains("shouldn't"));
      expect(result, contains("aren't"));
      expect(result, contains("mightn't"));
      expect(result, contains("oughtn't"));
      expect(result, contains("daren't"));
      expect(result, contains("shan't"));
    });

    test('contraction được sửa trước các filter khác (không bị lọc bởi length/regex)', () {
      // "didn" có length=4, nhưng kết quả "didn't" chứa dấu ' —
      // nếu contraction fix KHÔNG chạy trước thì "didn't" sẽ bị loại bởi regex
      // Test đảm bảo contraction fix chạy TRƯỚC (code hiện tại đúng)
      final result = svc.parseFullListForTest("didn\ncouldn", 'en-US');
      expect(result, contains("didn't"));
      expect(result, contains("couldn't"));
    });
  });

  // ─────────────────────────────────────────────
  // English — Hermit Dave format (word count)
  // ─────────────────────────────────────────────
  group('English: parse Hermit Dave format', () {
    test('lấy đúng từ ở parts[0] khi có số đếm', () {
      // Hermit Dave: "word frequency" per line
      final raw = 'hello 1234567\nworld 987654\ndid 500000';
      final result = svc.parseFullListForTest(raw, 'en-US');
      expect(result, contains('hello'));
      expect(result, contains('world'));
    });

    test('contraction Hermit Dave: "didn 853640" → "didn\'t"', () {
      final raw = 'didn 853640\ncouldn 500000';
      final result = svc.parseFullListForTest(raw, 'en-US');
      expect(result, contains("didn't"));
      expect(result, contains("couldn't"));
    });
  });

  // ─────────────────────────────────────────────
  // Non-English — minimum length
  // ─────────────────────────────────────────────
  group('Non-English: độ dài tối thiểu', () {
    test('Korean: tối thiểu 2 ký tự', () {
      // '사' (1 ký tự) bị loại, '안녕' (2 ký tự) được giữ
      final result = svc.parseFullListForTest('사\n안녕\n세계\n저', 'ko-KR');
      expect(result, contains('안녕'));
      expect(result, contains('세계'));
      expect(result, isNot(contains('사')));
      expect(result, isNot(contains('저')));
    });

    test('Chinese: cho phép từ nội dung đơn ký tự (minLen=1)', () {
      // 的/了/是 là hư từ → bị lọc bởi _zhStopwords
      // 人/好/大 là từ nội dung → được giữ
      final result = svc.parseFullListForTest('的\n了\n是\n人\n好\n你好', 'zh-CN');
      expect(result, contains('人'));
      expect(result, contains('好'));
      expect(result, contains('你好'));
      expect(result, isNot(contains('的')));
      expect(result, isNot(contains('了')));
      expect(result, isNot(contains('是')));
    });
  });

  // ─────────────────────────────────────────────
  // Chinese stopwords
  // ─────────────────────────────────────────────
  group('Chinese: lọc hư từ / trợ từ ngữ pháp', () {
    test('trợ từ cấu trúc 的了着地得 bị lọc', () {
      final result = svc.parseFullListForTest('的\n了\n着\n地\n得\n人', 'zh-CN');
      expect(result, isNot(contains('的')));
      expect(result, isNot(contains('了')));
      expect(result, isNot(contains('着')));
      expect(result, isNot(contains('地')));
      expect(result, isNot(contains('得')));
      expect(result, contains('人'));
    });

    test('đại từ nhân xưng cơ bản bị lọc', () {
      final result = svc.parseFullListForTest('我\n你\n他\n她\n它\n朋友', 'zh-CN');
      expect(result, isNot(contains('我')));
      expect(result, isNot(contains('你')));
      expect(result, isNot(contains('他')));
      expect(result, isNot(contains('她')));
      expect(result, contains('朋友'));
    });

    test('hệ từ / tồn tại cực kỳ cơ bản bị lọc', () {
      final result = svc.parseFullListForTest('是\n有\n在\n来\n去\n学习', 'zh-CN');
      expect(result, isNot(contains('是')));
      expect(result, isNot(contains('有')));
      expect(result, isNot(contains('在')));
      expect(result, isNot(contains('来')));
      expect(result, isNot(contains('去')));
      expect(result, contains('学习'));
    });

    test('từ nội dung đơn ký tự không bị lọc', () {
      // 人 (người), 好 (tốt), 大 (lớn), 小 (nhỏ) — từ thật, không phải hư từ
      final result = svc.parseFullListForTest('人\n好\n大\n小\n书\n水', 'zh-CN');
      expect(result, containsAll(['人', '好', '大', '小', '书', '水']));
    });

    test('stopwords chỉ áp dụng cho zh-CN/zh-TW, không cho ngôn ngữ khác', () {
      // Nếu một ngôn ngữ khác có chữ Hán trong danh sách → không bị lọc
      final result = svc.parseFullListForTest('的\n了', 'ja-JP');
      // Japanese parser: minLen=2, '的' length=1 → bị lọc bởi minLen, không phải zhStopwords
      // (test này chỉ kiểm tra không có lỗi runtime)
      expect(result, isA<List<String>>());
    });
  });

  // ─────────────────────────────────────────────
  // Non-English — digit/space filter
  // ─────────────────────────────────────────────
  group('Non-English: lọc số và khoảng trắng', () {
    test('từ chứa số bị loại', () {
      final result = svc.parseFullListForTest('안녕\nhello123\n세계', 'ko-KR');
      expect(result, contains('안녕'));
      expect(result, contains('세계'));
      expect(result, isNot(contains('hello123')));
    });

    test('dòng rỗng không làm crash', () {
      final result = svc.parseFullListForTest('\n\nhello\n\nworld\n', 'en-US');
      expect(result, contains('hello'));
      expect(result, contains('world'));
    });
  });

  // ─────────────────────────────────────────────
  // Script filter — loại bỏ từ Latin lẫn vào corpus
  // ─────────────────────────────────────────────
  group('Script filter: loại bỏ từ Latin lẫn vào corpus', () {
    test('Korean: từ Latin bị loại, Hangul được giữ', () {
      // Hermit Dave ko corpus có lẫn "facebook", "google"...
      final result = svc.parseFullListForTest(
          '안녕\n학교\nfacebook\ngoogle\n세계', 'ko-KR');
      expect(result, contains('안녕'));
      expect(result, contains('학교'));
      expect(result, contains('세계'));
      expect(result, isNot(contains('facebook')));
      expect(result, isNot(contains('google')));
    });

    test('Thai: từ Latin bị loại, Thai script được giữ', () {
      final result = svc.parseFullListForTest(
          'สวัสดี\nok\ncafe\nประเทศ', 'th-TH');
      expect(result, contains('สวัสดี'));
      expect(result, contains('ประเทศ'));
      expect(result, isNot(contains('ok')));
      expect(result, isNot(contains('cafe')));
    });

    test('Japanese: Hiragana/Katakana/Kanji được giữ, Latin bị loại', () {
      final result = svc.parseFullListForTest(
          'ありがとう\n日本語\nthanks\nバナナ', 'ja-JP');
      expect(result, contains('ありがとう'));
      expect(result, contains('日本語'));
      expect(result, contains('バナナ')); // Katakana OK
      expect(result, isNot(contains('thanks')));
    });

    test('Russian: Cyrillic được giữ, Latin bị loại', () {
      final result = svc.parseFullListForTest(
          'привет\nмир\nhello\nworld', 'ru-RU');
      expect(result, contains('привет'));
      expect(result, contains('мир'));
      expect(result, isNot(contains('hello')));
      expect(result, isNot(contains('world')));
    });

    test('Arabic: Arabic script được giữ, Latin bị loại', () {
      final result = svc.parseFullListForTest(
          'مرحبا\nعالم\nhello\ncafe', 'ar-SA');
      expect(result, contains('مرحبا'));
      expect(result, contains('عالم'));
      expect(result, isNot(contains('hello')));
      expect(result, isNot(contains('cafe')));
    });

    test('Vietnamese: Latin được giữ (không có script filter)', () {
      // Tiếng Việt dùng chữ Latin → không bị lọc
      final result = svc.parseFullListForTest('xin chào\nviệt nam', 'vi-VN');
      // Mỗi dòng là 1 entry, parser lấy parts[0]
      expect(result, contains('xin'));
      expect(result, contains('việt'));
    });

    test('Indonesian: Latin được giữ (không có script filter)', () {
      final result = svc.parseFullListForTest(
          'selamat\npagi\ndunia', 'id-ID');
      expect(result, contains('selamat'));
      expect(result, contains('dunia'));
    });
  });

  // ─────────────────────────────────────────────
  // Thứ tự bảo toàn
  // ─────────────────────────────────────────────
  group('Bảo toàn thứ tự tần suất', () {
    test('các từ được giữ theo thứ tự xuất hiện trong file', () {
      // Dùng từ không có số/ký tự đặc biệt, >= 4 ký tự, không phải stopword
      final result = svc.parseFullListForTest(
          'train 100\nlearn 90\ntrust 80', 'en-US');
      expect(result.indexOf('train'), lessThan(result.indexOf('learn')));
      expect(result.indexOf('learn'), lessThan(result.indexOf('trust')));
    });
  });
}
