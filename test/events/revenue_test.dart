import 'package:amplitude_flutter/events/revenue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final int testQuantity = 2;
  final double testPrice = 9.99;
  final double testRevenue = 19.98;
  final String testProductId = 'test_product';
  final String testRevenueType = 'test_type';
  final String testReceipt = 'test_receipt';
  final String testReceiptSig = 'test_receiptSig';
  final Map<String, dynamic> testProperties = {'custom_property': 'custom_value'};

  Revenue createTestRevenue() {
    return Revenue()
      ..quantity = testQuantity
      ..price = testPrice
      ..revenue = testRevenue
      ..productId = testProductId
      ..revenueType = testRevenueType
      ..receipt = testReceipt
      ..receiptSig = testReceiptSig
      ..properties = testProperties;
  }

  group('Revenue', () {
    test('should create a Revenue instance with default values', () {
      final revenue = Revenue();
      expect(revenue.quantity, 1);
      expect(revenue.price, isNull);
      expect(revenue.revenue, isNull);
      expect(revenue.productId, isNull);
      expect(revenue.revenueType, isNull);
      expect(revenue.receipt, isNull);
      expect(revenue.receiptSig, isNull);
      expect(revenue.properties, isNull);
    });

    test('should correctly assign properties', () {
      final revenue = createTestRevenue();
      expect(revenue.quantity, testQuantity);
      expect(revenue.price, testPrice);
      expect(revenue.revenue, testRevenue);
      expect(revenue.productId, testProductId);
      expect(revenue.revenueType, testRevenueType);
      expect(revenue.receipt, testReceipt);
      expect(revenue.receiptSig, testReceiptSig);
      expect(revenue.properties, testProperties);
    });

    test('toRevenueEvent should correctly convert to RevenueEvent', () {
      final revenue = createTestRevenue();
      final event = revenue.toRevenueEvent();

      expect(event.eventProperties, isNotNull);
      expect(event.eventProperties![RevenueConstants.revenueProductId], testProductId);
      expect(event.eventProperties![RevenueConstants.revenueQuantity], testQuantity);
      expect(event.eventProperties![RevenueConstants.revenuePrice], testPrice);
      expect(event.eventProperties![RevenueConstants.revenuePrice], testPrice);
      expect(event.eventProperties![RevenueConstants.revenueType], testRevenueType);
      expect(event.eventProperties![RevenueConstants.revenueReceipt], testReceipt);
      expect(event.eventProperties![RevenueConstants.revenueReceiptSig], testReceiptSig);
      expect(event.eventProperties![RevenueConstants.revenue], testRevenue);
    });

    test('isValid should return true when price is not null', () {
      final revenue = createTestRevenue();
      expect(revenue.isValid(), isTrue);
    });

    test('isValid should return false when price is null', () {
      final revenue = Revenue();
      expect(revenue.isValid(), isFalse);
    });
  });
}
