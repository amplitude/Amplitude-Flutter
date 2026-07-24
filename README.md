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

## Autocapture

Configure autocapture through the `autocapture` field of `Configuration`. Use
`AutocaptureEnabled()` to turn on every supported option, `AutocaptureDisabled()`
to turn them all off, or `AutocaptureOptions(...)` for granular control:

```dart
final analytics = Amplitude(Configuration(
  apiKey: 'API_KEY',
  autocapture: AutocaptureOptions(
    sessions: true,
    // Web
    attribution: AttributionOptions(),
    pageViews: PageViewsOptions(),
    formInteractions: true,
    fileDownloads: true,
    elementInteractions: ElementInteractionsOptions(), // clicks; off by default
    pageUrlEnrichment: true,
    // Mobile (iOS/Android)
    appLifecycles: true, // installs, upgrades, opens
    deepLinks: true,     // Android
    screenViews: true,   // see "Screen views" below
  ),
));
```

Each platform ignores the options that don't apply to it.

> **Upgrading:** on web, `formInteractions` and `fileDownloads` are now captured
> by default (this SDK previously disabled them). After upgrading, web apps begin
> emitting `[Amplitude] Form Started`/`Submitted` and `[Amplitude] File Downloaded`
> events — set those options to `false` to opt out. `elementInteractions` (click
> tracking) remains opt-in.

### Web setup

The web plugin does **not** inject the Amplitude Browser SDK — your app's page
must load it. Add the Amplitude loader snippet to your `web/index.html` (see
[`example/web/index.html`](https://github.com/amplitude/Amplitude-Flutter/blob/main/example/web/index.html)).
Autocapture features gate on the Browser SDK version the page loads:
`elementInteractions` needs **>= 2.10.0** and `pageUrlEnrichment` needs
**>= 2.29.0** (older SDKs silently ignore the option) — the example snippet
loads 2.44.4, which covers everything. If you change the snippet's SDK version,
update the snippet's `integrity` (SRI) hash to match that exact file, otherwise
the browser will refuse to load it. The SRI hash is the base64 sha384 of the
*decoded* JS (the CDN serves it gzip-encoded):
`curl -s https://cdn.amplitude.com/libs/analytics-browser-<version>-min.js.gz | gzcat | openssl dgst -sha384 -binary | openssl base64 -A`

On Flutter web, the Browser SDK's DOM-based capture (`elementInteractions`,
`formInteractions`, `fileDownloads`) only sees real DOM elements. With the
default CanvasKit renderer the UI is painted to a canvas, so these events fire
only for DOM the app actually creates — e.g. the accessibility semantics tree
(when enabled by the user or via `SemanticsBinding.ensureSemantics()`), where
text fields render as real `<input>`/`<form>` elements and are captured.
Route/screen tracking is unaffected (use the `AmplitudeNavigatorObserver`
below).

### Screen views

A Flutter app runs inside a single native surface (one `FlutterViewController`
on iOS, one `FlutterActivity` on Android), so the native SDK's screen view
autocapture cannot observe Flutter route navigation. Instead, enable
`screenViews` and attach an `AmplitudeNavigatorObserver` to your app's
`navigatorObservers`:

```dart
import 'package:amplitude_flutter/observers/amplitude_navigator_observer.dart';

MaterialApp(
  navigatorObservers: [AmplitudeNavigatorObserver(analytics)],
  // ...
);
```

The observer emits an `[Amplitude] Screen Viewed` event (with an
`[Amplitude] Screen Name` property from the route name) on each navigation, on
every platform including web. Both enabling `screenViews` and attaching the
observer are required.

Screen names come from `RouteSettings.name`, so **give your routes names** (named
routes, `RouteSettings(name: ...)`, or a router such as go_router) — routes with
no name are skipped, and in debug builds a log explains why. Pass a custom
`nameExtractor` to derive names differently.

On web, `pageViews` and the observer are independent. A Flutter route change does
not necessarily change the browser URL, so the observer (route-based) captures
navigations the Browser SDK's URL-based `pageViews` would miss. If you enable
both, a URL-changing navigation is recorded as both `[Amplitude] Page Viewed` and
`[Amplitude] Screen Viewed`; to record a single event, disable the one you don't
want — typically `pageViews: PageViewsDisabled()`, keeping `pageUrlEnrichment`
enabled to retain page-URL properties.

## Compatibility

From Amplitude Flutter v4, we bump up the kotlin version to v1.9.22 to support latest Gradle.

The following matrix lists the minimum support for Amplitude Flutter SDK version.

| Amplitude Flutter |  Dart   | Flutter | Gradle | Android Gradle Plugin | Kotlin Gradle Plugin |
|-------------------|---------|---------|--------|-----------------------|-----------------------|
| >= 4.0.0          | >=3.3   | >=3.7   | 8.2    | 8.2.2                 | 1.9.22                |


Learn more about the Android [Gradle Plugin compatibility](https://developer.android.com/studio/releases/gradle-plugin#updating-gradle), [Gradle compatibility](https://docs.gradle.org/current/userguide/compatibility.html#kotlin), and [Kotlin compatibility](https://kotlinlang.org/docs/whatsnew17.html#bumping-minimum-supported-versions).

## Need Help?

If you have any problems or issues over our SDK, feel free to create a github issue or submit a request on [Amplitude Help](https://help.amplitude.com/hc/en-us/requests/new).
