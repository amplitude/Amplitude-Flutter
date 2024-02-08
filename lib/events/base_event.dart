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
    userId = options.userId ?? userId;
    deviceId = options.deviceId ?? deviceId;
    timestamp = options.timestamp ?? timestamp;
    eventId = options.eventId ?? eventId;
    insertId = options.insertId ?? insertId;
    locationLat = options.locationLat ?? locationLat;
    locationLng = options.locationLng ?? locationLng;
    appVersion = options.appVersion ?? appVersion;
    versionName = options.versionName ?? versionName;
    platform = options.platform ?? platform;
    osName = options.osName ?? osName;
    osVersion = options.osVersion ?? osVersion;
    deviceBrand = options.deviceBrand ?? deviceBrand;
    deviceManufacturer = options.deviceManufacturer ?? deviceManufacturer;
    deviceModel = options.deviceModel ?? deviceModel;
    carrier = options.carrier ?? carrier;
    country = options.country ?? country;
    region = options.region ?? region;
    city = options.city ?? city;
    dma = options.dma ?? dma;
    idfa = options.idfa ?? idfa;
    idfv = options.idfv ?? idfv;
    adid = options.adid ?? adid;
    appSetId = options.appSetId ?? appSetId;
    androidId = options.androidId ?? androidId;
    language = options.language ?? language;
    library = options.library ?? library;
    ip = options.ip ?? ip;
    plan = options.plan ?? plan;
    ingestionMetadata = options.ingestionMetadata ?? ingestionMetadata;
    revenue = options.revenue ?? revenue;
    price = options.price ?? price;
    quantity = options.quantity ?? quantity;
    productId = options.productId ?? productId;
    revenueType = options.revenueType ?? revenueType;
    extra = options.extra ?? extra;
    partnerId = options.partnerId ?? partnerId;
    sessionId = options.sessionId ?? sessionId;
  }
}
