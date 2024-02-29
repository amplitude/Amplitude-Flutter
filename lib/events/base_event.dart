import 'package:amplitude_flutter/constants.dart';
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
    String library = "${Constants.packageName}/${Constants.packageVersion}",
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
        );

  Map<String, dynamic> toMap() {
    return {
      'event_type': eventType,
      if (eventProperties != null) 'event_properties': eventProperties,
      if (userProperties != null) 'user_properties': userProperties,
      if (groups != null) 'groups': groups,
      if (groupProperties != null) 'group_properties': groupProperties,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (timestamp != null) 'timestamp': timestamp,
      if (eventId != null) 'event_id': eventId,
      if (sessionId != null) 'session_id': sessionId,
      if (insertId != null) 'insert_id': insertId,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      if (appVersion != null) 'app_version': appVersion,
      if (versionName != null) 'version_name': versionName,
      if (platform != null) 'platform': platform,
      if (osName != null) 'os_name': osName,
      if (osVersion != null) 'os_version': osVersion,
      if (deviceBrand != null) 'device_brand': deviceBrand,
      if (deviceManufacturer != null) 'device_manufacturer': deviceManufacturer,
      if (deviceModel != null) 'device_model': deviceModel,
      if (carrier != null) 'carrier': carrier,
      if (country != null) 'country': country,
      if (region != null) 'region': region,
      if (city != null) 'city': city,
      if (dma != null) 'dma': dma,
      if (idfa != null) 'idfa': idfa,
      if (idfv != null) 'idfv': idfv,
      if (adid != null) 'adid': adid,
      if (appSetId != null) 'app_set_id': appSetId,
      if (androidId != null) 'android_id': androidId,
      if (language != null) 'language': language,
      if (library != null) 'library': library,
      if (ip != null) 'ip': ip,
      if (plan != null) 'plan': plan?.toMap(),
      if (ingestionMetadata != null) 'ingestion_metadata': ingestionMetadata?.toMap(),
      if (revenue != null) 'revenue': revenue,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (productId != null) 'product_id': productId,
      if (revenueType != null) 'revenue_type': revenueType,
      if (extra != null) 'extra': extra,
      if (partnerId != null) 'partner_id': partnerId,
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
