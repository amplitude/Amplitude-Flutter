import 'dart:core';

import 'plan.dart';
import 'ingestion_metadata.dart';

/// Keys for event arguments
///
/// To learn more at https://www.docs.developers.amplitude.com/analytics/apis/http-v2-api/#keys-for-the-event-argument
class EventOptions {
  String? userId;
  String? deviceId;
  int? timestamp;
  int? eventId;
  int? sessionId;
  String? insertId;
  double? locationLat;
  double? locationLng;
  String? appVersion;
  String? versionName;
  String? platform;
  String? osName;
  String? osVersion;
  String? deviceBrand;
  String? deviceManufacturer;
  String? deviceModel;
  String? carrier;
  String? country;
  String? region;
  String? city;
  String? dma;
  String? idfa;
  String? idfv;
  String? adid;
  String? appSetId;
  String? androidId;
  String? language;
  String? library;
  String? ip;
  Plan? plan;
  IngestionMetadata? ingestionMetadata;
  double? revenue;
  double? price;
  int? quantity;
  String? productId;
  String? revenueType;
  String? currency;
  Map<String, dynamic>? extra;
  // TODO(xinyi): callback is currently not supported until method channel returns event callback of each platform
  String? partnerId;
  int attempts = 0;

  EventOptions({
    this.userId,
    this.deviceId,
    this.timestamp,
    this.eventId,
    this.sessionId,
    this.insertId,
    this.locationLat,
    this.locationLng,
    this.appVersion,
    this.versionName,
    this.platform,
    this.osName,
    this.osVersion,
    this.deviceBrand,
    this.deviceManufacturer,
    this.deviceModel,
    this.carrier,
    this.country,
    this.region,
    this.city,
    this.dma,
    this.idfa,
    this.idfv,
    this.adid,
    this.appSetId,
    this.androidId,
    this.language,
    this.library,
    this.ip,
    this.plan,
    this.ingestionMetadata,
    this.revenue,
    this.price,
    this.quantity,
    this.productId,
    this.revenueType,
    this.currency,
    this.extra,
    this.partnerId,
  });
}
