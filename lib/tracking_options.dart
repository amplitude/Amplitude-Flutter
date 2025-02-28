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

  TrackingOptions(
      {this.ipAddress = true,
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
      this.idfv = true});

  Map<String, bool> toMap() {
    return {
      'ipAddress': ipAddress,
      'language': language,
      'platform': platform,
      'region': region,
      'dma': dma,
      'country': country,
      'city': city,
      'carrier': carrier,
      'deviceModel': deviceModel,
      'deviceManufacturer': deviceManufacturer,
      'osVersion': osVersion,
      'osName': osName,
      'versionName': versionName,
      'adid': adid,
      'appSetId': appSetId,
      'deviceBrand': deviceBrand,
      'latLag': latLag,
      'apiLevel': apiLevel,
      'idfv': idfv,
    };
  }
}
