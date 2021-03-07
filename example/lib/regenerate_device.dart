import 'package:flutter/material.dart';

import 'app_state.dart';

class RegenerateDeviceBtn extends StatefulWidget {
  @override
  _DeviceState createState() => _DeviceState();
}

class _DeviceState extends State<RegenerateDeviceBtn> {
  void onPress() {
    AppState.of(context)
      ..analytics.regenerateDeviceId()
      ..setMessage('Regenerate DeviceId.');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        child: const Text('Regenerate DeviceId'), onPressed: onPress);
  }
}
