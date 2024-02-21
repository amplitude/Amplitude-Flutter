class IdentifyOperation {
  final String operationType;

  const IdentifyOperation._(this.operationType);

  static const IdentifyOperation set = IdentifyOperation._("\$set");
  static const IdentifyOperation setOnce = IdentifyOperation._("\$setOnce");
  static const IdentifyOperation add = IdentifyOperation._("\$add");
  static const IdentifyOperation append = IdentifyOperation._("\$append");
  static const IdentifyOperation clearAll = IdentifyOperation._("\$clearAll");
  static const IdentifyOperation prepend = IdentifyOperation._("\$prepend");
  static const IdentifyOperation unset = IdentifyOperation._("\$unset");
  static const IdentifyOperation preInsert = IdentifyOperation._("\$preInsert");
  static const IdentifyOperation postInsert = IdentifyOperation._("\$postInsert");
  static const IdentifyOperation remove = IdentifyOperation._("\$remove");
}

class Identify {
  Set<String> propertySet = {};
  Map<String, dynamic> properties = {};

  Identify set({required String property, required dynamic value}) {
    // TODO(xinyi): data type check
    _setUserProperty(IdentifyOperation.set, property, value);
    return this;
  }

  Identify setOnce({required String property, required dynamic value}) {
    // TODO(xinyi): data type check
    _setUserProperty(IdentifyOperation.setOnce, property, value);
    return this;
  }

  Identify add({required String property, required dynamic value}) {
    // TODO(xinyi): data type check
    _setUserProperty(IdentifyOperation.add, property, value);
    return this;
  }

  Identify append({required String property, required dynamic value}) {
    // TODO(xinyi): data type check
    _setUserProperty(IdentifyOperation.append, property, value);
    return this;
  }

  Identify prepend({required String property, required dynamic value}) {
    // TODO(xinyi): data type check
    _setUserProperty(IdentifyOperation.prepend, property, value);
    return this;
  }

  Identify preInsert({required String property, required dynamic value}) {
    // TODO(xinyi): data type check
    _setUserProperty(IdentifyOperation.preInsert, property, value);
    return this;
  }

  Identify remove({required String property, required dynamic value}) {
    // TODO(xinyi): data type check
    _setUserProperty(IdentifyOperation.remove, property, value);
    return this;
  }

  Identify unset({required String property}) {
    _setUserProperty(IdentifyOperation.unset, property, Identify.UNSET_VALUE);
    return this;
  }

  Identify clearAll() {
    properties.clear();
    properties[IdentifyOperation.clearAll.operationType] = Identify.UNSET_VALUE;
    return this;
  }

  void _setUserProperty(IdentifyOperation operation, String property, dynamic value) {
    if (property.isEmpty) {
      // TODO(xinyi): add logs
      // log.warning("Attempting to perform operation ${operation.operationType} with a null or empty string property, ignoring");
      return;
    }
    if (value == null) {
      // TODO(xinyi): add logs
      // log.warning("Attempting to perform operation ${operation.operationType} with null value for property $property, ignoring");
      return;
    }
    if (properties.containsKey(IdentifyOperation.clearAll.operationType)) {
      // TODO(xinyi): add logs
      // log.warning("This Identify already contains a \$clearAll operation, ignoring operation ${operation.operationType}");
      return;
    }
    if (propertySet.contains(property)) {
      // TODO(xinyi): add logs
      // log.warning("Already used property $property in previous operation, ignoring operation ${operation.operationType}");
      return;
    }
    if (!properties.containsKey(operation.operationType)) {
      properties[operation.operationType] = <String, dynamic>{};
    }
    (properties[operation.operationType] as Map<String, dynamic>)[property] = value;
    propertySet.add(property);
  }

  static const UNSET_VALUE = "-";
}
