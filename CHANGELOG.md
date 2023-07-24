## 3.16.0
* Bump Amplitude Android SDK version (2.39.8) with session race condition fix.
* Add `setOffline` method. Thanks @nishiths23!
* Fix nested event properties in Web. Thanks @jtothebell!

## 3.15.0
* Bump Amplitude Android SDK version (2.39.4)
* Bump Amplitude iOS SDK version (8.16.1)

## 3.14.0
* Implement setEventUploadPeriodMillis

## 3.13.0
* Implement setDeviceId

## 3.12.0
* Bump Amplitude Android SDK version (2.38.3)
* Bump Amplitude iOS SDK version (8.14.0)

## 3.11.0
* Bump up the kotlin version to support latest gradle on Android.

## 3.10.0
* Fix the Amplitude Flutter Web throw exception on setting userId to null

## 3.9.0
* Bump Android (2.37.0) Amplitude SDK versions

## 3.8.1
*  Fix setUseDynamicConfig in Android
*  Enable foreground tracking on Android by default. Thanks @vishna!

## 3.8.0
*  Support Flutter Web. Please check the example app or go to developer center to see the usage(https://developers.amplitude.com/docs/flutter-setup#flutter-web-support).

## 3.7.0
* Downgrade the kotlin gradle plugin to '1.3.40' to fix amplitude_flutter incompatible to project with kotlin gradle plugin version < 1.4.0.

## 3.6.0
* Add `setServerZone` method for EU server zone support.

## 3.5.0
* Add `preInsert`, `postInsert`, `remove`, `clearAll` methods for `Identify`. Thanks @reeichert!

## 3.4.0
* Add `useAppSetIdForDeviceId` API for Android.
* Upgrade kotlin gradle plugin to '1.5.30'.


## 3.3.0
* Add `setMinTimeBetweenSessionsMillis` API. Thanks @chillbrodev!

## 3.2.1
* Add `getUserId` API. Thanks @keke-dandois!
* Fix iOS initializeApiKey have a wrong flow When passe null as the userid. Thanks @keke-dandois!

## 3.1.1
* Fix `Identify` set and other methods cannot pass int as value on Android.

## 3.1.0
* Add `getSessionId` and `getDeviceId` API

## 3.0.0
* Migrate package to null-safety

## 2.3.1
* Add `setEventUploadThreshold` API

## 2.3.0
* Add `regenerateDeviceId` API to enable regenerate a new deviceId.

## 2.2.3
* Bump iOS (7.2.0) and Android (2.29.2) Amplitude SDK versions
* Add `setUseDynamicConfig` API to dynamically adjust server URL

## 2.2.2
* Fix - Fixing crash on iOS. Thanks @nishiths23!
* Misc - Migrated plugin to android v2 embedding. Thanks @sergey-triputsco!

## 2.2.1
* Fix addIdentity doesn't work correctly. Thanks @bradchien!

## 2.2.0
* Add `setServerUrl` API to customize server destination.

## 2.1.1
* Fix calling `setUserId` with null crashes on iOS.

## 2.1.0
* Fix the crash when calling `setUserProperties`
* Add API `uploadEvents` to force uploading unsent events.

## 2.0.0
* A whole new Flutter SDK which is based on much more stable Amplitude native iOS, Android SDKs
