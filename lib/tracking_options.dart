import 'constants.dart';

class TrackingOptions {
  final bool disableIpAddress;
  final bool disableLanguage;
  final bool disablePlatform;
  final MobileTrackingOptions mobileTrackingOptions;
  final AndroidTrackingOptions androidTrackingOptions;
  final IOSTrackingOptions iosTrackingOptions;

  TrackingOptions({
    this.disableIpAddress = false,
    this.disableLanguage = false,
    this.disablePlatform = false,
    this.mobileTrackingOptions = const MobileTrackingOptions(),
    this.androidTrackingOptions = const AndroidTrackingOptions(),
    this.iosTrackingOptions = const IOSTrackingOptions(),
  });

  Map<String, Set<String>> toMap() {
    Set<String> disableFields = {};

    // General tracking options
    if (disableIpAddress) disableFields.add(Constants.ampTrackingOptionIpAddress);
    if (disableLanguage) disableFields.add(Constants.ampTrackingOptionLanguage);
    if (disablePlatform) disableFields.add(Constants.ampTrackingOptionPlatform);

    // Mobile tracking options
    if (mobileTrackingOptions.disableRegion) disableFields.add(Constants.ampTrackingOptionRegion);
    if (mobileTrackingOptions.disableDma) disableFields.add(Constants.ampTrackingOptionDma);
    if (mobileTrackingOptions.disableCountry) disableFields.add(Constants.ampTrackingOptionCountry);
    if (mobileTrackingOptions.disableCity) disableFields.add(Constants.ampTrackingOptionCity);
    if (mobileTrackingOptions.disableCarrier) disableFields.add(Constants.ampTrackingOptionCarrier);
    if (mobileTrackingOptions.disableDeviceModel) disableFields.add(Constants.ampTrackingOptionDeviceModel);
    if (mobileTrackingOptions.disableDeviceManufacturer) disableFields.add(Constants.ampTrackingOptionDeviceManufacturer);
    if (mobileTrackingOptions.disableOsVersion) disableFields.add(Constants.ampTrackingOptionOsVersion);
    if (mobileTrackingOptions.disableOsName) disableFields.add(Constants.ampTrackingOptionOsName);
    if (mobileTrackingOptions.disableVersionName) disableFields.add(Constants.ampTrackingOptionVersionName);

    // Android-specific tracking options
    if (androidTrackingOptions.disableADID) disableFields.add(Constants.ampTrackingOptionAdid);
    if (androidTrackingOptions.disableAppSetId) disableFields.add(Constants.ampTrackingOptionAppSetId);
    if (androidTrackingOptions.disableDeviceBrand) disableFields.add(Constants.ampTrackingOptionDeviceBrand);
    if (androidTrackingOptions.disableLatLag) disableFields.add(Constants.ampTrackingOptionLatLag);
    if (androidTrackingOptions.disableApiLevel) disableFields.add(Constants.ampTrackingOptionApiLevel);

    // iOS-specific tracking options
    if (iosTrackingOptions.disableIDFV) disableFields.add(Constants.ampTrackingOptionIdfv);

    return {
      'disabledFields': disableFields,
    };
  }
}

class MobileTrackingOptions {
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

  const MobileTrackingOptions({
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
  });
}

class AndroidTrackingOptions {
  final bool disableADID;
  final bool disableAppSetId;
  final bool disableDeviceBrand;
  final bool disableLatLag;
  final bool disableApiLevel;

  const AndroidTrackingOptions({
    this.disableADID = false,
    this.disableAppSetId = false,
    this.disableDeviceBrand = false,
    this.disableLatLag = false,
    this.disableApiLevel = false,
  });
}

class IOSTrackingOptions {
  final bool disableIDFV;

  const IOSTrackingOptions({
    this.disableIDFV = false
  });
}
