class Language {
  final String code;
  final String name;
  final String native;
  final String flag;
  final String ttsLang;
  final bool hasDictAPI;

  const Language({
    required this.code,
    required this.name,
    required this.native,
    required this.flag,
    required this.ttsLang,
    this.hasDictAPI = false,
  });
}

const List<Language> kLanguages = [
  Language(code: 'en-US', name: 'English US', native: 'English', flag: '\u{1F1FA}\u{1F1F8}', ttsLang: 'en-US', hasDictAPI: true),
  Language(code: 'en-GB', name: 'English UK', native: 'English', flag: '\u{1F1EC}\u{1F1E7}', ttsLang: 'en-GB', hasDictAPI: true),
  Language(code: 'ko-KR', name: 'Korean', native: '\uD55C\uAD6D\uC5B4', flag: '\u{1F1F0}\u{1F1F7}', ttsLang: 'ko-KR'),
  Language(code: 'ja-JP', name: 'Japanese', native: '\u65E5\u672C\u8A9E', flag: '\u{1F1EF}\u{1F1F5}', ttsLang: 'ja-JP'),
  Language(code: 'zh-CN', name: 'Chinese CN', native: '\u666E\u901A\u8BDD', flag: '\u{1F1E8}\u{1F1F3}', ttsLang: 'zh-CN'),
  Language(code: 'zh-TW', name: 'Chinese TW', native: '\u7E41\u9AD4\u4E2D\u6587', flag: '\u{1F1F9}\u{1F1FC}', ttsLang: 'zh-TW'),
  Language(code: 'fr-FR', name: 'French', native: 'Fran\u00E7ais', flag: '\u{1F1EB}\u{1F1F7}', ttsLang: 'fr-FR'),
  Language(code: 'de-DE', name: 'German', native: 'Deutsch', flag: '\u{1F1E9}\u{1F1EA}', ttsLang: 'de-DE'),
  Language(code: 'es-ES', name: 'Spanish', native: 'Espa\u00F1ol', flag: '\u{1F1EA}\u{1F1F8}', ttsLang: 'es-ES'),
  Language(code: 'it-IT', name: 'Italian', native: 'Italiano', flag: '\u{1F1EE}\u{1F1F9}', ttsLang: 'it-IT'),
  Language(code: 'pt-BR', name: 'Portuguese', native: 'Portugu\u00EAs', flag: '\u{1F1E7}\u{1F1F7}', ttsLang: 'pt-BR'),
  Language(code: 'ru-RU', name: 'Russian', native: '\u0420\u0443\u0441\u0441\u043A\u0438\u0439', flag: '\u{1F1F7}\u{1F1FA}', ttsLang: 'ru-RU'),
  Language(code: 'th-TH', name: 'Thai', native: '\u0E20\u0E32\u0E29\u0E32\u0E44\u0E17\u0E22', flag: '\u{1F1F9}\u{1F1ED}', ttsLang: 'th-TH'),
  Language(code: 'vi-VN', name: 'Vietnamese', native: 'Ti\u1EBFng Vi\u1EC7t', flag: '\u{1F1FB}\u{1F1F3}', ttsLang: 'vi-VN'),
  Language(code: 'ar-SA', name: 'Arabic', native: '\u0627\u0644\u0639\u0631\u0628\u064A\u0629', flag: '\u{1F1F8}\u{1F1E6}', ttsLang: 'ar-SA'),
  Language(code: 'hi-IN', name: 'Hindi', native: '\u0939\u093F\u0928\u094D\u0926\u0940', flag: '\u{1F1EE}\u{1F1F3}', ttsLang: 'hi-IN'),
  Language(code: 'id-ID', name: 'Indonesian', native: 'Bahasa', flag: '\u{1F1EE}\u{1F1E9}', ttsLang: 'id-ID'),
  Language(code: 'nl-NL', name: 'Dutch', native: 'Nederlands', flag: '\u{1F1F3}\u{1F1F1}', ttsLang: 'nl-NL'),
  Language(code: 'tr-TR', name: 'Turkish', native: 'T\u00FCrk\u00E7e', flag: '\u{1F1F9}\u{1F1F7}', ttsLang: 'tr-TR'),
  Language(code: 'ms-MY', name: 'Malay', native: 'Melayu', flag: '\u{1F1F2}\u{1F1FE}', ttsLang: 'ms-MY'),
];

Language findLanguage(String code) =>
    kLanguages.firstWhere((l) => l.code == code, orElse: () => kLanguages[0]);
