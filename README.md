# Evidence Archive (iOS MVP)

Local-first iOS app for structured evidence/document archiving with iCloud sync support.

## Positioning

This app provides:
- local evidence archive
- structured documentation
- SHA-256 integrity hash
- exportable index
- private local processing

It does **not** claim legal certification or guaranteed court admissibility.

## Implemented MVP

- Case management (create/edit/delete)
- Evidence import from Files picker
- Evidence import from Photos picker (images/videos)
- Evidence capture from camera
- Document scanning with camera
- Text notes saved as evidence files
- Local storage under Application Support
- iCloud sync foundation for case metadata and evidence files:
  - SwiftData metadata sync via private CloudKit database
  - evidence files stored in the app iCloud Drive container when available
  - local Application Support fallback when iCloud is unavailable
- SHA-256 hash per evidence file
- Evidence timeline with search + sort
- Evidence detail editing (metadata only)
- QuickLook preview + share original file
- Freemium limits with StoreKit full-version unlock:
  - free: 2 case files
  - free: 3 evidence items per case
- Case export to folder:
  - `00_Index.csv`
  - `hashes_sha256.txt`
  - `Evidence/` copied files
- Shared import architecture for future Share Extension

## Storage Layout

Primary path when iCloud is available:

`iCloud Drive app container/Documents/EvidenceArchive/Cases/<caseUUID>/`

Fallback path:

`Application Support/EvidenceArchive/Cases/<caseUUID>/`

- `evidence/`
- `thumbnails/`
- `exports/`

## Run in Xcode

1. Open `EvidenceArchive.xcodeproj`.
2. Select scheme `EvidenceArchive`.
3. Run on iOS Simulator or device.

Command-line build:

```sh
xcodebuild -project EvidenceArchive.xcodeproj -scheme EvidenceArchive -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/evidencearchive-build build CODE_SIGNING_ALLOWED=NO
```

## Tests

Utility tests are provided in `EvidenceArchiveCore` package:

```sh
swift test --package-path EvidenceArchiveCore
```

Covered tests:
- safe filename sanitization
- duplicate filename resolution
- SHA-256 known vector
- CSV escaping

## Manual Xcode Steps Remaining

- Configure App Group capability for app + future extension target
- Set `AppGroupConfig.useAppGroupContainer = true` once App Group is active
- Enable iCloud for the app target in Signing & Capabilities:
  - Services: CloudKit and iCloud Documents
  - Container: `iCloud.dev.marcello2020.evidencearchive`
  - Ensure the same container exists in Certificates, Identifiers & Profiles
  - Keep Push Notifications enabled when Xcode adds it for CloudKit sync
  - Use devices signed in to iCloud with iCloud Drive enabled for real sync testing
- Add Share Extension target manually
- Configure a non-consumable In-App Purchase in App Store Connect matching `PurchaseConfiguration.fullAccessProductID`
- For local purchase testing, add/select a StoreKit configuration in the Xcode scheme or use an App Store Connect sandbox product
- Publish the privacy policy from `docs/PrivacyPolicy.md` at a stable public URL and enter it in App Store Connect
- Complete App Store Connect privacy answers and verify the generated Xcode privacy report

Detailed plan:
- `ShareExtensionImplementationPlan.md`
- `docs/AppStoreSubmissionChecklist.md`

## Known Limitations

- ZIP export compression is not implemented yet (folder export is implemented).
- iCloud sync is implemented as an Apple iCloud-only foundation; conflict resolution is limited to SwiftData/CloudKit defaults and file-level iCloud Drive behavior.
- No OCR or AI classification in this MVP.
