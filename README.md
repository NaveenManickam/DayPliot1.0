# DayPilot — Offline-first Android planner

DayPilot is a Flutter/Dart Android planner with a soft-white rounded-card interface, blue/coral accents, quick-add actions and a week/month/day planner. It stores personal records locally and works without a login or cloud account.

## Android identity

- App name: `DayPilot`
- Application ID: `com.naveenmanickam.daypilot`
- Flutter package: `daypilot`
- Android minimum SDK: 24
- Current source version: `1.0.0+1`

## App modules

- **My Day:** local-time greeting, locally bundled wisdom quotes (English and Tamil), today's tasks, task priorities, completion, manual reorder, habits, streaks, missed-day counts, water and exercise summaries.
- **My Planner:** month, week, day and agenda views; date indicators; date-filtered tasks/events/notes; recurring events; date-linked notes.
- **My Notes:** searchable title/body notes with add, edit and delete; separate from planner date notes.
- **My Progress:** day/week/month/year task totals, task-completion chart, habit consistency, activity heatmap, water and exercise totals, sleep-duration and mood-score trend charts, and editable recent sleep/mood/journal records.
- **Quick add:** Task, Habit, Event, Note, Journal, Water, Exercise, Sleep and Mood.
- **Personal logs:** daily journal, water intake and target, exercise duration, bedtime/wake time, and mood check-ins.
- **Settings:** display name, light/dark/system appearance, English/Tamil language, local notifications, optional PIN, Android biometric unlock, and encrypted backup export/restore through Android's file picker.
- **Offline storage:** SQLite records and local preferences. Core app use does not require network access.

## Reminders

Task and event reminders are one-time scheduled reminders. Habit reminders repeat daily or on the selected weekdays. The app rebuilds scheduled reminders from saved local records on launch. Android notification and exact-alarm permissions, plus device battery restrictions, can affect delivery.

## Security and backups

- App PINs are stored as salted PBKDF2-HMAC-SHA256 hashes.
- Exported backups are saved as JSON files using Android's save-file picker. They use PBKDF2-HMAC-SHA256 key derivation and AES-256-GCM authenticated encryption. Restore supports selecting a JSON file or pasting backup JSON. The user-created password is required to restore an encrypted backup.
- Older plain JSON backups remain importable for backward compatibility.
- The app PIN is an access gate; it does **not** encrypt the SQLite database itself. Local database encryption and secure key storage remain a separate security enhancement. Keep the backup password safe; it cannot be recovered.

## Build locally

Requires Flutter 3.50.0 stable and Java 17.

```bash
flutter create --project-name daypilot --org com.naveenmanickam --platforms=android .
python3 tool/configure_android.py
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## GitHub Actions release

The `DayPilot Android Release` workflow builds the Android host project, configures the package ID, notification receivers and biometric bridge, runs dependency installation, Dart analysis and tests, then builds and uploads `daypilot-android-release`. Download the artifact ZIP from the successful workflow run and extract `app-release.apk`.

## Verification notes

A successful GitHub Actions build confirms analysis, automated tests and APK packaging. It does not replace installation and runtime testing on a physical Android device. Before publishing, verify first launch, local persistence after force-close/restart, notification permission flows, daily/weekday habit reminders, biometric availability, encrypted backup/restore with correct and incorrect passwords, and Tamil rendering on the target phone. The supplied reference video remains the visual source of truth; final pixel-level comparison requires checking the app on-device against that video.
