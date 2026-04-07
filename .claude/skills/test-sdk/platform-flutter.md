# Platform Reference: Flutter

Platform-specific build commands, paths, app identifiers, and known issues for
the Amplitude Flutter SDK example app. Swap this file to adapt the test-sdk
skill to a different platform (React Native, Swift, Kotlin, etc.).

## Supported Platforms

| Platform ID     | Description                        |
|-----------------|------------------------------------|
| `ios-spm`       | iOS via Swift Package Manager      |
| `ios-cocoapods` | iOS via CocoaPods                  |
| `android`       | Android (APK)                      |
| `web`           | Flutter Web (served via HTTP)      |

## Project Structure

- **Example app root**: `example/`
- **API key source**: `example/.env` (injected via `--dart-define-from-file`)
- **API key in code**: `example/lib/main.dart` uses `String.fromEnvironment('AMPLITUDE_API_KEY')`
- **Plugin source (Darwin)**: `darwin/`
- **Plugin source (Android)**: `android/`

## Build Commands

All commands run from the `example/` directory unless noted otherwise.

### ios-spm

```bash
flutter config --enable-swift-package-manager
flutter clean
flutter pub get
flutter build ios --debug --simulator --no-codesign --dart-define-from-file=.env 2>&1 | tee /tmp/test-sdk-build-ios-spm.log
```

### ios-cocoapods

```bash
flutter config --no-enable-swift-package-manager
flutter clean
flutter pub get
cd ios && pod repo update && cd ..
flutter build ios --debug --simulator --no-codesign --dart-define-from-file=.env 2>&1 | tee /tmp/test-sdk-build-ios-cocoapods.log
```

### android

```bash
flutter build apk --debug --dart-define-from-file=.env 2>&1 | tee /tmp/test-sdk-build-android.log
```

### web

```bash
flutter build web --dart-define-from-file=.env 2>&1 | tee /tmp/test-sdk-build-web.log
```

To serve after build:

```bash
cd build/web && python3 -m http.server 8080
```

## Build Sequencing

- **iOS SPM and iOS CocoaPods MUST be sequential** -- `flutter config` is a
  global setting, so switching between SPM and CocoaPods requires a clean build.
- Run `flutter clean && flutter pub get` between iOS build variants.
- Android and Web builds are independent and can run in parallel with iOS.
- Recommended order: ios-spm -> ios-cocoapods -> android (parallel) + web (parallel).

## Build Output Paths

| Platform        | Artifact Path (relative to `example/`)           |
|-----------------|--------------------------------------------------|
| `ios-spm`       | `build/ios/iphonesimulator/Runner.app`           |
| `ios-cocoapods` | `build/ios/iphonesimulator/Runner.app`           |
| `android`       | `build/app/outputs/flutter-apk/app-debug.apk`   |
| `web`           | `build/web/`                                     |

Note: Both iOS variants produce the same artifact path. Copy the artifact to
`/tmp/test-sdk-ios-spm-Runner.app` or `/tmp/test-sdk-ios-cocoapods-Runner.app`
after each build to avoid overwriting.

## App Identifiers

| Platform | Identifier                                    |
|----------|-----------------------------------------------|
| iOS      | `com.amplitude.flutterExample` (bundle ID)    |
| Android  | `com.amplitude.amplitude_flutter_example`     |
| Web      | `http://localhost:8080`                        |

## Known Issues

### Flutter.xcframework symlink

Some machines have Flutter SDK installed at a non-standard path. The Xcode
project may reference `Flutter.xcframework` via a hardcoded relative path. If
the iOS build fails with "There is no XCFramework found at ...", create a
symlink:

```bash
ln -sf /path/to/your/flutter /Users/$USER/code/flutter
```

### Gradle Kotlin version warning

Android builds may show a Kotlin version compatibility warning. This is
**non-blocking** -- the build still succeeds.

### CocoaPods spec repo

If the CocoaPods build fails with "CocoaPods could not find compatible
versions", run `pod repo update` in the `example/ios/` directory. This is
already included in the build commands above.

### iOS simulator selection

When multiple iOS simulators are available, prefer one that is already booted.
If none are booted, use the latest iPhone model available.
