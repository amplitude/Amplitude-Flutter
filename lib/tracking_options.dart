import 'constants.dart';

/// Disable tracking of user properties.
///
/// Before initialzing Amplitude instance, create a TrackingOptions instance
/// with your desired tracking options and pass it to the Amplitude instance.
class TrackingOptions {
  Set<String> _disabledFields = {};

  // Available on iOS, Android, and Web
  TrackingOptions diableIpAddress() {
    _disabledFields.add(Constants.ampTrackingOptionIpAddress);
    return this;
  }

  TrackingOptions diableLanguage() {
    _disabledFields.add(Constants.ampTrackingOptionLanguage);
    return this;
  }

  TrackingOptions diablePlatform() {
    _disabledFields.add(Constants.ampTrackingOptionPlatform);
    return this;
  }

  // Only avaliable on iOS and Android
  TrackingOptions diableVersionName() {
    _disabledFields.add(Constants.ampTrackingOptionVersionName);
    return this;
  }

  TrackingOptions diableOsName() {
    _disabledFields.add(Constants.ampTrackingOptionOsName);
    return this;
  }

  TrackingOptions diableOsVersion() {
    _disabledFields.add(Constants.ampTrackingOptionOsVersion);
    return this;
  }

  TrackingOptions diableDeviceManufacturer() {
    _disabledFields.add(Constants.ampTrackingOptionDeviceManufacturer);
    return this;
  }

  TrackingOptions diableDeviceModel() {
    _disabledFields.add(Constants.ampTrackingOptionDeviceModel);
    return this;
  }

  TrackingOptions diableCarrier() {
    _disabledFields.add(Constants.ampTrackingOptionCarrier);
    return this;
  }

  TrackingOptions diableCity() {
    _disabledFields.add(Constants.ampTrackingOptionCity);
    return this;
  }

  TrackingOptions diableCountry() {
    _disabledFields.add(Constants.ampTrackingOptionCountry);
    return this;
  }

  TrackingOptions diableDma() {
    _disabledFields.add(Constants.ampTrackingOptionDma);
    return this;
  }

  TrackingOptions diableRegion() {
    _disabledFields.add(Constants.ampTrackingOptionRegion);
    return this;
  }

  // Only avaliable on Android
  TrackingOptions diableADID() {
    _disabledFields.add(Constants.ampTrackingOptionAdid);
    return this;
  }

  TrackingOptions diableAppSetId() {
    _disabledFields.add(Constants.ampTrackingOptionAppSetId);
    return this;
  }

  TrackingOptions diableDeviceBrand() {
    _disabledFields.add(Constants.ampTrackingOptionDeviceBrand);
    return this;
  }

  TrackingOptions diableLatLag() {
    _disabledFields.add(Constants.ampTrackingOptionLatLag);
    return this;
  }

  TrackingOptions diableApiLevel() {
    _disabledFields.add(Constants.ampTrackingOptionApiLevel);
    return this;
  }

  // Only available on Swift
  TrackingOptions diableIDFV() {
    _disabledFields.add(Constants.ampTrackingOptionIdfv);
    return this;
  }

  Map<String, Set<String>> toMap() {
    return {
      'disabledFields': _disabledFields,
    };
  }
}
