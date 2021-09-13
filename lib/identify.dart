import 'package:flutter/foundation.dart';

class Identify {
  Identify() : payload = <String, dynamic>{};

  static const String OP_SET = r'$set';
  static const String OP_SET_ONCE = r'$setOnce';
  static const String OP_ADD = r'$add';
  static const String OP_APPEND = r'$append';
  static const String OP_UNSET = r'$unset';
  static const String OP_PREPEND = r'$prepend';
  static const String OP_PREINSERT = r'$preInsert';
  static const String OP_POSTINSERT = r'$postInsert';
  static const String OP_REMOVE = r'$remove';
  static const String OP_CLEAR_ALL = r'$clearAll';

  final Map<String, dynamic> payload;

  void set(String key, dynamic value) {
    addOp(OP_SET, key, value);
  }

  void setOnce(String key, dynamic value) {
    addOp(OP_SET_ONCE, key, value);
  }

  void add(String key, num value) {
    addOp(OP_ADD, key, value);
  }

  void append(String key, dynamic value) {
    addOp(OP_APPEND, key, value);
  }

  void unset(String key) {
    addOp(OP_UNSET, key, '-');
  }

  void prepend(String key, dynamic value) {
    addOp(OP_PREPEND, key, value);
  }

  void preInsert(String key, dynamic value) {
    addOp(OP_PREINSERT, key, value);
  }

  void postInsert(String key, dynamic value) {
    addOp(OP_POSTINSERT, key, value);
  }

  void remove(String key, dynamic value) {
    addOp(OP_REMOVE, key, value);
  }

  void clearAll() {
    addOp(OP_CLEAR_ALL, '-', '-');
  }

  @visibleForTesting
  void addOp(String op, String key, dynamic value) {
    assert([
      OP_SET,
      OP_SET_ONCE,
      OP_ADD,
      OP_APPEND,
      OP_UNSET,
      OP_PREPEND,
      OP_PREINSERT,
      OP_POSTINSERT,
      OP_REMOVE,
      OP_CLEAR_ALL,
    ].contains(op));

    _opMap(op)[key] = value;
  }

  Map<String, dynamic> _opMap(String key) {
    return payload.putIfAbsent(key, () => <String, dynamic>{});
  }
}
