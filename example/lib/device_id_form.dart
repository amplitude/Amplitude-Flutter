import 'package:flutter/material.dart';
import 'app_state.dart';

class DeviceIdForm extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  State<DeviceIdForm> createState() => _DeviceIdFormState();
}

class _DeviceIdFormState extends State<DeviceIdForm> {
  String? _deviceId;

  void Function(String) makeHandler(BuildContext context) {
    return (String deviceId) {
      AppState.of(context)
          .analytics
          .setDeviceId(deviceId.isEmpty ? null : deviceId);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Device Id (calls setDeviceId onChange)',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        TextField(
          autocorrect: false,
          decoration: InputDecoration(labelText: 'Device Id'),
          onChanged: makeHandler(context),
        ),
        ElevatedButton(
          onPressed: () async {
            final newDeviceId =
                await AppState.of(context).analytics.getDeviceId();
            setState(() {
              _deviceId = newDeviceId;
            });
          },
          child: Text('Get Device Id'),
        ),
        Row(
          children: [
            Text('Fetched Device Id: ',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(_deviceId ?? 'No Device Id fetched',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
