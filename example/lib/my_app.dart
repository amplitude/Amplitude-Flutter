import 'dart:async';

// ignore_for_file: depend_on_referenced_packages
import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/default_tracking.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'device_id_form.dart';
import 'event_form.dart';
import 'group_form.dart';
import 'group_identify_form.dart';
import 'identify_form.dart';
import 'reset.dart';
import 'revenue_form.dart';
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

  initAnalytics() async {
    await analytics.isBuilt;

    setMessage('Amplitude initialized');
  }

  @override
  void initState() {
    super.initState();
    analytics = Amplitude(
        Configuration(
            apiKey: widget.apiKey,
            logLevel: LogLevel.debug,
            defaultTracking: DefaultTrackingOptions.all()
        )
    );
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
                ElevatedButton(
                  child: const Text('Flush Events'),
                  onPressed: _flushEvents,
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
