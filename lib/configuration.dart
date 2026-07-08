// This file maintains the deprecation bridge from `defaultTracking` to
// `autocapture` (see Configuration._resolveAutocapture). Reading and
// re-emitting the deprecated DefaultTrackingOptions in this single file is
// intentional and required for backward compatibility.
// ignore_for_file: deprecated_member_use_from_same_package

import 'autocapture/attribution.dart';
import 'autocapture/autocapture.dart';
import 'autocapture/page_views.dart';
import 'constants.dart';
import 'tracking_options.dart';
import 'default_tracking.dart';
import 'cookie_options.dart';

class Configuration {
  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// The API key for the Amplitude project.
  String apiKey;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets the maximum number of events batched in a single upload atempt.
  int flushQueueSize;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets the interval of uploading events to Amplitude in milliseconds.
  int flushIntervalMillis;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// The name of the instance. Instances with the same name will share storage and identity.
  /// For isolated storage and identity use a unique instanceName for each instance.
  late String instanceName;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets permission to track events. Setting a value of true prevents Amplitude
  /// from tracking and uploading events.
  bool optOut;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets the level of logging. The default value is LogLevel.warn.
  LogLevel logLevel;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets the minimum length for the value of userId and deviceId properties.
  int? minIdLength;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets partner ID. Amplitude requires the customer who built an event
  /// ingestion integration to add the partner identifier to partner_id.
  String? partnerId;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets the maximum number of retries for failed upload attempts.
  /// This is only applicable to errors that the SDK can retry.
  int flushMaxRetries;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets whether to upload events to Batch API instead of the default HTTP V2 API or not.
  bool useBatch;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// 'EU' or 'US'. Sets the Amplitude server zone. Set this to EU for Amplitude
  /// projects created in EU data center.
  ServerZone serverZone;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Sets the URL where events are upload to.
  String? serverUrl;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// The amount of time for session timeout. The value is in milliseconds.
  ///
  /// Defaults to 300,000 milliseconds (5 minutes) for iOS/Android and
  /// 1,800,000 milliseconds (30 minutes) for Web. Overriding this value will
  /// change the session timeout for all platforms.
  /// This maps to `minTimeBetweenSessionsMillis` for iOS/Android and `sessionTimeout` for Web.
  int minTimeBetweenSessionsMillis;

  /// Applicable to all platforms (iOS, Android, Web)
  ///
  /// Configures tracking of extra properties.
  /// Check platform-specific documentation for more information.
  TrackingOptions trackingOptions;

  /// Mobile (iOS and Android) specific
  ///
  /// Enable tracking of default events for sessions, app lifecycles, screen
  /// views, and deep links.
  ///
  /// Prefer [autocapture] instead. When `defaultTracking` is set and
  /// [autocapture] is omitted, its values flow into the derived
  /// [AutocaptureOptions] so existing callers continue to work.
  @Deprecated('Use autocapture instead. See Configuration.autocapture.')
  DefaultTrackingOptions defaultTracking;

  /// Mobile (iOS and Android) specific
  ///
  /// Whether to enable COPPA control for tracking options.
  bool enableCoppaControl;

  /// Mobile (iOS and Android) specific
  ///
  /// Flushing of unsent events on app close.
  bool flushEventsOnClose;

  /// Mobile (iOS and Android) specific
  ///
  /// The amount of time SDK will attempt to batch intercepted identify events. The value is in milliseconds.
  int identifyBatchIntervalMillis;

  /// Mobile (iOS and Android) specific
  ///
  /// Whether to migrate maintenance SDK data (events, user/device ID).
  /// See platform-specific documentation for more information.
  bool migrateLegacyData;

  /// Applicable to Web and Android
  ///
  /// The device ID to use for this device. If no deviceID is provided one will be generated automatically.
  String? deviceId;

  /// Android specific
  ///
  /// Whether to enable Android location service. Learn more at
  /// https://amplitude.com/docs/sdks/analytics/android/android-kotlin-sdk#location-tracking
  bool locationListening;

  /// Android specific
  ///
  /// Whether to use advertising id as device id.
  /// See https://amplitude.com/docs/sdks/analytics/android/android-kotlin-sdk#advertiser-id for more information.
  bool useAdvertisingIdForDeviceId;

  /// Android specific
  ///
  /// Whether to use app set id as device id.
  /// See https://amplitude.com/docs/sdks/analytics/android/android-kotlin-sdk#app-set-id for more information.
  bool useAppSetIdForDeviceId;

  /// Web specific
  ///
  /// Sets an app version for events tracked. This can be the version of your application. For example: "1.0.0".
  String? appVersion;

  /// Web specific
  ///
  /// Sets cookie options. See https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
  /// for more information.
  CookieOptions cookieOptions;

  /// Web specific
  ///
  /// Sets storage API for user identity. Options include cookie for document.cookie, localStorage for localStorage,
  /// or none to opt-out of persisting user identity.
  String identityStorage;

  /// Web specific
  ///
  /// Sets an identifier for the tracked user. Must have a minimum length of 5 characters unless overridden with the
  /// minIdLength option.
  String? userId;

  /// Web specific
  ///
  /// Sets request API to use by name. Options include fetch for fetch, xhr for XMLHTTPRequest, or beacon for
  /// navigator.sendBeacon.
  String? transport;

  /// Web specific
  ///
  /// Whether the SDK fetches remote configuration.
  /// See https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#remote-configuration for more information.
  bool fetchRemoteConfig;

  /// Cross-platform
  ///
  /// Configures autocapture. Use [AutocaptureEnabled] or [AutocaptureDisabled]
  /// for the common cases, or [AutocaptureOptions] for granular control.
  ///
  /// For backward compatibility, if [autocapture] is not set, values from the
  /// deprecated [defaultTracking] field are used instead. Prefer [autocapture]
  /// for new code.
  ///
  /// See [Web](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#autocapture),
  /// [iOS](https://amplitude.com/docs/sdks/analytics/ios/ios-swift-sdk#autocapture),
  /// [Android](https://amplitude.com/docs/sdks/analytics/android/android-kotlin-sdk#autocapture)
  /// for platform-specific behavior.
  Autocapture autocapture;

  /// Configuration for Amplitude instance.
  ///
  /// Before initializing Amplitude instance, create a Configuration instance
  /// with your desired configuration and pass it to the Amplitude instance.
  ///
  /// Note the Configuration is immutable (cannot be changed) after being passed to Amplitude
  /// `optOut` can be changed later by calling `setOptOut()`.
  ///
  /// See platform-specific documentation for more information.
  /// Android: https://amplitude.com/docs/sdks/analytics/android/android-kotlin-sdk#configure-the-sdk
  /// iOS: https://amplitude.com/docs/sdks/analytics/ios/ios-swift-sdk#configure-the-sdk
  /// Web: https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
  Configuration({
    required this.apiKey,
    this.flushQueueSize = Constants.flushQueueSize,
    this.flushIntervalMillis = Constants.flushIntervalMillis,
    String instanceName = '',
    this.optOut = false,
    this.logLevel = LogLevel.warn,
    this.minIdLength,
    this.partnerId,
    this.flushMaxRetries = Constants.flushMaxRetries,
    this.useBatch = false,
    this.serverZone = ServerZone.us,
    this.serverUrl,
    this.minTimeBetweenSessionsMillis =
        Constants.minTimeBetweenSessionsMillisUnset,
    @Deprecated('Use autocapture instead. See Configuration.autocapture.')
    DefaultTrackingOptions? defaultTracking,
    TrackingOptions? trackingOptions,
    this.enableCoppaControl = false,
    this.flushEventsOnClose = true,
    this.identifyBatchIntervalMillis = Constants.identifyBatchIntervalMillis,
    this.migrateLegacyData = true,
    this.locationListening = true,
    this.useAdvertisingIdForDeviceId = false,
    this.useAppSetIdForDeviceId = false,
    this.appVersion,
    this.deviceId,
    CookieOptions? cookieOptions,
    this.identityStorage = 'cookie',
    this.userId,
    this.transport = 'fetch',
    this.fetchRemoteConfig = false,
    Autocapture? autocapture,
  })  : defaultTracking = defaultTracking ?? const DefaultTrackingOptions(),
        autocapture = _resolveAutocapture(
          autocapture,
          defaultTracking ?? const DefaultTrackingOptions(),
        ),
        trackingOptions = trackingOptions ?? TrackingOptions(),
        cookieOptions = cookieOptions ?? CookieOptions() {
    this.instanceName =
        instanceName.isEmpty ? Constants.defaultInstanceName : instanceName;
  }

  /// Returns the [Autocapture] to use, deriving an [AutocaptureOptions] from
  /// the deprecated `DefaultTrackingOptions` when `autocapture` was not passed.
  ///
  /// This is the single place where the `defaultTracking → autocapture` bridge
  /// lives. Native plugins read only the resolved `autocapture` map.
  static Autocapture _resolveAutocapture(
    Autocapture? autocapture,
    DefaultTrackingOptions defaultTracking,
  ) {
    if (autocapture != null) return autocapture;
    return AutocaptureOptions(
      sessions: defaultTracking.sessions,
      appLifecycles: defaultTracking.appLifecycles,
      deepLinks: defaultTracking.deepLinks,
      attribution: defaultTracking.attribution
          ? const AttributionOptions()
          : const AttributionDisabled(),
      pageViews: defaultTracking.pageViews
          ? const PageViewsOptions()
          : const PageViewsDisabled(),
      formInteractions: defaultTracking.formInteractions,
      fileDownloads: defaultTracking.fileDownloads,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'flushQueueSize': flushQueueSize,
      'flushIntervalMillis': flushIntervalMillis,
      'instanceName': instanceName,
      'optOut': optOut,
      'logLevel': logLevel.name,
      'minIdLength': minIdLength,
      'partnerId': partnerId,
      'flushMaxRetries': flushMaxRetries,
      'useBatch': useBatch,
      'serverZone': serverZone.name,
      'serverUrl': serverUrl,
      'minTimeBetweenSessionsMillis': minTimeBetweenSessionsMillis !=
              Constants.minTimeBetweenSessionsMillisUnset
          ? minTimeBetweenSessionsMillis
          : Constants.minTimeBetweenSessionsMillisForMobile,
      // Still serialized for backward compatibility; native plugins now read
      // 'autocapture' instead. See Configuration.autocapture.
      'defaultTracking': defaultTracking.toMap(),
      'trackingOptions': trackingOptions.toMap(),
      'enableCoppaControl': enableCoppaControl,
      'flushEventsOnClose': flushEventsOnClose,
      'identifyBatchIntervalMillis': identifyBatchIntervalMillis,
      'migrateLegacyData': migrateLegacyData,
      'locationListening': locationListening,
      'useAdvertisingIdForDeviceId': useAdvertisingIdForDeviceId,
      'useAppSetIdForDeviceId': useAppSetIdForDeviceId,
      'appVersion': appVersion,
      'deviceId': deviceId,
      'cookieOptions': cookieOptions.toMap(),
      'identityStorage': identityStorage,
      'sessionTimeout': minTimeBetweenSessionsMillis !=
              Constants.minTimeBetweenSessionsMillisUnset
          ? minTimeBetweenSessionsMillis
          : Constants.minTimeBetweenSessionsMillisForWeb,
      'userId': userId,
      'transport': transport,
      'fetchRemoteConfig': fetchRemoteConfig,
      'autocapture': Autocapture.toMapOrBool(autocapture),
      // This field doesn't belong to Configuration
      // Pass it for FlutterLibraryPlugin
      'library': '${Constants.packageName}/${Constants.packageVersion}'
    };
  }
}
