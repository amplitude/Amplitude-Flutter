import 'package:flutter/material.dart';

// ignore_for_file: depend_on_referenced_packages
import 'package:amplitude_flutter/events/base_event.dart';

import 'app_state.dart';

class EventForm extends StatefulWidget {
  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final TextEditingController _controller =
      TextEditingController(text: 'Dart Click');

  void onPress() {
    AppState.of(context)
      ..analytics.track(BaseEvent(_controller.text))
      ..setMessage('Event sent.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Event', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        TextField(
            decoration: InputDecoration(
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                labelText: 'Event Name'),
            controller: _controller),
        ElevatedButton(child: const Text('Send Event'), onPressed: onPress)
      ],
    );
  }
}
