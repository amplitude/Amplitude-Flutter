import 'constants.dart';

/// Options to control the values tracked in SDK
///
/// Different platforms have different default events.
/// Refer to platform specific docs for more details.
///
/// * [iOS](https://www.docs.developers.amplitude.com/data/sdks/ios-swift/#disable-tracking)
/// * [Android](https://www.docs.developers.amplitude.com/data/sdks/android-kotlin/#disable-tracking)
/// * [Web](https://www.docs.developers.amplitude.com/data/sdks/browser-2/#optional-tracking)
class TrackingOptions {
  final bool ipAddress;
  final bool language;
  final bool platform;
  /// Mobile (iOS and Android) specific
  final bool region;
  /// Mobile (iOS and Android) specific
  final bool dma;
  /// Mobile (iOS and Android) specific
  final bool country;
  /// Mobile (iOS and Android) specific
  final bool city;
  /// Mobile (iOS and Android) specific
  final bool carrier;
  /// Mobile (iOS and Android) specific
  final bool deviceModel;
  /// Mobile (iOS and Android) specific
  final bool deviceManufacturer;
  /// Mobile (iOS and Android) specific
  final bool osVersion;
  /// Mobile (iOS and Android) specific
  final bool osName;
  /// Mobile (iOS and Android) specific
  final bool versionName;
  /// Android specific
  final bool adid;
  /// Android specific
  final bool appSetId;
  /// Android specific
  final bool deviceBrand;
  /// Android specific
  final bool latLag;
  /// Android specific
  final bool apiLevel;
  /// iOS specific
  final bool idfv;

  TrackingOptions({
    this.ipAddress = true,
    this.language = true,
    this.platform = true,
    this.region = true,
    this.dma = true,
    this.country = true,
    this.city = true,
    this.carrier = true,
    this.deviceModel = true,
    this.deviceManufacturer = true,
    this.osVersion = true,
    this.osName = true,
    this.versionName = true,
    this.adid = true,
    this.appSetId = true,
    this.deviceBrand = true,
    this.latLag = true,
    this.apiLevel = true,
    this.idfv = true
  });

  Map<String, Set<String>> toMap() {
    Set<String> disableFields = {};

    // General tracking options
    if (!ipAddress) disableFields.add(Constants.ampTrackingOptionIpAddress);
    if (!language) disableFields.add(Constants.ampTrackingOptionLanguage);
    if (!platform) disableFields.add(Constants.ampTrackingOptionPlatform);

    // Mobile tracking options
    if (!region) disableFields.add(Constants.ampTrackingOptionRegion);
    if (!dma) disableFields.add(Constants.ampTrackingOptionDma);
    if (!country) disableFields.add(Constants.ampTrackingOptionCountry);
    if (!city) disableFields.add(Constants.ampTrackingOptionCity);
    if (!carrier) disableFields.add(Constants.ampTrackingOptionCarrier);
    if (!deviceModel) disableFields.add(Constants.ampTrackingOptionDeviceModel);
    if (!deviceManufacturer) disableFields.add(Constants.ampTrackingOptionDeviceManufacturer);
    if (!osVersion) disableFields.add(Constants.ampTrackingOptionOsVersion);
    if (!osName) disableFields.add(Constants.ampTrackingOptionOsName);
    if (!versionName) disableFields.add(Constants.ampTrackingOptionVersionName);

    // Android-specific tracking options
    if (!adid) disableFields.add(Constants.ampTrackingOptionAdid);
    if (!appSetId) disableFields.add(Constants.ampTrackingOptionAppSetId);
    if (!deviceBrand) disableFields.add(Constants.ampTrackingOptionDeviceBrand);
    if (!latLag) disableFields.add(Constants.ampTrackingOptionLatLag);
    if (!apiLevel) disableFields.add(Constants.ampTrackingOptionApiLevel);

    // iOS-specific tracking options
    if (!idfv) disableFields.add(Constants.ampTrackingOptionIdfv);

    return {
      'disabledFields': disableFields,
    };
  }
}

