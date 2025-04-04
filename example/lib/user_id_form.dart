import 'package:flutter/material.dart';
import 'app_state.dart';

class UserIdForm extends StatefulWidget {
  @override
  State<UserIdForm> createState() => _UserIdFormState();
}

class _UserIdFormState extends State<UserIdForm> {
  String? _userId;

  void Function(String) makeHandler(BuildContext context) {
    return (String userId) {
      AppState.of(context).analytics.setUserId(userId.isEmpty ? null : userId);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('User Id (calls setUserId onChange)',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        TextField(
            autocorrect: false,
            decoration: InputDecoration(labelText: 'User Id'),
            onChanged: makeHandler(context)),
        ElevatedButton(
          onPressed: () async {
            final newUserId = await AppState.of(context).analytics.getUserId();
            setState(() {
              _userId = newUserId;
            });
          },
          child: Text('Get User Id'),
        ),
        Row(
          children: [
            Text('Fetched User Id: ',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(_userId ?? 'No User Id fetched',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
