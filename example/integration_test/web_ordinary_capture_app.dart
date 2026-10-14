// Offline fixture for tools/web_ordinary_capture_probe.cjs only.
import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final mode = Uri.base.queryParameters['capture'];
  final Autocapture options = switch (mode) {
    'all' => const AutocaptureEnabled(),
    'explicit' => AutocaptureOptions(
          elementInteractions: ElementInteractionsOptions(
        cssSelectorAllowlist: const ['#probe-allowed'],
        actionClickAllowlist: const ['.probe-parent'],
        dataAttributePrefix: 'data-probe-',
        pageUrlAllowlist: [Uri.base.toString()],
      )),
    _ => const AutocaptureOptions(
        elementInteractions: ElementInteractionsEnabled()),
  };
  final analytics = Amplitude(
      Configuration(apiKey: 'offline-pr1-probe', autocapture: options));
  SemanticsBinding.instance.ensureSemantics();
  // Read-only evidence of Flutter pointer delivery, independent of capture.
  WidgetsBinding.instance.pointerRouter.addGlobalRoute((event) {
    if (event is PointerDownEvent || event is PointerUpEvent) {
      analytics.track(BaseEvent(event is PointerDownEvent
          ? 'Probe Pointer Down'
          : 'Probe Pointer Up'));
    }
  });
  runApp(MaterialApp(
      home: Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
    for (final name in ['Allowed', 'Blocked'])
      ElevatedButton(
        onPressed: () => analytics.track(
            BaseEvent('Probe Callback', eventProperties: {'button': name})),
        child: Text(name),
      ),
  ])))));
}
