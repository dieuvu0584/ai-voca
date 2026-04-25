import re, os

path = r"D:\Projects\vocab_ai\lib\core\l10n\strings.dart"
with open(path, encoding='utf-8') as f:
    content = f.read()

topic_strings = {
    'vi-VN': {'topic_all':'Tat ca','topic_food':'Thuc an','topic_drink':'Do uong','topic_household':'Do vat nha','topic_clothing':'Quan ao','topic_body':'Co the','topic_family':'Gia dinh','topic_transport':'Phuong tien','topic_nature':'Thien nhien','topic_animals':'Dong vat','topic_work':'Cong viec','topic_technology':'Cong nghe','topic_health':'Suc khoe','topic_education':'Giao duc','topic_money':'Tien bac','topic_sports':'The thao','topic_emotions':'Cam xuc'},
    'en-US': {'topic_all':'All','topic_food':'Food','topic_drink':'Drinks','topic_household':'Household','topic_clothing':'Clothing','topic_body':'Body','topic_family':'Family','topic_transport':'Transport','topic_nature':'Nature','topic_animals':'Animals','topic_work':'Work','topic_technology':'Technology','topic_health':'Health','topic_education':'Education','topic_money':'Money','topic_sports':'Sports','topic_emotions':'Emotions'},
    'ko-KR': {'topic_all':'전체','topic_food':'음식','topic_drink':'음료','topic_household':'가정용품','topic_clothing':'의류','topic_body':'신체','topic_family':'가족','topic_transport':'교통','topic_nature':'자연','topic_animals':'동물','topic_work':'직업','topic_technology':'기술','topic_health':'건강','topic_education':'교육','topic_money':'돈','topic_sports':'스포츠','topic_emotions':'감정'},
    'ja-JP': {'topic_all':'すべて','topic_food':'食べ物','topic_drink':'飲み物','topic_household':'家庭用品','topic_clothing':'衣類','topic_body':'体','topic_family':'家族','topic_transport':'交通','topic_nature':'自然','topic_animals':'動物','topic_work':'仕事','topic_technology':'テクノロジー','topic_health':'健康','topic_education':'教育','topic_money':'お金','topic_sports':'スポーツ','topic_emotions':'感情'},
    'zh-CN': {'topic_all':'全部','topic_food':'食物','topic_drink':'饮料','topic_household':'家居','topic_clothing':'服装','topic_body':'身体','topic_family':'家庭','topic_transport':'交通','topic_nature':'自然','topic_animals':'动物','topic_work':'工作','topic_technology':'科技','topic_health':'健康','topic_education':'教育','topic_money':'金钱','topic_sports':'体育','topic_emotions':'情感'},
    'zh-TW': {'topic_all':'全部','topic_food':'食物','topic_drink':'飲料','topic_household':'家居','topic_clothing':'服裝','topic_body':'身體','topic_family':'家庭','topic_transport':'交通','topic_nature':'自然','topic_animals':'動物','topic_work':'工作','topic_technology':'科技','topic_health':'健康','topic_education':'教育','topic_money':'金錢','topic_sports':'體育','topic_emotions':'情感'},
    'fr-FR': {'topic_all':'Tout','topic_food':'Nourriture','topic_drink':'Boissons','topic_household':'Maison','topic_clothing':'Vetements','topic_body':'Corps','topic_family':'Famille','topic_transport':'Transport','topic_nature':'Nature','topic_animals':'Animaux','topic_work':'Travail','topic_technology':'Technologie','topic_health':'Sante','topic_education':'Education','topic_money':'Argent','topic_sports':'Sports','topic_emotions':'Emotions'},
    'de-DE': {'topic_all':'Alle','topic_food':'Essen','topic_drink':'Getranke','topic_household':'Haushalt','topic_clothing':'Kleidung','topic_body':'Korper','topic_family':'Familie','topic_transport':'Verkehr','topic_nature':'Natur','topic_animals':'Tiere','topic_work':'Arbeit','topic_technology':'Technologie','topic_health':'Gesundheit','topic_education':'Bildung','topic_money':'Geld','topic_sports':'Sport','topic_emotions':'Gefuhle'},
    'es-ES': {'topic_all':'Todo','topic_food':'Comida','topic_drink':'Bebidas','topic_household':'Hogar','topic_clothing':'Ropa','topic_body':'Cuerpo','topic_family':'Familia','topic_transport':'Transporte','topic_nature':'Naturaleza','topic_animals':'Animales','topic_work':'Trabajo','topic_technology':'Tecnologia','topic_health':'Salud','topic_education':'Educacion','topic_money':'Dinero','topic_sports':'Deportes','topic_emotions':'Emociones'},
    'it-IT': {'topic_all':'Tutto','topic_food':'Cibo','topic_drink':'Bevande','topic_household':'Casa','topic_clothing':'Abbigliamento','topic_body':'Corpo','topic_family':'Famiglia','topic_transport':'Trasporti','topic_nature':'Natura','topic_animals':'Animali','topic_work':'Lavoro','topic_technology':'Tecnologia','topic_health':'Salute','topic_education':'Istruzione','topic_money':'Denaro','topic_sports':'Sport','topic_emotions':'Emozioni'},
    'pt-BR': {'topic_all':'Tudo','topic_food':'Comida','topic_drink':'Bebidas','topic_household':'Casa','topic_clothing':'Roupas','topic_body':'Corpo','topic_family':'Familia','topic_transport':'Transporte','topic_nature':'Natureza','topic_animals':'Animais','topic_work':'Trabalho','topic_technology':'Tecnologia','topic_health':'Saude','topic_education':'Educacao','topic_money':'Dinheiro','topic_sports':'Esportes','topic_emotions':'Emocoes'},
    'ru-RU': {'topic_all':'Все','topic_food':'Еда','topic_drink':'Напитки','topic_household':'Дом','topic_clothing':'Одежда','topic_body':'Тело','topic_family':'Семья','topic_transport':'Транспорт','topic_nature':'Природа','topic_animals':'Животные','topic_work':'Работа','topic_technology':'Технологии','topic_health':'Здоровье','topic_education':'Образование','topic_money':'Деньги','topic_sports':'Спорт','topic_emotions':'Эмоции'},
    'th-TH': {'topic_all':'ทั้งหมด','topic_food':'อาหาร','topic_drink':'เครื่องดื่ม','topic_household':'ของในบ้าน','topic_clothing':'เสื้อผ้า','topic_body':'ร่างกาย','topic_family':'ครอบครัว','topic_transport':'การขนส่ง','topic_nature':'ธรรมชาติ','topic_animals':'สัตว์','topic_work':'งาน','topic_technology':'เทคโนโลยี','topic_health':'สุขภาพ','topic_education':'การศึกษา','topic_money':'เงิน','topic_sports':'กีฬา','topic_emotions':'อารมณ์'},
    'ar-SA': {'topic_all':'الكل','topic_food':'طعام','topic_drink':'مشروبات','topic_household':'منزل','topic_clothing':'ملابس','topic_body':'الجسم','topic_family':'العائلة','topic_transport':'مواصلات','topic_nature':'الطبيعة','topic_animals':'حيوانات','topic_work':'عمل','topic_technology':'تكنولوجيا','topic_health':'صحة','topic_education':'تعليم','topic_money':'مال','topic_sports':'رياضة','topic_emotions':'مشاعر'},
    'hi-IN': {'topic_all':'सभी','topic_food':'खाना','topic_drink':'पेय','topic_household':'घर','topic_clothing':'कपड़े','topic_body':'शरीर','topic_family':'परिवार','topic_transport':'परिवहन','topic_nature':'प्रकृति','topic_animals':'जानवर','topic_work':'काम','topic_technology':'तकनीक','topic_health':'स्वास्थ्य','topic_education':'शिक्षा','topic_money':'पैसा','topic_sports':'खेल','topic_emotions':'भावनाएं'},
    'id-ID': {'topic_all':'Semua','topic_food':'Makanan','topic_drink':'Minuman','topic_household':'Rumah','topic_clothing':'Pakaian','topic_body':'Tubuh','topic_family':'Keluarga','topic_transport':'Transportasi','topic_nature':'Alam','topic_animals':'Hewan','topic_work':'Pekerjaan','topic_technology':'Teknologi','topic_health':'Kesehatan','topic_education':'Pendidikan','topic_money':'Uang','topic_sports':'Olahraga','topic_emotions':'Emosi'},
    'nl-NL': {'topic_all':'Alles','topic_food':'Eten','topic_drink':'Drinken','topic_household':'Huishouden','topic_clothing':'Kleding','topic_body':'Lichaam','topic_family':'Familie','topic_transport':'Vervoer','topic_nature':'Natuur','topic_animals':'Dieren','topic_work':'Werk','topic_technology':'Technologie','topic_health':'Gezondheid','topic_education':'Onderwijs','topic_money':'Geld','topic_sports':'Sport','topic_emotions':'Emoties'},
    'tr-TR': {'topic_all':'Hepsi','topic_food':'Yiyecek','topic_drink':'Icecek','topic_household':'Ev','topic_clothing':'Giysi','topic_body':'Vucut','topic_family':'Aile','topic_transport':'Ulasim','topic_nature':'Doga','topic_animals':'Hayvanlar','topic_work':'Is','topic_technology':'Teknoloji','topic_health':'Saglik','topic_education':'Egitim','topic_money':'Para','topic_sports':'Spor','topic_emotions':'Duygular'},
    'ms-MY': {'topic_all':'Semua','topic_food':'Makanan','topic_drink':'Minuman','topic_household':'Rumah','topic_clothing':'Pakaian','topic_body':'Badan','topic_family':'Keluarga','topic_transport':'Pengangkutan','topic_nature':'Alam','topic_animals':'Haiwan','topic_work':'Kerja','topic_technology':'Teknologi','topic_health':'Kesihatan','topic_education':'Pendidikan','topic_money':'Wang','topic_sports':'Sukan','topic_emotions':'Emosi'},
}

locale_order = list(topic_strings.keys())
lines = content.split('\n')

free_limit_positions = [i for i, l in enumerate(lines) if "'free_limit_msg'" in l]
print(f"Found {len(free_limit_positions)} free_limit_msg lines")

def detect_locale(lines, idx):
    for locale in locale_order:
        for j in range(idx, max(0, idx-300), -1):
            if f"'{locale}'" in lines[j]:
                return locale
    return None

for idx in reversed(free_limit_positions):
    locale = detect_locale(lines, idx)
    if locale and locale in topic_strings:
        indent = '    '
        new_lines = []
        for key, val in topic_strings[locale].items():
            new_lines.append(f"{indent}'{key}': '{val}',")
        for nl in reversed(new_lines):
            lines.insert(idx + 1, nl)
        print(f"Inserted {len(new_lines)} topic strings for {locale}")
    else:
        print(f"No locale for line {idx}")

with open(path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print("Done!")
