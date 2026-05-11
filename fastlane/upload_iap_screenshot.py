"""Заливка Review Screenshot для IAP — Apple требует для каждого product."""
import hashlib, json, sys
from pathlib import Path
import requests

sys.path.insert(0, "/Users/iharshkredau/Sweep/fastlane")
import asc_token

H = {**asc_token.auth_headers(), "Content-Type": "application/json"}
IAP_ID = "6768285295"
IMAGE = Path("/tmp/pixelbroom-screens/03-privacy.png")


def md5(p): h=hashlib.md5(); h.update(p.read_bytes()); return h.hexdigest()


def upload():
    data = IMAGE.read_bytes()
    payload = {
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "attributes": {"fileName": IMAGE.name, "fileSize": len(data)},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": IAP_ID}}}
        }
    }
    r = requests.post("https://api.appstoreconnect.apple.com/v1/inAppPurchaseAppStoreReviewScreenshots",
                      headers=H, data=json.dumps(payload))
    if r.status_code >= 300:
        print(f"reserve: {r.status_code} {r.text[:200]}")
        return
    d = r.json()["data"]
    sid = d["id"]
    for op in d["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        rr = requests.request(op["method"], op["url"], headers=headers, data=chunk)
        if rr.status_code >= 300:
            print(f"upload: {rr.status_code}")
            return
    r = requests.patch(f"https://api.appstoreconnect.apple.com/v1/inAppPurchaseAppStoreReviewScreenshots/{sid}",
                       headers=H,
                       data=json.dumps({"data": {"type": "inAppPurchaseAppStoreReviewScreenshots", "id": sid,
                                                  "attributes": {"uploaded": True, "sourceFileChecksum": md5(IMAGE)}}}))
    print(f"commit: {r.status_code}")


if __name__ == "__main__":
    upload()
