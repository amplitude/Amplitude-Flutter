import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/events/identify_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("IdentifyEvent", () {
    test("should init with default values", () {
      final identifyEvent = IdentifyEvent();

      expect(identifyEvent.eventType, Constants.identify_event);
    });
  });
}