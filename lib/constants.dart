class Constants {
  static const packageName = 'amplitude-flutter';
  static const packageVersion = '3.16.1';

  static const flushQueueSize = 30;
  static const flushIntervalMillis = 30 * 1000; // 30 seconds
  static const identifyBatchIntervalMillis = 30 * 1000; // 30 seconds
  static const defaultInstanceName = '\$default_instance';
  static const logLevel = 'info';
  static const flushMaxRetries = 5;
  static const minTimeBetweenSessionsMillis = 5 * 60 * 1000; // 5 minutes

  // Tracking options available on iOS, Android, and Web
  static const String ampTrackingOptionIpAddress = "ip_address";
  static const String ampTrackingOptionLanguage = "language";
  static const String ampTrackingOptionPlatform = "platform";
  // Tracking options only available on iOS, Android
  static const String ampTrackingOptionCarrier = "carrier";
  static const String ampTrackingOptionCity = "city";
  static const String ampTrackingOptionCountry = "country";
  static const String ampTrackingOptionDeviceModel = "device_model";
  static const String ampTrackingOptionDeviceManufacturer = "device_manufacturer";
  static const String ampTrackingOptionDma = "dma";
  static const String ampTrackingOptionOsName = "os_name";
  static const String ampTrackingOptionOsVersion = "os_version";
  static const String ampTrackingOptionRegion = "region";
  static const String ampTrackingOptionVersionName = "version_name";
  // Tracking options only available on iOS
  static const String ampTrackingOptionIdfv = "idfv";
  // Tracking options only available on Android
  static const String ampTrackingOptionAdid = 'adid';
  static const String ampTrackingOptionAppSetId = 'app_set_id';
  static const String ampTrackingOptionDeviceBrand = "device_brand";
  static const String ampTrackingOptionLatLag = "Lat_Lng";
  static const String ampTrackingOptionApiLevel = "api_level";
}

enum LogLevel {
  off,
  error,
  warn,
  log,
  debug,
}

enum ServerZone {
  us,
  eu,
}
