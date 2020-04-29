import 'package:flutter/foundation.dart';

class Identify {
  Identify() {
    payload = <String, dynamic>{};
  }

  static const String OP_SET = r'$set';
  static const String OP_SET_ONCE = r'$setOnce';
  static const String OP_ADD = r'$add';
  static const String OP_APPEND = r'$append';
  static const String OP_UNSET = r'$unset';

  Map<String, dynamic> payload;

  void set(String key, dynamic value) {
    addOp(OP_SET, key, value);
  }

  void setOnce(String key, dynamic value) {
    addOp(OP_SET_ONCE, key, value);
  }

  void add(String key, num value) {
    addOp(OP_ADD, key, value);
  }

  void unset(String key) {
    addOp(OP_UNSET, key, '-');
  }

  void append(String key, dynamic value) {
    addOp(OP_APPEND, key, value);
  }

  @visibleForTesting
  void addOp(String op, String key, dynamic value) {
    assert([OP_SET, OP_SET_ONCE, OP_ADD, OP_APPEND, OP_UNSET].contains(op));

    _opMap(op)[key] = value;
  }

  Map<String, dynamic> _opMap(String key) {
    return payload.putIfAbsent(key, () => <String, dynamic>{});
  }
}
