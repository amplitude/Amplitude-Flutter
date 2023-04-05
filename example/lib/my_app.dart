import 'dart:async';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter_example/flush_thresholds_form.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'deviceid_sessionid.dart';
import 'event_form.dart';
import 'group_form.dart';
import 'group_identify_form.dart';
import 'identify_form.dart';
import 'regenerate_device.dart';
import 'revenue_form.dart';
import 'user_id_form.dart';

class MyApp extends StatefulWidget {
  const MyApp(this.apiKey);

  final String apiKey;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _message = '';

  late final Amplitude analytics;

  @override
  void initState() {
    super.initState();

    analytics = Amplitude.getInstance(instanceName: "project");
    analytics.setUseDynamicConfig(true);
    analytics.setServerUrl("https://api2.amplitude.com");
    analytics.init(widget.apiKey);
    analytics.enableCoppaControl();
    analytics.setUserId("test_user", startNewSession: true);
    analytics.trackingSessionEvents(true);
    analytics.setMinTimeBetweenSessionsMillis(5000);
    analytics.setEventUploadThreshold(5);
    analytics.setEventUploadPeriodMillis(30000);
    analytics.setServerZone("US");
    analytics.logEvent('MyApp startup',
        eventProperties: {'event_prop_1': 10, 'event_prop_2': true});
    analytics.logEvent('Out of Session Event', outOfSession: true);
    analytics.setOptOut(true);
    analytics.logEvent('Opt Out Event');
    analytics.setOptOut(false);

    Map<String, dynamic> userProps = {
      'date': '01.06.2020',
      'name': 'Name',
      'buildNumber': '1.1.1',
    };
    analytics.logRevenueAmount(21.9);
    analytics.setUserProperties(userProps);
  }

  Future<void> _flushEvents() async {
    await analytics.uploadEvents();

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
                DeviceIdSessionId(),
                divider,
                UserIdForm(),
                divider,
                RegenerateDeviceBtn(),
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
                FlushThresholdForm(),
                divider,
                ElevatedButton(
                  child: const Text('Flush Events'),
                  onPressed: _flushEvents,
                ),
                Text(_message, style: Theme.of(context).textTheme.bodyText1)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
