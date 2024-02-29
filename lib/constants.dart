class Constants {
  static const packageName = "amplitude-flutter";
  static const packageVersion = "4.0.0-beta.0";
  static const identify_event = "\$identify";
  static const group_identify_event = "\$groupidentify";
  static const revenue_event = "revenue_amount";

  static const flushQueueSize = 30;
  static const flushIntervalMillis = 30 * 1000; // 30 seconds
  static const identifyBatchIntervalMillis = 30 * 1000; // 30 seconds
  static const defaultInstanceName = "\$default_instance";
  static const logLevel = "info";
  static const flushMaxRetries = 5;
  static const minTimeBetweenSessionsMillis = 5 * 60 * 1000; // 5 minutes
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
