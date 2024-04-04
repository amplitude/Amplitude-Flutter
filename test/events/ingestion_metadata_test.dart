import 'package:amplitude_flutter/events/ingestion_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testSourceName = 'test-source-name';
  final testSourceVersion = 'test-source-version';

  group('IngestionMetadata', () {
    test('Should init with default values', () {
      final ingestionMetadata = IngestionMetadata();

      expect(ingestionMetadata.sourceName, isNull);
      expect(ingestionMetadata.sourceVersion, isNull);
    });

    test('Should init with custom values', () {
      final ingestionMetadata = IngestionMetadata(
        sourceName: testSourceName,
        sourceVersion: testSourceVersion,
      );

      expect(ingestionMetadata.sourceName, testSourceName);
      expect(ingestionMetadata.sourceVersion, testSourceVersion);
    });

    test('Should toMap() returns correct mapping', () {
      final ingestionMetadata = IngestionMetadata(
        sourceName: testSourceName,
        sourceVersion: testSourceVersion,
      );
      final ingestionMetadataMap = ingestionMetadata.toMap();

      expect(ingestionMetadataMap, isA<Map<String, dynamic>>());
      expect(ingestionMetadataMap['sourceName'], testSourceName);
      expect(ingestionMetadataMap['sourceVersion'], testSourceVersion);
    });
  });
}
