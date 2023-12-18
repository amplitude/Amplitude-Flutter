import 'constants.dart';

/// Disable tracking of user properties.
///
/// Before initialzing Amplitude instance, create a TrackingOptions instance
/// with your desired tracking options and pass it to the Amplitude instance.
class TrackingOptions {
  Set<String> _disabledFields = {};

  // Available on iOS, Android, and Web
  TrackingOptions disableIpAddress() {
    _disabledFields.add(Constants.ampTrackingOptionIpAddress);
    return this;
  }

  TrackingOptions disableLanguage() {
    _disabledFields.add(Constants.ampTrackingOptionLanguage);
    return this;
  }

  TrackingOptions disablePlatform() {
    _disabledFields.add(Constants.ampTrackingOptionPlatform);
    return this;
  }

  // Only avaliable on iOS and Android
  TrackingOptions disableVersionName() {
    _disabledFields.add(Constants.ampTrackingOptionVersionName);
    return this;
  }

  TrackingOptions disableOsName() {
    _disabledFields.add(Constants.ampTrackingOptionOsName);
    return this;
  }

  TrackingOptions disableOsVersion() {
    _disabledFields.add(Constants.ampTrackingOptionOsVersion);
    return this;
  }

  TrackingOptions disableDeviceManufacturer() {
    _disabledFields.add(Constants.ampTrackingOptionDeviceManufacturer);
    return this;
  }

  TrackingOptions disableDeviceModel() {
    _disabledFields.add(Constants.ampTrackingOptionDeviceModel);
    return this;
  }

  TrackingOptions disableCarrier() {
    _disabledFields.add(Constants.ampTrackingOptionCarrier);
    return this;
  }

  TrackingOptions disableCity() {
    _disabledFields.add(Constants.ampTrackingOptionCity);
    return this;
  }

  TrackingOptions disableCountry() {
    _disabledFields.add(Constants.ampTrackingOptionCountry);
    return this;
  }

  TrackingOptions disableDma() {
    _disabledFields.add(Constants.ampTrackingOptionDma);
    return this;
  }

  TrackingOptions disableRegion() {
    _disabledFields.add(Constants.ampTrackingOptionRegion);
    return this;
  }

  // Only avaliable on Android
  TrackingOptions disableADID() {
    _disabledFields.add(Constants.ampTrackingOptionAdid);
    return this;
  }

  TrackingOptions disableAppSetId() {
    _disabledFields.add(Constants.ampTrackingOptionAppSetId);
    return this;
  }

  TrackingOptions disableDeviceBrand() {
    _disabledFields.add(Constants.ampTrackingOptionDeviceBrand);
    return this;
  }

  TrackingOptions disableLatLag() {
    _disabledFields.add(Constants.ampTrackingOptionLatLag);
    return this;
  }

  TrackingOptions disableApiLevel() {
    _disabledFields.add(Constants.ampTrackingOptionApiLevel);
    return this;
  }

  // Only available on Swift
  TrackingOptions disableIDFV() {
    _disabledFields.add(Constants.ampTrackingOptionIdfv);
    return this;
  }

  Map<String, Set<String>> toMap() {
    return {
      'disabledFields': _disabledFields,
    };
  }
}
