import 'package:flutter/material.dart';

import 'app_state.dart';

class UserIdForm extends StatefulWidget {
  @override
  _UserIdFormState createState() => _UserIdFormState();
}

class _UserIdFormState extends State<UserIdForm> {
  Function makeHandler(BuildContext context) {
    return (String userId) {
      AppState.of(context).analytics..setUserId(userId.isEmpty ? null : userId);
    };
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
        autocorrect: false,
        decoration: InputDecoration(labelText: 'User Id'),
        onChanged: makeHandler(context));
  }
}
