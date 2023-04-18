import 'dart:async';
import 'dart:convert';

import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/identify.dart';
import 'package:flutter/services.dart';

abstract class _Amplitude {
  final MethodChannel _channel = const MethodChannel('amplitude_flutter');
}

class Amplitude extends _Amplitude {
  static Map<String, Amplitude>? _instances;

  final String _instanceName;

  static Amplitude getInstance({String instanceName = '\$default_instance'}) {
    if (_instances == null) {
      _instances = <String, Amplitude>{};
    }

    return _instances!
        .putIfAbsent(instanceName, () => new Amplitude(instanceName));
  }

  Amplitude(String instanceName) : _instanceName = instanceName {
    _setLibraryName(Constants.packageName);
    _setLibraryVersion(Constants.packageVersion);
  }

  Future<void> init(String apiKey, {String? userId}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['apiKey'] = apiKey;
    if (userId != null) {
      properties['userId'] = userId;
    }

    return await _channel.invokeMethod('init', jsonEncode(properties));
  }

  /// Enable COPPA (Children's Online Privacy Protection Act) restrictions on
  /// IDFA, IDFV, city, IP address and location tracking.
  ///
  /// This can be used by any customer that does not want to collect IDFA, IDFV,
  /// city, IP address and location tracking.
  Future<void> enableCoppaControl() async {
    return await _channel.invokeMethod(
        'enableCoppaControl', jsonEncode(_baseProperties()));
  }

  /// Disable COPPA (Children's Online Privacy Protection Act) restrictions on
  /// IDFA, IDFV, city, IP address and location tracking.
  Future<void> disableCoppaControl() async {
    return await _channel.invokeMethod(
        'disableCoppaControl', jsonEncode(_baseProperties()));
  }

  /// Enables tracking opt out.
  ///
  /// If the user wants to opt out of all tracking, use this method to enable
  /// opt out for them. Once opt out is enabled, no events will be saved locally
  /// or sent to the server.
  ///
  /// Calling this method again with enabled set to false will turn tracking back on for the user.
  Future<void> setOptOut(bool optOut) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['optOut'] = optOut;

    return await _channel.invokeMethod('setOptOut', jsonEncode(properties));
  }

  /// Whether to automatically log start and end session events corresponding to
  /// the start and end of a user's session.
  Future<void> trackingSessionEvents(bool trackingSessionEvents) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['trackingSessionEvents'] = trackingSessionEvents;

    return await _channel.invokeMethod(
        'trackingSessionEvents', jsonEncode(properties));
  }

  /// If your app has its own login system that you want to track users with,
  /// you can set the userId.
  Future<void> setUserId(String? userId, {bool? startNewSession}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['userId'] = userId;
    if (startNewSession != null) {
      properties['startNewSession'] = startNewSession;
    }

    return await _channel.invokeMethod('setUserId', jsonEncode(properties));
  }

  /// Customize the destination for server url.
  Future<void> setServerUrl(String serverUrl) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['serverUrl'] = serverUrl;

    return await _channel.invokeMethod('setServerUrl', jsonEncode(properties));
  }

  Future<void> setEventUploadThreshold(int value) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['eventUploadThreshold'] = value;

    await _channel.invokeMethod(
        'setEventUploadThreshold', jsonEncode(properties));
  }

  Future<void> setEventUploadPeriodMillis(int value) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['eventUploadPeriodMillis'] = value;

    await _channel.invokeMethod(
        'setEventUploadPeriodMillis', jsonEncode(properties));
  }

  /// Regenerates a new random deviceId for current user.
  /// Note: this is not recommended unless you know what you are doing.
  /// This can be used in conjunction with setUserId(null) to anonymize users after they log out.
  /// With a null userId and a completely new deviceId, the current user would appear as a brand new user in dashboard.
  Future<void> regenerateDeviceId() async {
    return await _channel.invokeMethod(
        'regenerateDeviceId', jsonEncode(_baseProperties()));
  }

  Future<void> setDeviceId(String deviceId) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['deviceId'] = deviceId;

    await _channel.invokeMethod('setDeviceId', jsonEncode(properties));
  }

  /// Dynamically adjust server URL
  Future<void> setUseDynamicConfig(bool useDynamicConfig) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['useDynamicConfig'] = useDynamicConfig;

    return await _channel.invokeMethod(
        'setUseDynamicConfig', jsonEncode(properties));
  }

  /// Tracks an event. Events are saved locally.
  ///
  /// Uploads are batched to occur every 30 events or every 30 seconds
  /// (whichever comes first), as well as on app close.
  ///
  /// [eventType] The name of the event you wish to track.
  /// [eventProperties] You can attach additional data to any event by passing a
  /// [Map] object with property: value pairs.
  Future<void> logEvent(String eventType,
      {Map<String, dynamic>? eventProperties, bool? outOfSession}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['eventType'] = eventType;
    if (eventProperties != null) {
      properties['eventProperties'] = eventProperties;
    }
    if (outOfSession != null) {
      properties['outOfSession'] = outOfSession;
    }

    return await _channel.invokeMethod('logEvent', jsonEncode(properties));
  }

  /// Tracks revenue. This allows us to automatically display data relevant to
  /// revenue on the Amplitude website, including average revenue per daily
  /// active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV)
  /// estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.
  Future<void> logRevenue(
      String productIdentifier, int quantity, double price) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['productIdentifier'] = productIdentifier;
    properties['quantity'] = quantity;
    properties['price'] = price;

    return await _channel.invokeMethod('logRevenue', jsonEncode(properties));
  }

  /// Tracks revenue. This allows us to automatically display data relevant to
  /// revenue on the Amplitude website, including average revenue per daily
  /// active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV)
  /// estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.
  Future<void> logRevenueAmount(double amount) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['amount'] = amount;

    return await _channel.invokeMethod(
        'logRevenueAmount', jsonEncode(properties));
  }

  /// Update user properties using operations provided via Identify API.
  ///
  /// To update user properties, first create an AMPIdentify object.
  ///
  /// Example: if you wanted to set a user's gender, increment their karma count by 1, you would do:
  /// ```
  ///    final Identify identify = Identify()
  ///      ..set('gender','male')
  ///      ..add('karma', 1);
  ///    Amplitude.getInstance.identify(identify);
  /// ```
  Future<void> identify(Identify identify) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['userProperties'] = identify.payload;

    return await _channel.invokeMethod('identify', jsonEncode(properties));
  }

  /// Adds a user to a group or groups. You need to specify a groupType and groupName(s).

  /// For example you can group people by their organization. In this case,
  /// groupType is "orgId", and groupName would be the actual ID(s).
  /// groupName can be a string or an array of strings to indicate a user in multiple groups.

  /// You can also call setGroup multiple times with different groupTypes to track
  /// multiple types of groups (up to 5 per app).
  /// Note: This will also set groupType: groupName as a user property.
  Future<void> setGroup(String groupType, dynamic groupName) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['groupType'] = groupType;
    properties['groupName'] = groupName;

    return await _channel.invokeMethod('setGroup', jsonEncode(properties));
  }

  /// Use the Group Identify API to set or update properties of particular groups.
  /// However, these updates will only affect events going forward.
  Future<void> groupIdentify(
      String groupType, String groupName, Identify groupIdentify,
      {bool outOfSession = false}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['groupType'] = groupType;
    properties['groupName'] = groupName;
    properties['userProperties'] = groupIdentify.payload;
    properties['outOfSession'] = outOfSession;

    return await _channel.invokeMethod('groupIdentify', jsonEncode(properties));
  }

  /// Adds properties that are tracked on the user level.
  ///
  /// Note: Property keys must be [String] objects and values must be serializable.
  Future<void> setUserProperties(Map<String, dynamic> userProperties) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['userProperties'] = userProperties;

    return await _channel.invokeMethod(
        'setUserProperties', jsonEncode(properties));
  }

  /// Clears all properties that are tracked on the user level.
  ///
  /// Note: This operation is irreversible!!
  Future<void> clearUserProperties() async {
    return await _channel.invokeMethod(
        'clearUserProperties', jsonEncode(_baseProperties()));
  }

  /// Upload all unsent events.
  Future<void> uploadEvents() async {
    return await _channel.invokeMethod(
        'uploadEvents', jsonEncode(_baseProperties()));
  }

  Map<String, dynamic> _baseProperties() {
    return {'instanceName': _instanceName};
  }

  /// Private bridging calls
  Future<void> _setLibraryName(String libraryName) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['libraryName'] = libraryName;

    return await _channel.invokeMethod(
        'setLibraryName', jsonEncode(properties));
  }

  Future<void> _setLibraryVersion(String libraryVersion) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['libraryVersion'] = libraryVersion;

    return await _channel.invokeMethod(
        'setLibraryVersion', jsonEncode(properties));
  }

  /// Fetches the deviceId, a unique identifier shared between multiple users using the same app on the same device.
  /// @returns the deviceId.
  Future<String?> getDeviceId() async {
    return await _channel.invokeMethod(
        'getDeviceId', jsonEncode(_baseProperties()));
  }

  /// Fetches the userId, a unique identifier for tracking a user.
  /// @returns the userId
  Future<String?> getUserId() async {
    return await _channel.invokeMethod(
        'getUserId', jsonEncode(_baseProperties()));
  }

  /// Fetches the current sessionId, an identifier used by Amplitude to group together events tracked during the same session.
  /// @returns the sessionId.
  Future<int?> getSessionId() async {
    return await _channel.invokeMethod(
        'getSessionId', jsonEncode(_baseProperties()));
  }

  // Android only, supports to use android app set id as device id
  Future<void> useAppSetIdForDeviceId() async {
    return await _channel.invokeMethod(
        'useAppSetIdForDeviceId', jsonEncode(_baseProperties()));
  }

  /// Defines a custom session expiration time where the timeout input is in milliseconds.
  Future<void> setMinTimeBetweenSessionsMillis(int timeInMillis) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['timeInMillis'] = timeInMillis;

    return await _channel.invokeMethod(
        'setMinTimeBetweenSessionsMillis', jsonEncode(properties));
  }

  /// Set Amplitude Server Zone, switch to zone related configuration, including dynamic configuration and server url.
  /// To send data to Amplitude's EU servers, you need to configure the serverZone to EU like client.setServerZone("EU");
  /// serverZone could be EU or US. Recommend to keep updateServerUrl to be true for alignment.
  Future<void> setServerZone(String serverZone,
      {bool updateServerUrl = true}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['serverZone'] = serverZone;
    properties['updateServerUrl'] = updateServerUrl;

    return await _channel.invokeMethod('setServerZone', jsonEncode(properties));
  }

  /// Sets offline. If offline is true, then the SDK will not upload events to Amplitude servers;
  /// however, it will still log events.
  Future<void> setOffline(bool enabled) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['offline'] = enabled;

    return await _channel.invokeMethod('setOffline', jsonEncode(properties));
  }
}
