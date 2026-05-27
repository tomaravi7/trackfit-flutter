# TrackFit Mobile - Flutter Port

This is a complete mobile port of the TrackFit fitness application in Flutter. It replicates all the features, layouts, custom responsive views, and animations from the Next.js web application.

---

## Getting Started

### Prerequisites

- **Flutter SDK** (stable, >=3.0.0) — [install guide](https://docs.flutter.dev/get-started/install)
- **Android**: Android Studio or Android SDK command-line tools
- **iOS** (macOS only): Xcode 14+, CocoaPods

### Clone

```bash
git clone https://github.com/tomaravi7/trackfit-flutter.git
cd trackfit-flutter
flutter pub get
```

---

## Build for Android

```bash
flutter build apk --debug
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

To build a release version (requires a signing key):
```bash
flutter build apk --release
```

> **Debug APK size** is ~150 MB. A release build will be significantly smaller.

---

## Build for iOS (macOS only)

```bash
cd ios
pod install
cd ..
flutter build ios --debug
```

Then open `ios/Runner.xcworkspace` in Xcode, select a simulator or a connected device, and run the app (Product → Run).

For a release build:
```bash
flutter build ios --release --no-codesign
```

---

## Run Directly (any platform)

With a connected device or emulator:
```bash
flutter run
```

---

## Features

- **Glow Calorie Target Ring**: Custom-drawn circular progress ring with neon gradient blur filters.
- **Translucent Glassmorphic Layout**: Premium UI styling using Backdrop Filters.
- **Interactive Muscle Heatmap**: Selectable front/back silhouette map detailing muscle frequencies and target stats.
- **Hydration Liquid Wave**: Barber-pole animated water tracking progress bar.
- **Snack Budget Evaluator**: Local database target calculator with simulated scanning checks.
- **Dual Database sync**: Connects to a local SQLite database by default, and dynamically binds query handlers to remote PostgreSQL database servers when connection credentials are saved.

---

## Setup & Running Instructions

Since this repository contains the raw source files (`lib/` and `pubspec.yaml`), you can easily initialize native platform folders (Android, iOS, Web, Windows) using your local Flutter SDK:

1. **Initialize native folders**:
   Open a terminal inside this directory and run:
   ```bash
   flutter create .
   ```
   This will auto-generate all requisite build files (Gradle, Xcode workspaces, etc.) without modifying your source code.

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   Make sure an emulator/simulator or physical device is connected, and run:
   ```bash
   flutter run
   ```

---

## Project Architecture

- `lib/main.dart`: MultiProvider initialization and theme setup (Plus Jakarta Sans and Inter integration).
- `lib/models/`: Data models for food logs, workout sets, water logs, weight histories, and targets.
- `lib/services/`:
  - `db_service.dart`: Handles SQLite local CRUD queries and PostgreSQL drivers.
  - `state_service.dart`: Coordinates logging dates, shifts active days, and manages local storage preferences.
- `lib/widgets/`:
  - `calorie_ring.dart`: Circular calorie progress sweep.
  - `water_wave.dart`: Liquid wave water tracker.
  - `body_heatmap.dart`: Silhouette path overlays for targeted workouts.
  - `snack_evaluator.dart`: Micro-analysis radar spinner.
  - `glass_card.dart`: BackdropFilter overlay card.
- `lib/screens/`: Layout screens for Overview dashboard, Meals logging list, Exercise timers, Trends charts, and Database connections.
