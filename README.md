<p align="center">
  <a href="https://amplitude.com" target="_blank" align="center">
    <img src="https://static.amplitude.com/lightning/46c85bfd91905de8047f1ee65c7c93d6fa9ee6ea/static/media/amplitude-logo-with-text.4fb9e463.svg" width="280">
  </a>
  <br />
</p>

[![pub package](https://img.shields.io/pub/v/amplitude_flutter.svg)](https://pub.dartlang.org/packages/amplitude_flutter)

# Official Amplitude Flutter SDK
This is the official Amplitude Flutter SDK developed and maintained by Amplitude Inc.

## Minimum Supported Versions
iOS - 10
Android - API 21 (Lollipop)

## Installation and Usage
Add the dependency to your project.
```yaml
dependencies:
  amplitude_flutter: ^2.0.0
```

Import the module and use its APIs.
```dart
import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/identify.dart';

class YourClass {
  Future<void> exampleForAmplitude() async {
    // Create the instance
    final Amplitude analytics = Amplitude.getInstance(instanceName: "project");

    // Initialize SDK
    analytics.init(widget.apiKey);

    // Enable COPPA privacy guard. This is useful when you choose not to report sensitive user information.
    analytics.enableCoppaControl();

    // Set user Id
    analytics.setUserId("test_user");

    // Turn on automatic session events
    analytics.trackingSessionEvents(true);

    // Log an event
    analytics.logEvent('MyApp startup', eventProperties: {
      'friend_num': 10,
      'is_heavy_user': true
    });

    // Identify
    final Identify identify1 = Identify()
      ..set('identify_test',
          'identify sent at ${DateTime.now().millisecondsSinceEpoch}')
      ..add('identify_count', 1);
    analytics.identify(identify1);

    // Set group
    analytics.setGroup('orgId', 15);

    // Group identify
    final Identify identify2 = Identify()
      ..set('identify_count', 1);
    analytics.groupIdentify('orgId', '15', identify2);
  }
}
```

## Advertising Id Tracking
In iOS, to enable Advertising Id tracking, you will need to add `AdSupport.framework` in your project setting page. 
<img src="https://github.com/amplitude/Amplitude-Flutter/blob/master/add_dep_ios.png" width="800">

In Android, firstly you need to add `com.google.android.gms:play-services-ads` as a dependency in your `build.gradle`. If you use Google Mobile Ads SDK version 17.0.0 above. You need to add [`AD_MANAGER_APP`](https://developers.google.com/ad-manager/mobile-ads-sdk/android/quick-start#update_your_androidmanifestxml) into your `androidmanifest.xml` file.
<img src="https://github.com/amplitude/Amplitude-Flutter/blob/master/add_dep_android.png" width="500">

Secondly, since we don't assume user's project will depend on this library, we use reflection to invoke its APIs. So the names of its classes can't be changed since reflection will use original name to find the class. You also need to add exception rules into your `proguard-android.txt` or `proguard-rules.pro`.

```
-keep class com.google.android.gms.ads.** { *; }
```

## Need Help?
If you have any problems or issues over our SDK, feel free to create a github issue or submit a request on [Amplitude Help](https://help.amplitude.com/hc/en-us/requests/new).
