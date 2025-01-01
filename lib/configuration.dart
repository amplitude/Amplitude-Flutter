import 'constants.dart';
import 'tracking_options.dart';
import 'default_tracking.dart';
import 'cookie_options.dart';

class Configuration {
  /// Applicable to all platforms
  String apiKey;
  int flushQueueSize;
  int flushIntervalMillis;
  late String instanceName;
  bool optOut;
  LogLevel logLevel;
  int? minIdLength;
  String? partnerId;
  int flushMaxRetries;
  bool useBatch;
  ServerZone serverZone;
  String? serverUrl;

  /// Mobile (iOS and Android) specific
  int minTimeBetweenSessionsMillis;
  DefaultTrackingOptions defaultTracking;
  TrackingOptions trackingOptions;
  bool enableCoppaControl;
  bool flushEventsOnClose;
  int identifyBatchIntervalMillis;
  bool migrateLegacyData;

  /// Android specific
  bool locationListening;
  bool useAdvertisingIdForDeviceId;
  bool useAppSetIdForDeviceId;

  /// Web specific
  String? appVersion;
  String? deviceId;
  CookieOptions cookieOptions;
  String? identityStorage;
  int sessionTimeout;
  String? userId;
  String? transport;
  bool offline;
  bool fetchRemoteConfig;



  /// Configuration for Amplitude instance.
  ///
  /// Before initializing Amplitude instance, create a Configuration instance
  /// with your desired configuration and pass it to the Amplitude instance.
  ///
  /// Note the Configuration is immutable (cannot be changed) after being passed to Amplitude
  /// `optOut` can be changed later by calling `setOptOut()`.
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
    this.minTimeBetweenSessionsMillis = Constants.minTimeBetweenSessionsMillis,
    this.defaultTracking = const DefaultTrackingOptions(),
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
    String identityStorage = '',
    this.sessionTimeout = Constants.sessionTimeoutMillis,
    this.userId,
    this.transport = 'fetch',
    this.offline = false,
    this.fetchRemoteConfig = false,
  }): trackingOptions = trackingOptions ?? TrackingOptions(),
      cookieOptions = cookieOptions ?? CookieOptions() {
    this.instanceName = instanceName.isEmpty ? Constants.defaultInstanceName : instanceName;
    this.identityStorage = identityStorage.isEmpty ? IdentityStorage.cookie.name : identityStorage;
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
      'minTimeBetweenSessionsMillis': minTimeBetweenSessionsMillis,
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
      'sessionTimeout': sessionTimeout,
      'userId': userId,
      'transport': transport,
      'offline': offline,
      'fetchRemoteConfig': fetchRemoteConfig,
      // This field doesn't belong to Configuration
      // Pass it for FlutterLibraryPlugin
      'library': '${Constants.packageName}/${Constants.packageVersion}'
    };
  }
}
