path = r"D:\Projects\vocab_ai\lib\core\l10n\strings.dart"
with open(path, encoding='utf-8') as f:
    content = f.read()

strings = {
    'vi-VN': ('Store không khả dụng', 'Không tìm thấy sản phẩm'),
    'en-US': ('Store unavailable', 'Product not found'),
    'ko-KR': ('스토어를 사용할 수 없습니다', '상품을 찾을 수 없습니다'),
    'ja-JP': ('ストアが利用できません', '商品が見つかりません'),
    'zh-CN': ('商店不可用', '找不到产品'),
    'zh-TW': ('商店不可用', '找不到產品'),
    'fr-FR': ('Boutique indisponible', 'Produit introuvable'),
    'de-DE': ('Store nicht verfügbar', 'Produkt nicht gefunden'),
    'es-ES': ('Tienda no disponible', 'Producto no encontrado'),
    'it-IT': ('Store non disponibile', 'Prodotto non trovato'),
    'pt-BR': ('Loja indisponível', 'Produto não encontrado'),
    'ru-RU': ('Магазин недоступен', 'Продукт не найден'),
    'th-TH': ('ไม่สามารถใช้ร้านค้าได้', 'ไม่พบสินค้า'),
    'ar-SA': ('المتجر غير متاح', 'المنتج غير موجود'),
    'hi-IN': ('स्टोर उपलब्ध नहीं है', 'उत्पाद नहीं मिला'),
    'id-ID': ('Toko tidak tersedia', 'Produk tidak ditemukan'),
    'nl-NL': ('Store niet beschikbaar', 'Product niet gevonden'),
    'tr-TR': ('Mağaza kullanılamıyor', 'Ürün bulunamadı'),
    'ms-MY': ('Kedai tidak tersedia', 'Produk tidak dijumpai'),
}

lines = content.split('\n')

# Insert after 'no_words_in_topic' line in each locale
result = []
i = 0
while i < len(lines):
    line = lines[i]
    result.append(line)
    if "'no_words_in_topic'" in line:
        # Find locale for this line
        locale = None
        for j in range(i, max(0, i - 300), -1):
            for loc in strings:
                if f"'{loc}'" in lines[j]:
                    locale = loc
                    break
            if locale:
                break
        if locale and locale in strings:
            store_msg, product_msg = strings[locale]
            result.append(f"    'store_unavailable': '{store_msg}',")
            result.append(f"    'product_not_found': '{product_msg}',")
            print(f"Added for {locale}")
    i += 1

with open(path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(result))
print("Done!")
