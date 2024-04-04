class Constants {
  static const packageName = 'amplitude-flutter';
  static const packageVersion = '4.0.0-beta.2';
  static const identifyEvent = '\$identify';
  static const groupIdentifyEvent = '\$groupidentify';
  static const revenueEvent = 'revenue_amount';

  static const flushQueueSize = 30;
  static const flushIntervalMillis = 30 * 1000; // 30 seconds
  static const identifyBatchIntervalMillis = 30 * 1000; // 30 seconds
  static const defaultInstanceName = '\$default_instance';
  static const logLevel = 'info';
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
