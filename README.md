# Evidence Archive (iOS MVP)

Local-first iOS app for structured evidence/document archiving.

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
- Text notes saved as evidence files
- Local storage under Application Support
- SHA-256 hash per evidence file
- Evidence timeline with search + sort
- Evidence detail editing (metadata only)
- QuickLook preview + share original file
- Case export to folder:
  - `00_Index.csv`
  - `hashes_sha256.txt`
  - `Evidence/` copied files
- Shared import architecture for future Share Extension

## Storage Layout

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
- Add Share Extension target manually

Detailed plan:
- `ShareExtensionImplementationPlan.md`

## Known Limitations

- ZIP export compression is not implemented yet (folder export is implemented).
- No iCloud sync / account system (intentionally local-only).
- No OCR or AI classification in this MVP.
