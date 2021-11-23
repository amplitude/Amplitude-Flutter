import 'package:flutter/material.dart';

import 'app_state.dart';

class UserIdForm extends StatefulWidget {
  @override
  _UserIdFormState createState() => _UserIdFormState();
}

class _UserIdFormState extends State<UserIdForm> {
  void Function(String) makeHandler(BuildContext context) {
    return (String userId) {
      AppState.of(context).analytics..setUserId(userId.isEmpty ? null : userId);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Current User Id', style: Theme.of(context).textTheme.headline5),
        FutureBuilder(
          future: AppState.of(context).analytics.getUserId(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            return Text(snapshot.data.toString());
          },
        ),
        const SizedBox(height: 10),
        Text('User Id', style: Theme.of(context).textTheme.headline5),
        const SizedBox(height: 10),
        new TextField(
            autocorrect: false,
            decoration: InputDecoration(labelText: 'User Id'),
            onChanged: makeHandler(context)),
      ],
    );
  }
}
