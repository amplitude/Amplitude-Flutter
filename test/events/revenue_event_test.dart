import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/events/revenue_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("RevenueEvent", () {
    test("should init with default values", () {
      final revenueEvent = RevenueEvent();

      expect(revenueEvent.eventType, Constants.revenue_event);
    });
  });
}
