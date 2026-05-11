"""Заливка 3 скриншотов 1290×2796 (APP_IPHONE_67) во все 5 локалей.

Все локали получают тот же английский набор изображений — для MVP
переводить mock-UI не нужно (текст внутри картинки минимален).
"""
import hashlib, json, sys
from pathlib import Path
import requests

sys.path.insert(0, "/Users/iharshkredau/Sweep/fastlane")
import asc_token

BASE = "https://api.appstoreconnect.apple.com"
H = {**asc_token.auth_headers(), "Content-Type": "application/json"}
VERSION_ID = "d7fa5057-88cf-4f47-805f-5add72b59020"
SCREENS_DIR = Path("/tmp/pixelbroom-screens")
DISPLAY = "APP_IPHONE_67"

LOCALES = ["en-US", "ru", "de-DE", "fr-FR", "ja"]


def md5(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def get_or_create_screenshot_set(loc_id: str) -> str | None:
    r = requests.get(f"{BASE}/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets",
                     headers=asc_token.auth_headers())
    for s in r.json().get("data", []):
        if s["attributes"]["screenshotDisplayType"] == DISPLAY:
            return s["id"]
    payload = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": DISPLAY},
            "relationships": {"appStoreVersionLocalization": {
                "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
            }}
        }
    }
    r = requests.post(f"{BASE}/v1/appScreenshotSets", headers=H, data=json.dumps(payload))
    if r.status_code >= 300:
        print(f"  create set fail: {r.status_code} {r.text[:200]}")
        return None
    return r.json()["data"]["id"]


def upload_screenshot(set_id: str, path: Path):
    data_bytes = path.read_bytes()
    payload = {
        "data": {
            "type": "appScreenshots",
            "attributes": {
                "fileName": path.name,
                "fileSize": len(data_bytes),
            },
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}
        }
    }
    r = requests.post(f"{BASE}/v1/appScreenshots", headers=H, data=json.dumps(payload))
    if r.status_code >= 300:
        print(f"    reserve fail: {r.status_code} {r.text[:200]}")
        return
    rdata = r.json()["data"]
    screenshot_id = rdata["id"]
    ops = rdata["attributes"]["uploadOperations"]
    for op in ops:
        chunk = data_bytes[op["offset"]:op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        rr = requests.request(op["method"], op["url"], headers=headers, data=chunk)
        if rr.status_code >= 300:
            print(f"    upload fail: {rr.status_code}")
            return
    patch = {
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": md5(path)},
        }
    }
    r = requests.patch(f"{BASE}/v1/appScreenshots/{screenshot_id}", headers=H, data=json.dumps(patch))
    print(f"    {path.name}: commit {r.status_code}")


def main():
    r = requests.get(f"{BASE}/v1/appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations",
                     headers=asc_token.auth_headers())
    locs = {l["attributes"]["locale"]: l["id"] for l in r.json().get("data", [])}

    files = sorted(SCREENS_DIR.glob("*.png"))
    for locale in LOCALES:
        if locale not in locs:
            print(f"skip {locale} — нет localization")
            continue
        print(f"  {locale}:")
        set_id = get_or_create_screenshot_set(locs[locale])
        if not set_id: continue
        for f in files:
            upload_screenshot(set_id, f)


if __name__ == "__main__":
    main()
