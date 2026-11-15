"""Adds the picture-fact and group texts to the eight translation files.

Usage (from the project root):
    python scripts/i18n/ui_keys.py

Safe to run again: existing keys are overwritten with the values below, every
other key and the file formatting are left as they are.
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
DIR = ROOT / "assets" / "translations"

# key: (en, tr, ru, pt, hi, es, ar, de)
LANGS = ["en-US", "tr-TR", "ru-RU", "pt-BR", "hi-IN", "es-ES", "ar-SA", "de-DE"]
KEYS = {
    "group_farm": ("Farm", "Çiftlik", "Ферма", "Fazenda", "खेत", "Granja", "المزرعة", "Bauernhof"),
    "group_wild": ("Wild", "Vahşi", "Дикие", "Selvagens", "जंगली", "Salvajes", "البرية", "Wildtiere"),
    "group_birds": ("Birds", "Kuşlar", "Птицы", "Aves", "पक्षी", "Aves", "الطيور", "Vögel"),
    "group_water": ("Water", "Su", "Вода", "Água", "पानी", "Agua", "الماء", "Wasser"),
    "group_small": ("Tiny", "Minikler", "Малыши", "Pequenos", "नन्हे", "Pequeños", "الصغار", "Winzige"),
    "home_farm": ("Farm", "Çiftlik", "Ферма", "Fazenda", "खेत", "Granja", "المزرعة", "Bauernhof"),
    "home_house": ("Home", "Ev", "Дом", "Casa", "घर", "Casa", "البيت", "Zuhause"),
    "home_savanna": ("Savanna", "Savan", "Саванна", "Savana", "सवाना", "Sabana", "السافانا", "Savanne"),
    "home_forest": ("Forest", "Orman", "Лес", "Floresta", "जंगल", "Bosque", "الغابة", "Wald"),
    "home_jungle": ("Jungle", "Yağmur ormanı", "Джунгли", "Selva", "वर्षावन", "Selva", "الأدغال", "Dschungel"),
    "home_sea": ("Sea", "Deniz", "Море", "Mar", "समुद्र", "Mar", "البحر", "Meer"),
    "home_ice": ("Ice", "Buzullar", "Льды", "Gelo", "बर्फ़", "Hielo", "الجليد", "Eis"),
    "home_desert": ("Desert", "Çöl", "Пустыня", "Deserto", "रेगिस्तान", "Desierto", "الصحراء", "Wüste"),
    "home_lake": ("Lake", "Göl", "Озеро", "Lago", "झील", "Lago", "البحيرة", "See"),
    "home_mountain": ("Mountains", "Dağlar", "Горы", "Montanhas", "पहाड़", "Montañas", "الجبال", "Berge"),
    "home_meadow": ("Meadow", "Çayır", "Луг", "Campo", "घास का मैदान", "Pradera", "المرج", "Wiese"),
    "home_city": ("City", "Şehir", "Город", "Cidade", "शहर", "Ciudad", "المدينة", "Stadt"),
    "food_grass": ("Grass", "Ot", "Трава", "Capim", "घास", "Hierba", "العشب", "Gras"),
    "food_plants": ("Plants", "Bitkiler", "Растения", "Plantas", "पौधे", "Plantas", "النباتات", "Pflanzen"),
    "food_meat": ("Meat", "Et", "Мясо", "Carne", "मांस", "Carne", "اللحم", "Fleisch"),
    "food_fish": ("Fish", "Balık", "Рыба", "Peixe", "मछली", "Pescado", "السمك", "Fisch"),
    "food_insects": ("Insects", "Böcekler", "Насекомые", "Insetos", "कीड़े", "Insectos", "الحشرات", "Insekten"),
    "food_seeds": ("Seeds", "Tohumlar", "Семена", "Sementes", "बीज", "Semillas", "البذور", "Körner"),
    "food_fruit": ("Fruit", "Meyve", "Фрукты", "Frutas", "फल", "Fruta", "الفاكهة", "Obst"),
    "food_nectar": ("Nectar", "Çiçek özü", "Нектар", "Néctar", "फूलों का रस", "Néctar", "الرحيق", "Nektar"),
    "food_everything": ("Everything", "Her şey", "Всё подряд", "De tudo", "सब कुछ", "De todo", "كل شيء", "Alles"),
    "size_smaller": ("Smaller than you", "Senden küçük", "Меньше тебя", "Menor que você", "तुमसे छोटा", "Más pequeño que tú", "أصغر منك", "Kleiner als du"),
    "size_same": ("About your size", "Senin kadar", "Примерно как ты", "Do seu tamanho", "तुम्हारे जितना", "De tu tamaño", "بحجمك تقريبًا", "So groß wie du"),
    "size_bigger": ("Bigger than you", "Senden büyük", "Больше тебя", "Maior que você", "तुमसे बड़ा", "Más grande que tú", "أكبر منك", "Größer als du"),
    "info_lives": ("Where I live", "Nerede yaşarım", "Где я живу", "Onde eu moro", "मैं कहाँ रहता हूँ", "Dónde vivo", "أين أعيش", "Wo ich wohne"),
    "info_eats": ("What I eat", "Ne yerim", "Что я ем", "O que eu como", "मैं क्या खाता हूँ", "Qué como", "ماذا آكل", "Was ich fresse"),
    "info_size": ("How big I am", "Ne kadar büyüğüm", "Какой я большой", "Qual é o meu tamanho", "मैं कितना बड़ा हूँ", "Qué tan grande soy", "كم حجمي", "Wie groß ich bin"),
    "info_more": ("More details", "Daha fazla bilgi", "Подробнее", "Mais detalhes", "और जानकारी", "Más detalles", "تفاصيل أكثر", "Mehr Details"),
    "animal_info": ("Learn", "Öğren", "Узнать", "Aprender", "जानो", "Aprender", "تعلّم", "Lernen"),
    "sound_credits": ("Sound credits", "Ses kaynakları", "Источники звуков", "Créditos dos sons", "ध्वनि स्रोत", "Créditos de sonido", "مصادر الأصوات", "Tonquellen"),
    "sound_credits_note": ("Thank you to the people and institutions who recorded these sounds. The clips were shortened and their volume was adjusted.", "Bu sesleri kaydeden kişi ve kurumlara teşekkür ederiz. Kayıtlar kısaltıldı ve ses seviyeleri ayarlandı.", "Спасибо людям и организациям, записавшим эти звуки. Записи были укорочены, а их громкость выровнена.", "Obrigado às pessoas e instituições que gravaram estes sons. As gravações foram encurtadas e o volume foi ajustado.", "इन ध्वनियों को रिकॉर्ड करने वाले लोगों और संस्थाओं का धन्यवाद। रिकॉर्डिंग छोटी की गईं और उनकी आवाज़ का स्तर ठीक किया गया।", "Gracias a las personas e instituciones que grabaron estos sonidos. Las grabaciones se acortaron y se ajustó su volumen.", "شكرًا للأشخاص والمؤسسات الذين سجّلوا هذه الأصوات. تم تقصير التسجيلات وضبط مستوى صوتها.", "Danke an die Menschen und Einrichtungen, die diese Töne aufgenommen haben. Die Aufnahmen wurden gekürzt und in der Lautstärke angepasst."),
}


def insert(text: str, pairs: dict) -> str:
    """Rewrites or appends top-level keys without touching anything else."""
    data = json.loads(text)
    out = text.rstrip()
    assert out.endswith("}")
    body = out[:-1].rstrip()
    added = []
    for key, value in pairs.items():
        line = f'    {json.dumps(key)}: {json.dumps(value, ensure_ascii=False)}'
        if key in data:
            start = body.index(f'\n    {json.dumps(key)}:')
            end = body.index("\n", start + 1) if "\n" in body[start + 1:] else len(body)
            comma = "," if body[start:end].rstrip().endswith(",") else ""
            body = body[:start] + "\n" + line + comma + body[end:]
        else:
            added.append(line)
    if added:
        body = body + ",\n" + ",\n".join(added)
    result = body + "\n}\n"
    json.loads(result)
    return result


def main() -> None:
    for i, lang in enumerate(LANGS):
        path = DIR / f"{lang}.json"
        pairs = {key: values[i] for key, values in KEYS.items()}
        path.write_text(insert(path.read_text(encoding="utf-8"), pairs),
                        encoding="utf-8", newline="\n")
        print(lang, len(pairs), "keys")


if __name__ == "__main__":
    main()
