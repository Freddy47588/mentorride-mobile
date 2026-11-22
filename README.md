<div align="center">
  <img src="assets/images/mentorride_logo.png" alt="MentorRide logo" width="96" />

# MentorRide Mobile

**Motorcycle Maintenance History, Cost Analytics & Service Scheduler**

[![Flutter](https://img.shields.io/badge/Flutter-3.44%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00B4AB)](https://riverpod.dev)
[![CI](https://github.com/Freddy47588/mentorride-mobile/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/Freddy47588/mentorride-mobile/actions/workflows/flutter_ci.yml)

</div>

MentorRide is an Android mobile application for tracking motorcycles, service records, maintenance costs, service schedules, and local reminders. All records are user-entered and stored per account in Cloud Firestore.

> **Note:** The in-app user interface is localized in Bahasa Indonesia for local riders, while this repository documentation is written in English.

## Features

- **Firebase Authentication:** Registration, login, password reset, profile name updates, and logout via Firebase Email/Password authentication.
- **First-Run Onboarding:** Three-step onboarding flow with completion state stored locally via `shared_preferences` (not in Firestore).
- **Vehicle Management & Monotonic Odometer:** Full vehicle CRUD, per-user active vehicle selection, and quick odometer updates. Firestore transactions ensure odometer readings never decrease; identical values are treated as no-ops.
- **Vehicle Archiving:** Archive vehicles while retaining full service history, schedules, and odometer logs. Archived vehicles cannot be selected as active and can be restored or permanently deleted with strong confirmation.
- **Odometer History & Trends:** Tracks odometer increments from manual updates or service records, with 30-day to 1-year charts and monthly usage statistics.
- **Service Records:** Multi-item service entries with automatic cost totals, local search (workshop, component, notes), date/cost filters, and transactional vehicle odometer updates.
- **Local Maintenance Statistics:** Computes service counts, total and average costs, and most-serviced components directly from loaded records.
- **On-Device Report Export:** Exports active vehicle reports to A4 PDF or UTF-8 CSV and shares them via the Android share sheet without requiring legacy storage permissions.
- **Local Maintenance Presets:** Built-in local preset references for common motorcycle components and default intervals (no external datasets required).
- **Deterministic Maintenance Condition:** Calculates maintenance readiness and next-service estimates deterministically from local presets, service history, schedules, dates, and odometer readings.
- **Service Schedules & Local Reminders:** Supports optional due dates and due odometers using a shared domain status calculator, stable local notification IDs, completion states, and quick follow-up scheduling.
- **Dashboard & Calendar:** Active vehicle overview, latest service, upcoming schedule, monthly/yearly spend, 6-month cost chart, monthly maintenance calendar, local JSON backup/restore with ID remapping, list/timeline view toggle, and System/Light/Dark themes.
- **Accessible Material 3 UI:** Loading, error, and empty states, form validation, snackbars, confirmation dialogs, and reduced-motion-aware animations.

## Tech Stack

- **Framework & Language:** Flutter 3.44+ and Dart 3.12+
- **UI & Localization:** Material 3, `flutter_localizations`, `fl_chart`
- **State & Navigation:** Riverpod (without code generation), GoRouter with auth redirects
- **Backend (Firebase Spark-compatible):** Firebase Core, Firebase Authentication, Cloud Firestore
- **Notifications & Timezone:** `flutter_local_notifications`, `timezone` (`Asia/Jakarta`)
- **Utilities & Export:** `shared_preferences`, `uuid`, `intl`, `pdf`, `path_provider`, `share_plus`, `file_picker`, `package_info_plus`

## Spark-Only Architecture

MentorRide is designed to stay compatible with the **Firebase Spark** (free) plan. It uses only **Firebase Authentication** and **Cloud Firestore**—without Firebase Storage, Cloud Functions, Firebase Messaging, Firebase Extensions, external backends, or paid Google Cloud services. Maintenance presets remain local reference data, and exported reports/JSON backups are generated in temporary device storage prior to sharing.

## Project Structure

```text
lib/
├── app/                         Theme, router, and application root
├── core/                        Firebase, error handling, notifications, storage, utilities
├── features/
│   ├── auth/                    Authentication and user profile
│   ├── dashboard/               Home screen aggregation and UI
│   ├── navigation/              Bottom navigation shell
│   ├── onboarding/              First-run experience
│   ├── profile/                 Profile, notification permissions, and logout
│   ├── service_records/         Service history and costs
│   ├── service_reports/         Vehicle report mapping and PDF/CSV export
│   ├── service_schedules/       Schedules and local reminders
│   └── vehicles/                Vehicle CRUD and active selection
├── shared/                      Cross-feature reusable widgets
├── firebase_options.dart        FlutterFire generated client configuration
└── main.dart                    Firebase and notification bootstrap
```

Each feature separates domain models, data adapters/repositories, providers, controllers/services, and presentation screens. Models use explicit `fromMap`, `toMap`, and `copyWith` methods without code generation. Date and odometer due statuses are computed by a single shared domain calculator across the dashboard, lists, and detail views.

## Cloud Firestore Schema

```text
users/{uid}
├── displayName, email, createdAt, updatedAt
└── vehicles/{vehicleId}
    ├── name, brand, model, year, plateNumber, currentOdometer, isArchived
    ├── createdAt, updatedAt
    ├── odometer_logs/{logId}
    │   └── odometer, recordedAt, source ("manual_update" | "service_record")
    ├── service_records/{recordId}
    │   ├── serviceDate, odometer, workshop, items, totalCost, notes
    │   └── createdAt, updatedAt
    └── service_schedules/{scheduleId}
        ├── title, serviceType, dueDate, dueOdometer
        ├── reminderAt, reminderEnabled, localNotificationId, status
        └── createdAt, updatedAt
```

Rupiah amounts, odometer values, years, and notification IDs are stored as integers. `createdAt` and `updatedAt` use `FieldValue.serverTimestamp()` and may temporarily be `null` before local writes are acknowledged by the server.

## Firebase Configuration

This repository expects the following Android FlutterFire configuration:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- Android application ID: `com.mentorrideapp.mentorride`

To link a different Firebase project, run the FlutterFire CLI for Android:

```bash
flutterfire configure --platforms=android
```

In Firebase Console, enable:
1. **Authentication** with the **Email/Password** sign-in provider.
2. **Cloud Firestore** using the `(default)` database.

Never commit service-account keys, Firebase Admin SDK credentials, `.env` files, Android keystores, or private tokens.

## Getting Started

Ensure the Flutter SDK, Android SDK, and an Android device or emulator are available:

```bash
flutter pub get
flutter run
```

Local reminders use the `Asia/Jakarta` timezone and Android scheduling modes that do not require exact-alarm permissions. Android 13+ prompts for notification permission when reminders are enabled. Scheduled notifications are automatically canceled when a schedule is edited, deleted, marked complete, its parent vehicle is deleted, or the user logs out.

> Local reminders are scheduled based on `reminderAt`, not live hardware odometer sensors. `dueOdometer` thresholds are evaluated when the user updates the odometer or loads updated data in the app.

## Firestore Security Rules

`firestore.rules` restricts read/write access strictly to authenticated users under their own `users/{uid}` subtree:
- `odometer_logs` are immutable (no updates; deletion is permitted only by the owner to support permanent vehicle cascade deletion).
- Vehicle writes enforce that `currentOdometer` is a non-negative integer and never lower than the previously stored value.
- All other paths are denied by default. No composite indexes are currently required (`firestore.indexes.json` remains empty).

Review the active Firebase project before manually deploying rules:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

## Validation & Testing

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Unit and widget tests run offline without hitting live Firebase using fakes under `test/`. Coverage includes due-date/odometer calculators, monotonic odometer enforcement, local presets, follow-up schedule defaults, onboarding, search/filter, statistics aggregation, CSV/PDF export serialization, filename sanitization, and small-screen/large-text layout checks.

## Continuous Integration

[`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml) runs on every push and pull request to `main` using Flutter 3.44.2 and Java 17. It verifies formatting, static analysis, the full test suite, and a debug APK build. It does not deploy Firebase rules or publish releases automatically.

## Building a Release APK

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Gradle does not sign release builds with a debug key. Before running `flutter build apk --release`, create a developer keystore outside the repository and add a local (gitignored) `android/key.properties` file containing `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`.

The signed release APK is output to `build/app/outputs/flutter-apk/app-release.apk`. See [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) and [`RELEASE_NOTES.md`](RELEASE_NOTES.md) for `1.0.0` release preparation.

## Engineering Notes

- Initial target platform is Android with Indonesian in-app copy.
- Because Cloud Firestore does not auto-delete subcollections, deleting a vehicle performs a cascade delete and cancels its scheduled notifications.
- Vehicle odometer values are monotonic across quick updates, vehicle edits, and new service records. Editing or deleting past service records does not roll back the vehicle's current odometer.
- The app intentionally avoids AI dependencies, Firebase Cloud Messaging, Cloud Functions, and external datasets.
