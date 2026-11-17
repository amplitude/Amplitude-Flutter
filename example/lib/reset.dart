import 'package:flutter/material.dart';

import 'app_state.dart';

class ResetForm extends StatefulWidget {
  @override
  State<ResetForm> createState() => _DeviceState();
}

class _DeviceState extends State<ResetForm> {
  void onPress() {
    AppState.of(context)
      ..analytics.reset()
      ..setMessage('Reset.');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        child: const Text('Reset user Id and device Id'), onPressed: onPress);
  }
}
