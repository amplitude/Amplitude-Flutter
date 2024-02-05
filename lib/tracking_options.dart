import 'constants.dart';

class TrackingOptions {
  final bool disableIpAddress;
  final bool disableLanguage;
  final bool disablePlatform;
  // Mobile (iOS and Android) specific
  final bool disableRegion;
  final bool disableDma;
  final bool disableCountry;
  final bool disableCity;
  final bool disableCarrier;
  final bool disableDeviceModel;
  final bool disableDeviceManufacturer;
  final bool disableOsVersion;
  final bool disableOsName;
  final bool disableVersionName;
  // Android specific
  final bool disableADID;
  final bool disableAppSetId;
  final bool disableDeviceBrand;
  final bool disableLatLag;
  final bool disableApiLevel;
  // iOS specific
  final bool disableIDFV;

  TrackingOptions({
    this.disableIpAddress = false,
    this.disableLanguage = false,
    this.disablePlatform = false,
    this.disableRegion = false,
    this.disableDma = false,
    this.disableCountry = false,
    this.disableCity = false,
    this.disableCarrier = false,
    this.disableDeviceModel = false,
    this.disableDeviceManufacturer = false,
    this.disableOsVersion = false,
    this.disableOsName = false,
    this.disableVersionName = false,
    this.disableADID = false,
    this.disableAppSetId = false,
    this.disableDeviceBrand = false,
    this.disableLatLag = false,
    this.disableApiLevel = false,
    this.disableIDFV = false
  });

  Map<String, Set<String>> toMap() {
    Set<String> disableFields = {};

    // General tracking options
    if (disableIpAddress) disableFields.add(Constants.ampTrackingOptionIpAddress);
    if (disableLanguage) disableFields.add(Constants.ampTrackingOptionLanguage);
    if (disablePlatform) disableFields.add(Constants.ampTrackingOptionPlatform);

    // Mobile tracking options
    if (disableRegion) disableFields.add(Constants.ampTrackingOptionRegion);
    if (disableDma) disableFields.add(Constants.ampTrackingOptionDma);
    if (disableCountry) disableFields.add(Constants.ampTrackingOptionCountry);
    if (disableCity) disableFields.add(Constants.ampTrackingOptionCity);
    if (disableCarrier) disableFields.add(Constants.ampTrackingOptionCarrier);
    if (disableDeviceModel) disableFields.add(Constants.ampTrackingOptionDeviceModel);
    if (disableDeviceManufacturer) disableFields.add(Constants.ampTrackingOptionDeviceManufacturer);
    if (disableOsVersion) disableFields.add(Constants.ampTrackingOptionOsVersion);
    if (disableOsName) disableFields.add(Constants.ampTrackingOptionOsName);
    if (disableVersionName) disableFields.add(Constants.ampTrackingOptionVersionName);

    // Android-specific tracking options
    if (disableADID) disableFields.add(Constants.ampTrackingOptionAdid);
    if (disableAppSetId) disableFields.add(Constants.ampTrackingOptionAppSetId);
    if (disableDeviceBrand) disableFields.add(Constants.ampTrackingOptionDeviceBrand);
    if (disableLatLag) disableFields.add(Constants.ampTrackingOptionLatLag);
    if (disableApiLevel) disableFields.add(Constants.ampTrackingOptionApiLevel);

    // iOS-specific tracking options
    if (disableIDFV) disableFields.add(Constants.ampTrackingOptionIdfv);

    return {
      'disabledFields': disableFields,
    };
  }
}

