import 'dart:async';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'event_form.dart';
import 'group_form.dart';
import 'group_identify_form.dart';
import 'identify_form.dart';
import 'revenue_form.dart';
import 'user_id_form.dart';
import 'regenerate_device.dart';

class MyApp extends StatefulWidget {
  const MyApp(this.apiKey);

  final String apiKey;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _message = '';
  Amplitude analytics;

  @override
  void initState() {
    super.initState();

    analytics = Amplitude.getInstance(instanceName: "project");
    analytics.setUseDynamicConfig(true);
    analytics.setServerUrl("https://api2.amplitude.com");
    analytics.init(widget.apiKey);
    analytics.enableCoppaControl();
    analytics.setUserId("test_user");
    analytics.trackingSessionEvents(true);
    analytics.logEvent('MyApp startup',
        eventProperties: {'event_prop_1': 10, 'event_prop_2': true});
    Map<String, dynamic> userProps = {
      'date': '01.06.2020',
      'name': 'Name',
      'buildNumber': '1.1.1',
    };

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
                GroupIdentifyForm(),
                divider,
                RevenueForm(),
                divider,
                RaisedButton(
                  child: const Text('Flush Events'),
                  onPressed: _flushEvents,
                ),
                Text(_message, style: Theme.of(context).textTheme.body1)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
