import 'package:flutter/material.dart';

import 'app_state.dart';

class testBtn extends StatefulWidget {
  @override
  _DeviceState createState() => _DeviceState();
}

class _DeviceState extends State<testBtn> {
  void onPress() {
    AppState.of(context)
      ..analytics.adSupportBlock({ return 'addsupportblock in test dart';})
      ..setMessage('click the adsupportblock and pass the function.');
  }

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
        child: const Text('addsupportblock'), onPressed: onPress);
  }
}
