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

    analytics = Amplitude.getInstance();
    analytics.init(widget.apiKey);
    analytics.logEvent('MyApp startup');
  }

  Future<void> _flushEvents() async {
//    await analytics.flushEvents();

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
