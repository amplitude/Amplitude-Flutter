import 'dart:async';

import 'package:flutter/services.dart';
import 'events/event_options.dart';
import 'events/identify_event.dart';
import 'events/identify.dart';
import 'events/revenue.dart';
import 'configuration.dart';
import 'events/base_event.dart';
import 'events/group_identify_event.dart';

class Amplitude {
  Configuration configuration;
  MethodChannel _channel = const MethodChannel('amplitude_flutter');

  /// Whether the Amplitude instance has been successfully initialized
  ///
  /// ```
  /// var amplitude = Amplitude(Configuration(apiKey: 'apiKey'));
  /// // If care about init complete
  /// await amplitude.isBuilt;
  /// ```
  late Future<bool> isBuilt;

  /// Returns an Amplitude instance
  ///
  /// ```
  /// final amplitude = Amplitude(Configuration(apiKey: 'apiKey'));
  /// // If care about init complete
  /// await amplitude.isBuilt;
  /// ```
  Amplitude(this.configuration, [MethodChannel? methodChannel]) {
    _channel = methodChannel ?? _channel;
    isBuilt = _init();
  }

  /// Private method to initialize and return a `Future<bool>`
  Future<bool> _init() async {
    try {
      await _channel.invokeMethod('init', configuration.toMap());
      return true; // Initialization successful
    } catch (e) {
      print('Error initializing Amplitude: $e');
      return false; // Initialization failed
    }
  }

  /// Tracks an event. Events are saved locally.
  ///
  /// Uploads are batched to occur every 30 events or every 30 seconds
  /// (whichever comes first), as well as on app close.
  ///
  /// ```
  /// amplitude.track(BaseEvent('Button Clicked'))
  /// ```
  Future<void> track(
    BaseEvent event, [
    EventOptions? options,
  ]) async {
    if (options != null) {
      event.mergeEventOptions(options);
    }

    return await _channel.invokeMethod('track',
        {'instanceName': configuration.instanceName, 'event': event.toMap()});
  }

  /// Updates user properties using operations provided via Identify API.
  ///
  /// Note that this will only affect only future events, and don't update historical events.
  ///
  /// To update user properties, first create an Identify object.
  ///
  /// Example: if you wanted to set a user's gender, increment their karma count by 1, you would do:
  /// ```
  /// final Identify identify = Identify()
  ///   ..set('gender','male')
  ///   ..add('karma', 1);
  /// amplitude.identify(identify);
  /// ```
  Future<void> identify(Identify identify, [EventOptions? options]) async {
    final event = IdentifyEvent();
    event.userProperties = identify.properties;

    if (options != null) {
      event.mergeEventOptions(options);
      if (options.userId != null) {
        // TODO(xinyi): make sure setUserId() is called on native platforms
        setUserId(options.userId!);
      }
      if (options.deviceId != null) {
        // TODO(xinyi): make sure setUserId() is called on native platforms
        setDeviceId(options.deviceId!);
      }
    }

    return await _channel.invokeMethod('identify',
        {'instanceName': configuration.instanceName, 'event': event.toMap()});
  }

  /// Updates the properties of particular groups.
  ///
  /// This feature is available in accounts with a Growth or Enterprise plan
  /// with the [Accounts add-on](https://help.amplitude.com/hc/en-us/articles/115001765532-Account-level-reporting-in-Amplitude).
  ///
  /// Note that this will only affect future events, and don't update historical events.
  ///
  /// Accepts a [groupType], a [groupName], an [identify] object that's applied to the group,
  /// and an optional [eventOptions]
  ///
  /// Example: if you wanted to set a key-value pair as a group property to the enterprise group with group type to be plan, you would do:
  /// ```
  /// final groupIdentifyEvent = Identify()
  ///   ..set('key1', 'value1');
  /// amplitude.groupIdentify('plan', 'enterprise', identify);
  /// ```
  Future<void> groupIdentify(
      String groupType, String groupName, Identify identify,
      [EventOptions? options]) async {
    final event = GroupIdentifyEvent();
    final group = <String, dynamic>{};
    group[groupType] = groupName;
    event.groups = group;
    event.groupProperties = identify.properties;
    if (options != null) {
      event.mergeEventOptions(options);
    }

    return await _channel.invokeMethod('groupIdentify',
        {'instanceName': configuration.instanceName, 'event': event.toMap()});
  }

  /// Adds a user to a group or groups. You need to specify a groupType and groupName(s).
  ///
  /// For example you can group people by their organization. In this case,
  /// groupType is 'orgId', and groupName would be the actual ID(s).
  /// groupName can be a string or an array of strings to indicate a user in multiple groups.
  ///
  /// ```
  /// amplitude.setGroup('orgId', '15');
  /// ```
  ///
  /// You can also call setGroup multiple times with different groupTypes to track
  /// multiple types of groups (up to 5 per app).
  /// Note: This will also set groupType: groupName as a user property.
  Future<void> setGroup(String groupType, dynamic groupName,
      [EventOptions? options]) async {
    if (groupName is! String && groupName is! List<String>) {
      // TODO(xinyi): log warn that groupName should be either a string or an array of string.
      return;
    }

    final identify = Identify().set(groupType, groupName);
    final event = IdentifyEvent()
      ..groups = {groupType: groupName}
      ..userProperties = identify.properties;

    if (options != null) {
      event.mergeEventOptions(options);
    }

    return await _channel.invokeMethod('setGroup',
        {'instanceName': configuration.instanceName, 'event': event.toMap()});
  }

  /// Tracks revenue generated by a user.
  ///
  /// Example:
  /// ```
  /// final revenue = Revenue()
  ///   ..price = 3.99
  ///   ..quantity = 3
  ///   ..productId = 'com.company.productId';
  /// amplitude.revenue(revenue);
  /// ```
  Future<void> revenue(Revenue revenue, [EventOptions? options]) async {
    if (!revenue.isValid()) {
      // TODO(xinyi): logger.warn('Invalid revenue object, missing required fields')
      return;
    }
    final event = revenue.toRevenueEvent();
    if (options != null) {
      event.mergeEventOptions(options);
    }

    return await _channel.invokeMethod('revenue',
        {'instanceName': configuration.instanceName, 'event': event.toMap()});
  }

  /// Get the current user Id.
  /// ```
  /// final userId = await amplitude.getUserId();
  /// ```
  Future<String?> getUserId() async {
    return await _channel.invokeMethod(
        'getUserId', {'instanceName': configuration.instanceName});
  }

  /// Set a custom user Id.
  ///
  /// If your app has its own login system that you want to track users with,
  /// you can set the userId.
  ///
  /// ```
  /// amplitude.setUserId('user Id');
  /// ```
  Future<void> setUserId(String? userId) async {
    Map<String, String?> properties = {};
    properties['setUserId'] = userId;

    return await _channel.invokeMethod('setUserId',
        {'instanceName': configuration.instanceName, 'properties': properties});
  }

  /// Get the current device ID.
  ///
  /// ```
  /// final deviceId = await amplitude.getDeviceId();
  /// ```
  Future<String?> getDeviceId() async {
    return await _channel.invokeMethod(
        'getDeviceId', {'instanceName': configuration.instanceName});
  }

  /// Sets a custom device ID.
  ///
  /// Make sure the value is sufficiently unique. Amplitude recommends using a UUID.
  ///
  /// ```
  /// amplitude.setDeviceId('device Id');
  /// ```
  Future<void> setDeviceId(String? deviceId) async {
    Map<String, String?> properties = {};
    properties['setDeviceId'] = deviceId;

    return await _channel.invokeMethod('setDeviceId',
        {'instanceName': configuration.instanceName, 'properties': properties});
  }

  /// Get the current session ID.
  ///
  /// ```
  /// final sessionId = await amplitude.getSessionId();
  /// ```
  Future<int?> getSessionId() async {
    return await _channel.invokeMethod(
        'getSessionId', {'instanceName': configuration.instanceName});
  }

  /// Web only.
  /// Disables tracking.
  ///
  /// Set setOptOut to true to disable logging for a specific user.
  /// Set setOptOut to false to re-enable logging.
  Future<void> setOptOut(bool enabled) async {
    Map<String, bool> properties = {};
    properties['setOptOut'] = enabled;

    return await _channel.invokeMethod('setOptOut',
        {'instanceName': configuration.instanceName, 'properties': properties});
  }

  /// Resets userId to 'null' and deviceId to a random UUID.
  ///
  /// Note different devices on different platforms should have different device Ids.
  Future<void> reset() async {
    return await _channel
        .invokeMethod('reset', {'instanceName': configuration.instanceName});
  }

  /// Flush events in storage.
  Future<void> flush() async {
    return await _channel
        .invokeMethod('flush', {'instanceName': configuration.instanceName});
  }
}
