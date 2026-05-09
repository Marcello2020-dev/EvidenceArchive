# Chat Archive

Rudimentary iOS prototype for viewing exported chat archives.

## Current MVP

- SwiftUI iPhone/iPad app
- Imports `.txt` WhatsApp-style chat exports through the system file picker
- Accepts `.zip` files as a placeholder entry so the import flow is visible
- Shows message counts, participant counts, recent message previews, and local search
- Keeps all data in memory for now

## Run

Open `ChatArchive.xcodeproj` in Xcode and run the `ChatArchive` scheme on an iOS simulator.

Command-line build:

```sh
xcodebuild -project ChatArchive.xcodeproj -scheme ChatArchive -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath .build/DerivedData build CODE_SIGNING_ALLOWED=NO
```

## Next Steps

- Persist imported archives with SwiftData
- Add real ZIP extraction and media indexing
- Parse dates and group message previews by day
- Add Share Sheet import handling
- Add tests for common WhatsApp export formats

