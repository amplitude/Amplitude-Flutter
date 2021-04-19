import 'package:flutter/material.dart';
import 'app_state.dart';

class DeviceIdSessionId extends StatefulWidget {
  @override
  _DeviceIdSessionIdState createState() => _DeviceIdSessionIdState();
}

class _DeviceIdSessionIdState extends State<DeviceIdSessionId> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Device Id', style: Theme.of(context).textTheme.headline5),
          ],
        ),
        Row(
          children: [
            FutureBuilder(
              future: AppState.of(context).analytics.getDeviceId(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                return Text(snapshot.data.toString());
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Session Id', style: Theme.of(context).textTheme.headline5),
          ],
        ),
        Row(children: [
          FutureBuilder(
            future: AppState.of(context).analytics.getSessionId(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              return Text(snapshot.data.toString());
            },
          ),
        ])
      ],
    );
  }
}
