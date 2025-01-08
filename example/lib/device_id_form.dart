import 'package:flutter/material.dart';
import 'app_state.dart';

class DeviceIdForm extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  State<DeviceIdForm> createState() => _DeviceIdFormState();
}

class _DeviceIdFormState extends State<DeviceIdForm> {
  void Function(String) makeHandler(BuildContext context) {
    return (String deviceId) {
      AppState
          .of(context)
          .analytics
          .setDeviceId(deviceId);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Device Id', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        TextField(
          autocorrect: false,
          decoration: InputDecoration(labelText: 'Device Id'),
          onChanged: makeHandler(context),
        ),
      ],
    );
  }
}
