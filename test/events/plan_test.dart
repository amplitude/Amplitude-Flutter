import 'package:amplitude_flutter/events/plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testBranch = "test-branch";
  final testSource = "test-source";
  final testVersion = "test-version";
  final testVersionId = "test-version-id";

  group("Plan", () {
    test("Should init with default values", () {
      final plan = Plan();

      expect(plan.branch, isNull);
      expect(plan.source, isNull);
      expect(plan.version, isNull);
      expect(plan.versionId, isNull);
    });

    test("Should init with custom values", () {
      final plan = Plan(
        branch: testBranch,
        source: testSource,
        version: testVersion,
        versionId: testVersionId,
      );

      expect(plan.branch, testBranch);
      expect(plan.source, testSource);
      expect(plan.version, testVersion);
      expect(plan.versionId, testVersionId);
    });

    test('Should toMap() returns correct mapping', () {
      final plan = Plan(
        branch: testBranch,
        source: testSource,
        version: testVersion,
        versionId: testVersionId,
      );
      final planMap = plan.toMap();

      expect(planMap, isA<Map<String, dynamic>>());
      expect(planMap['branch'], testBranch);
      expect(planMap['source'], testSource);
      expect(planMap['version'], testVersion);
      expect(planMap['versionId'], testVersionId);
    });
  });
}
