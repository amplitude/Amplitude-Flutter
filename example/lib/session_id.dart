import 'package:flutter/material.dart';
import 'app_state.dart';

class SessionIdForm extends StatefulWidget {
  @override
  State<SessionIdForm> createState() => _SessionIdFormState();
}

class _SessionIdFormState extends State<SessionIdForm> {
  int? _sessionId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Session Id', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            final newSessionId =
                await AppState.of(context).analytics.getSessionId();
            setState(() {
              _sessionId = newSessionId;
            });
          },
          child: Text('Get Session Id'),
        ),
        Row(
          children: [
            Text('Fetched Session Id: ',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(_sessionId.toString() ?? 'No Session Id fetched',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
