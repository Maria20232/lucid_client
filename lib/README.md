# Lucid client 0.3

Flutter source update for the Lucid food-label prototype. Use this with the
**updated Lucid backend 0.3**, including `/scan`, `/analyze`, and ingredient
explanation endpoints. This is a source overlay for your existing Flutter
project; generated Android/iOS/web/desktop projects are not included.

## Start here on Windows

1. Keep a copy or commit of your current `C:\dev\lucid_client` project.
2. Extract this package. Copy its `lib/`, `test/`, `pubspec.yaml`,
   `analysis_options.yaml`, and README into your existing `lucid_client` folder.
   Use the complete `lib/` folder: the updated screens depend on the new models,
   state controller, and services. Retain your platform folders.
3. Start the updated backend in a separate terminal.
4. Run these commands in PowerShell:

```powershell
cd C:\dev\lucid_client
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome --web-port 52000
```

The project keeps your supplied Dart SDK constraint `^3.13.5`. Use your existing
Flutter SDK that provides that Dart version. New dependencies are declared in
`pubspec.yaml`; `flutter pub get` regenerates the dependency lock file. No
fabricated lock file is supplied. Commit the generated lock after resolving and
testing successfully.

**Flutter and Dart are not installed in the preparation environment.** The
Flutter commands above have not been run here. Read `VALIDATION.md` for the
checks actually performed and the remaining device checks.

## What was fixed and added

- Replaced the uploaded JSON-formatted `ingredient.dart` with a real Dart model.
- Replaced zero-filled placeholder uploads with actual selected photo bytes.
- Added photo selection, Android/iOS camera capture, preview, and Android
  interrupted-picker recovery. Desktop/Chrome use photo selection.
- Added a manual text-entry path so OCR is not required for every input.
- Preserved raw OCR text, warnings, unknown fragments, and data versions from
  the backend instead of returning only a list of ingredients.
- Added an explicit review flow. Users edit text, call `/analyze`, review matches,
  and acknowledge their review before viewing/saving results. Any edit invalidates
  the current analysis and review acknowledgment until checked again.
- Kept fuzzy suggestions separate from confirmed matches. Selecting a suggestion
  edits the text and requires rechecking; nothing is automatically confirmed.
- Added ingredient source information and a source link. Current explanations
  are taxonomy templates, not generated RAG explanations.
- Added exact-ID personal highlights stored locally, with ingredient search.
- Added local saving of up to 20 reviewed product records. Saving the 21st keeps
  the newest 20. Records include text, unknown fragments, and data versions.
- Added comparison of any two saved products, including different categories.
  It compares recognized ingredient IDs only and preserves uncertainty.
- Added editable server URL and English/English+Malay OCR settings, connection
  testing, request timeouts, and actionable API errors.
- Retained the dark Lucid design while making pages scrollable and allowing
  controls/text to wrap on small screens.

## First manual run

Start with **Enter ingredients**, using:

```text
Ingredients: sugar, wheat flour, palm oil, E322, salt.
```

Tap **Check ingredients**, inspect the matches, check the review box, and continue.
Open an ingredient, inspect its source, and optionally highlight it. Save the
product with a name. Repeat for another label, then select both in **Saved
products & compare**.

Try `Ingredients: sugra, salt.` to verify that the typo stays unresolved until
reviewed. Try editing text after checking it: the Continue button must become
disabled until you check the new text and acknowledge review again.

Then try **Scan a label → Choose photo** using a real, supported image. The client
limits input files to 10 MiB. On mobile it requests a bounded image size from the
picker; desktop pickers may ignore resize options. The backend independently
enforces file and pixel limits. HEIC is not supported by the included backend;
choose or export a JPEG/PNG if decoding fails. Cropping and perspective correction
are not implemented in this client.

## Backend URL and OCR language

Open **Settings & highlights** to change the server URL. Save it before scanning.

| Target | Default or configuration |
|---|---|
| Chrome on the backend PC | `http://localhost:8000` |
| Standard Android emulator | `http://10.0.2.2:8000` |
| Physical phone | Set `http://YOUR_PC_LAN_IP:8000` |

For a physical phone, use the same Wi-Fi, run the backend with
`python -m uvicorn main:app --host 0.0.0.0 --reload`, and allow the local connection
through your PC firewall. Native app requests do not use browser CORS. The
backend's default CORS configuration allows localhost Flutter web development.
If you host Flutter web elsewhere, configure its exact origin on the backend.

You can set an initial default at build time:

```powershell
flutter run -d chrome --web-port 52000 --dart-define=API_BASE_URL=http://localhost:8000
```

A saved in-app URL takes precedence over the initial default. Use a stable web
port while developing if you want browser-local settings to remain available
across runs. Changing the browser origin changes the local-storage location.

The English+Malay option sends `eng+msa` as an encoded query parameter. Install
both Tesseract models on the backend first. The health endpoint reports readiness
for the **backend's configured default language**, not every selectable language.
A missing selected language produces a specific upload error.

## Android and iOS setup

Your platform source files were not uploaded, so this package does not overwrite
them. Follow `platform_setup/README.md` before running on a phone. For Android
development over HTTP, merge the supplied debug/profile manifest snippets. Use
HTTPS for a release deployment.

## Project layout

| Path | Role |
|---|---|
| `lib/models/` | Ingredient, analysis, saved-product, and comparison data |
| `lib/services/api_service.dart` | HTTP contract, upload, errors, URL settings |
| `lib/services/local_store.dart` | Small local preference store |
| `lib/state/app_controller.dart` | Settings, highlights, queued local writes |
| `lib/screens/` | Welcome, scan, review, results, details, settings, saved products, comparison |
| `lib/widgets/common.dart` | Shared page/list/notice widgets |
| `lib/theme/` | Dark theme and colors |
| `test/` | Models, networking, local state, and review-flow tests |

The old static `ApiService.scanImage()` now returns a full `AnalysisResult` through
an instance-based service. Existing screens were migrated together. New services
support injected HTTP clients and local stores for isolated tests.

## Data and comparison scope

Photos are not copied into saved-product records. The active photo is sent to
the configured backend, then retained in memory for review until the route is
discarded. The picker/operating system may keep its own temporary camera files.
Locally saved records contain label text, matched IDs, unknown fragments,
timestamps, and KB/matcher versions. Highlights and server settings are also local.
These are simple preferences, not an encrypted or durable research database.

Highlights apply to exact IDs. Selecting `milk` does not automatically include
all derivatives or subtypes. The app does not infer an allergen's absence or
dietary compliance. Source ambiguity and unresolved fragments remain unresolved.

Comparison groups are **recognized in both**, **recognized only in A**, and
**recognized only in B**. A missing recognized ID is not proof of absence. KB or
matcher version differences are shown. The app does not derive a health score,
nutrition ranking, or quantities from ingredient counts.

## Remaining work before a research-ready app

- Run analyzer, tests, builds, and real-device flows on your SDK; fix any
  dependency or platform integration issues found there.
- Evaluate OCR and linking on your real English/Malay label photos.
- Add a curated evidence corpus and evaluated retrieval/generation for RAG.
- Implement and test the paper's full comparison rules, nutrition units,
  missing-data handling, and criterion-specific comparisons separately.
- Add durable storage/export and study instrumentation if needed for the study.
- Measure comprehension and comparison outcomes using the evaluation protocol.

The current client does not establish clinical, regulatory, or user-study outcomes.

## Implementation references

- [Image picker and platform setup](https://pub.dev/packages/image_picker)
- [Local preferences](https://pub.dev/packages/shared_preferences)
- [Source URL launching](https://pub.dev/packages/url_launcher)
- [HTTP multipart requests](https://pub.dev/documentation/http/latest/http/MultipartRequest-class.html)
- [Android emulator host address](https://developer.android.com/studio/run/emulator-networking-address)
- [Android network security configuration](https://developer.android.com/privacy-and-security/security-config)
