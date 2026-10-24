# CandyLauncher

The default home screen for **CandyOS** (a custom Android distribution based on LineageOS). Built in Flutter.

Inspired by [Undefined's video](https://www.youtube.com/watch?v=SKSkAg-4wg8) on bringing back tactile, human mobile design without the modern clutter.

---

## What it does

- **Tactile UI:** Dark frosted glass cards, subtle blur, and classic Holo Cyan accents.
- **Smart Widgets:** Swipe inside the top card to switch between the analog/digital clock, a calendar, and live media playback controls (play/pause/skip for Spotify, YouTube Music, etc.).
- **Fast Search:** 
  - Real-time app filtering with prefix sorting.
  - Inline calculator (type math directly into the bar).
  - Wikipedia summaries with live definitions and photos.
  - Web search fallback.
- **Dock:** Quick-access dock with long-press support to pin/unpin apps or open system settings.

---

## Building & Running

### Requirements
- Flutter SDK (latest stable)
- Android device or emulator (Android 11+)

### Run locally
```bash
git clone https://github.com/LecSUSOff/thelauncher.git
cd thelauncher
flutter run
```

### Build APK
```bash
flutter build apk --release
```
The compiled APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## CandyOS Integration

This launcher is vendored into CandyOS under `apps/CandyLauncher` and configured via `Android.bp` to override stock `Launcher3`.

- **CandyOS Core:** [EHowardHill/candyos](https://github.com/EHowardHill/candyos)
- **Discussion:** Undefined UX/UI Discord