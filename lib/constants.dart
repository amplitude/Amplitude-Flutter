class Constants {
  static const packageName = 'amplitude-flutter';
  static const packageVersion = '4.3.2';
  static const identifyEvent = '\$identify';
  static const groupIdentifyEvent = '\$groupidentify';
  static const revenueEvent = 'revenue_amount';

  static const flushQueueSize = 30;
  static const flushIntervalMillis = 30 * 1000; // 30 seconds
  static const identifyBatchIntervalMillis = 30 * 1000; // 30 seconds
  static const defaultInstanceName = '\$default_instance';
  static const flushMaxRetries = 5;
  static const minTimeBetweenSessionsMillisUnset = -1;
  static const minTimeBetweenSessionsMillisForMobile =
      5 * 60 * 1000; // 5 minutes
  static const minTimeBetweenSessionsMillisForWeb =
      30 * 60 * 1000; // 30 minutes
}

/// Log level enum that maps to platform-specific log levels.
///
/// iOS: Uses log level names directly (off, error, warn, log, debug)
/// Android: Uses log level names directly, but LogLevel.log maps to 'info' instead of 'log' in AmplitudeFlutterPlugin.kt
/// Web: Uses index-based log levels internally, so string values don't affect behavior
///      The mapping is:
///      LogLevel.off -> LogLevel.None
///      LogLevel.error -> LogLevel.Error
///      LogLevel.warn -> LogLevel.Warn
///      LogLevel.log -> LogLevel.Verbose
///      LogLevel.debug -> LogLevel.Debug
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
