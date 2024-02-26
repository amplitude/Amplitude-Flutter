import 'package:amplitude_flutter/events/identify.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';

class IdentifyForm extends StatefulWidget {
  @override
  _IdentifyFormState createState() => _IdentifyFormState();
}

class _IdentifyFormState extends State<IdentifyForm> {
  void onPress() {
    final Identify identify = Identify()
      ..set(property: 'identify_test', value: 'identify sent at ${DateTime
          .now()
          .millisecondsSinceEpoch}')
    ..add(property: "identify_count", value: 1);

    if (userPropKey.isNotEmpty && userPropValue.isNotEmpty) {
      identify.set(property: userPropKey, value: userPropValue);
    }

    AppState.of(context)
      ..analytics.identify(identify: identify)
      ..setMessage('Identify sent.');
  }

  String userPropKey = '';
  String userPropValue = '';

  @override
  Widget build(BuildContext context) {
    final InputDecoration dec = InputDecoration()
      ..applyDefaults(Theme
          .of(context)
          .inputDecorationTheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Identify', style: Theme
            .of(context)
            .textTheme
            .headlineSmall),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          Expanded(
            child: TextField(
                decoration: dec.copyWith(labelText: 'User Property Key'),
                onChanged: (String s) => userPropKey = s),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
                decoration: dec.copyWith(labelText: 'User Property Value'),
                onChanged: (String s) => userPropValue = s),
          ),
        ]),
        ElevatedButton(child: const Text('Send Identify'), onPressed: onPress)
      ],
    );
  }
}
