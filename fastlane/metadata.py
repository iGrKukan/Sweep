"""Локализованная metadata + appInfo поля для Pixelbroom (App Store Connect).

Грубо повторяет patterns из ~/Echograph/fastlane/. Не идемпотентный —
сначала вызывает GET, потом POST/PATCH по необходимости.
"""
import sys, json, requests
sys.path.insert(0, "/Users/iharshkredau/Sweep/fastlane")
import asc_token

H = {**asc_token.auth_headers(), "Content-Type": "application/json"}
APP_ID = asc_token.APP_ID

LOCALES = ["en-US", "ru", "de-DE", "fr-FR", "ja"]

# CFBundleDisplayName и primary metadata. ВНИМАНИЕ: name ≤30, subtitle ≤30,
# keywords ≤100, description ≤4000, promotionalText ≤170.
SUBTITLE = {
    "en-US": "Find duplicates, free up space",
    "ru":    "Найди дубли и освободи место",
    "de-DE": "Duplikate weg, Speicher frei",
    "fr-FR": "Trouvez les doublons, libérez",
    "ja":    "重複検出でストレージを解放",
}

KEYWORDS = {
    "en-US": "photo cleaner,duplicate,storage,clean,screenshot,blurry,photo,gallery,similar,burst",
    "ru":    "очистка фото,дубликаты,место,скриншоты,галерея,размытые,серии,камера,хранилище",
    "de-DE": "fotoreiniger,duplikate,speicher,screenshots,unscharf,galerie,kamera,fotos",
    "fr-FR": "nettoyage,doublons,stockage,captures,flou,galerie,photos,rafales",
    "ja":    "写真整理,重複,容量,スクリーンショット,ぼけ,ギャラリー,カメラ,バースト",
}

DESCRIPTION = {
    "en-US": """Pixelbroom is a fast, private photo cleaner for iPhone.

It scans your photo library locally — nothing is uploaded — and surfaces:

• Duplicate photos (exact and near-duplicates via on-device perceptual hashing)
• Old screenshots that have been quietly filling your library
• Blurry shots you forgot to delete
• Photo bursts (10 near-identical shots in 2 seconds — pick the keeper)
• The 100 biggest videos and Live Photos eating your storage

You confirm every delete. iOS shows its own system dialog before anything is removed, so nothing disappears without your tap.

PRIVACY-FIRST
• 100% on-device. No cloud, no server, no telemetry.
• No SDKs, no analytics, no ads, no tracking.
• Sweep only sees photo metadata and downsized thumbnails — never uploads anything anywhere.

PRO — one-time, $9.99
Free tier lets you delete up to 20 photos a week so you can try it. Pro removes that limit and unlocks smart suggestions (old screenshots, repeat-bursts across years). One purchase. Yours forever. No subscription.

Built for iPhone 12 and newer. iOS 17+.""",
    "ru": """Pixelbroom — быстрый и приватный «уборщик» фото для iPhone.

Сканирует библиотеку фото локально на устройстве — ничего не уходит в облако — и показывает:

• Дубликаты фото (точные и близкие через локальное perceptual hashing)
• Старые скриншоты, которые незаметно копятся в галерее
• Размытые кадры, забытые в библиотеке
• Серии фото (10 почти одинаковых снимков за 2 секунды — оставь один)
• 100 самых больших видео и Live Photos, занимающих место

Каждое удаление подтверждаешь ты сам. iOS дополнительно показывает системный диалог — ничего не исчезает без твоего тапа.

PRIVACY-FIRST
• 100% на устройстве. Нет облака, нет сервера, нет телеметрии.
• Никаких SDK, аналитики, рекламы или трекинга.
• Pixelbroom видит только метаданные и уменьшенные превью — ничего не выгружается наружу.

PRO — разово, $9.99
Free режим даёт удалять до 20 фото в неделю, чтобы попробовать. Pro убирает лимит и открывает умные подсказки (старые скриншоты, повторы серий по годам). Одна покупка — навсегда. Без подписки.

Для iPhone 12 и новее. iOS 17+.""",
    "de-DE": """Pixelbroom ist ein schneller, privater Foto-Reiniger fürs iPhone.

Er scannt deine Mediathek lokal — nichts wird hochgeladen — und zeigt dir:

• Duplikate (exakt und nahezu identisch via on-device Perceptual Hashing)
• Alte Screenshots, die heimlich deine Mediathek füllen
• Unscharfe Fotos, die du vergessen hast zu löschen
• Serienaufnahmen (10 nahezu gleiche Fotos in 2 Sekunden — wähle das beste)
• Die 100 größten Videos und Live Photos

Du bestätigst jedes Löschen — iOS zeigt zusätzlich seinen eigenen Dialog.

PRIVACY-FIRST
• 100% auf dem Gerät. Keine Cloud, kein Server, keine Telemetrie.
• Keine SDKs, keine Analytics, keine Werbung, kein Tracking.

PRO — einmalig 9,99 $
Free löscht bis zu 20 Fotos pro Woche zum Ausprobieren. Pro entfernt das Limit und schaltet smarte Vorschläge frei (alte Screenshots, wiederkehrende Serien). Ein Kauf, für immer. Kein Abo.

Für iPhone 12 und neuer. iOS 17+.""",
    "fr-FR": """Pixelbroom est un nettoyeur de photos rapide et privé pour iPhone.

Il analyse ta photothèque localement — rien n'est envoyé en ligne — et te montre :

• Les doublons (exacts et similaires via perceptual hashing sur l'appareil)
• Les anciennes captures d'écran qui remplissent silencieusement la bibliothèque
• Les photos floues oubliées
• Les rafales (10 photos quasi identiques en 2 secondes — choisis la bonne)
• Les 100 plus gros vidéos et Live Photos

Tu valides chaque suppression — iOS affiche son propre dialogue système en plus.

PRIVACY-FIRST
• 100 % sur ton iPhone. Aucun cloud, aucun serveur, aucune télémétrie.
• Aucun SDK, aucune analytique, aucune pub, aucun pistage.

PRO — paiement unique de 9,99 $
La version gratuite supprime jusqu'à 20 photos par semaine pour essayer. Pro retire la limite et débloque les suggestions intelligentes (anciennes captures, rafales répétées). Un achat, pour toujours. Pas d'abonnement.

Pour iPhone 12 et plus récents. iOS 17+.""",
    "ja": """Pixelbroom は iPhone 用の高速・プライバシー重視の写真クリーナーです。

写真ライブラリを端末上で解析し（何もアップロードしません）、次を表示します：

• 重複写真（完全一致と類似 — 端末上の perceptual hashing による）
• ライブラリを静かに圧迫している古いスクリーンショット
• 削除し忘れたぼけた写真
• バースト（2秒で10枚のほぼ同じ写真 — ベストの1枚を選んで残す）
• ストレージを食っている動画と Live Photos の上位100件

削除はすべてあなたが確認します。iOS のシステム確認ダイアログも追加で表示されます。

PRIVACY-FIRST
• 100% オンデバイス。クラウドも、サーバーも、テレメトリーもありません。
• SDK・分析・広告・トラッキング、いずれもありません。

PRO — 買い切り $9.99
無料版は週20件まで削除でき、お試し可能。Pro で制限が解除され、スマート提案（古いスクショ、年をまたぐ反復バースト）も使えます。一度購入すれば永久に。サブスク無し。

iPhone 12 以降、iOS 17 以降に対応。""",
}

PROMO = {
    "en-US": "On-device duplicate detection. Free up gigabytes in minutes.",
    "ru":    "Локальный поиск дубликатов. Освободи гигабайты за минуты.",
    "de-DE": "On-device Duplikatsuche. Gigabytes in Minuten frei.",
    "fr-FR": "Détection de doublons sur appareil. Libère des gigaoctets en minutes.",
    "ja":    "端末上で重複検出。数分でギガバイト単位の空き容量。",
}

WHATS_NEW = {
    "en-US": "First release. Clean up your camera roll without leaving the device.",
    "ru":    "Первый релиз. Чисти галерею не выходя за пределы устройства.",
    "de-DE": "Erste Version. Mediathek aufräumen — alles bleibt auf dem Gerät.",
    "fr-FR": "Première version. Nettoyez votre photothèque sans rien envoyer.",
    "ja":    "初回リリース。端末外に何も送らずにカメラロールを整理。",
}

SUPPORT_URL = "https://igrkukan.github.io/Sweep/"
MARKETING_URL = "https://igrkukan.github.io/Sweep/"
PRIVACY_URL = "https://igrkukan.github.io/Sweep/privacy.html"


def main():
    # appInfo: localized name + subtitle, primary category, content rights
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appInfos", headers=asc_token.auth_headers())
    info = r.json()["data"][0]
    INFO_ID = info["id"]

    # 1. Primary category + content rights
    payload = {
        "data": {
            "type": "appInfos", "id": INFO_ID,
            "relationships": {
                "primaryCategory": {"data": {"type": "appCategories", "id": "UTILITIES"}}
            }
        }
    }
    r = requests.patch(f"https://api.appstoreconnect.apple.com/v1/appInfos/{INFO_ID}",
                       headers=H, data=json.dumps(payload))
    print(f"Set category: {r.status_code}")

    r = requests.patch(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}",
                       headers=H,
                       data=json.dumps({"data": {"type": "apps", "id": APP_ID, "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}}))
    print(f"Content rights: {r.status_code}")

    # 2. AppInfo localizations: name, subtitle, privacyPolicyUrl
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/appInfos/{INFO_ID}/appInfoLocalizations", headers=asc_token.auth_headers())
    existing_locs = {l["attributes"]["locale"]: l["id"] for l in r.json().get("data", [])}

    for locale in LOCALES:
        attrs = {
            "name": "Pixelbroom",
            "subtitle": SUBTITLE[locale],
            "privacyPolicyUrl": PRIVACY_URL,
        }
        if locale in existing_locs:
            loc_id = existing_locs[locale]
            r = requests.patch(f"https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/{loc_id}",
                               headers=H,
                               data=json.dumps({"data": {"type": "appInfoLocalizations", "id": loc_id, "attributes": attrs}}))
            print(f"  AppInfo loc {locale} PATCH: {r.status_code}")
        else:
            payload = {
                "data": {
                    "type": "appInfoLocalizations",
                    "attributes": {"locale": locale, **attrs},
                    "relationships": {"appInfo": {"data": {"type": "appInfos", "id": INFO_ID}}}
                }
            }
            r = requests.post("https://api.appstoreconnect.apple.com/v1/appInfoLocalizations",
                              headers=H, data=json.dumps(payload))
            print(f"  AppInfo loc {locale} POST: {r.status_code}")
            if r.status_code >= 300:
                print(f"    {r.text[:200]}")

    # 3. Version: copyright + releaseType + localizations
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions", headers=asc_token.auth_headers())
    version = r.json()["data"][0]
    VERSION_ID = version["id"]

    payload = {"data": {"type": "appStoreVersions", "id": VERSION_ID, "attributes": {
        "copyright": "© 2026 Igor Shkredov",
        "releaseType": "AFTER_APPROVAL",
    }}}
    r = requests.patch(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{VERSION_ID}",
                       headers=H, data=json.dumps(payload))
    print(f"Version attrs: {r.status_code}")

    # 4. Version localizations
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations", headers=asc_token.auth_headers())
    existing_vlocs = {l["attributes"]["locale"]: l["id"] for l in r.json().get("data", [])}

    for locale in LOCALES:
        # `whatsNew` нельзя редактировать у первой версии — это поле появляется
        # для подальшего апдейта. На version 1.0 пропускаем.
        attrs = {
            "description": DESCRIPTION[locale],
            "keywords": KEYWORDS[locale],
            "promotionalText": PROMO[locale],
            "marketingUrl": MARKETING_URL,
            "supportUrl": SUPPORT_URL,
        }
        if locale in existing_vlocs:
            loc_id = existing_vlocs[locale]
            r = requests.patch(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{loc_id}",
                               headers=H,
                               data=json.dumps({"data": {"type": "appStoreVersionLocalizations", "id": loc_id, "attributes": attrs}}))
            print(f"  Version loc {locale} PATCH: {r.status_code}")
            if r.status_code >= 300: print(f"    {r.text[:300]}")
        else:
            payload = {"data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {"locale": locale, **attrs},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}}},
            }}
            r = requests.post("https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations",
                              headers=H, data=json.dumps(payload))
            print(f"  Version loc {locale} POST: {r.status_code}")
            if r.status_code >= 300: print(f"    {r.text[:300]}")

    # 5. App Store Review details
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{VERSION_ID}/appStoreReviewDetail", headers=asc_token.auth_headers())
    review_data = r.json().get("data")
    review_payload_attrs = {
        "contactFirstName": "Igor",
        "contactLastName": "Shkredov",
        "contactPhone": "+375296036570",
        "contactEmail": "timbelwood@gmail.com",
        "demoAccountRequired": False,
        "notes": "Pixelbroom scans the photo library on-device and helps the user delete duplicates / screenshots / blurry shots. All deletions go through PHPhotoLibrary.performChanges → iOS shows its own confirm dialog. The app does NOT upload photos anywhere. No login required.",
    }
    if review_data:
        rid = review_data["id"]
        r = requests.patch(f"https://api.appstoreconnect.apple.com/v1/appStoreReviewDetails/{rid}",
                           headers=H,
                           data=json.dumps({"data": {"type": "appStoreReviewDetails", "id": rid, "attributes": review_payload_attrs}}))
        print(f"Review detail PATCH: {r.status_code}")
    else:
        payload = {"data": {
            "type": "appStoreReviewDetails",
            "attributes": review_payload_attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}}},
        }}
        r = requests.post("https://api.appstoreconnect.apple.com/v1/appStoreReviewDetails",
                          headers=H, data=json.dumps(payload))
        print(f"Review detail POST: {r.status_code}")
        if r.status_code >= 300: print(r.text[:300])


if __name__ == "__main__":
    main()
