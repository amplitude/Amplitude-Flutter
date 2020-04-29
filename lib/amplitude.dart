import 'dart:async';
import 'dart:convert';

import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/identify.dart';
import 'package:flutter/services.dart';

abstract class _Amplitude {
  final MethodChannel _channel = const MethodChannel('amplitude_flutter');
}

class Amplitude extends _Amplitude {
  static Map<String, Amplitude> _instances;

  String _instanceName;

  static Amplitude getInstance({String instanceName = '\$default_instance'}) {
    if (_instances == null) {
      _instances = <String, Amplitude>{};
    }

    return _instances.putIfAbsent(instanceName, () => new Amplitude(instanceName));
  }

  Amplitude(String instanceName) {
    this._instanceName = instanceName;
    setLibraryName(Constants.packageName);
    setLibraryVersion(Constants.packageVersion);
  }

  Future<void> init(String apiKey, {String userId}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['apiKey'] = apiKey;
    if (userId != null) {
      properties['userId'] = userId;
    }

    return await _channel.invokeMethod('init', jsonEncode(properties));
  }

  Future<void> enableCoppaControl() async {
    return await _channel.invokeMethod('enableCoppaControl', jsonEncode(_baseProperties()));
  }

  Future<void> disableCoppaControl() async {
    return await _channel.invokeMethod('disableCoppaControl', jsonEncode(_baseProperties()));
  }

  Future<void> setOptOut(bool optOut) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['optOut'] = optOut;

    return await _channel.invokeMethod('setOptOut', jsonEncode(properties));
  }

  Future<void> setLibraryName(String libraryName) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['libraryName'] = libraryName;

    return await _channel.invokeMethod('setLibraryName', jsonEncode(properties));
  }

  Future<void> setLibraryVersion(String libraryVersion) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['libraryVersion'] = libraryVersion;

    return await _channel.invokeMethod('setLibraryVersion', jsonEncode(properties));
  }

  Future<void> trackingSessionEvents(String trackingSessionEvents) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['trackingSessionEvents'] = trackingSessionEvents;

    return await _channel.invokeMethod('trackingSessionEvents', jsonEncode(properties));
  }

  Future<void> setUserId(String userId, {bool startNewSession}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['userId'] = userId;
    if (startNewSession != null) {
      properties['startNewSession'] = userId;
    }

    return await _channel.invokeMethod('setUserId', jsonEncode(properties));
  }

  Future<void> logEvent(String eventType, {Map<String, dynamic> eventProperties, bool outOfSession}) async {
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

  Future<void> logRevenue(String productIdentifier, {int quantity, double price}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['productIdentifier'] = productIdentifier;
    properties['quantity'] = quantity;
    properties['price'] = price;

    return await _channel.invokeMethod('logRevenue', jsonEncode(properties));
  }

  Future<void> logRevenueAmount(double amount) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['amount'] = amount;

    return await _channel.invokeMethod('logRevenueAmount', jsonEncode(properties));
  }

  // Identify
  Future<void> identify(Identify identify) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['userProperties'] = identify.payload;

    return await _channel.invokeMethod('identify', jsonEncode(properties));
  }

  // Groups
  Future<void> setGroup(String groupType, dynamic groupName) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['groupType'] = groupType;
    properties['groupName'] = groupName;

    return await _channel.invokeMethod('setGroup', jsonEncode(properties));
  }

  Future<void> groupIdentify(String groupType, String groupName, Identify groupIdentify, {bool outOfSession}) async {
    Map<String, dynamic> properties = _baseProperties();
    properties['groupType'] = groupType;
    properties['groupName'] = groupName;
    properties['userProperties'] = groupIdentify.payload;
    if (outOfSession != null) {
      properties['outOfSession'] = outOfSession;
    }

    return await _channel.invokeMethod('groupIdentify', jsonEncode(properties));
  }

  Map<String, dynamic> _baseProperties() {
    return {
      'instanceName': _instanceName
    };
  }
}
