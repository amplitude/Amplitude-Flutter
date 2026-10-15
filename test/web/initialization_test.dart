@TestOn('chrome')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:amplitude_flutter/amplitude.dart' as dart_sdk;
import 'package:amplitude_flutter/amplitude_web.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

@JS('amplitude')
external JSObject? get browserAmplitude;

@JS('amplitude')
external set browserAmplitude(JSObject? value);

class AdapterChannel extends MethodChannel {
  AdapterChannel(this.plugin) : super('amplitude-readiness-test');

  final AmplitudeFlutterPlugin plugin;

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    final result = await plugin.handleMethodCall(MethodCall(method, arguments));
    return result as T?;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late JSObject? originalAmplitude;
  late Completer<JSAny?> initialized;
  late List<JSObject> tracked;
  late AmplitudeFlutterPlugin plugin;

  setUp(() {
    originalAmplitude = browserAmplitude;
    initialized = Completer<JSAny?>();
    tracked = [];
    plugin = AmplitudeFlutterPlugin();
    final result = JSObject();
    result.setProperty('promise'.toJS, initialized.future.toJS);
    final instance = JSObject();
    instance.setProperty(
        'init'.toJS, ((JSString key, JSObject? configuration) => result).toJS);
    instance.setProperty('add'.toJS, ((JSObject value) {}).toJS);
    instance.setProperty(
        'track'.toJS,
        ((JSObject event) {
          tracked.add(event);
        }).toJS);
    final global = JSObject();
    global.setProperty('createInstance'.toJS, (() => instance).toJS);
    browserAmplitude = global;
  });

  tearDown(() {
    browserAmplitude = originalAmplitude;
  });

  test('isBuilt waits for web initialization without delaying tracking',
      () async {
    final analytics = dart_sdk.Amplitude(
      Configuration(apiKey: 'test-api-key', instanceName: 'web-readiness'),
      AdapterChannel(plugin),
    );
    var completed = false;
    unawaited(analytics.isBuilt.then((_) => completed = true));

    await analytics.track(BaseEvent('early'));
    await Future<void>.delayed(Duration.zero);
    expect(tracked, hasLength(1));
    expect(plugin.instances, contains('web-readiness'));
    expect(completed, isFalse);

    initialized.complete(null);
    expect(await analytics.isBuilt, isTrue);
  });

  test('isBuilt reports rejected web initialization', () async {
    final analytics = dart_sdk.Amplitude(
      Configuration(apiKey: 'test-api-key'),
      AdapterChannel(plugin),
    );
    await Future<void>.delayed(Duration.zero);
    initialized.completeError(StateError('Initialization failed.'));
    expect(await analytics.isBuilt, isFalse);
  });

  test('isBuilt reports false when web initialization never settles', () async {
    // A blocked SDK script leaves the snippet's init promise pending forever.
    plugin =
        AmplitudeFlutterPlugin(initTimeout: const Duration(milliseconds: 50));
    final analytics = dart_sdk.Amplitude(
      Configuration(apiKey: 'test-api-key', instanceName: 'web-timeout'),
      AdapterChannel(plugin),
    );

    await analytics.track(BaseEvent('queued'));
    expect(tracked, hasLength(1));
    expect(
        await analytics.isBuilt.timeout(const Duration(seconds: 5)), isFalse);
  });
}
