import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/autocapture/page_views_options.dart';
void main() {
  group('PageViewsOptions', () {
    test('should have default values when no parameters are provided', () {
      final options = PageViewsOptions();
      expect(options.trackHistoryChanges, 'all');
      expect(options.eventType, '');
    });

    test('should set custom values when parameters are provided', () {
      final options = PageViewsOptions(
        trackHistoryChanges: 'pathOnly',
        eventType: 'Custom Event',
      );
      expect(options.trackHistoryChanges, 'pathOnly');
      expect(options.eventType, 'Custom Event');
    });

    test('toMap should return a map with the correct values', () {
      final options = PageViewsOptions(
        trackHistoryChanges: 'pathOnly',
        eventType: 'Custom Event',
      );
      final map = options.toMap();
      expect(map['trackHistoryChanges'], 'pathOnly');
      expect(map['eventType'], 'Custom Event');
    });

    test('toMap should return a map with default values when no parameters are provided', () {
      final options = PageViewsOptions();
      final map = options.toMap();
      expect(map['trackHistoryChanges'], 'all');
      expect(map['eventType'], '');
    });
  });
}
