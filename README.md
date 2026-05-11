# Sweep

Privacy-first photo cleaner for iPhone. Finds duplicates, blurry shots, old screenshots, large videos — all on-device.

- **Bundle ID**: `by.timberbid.sweep`
- **Apple Team**: `U5BAN54DL2`
- **Platforms**: iOS 17+ (iPhone-only)
- **Web**: https://igrkukan.github.io/Sweep/

## Build

```bash
brew install xcodegen
git clone https://github.com/iGrKukan/Sweep.git ~/Sweep
cd ~/Sweep
xcodegen generate
open Sweep.xcodeproj
```

## ASC submission

Setup ASC API key (shared with Voicekeep):

```bash
bash fastlane/setup_secrets.sh   # symlink to iCloud Drive
```

Then fastlane/asc_token.py mints JWT tokens for API calls.

App Store Connect record itself must be created in web UI first (Apple
doesn't allow `POST /v1/apps`). After that everything else (metadata,
screenshots, IAPs) goes through ASC API — see `fastlane/`.

## Architecture

- `Sweep/App/SweepApp.swift` — entry point, environment объекты
- `Sweep/Core/PhotoAuthorization.swift` — PHAuthorizationStatus gating
- `Sweep/Core/ScanCoordinator.swift` — orchestrator, 6 detection passes
- `Sweep/Core/PerceptualHash.swift` — dHash + Laplacian variance
- `Sweep/Core/PurchaseManager.swift` — StoreKit 2, isPro entitlement
- `Sweep/Core/ThumbnailLoader.swift` — NSCache + PHCachingImageManager
- `Sweep/UI/` — SwiftUI views (RootView гейтит auth → scan-state machine)
- `StoreKitTesting/Sweep.storekit` — локальный IAP-конфиг

## License

All rights reserved.
