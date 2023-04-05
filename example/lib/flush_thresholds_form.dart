import 'package:flutter/material.dart';

import 'app_state.dart';

class FlushThresholdForm extends StatefulWidget {
  @override
  _FlushThresholdFormState createState() => _FlushThresholdFormState();
}

class _FlushThresholdFormState extends State<FlushThresholdForm> {
  final TextEditingController eventUploadThresholdInput =
      TextEditingController(text: '5');
  final TextEditingController eventUploadPeriodMillisInput =
      TextEditingController(text: '30000');
  final EdgeInsetsGeometry contentPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 8);

  void onPressSetUploadThreshold() {
    final value = int.tryParse(eventUploadThresholdInput.text);

    if (eventUploadThresholdInput.text.isNotEmpty && value != null) {
      AppState.of(context)
        ..analytics.setEventUploadThreshold(value!)
        ..setMessage('Event upload threshold set.');
    }
  }

  void onPressSetEventUploadPeriodMillis() {
    final value = int.tryParse(eventUploadPeriodMillisInput.text);

    if (eventUploadPeriodMillisInput.text.isNotEmpty && value != null) {
      AppState.of(context)
        ..analytics.setEventUploadPeriodMillis(value!)
        ..setMessage('Event upload period millis set.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Flush Intervals', style: Theme.of(context).textTheme.headline5),
        const SizedBox(height: 10),
        TextField(
            decoration: InputDecoration(
                filled: true,
                contentPadding: contentPadding,
                labelText: 'Event Upload Threshold'),
            controller: eventUploadThresholdInput),
        ElevatedButton(
            child: const Text('Set Event Upload Threshold'),
            onPressed: onPressSetUploadThreshold),
        const SizedBox(height: 10),
        TextField(
            decoration: InputDecoration(
                filled: true,
                contentPadding: contentPadding,
                labelText: 'Event Upload Period (Milliseconds)'),
            controller: eventUploadPeriodMillisInput),
        ElevatedButton(
            child: const Text('Set Event Upload Period'),
            onPressed: onPressSetEventUploadPeriodMillis)
      ],
    );
  }
}
