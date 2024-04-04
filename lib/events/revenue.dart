import 'revenue_event.dart';

class RevenueConstants {
  static const String revenueProductId = '\$productId';
  static const String revenueQuantity = '\$quantity';
  static const String revenuePrice = '\$price';
  static const String revenueType = '\$revenueType';
  static const String revenueReceipt = '\$receipt';
  static const String revenueReceiptSig = '\$receiptSig';
  static const String revenue = '\$revenue';
}

class Revenue {
  int quantity = 1;
  double? price;
  double? revenue;
  String? productId;
  String? revenueType;
  String? receipt;
  String? receiptSig;
  Map<String, dynamic>? properties;

  Revenue();

  RevenueEvent toRevenueEvent() {
    final event = RevenueEvent();
    final eventProperties = properties ?? {};
    eventProperties[RevenueConstants.revenuePrice] = price ?? 0;
    eventProperties[RevenueConstants.revenueQuantity] = quantity;
    if (productId != null) {eventProperties[RevenueConstants.revenueProductId] = productId;}
    if (revenueType != null) {eventProperties[RevenueConstants.revenueType] = revenueType;}
    if (receipt != null) {eventProperties[RevenueConstants.revenueReceipt] = receipt;}
    if (receiptSig != null) {eventProperties[RevenueConstants.revenueReceiptSig] = receiptSig;}
    if (revenue != null) {eventProperties[RevenueConstants.revenue] = revenue;}
    event.eventProperties = eventProperties;
    return event;
  }

  bool isValid() {
    return price != null;
  }

}
