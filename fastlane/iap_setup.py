"""Локализации + цена для Pro Lifetime IAP."""
import sys, json, requests
sys.path.insert(0, "/Users/iharshkredau/Sweep/fastlane")
import asc_token

H = {**asc_token.auth_headers(), "Content-Type": "application/json"}
IAP_ID = "6768285295"  # Pro Lifetime non-consumable

LOCALIZATIONS = {
    "en-US": {"name": "Pixelbroom Pro",  "description": "Unlimited deletions & smart suggestions."},
    "ru":    {"name": "Pixelbroom Pro",  "description": "Безлимит удаления и умные подсказки."},
    "de-DE": {"name": "Pixelbroom Pro",  "description": "Unbegrenztes Löschen & smarte Tipps."},
    "fr-FR": {"name": "Pixelbroom Pro",  "description": "Suppression illimitée et suggestions."},
    "ja":    {"name": "Pixelbroom Pro",  "description": "削除は無制限、スマート提案も解放。"},
}


def main():
    # 1. Localizations
    for locale, fields in LOCALIZATIONS.items():
        payload = {
            "data": {
                "type": "inAppPurchaseLocalizations",
                "attributes": {"locale": locale, **fields},
                "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": IAP_ID}}}
            }
        }
        r = requests.post("https://api.appstoreconnect.apple.com/v1/inAppPurchaseLocalizations",
                          headers=H, data=json.dumps(payload))
        print(f"  loc {locale}: {r.status_code}")
        if r.status_code >= 300 and "DUPLICATE" not in r.text:
            print(f"    {r.text[:200]}")

    # 2. Price schedule — Tier 9 ($9.99). Apple's pricePoint ID for $9.99 в USA = 10086.
    # Получаем availablePricePoints чтобы найти точный ID.
    r = requests.get(f"https://api.appstoreconnect.apple.com/v2/inAppPurchases/{IAP_ID}/pricePoints",
                     headers=asc_token.auth_headers(),
                     params={"filter[territory]": "USA", "limit": 200})
    points = r.json().get("data", [])
    tier_9_99 = None
    for p in points:
        price = p["attributes"].get("customerPrice")
        if price == "9.99":
            tier_9_99 = p["id"]
            break
    print(f"USA $9.99 pricePoint: {tier_9_99}")

    if not tier_9_99:
        print("Не нашли $9.99 — выставите цену в web UI.")
        return

    # Create iapPriceSchedule with manualPrices=[$9.99 in USA]
    payload = {
        "data": {
            "type": "inAppPurchasePriceSchedules",
            "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": IAP_ID}},
                "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${manual1}"}]},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
            }
        },
        "included": [{
            "type": "inAppPurchasePrices",
            "id": "${manual1}",
            "attributes": {"startDate": None},
            "relationships": {
                "inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": tier_9_99}},
            }
        }]
    }
    r = requests.post("https://api.appstoreconnect.apple.com/v1/inAppPurchasePriceSchedules",
                      headers=H, data=json.dumps(payload))
    print(f"Price schedule: {r.status_code}")
    if r.status_code >= 300:
        print(r.text[:400])


if __name__ == "__main__":
    main()
