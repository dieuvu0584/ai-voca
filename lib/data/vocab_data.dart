class BuiltinWord {
  final String word;
  final String? romanization;
  final String? phonetic;
  final String? phoneticUK;
  final String type;
  final String meaning;
  final String example;

  const BuiltinWord({
    required this.word,
    this.romanization,
    this.phonetic,
    this.phoneticUK,
    required this.type,
    required this.meaning,
    required this.example,
  });
}

const Map<String, List<BuiltinWord>> kBuiltinVocab = {
  'en-US': _englishWords,
  'en-GB': _englishWords,
  'ko-KR': _koreanWords,
  'ja-JP': _japaneseWords,
  'zh-CN': _chineseWords,
  'fr-FR': _frenchWords,
  'de-DE': _germanWords,
  'es-ES': _spanishWords,
  'pt-BR': _portugueseWords,
  'it-IT': _italianWords,
  'ru-RU': _russianWords,
  'th-TH': _thaiWords,
  'vi-VN': _vietnameseWords,
};

const _englishWords = [
  BuiltinWord(word: 'algorithm', phonetic: '/ˈælɡərɪðəm/', type: 'noun', meaning: '🇻🇳 thuật toán', example: 'The sorting algorithm runs in O(n log n).'),
  BuiltinWord(word: 'debug', phonetic: '/diːˈbʌɡ/', type: 'verb', meaning: '🇻🇳 gỡ lỗi', example: 'I spent hours debugging the code.'),
  BuiltinWord(word: 'deploy', phonetic: '/dɪˈplɔɪ/', type: 'verb', meaning: '🇻🇳 triển khai', example: 'We deploy the app every Friday.'),
  BuiltinWord(word: 'repository', phonetic: '/rɪˈpɒzɪtri/', type: 'noun', meaning: '🇻🇳 kho lưu trữ', example: 'Push your code to the repository.'),
  BuiltinWord(word: 'framework', phonetic: '/ˈfreɪmwɜːrk/', type: 'noun', meaning: '🇻🇳 khung làm việc, nền tảng', example: 'Flutter is a UI framework.'),
  BuiltinWord(word: 'persevere', phonetic: '/ˌpɜːrsɪˈvɪər/', type: 'verb', meaning: '🇻🇳 kiên trì, bền bỉ', example: 'She persevered despite many obstacles.'),
  BuiltinWord(word: 'meticulous', phonetic: '/məˈtɪkjʊləs/', type: 'adj', meaning: '🇻🇳 tỉ mỉ, cẩn thận', example: 'He is meticulous about his work.'),
  BuiltinWord(word: 'ubiquitous', phonetic: '/juːˈbɪkwɪtəs/', type: 'adj', meaning: '🇻🇳 có mặt khắp nơi', example: 'Smartphones are ubiquitous in modern life.'),
  BuiltinWord(word: 'pragmatic', phonetic: '/præɡˈmætɪk/', type: 'adj', meaning: '🇻🇳 thực dụng, thực tế', example: 'We need a pragmatic approach to this problem.'),
  BuiltinWord(word: 'optimize', phonetic: '/ˈɒptɪmaɪz/', type: 'verb', meaning: '🇻🇳 tối ưu hóa', example: 'We need to optimize the database queries.'),
  BuiltinWord(word: 'resilient', phonetic: '/rɪˈzɪliənt/', type: 'adj', meaning: '🇻🇳 kiên cường, dẻo dai', example: 'The system must be resilient to failures.'),
  BuiltinWord(word: 'paradigm', phonetic: '/ˈpærədaɪm/', type: 'noun', meaning: '🇻🇳 mô hình, khuôn mẫu', example: 'Object-oriented programming is a paradigm.'),
  BuiltinWord(word: 'iterate', phonetic: '/ˈɪtəreɪt/', type: 'verb', meaning: '🇻🇳 lặp lại', example: 'We iterate through each element in the list.'),
  BuiltinWord(word: 'eloquent', phonetic: '/ˈɛləkwənt/', type: 'adj', meaning: '🇻🇳 hùng biện, lưu loát', example: 'She gave an eloquent speech.'),
  BuiltinWord(word: 'ambiguous', phonetic: '/æmˈbɪɡjuəs/', type: 'adj', meaning: '🇻🇳 mơ hồ, nhập nhằng', example: 'The requirements are ambiguous.'),
  BuiltinWord(word: 'concurrent', phonetic: '/kənˈkɜːrənt/', type: 'adj', meaning: '🇻🇳 đồng thời, song song', example: 'Handle concurrent requests efficiently.'),
  BuiltinWord(word: 'ephemeral', phonetic: '/ɪˈfemərəl/', type: 'adj', meaning: '🇻🇳 phù du, chốc lát', example: 'Social media stories are ephemeral.'),
  BuiltinWord(word: 'comprehensive', phonetic: '/ˌkɒmprɪˈhensɪv/', type: 'adj', meaning: '🇻🇳 toàn diện, đầy đủ', example: 'We need comprehensive test coverage.'),
  BuiltinWord(word: 'mitigate', phonetic: '/ˈmɪtɪɡeɪt/', type: 'verb', meaning: '🇻🇳 giảm nhẹ, xoa dịu', example: 'We must mitigate the security risks.'),
  BuiltinWord(word: 'inherent', phonetic: '/ɪnˈhɪərənt/', type: 'adj', meaning: '🇻🇳 vốn có, bẩm sinh', example: 'There are inherent risks in any investment.'),
];

// Korean: basic vocab + parallel tech words (matching English meanings)
const _koreanWords = [
  // Basic Korean vocabulary
  BuiltinWord(word: '프로그래밍', romanization: 'peurogeuraem-ing', type: 'noun', meaning: '🇻🇳 lập trình', example: '프로그래밍을 배우고 있어요.'),
  BuiltinWord(word: '컴퓨터', romanization: 'keompyuteo', type: 'noun', meaning: '🇻🇳 máy tính', example: '컴퓨터를 켜세요.'),
  BuiltinWord(word: '열심히', romanization: 'yeolsimhi', type: 'adv', meaning: '🇻🇳 chăm chỉ', example: '열심히 공부하세요.'),
  BuiltinWord(word: '공부', romanization: 'gongbu', type: 'noun', meaning: '🇻🇳 học tập', example: '한국어 공부가 재미있어요.'),
  BuiltinWord(word: '사랑', romanization: 'sarang', type: 'noun', meaning: '🇻🇳 tình yêu', example: '사랑해요.'),
  BuiltinWord(word: '친구', romanization: 'chingu', type: 'noun', meaning: '🇻🇳 bạn bè', example: '제일 친한 친구예요.'),
  BuiltinWord(word: '감사합니다', romanization: 'gamsahamnida', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: '도와주셔서 감사합니다.'),
  BuiltinWord(word: '음식', romanization: 'eumsik', type: 'noun', meaning: '🇻🇳 thức ăn', example: '한국 음식을 좋아해요.'),
  BuiltinWord(word: '여행', romanization: 'yeohaeng', type: 'noun', meaning: '🇻🇳 du lịch', example: '여행을 가고 싶어요.'),
  BuiltinWord(word: '학생', romanization: 'haksaeng', type: 'noun', meaning: '🇻🇳 học sinh', example: '저는 학생이에요.'),
  BuiltinWord(word: '선생님', romanization: 'seonsaengnim', type: 'noun', meaning: '🇻🇳 giáo viên, thầy/cô', example: '선생님, 안녕하세요.'),
  BuiltinWord(word: '행복', romanization: 'haengbok', type: 'noun', meaning: '🇻🇳 hạnh phúc', example: '행복하세요!'),
  // Parallel tech/academic words (matching English word meanings)
  BuiltinWord(word: '알고리즘', romanization: 'algorijeum', type: 'noun', meaning: '🇻🇳 thuật toán', example: '이 알고리즘은 효율적입니다.'),
  BuiltinWord(word: '디버그하다', romanization: 'dibeugeuhada', type: 'verb', meaning: '🇻🇳 gỡ lỗi', example: '코드를 디버그하고 있어요.'),
  BuiltinWord(word: '배포하다', romanization: 'baepohada', type: 'verb', meaning: '🇻🇳 triển khai', example: '앱을 매주 배포해요.'),
  BuiltinWord(word: '저장소', romanization: 'jeojangsо', type: 'noun', meaning: '🇻🇳 kho lưu trữ', example: '저장소에 코드를 올려요.'),
  BuiltinWord(word: '프레임워크', romanization: 'peureim-weokeu', type: 'noun', meaning: '🇻🇳 khung làm việc, nền tảng', example: 'Flutter는 UI 프레임워크예요.'),
  BuiltinWord(word: '인내하다', romanization: 'innaehada', type: 'verb', meaning: '🇻🇳 kiên trì, bền bỉ', example: '어려움에도 인내해야 해요.'),
  BuiltinWord(word: '꼼꼼하다', romanization: 'kkokkomhada', type: 'adj', meaning: '🇻🇳 tỉ mỉ, cẩn thận', example: '그는 꼼꼼한 사람이에요.'),
  BuiltinWord(word: '어디에나 있는', romanization: 'eodie-na inneun', type: 'adj', meaning: '🇻🇳 có mặt khắp nơi', example: '스마트폰은 어디에나 있어요.'),
  BuiltinWord(word: '실용적인', romanization: 'siryongjeog-in', type: 'adj', meaning: '🇻🇳 thực dụng, thực tế', example: '실용적인 접근이 필요해요.'),
  BuiltinWord(word: '최적화하다', romanization: 'choejokhwahada', type: 'verb', meaning: '🇻🇳 tối ưu hóa', example: '성능을 최적화해야 해요.'),
  BuiltinWord(word: '회복력 있는', romanization: 'hoeбongnyeok inneun', type: 'adj', meaning: '🇻🇳 kiên cường, dẻo dai', example: '시스템이 회복력 있어야 해요.'),
  BuiltinWord(word: '패러다임', romanization: 'paereodaim', type: 'noun', meaning: '🇻🇳 mô hình, khuôn mẫu', example: '객체지향은 패러다임이에요.'),
  BuiltinWord(word: '반복하다', romanization: 'banbokha-da', type: 'verb', meaning: '🇻🇳 lặp lại', example: '리스트의 각 요소를 반복해요.'),
  BuiltinWord(word: '웅변적인', romanization: 'ungbyeonjeog-in', type: 'adj', meaning: '🇻🇳 hùng biện, lưu loát', example: '그녀는 웅변적인 연설을 했어요.'),
  BuiltinWord(word: '모호한', romanization: 'mohohan', type: 'adj', meaning: '🇻🇳 mơ hồ, nhập nhằng', example: '요구사항이 모호해요.'),
  BuiltinWord(word: '동시의', romanization: 'dongsieui', type: 'adj', meaning: '🇻🇳 đồng thời, song song', example: '동시 요청을 처리해요.'),
  BuiltinWord(word: '덧없는', romanization: 'deos-eomneun', type: 'adj', meaning: '🇻🇳 phù du, chốc lát', example: '소셜 미디어 스토리는 덧없어요.'),
  BuiltinWord(word: '포괄적인', romanization: 'pogwaljeogeun', type: 'adj', meaning: '🇻🇳 toàn diện, đầy đủ', example: '포괄적인 테스트가 필요해요.'),
  BuiltinWord(word: '완화하다', romanization: 'wanhwahada', type: 'verb', meaning: '🇻🇳 giảm nhẹ, xoa dịu', example: '보안 위험을 완화해야 해요.'),
  BuiltinWord(word: '내재된', romanization: 'naejae-doen', type: 'adj', meaning: '🇻🇳 vốn có, bẩm sinh', example: '모든 투자에는 내재된 위험이 있어요.'),
];

// Japanese: basic vocab + parallel tech words
const _japaneseWords = [
  // Basic Japanese vocabulary
  BuiltinWord(word: 'プログラム', romanization: 'puroguramu', type: 'noun', meaning: '🇻🇳 chương trình', example: 'プログラムを書きます。'),
  BuiltinWord(word: '勉強', romanization: 'benkyou', type: 'noun', meaning: '🇻🇳 học tập', example: '毎日勉強しています。'),
  BuiltinWord(word: '友達', romanization: 'tomodachi', type: 'noun', meaning: '🇻🇳 bạn bè', example: '友達と遊びます。'),
  BuiltinWord(word: '食べ物', romanization: 'tabemono', type: 'noun', meaning: '🇻🇳 thức ăn', example: '日本の食べ物が好きです。'),
  BuiltinWord(word: '今日', romanization: 'kyou', type: 'noun', meaning: '🇻🇳 hôm nay', example: '今日はいい天気です。'),
  BuiltinWord(word: 'ありがとう', romanization: 'arigatou', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: 'ありがとうございます。'),
  BuiltinWord(word: '先生', romanization: 'sensei', type: 'noun', meaning: '🇻🇳 giáo viên, thầy/cô', example: '先生は優しいです。'),
  BuiltinWord(word: '電話', romanization: 'denwa', type: 'noun', meaning: '🇻🇳 điện thoại', example: '電話をかけます。'),
  BuiltinWord(word: '旅行', romanization: 'ryokou', type: 'noun', meaning: '🇻🇳 du lịch', example: '旅行が大好きです。'),
  BuiltinWord(word: '幸せ', romanization: 'shiawase', type: 'noun', meaning: '🇻🇳 hạnh phúc', example: '幸せな時間です。'),
  // Parallel tech/academic words (matching English meanings)
  BuiltinWord(word: 'アルゴリズム', romanization: 'arugorizumu', type: 'noun', meaning: '🇻🇳 thuật toán', example: 'このアルゴリズムは効率的です。'),
  BuiltinWord(word: 'デバッグする', romanization: 'debaggu suru', type: 'verb', meaning: '🇻🇳 gỡ lỗi', example: 'コードをデバッグしています。'),
  BuiltinWord(word: 'デプロイする', romanization: 'depuroi suru', type: 'verb', meaning: '🇻🇳 triển khai', example: '毎週金曜日にデプロイします。'),
  BuiltinWord(word: 'リポジトリ', romanization: 'ripojitori', type: 'noun', meaning: '🇻🇳 kho lưu trữ', example: 'リポジトリにコードをプッシュします。'),
  BuiltinWord(word: 'フレームワーク', romanization: 'furēmuwāku', type: 'noun', meaning: '🇻🇳 khung làm việc, nền tảng', example: 'FlutterはUIフレームワークです。'),
  BuiltinWord(word: '忍耐する', romanization: 'nintai suru', type: 'verb', meaning: '🇻🇳 kiên trì, bền bỉ', example: '困難があっても忍耐します。'),
  BuiltinWord(word: '細心の', romanization: 'saishin no', type: 'adj', meaning: '🇻🇳 tỉ mỉ, cẩn thận', example: '彼は細心の注意を払います。'),
  BuiltinWord(word: '遍在する', romanization: 'henzai suru', type: 'verb', meaning: '🇻🇳 có mặt khắp nơi', example: 'スマートフォンは遍在します。'),
  BuiltinWord(word: '実用的', romanization: 'jitsuyō-teki', type: 'adj', meaning: '🇻🇳 thực dụng, thực tế', example: '実用的なアプローチが必要です。'),
  BuiltinWord(word: '最適化する', romanization: 'saitekika suru', type: 'verb', meaning: '🇻🇳 tối ưu hóa', example: 'データベースを最適化します。'),
  BuiltinWord(word: '回復力のある', romanization: 'kaifukuryoku no aru', type: 'adj', meaning: '🇻🇳 kiên cường, dẻo dai', example: 'システムは回復力が必要です。'),
  BuiltinWord(word: 'パラダイム', romanization: 'paradaimu', type: 'noun', meaning: '🇻🇳 mô hình, khuôn mẫu', example: 'オブジェクト指向はパラダイムです。'),
  BuiltinWord(word: '繰り返す', romanization: 'kurikaesu', type: 'verb', meaning: '🇻🇳 lặp lại', example: 'リストの各要素を繰り返します。'),
  BuiltinWord(word: '雄弁な', romanization: 'yūben na', type: 'adj', meaning: '🇻🇳 hùng biện, lưu loát', example: '彼女は雄弁なスピーチをしました。'),
  BuiltinWord(word: '曖昧な', romanization: 'aimai na', type: 'adj', meaning: '🇻🇳 mơ hồ, nhập nhằng', example: '要件が曖昧です。'),
  BuiltinWord(word: '同時の', romanization: 'dōji no', type: 'adj', meaning: '🇻🇳 đồng thời, song song', example: '同時リクエストを処理します。'),
  BuiltinWord(word: '束の間の', romanization: 'tsuka no ma no', type: 'adj', meaning: '🇻🇳 phù du, chốc lát', example: 'SNSのストーリーは束の間です。'),
  BuiltinWord(word: '包括的な', romanization: 'hōkatsuteki na', type: 'adj', meaning: '🇻🇳 toàn diện, đầy đủ', example: '包括的なテストが必要です。'),
  BuiltinWord(word: '軽減する', romanization: 'keigen suru', type: 'verb', meaning: '🇻🇳 giảm nhẹ, xoa dịu', example: 'セキュリティリスクを軽減します。'),
  BuiltinWord(word: '本来の', romanization: 'honrai no', type: 'adj', meaning: '🇻🇳 vốn có, bẩm sinh', example: '投資には本来のリスクがあります。'),
];

// Chinese: basic vocab + parallel tech words
const _chineseWords = [
  // Basic Chinese vocabulary
  BuiltinWord(word: '编程', romanization: 'biānchéng', type: 'noun', meaning: '🇻🇳 lập trình', example: '我喜欢编程。'),
  BuiltinWord(word: '电脑', romanization: 'diànnǎo', type: 'noun', meaning: '🇻🇳 máy tính', example: '我用电脑工作。'),
  BuiltinWord(word: '学习', romanization: 'xuéxí', type: 'verb', meaning: '🇻🇳 học tập', example: '我每天学习中文。'),
  BuiltinWord(word: '朋友', romanization: 'péngyou', type: 'noun', meaning: '🇻🇳 bạn bè', example: '他是我的好朋友。'),
  BuiltinWord(word: '谢谢', romanization: 'xièxie', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: '谢谢你的帮助。'),
  BuiltinWord(word: '幸福', romanization: 'xìngfú', type: 'noun', meaning: '🇻🇳 hạnh phúc', example: '我很幸福。'),
  BuiltinWord(word: '旅行', romanization: 'lǚ xíng', type: 'noun', meaning: '🇻🇳 du lịch', example: '我喜欢旅行。'),
  BuiltinWord(word: '老师', romanization: 'lǎoshī', type: 'noun', meaning: '🇻🇳 giáo viên', example: '老师好！'),
  BuiltinWord(word: '美食', romanization: 'měishí', type: 'noun', meaning: '🇻🇳 món ngon', example: '中国美食很多。'),
  BuiltinWord(word: '努力', romanization: 'nǔlì', type: 'verb', meaning: '🇻🇳 nỗ lực', example: '加油，继续努力！'),
  // Parallel tech/academic words (matching English meanings)
  BuiltinWord(word: '算法', romanization: 'suànfǎ', type: 'noun', meaning: '🇻🇳 thuật toán', example: '这个算法很高效。'),
  BuiltinWord(word: '调试', romanization: 'tiáoshì', type: 'verb', meaning: '🇻🇳 gỡ lỗi', example: '我在调试代码。'),
  BuiltinWord(word: '部署', romanization: 'bùshǔ', type: 'verb', meaning: '🇻🇳 triển khai', example: '每周五部署应用。'),
  BuiltinWord(word: '仓库', romanization: 'cāngkù', type: 'noun', meaning: '🇻🇳 kho lưu trữ', example: '把代码推送到仓库。'),
  BuiltinWord(word: '框架', romanization: 'kuàngjià', type: 'noun', meaning: '🇻🇳 khung làm việc, nền tảng', example: 'Flutter是UI框架。'),
  BuiltinWord(word: '坚持', romanization: 'jiānchí', type: 'verb', meaning: '🇻🇳 kiên trì, bền bỉ', example: '尽管困难，她还是坚持下去。'),
  BuiltinWord(word: '细心', romanization: 'xìxīn', type: 'adj', meaning: '🇻🇳 tỉ mỉ, cẩn thận', example: '他做事很细心。'),
  BuiltinWord(word: '无处不在', romanization: 'wúchù bùzài', type: 'adj', meaning: '🇻🇳 có mặt khắp nơi', example: '智能手机无处不在。'),
  BuiltinWord(word: '实用的', romanization: 'shíyòng de', type: 'adj', meaning: '🇻🇳 thực dụng, thực tế', example: '我们需要实用的方法。'),
  BuiltinWord(word: '优化', romanization: 'yōuhuà', type: 'verb', meaning: '🇻🇳 tối ưu hóa', example: '优化数据库查询。'),
  BuiltinWord(word: '有韧性', romanization: 'yǒu rènxìng', type: 'adj', meaning: '🇻🇳 kiên cường, dẻo dai', example: '系统必须有韧性。'),
  BuiltinWord(word: '范式', romanization: 'fànshì', type: 'noun', meaning: '🇻🇳 mô hình, khuôn mẫu', example: '面向对象编程是一种范式。'),
  BuiltinWord(word: '迭代', romanization: 'diédài', type: 'verb', meaning: '🇻🇳 lặp lại', example: '我们遍历列表中的每个元素。'),
  BuiltinWord(word: '雄辩的', romanization: 'xióngbiàn de', type: 'adj', meaning: '🇻🇳 hùng biện, lưu loát', example: '她发表了雄辩的演讲。'),
  BuiltinWord(word: '模糊的', romanization: 'móhu de', type: 'adj', meaning: '🇻🇳 mơ hồ, nhập nhằng', example: '需求很模糊。'),
  BuiltinWord(word: '并发的', romanization: 'bìngfā de', type: 'adj', meaning: '🇻🇳 đồng thời, song song', example: '高效处理并发请求。'),
  BuiltinWord(word: '短暂的', romanization: 'duǎnzàn de', type: 'adj', meaning: '🇻🇳 phù du, chốc lát', example: '社交媒体故事是短暂的。'),
  BuiltinWord(word: '全面的', romanization: 'quánmiàn de', type: 'adj', meaning: '🇻🇳 toàn diện, đầy đủ', example: '我们需要全面的测试。'),
  BuiltinWord(word: '缓解', romanization: 'huǎnjiě', type: 'verb', meaning: '🇻🇳 giảm nhẹ, xoa dịu', example: '必须缓解安全风险。'),
  BuiltinWord(word: '固有的', romanization: 'gùyǒu de', type: 'adj', meaning: '🇻🇳 vốn có, bẩm sinh', example: '任何投资都有固有风险。'),
];

const _frenchWords = [
  BuiltinWord(word: 'bonjour', phonetic: '/bɔ̃.ʒuʁ/', type: 'phrase', meaning: '🇻🇳 xin chào', example: 'Bonjour, comment allez-vous?'),
  BuiltinWord(word: 'merci', phonetic: '/mɛʁ.si/', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: 'Merci beaucoup!'),
  BuiltinWord(word: 'ordinateur', phonetic: '/ɔʁ.di.na.tœʁ/', type: 'noun', meaning: '🇻🇳 máy tính', example: "J'utilise l'ordinateur."),
  BuiltinWord(word: 'apprendre', phonetic: '/a.pʁɑ̃dʁ/', type: 'verb', meaning: '🇻🇳 học', example: "J'apprends le français."),
  BuiltinWord(word: 'voyage', phonetic: '/vwa.jaʒ/', type: 'noun', meaning: '🇻🇳 chuyến đi', example: 'Bon voyage!'),
  BuiltinWord(word: 'ami', phonetic: '/a.mi/', type: 'noun', meaning: '🇻🇳 bạn', example: "C'est mon meilleur ami."),
];

const _germanWords = [
  BuiltinWord(word: 'Computer', phonetic: '/kɔmˈpjuːtɐ/', type: 'noun', meaning: '🇻🇳 máy tính', example: 'Ich benutze einen Computer.'),
  BuiltinWord(word: 'lernen', phonetic: '/ˈlɛʁnən/', type: 'verb', meaning: '🇻🇳 học', example: 'Ich lerne Deutsch.'),
  BuiltinWord(word: 'Freund', phonetic: '/fʁɔʊnt/', type: 'noun', meaning: '🇻🇳 bạn', example: 'Er ist mein bester Freund.'),
  BuiltinWord(word: 'danke', phonetic: '/ˈdaŋkə/', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: 'Danke schön!'),
  BuiltinWord(word: 'Reise', phonetic: '/ˈʁaɪzə/', type: 'noun', meaning: '🇻🇳 chuyến đi', example: 'Die Reise war wunderbar.'),
  BuiltinWord(word: 'Arbeit', phonetic: '/ˈaʁbaɪt/', type: 'noun', meaning: '🇻🇳 công việc', example: 'Ich gehe zur Arbeit.'),
];

const _spanishWords = [
  BuiltinWord(word: 'hola', phonetic: '/ˈola/', type: 'phrase', meaning: '🇻🇳 xin chào', example: '¡Hola! ¿Cómo estás?'),
  BuiltinWord(word: 'gracias', phonetic: '/ˈɡɾaθjas/', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: '¡Muchas gracias!'),
  BuiltinWord(word: 'ordenador', phonetic: '/oɾðenaˈðoɾ/', type: 'noun', meaning: '🇻🇳 máy tính', example: 'Uso el ordenador para trabajar.'),
  BuiltinWord(word: 'aprender', phonetic: '/apɾenˈdeɾ/', type: 'verb', meaning: '🇻🇳 học', example: 'Quiero aprender español.'),
  BuiltinWord(word: 'amigo', phonetic: '/aˈmiɣo/', type: 'noun', meaning: '🇻🇳 bạn', example: 'Él es mi mejor amigo.'),
  BuiltinWord(word: 'viaje', phonetic: '/ˈbjaxe/', type: 'noun', meaning: '🇻🇳 chuyến đi', example: '¡Buen viaje!'),
];

const _portugueseWords = [
  BuiltinWord(word: 'obrigado', phonetic: '/obɾiˈɡadu/', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: 'Muito obrigado!'),
  BuiltinWord(word: 'computador', phonetic: '/kõputaˈdoɾ/', type: 'noun', meaning: '🇻🇳 máy tính', example: 'Eu uso o computador.'),
  BuiltinWord(word: 'aprender', phonetic: '/apɾẽˈdeɾ/', type: 'verb', meaning: '🇻🇳 học', example: 'Eu quero aprender português.'),
  BuiltinWord(word: 'amigo', phonetic: '/aˈmigu/', type: 'noun', meaning: '🇻🇳 bạn', example: 'Ele é meu melhor amigo.'),
  BuiltinWord(word: 'viagem', phonetic: '/viˈaʒĩ/', type: 'noun', meaning: '🇻🇳 chuyến đi', example: 'Boa viagem!'),
  BuiltinWord(word: 'trabalho', phonetic: '/tɾaˈbaʎu/', type: 'noun', meaning: '🇻🇳 công việc', example: 'Vou ao trabalho.'),
];

const _italianWords = [
  BuiltinWord(word: 'ciao', phonetic: '/tʃao/', type: 'phrase', meaning: '🇻🇳 xin chào', example: 'Ciao, come stai?'),
  BuiltinWord(word: 'grazie', phonetic: '/ˈɡrattsje/', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: 'Grazie mille!'),
  BuiltinWord(word: 'amico', phonetic: '/aˈmiko/', type: 'noun', meaning: '🇻🇳 bạn', example: 'È il mio migliore amico.'),
  BuiltinWord(word: 'viaggio', phonetic: '/ˈvjadʒo/', type: 'noun', meaning: '🇻🇳 chuyến đi', example: 'Buon viaggio!'),
  BuiltinWord(word: 'lavoro', phonetic: '/laˈvoro/', type: 'noun', meaning: '🇻🇳 công việc', example: 'Vado al lavoro.'),
  BuiltinWord(word: 'imparare', phonetic: '/impaˈrare/', type: 'verb', meaning: '🇻🇳 học', example: 'Voglio imparare italiano.'),
];

const _russianWords = [
  BuiltinWord(word: 'Привет', romanization: 'privet', type: 'phrase', meaning: '🇻🇳 xin chào', example: 'Привет, как дела?'),
  BuiltinWord(word: 'Спасибо', romanization: 'spasibo', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: 'Большое спасибо!'),
  BuiltinWord(word: 'Друг', romanization: 'drug', type: 'noun', meaning: '🇻🇳 bạn', example: 'Он мой лучший друг.'),
  BuiltinWord(word: 'Учиться', romanization: 'uchitsya', type: 'verb', meaning: '🇻🇳 học', example: 'Я учусь русскому языку.'),
  BuiltinWord(word: 'Путешествие', romanization: 'puteshestviye', type: 'noun', meaning: '🇻🇳 du lịch', example: 'Я люблю путешествовать.'),
  BuiltinWord(word: 'Работа', romanization: 'rabota', type: 'noun', meaning: '🇻🇳 công việc', example: 'Я иду на работу.'),
];

const _thaiWords = [
  BuiltinWord(word: 'สวัสดี', romanization: 'sawasdee', type: 'phrase', meaning: '🇻🇳 xin chào', example: 'สวัสดีครับ'),
  BuiltinWord(word: 'ขอบคุณ', romanization: 'khob khun', type: 'phrase', meaning: '🇻🇳 cảm ơn', example: 'ขอบคุณครับ'),
  BuiltinWord(word: 'เพื่อน', romanization: 'pheuan', type: 'noun', meaning: '🇻🇳 bạn', example: 'เขาเป็นเพื่อนที่ดีที่สุด'),
  BuiltinWord(word: 'เรียน', romanization: 'rian', type: 'verb', meaning: '🇻🇳 học', example: 'ฉันเรียนภาษาไทย'),
  BuiltinWord(word: 'อาหาร', romanization: 'ahaan', type: 'noun', meaning: '🇻🇳 thức ăn', example: 'อาหารไทยอร่อยมาก'),
  BuiltinWord(word: 'ท่องเที่ยว', romanization: 'thong thiao', type: 'noun', meaning: '🇻🇳 du lịch', example: 'ฉันชอบท่องเที่ยว'),
];

const _vietnameseWords = [
  BuiltinWord(word: 'xin chào', type: 'phrase', meaning: '🇻🇳 lời chào hỏi', example: 'Xin chào, bạn khỏe không?'),
  BuiltinWord(word: 'cảm ơn', type: 'phrase', meaning: '🇻🇳 lời biết ơn', example: 'Cảm ơn bạn rất nhiều!'),
  BuiltinWord(word: 'bạn bè', type: 'noun', meaning: '🇻🇳 người thân thiết', example: 'Anh ấy là bạn bè tốt nhất của tôi.'),
  BuiltinWord(word: 'học tập', type: 'verb', meaning: '🇻🇳 tiếp thu kiến thức', example: 'Tôi học tập mỗi ngày.'),
  BuiltinWord(word: 'du lịch', type: 'noun', meaning: '🇻🇳 đi chơi, tham quan', example: 'Tôi thích du lịch.'),
  BuiltinWord(word: 'hạnh phúc', type: 'noun', meaning: '🇻🇳 trạng thái vui vẻ, mãn nguyện', example: 'Hạnh phúc là điều quan trọng nhất.'),
];
