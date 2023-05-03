import 'package:flutter/foundation.dart';
import 'dart:convert';

enum TrackingOptionStatus { unknown, enabled, disabled }

// iOS only
//    IDFA, IDFV
// Android only
//    Adid, ApiLevel, AppSetId, DeviceBrand

class TrackingOptions {
  final Map<String, dynamic> _options = {
    'Adid': true,
    'ApiLevel': true,
    'AppSetId': true,
    'Carrier': true,
    'City': true,
    'Country': true,
    'DeviceBrand': true,
    'DeviceManufacturer': true,
    'DeviceModel': true,
    'DMA': true,
    'IDFA': true,
    'IDFV': true,
    'IpAddress': true,
    'Language': true,
    'LatLng': true,
    'OsName': true,
    'OsVersion': true,
    'Platform': true,
    'Region': true,
    'VersionName': true
  };

  TrackingOptionStatus enableProperty(String key) {
    if (_options.containsKey(key)) {
      _options[key] = true;
      return TrackingOptionStatus.enabled;
    }
    return TrackingOptionStatus.unknown;
  }

  TrackingOptionStatus disableProperty(String key) {
    if (_options.containsKey(key)) {
      _options[key] = false;
      return TrackingOptionStatus.disabled;
    }
    return TrackingOptionStatus.unknown;
  }

  int enableProperties(List<String> optionKeys) {
    int count = 0;
    optionKeys.forEach((key) {
      if (_options.containsKey(key)) {
        _options[key] = true;
        count++;
      }
    });
    return count;
  }

  int disableProperties(List<String> optionKeys) {
    int count = 0;
    optionKeys.forEach((key) {
      if (_options.containsKey(key)) {
        _options[key] = false;
        count++;
      }
    });
    return count;
  }

  TrackingOptionStatus queryProperty(String key) {
    if (_options.containsKey(key)) {
      if(_options[key]!)
        return TrackingOptionStatus.enabled;
      return TrackingOptionStatus.disabled;
    }
    return TrackingOptionStatus.unknown;
  }

  Map<String, dynamic> getProperties(){
    return new Map<String, dynamic>.from(_options);
  }
}
