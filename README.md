# DayPilot — Flutter source project

DayPilot is a fresh, offline-first Android planner written in Dart and Flutter. Its source is created independently from any earlier app project. The visual direction is based on the supplied DayPilot reference video: a light dashboard, curved soft background, rounded white cards, blue/coral task blocks, compact progress circles and a week/timeline planner.

## Android identity

- App name: `DayPilot`
- Android application ID: `com.naveenmanickam.daypilot`
- Flutter package: `daypilot`
- Current source version: `1.0.0+1`
- Android minimum SDK: 24 (Flutter project baseline)

## Included modules

- **My Day:** local-time greeting, editable display name, locally bundled wisdom quotes, today's tasks, priorities, completion, manual reorder, habits, streaks/missed days, water and exercise summaries.
- **My Planner:** month, week, day and agenda views; date indicators; date-filtered tasks/events/notes; event recurrence and completion; date-linked notes.
- **My Notes:** searchable title/body notes, edit and delete; separate from date-linked planner notes.
- **My Progress:** day/week/month/year task totals, task completion chart, habit consistency, activity heatmap, water totals, exercise minutes and editable recent sleep/mood/journal history, all calculated from SQLite records.
- **Quick add:** Task, Habit, Event, Note, Journal, Water, Exercise, Sleep and Mood forms.
- **Personal logs:** daily journal, water intake and target, exercise duration, bedtime/wake time, and mood entries. Recent sleep, mood and journal records can be opened and edited from My Progress.
- **Settings:** name, light/dark/system appearance, English/Tamil locale selection, local notifications, optional PIN, optional Android biometric unlock and JSON backup export/restore.
- **Storage:** SQLite records with create/read/update/delete and transactional restore. No login, network or cloud service is needed for the app's core functions.

## Build on a computer with Flutter installed

The Android host folder is generated from the Flutter SDK template by the bootstrap step so it is guaranteed to be a new Flutter Android shell, not a reused legacy native project.

```bash
flutter --version
flutter create --project-name daypilot --org com.naveenmanickam --platforms=android .
python tool/configure_android.py
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build apk --release
```

On macOS/Linux, use `python3` instead of `python` when that is the installed command. The Android bootstrap pins Android Gradle Plugin 9.3.1 with its required Gradle 9.5.0 wrapper, Android compile SDK 37 and Java 17. The biometric prompt is provided by AndroidX Biometric through a small platform channel, avoiding a second Flutter lifecycle plugin.

The release APK is normally written to:

`build/app/outputs/flutter-apk/app-release.apk`

## GitHub Actions APK build

A dedicated workflow is included at `.github/workflows/android.yml`. Push this project to a new GitHub repository (the `main` or `master` branch) or manually run **DayPilot Android Release** from the Actions tab. The workflow:

1. Checks out this source project.
2. Installs Java 17 and Flutter 3.50.0.
3. Generates a fresh Android host project.
4. Applies the package ID, notification alarm receivers/permissions, desugaring and biometric activity setup.
5. Runs `flutter pub get`, launcher icon generation, `flutter analyze` and `flutter test`.
6. Builds the release APK and uploads it as the `daypilot-android-release` workflow artifact.

## Important delivery / verification status

This source package does **not** contain a compiled APK. The current build container does not have Flutter/Dart or the Android SDK installed, and its network access cannot download them; therefore `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --release`, emulator installation and runtime notification checks have not been executed here. The workflow is supplied to perform those steps in GitHub Actions, but it has not yet run and no successful APK artifact is claimed.

The implementation is an initial functional source build, not a certified production release. Before publishing, verify the Android workflow end-to-end and test scheduled alarms on physical devices (OEM battery optimisations can affect background scheduling). Habit reminders are saved as individual scheduled reminders rather than an automatically repeating recurrence. Sleep and mood records are stored locally and recent entries are visible/editable from My Progress; dedicated long-term sleep and mood trend visualisations and richer journal analytics remain future enhancements. Tamil locale is configured and the main navigation/settings strings are translated, but not every label and form description has a Tamil translation yet.

The optional app PIN is a local access gate using a salted hash; it does not encrypt the SQLite database. Backup JSON is plain text, so store exported backups securely. Restore replaces the app's current local record set after validation.
