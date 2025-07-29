## [4.3.5](https://github.com/amplitude/Amplitude-Flutter/compare/v4.3.4...v4.3.5) (2025-07-29)


### Bug Fixes

* update AmplitudeSwift to 1.14.0 ([#275](https://github.com/amplitude/Amplitude-Flutter/issues/275)) ([b4636f2](https://github.com/amplitude/Amplitude-Flutter/commit/b4636f21c7140435cd663e062058a675ae6bbb5a))

## [4.3.4](https://github.com/amplitude/Amplitude-Flutter/compare/v4.3.3...v4.3.4) (2025-07-15)


### Bug Fixes

* [android] Remove duplicate install event tracking ([#273](https://github.com/amplitude/Amplitude-Flutter/issues/273)) ([da5f2c5](https://github.com/amplitude/Amplitude-Flutter/commit/da5f2c56ab3600750d38acdf137feed701cbdf1f))

## [4.3.3](https://github.com/amplitude/Amplitude-Flutter/compare/v4.3.2...v4.3.3) (2025-07-07)


### Bug Fixes

* [android] Flutter debug levels now map correctly to Android ([#272](https://github.com/amplitude/Amplitude-Flutter/issues/272)) ([8dc0589](https://github.com/amplitude/Amplitude-Flutter/commit/8dc0589f21e094de5fe00cb618e78522e25a8786))

## [4.3.2](https://github.com/amplitude/Amplitude-Flutter/compare/v4.3.1...v4.3.2) (2025-05-30)


### Bug Fixes

* (web) make setOptOut grab arguments and pass to TS SDK ([#260](https://github.com/amplitude/Amplitude-Flutter/issues/260)) ([1c1acc2](https://github.com/amplitude/Amplitude-Flutter/commit/1c1acc2443f3ebd46d7d4361298fbf3e029551de))
* iOS logLevel configuration not being applied correctly ([#256](https://github.com/amplitude/Amplitude-Flutter/issues/256)) ([dcf2a6f](https://github.com/amplitude/Amplitude-Flutter/commit/dcf2a6fb102c2170cc521e50d4a511b71f5d8473))

## [4.3.1](https://github.com/amplitude/Amplitude-Flutter/compare/v4.3.0...v4.3.1) (2025-04-17)


### Bug Fixes

* cast call.arguments to Map rather than Map<String, dynamic> to fix setUserId and setDeviceId ([#251](https://github.com/amplitude/Amplitude-Flutter/issues/251)) ([409ce18](https://github.com/amplitude/Amplitude-Flutter/commit/409ce18bf138a5de852099a324fad75ca4ebf7c3))
* Unnecessary double await call ([#253](https://github.com/amplitude/Amplitude-Flutter/issues/253)) ([02be47d](https://github.com/amplitude/Amplitude-Flutter/commit/02be47dc918eb5e06add66ae0b0fd5e32f7e11cd))

# [4.3.0](https://github.com/amplitude/Amplitude-Flutter/compare/v4.2.0...v4.3.0) (2025-03-26)


### Features

* add multiple instances support ([#241](https://github.com/amplitude/Amplitude-Flutter/issues/241)) ([e223fba](https://github.com/amplitude/Amplitude-Flutter/commit/e223fbafad3444170382412ea6f3f8d18cd99ede))

# [4.2.0](https://github.com/amplitude/Amplitude-Flutter/compare/v4.1.0...v4.2.0) (2025-03-17)


### Bug Fixes

* allow setUserId and setDeviceId to be called with null in swift code ([#236](https://github.com/amplitude/Amplitude-Flutter/issues/236)) ([9197d45](https://github.com/amplitude/Amplitude-Flutter/commit/9197d45e81a4b8f852a7b97e21a71ba18683e7bf))
* allow userId and deviceId to be set nullable ([#238](https://github.com/amplitude/Amplitude-Flutter/issues/238)) ([af9d225](https://github.com/amplitude/Amplitude-Flutter/commit/af9d225ad50cb2ea9dd6bbf307d14bed8d0d2a29))


### Features

* add getSessionId for all platforms ([#237](https://github.com/amplitude/Amplitude-Flutter/issues/237)) ([372eecf](https://github.com/amplitude/Amplitude-Flutter/commit/372eecf84ee3b0d74a0d76768f37abbe30a73b14))

# [4.1.0](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.1...v4.1.0) (2025-03-03)


### Bug Fixes

* update minimum version of Amplitude-Kotlin to 1.20 ([#232](https://github.com/amplitude/Amplitude-Flutter/issues/232)) ([98fb633](https://github.com/amplitude/Amplitude-Flutter/commit/98fb6338b44bb1cb7405c8cbe4350a69e60d1edb))


### Features

* add getUserId and getDeviceId functions on web/android/ios ([#230](https://github.com/amplitude/Amplitude-Flutter/issues/230)) ([295cfa6](https://github.com/amplitude/Amplitude-Flutter/commit/295cfa6b36358b1168e589b699f13b3a10c509a7))

## [4.0.1](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0...v4.0.1) (2025-02-21)


### Bug Fixes

* use js_interop_unsafe jsify() to convert dart object to JSObject rather than DIY mapToJSObj method ([#229](https://github.com/amplitude/Amplitude-Flutter/issues/229)) ([c9be554](https://github.com/amplitude/Amplitude-Flutter/commit/c9be55476ae0680a2ba760dd6f369e151c5de7a5))

# [4.0.0](https://github.com/amplitude/Amplitude-Flutter/compare/v3.16.1...v4.0.0) (2025-02-19)


### Bug Fixes

* Adding underlying library version to library field ([#192](https://github.com/amplitude/Amplitude-Flutter/issues/192)) ([9afeaa1](https://github.com/amplitude/Amplitude-Flutter/commit/9afeaa199347312bbd9d64cfafeb70140b4df361))
* Adding underlying library version to library field ([#195](https://github.com/amplitude/Amplitude-Flutter/issues/195)) ([bd72e9d](https://github.com/amplitude/Amplitude-Flutter/commit/bd72e9d97dffbd9f4128f59578d02dd6f595b628))
* capitalize serverZone before passing to browser SDK ([#219](https://github.com/amplitude/Amplitude-Flutter/issues/219)) ([3e46e78](https://github.com/amplitude/Amplitude-Flutter/commit/3e46e78cc89b1642619b8668d813b880ab0f7ec4))
* don't set namespace via package attribute in AndroidManifest.xml ([#225](https://github.com/amplitude/Amplitude-Flutter/issues/225)) ([a56915a](https://github.com/amplitude/Amplitude-Flutter/commit/a56915a8d4f70b7b3eb78f35b1f9be6bea38aa0c))
* eventType should be required positional param ([#186](https://github.com/amplitude/Amplitude-Flutter/issues/186)) ([1cb1f9b](https://github.com/amplitude/Amplitude-Flutter/commit/1cb1f9bfaf41c0f2d527b6ac02f6f17b69efbcec))


### Features

* add subset of Browser SDK  autocapture configuration to flutter web ([#221](https://github.com/amplitude/Amplitude-Flutter/issues/221)) ([ff53638](https://github.com/amplitude/Amplitude-Flutter/commit/ff53638f8b3445ba286480b52190ed0562754a7b))
* add support for macOS ([#217](https://github.com/amplitude/Amplitude-Flutter/issues/217)) ([eb66de8](https://github.com/amplitude/Amplitude-Flutter/commit/eb66de8e93e1d015808fb266b20961bc897df9d8)), closes [#156](https://github.com/amplitude/Amplitude-Flutter/issues/156) [#211](https://github.com/amplitude/Amplitude-Flutter/issues/211) [#46](https://github.com/amplitude/Amplitude-Flutter/issues/46)
* enable app installed & updated events for iOS ([#183](https://github.com/amplitude/Amplitude-Flutter/issues/183)) ([2d4cfe2](https://github.com/amplitude/Amplitude-Flutter/commit/2d4cfe2d4ec87aaaf1b5d530c2b725ee64ce608f))
* update to the latests native SDKs ([#179](https://github.com/amplitude/Amplitude-Flutter/issues/179)) ([fa0b4b9](https://github.com/amplitude/Amplitude-Flutter/commit/fa0b4b9d9ed6ca6f0d7763cced876dfae319dcd5))
* use latest Amplitude Browser 2 SDK (2.11.10) for flutter SDK web ([#216](https://github.com/amplitude/Amplitude-Flutter/issues/216)) ([3ba2a54](https://github.com/amplitude/Amplitude-Flutter/commit/3ba2a54965b69b149812448e7e046a796e25d186))


### BREAKING CHANGES

* Update to the latest native SDKs

# [4.0.0-beta.9](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0-beta.8...v4.0.0-beta.9) (2025-02-06)


### Bug Fixes

* don't set namespace via package attribute in AndroidManifest.xml ([#225](https://github.com/amplitude/Amplitude-Flutter/issues/225)) ([a56915a](https://github.com/amplitude/Amplitude-Flutter/commit/a56915a8d4f70b7b3eb78f35b1f9be6bea38aa0c))


### Features

* add subset of Browser SDK  autocapture configuration to flutter web ([#221](https://github.com/amplitude/Amplitude-Flutter/issues/221)) ([ff53638](https://github.com/amplitude/Amplitude-Flutter/commit/ff53638f8b3445ba286480b52190ed0562754a7b))

# [4.0.0-beta.8](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0-beta.7...v4.0.0-beta.8) (2025-01-20)


### Bug Fixes

* capitalize serverZone before passing to browser SDK ([#219](https://github.com/amplitude/Amplitude-Flutter/issues/219)) ([3e46e78](https://github.com/amplitude/Amplitude-Flutter/commit/3e46e78cc89b1642619b8668d813b880ab0f7ec4))

# [4.0.0-beta.7](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0-beta.6...v4.0.0-beta.7) (2025-01-15)


### Features

* add support for macOS ([#217](https://github.com/amplitude/Amplitude-Flutter/issues/217)) ([eb66de8](https://github.com/amplitude/Amplitude-Flutter/commit/eb66de8e93e1d015808fb266b20961bc897df9d8)), closes [#156](https://github.com/amplitude/Amplitude-Flutter/issues/156) [#211](https://github.com/amplitude/Amplitude-Flutter/issues/211) [#46](https://github.com/amplitude/Amplitude-Flutter/issues/46)

# [4.0.0-beta.6](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0-beta.5...v4.0.0-beta.6) (2025-01-08)


### Features

* use latest Amplitude Browser 2 SDK (2.11.10) for flutter SDK web ([#216](https://github.com/amplitude/Amplitude-Flutter/issues/216)) ([3ba2a54](https://github.com/amplitude/Amplitude-Flutter/commit/3ba2a54965b69b149812448e7e046a796e25d186))

# [4.0.0-beta.5](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0-beta.4...v4.0.0-beta.5) (2024-06-28)


### Bug Fixes

* Adding underlying library version to library field ([#195](https://github.com/amplitude/Amplitude-Flutter/issues/195)) ([bd72e9d](https://github.com/amplitude/Amplitude-Flutter/commit/bd72e9d97dffbd9f4128f59578d02dd6f595b628))

# [4.0.0-beta.4](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0-beta.3...v4.0.0-beta.4) (2024-06-24)


### Bug Fixes

* Adding underlying library version to library field ([#192](https://github.com/amplitude/Amplitude-Flutter/issues/192)) ([9afeaa1](https://github.com/amplitude/Amplitude-Flutter/commit/9afeaa199347312bbd9d64cfafeb70140b4df361))

# [4.0.0-beta.3](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0-beta.2...v4.0.0-beta.3) (2024-04-08)


### Bug Fixes

* eventType should be required positional param ([#186](https://github.com/amplitude/Amplitude-Flutter/issues/186)) ([1cb1f9b](https://github.com/amplitude/Amplitude-Flutter/commit/1cb1f9bfaf41c0f2d527b6ac02f6f17b69efbcec))

# [4.0.0-beta.2](https://github.com/amplitude/Amplitude-Flutter/compare/v4.0.0-beta.1...v4.0.0-beta.2) (2024-04-03)


### Features

* enable app installed & updated events for iOS ([#183](https://github.com/amplitude/Amplitude-Flutter/issues/183)) ([2d4cfe2](https://github.com/amplitude/Amplitude-Flutter/commit/2d4cfe2d4ec87aaaf1b5d530c2b725ee64ce608f))

# [4.0.0-beta.1](https://github.com/amplitude/Amplitude-Flutter/compare/v3.16.1...v4.0.0-beta.1) (2024-03-12)


### Features

* update to the latests native SDKs ([#179](https://github.com/amplitude/Amplitude-Flutter/issues/179)) ([fa0b4b9](https://github.com/amplitude/Amplitude-Flutter/commit/fa0b4b9d9ed6ca6f0d7763cced876dfae319dcd5))


### BREAKING CHANGES

* Update to the latest native SDKs

## [3.16.1](https://github.com/amplitude/Amplitude-Flutter/compare/v3.16.0...v3.16.1) (2023-11-08)


### Bug Fixes

* add release/publish workflows ([#155](https://github.com/amplitude/Amplitude-Flutter/issues/155)) ([42d09c4](https://github.com/amplitude/Amplitude-Flutter/commit/42d09c4369c93e688dabe00d0ec66dc1d7ef1ecd))

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
