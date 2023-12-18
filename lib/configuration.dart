import 'constants.dart';
import 'tracking_options.dart';
import 'default_tracking.dart';

/// Configuration for Amplitude instance.
/// 
/// Before initialzing Amplitude instance, create a Configuration instance
/// with your desired configuration and pass it to the Amplitude instance.
/// Note the Configuration is immutable (cannot be changed) after being passed to Amplitude.init()
/// `optOut` can be changed later by calling `setOptOut()`.
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
  MobileConfiguration mobileConfiguration;
  AndroidConfiguration androidConfiguration;
  WebConfiguration webConfiguration;
  
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
    this.mobileConfiguration = const MobileConfiguration(),
    this.androidConfiguration = const AndroidConfiguration(),
    this.webConfiguration = const WebConfiguration(),
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
      ...mobileConfiguration.toMap(),
      ...androidConfiguration.toMap(),
      ...webConfiguration.toMap(),
    };
  }
}

class MobileConfiguration {
  final bool enableCoppaControl;
  final bool flushEventsOnClose;
  final int identifyBatchIntervalMillis;
  final bool migrateLegacyData;

  const MobileConfiguration({
    this.enableCoppaControl = false,
    this.flushEventsOnClose = true,
    this.identifyBatchIntervalMillis = Constants.identifyBatchIntervalMillis,
    this.migrateLegacyData = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableCoppaControl': enableCoppaControl,
      'flushEventsOnClose': flushEventsOnClose,
      'identifyBatchIntervalMillis': identifyBatchIntervalMillis,
      'migrateLegacyData': migrateLegacyData,
    };
  }
}

class AndroidConfiguration {
  final bool locationListening;
  final bool useAdvertisingIdForDeviceId;
  final bool useAppSetIdForDeviceId;

  const AndroidConfiguration({
    this.locationListening = true,
    this.useAdvertisingIdForDeviceId = false,
    this.useAppSetIdForDeviceId = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'locationListening': locationListening,
      'useAdvertisingIdForDeviceId': useAdvertisingIdForDeviceId,
      'useAppSetIdForDeviceId': useAppSetIdForDeviceId,
    };
  }
}

class WebConfiguration {
  final int? appVersion;

  const WebConfiguration({
    this.appVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'appVersion': appVersion,
    };
  }
}