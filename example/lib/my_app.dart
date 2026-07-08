import 'dart:async';

// ignore_for_file: depend_on_referenced_packages
import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/page_views.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/observers/amplitude_navigator_observer.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'device_id_form.dart';
import 'event_form.dart';
import 'group_form.dart';
import 'group_identify_form.dart';
import 'identify_form.dart';
import 'reset.dart';
import 'revenue_form.dart';
import 'session_id.dart';
import 'user_id_form.dart';

class MyApp extends StatefulWidget {
  const MyApp(this.apiKey);

  final String apiKey;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _message = '';

  late Amplitude analytics;
  late final AmplitudeNavigatorObserver _navigatorObserver;

  initAnalytics() async {
    await analytics.isBuilt;

    setMessage('Amplitude initialized');
  }

  @override
  void initState() {
    super.initState();
    analytics = Amplitude(Configuration(
        apiKey: widget.apiKey,
        logLevel: LogLevel.debug,
        // Screen views are captured by the AmplitudeNavigatorObserver on every
        // platform. On web we disable pageViews so a navigation is reported once
        // (as `[Amplitude] Screen Viewed`) instead of also as
        // `[Amplitude] Page Viewed`.
        autocapture: const AutocaptureOptions(
          screenViews: true,
          pageViews: PageViewsDisabled(),
          appLifecycles: true,
          deepLinks: true,
        )));
    _navigatorObserver = AmplitudeNavigatorObserver(analytics);
    initAnalytics();
  }

  Future<void> _flushEvents() async {
    analytics.flush();

    setMessage('Events flushed.');
  }

  void setMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Widget divider = Divider();

    return AppState(
      analytics: analytics,
      setMessage: setMessage,
      child: MaterialApp(
        theme: ThemeData(
            inputDecorationTheme: InputDecorationTheme(
                contentPadding: const EdgeInsets.all(8), filled: true)),
        navigatorObservers: [_navigatorObserver],
        routes: {
          '/details': (context) => const DetailsScreen(),
        },
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Amplitude Flutter'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView(
              children: <Widget>[
                DeviceIdForm(),
                divider,
                UserIdForm(),
                divider,
                ResetForm(),
                divider,
                SessionIdForm(),
                divider,
                EventForm(),
                divider,
                IdentifyForm(),
                divider,
                GroupForm(),
                divider,
                GroupIdentifyForm(),
                divider,
                RevenueForm(),
                divider,
                // FlushThresholdForm(),
                // divider,
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Opt Out'),
                        onPressed: () {
                          analytics.setOptOut(true);
                          setMessage('Opted out — tracking disabled.');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Opt In'),
                        onPressed: () {
                          analytics.setOptOut(false);
                          setMessage('Opted in — tracking enabled.');
                        },
                      ),
                    ),
                  ],
                ),
                divider,
                ElevatedButton(
                  child: const Text('Flush Events'),
                  onPressed: _flushEvents,
                ),
                Builder(
                  builder: (context) => ElevatedButton(
                    child: const Text('Open Details Screen'),
                    onPressed: () => Navigator.of(context).pushNamed('/details'),
                  ),
                ),
                Text(_message, style: Theme.of(context).textTheme.bodyLarge)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple second screen to demonstrate screen view autocapture. Navigating to
/// the `/details` route emits an `[Amplitude] Screen Viewed` event through the
/// [AmplitudeNavigatorObserver].
class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(child: Text('Details screen')),
    );
  }
}
