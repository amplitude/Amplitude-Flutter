<p align="center">
  <a href="https://amplitude.com" target="_blank" align="center">
    <img src="https://static.amplitude.com/lightning/46c85bfd91905de8047f1ee65c7c93d6fa9ee6ea/static/media/amplitude-logo-with-text.4fb9e463.svg" width="280">
  </a>
  <br />
</p>

[![pub package](https://img.shields.io/pub/v/amplitude_flutter.svg)](https://pub.dartlang.org/packages/amplitude_flutter)

# Official Amplitude Flutter SDK

This is the official Amplitude Flutter SDK developed and maintained by Amplitude Inc.

## Installation and Quick Start

- Please visit our :100:[Developer Center](https://developers.amplitude.com/docs/flutter-setup) for instructions on installing and using our the SDK.
- For developing the SDK, please visit our [CONTRIBUTING.md](https://github.com/amplitude/Amplitude-Flutter/blob/main/CONTRIBUTING.md) to get started.

## Compatibility

From Amplitude Flutter v4, we bump up the kotlin version to v1.9.22 to support latest Gradle.

The following matrix lists the baseline requirements for Amplitude Flutter and the verified requirements for the native Android dependency configuration listed below. Native dependencies can impose higher Android build requirements than the baseline.

| Amplitude Flutter |  Dart   | Flutter | Gradle | Android Gradle Plugin | Kotlin Gradle Plugin |
|-------------------|---------|---------|--------|-----------------------|-----------------------|
| >= 4.0.0 (baseline) | >=3.3 | >=3.7 | 8.2 | 8.2.2 | 1.9.22 |
| 4.6.2 with `analytics-android` 1.29.1 | >=3.3 | >=3.19.0 | 8.7 | 8.6.0 | 1.9.22 |

For the 4.6.2 configuration above, the native Android dependency chain requires the consuming app to use `compileSdk` 35 or higher and Android Gradle Plugin 8.6.0 or higher. Debug and release builds were verified with Flutter 3.19.0, Gradle 8.7, Kotlin Gradle Plugin 1.9.22, and JDK 17. These requirements apply to this native dependency configuration, not retroactively to every 4.x release. Because the native SDK dependency uses the `1.29.+` version range, check which version Gradle resolves when diagnosing build compatibility.

Learn more about the Android [Gradle Plugin compatibility](https://developer.android.com/studio/releases/gradle-plugin#updating-gradle), [Gradle compatibility](https://docs.gradle.org/current/userguide/compatibility.html#kotlin), and [Kotlin compatibility](https://kotlinlang.org/docs/whatsnew17.html#bumping-minimum-supported-versions).

## Need Help?

If you have any problems or issues over our SDK, feel free to create a github issue or submit a request on [Amplitude Help](https://help.amplitude.com/hc/en-us/requests/new).
