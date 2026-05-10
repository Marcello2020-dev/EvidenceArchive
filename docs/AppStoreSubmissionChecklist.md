# App Store Submission Checklist

This checklist covers the remaining App Store Connect and Apple Developer Portal work for Evidence Archive.

## 1. Privacy Manifest

Implemented in `EvidenceArchive/PrivacyInfo.xcprivacy`.

- Tracking: `false`
- Tracking domains: none
- Developer-collected data in the app manifest: none
- Required reason API:
  - `NSPrivacyAccessedAPICategoryFileTimestamp`
  - `C617.1`: file metadata for files inside the app, app group, or CloudKit/iCloud container
  - `3B52.1`: file metadata for files the user grants access to through imports

Before upload, create an Archive in Xcode and review the generated privacy report.

Apple references:
- https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api

## 2. In-App Purchase

Configure the full-version unlock in App Store Connect.

- Type: Non-Consumable
- Product ID: `dev.marcello2020.evidencearchive.full`
- Suggested reference name: `Evidence Archive Full Access`
- Suggested display name:
  - English: `Full Access`
  - German: `Vollversion`
- Suggested review note: unlocks unlimited case files and evidence items; the free version is limited to 2 case files and 3 evidence items per case.

Submission requirements:

- Complete price, availability, localization, review screenshot, and review notes.
- Ensure the In-App Purchase status is `Ready to Submit`.
- For the first In-App Purchase, select it on the app version page and submit it together with the app version.

Apple reference:
- https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase

## 3. iCloud / CloudKit

The project is configured for:

- Bundle ID: `dev.marcello2020.evidencearchive`
- CloudKit container: `iCloud.dev.marcello2020.evidencearchive`
- iCloud Documents container: `iCloud.dev.marcello2020.evidencearchive`
- Entitlements file: `EvidenceArchive/EvidenceArchive.entitlements`

Manual checks before App Store upload:

- In Apple Developer Portal, confirm the App ID has iCloud enabled.
- Confirm CloudKit and iCloud Documents are enabled for the container.
- Confirm the distribution provisioning profile includes the same iCloud container.
- Build and run a signed app on a real device signed in to iCloud with iCloud Drive enabled.
- Create at least one case and evidence item so SwiftData/CloudKit can create the development schema.
- In CloudKit Console, verify the record types and deploy the schema to production before TestFlight/App Store submission.

Apple references:
- https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app
- https://developer.apple.com/documentation/cloudkit/managing-icloud-containers-with-cloudkit-database-app
- https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit

## 4. App Privacy Details and Privacy Policy

App Store Connect requires a Privacy Policy URL for iOS apps.

Use `docs/PrivacyPolicy.md` as the source text, add a real contact method, and publish it at a stable public URL before submission.

Suggested App Privacy answer if the app stays as currently implemented:

- Tracking: No
- Third-party advertising: No
- Analytics: No
- Developer-collected data: No, assuming the developer does not access, receive, or process users' local/iCloud evidence content outside the app.

Important: If analytics, crash reporting with user identifiers, support uploads, external sync, or a backend are added later, update both App Store Connect privacy answers and `PrivacyInfo.xcprivacy`.

Apple references:
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy/
