import 'package:test/test.dart';
import 'package:amplitude_flutter/events/identify.dart';

void main() {
  final String testProperty = 'test-property';
  final String testValue = 'test-value';

  group('IdentifyOperation', () {
    test('Operation types should be correct', () {
      expect(IdentifyOperation.set.operationType, '\$set');
      expect(IdentifyOperation.setOnce.operationType, '\$setOnce');
      expect(IdentifyOperation.add.operationType, '\$add');
      expect(IdentifyOperation.append.operationType, '\$append');
      expect(IdentifyOperation.clearAll.operationType, '\$clearAll');
      expect(IdentifyOperation.prepend.operationType, '\$prepend');
      expect(IdentifyOperation.unset.operationType, '\$unset');
      expect(IdentifyOperation.preInsert.operationType, '\$preInsert');
      expect(IdentifyOperation.postInsert.operationType, '\$postInsert');
      expect(IdentifyOperation.remove.operationType, '\$remove');
    });
  });

  group('Identify', () {
    test('Should set() correctly', () {
      final identify = Identify();
      identify.set(testProperty, testValue);

      expect(identify.properties.containsKey('\$set'), isTrue);
      expect(identify.properties['\$set'][testProperty], testValue);
      expect(identify.propertySet.contains(testProperty), isTrue);
    });

    test('Should setOnce() correctly', () {
      final identify = Identify();
      identify.setOnce(testProperty, testValue);

      expect(identify.properties.containsKey('\$setOnce'), isTrue);
      expect(identify.properties['\$setOnce'][testProperty], testValue);
      expect(identify.propertySet.contains(testProperty), isTrue);
    });

    test('Should add() correctly', () {
      final identify = Identify();
      identify.add(testProperty, testValue);

      expect(identify.properties.containsKey('\$add'), isTrue);
      expect(identify.properties['\$add'][testProperty], testValue);
      expect(identify.propertySet.contains(testProperty), isTrue);
    });

    test('Should append() correctly', () {
      final identify = Identify();
      identify.append(testProperty, testValue);

      expect(identify.properties.containsKey('\$append'), isTrue);
      expect(identify.properties['\$append'][testProperty], testValue);
      expect(identify.propertySet.contains(testProperty), isTrue);
    });

    test('Should prepend() correctly', () {
      final identify = Identify();
      identify.prepend(testProperty, testValue);

      expect(identify.properties.containsKey('\$prepend'), isTrue);
      expect(identify.properties['\$prepend'][testProperty], testValue);
      expect(identify.propertySet.contains(testProperty), isTrue);
    });

    test('Should preInsert() correctly', () {
      final identify = Identify();
      identify.preInsert(testProperty, testValue);

      expect(identify.properties.containsKey('\$preInsert'), isTrue);
      expect(identify.properties['\$preInsert'][testProperty], testValue);
      expect(identify.propertySet.contains(testProperty), isTrue);
    });

    test('Should remove() correctly', () {
      final identify = Identify();
      identify.remove(testProperty, testValue);

      expect(identify.properties.containsKey('\$remove'), isTrue);
      expect(identify.properties['\$remove'][testProperty], testValue);
      expect(identify.propertySet.contains(testProperty), isTrue);
    });

    test('Should unset() correctly', () {
      final identify = Identify();
      identify.unset(testProperty);

      expect(identify.properties.containsKey('\$unset'), isTrue);
      expect(
          identify.properties['\$unset'][testProperty], Identify.UNSET_VALUE);
      expect(identify.propertySet.contains(testProperty), isTrue);
    });

    test('Should clearAll() clear properties and block further updates', () {
      final identify = Identify();
      identify.set(testProperty, testValue);
      identify.clearAll();

      // After clearAll, properties should be cleared except for the clearAll operation itself
      expect(identify.properties.length, 1);
      expect(identify.properties.containsKey('\$clearAll'), isTrue);

      // Attempt to set another property after clearAll should be ignored
      identify.set(testProperty, testValue);
      expect(identify.properties.containsKey('\$set'), isFalse);
    });

    test('Should not proceed when property is empty', () {
      final identify = Identify();
      identify.set('', testValue);

      expect(identify.properties.length, 0);
    });

    test('Should not proceed when value is null', () {
      final identify = Identify();
      identify.set(testProperty, null);

      expect(identify.properties.length, 0);
    });

    test('Should ignore operation when property exists in previous operation',
        () {
      final identify = Identify();
      identify.set(testProperty, testValue);
      identify.set(testProperty, 'new Value');
      expect(identify.properties.length, 1);
      expect(identify.propertySet.length, 1);
      expect(identify.properties[IdentifyOperation.set.operationType],
          {testProperty: testValue});
    });
  });
}
