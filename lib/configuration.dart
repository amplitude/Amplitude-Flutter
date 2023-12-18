import 'constants.dart';
import 'tracking_options.dart';
import 'default_tracking.dart';

/// Configuration for Amplitude instance.
/// 
/// Before initialzing Amplitude instance, create a Configuration instance
/// with your desired configuration and pass it to the Amplitude instance.
/// Note the Configuration is immutable (cannot be changed) after being passed to Amplitude.init()
/// `optOut` and be changed later by calling `setOptOut()`.
class Configuration {
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
  int minTimeBetweenSessionsMillis;
  DefaultTrackingOptions defaultTracking;
  TrackingOptions trackingOptions;
  // Mobile (iOS and Android) specific
  bool enableCoppaControl;
  bool flushEventsOnClose;
  int identifyBatchIntervalMillis;
  bool migrateLegacyData;
  // Android specific
  bool locationListening;
  bool useAdvertisingIdForDeviceId;
  bool useAppSetIdForDeviceId;
  // Web specific
  int? appVersion;
  
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
    this.serverZone = ServerZone.US,
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
  }): trackingOptions = trackingOptions ?? TrackingOptions() {
    instanceName = instanceName.isEmpty ? Constants.defaultInstanceName : instanceName;
  }

  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'flushQueueSize': flushQueueSize,
      'flushIntervalMillis': flushIntervalMillis,
      'instanceName': instanceName,
      'optOut': optOut,
      'logLevel': logLevel.toString(),
      'minIdLength': minIdLength,
      'partnerId': partnerId,
      'flushMaxRetries': flushMaxRetries,
      'useBatch': useBatch,
      'serverZone': serverZone.toString(),
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
    };
  }
}
