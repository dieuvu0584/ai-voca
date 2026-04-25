import re

path = r"D:\Projects\vocab_ai\lib\core\l10n\strings.dart"
with open(path, encoding='utf-8') as f:
    content = f.read()

# Map locale to (no_words_in_topic, due)
missing_keys = {
    'en-US': ("No words in this topic.", "Due"),
    'ko-KR': ("이 주제에 단어가 없습니다.", "복습 예정"),
    'ja-JP': ("このトピックに単語がありません。", "復習予定"),
    'zh-CN': ("该主题没有单词。", "到期"),
    'zh-TW': ("該主題沒有單字。", "到期"),
    'fr-FR': ("Aucun mot dans ce thème.", "À réviser"),
    'de-DE': ("Keine Wörter in diesem Thema.", "Fällig"),
    'es-ES': ("No hay palabras en este tema.", "Pendiente"),
    'it-IT': ("Nessuna parola in questo argomento.", "In scadenza"),
    'pt-BR': ("Nenhuma palavra neste tópico.", "Pendente"),
    'ru-RU': ("В этой теме нет слов.", "К повторению"),
    'th-TH': ("ไม่มีคำในหัวข้อนี้", "ถึงกำหนด"),
    'ar-SA': ("لا توجد كلمات في هذا الموضوع.", "مستحق"),
    'hi-IN': ("इस विषय में कोई शब्द नहीं है।", "समय पर"),
    'id-ID': ("Tidak ada kata dalam topik ini.", "Jatuh tempo"),
    'nl-NL': ("Geen woorden in dit onderwerp.", "Vervallen"),
    'tr-TR': ("Bu konuda kelime yok.", "Vadesi geldi"),
    'ms-MY': ("Tiada perkataan dalam topik ini.", "Tamat tempoh"),
}

lines = content.split('\n')

# Find all free_limit_msg lines (skip vi-VN which already has no_words_in_topic)
# We check: if the line after free_limit_msg already has no_words_in_topic, skip
result_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    result_lines.append(line)

    if "'free_limit_msg'" in line:
        # Check if next non-empty line already has no_words_in_topic
        next_i = i + 1
        already_has = False
        if next_i < len(lines) and "'no_words_in_topic'" in lines[next_i]:
            already_has = True

        if not already_has:
            # Find which locale this belongs to
            locale = None
            for j in range(i, max(0, i - 300), -1):
                for loc in missing_keys:
                    if f"'{loc}'" in lines[j]:
                        locale = loc
                        break
                if locale:
                    break

            if locale and locale in missing_keys:
                no_words_val, due_val = missing_keys[locale]
                indent = '    '
                result_lines.append(f"{indent}'no_words_in_topic': '{no_words_val}',")
                result_lines.append(f"{indent}'due': '{due_val}',")
                print(f"Added keys for {locale}")
            else:
                print(f"Could not find locale for line {i}: {line.strip()}")

    i += 1

with open(path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(result_lines))
print("Done!")
