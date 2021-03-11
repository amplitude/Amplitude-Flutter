import 'package:flutter/material.dart';

import 'app_state.dart';

class GroupForm extends StatefulWidget {
  @override
  _GroupFormState createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  void onPress() {
    if (groupType.text.isNotEmpty && groupValue.text.isNotEmpty) {
      AppState.of(context)
        ..analytics.setGroup(groupType.text, groupValue.text)
        ..setMessage('Group set.');
    }
  }

  final TextEditingController groupType =
      TextEditingController(text: 'account');
  final TextEditingController groupValue = TextEditingController(text: 'acme');

  @override
  Widget build(BuildContext context) {
    final InputDecoration dec = InputDecoration(
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Group / Account', style: Theme.of(context).textTheme.headline5),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          Expanded(
            child: TextField(
              controller: groupType,
              decoration: dec.copyWith(labelText: 'Group Type'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: groupValue,
              decoration: dec.copyWith(labelText: 'Group Value'),
            ),
          ),
        ]),
        ElevatedButton(child: const Text('Set Group'), onPressed: onPress)
      ],
    );
  }
}
