import 'package:amplitude_flutter/events/plan.dart';
import 'event_options.dart';
import 'ingestion_metadata.dart';

class BaseEvent extends EventOptions {
  String eventType;
  Map<String, dynamic>? eventProperties;
  Map<String, dynamic>? userProperties;
  Map<String, dynamic>? groups;
  Map<String, dynamic>? groupProperties;

  BaseEvent({
    String? userId,
    String? deviceId,
    int? timestamp,
    int? eventId,
    int? sessionId,
    String? insertId,
    double? locationLat,
    double? locationLng,
    String? appVersion,
    String? versionName,
    String? platform,
    String? osName,
    String? osVersion,
    String? deviceBrand,
    String? deviceManufacturer,
    String? deviceModel,
    String? carrier,
    String? country,
    String? region,
    String? city,
    String? dma,
    String? idfa,
    String? idfv,
    String? adid,
    String? appSetId,
    String? androidId,
    String? language,
    String? library,
    String? ip,
    Plan? plan,
    IngestionMetadata? ingestionMetadata,
    double? revenue,
    double? price,
    int? quantity,
    String? productId,
    String? revenueType,
    Map<String, dynamic>? extra,
    String? partnerId,
    int attempts = 0,
    required this.eventType,
    this.eventProperties,
    this.userProperties,
    this.groups,
    this.groupProperties,
  }) : super(
          userId: userId,
          deviceId: deviceId,
          timestamp: timestamp,
          eventId: eventId,
          sessionId: sessionId,
          insertId: insertId,
          locationLat: locationLat,
          locationLng: locationLng,
          appVersion: appVersion,
          versionName: versionName,
          platform: platform,
          osName: osName,
          osVersion: osVersion,
          deviceBrand: deviceBrand,
          deviceManufacturer: deviceManufacturer,
          deviceModel: deviceModel,
          carrier: carrier,
          country: country,
          region: region,
          city: city,
          dma: dma,
          idfa: idfa,
          idfv: idfv,
          adid: adid,
          appSetId: appSetId,
          androidId: androidId,
          language: language,
          library: library,
          ip: ip,
          plan: plan,
          ingestionMetadata: ingestionMetadata,
          revenue: revenue,
          price: price,
          quantity: quantity,
          productId: productId,
          revenueType: revenueType,
          extra: extra,
          partnerId: partnerId,
          attempts: attempts,
        );

  Map<String, dynamic> toMap() {
    return {
      'event_type': eventType,
      'event_properties': eventProperties,
      'user_properties': userProperties,
      'groups': groups,
      'group_properties': groupProperties,
      'user_id': userId,
      'device_id': deviceId,
      'timestamp': timestamp,
      'event_id': eventId,
      'session_id': sessionId,
      'insert_id': insertId,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'app_version': appVersion,
      'version_name': versionName,
      'platform': platform,
      'os_name': osName,
      'os_version': osVersion,
      'device_brand': deviceBrand,
      'device_manufacturer': deviceManufacturer,
      'device_model': deviceModel,
      'carrier': carrier,
      'country': country,
      'region': region,
      'city': city,
      'dma': dma,
      'idfa': idfa,
      'idfv': idfv,
      'adid': adid,
      'app_set_id': appSetId,
      'android_id': androidId,
      'language': language,
      'library': library,
      'ip': ip,
      'plan': plan?.toMap(),
      'ingestion_metadata': ingestionMetadata?.toMap(),
      'revenue': revenue,
      'price': price,
      'quantity': quantity,
      'product_id': productId,
      'revenue_type': revenueType,
      'extra': extra,
      'partner_id': partnerId,
      'attempts': attempts,
    };
  }

  void mergeEventOptions(EventOptions options) {
    if (options.userId != null) userId = options.userId!;
    if (options.deviceId != null) deviceId = options.deviceId!;
    if (options.timestamp != null) timestamp = options.timestamp!;
    if (options.eventId != null) eventId = options.eventId!;
    if (options.insertId != null) insertId = options.insertId!;
    if (options.locationLat != null) locationLat = options.locationLat!;
    if (options.locationLng != null) locationLng = options.locationLng!;
    if (options.appVersion != null) appVersion = options.appVersion!;
    if (options.versionName != null) versionName = options.versionName!;
    if (options.platform != null) platform = options.platform!;
    if (options.osName != null) osName = options.osName!;
    if (options.osVersion != null) osVersion = options.osVersion!;
    if (options.deviceBrand != null) deviceBrand = options.deviceBrand!;
    if (options.deviceManufacturer != null)
      deviceManufacturer = options.deviceManufacturer!;
    if (options.deviceModel != null) deviceModel = options.deviceModel!;
    if (options.carrier != null) carrier = options.carrier!;
    if (options.country != null) country = options.country!;
    if (options.region != null) region = options.region!;
    if (options.city != null) city = options.city!;
    if (options.dma != null) dma = options.dma!;
    if (options.idfa != null) idfa = options.idfa!;
    if (options.idfv != null) idfv = options.idfv!;
    if (options.adid != null) adid = options.adid!;
    if (options.appSetId != null) appSetId = options.appSetId!;
    if (options.androidId != null) androidId = options.androidId!;
    if (options.language != null) language = options.language!;
    if (options.library != null) library = options.library!;
    if (options.ip != null) ip = options.ip!;
    if (options.plan != null) plan = options.plan!;
    if (options.ingestionMetadata != null)
      ingestionMetadata = options.ingestionMetadata!;
    if (options.revenue != null) revenue = options.revenue!;
    if (options.price != null) price = options.price!;
    if (options.quantity != null) quantity = options.quantity!;
    if (options.productId != null) productId = options.productId!;
    if (options.revenueType != null) revenueType = options.revenueType!;
    if (options.extra != null) extra = options.extra!;
    if (options.partnerId != null) partnerId = options.partnerId!;
    if (options.sessionId != null) sessionId = options.sessionId!;
  }
}
