# Share Extension Implementation Plan (Manual Xcode Steps)

This MVP includes shared import logic (`ChatArchive/Import/SharedImportService.swift`) and app-group-aware storage configuration (`ChatArchive/Utilities/AppGroupConfig.swift`).

The Share Extension target itself still requires manual Xcode setup.

## 1) Add Share Extension target

1. Open `ChatArchive.xcodeproj`.
2. `File` -> `New` -> `Target`.
3. Choose `Share Extension` (iOS).
4. Name example: `EvidenceArchiveShareExtension`.
5. Keep default activation rule, then refine in step 4.

## 2) Enable App Groups in both targets

1. Select app target `ChatArchive` -> `Signing & Capabilities`.
2. Add capability `App Groups`.
3. Add: `group.com.example.EvidenceArchive` (or your production identifier).
4. Repeat for `EvidenceArchiveShareExtension` target.
5. In `AppGroupConfig.swift`, set:
   - `groupIdentifier` to the same value
   - `useAppGroupContainer = true`

## 3) Share code with extension target

Add these files to both app and extension targets:

- `ChatArchive/Models/CaseCategory.swift`
- `ChatArchive/Models/EvidenceType.swift`
- `ChatArchive/Models/CaseFile.swift`
- `ChatArchive/Models/EvidenceItem.swift`
- `ChatArchive/Utilities/AppGroupConfig.swift`
- `ChatArchive/Utilities/SafeFilename.swift`
- `ChatArchive/Utilities/StorageLayout.swift`
- `ChatArchive/Services/HashService.swift`
- `ChatArchive/Services/FileImportService.swift`
- `ChatArchive/Services/EvidenceError.swift`
- `ChatArchive/Import/SharedImportService.swift`

## 4) Configure accepted attachment types

In extension `Info.plist`, configure activation rules for:

- PDF (`com.adobe.pdf`)
- Images (`public.image`)
- Text (`public.plain-text`)
- ZIP (`public.zip-archive`)
- Audio/video (`public.audio`, `public.movie`)

## 5) Build extension UI

Recommended flow:

1. Host SwiftUI inside extension controller.
2. Read incoming `NSExtensionItem` attachments.
3. Resolve file URLs/data from `NSItemProvider`.
4. Show:
   - case picker (existing cases)
   - quick create case option
   - optional source/tags/note fields
5. Call `SharedImportService.importFileURLs(...)`.
6. Close extension with success/failure feedback.

## 6) Verify end-to-end

1. Run app once, create a test case.
2. From Files/Photos/Safari share menu, choose extension.
3. Import into existing case and verify:
   - file copied under App Group container
   - metadata appears in app timeline
   - SHA-256 present

## 7) TODO markers

- TODO(share-ext): Add extension target UI and case picker.
- TODO(share-ext): Map `NSItemProvider` payloads to local temp URLs reliably.
- TODO(share-ext): Add extension-focused UI tests once target exists.
