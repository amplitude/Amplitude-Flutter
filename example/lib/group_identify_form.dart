import 'package:amplitude_flutter/identify.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';

class GroupIdentifyForm extends StatefulWidget {
  @override
  _GroupIdentifyFormState createState() => _GroupIdentifyFormState();
}

class _GroupIdentifyFormState extends State<GroupIdentifyForm> {
  void onPress() {
    if (groupType.text.isNotEmpty &&
        groupValue.text.isNotEmpty &&
        groupPropertyKey.text.isNotEmpty &&
        groupPropertyValue.text.isNotEmpty) {
      final Identify identify = Identify()
        ..set(groupPropertyKey.text, groupPropertyValue.text);

      AppState.of(context)
        ..analytics.groupIdentify(groupType.text, groupValue.text, identify)
        ..setMessage('Group Identify sent.');
    }
  }

  final TextEditingController groupType =
      TextEditingController(text: 'account');
  final TextEditingController groupValue = TextEditingController(text: 'acme');
  final TextEditingController groupPropertyKey =
      TextEditingController(text: '');
  final TextEditingController groupPropertyValue =
      TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    final InputDecoration dec = InputDecoration()
      ..applyDefaults(Theme.of(context).inputDecorationTheme);

    const sizedBox = SizedBox(width: 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Group Identify', style: Theme.of(context).textTheme.headline5),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          Expanded(
              child: TextField(
                  controller: groupType,
                  decoration: dec.copyWith(labelText: 'Group Type'))),
          sizedBox,
          Expanded(
              child: TextField(
                  controller: groupValue,
                  decoration: dec.copyWith(labelText: 'Group Value'))),
        ]),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          Expanded(
              child: TextField(
            controller: groupPropertyKey,
            decoration: dec.copyWith(labelText: 'User Property Key'),
          )),
          sizedBox,
          Expanded(
              child: TextField(
            controller: groupPropertyValue,
            decoration: dec.copyWith(labelText: 'User Property Value'),
          )),
        ]),
        ElevatedButton(
            child: const Text('Send Group Identify'), onPressed: onPress)
      ],
    );
  }
}
