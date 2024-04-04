import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/events/group_identify_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupIdentifyEvent', () {
    test('should init with default values', () {
      final groupIdentifyEvent = GroupIdentifyEvent();

      expect(groupIdentifyEvent.eventType, Constants.groupIdentifyEvent);
    });
  });
}
