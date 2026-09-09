# uthme2

Unofficial companion app for University of Thessaly (UTH) students. It tracks grades from the university portal and browses the university restaurant menus. Built with Flutter, targeting Android, iOS, web, Linux, macOS and Windows.

## Features

- **Grades**: grades grouped by semester, with the average calculated either ECTS weighted or as a plain mean (toggleable)
- **Stats**: passed course count, total ECTS and most recent grade update
- **Restaurant menus**: pick a university restaurant and browse its menu by date, split into breakfast, lunch and dinner with serving hours
- **Menus without an account**: the menu section is reachable straight from the login screen
- **Android home screen widget**: grade stats on the home screen with tap to refresh
- **Bilingual**: English and Greek, following the system language or an explicit choice
- **Persistent login**: credentials stored encrypted on device, so the app opens straight to the grades screen

## Requirements

| Tool | Version |
|---|---|
| Flutter | 3.44.2 (stable) |
| Dart SDK | ^3.11.4 |
| JDK | 17 (needed for Android builds) |

## Getting started

```bash
flutter pub get
flutter run
```

Other targets:

```bash
flutter run -d chrome     # web
flutter run -d linux      # Linux desktop
flutter build apk         # Android release APK
flutter build web         # web release bundle
```

## Project layout

```
lib/
├── main.dart          Entry point. Reads stored credentials and seeds locale
│                      plus average mode before the first frame
├── models/            Grade, GradeStats, UniversityRestaurant, RestaurantMenu*
├── providers/         Riverpod state (grades, average mode)
├── screens/           Login, Grades, Menu, Settings
├── services/          API client and Android widget bridge
├── theme/             Colors, radii, text styles
├── widgets/           Grade ring, home widget card
└── l10n/              ARB translation files, locale controller and
                       generated localization Dart files
```

State management is Riverpod throughout. `gradesProvider` is an auto disposing `AsyncNotifierProvider` that owns fetching and refresh. Locale and average mode are `NotifierProvider`s that persist their value to secure storage.

## Backend

The app talks to a REST API. The base URL lives in `lib/services/api_service.dart`:

```
https://manraf.duckdns.org:4242/api
```

| Endpoint | Method | Purpose |
|---|---|---|
| `/get-grades` | POST | Validates credentials and returns grades, or a `taskId` for an async scrape |
| `/task-status/{taskId}` | GET | Polled while the backend scrapes the university portal |
| `/restaurants` | GET | Lists university restaurants |
| `/restaurants/{id}/menu` | GET | Menu for a `start` to `end` date range |
| `/user/preference` | POST | Saves the preferred restaurant for a user |

Grade fetching can be asynchronous. When `/get-grades` returns a `taskId`, the client long polls `/task-status/{taskId}` every 2.5 seconds and gives up after 2 minutes.

## Credential storage

`flutter_secure_storage` holds the following keys:

| Key | Contents |
|---|---|
| `username` | UTH portal username |
| `password` | UTH portal password |
| `app_locale` | `en`, `el`, or absent to follow the system |
| `grade_average_weighted` | Whether the average is ECTS weighted (defaults to true) |
| `preferred_restaurant_id_<username>` | Preferred restaurant per user |
| `preferred_restaurant_id` | Legacy key, read as a fallback |

Credentials are stored encrypted on device and sent to the API, which authenticates against the university portal on the user's behalf.

## Localization

Two locales exist: English (`lib/l10n/app_en.arb`) and Greek (`lib/l10n/app_el.arb`). `app_en.arb` is the template.

To add a string, add the key to **every** ARB file in alphabetical order, then regenerate:

```bash
flutter gen-l10n
```

The generated `lib/l10n/app_localizations*.dart` files are committed, so regenerate and commit them whenever an ARB file changes. A regular `flutter run` or `flutter build` also regenerates them, since `generate: true` is set in `pubspec.yaml`.

## Theming

Material 3 with light and dark schemes following the system setting. The "Aegean Citrus" palette lives in `lib/theme/app_theme.dart` (coral `#FF5436`, teal `#0FB5A8`, amber `#FFC53D`). JetBrains Mono, pulled through `google_fonts`, is used for grades, stats and dates.

## App icons

Masters live in `assets/logo/`. After changing them, regenerate every platform's icons:

```bash
dart run flutter_launcher_icons
```

## Android home screen widget

Built on the `home_widget` plugin. The native side is `android/app/src/main/kotlin/com/example/uthme2/GradeWidgetProvider.kt` with its layout in `android/app/src/main/res/layout/grade_widget.xml`. The Flutter side renders through `lib/widgets/widget_card.dart` and `lib/services/widget_service.dart`.

## Development

```bash
flutter analyze           # static analysis, the CI baseline is zero warnings
dart format lib/ test/    # formatting
flutter test              # tests
flutter clean             # drop build artifacts
```

Lints come from `package:flutter_lints` via `analysis_options.yaml`.

## Continuous integration

`.github/workflows/android-build.yml` runs on every push and pull request to `main`, and on manual dispatch. It pins Flutter 3.44.2 and JDK 17, runs `flutter analyze`, builds a release APK and uploads it as the `uthme2-release-apk` artifact.

Release builds are currently signed with the Flutter debug keystore (see `android/app/build.gradle.kts`), so CI artifacts are for testing only and cannot be published. Real signing needs a keystore plus `key.properties`, both of which are gitignored.

## Known rough edges

- `applicationId` is still the template default, `com.example.uthme2`
- Release signing is not set up (see above)

## Disclaimer

This is a student built project. It is not affiliated with, endorsed by, or operated by the University of Thessaly.
